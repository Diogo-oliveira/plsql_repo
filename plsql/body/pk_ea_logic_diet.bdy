/*-- Last Change Revision: $Rev: 2018918 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-07-13 10:43:08 +0100 (qua, 13 jul 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_diet IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Return if the id_epis_diet_req has children
    *
    * @param i_epis_diet_req         language identifier
    *
    * @author               Jorge Silva
    * @version               2.6.3.13
    * @since                2013/03/13
    */
    FUNCTION haschild(i_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE) RETURN BOOLEAN IS
        l_count NUMBER := 0;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_diet_req edr
         WHERE edr.id_epis_diet_req_parent = i_epis_diet_req;
    
        RETURN(l_count > 0);
    
    END haschild;
    --
    FUNCTION get_last_status(i_id_epis_diet_req_parent IN epis_diet_req.id_epis_diet_req_parent%TYPE)
        RETURN epis_diet_req.flg_status%TYPE IS
        l_flg_status epis_diet_req.flg_status%TYPE;
    BEGIN
    
        SELECT edr.flg_status
          INTO l_flg_status
          FROM epis_diet_req edr
         WHERE edr.id_epis_diet_req = i_id_epis_diet_req_parent;
    
        RETURN l_flg_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_status;
    /**
    * Process insert/update events on EPIS_DIET_REQ into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/20
    */
    PROCEDURE set_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_DIET_REQ';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
        l_count   NUMBER := 0;
    
        CURSOR c_diet IS
            SELECT edr.id_epis_diet_req,
                   edr.id_patient,
                   edr.id_episode,
                   e.id_visit,
                   e.id_institution,
                   CASE
                        WHEN edr.flg_status IN (pk_diet.g_flg_diet_status_s, pk_diet.g_flg_diet_status_c) THEN
                         edr.dt_cancel
                        ELSE
                         edr.dt_creation
                    END dt_creation,
                   edr.id_professional,
                   edr.dt_inicial,
                   edr.dt_end,
                   edr.flg_status,
                   CASE
                        WHEN edr.flg_status IN
                             (pk_diet.g_flg_diet_status_s, pk_diet.g_flg_diet_status_c, pk_diet.g_flg_diet_status_x) THEN
                         pk_ea_logic_tasktimeline.g_flg_outdated -- diet is suspended, cancelled or expired
                        WHEN edr.dt_end < g_sysdate_tstz THEN
                         pk_ea_logic_tasktimeline.g_flg_outdated -- diet is complete
                        ELSE
                         pk_ea_logic_tasktimeline.g_flg_not_outdated -- otherwise, diet is pending or ongoing
                    END flg_outdated,
                   CASE
                        WHEN edr.flg_status = pk_diet.g_flg_diet_status_s THEN
                         3
                        WHEN edr.flg_status = pk_diet.g_flg_diet_status_c THEN
                         5
                        WHEN edr.dt_inicial > g_sysdate_tstz THEN
                         2
                        WHEN edr.dt_end < g_sysdate_tstz THEN
                         4
                        ELSE
                         1
                    END rank,
                   edr.id_diet_type id_group_import,
                   dt.code_diet_type code_desc_group,
                   edr.id_epis_diet_req_parent,
                   CASE
                        WHEN edr.flg_status IN
                             (pk_diet.g_flg_diet_status_s, pk_diet.g_flg_diet_status_c, pk_diet.g_flg_diet_status_x) THEN
                         pk_prog_notes_constants.g_task_finalized_f -- diet is suspended, cancelled or expired
                        WHEN edr.dt_end < g_sysdate_tstz THEN
                         pk_prog_notes_constants.g_task_finalized_f -- diet is complete
                        ELSE
                         pk_prog_notes_constants.g_task_ongoing_o -- diet is ongoing or pending
                    END flg_ongoing,
                   e.flg_status flg_status_epis
              FROM epis_diet_req edr
              JOIN diet_type dt
                ON edr.id_diet_type = dt.id_diet_type
              LEFT JOIN episode e
                ON edr.id_episode = e.id_episode
             WHERE edr.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t)
                  -- exclude draft and temporary diets
               AND edr.flg_status NOT IN (pk_diet.g_flg_diet_status_t, pk_diet.g_flg_diet_status_o)
             ORDER BY edr.id_epis_diet_req DESC;
    
        TYPE t_coll_diet IS TABLE OF c_diet%ROWTYPE;
        l_diet_rows t_coll_diet;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => l_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- debug event
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            -- get diet data from rowids
            g_error := 'OPEN c_diet';
            OPEN c_diet;
            FETCH c_diet BULK COLLECT
                INTO l_diet_rows;
            CLOSE c_diet;
        
            -- copy diet data into rows collection
            IF l_diet_rows IS NOT NULL
               AND l_diet_rows.count > 0
            THEN
            
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_diets;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_diet_rows.first .. l_diet_rows.last
                LOOP
                    pk_diet.build_status_str(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_flg_status  => l_diet_rows(i).flg_status,
                                             i_dt_inicial  => l_diet_rows(i).dt_inicial,
                                             i_sys_date    => g_sysdate_tstz,
                                             o_status_str  => l_ea_row.status_str,
                                             o_status_msg  => l_ea_row.status_msg,
                                             o_status_icon => l_ea_row.status_icon,
                                             o_status_flg  => l_ea_row.status_flg);
                
                    l_ea_row.dt_last_update       := l_diet_rows(i).dt_creation;
                    l_ea_row.id_task_refid        := l_diet_rows(i).id_epis_diet_req;
                    l_ea_row.id_patient           := l_diet_rows(i).id_patient;
                    l_ea_row.id_episode           := l_diet_rows(i).id_episode;
                    l_ea_row.id_visit             := l_diet_rows(i).id_visit;
                    l_ea_row.id_institution       := l_diet_rows(i).id_institution;
                    l_ea_row.dt_req               := l_diet_rows(i).dt_creation;
                    l_ea_row.id_prof_req          := l_diet_rows(i).id_professional;
                    l_ea_row.dt_begin             := l_diet_rows(i).dt_inicial;
                    l_ea_row.dt_end               := l_diet_rows(i).dt_end;
                    l_ea_row.flg_status_req       := l_diet_rows(i).flg_status;
                    l_ea_row.flg_outdated         := l_diet_rows(i).flg_outdated;
                    l_ea_row.rank                 := l_diet_rows(i).rank;
                    l_ea_row.id_group_import      := l_diet_rows(i).id_group_import;
                    l_ea_row.code_desc_group      := l_diet_rows(i).code_desc_group;
                    l_ea_row.id_parent_task_refid := l_diet_rows(i).id_epis_diet_req_parent;
                    l_ea_row.flg_ongoing          := l_diet_rows(i).flg_ongoing;
                
                    IF l_diet_rows(i).flg_status IN (pk_diet.g_flg_diet_status_c, pk_diet.g_flg_diet_status_x)
                        OR l_diet_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSIF l_diet_rows(i).id_epis_diet_req_parent IS NOT NULL
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        ts_task_timeline_ea.del(id_task_refid_in => l_diet_rows(i).id_epis_diet_req_parent,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                        -- add row to rows collection
                        IF (haschild(l_diet_rows(i).id_epis_diet_req) = FALSE)
                        THEN
                            --l_ea_rows.extend;
                            l_count := l_count + 1;
                            l_ea_rows(l_count) := l_ea_row;
                            --      l_ea_rows(i) := l_ea_row;
                        END IF;
                    ELSE
                        IF (haschild(l_diet_rows(i).id_epis_diet_req) = FALSE)
                        THEN
                            --l_ea_rows.extend;
                            l_count := l_count + 1;
                            l_ea_rows(l_count) := l_ea_row;
                        END IF;
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins I';
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                    
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                    
                        IF l_rows.count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins II';
                            ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_task_timeline;
    /**
    * Process insert/update events on EPIS_DIET_REQ into inter alert
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/20
    */

    PROCEDURE call_diet_inter_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CALL_DIET_INTER_ALERT';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_DIET_REQ';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'V_EPIS_DIET_REQ';
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_error t_error_out;
    
        CURSOR c_diet IS
            SELECT edr.id_epis_diet_req,
                   edr.id_patient,
                   edr.id_episode,
                   edr.flg_status,
                   edr.id_epis_diet_req_parent,
                   edr.id_cancel_reason
              FROM epis_diet_req edr
             WHERE edr.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t)
                  -- exclude draft and temporary diets
               AND edr.flg_status NOT IN (pk_diet.g_flg_diet_status_t, pk_diet.g_flg_diet_status_o)
             ORDER BY edr.id_epis_diet_req DESC;
    
        TYPE t_coll_diet IS TABLE OF c_diet%ROWTYPE;
        l_diet_rows t_coll_diet;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => l_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- get diet data from rowids
            g_error := 'OPEN c_diet';
            OPEN c_diet;
            FETCH c_diet BULK COLLECT
                INTO l_diet_rows;
            CLOSE c_diet;
        
            IF l_diet_rows IS NOT NULL
               AND l_diet_rows.count > 0
            THEN
                FOR i IN l_diet_rows.first .. l_diet_rows.last
                LOOP
                    IF l_diet_rows(i).flg_status IN (pk_diet.g_flg_diet_status_c, pk_diet.g_flg_diet_status_i)
                    THEN
                        --Cancelamento de Dietas       
                    
                        IF l_diet_rows(i).id_cancel_reason IS NULL
                            OR l_diet_rows(i).id_cancel_reason != l_cancel_id
                            OR (l_diet_rows(i).id_cancel_reason = l_cancel_id AND
                                 l_send_cancel_event = pk_alert_constant.g_yes)
                        THEN
                            pk_ia_event_common.diet_cancel(i_id_institution   => i_prof.institution,
                                                           i_id_epis_diet_req => l_diet_rows(i).id_epis_diet_req);
                        END IF;
                    
                    ELSIF l_diet_rows(i).flg_status = pk_diet.g_flg_diet_status_s
                    THEN
                        --Suspensão de Dietas
                        pk_ia_event_common.diet_suspend(i_id_institution   => i_prof.institution,
                                                        i_id_epis_diet_req => l_diet_rows(i).id_epis_diet_req);
                    
                    ELSIF l_diet_rows(i).id_epis_diet_req_parent IS NULL
                    THEN
                        --Prescrição de Dietas
                        pk_ia_event_common.diet_new(i_id_institution   => i_prof.institution,
                                                    i_id_epis_diet_req => l_diet_rows(i).id_epis_diet_req);
                    
                    ELSIF (get_last_status(l_diet_rows(i).id_epis_diet_req_parent) = pk_diet.g_flg_diet_status_s)
                    THEN
                        --Ativação de Dietas
                        pk_ia_event_common.diet_activate(i_id_institution   => i_prof.institution,
                                                         i_id_epis_diet_req => l_diet_rows(i).id_epis_diet_req);
                    
                    ELSE
                        --Alteração de Dietas
                        pk_ia_event_common.diet_update(i_id_institution   => i_prof.institution,
                                                       i_id_epis_diet_req => l_diet_rows(i).id_epis_diet_req);
                    
                    END IF;
                
                --A Active
                --R Active
                --H Scheduled
                --S On hold
                --F Complete
                --C Cancelled
                --T Draft
                --X Expired
                
                END LOOP;
            END IF;
        END IF;
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END call_diet_inter_alert;
BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_diet;
/
