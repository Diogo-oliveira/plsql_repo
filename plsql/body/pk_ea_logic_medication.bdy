/*-- Last Change Revision: $Rev: 2027034 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_medication IS

    g_exception_np EXCEPTION;

    /********************************************************************************
    ********************************************************************************/
    -- insert into data_gov_event (ID_DATA_GOV_EVENT, DG_TABLE_NAME, SOURCE_TABLE_NAME, SOURCE_COLUMN_NAME, FLG_ENABLED, FLG_BACKGROUND, EXEC_PROCEDURE, EXEC_ORDER, ID_SOFTWARE)
    -- values (17063, 'TASK_TIMELINE_EA', 'PRESC', '', 'Y', 'N', 'PK_EA_LOGIC_MEDICATION.SET_PRESC_TASK_TIME_LINE', 2, 0);
    /*******************************************************************************************************************************************
    * Name:                           SET_PRESC_TASK_TIME_LINE
    * Description:                    Function that updates medicationo information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Pedro Teixeira
    * @version                        2.6.1.2
    * @since                          2011/08/26
    *******************************************************************************************************************************************/
    PROCEDURE set_presc_task_time_line
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_PRESC_TASK_TIME_LINE';
    
        l_new_rec_row      task_timeline_ea%ROWTYPE;
        l_func_proc_name   VARCHAR2(30) := 'SET_PRESC_TASK_TIME_LINE';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_calc_active  VARCHAR2(1);
    
        ---------------------------
        c_presc_data pk_types.cursor_type;
        l_error_out  t_error_out;
    
        l_id_presc              table_number := table_number();
        l_id_patient            table_number := table_number();
        l_id_episode            table_number := table_number();
        l_id_institution        table_number := table_number();
        l_dt_req                table_timestamp_tstz := table_timestamp_tstz();
        l_id_prof_req           table_number := table_number();
        l_dt_begin              table_timestamp_tstz := table_timestamp_tstz();
        l_dt_end                table_timestamp_tstz := table_timestamp_tstz();
        l_id_workflow           table_number := table_number();
        l_id_status             table_number := table_number();
        l_universal_description table_varchar := table_varchar();
        l_flg_sos               table_varchar := table_varchar();
        l_flg_active            table_varchar := table_varchar();
        l_dt_last_execution     table_timestamp_tstz := table_timestamp_tstz();
        l_flg_has_comments      table_varchar := table_varchar();
        l_dt_last_update        table_timestamp_tstz := table_timestamp_tstz();
        l_id_presc_parent       table_number := table_number();
        l_flg_chinese           table_varchar := table_varchar();
        l_flg_stat              table_varchar := table_varchar();
        l_flg_type              table_varchar := table_varchar();
    
        l_flg_ongoing task_timeline_ea.flg_ongoing%TYPE;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- Validate arguments
        g_error := ' validate arguments ';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := ' INSERT ';
                l_event_into_ea := t_data_gov_mnt.g_event_insert;
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := ' UPDATE ';
                l_event_into_ea := t_data_gov_mnt.g_event_update;
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := ' DELETE ';
                l_event_into_ea := t_data_gov_mnt.g_event_delete;
            END IF;
        
            pk_alertlog.log_debug('Detected ' || l_process_name || ' ON ' || i_source_table_name || '(' ||
                                  l_name_table_ea || ') ',
                                  g_package_name,
                                  l_func_proc_name);
        
            ----------------------------------------------------------------------
            -- obtain medication prescription data
            pk_api_pfh_in.get_presc_time_task_line(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_rowids     => i_rowids,
                                                   o_presc_data => c_presc_data,
                                                   o_error      => l_error_out);
        
            /* log: to delete */
            pk_alertlog.log_debug('AFTER pk_api_pfh_in.get_presc_time_task_line', g_package_name, l_db_object_name);
            pk_alertlog.log_debug('i_rowids.count = ' || i_rowids.count, g_package_name, l_db_object_name);
            pk_alertlog.log_debug('i_rowids(1) = ' || i_rowids(1), g_package_name, l_db_object_name);
        
            ----------------------------------------------------------------------
            -- fetch presc_data cursor elements
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                BEGIN
                    pk_alertlog.log_debug('inside FETCH c_presc_data BULK COLLECT', g_package_name, l_db_object_name);
                    g_error := ' FETCH c_presc_data ';
                    FETCH c_presc_data BULK COLLECT
                        INTO --
                             l_id_presc,
                             l_id_patient,
                             l_id_episode,
                             l_id_institution,
                             l_dt_req,
                             l_id_prof_req,
                             l_dt_begin,
                             l_dt_end,
                             l_id_workflow,
                             l_id_status,
                             l_universal_description,
                             l_flg_sos,
                             l_flg_active,
                             l_dt_last_execution,
                             l_flg_has_comments,
                             l_dt_last_update,
                             l_id_presc_parent,
                             l_flg_chinese,
                             l_flg_type,
                             l_flg_stat;
                    CLOSE c_presc_data;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE g_excp_invalid_data;
                END;
            END IF;
        
            -- verify if the query returned some data
            IF l_id_presc.count = 0
               OR l_id_presc IS NULL
            THEN
                /* log: to delete */
                pk_alertlog.log_debug('l_id_presc.count = 0 ; no presc found meeting the necessary requirements, so exiting function',
                                      g_package_name,
                                      l_db_object_name);
                RETURN;
            END IF;
        
            ----------------------------------------------------------------------
            -- loop through returned presc data
            FOR i IN 1 .. l_id_presc.last
            LOOP
                pk_alertlog.log_debug('l_id_presc(' || i || ')= ' || l_id_presc(i) || ' / l_id_patient(' || i || ')= ' ||
                                      l_id_patient(i),
                                      g_package_name,
                                      l_db_object_name);
            
                IF l_id_patient(i) IS NULL
                   OR l_id_presc(i) IS NULL
                THEN
                    -- do nothing
                    NULL;
                ELSE
                    ----------------------------------------------------------------------
                    -- insert presc data into time line record to be processed
                    g_error := ' define NEW RECORD FOR task_timeline_ea id_workflow: ' || l_id_workflow(i);
                    pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
                    IF l_id_workflow(i) = pk_api_pfh_in.g_wf_report
                    THEN
                        pk_alertlog.log_debug('l_flg_chinese(i): ' || l_flg_chinese(i));
                        -- Home Medication
                        IF (l_flg_chinese(i) = pk_alert_constant.g_yes)
                        THEN
                            l_new_rec_row.id_tl_task := pk_prog_notes_constants.g_task_home_med_chinese;
                        ELSE
                            l_new_rec_row.id_tl_task := pk_prog_notes_constants.g_task_reported_medic;
                        END IF;
                    
                        l_flg_ongoing := CASE
                                             WHEN l_id_status(i) IN (pk_rt_med_pfh.st_inactive, pk_rt_med_pfh.st_inactive_gen_auto) THEN
                                              pk_prog_notes_constants.g_task_inactive_i
                                             WHEN l_id_status(i) IN
                                                  (pk_rt_med_pfh.st_active, pk_rt_med_pfh.st_active_gen_auto, pk_rt_med_pfh.st_unknown) THEN
                                              pk_prog_notes_constants.g_task_ongoing_o
                                             ELSE
                                              pk_prog_notes_constants.g_task_ongoing_o
                                         END;
                    
                    ELSIF l_id_workflow(i) IN (pk_api_pfh_in.g_wf_institution, pk_api_pfh_in.g_wf_iv)
                    THEN
                        -- Local Medication
                        l_new_rec_row.id_tl_task := pk_prog_notes_constants.g_task_medic_here;
                    
                        l_flg_ongoing := CASE l_id_status(i)
                                             WHEN pk_rt_med_pfh.st_on_going THEN
                                              pk_prog_notes_constants.g_task_ongoing_o
                                             WHEN pk_rt_med_pfh.st_prescribed THEN
                                              pk_prog_notes_constants.g_task_ongoing_o
                                             WHEN pk_rt_med_pfh.g_wf_presc_concluded THEN
                                              pk_prog_notes_constants.g_task_finalized_f
                                             WHEN pk_rt_med_pfh.st_inactive THEN
                                              pk_prog_notes_constants.g_task_inactive_i
                                             ELSE
                                              pk_prog_notes_constants.g_task_ongoing_o
                                         END;
                    ELSE
                        -- Exterior (Ambulatory) Medication
                        l_new_rec_row.id_tl_task := pk_prog_notes_constants.g_task_amb_medication;
                    
                        l_flg_ongoing := CASE l_id_status(i)
                                             WHEN pk_rt_med_pfh.st_concluded THEN
                                              pk_prog_notes_constants.g_task_finalized_f
                                             ELSE
                                              pk_prog_notes_constants.g_task_ongoing_o
                                         END;
                    END IF;
                
                    pk_alertlog.log_debug(' id_tl_task: ' || l_new_rec_row.id_tl_task,
                                          g_package_name,
                                          l_db_object_name);
                
                    l_new_rec_row.table_name        := i_source_table_name;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                    --
                    l_new_rec_row.id_task_refid        := l_id_presc(i);
                    l_new_rec_row.id_parent_task_refid := l_id_presc_parent(i);
                    l_new_rec_row.dt_req               := l_dt_req(i);
                    l_new_rec_row.dt_begin             := l_dt_begin(i);
                    l_new_rec_row.dt_end               := l_dt_end(i);
                    l_new_rec_row.flg_status_req       := l_id_status(i); --l_id_workflow(i) || ' . ' || l_id_status(i);
                    l_new_rec_row.flg_type_viewer      := 'DP';
                    --
                    l_new_rec_row.id_prof_req    := l_id_prof_req(i);
                    l_new_rec_row.id_patient     := l_id_patient(i);
                    l_new_rec_row.id_episode     := l_id_episode(i);
                    l_new_rec_row.id_visit       := pk_visit.get_visit(l_id_episode(i), l_error_out);
                    l_new_rec_row.id_institution := l_id_institution(i);
                    --
                    l_new_rec_row.code_description  := NULL; --l_id_presc(i);
                    l_new_rec_row.dt_last_execution := l_dt_last_execution(i);
                    l_new_rec_row.flg_has_comments  := l_flg_has_comments(i);
                
                    l_new_rec_row.code_status    := 'WF_STATUS.CODE_STATUS.' || l_id_status(i);
                    l_new_rec_row.flg_sos        := l_flg_sos(i);
                    l_new_rec_row.flg_ongoing    := l_flg_ongoing;
                    l_new_rec_row.flg_normal     := pk_alert_constant.g_yes;
                    l_new_rec_row.dt_last_update := l_dt_last_update(i);
                    l_new_rec_row.flg_stat       := l_flg_stat(i);
                    l_new_rec_row.flg_type       := l_flg_type(i);
                    IF l_id_workflow(i) = pk_api_pfh_in.g_wf_report
                    THEN
                        --Home Medication
                        g_error := ' check status0 l_id_status(i): ' || l_id_status(i);
                        pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
                        --Only Active and Unknown status are to include
                        IF l_id_status(i) IN (pk_rt_med_pfh.st_active,
                                              pk_rt_med_pfh.st_active_gen_auto,
                                              pk_rt_med_pfh.st_unknown,
                                              pk_rt_med_pfh.st_inactive,
                                              pk_rt_med_pfh.st_inactive_gen_auto)
                        THEN
                            l_flg_calc_active          := pk_alert_constant.g_yes;
                            l_new_rec_row.flg_outdated := CASE
                                                              WHEN l_flg_active(i) = pk_alert_constant.g_no THEN
                                                               l_flg_outdated
                                                              ELSE
                                                               l_flg_not_outdated
                                                          END;
                        ELSE
                            -- if cancelled or discontinued then it's not active
                            l_flg_calc_active          := pk_alert_constant.g_no;
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    ELSIF l_id_workflow(i) IN (pk_api_pfh_in.g_wf_institution, pk_api_pfh_in.g_wf_iv)
                    THEN
                        -- Local Medication
                        g_error := ' check status l_id_status(i): ' || l_id_status(i);
                        pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
                        IF l_id_status(i) IN (pk_rt_med_pfh.st_on_going,
                                              pk_rt_med_pfh.st_prescribed_pharm_req,
                                              pk_rt_med_pfh.st_prescribed,
                                              pk_rt_med_pfh.st_suspended,
                                              pk_rt_med_pfh.st_suspended_ongoing,
                                              pk_rt_med_pfh.st_suspended_pharm_req,
                                              pk_rt_med_pfh.st_ongoing_pharm_req,
                                              pk_rt_med_pfh.st_suspended_ongoing_pharm_req,
                                              pk_rt_med_pfh.st_requested,
                                              pk_rt_med_pfh.g_wf_presc_concluded,
                                              pk_rt_med_pfh.g_wf_presc_conditional_order)
                        THEN
                            l_flg_calc_active          := pk_alert_constant.g_yes;
                            l_new_rec_row.flg_outdated := CASE
                                                              WHEN l_flg_active(i) = pk_alert_constant.g_no THEN
                                                               l_flg_outdated
                                                              ELSE
                                                               l_flg_not_outdated
                                                          END;
                        ELSE
                            -- otherwise
                            l_flg_calc_active          := pk_alert_constant.g_no;
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    ELSE
                        -- Exterior (Ambulatory) Medication
                        g_error := ' check status2 l_id_status(i): ' || l_id_status(i);
                        pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
                        IF l_id_status(i) IN
                           (pk_rt_med_pfh.st_cancelled, pk_rt_med_pfh.st_temp_edition, pk_rt_med_pfh.st_pre_defined)
                        THEN
                            l_flg_calc_active          := pk_alert_constant.g_no;
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        
                        ELSE
                            l_flg_calc_active          := pk_alert_constant.g_yes;
                            l_new_rec_row.flg_outdated := CASE
                                                              WHEN l_flg_active(i) = pk_alert_constant.g_no THEN
                                                               l_flg_outdated
                                                              ELSE
                                                               l_flg_not_outdated
                                                          END;
                        END IF;
                    END IF;
                
                    ----------------------------------------------------------------------
                    -- (we don' t want to consider canceled, interrupted AND suspended medications)
                    -- if record is not active or is SOS then DELETE it
                    g_error := 'l_flg_calc_active: ' || l_flg_calc_active;
                    pk_alertlog.log_debug(g_error, g_package_name, l_db_object_name);
                    IF (l_flg_calc_active = pk_alert_constant.g_no) -- OR l_flg_sos(i) = pk_api_pfh_in.g_presc_take_sos)
                    THEN
                        -------------------------------------
                        -- Information in status that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := t_data_gov_mnt.g_event_delete;
                    
                        pk_alertlog.log_debug('Processing DELETE ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                              l_name_table_ea || '): ' || g_error,
                                              g_package_name,
                                              l_func_proc_name);
                    
                    ELSE
                        -------------------------------------
                        -- search for updated record
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = l_new_rec_row.table_name
                           AND tte.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -------------------------------------
                        -- iF exists one record, information should be UPDATED in TASK_TIMELINE_EA table for this record
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := t_data_gov_mnt.g_event_update;
                        
                            pk_alertlog.log_debug('Processing UPDATE ' || l_process_name || ' on ' ||
                                                  i_source_table_name || ' (' || l_name_table_ea || '): ' || g_error,
                                                  g_package_name,
                                                  l_func_proc_name);
                        
                        ELSE
                            -------------------------------------
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that record
                            l_process_name  := 'INSERT';
                            l_event_into_ea := t_data_gov_mnt.g_event_insert;
                        
                            pk_alertlog.log_debug('Processing INSERT ' || l_process_name || ' on ' ||
                                                  i_source_table_name || ' (' || l_name_table_ea || '): ' || g_error,
                                                  g_package_name,
                                                  l_func_proc_name);
                        
                        END IF;
                    END IF;
                
                    --------------------------------------------------------------------
                    -- delete from task_timeline_ea
                    IF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.del_by';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task);
                    ELSE
                        IF (l_flg_calc_active = pk_alert_constant.g_yes)
                        THEN
                            -- insert or update task_timeline_ea
                            IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                            THEN
                                g_error := 'CALL ts_task_timeline_ea.ins';
                                ts_task_timeline_ea.ins(rec_in => l_new_rec_row);
                            ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                            THEN
                                g_error := 'CALL ts_task_timeline_ea.upd';
                                ts_task_timeline_ea.upd(rec_in => l_new_rec_row);
                            END IF;
                        END IF;
                    END IF;
                    --------------------------------------------------------------------
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_alertlog.log_debug('Processing error ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
    END set_presc_task_time_line;

    /**
    * Process insert/update events on PRESC_NOTES_ITEM into TASK_TIMELINE_EA
    * (prescription comment tasks).
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
    * @since                2012/05/02
    */
    PROCEDURE set_presc_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PRESC_NOTES';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'PRESC_NOTES_ITEM';
        l_ea_row     task_timeline_ea%ROWTYPE;
        l_ea_rows    ts_task_timeline_ea.task_timeline_ea_tc;
        l_cursor     pk_types.cursor_type;
        l_presc_tbl  table_number;
        l_pat_tbl    table_number;
        l_epis_tbl   table_number;
        l_inst_tbl   table_number;
        l_pnotes_tbl table_number;
        l_pnitem_tbl table_number;
        l_dt_req_tbl table_timestamp_tz;
        l_prof_tbl   table_number;
        l_notes_tbl  table_varchar;
        l_rn         table_number;
        l_visit      task_timeline_ea.id_visit%TYPE;
        l_error      t_error_out;
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
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            -- get notes data from rowids
            g_error := 'CALL pk_api_pfh_in.get_presc_notes_ttl';
            pk_api_pfh_in.get_presc_notes_ttl(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_rowids     => i_rowids,
                                              o_notes_info => l_cursor);
        
            FETCH l_cursor BULK COLLECT
                INTO l_presc_tbl,
                     l_pat_tbl,
                     l_epis_tbl,
                     l_inst_tbl,
                     l_pnotes_tbl,
                     l_pnitem_tbl,
                     l_dt_req_tbl,
                     l_prof_tbl,
                     l_notes_tbl,
                     l_rn;
            CLOSE l_cursor;
        
            -- copy notes data into rows collection
            IF l_presc_tbl IS NOT NULL
               AND l_presc_tbl.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_medication_comments;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_outdated      := pk_ea_logic_tasktimeline.g_flg_outdated;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_ongoing       := pk_prog_notes_constants.g_task_ongoing_o;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
                l_ea_row.dt_last_update    := g_sysdate_tstz;
            
                -- set variable fields
                FOR i IN l_presc_tbl.first .. l_presc_tbl.last
                LOOP
                    IF l_pat_tbl(i) IS NOT NULL
                    THEN
                    
                        IF l_epis_tbl(i) IS NOT NULL
                        THEN
                        
                            l_visit := pk_episode.get_id_visit(i_episode => l_epis_tbl(i));
                        
                            l_ea_row.id_task_refid       := l_pnitem_tbl(i);
                            l_ea_row.id_patient          := l_pat_tbl(i);
                            l_ea_row.id_episode          := l_epis_tbl(i);
                            l_ea_row.id_visit            := l_visit;
                            l_ea_row.id_institution      := l_inst_tbl(i);
                            l_ea_row.dt_req              := l_dt_req_tbl(i);
                            l_ea_row.id_prof_req         := l_prof_tbl(i);
                            l_ea_row.universal_desc_clob := to_clob(l_notes_tbl(i));
                            l_ea_row.id_parent_comments  := l_presc_tbl(i);
                            -- add row to rows collection
                            l_ea_rows(i) := l_ea_row;
                        END IF;
                    END IF;
                END LOOP;
            
                IF l_ea_rows.count > 0
                THEN
                
                    -- add rows collection to easy access
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.ins';
                        ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                    ELSIF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'CALL ts_task_timeline_ea.upd';
                        ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE);
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
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END set_presc_notes;

    /********************************************************************************************
    * Procedure to update task_timeline_ea with information regarding reconciliation information
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               The episode id
    * @param   I_ID_PATIENT               The patient id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Pedro Teixeira
    * @version                            2.6.2
    *
    **********************************************************************************************/
    FUNCTION update_task_tl_recon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN episode.id_patient%TYPE,
        i_id_presc        IN NUMBER,
        i_dt_req          IN episode.dt_begin_tstz%TYPE,
        i_id_prof_req     IN episode.id_prof_cancel%TYPE,
        i_id_institution  IN episode.id_institution%TYPE,
        i_event_type      IN VARCHAR2,
        i_id_tl_task      IN NUMBER,
        i_id_prev_tl_task IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ea_row    task_timeline_ea%ROWTYPE;
        l_error_out t_error_out;
    BEGIN
        -- if it's update then delete the old rec first, then create a new one
        IF i_event_type IN (t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_insert)
        THEN
            g_error := 'CALL ts_task_timeline_ea.del';
            IF (i_id_tl_task IN (pk_prog_notes_constants.g_task_medrec_cont_home_hm,
                                 pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm,
                                 pk_prog_notes_constants.g_task_medrec_cont_hospital_hm,
                                 pk_prog_notes_constants.g_task_medrec_discontinue_hm))
            THEN
                ts_task_timeline_ea.del_by(where_clause_in => ' id_task_refid = ' || i_id_presc ||
                                                              ' and id_tl_task in (' ||
                                                              pk_prog_notes_constants.g_task_medrec_cont_home_hm || ',' ||
                                                              pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm || ',' ||
                                                              pk_prog_notes_constants.g_task_medrec_cont_hospital_hm || ',' ||
                                                              pk_prog_notes_constants.g_task_medrec_discontinue_hm || ')');
            ELSIF (i_id_tl_task IN (pk_prog_notes_constants.g_task_medrec_cont_home_lm,
                                    pk_prog_notes_constants.g_task_medrec_cont_hospital_lm,
                                    pk_prog_notes_constants.g_task_medrec_discontinue_lm))
            THEN
                ts_task_timeline_ea.del_by(where_clause_in => ' id_task_refid = ' || i_id_presc ||
                                                              ' and id_tl_task in (' ||
                                                              pk_prog_notes_constants.g_task_medrec_cont_home_lm || ',' ||
                                                              pk_prog_notes_constants.g_task_medrec_cont_hospital_lm || ',' ||
                                                              pk_prog_notes_constants.g_task_medrec_discontinue_lm || ')');
            END IF;
        END IF;
    
        l_ea_row.id_tl_task       := i_id_tl_task;
        l_ea_row.table_name       := 'PRESC';
        l_ea_row.flg_show_method  := pk_alert_constant.g_tl_oriented_visit;
        l_ea_row.flg_sos          := pk_alert_constant.g_no;
        l_ea_row.flg_ongoing      := pk_prog_notes_constants.g_task_ongoing_o;
        l_ea_row.flg_normal       := pk_alert_constant.g_yes;
        l_ea_row.flg_has_comments := pk_alert_constant.g_no;
    
        l_ea_row.id_task_refid     := i_id_presc;
        l_ea_row.id_patient        := i_id_patient;
        l_ea_row.id_episode        := i_id_episode;
        l_ea_row.id_visit          := pk_visit.get_visit(i_id_episode, l_error_out);
        l_ea_row.id_institution    := i_id_institution;
        l_ea_row.dt_req            := i_dt_req;
        l_ea_row.id_prof_req       := i_id_prof_req;
        l_ea_row.dt_last_update    := i_dt_req;
        l_ea_row.dt_dg_last_update := current_timestamp;
        l_ea_row.flg_outdated      := pk_ea_logic_tasktimeline.g_flg_not_outdated;
    
        -- add rows collection to easy access
        g_error := 'CALL ts_task_timeline_ea.upd_ins';
        ts_task_timeline_ea.upd_ins(id_tl_task_in        => l_ea_row.id_tl_task,
                                    table_name_in        => l_ea_row.table_name,
                                    flg_show_method_in   => l_ea_row.flg_show_method,
                                    dt_dg_last_update_in => l_ea_row.dt_dg_last_update,
                                    flg_sos_in           => l_ea_row.flg_sos,
                                    flg_ongoing_in       => l_ea_row.flg_ongoing,
                                    flg_normal_in        => l_ea_row.flg_normal,
                                    flg_has_comments_in  => l_ea_row.flg_has_comments,
                                    id_task_refid_in     => l_ea_row.id_task_refid,
                                    id_patient_in        => l_ea_row.id_patient,
                                    id_episode_in        => l_ea_row.id_episode,
                                    id_visit_in          => l_ea_row.id_visit,
                                    id_institution_in    => l_ea_row.id_institution,
                                    dt_req_in            => l_ea_row.dt_req,
                                    id_prof_req_in       => l_ea_row.id_prof_req,
                                    dt_last_update_in    => l_ea_row.dt_last_update,
                                    flg_outdated_in      => l_ea_row.flg_outdated,
                                    handle_error_in      => TRUE);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TASK_TL_RECON',
                                              o_error);
    END update_task_tl_recon;

    /********************************************************************************
    * Name:                           UPDATE_PRESC_LIST_JOBS
    * Description:                    Updates presc_list_jobs for the cancelled prescriptions
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Pedro Teixeira
    * @since                          17/10/2014
    ********************************************************************************/
    PROCEDURE update_presc_list_jobs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PK_EA_LOGIC_MEDICATION.UPDATE_PRESC_LIST_JOBS';
        l_name_table_ea VARCHAR2(30) := 'PRESC_LIST_JOB';
        l_error_out     t_error_out;
    
        ---------------------------
        l_print_list_jobs     table_number := table_number();
        l_out_print_list_jobs table_number := table_number();
        l_id_print_list_job   print_list_job.id_print_list_job%TYPE;
        l_presc_pl_count      NUMBER;
    
        l_id_patient      patient.id_patient%TYPE;
        l_id_episode      episode.id_episode%TYPE;
        l_print_list_area NUMBER;
        l_id_workflow     table_number := table_number();
        l_id_presc        table_number := table_number();
    BEGIN
        -- Process update event
        -- delete and insert aren't necessary to process, only update to cancel/discontinue
        IF nvl(cardinality(i_rowids), 0) != 0
           AND i_event_type = t_data_gov_mnt.g_event_update
        THEN
            pk_alertlog.log_debug('Detected ' || i_event_type || ' ON ' || i_source_table_name || '(' ||
                                  l_name_table_ea || ') ',
                                  g_package_name,
                                  l_db_object_name);
        
            ----------------------------------------------------------------------
            -- obtain prescription print list data
            IF NOT pk_api_pfh_in.get_presc_print_list_data(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_rowids          => i_rowids,
                                                           o_id_patient      => l_id_patient,
                                                           o_id_episode      => l_id_episode,
                                                           o_print_list_area => l_print_list_area,
                                                           o_id_workflow     => l_id_workflow,
                                                           o_id_presc        => l_id_presc,
                                                           o_error           => l_error_out)
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- verify cardinality to see if data was returned
            IF nvl(cardinality(l_id_presc), 0) = 0
               OR l_id_patient IS NULL
            THEN
                -- no data found, so return
                RETURN;
            END IF;
        
            ----------------------------------------------------------------------
            -- loop through returned presc data
            FOR i IN 1 .. l_id_presc.last
            LOOP
                -- verify if presc_list context contains the presc that was changed
                l_presc_pl_count := 0;
                BEGIN
                    SELECT v.id_print_list_job, dbms_lob.instr(v.context_data, l_id_presc(i))
                      INTO l_id_print_list_job, l_presc_pl_count
                      FROM v_print_list_context_data v
                     WHERE v.id_patient = l_id_patient
                       AND v.id_episode = l_id_episode
                       AND v.id_print_list_area = l_print_list_area;
                EXCEPTION
                    WHEN OTHERS THEN
                        -- no records found, so no print list job exists
                        l_presc_pl_count := 0;
                        NULL;
                END;
            
                -- if presc found add print list job to the list
                IF l_presc_pl_count != 0
                THEN
                    l_print_list_jobs.extend;
                    l_print_list_jobs(l_print_list_jobs.last) := l_id_print_list_job;
                END IF;
            END LOOP;
        
            ----------------------------------------------------------------------
            IF nvl(cardinality(l_print_list_jobs), 0) != 0
            THEN
                -- means the presc was found
                g_error := 'Call pk_print_list_db.set_print_jobs_cancel from pk_api_pfh_out.remove_print_jobs';
                IF NOT pk_print_list_db.set_print_jobs_cancel(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_id_print_list_job => l_print_list_jobs,
                                                              o_id_print_list_job => l_out_print_list_jobs,
                                                              o_error             => l_error_out)
                THEN
                    RAISE g_exception_np;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END update_presc_list_jobs;

    /********************************************************************************
    * Name:                           UPDATE_LIST_JOB_PRESCS
    * Description:                    Updates prescription group for terminated presc_list_jobs
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Pedro Teixeira
    * @since                          20/10/2014
    ********************************************************************************/
    PROCEDURE update_list_job_prescs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'PK_EA_LOGIC_MEDICATION.UPDATE_LIST_JOB_PRESCS';
        l_name_table_ea VARCHAR2(30) := 'PRESC_LIST_JOB';
        l_error_out     t_error_out;
    
        ---------------------------
        l_id_print_list_jobs      print_list_job.id_print_list_job%TYPE;
        l_id_print_list_jobs_hist print_list_job_hist.id_print_list_job_hist%TYPE;
        l_context_data            print_list_job_hist.context_data%TYPE;
        l_id_status               print_list_job_hist.id_status%TYPE;
    
        l_context_data_elements table_varchar := table_varchar();
        l_id_presc              table_number := table_number();
        l_presc_list            table_number := table_number();
    
        l_delim       VARCHAR2(1 CHAR) := '|';
        l_delim_presc VARCHAR2(1 CHAR) := ',';
        l_action_type VARCHAR2(1 CHAR);
    
    BEGIN
        ----------------------------------------------------------------------
        -- Process insert event
        -- only insert events are necessary to validate, because hist table does not have update and delete
        IF nvl(cardinality(i_rowids), 0) != 0
           AND i_event_type = t_data_gov_mnt.g_event_insert
        THEN
            FOR k IN i_rowids.first .. i_rowids.last
            LOOP
                pk_alertlog.log_debug('Detected ' || i_event_type || ' ON ' || i_source_table_name || '(' ||
                                      l_name_table_ea || ') ',
                                      g_package_name,
                                      l_db_object_name);
            
                BEGIN
                    SELECT pljh.id_print_list_job, pljh.id_print_list_job_hist, pljh.context_data, pljh.id_status
                      INTO l_id_print_list_jobs, l_id_print_list_jobs_hist, l_context_data, l_id_status
                      FROM v_print_list_job_hist pljh
                     WHERE pljh.id_print_list_area = pk_print_list_db.g_print_list_area_med
                       AND pljh.rowid = i_rowids(k)
                       AND pljh.id_status IN (pk_print_list_db.g_id_sts_completed,
                                              pk_print_list_db.g_id_sts_canceled,
                                              pk_print_list_db.g_id_sts_error);
                EXCEPTION
                    WHEN no_data_found THEN
                        -- nothing to do, just return
                        RETURN;
                END;
            
                ----------------------------------------------------------------------
                -- split context data
                l_context_data_elements := pk_utils.str_split_l(i_list => l_context_data, i_delim => l_delim);
                l_presc_list            := table_number();
            
                -- obtain presc ids
                IF l_context_data_elements.count >= 2 -- at least two elements needed: id_workflow | list_of_id_prescs
                THEN
                    l_id_presc := pk_utils.str_split_n(i_list => l_context_data_elements(2), i_delim => l_delim_presc); -- prescs separated by ','
                    IF nvl(cardinality(l_id_presc), 0) != 0
                    THEN
                        FOR j IN l_id_presc.first .. l_id_presc.last
                        LOOP
                            l_presc_list.extend;
                            l_presc_list(l_presc_list.last) := l_id_presc(j);
                        END LOOP;
                    END IF;
                    l_id_presc := table_number();
                END IF;
            
                --
                CASE l_id_status
                    WHEN pk_print_list_db.g_id_sts_completed THEN
                        l_action_type := 'A';
                    WHEN pk_print_list_db.g_id_sts_canceled THEN
                        l_action_type := 'C';
                    ELSE
                        l_action_type := 'C';
                END CASE;
            
                ----------------------------------------------------------------------
                IF nvl(cardinality(l_presc_list), 0) != 0
                THEN
                    -- call medication function to finalize active presc_groups
                    IF NOT pk_api_pfh_in.update_list_job_prescs(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_id_presc    => l_presc_list,
                                                                i_action_type => l_action_type,
                                                                o_error       => l_error_out)
                    THEN
                        RAISE g_exception_np;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END update_list_job_prescs;

    /********************************************************************************
    * Get new print arguments to the reports that need to be regenerated
    * Used by reports (pk_print_tool) when sending report to the printer (after selecting print button)    
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   io_print_arguments          Json string to be printed
    * @param   o_flg_regenerate_report     Flag indicating if the report needs to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @RETURN  boolean                     TRUE if sucess, FALSE otherwise
    *
    * @author  Pedro teixeira
    * @since   29-10-2014
    ********************************************************************************/
    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        io_print_arguments      IN OUT print_list_job.print_arguments%TYPE,
        o_flg_regenerate_report OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(40 CHAR) := 'get_print_args_to_regen_report';
        l_params VARCHAR2(1000 CHAR);
        l_json   json_object_t;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        pk_alertlog.log_debug(g_error);
        o_flg_regenerate_report := pk_ref_constant.g_no;
    
        -- func
        -- search for parameter 'PRINT_TYPE'
        l_json := json_object_t(io_print_arguments);
        IF l_json.has('FLG_PRINTABLE')
        THEN
            -- if found, replace value of parameter PRINT_TYPE by 1
            g_error := 'Set FLG_PRINTABLE=1 / ' || l_params;
            l_json.put('FLG_PRINTABLE', 1);
            o_flg_regenerate_report := pk_ref_constant.g_yes;
            io_print_arguments      := l_json.to_string();
        ELSE
            -- parameter not found, do not re-generate the report
            g_error                 := 'No FLG_PRINTABLE found / ' || l_params;
            o_flg_regenerate_report := pk_ref_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_print_args_to_regen_report;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_medication;
/
