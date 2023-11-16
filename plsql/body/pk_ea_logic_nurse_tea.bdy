/*-- Last Change Revision: $Rev: 2001943 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-11-24 16:20:34 +0000 (qua, 24 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_nurse_tea IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    /**
    * Process insert/update events on Patient education into TASK_TIMELINE_EA.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_event_type   event type
    * @param i_rowids       changed records rowids list
    * @param i_src_table    source table name
    * @param i_list_columns changed column names list
    * @param i_dg_table     easy access table name
    *
    * @author               Nuno Neves
    * @version              2.6.2
    * @since                2012/09/14
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
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'NURSE_TEA_REQ';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_rows    table_varchar := table_varchar();
        l_error   t_error_out;
    
        CURSOR c_nurse_tea IS
            SELECT ntr.id_nurse_tea_req,
                   ntr.id_patient,
                   ntr.id_episode,
                   ntr.id_visit,
                   e.id_institution,
                   ntr.dt_nurse_tea_req_tstz dt_creation_tstz,
                   ntr.id_prof_req id_professional,
                   ntr.dt_begin_tstz dt_initial_tstz,
                   ntr.dt_close_tstz dt_end_tstz,
                   ntr.flg_status,
                   CASE
                        WHEN ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_act,
                                                pk_patient_education_constant.g_nurse_tea_req_pend) THEN
                         pk_ea_logic_tasktimeline.g_flg_not_outdated --active
                        ELSE
                         pk_ea_logic_tasktimeline.g_flg_outdated
                    END flg_outdated,
                   CASE
                        WHEN ntr.flg_status IN (pk_patient_education_constant.g_nurse_tea_req_fin,
                                                pk_patient_education_constant.g_nurse_tea_req_expired) THEN
                         pk_prog_notes_constants.g_task_finalized_f
                        ELSE
                         pk_prog_notes_constants.g_task_ongoing_o
                    END flg_ongoing,
                   e.flg_status flg_status_epis,
                   coalesce(ntr.dt_close_tstz, ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) dt_last_update
              FROM nurse_tea_req ntr
              JOIN episode e
                ON ntr.id_episode = e.id_episode
             WHERE ntr.rowid IN (SELECT /*+dynamic_sampling(t 2)*/
                                  t.column_value row_id
                                   FROM TABLE(i_rowids) t)
               AND ntr.flg_status NOT IN
                   (pk_patient_education_constant.g_nurse_tea_req_draft,
                    pk_patient_education_constant.g_nurse_tea_req_ign,
                    pk_patient_education_constant.g_nurse_tea_req_sug,
                    pk_patient_education_constant.g_nurse_tea_req_not_ord_reas);
    
        TYPE t_coll_nurse_tea IS TABLE OF c_nurse_tea%ROWTYPE;
        l_nurse_tea_rows t_coll_nurse_tea;
    
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
        
            -- get hidric data from rowids
            g_error := 'OPEN c_hidric';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            OPEN c_nurse_tea;
            FETCH c_nurse_tea BULK COLLECT
                INTO l_nurse_tea_rows;
            CLOSE c_nurse_tea;
        
            -- copy hidric data into rows collection
            IF l_nurse_tea_rows IS NOT NULL
               AND l_nurse_tea_rows.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_pat_education;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_nurse_tea_rows.first .. l_nurse_tea_rows.last
                LOOP
                    l_ea_row.id_task_refid  := l_nurse_tea_rows(i).id_nurse_tea_req;
                    l_ea_row.id_patient     := l_nurse_tea_rows(i).id_patient;
                    l_ea_row.id_episode     := l_nurse_tea_rows(i).id_episode;
                    l_ea_row.id_visit       := l_nurse_tea_rows(i).id_visit;
                    l_ea_row.id_institution := l_nurse_tea_rows(i).id_institution;
                    l_ea_row.dt_req         := l_nurse_tea_rows(i).dt_creation_tstz;
                    l_ea_row.id_prof_req    := l_nurse_tea_rows(i).id_professional;
                    l_ea_row.dt_begin       := l_nurse_tea_rows(i).dt_initial_tstz;
                    l_ea_row.dt_end         := l_nurse_tea_rows(i).dt_end_tstz;
                    l_ea_row.flg_status_req := l_nurse_tea_rows(i).flg_status;
                    l_ea_row.flg_outdated   := l_nurse_tea_rows(i).flg_outdated;
                    l_ea_row.flg_ongoing    := l_nurse_tea_rows(i).flg_ongoing;
                    l_ea_row.dt_last_update := l_nurse_tea_rows(i).dt_last_update;
                
                    --
                    IF l_nurse_tea_rows(i)
                     .flg_status IN (pk_patient_education_constant.g_nurse_tea_req_canc)
                        OR l_nurse_tea_rows(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
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
                        g_error := 'CALL ts_task_timeline_ea.ins I';
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
    END set_task_timeline;

BEGIN
    -- log init
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_nurse_tea;
/
