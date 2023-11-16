/*-- Last Change Revision: $Rev: 2027060 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:52 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_ea_logic_social_worker IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on EPIS_INTERV_PLAN into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Diogo Oliveira
    * @version              v2.7.4.5
    * @since                2018/11/09
    */
    PROCEDURE set_interv_plan_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_INTERV_PLAN_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_INTERV_PLAN';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_epis_interv_plan IS
            SELECT eip.id_epis_interv_plan,
                   e.id_patient,
                   e.id_episode,
                   e.id_institution,
                   eip.dt_creation dt_creation_tstz,
                   eip.dt_begin,
                   eip.dt_end,
                   eip.id_professional,
                   eip.flg_status
              FROM epis_interv_plan eip
              JOIN episode e
                ON e.id_episode = eip.id_episode
             WHERE eip.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t);
    
        TYPE t_coll_epis_interv_plan IS TABLE OF c_epis_interv_plan%ROWTYPE;
        l_epis_interv_plan_rows t_coll_epis_interv_plan;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        l_idx       PLS_INTEGER;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx          := 0;
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
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
        
            -- get epis_interv_plan data from rowids
            g_error := 'OPEN c_epis_interv_plan';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_epis_interv_plan;
            FETCH c_epis_interv_plan BULK COLLECT
                INTO l_epis_interv_plan_rows;
            CLOSE c_epis_interv_plan;
        
            -- copy epis_interv_plan data into rows collection
            IF l_epis_interv_plan_rows IS NOT NULL
               AND l_epis_interv_plan_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_intervention_plan;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_epis_interv_plan_rows.first .. l_epis_interv_plan_rows.last
                LOOP
                    l_ea_row.id_task_refid  := l_epis_interv_plan_rows(i).id_epis_interv_plan;
                    l_ea_row.id_patient     := l_epis_interv_plan_rows(i).id_patient;
                    l_ea_row.id_episode     := l_epis_interv_plan_rows(i).id_episode;
                    l_ea_row.id_visit       := NULL;
                    l_ea_row.id_institution := l_epis_interv_plan_rows(i).id_institution;
                    l_ea_row.dt_begin       := l_epis_interv_plan_rows(i).dt_begin;
                    l_ea_row.dt_end         := l_epis_interv_plan_rows(i).dt_end;
                    l_ea_row.dt_req         := l_epis_interv_plan_rows(i).dt_creation_tstz;
                    l_ea_row.id_prof_req    := l_epis_interv_plan_rows(i).id_professional;
                    l_ea_row.flg_status_req := l_epis_interv_plan_rows(i).flg_status;
                    l_ea_row.flg_outdated   := 0;
                    l_ea_row.flg_ongoing    := 'N';
                
                    --
                    IF l_epis_interv_plan_rows(i).flg_status IN ('C')
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                        l_idx := l_idx + 1;
                        l_ea_rows(l_idx) := l_ea_row;
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                    
                        IF l_rows.count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins II';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
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
    END set_interv_plan_task_timeline;

    /**
    * Process insert/update events on MANAGEMENT_FOLLOW_UP into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Diogo Oliveira
    * @version              v2.7.4.4
    * @since                2018/11/28
    */
    PROCEDURE set_follow_up_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_FOLLOW_UP_TASK_TIMELINE';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'MANAGEMENT_FOLLOW_UP';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_follow_up IS
            SELECT mfu.id_management_follow_up,
                   e.id_patient,
                   e.id_episode,
                   e.id_institution,
                   mfu.dt_register dt_creation_tstz,
                   mfu.dt_start,
                   mfu.id_professional,
                   mfu.flg_status
              FROM management_follow_up mfu
              JOIN episode e
                ON e.id_episode = mfu.id_episode
             WHERE mfu.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t);
    
        TYPE t_coll_follow_up IS TABLE OF c_follow_up%ROWTYPE;
        l_follow_up_rows t_coll_follow_up;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
        l_idx       PLS_INTEGER;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx          := 0;
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
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
        
            -- get epis_interv_plan data from rowids
            g_error := 'OPEN c_epis_interv_plan';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_follow_up;
            FETCH c_follow_up BULK COLLECT
                INTO l_follow_up_rows;
            CLOSE c_follow_up;
        
            -- copy follow_up data into rows collection
            IF l_follow_up_rows IS NOT NULL
               AND l_follow_up_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := 196; --pk_prog_notes_constants.g_task_follow_up_notes;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_follow_up_rows.first .. l_follow_up_rows.last
                LOOP
                    l_ea_row.id_task_refid  := l_follow_up_rows(i).id_management_follow_up;
                    l_ea_row.id_patient     := l_follow_up_rows(i).id_patient;
                    l_ea_row.id_episode     := l_follow_up_rows(i).id_episode;
                    l_ea_row.id_visit       := NULL;
                    l_ea_row.id_institution := l_follow_up_rows(i).id_institution;
                    l_ea_row.dt_begin       := l_follow_up_rows(i).dt_start;
                    l_ea_row.dt_req         := l_follow_up_rows(i).dt_creation_tstz;
                    l_ea_row.id_prof_req    := l_follow_up_rows(i).id_professional;
                    l_ea_row.flg_status_req := l_follow_up_rows(i).flg_status;
                    l_ea_row.flg_outdated   := 0;
                    l_ea_row.flg_ongoing    := 'N';
                
                    --
                    IF l_follow_up_rows(i).flg_status IN ('O', 'C')
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                        l_idx := l_idx + 1;
                        l_ea_rows(l_idx) := l_ea_row;
                    END IF;
                END LOOP;
            
                --if it was canceled there is nothing to insert or update
                IF l_ea_rows.count > 0
                THEN
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE, rows_out => l_rows);
                    
                        IF l_rows.count = 0
                        THEN
                            g_error := 'CALL ts_task_timeline_ea.ins II';
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package,
                                                 sub_object_name => l_func_name);
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
    END set_follow_up_task_timeline;

BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);

END pk_ea_logic_social_worker;
/
