/*-- Last Change Revision: $Rev: 2027049 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_problems IS

    -- Private type declarations
    -- Private constant declarations    
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /*******************************************************************************************************************************************
    * Name:                           set_tl_PROBLEMS
    * Description:                    Function that updates past history information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         paulo teixeira
    * @version                        2.6.2.1.5
    * @since                          18/07/2012
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_problems
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROBLEMS';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
        o_rowids         table_varchar;
        l_error_out      t_error_out;
    
        l_dup_del VARCHAR2(4000);
    
        l_get_phd_ids    table_number := table_number();
        l_count          NUMBER(12);
        l_id_pat_problem pat_problem.id_pat_problem%TYPE;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT phd.id_pat_history_diagnosis,
                                     phd.id_episode,
                                     phd.dt_pat_history_diagnosis_tstz dt_req,
                                     phd.flg_status,
                                     phd.id_professional id_prof_request,
                                     phd.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     CASE
                                          WHEN phd.flg_status IN (pk_problems.g_pat_probl_active) THEN
                                           pk_prog_notes_constants.g_task_ongoing_o
                                          WHEN phd.flg_status IN (pk_problems.g_pat_probl_resolved) THEN
                                           pk_prog_notes_constants.g_task_finalized_f
                                          WHEN phd.flg_status IN (pk_problems.g_pat_probl_passive) THEN
                                           pk_prog_notes_constants.g_task_inactive_i
                                          ELSE
                                           pk_prog_notes_constants.g_task_ongoing_o
                                      END flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     phd.id_diagnosis,
                                     pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status) rank,
                                     phd.flg_recent_diag,
                                     phd.dt_diagnosed,
                                     phd.dt_diagnosed_precision
                                FROM pat_history_diagnosis phd
                                LEFT JOIN alert_diagnosis ad
                                  ON phd.id_alert_diagnosis = ad.id_alert_diagnosis
                                LEFT JOIN diagnosis d
                                  ON phd.id_diagnosis = d.id_diagnosis
                                LEFT JOIN episode e
                                  ON e.id_episode = phd.id_episode
                               WHERE phd.rowid IN (SELECT vc_1
                                                     FROM tbl_temp)
                                 AND phd.flg_type = pk_problems.g_flg_type_med
                                 AND phd.flg_status NOT IN
                                     (pk_past_history.g_pat_hist_diag_none,
                                      pk_past_history.g_pat_hist_diag_non_remark,
                                      pk_past_history.g_pat_hist_diag_unknown)
                                 AND phd.id_pat_history_diagnosis =
                                     pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                                 AND phd.flg_area IN
                                     (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)
                                    
                                 AND NOT EXISTS
                               (SELECT 1
                                        FROM pat_problem pp
                                        JOIN epis_diagnosis ed
                                          ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                                        LEFT JOIN diagnosis d1
                                          ON pp.id_diagnosis = d1.id_diagnosis
                                       WHERE pp.id_diagnosis = d.id_diagnosis
                                         AND pp.id_patient = phd.id_patient
                                         AND pp.id_habit IS NULL
                                         AND nvl(d1.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                                         AND ( --final diagnosis 
                                              (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                              OR -- differencial diagnosis only 
                                              (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                              ed.id_diagnosis NOT IN
                                              (SELECT ed3.id_diagnosis
                                                  FROM epis_diagnosis ed3
                                                 WHERE ed3.id_diagnosis = ed.id_diagnosis
                                                   AND ed3.id_patient = pp.id_patient
                                                   AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                                         AND pp.flg_status <> pk_problems.g_pat_probl_invest
                                         AND pp.dt_pat_problem_tstz > phd.dt_pat_history_diagnosis_tstz
                                         AND rownum = 1))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_problems;
                    l_new_rec_row.table_name        := pk_prog_notes_constants.g_tl_table_name_ph_diag;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid    := r_cur.id_pat_history_diagnosis;
                    l_new_rec_row.dt_begin := CASE
                                                  WHEN r_cur.dt_diagnosed_precision IS NOT NULL
                                                       AND r_cur.dt_diagnosed_precision <> pk_problems.g_unknown THEN
                                                   r_cur.dt_diagnosed
                                                  ELSE
                                                   NULL
                                              END;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    l_new_rec_row.rank             := r_cur.rank;
                
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF ((r_cur.flg_status <> pk_past_history.g_pat_hist_diag_canceled AND
                       r_cur.flg_recent_diag <> pk_alert_constant.g_no) OR r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF (r_cur.flg_status = pk_past_history.g_pat_hist_diag_canceled OR
                          r_cur.flg_recent_diag = pk_alert_constant.g_no)
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                    --Now we will remove duplicated problems - outdated problems
                    g_error := 'REMOVE DUPLICATED PROBLEMS FROM TASK_TIMELINE_EA id_task_refid: ' ||
                               l_new_rec_row.id_task_refid;
                    pk_alertlog.log_debug(g_error);
                
                    l_get_phd_ids := pk_problems.get_phd_ids(l_new_rec_row.id_task_refid);
                    l_get_phd_ids := pk_utils.remove_element(l_get_phd_ids, l_new_rec_row.id_task_refid);
                
                    IF l_get_phd_ids.count > 0
                    THEN
                    
                        l_dup_del := 'id_task_refid in (' || pk_utils.concat_table(l_get_phd_ids, ',', 1, -1) || ')
                                  AND id_tl_task = ' || l_new_rec_row.id_tl_task;
                    
                        pk_alertlog.log_debug('where_clause_in => ' || l_dup_del);
                    
                        ts_task_timeline_ea.del_by(where_clause_in => l_dup_del, rows_out => o_rowids);
                    
                    END IF;
                
                    --Now we will remove duplicated problems vs diagnosis
                    g_error := 'REMOVE DUPLICATED PROBLEMS vs DIAGNOSIS';
                    pk_alertlog.log_debug(g_error);
                
                    BEGIN
                        SELECT pp.id_pat_problem
                          INTO l_id_pat_problem
                          FROM pat_problem pp
                          JOIN epis_diagnosis ed
                            ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                          LEFT JOIN diagnosis d1
                            ON pp.id_diagnosis = d1.id_diagnosis
                         WHERE pp.id_diagnosis = r_cur.id_diagnosis
                           AND pp.id_patient = r_cur.id_patient
                           AND pp.id_habit IS NULL
                           AND nvl(d1.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                           AND ( --final diagnosis 
                                (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                OR -- differencial diagnosis only 
                                (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                ed.id_diagnosis NOT IN
                                (SELECT ed3.id_diagnosis
                                    FROM epis_diagnosis ed3
                                   WHERE ed3.id_diagnosis = ed.id_diagnosis
                                     AND ed3.id_patient = pp.id_patient
                                     AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                           AND pp.flg_status <> pk_problems.g_pat_probl_invest
                           AND pp.dt_pat_problem_tstz < r_cur.dt_req
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_pat_problem := NULL;
                    END;
                
                    SELECT COUNT(1)
                      INTO l_count
                      FROM task_timeline_ea tt
                     WHERE tt.id_task_refid = l_id_pat_problem
                       AND tt.id_tl_task = pk_prog_notes_constants.g_task_problems_diag;
                
                    IF l_count > 0
                    THEN
                        l_dup_del := 'id_task_refid = ' || l_id_pat_problem || '
                                  AND id_tl_task = ' ||
                                     pk_prog_notes_constants.g_task_problems_diag;
                    
                        pk_alertlog.log_debug('where_clause_in2 => ' || l_dup_del);
                    
                        ts_task_timeline_ea.del_by(where_clause_in => l_dup_del, rows_out => o_rowids);
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_TL_PROBLEMS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_problems;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_PROBLEMS
    * Description:                    Function that updates past history information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         paulo teixeira
    * @version                        2.6.2.1.5
    * @since                          18/07/2012
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_prob_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROB_DIAG';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
        o_rowids         table_varchar;
        l_error_out      t_error_out;
    
        l_dup_del VARCHAR2(4000);
    
        l_id_phd pat_history_diagnosis.id_pat_history_diagnosis%TYPE;
        l_count  NUMBER(12);
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT pp.id_pat_problem,
                                     pp.id_episode,
                                     pp.dt_pat_problem_tstz dt_req,
                                     pp.flg_status,
                                     pp.id_professional_ins id_prof_request,
                                     pp.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     pp.year_begin,
                                     pp.month_begin,
                                     pp.day_begin,
                                     CASE
                                          WHEN pp.flg_status IN (pk_problems.g_pat_probl_active) THEN
                                           pk_prog_notes_constants.g_task_ongoing_o
                                          WHEN pp.flg_status IN (pk_problems.g_pat_probl_resolved) THEN
                                           pk_prog_notes_constants.g_task_finalized_f
                                          WHEN pp.flg_status IN (pk_problems.g_pat_probl_passive) THEN
                                           pk_prog_notes_constants.g_task_inactive_i
                                          ELSE
                                           pk_prog_notes_constants.g_task_ongoing_o
                                      END flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     pp.id_diagnosis
                                FROM pat_problem pp
                                LEFT JOIN diagnosis d
                                  ON pp.id_diagnosis = d.id_diagnosis
                                JOIN epis_diagnosis ed
                                  ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                                LEFT JOIN episode e
                                  ON e.id_episode = pp.id_episode
                               WHERE pp.rowid IN (SELECT vc_1
                                                    FROM tbl_temp)
                                    --AND nvl(d.flg_type, 'Y') <> pk_diagnosis.g_diag_type_x
                                 AND ( --final diagnosis 
                                      (ed.flg_type = pk_diagnosis.g_diag_type_d) --                             
                                      OR -- differencial diagnosis only 
                                      (ed.flg_type = pk_diagnosis.g_diag_type_p AND
                                      ed.id_diagnosis NOT IN
                                      (SELECT ed3.id_diagnosis
                                          FROM epis_diagnosis ed3
                                         WHERE ed3.id_diagnosis = ed.id_diagnosis
                                           AND ed3.id_patient = pp.id_patient
                                           AND ed3.flg_type = pk_diagnosis.g_diag_type_d)))
                                    --AND pp.flg_status <> pk_problems.g_pat_probl_invest
                                 AND NOT EXISTS
                               (SELECT 1
                                        FROM pat_history_diagnosis phd
                                        LEFT JOIN diagnosis d2
                                          ON d2.id_diagnosis = phd.id_diagnosis
                                       WHERE phd.id_patient = pp.id_patient
                                         AND phd.flg_type = pk_problems.g_flg_type_med
                                         AND phd.id_diagnosis = pp.id_diagnosis
                                         AND nvl(d2.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                                         AND phd.id_pat_history_diagnosis =
                                             pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                                         AND pp.dt_pat_problem_tstz < phd.dt_pat_history_diagnosis_tstz
                                         AND phd.flg_area IN (pk_alert_constant.g_diag_area_problems,
                                                              pk_alert_constant.g_diag_area_not_defined)
                                         AND rownum = 1))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_problems_diag;
                    l_new_rec_row.table_name        := pk_prog_notes_constants.g_tl_table_name_pp;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid    := r_cur.id_pat_problem;
                    l_new_rec_row.dt_begin := CASE
                                                  WHEN r_cur.year_begin IS NOT NULL
                                                       AND r_cur.year_begin <> pk_past_history.g_year_unknown
                                                       AND r_cur.month_begin IS NOT NULL
                                                       AND r_cur.day_begin IS NOT NULL THEN
                                                   to_timestamp(r_cur.year_begin || lpad(r_cur.month_begin, 2, '0') ||
                                                                lpad(r_cur.day_begin, 2, '0'),
                                                                'YYYYMMDD')
                                                  ELSE
                                                   NULL
                                              END;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    --
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF ((r_cur.flg_status NOT IN
                       (pk_past_history.g_pat_hist_diag_canceled, pk_diagnosis.g_pat_prob_excluded)) OR
                       r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status IN
                          (pk_past_history.g_pat_hist_diag_canceled, pk_diagnosis.g_pat_prob_excluded)
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                    IF (l_event_into_ea IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update))
                    THEN
                        --Now we will remove duplicated problems vs diagnosis
                        g_error := 'REMOVE DUPLICATED PROBLEMS vs DIAGNOSIS';
                        pk_alertlog.log_debug(g_error);
                    
                        BEGIN
                            SELECT phd.id_pat_history_diagnosis
                              INTO l_id_phd
                              FROM pat_history_diagnosis phd
                              LEFT JOIN diagnosis d2
                                ON d2.id_diagnosis = phd.id_diagnosis
                             WHERE phd.id_patient = r_cur.id_patient
                               AND phd.flg_type = pk_problems.g_flg_type_med
                               AND phd.id_diagnosis = r_cur.id_diagnosis
                               AND nvl(d2.flg_other, pk_alert_constant.g_no) <> pk_alert_constant.g_yes
                               AND phd.id_pat_history_diagnosis =
                                   pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                               AND r_cur.dt_req > phd.dt_pat_history_diagnosis_tstz
                               AND phd.flg_area IN
                                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)
                               AND rownum = 1;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_phd := NULL;
                        END;
                    
                        SELECT COUNT(1)
                          INTO l_count
                          FROM task_timeline_ea tt
                         WHERE tt.id_task_refid = l_id_phd
                           AND tt.id_tl_task = pk_prog_notes_constants.g_task_problems;
                    
                        IF l_count > 0
                        THEN
                            l_dup_del := 'id_task_refid = ' || l_id_phd || '
                                  AND id_tl_task = ' ||
                                         pk_prog_notes_constants.g_task_problems;
                        
                            pk_alertlog.log_debug('where_clause_in3 => ' || l_dup_del);
                        
                            ts_task_timeline_ea.del_by(where_clause_in => l_dup_del, rows_out => o_rowids);
                        END IF;
                    END IF;
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_TL_PROBLEMS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_prob_diag;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_prob_unaware
    * Description:                    Function that updates past history information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         paulo teixeira
    * @version                        2.6.2.1.5
    * @since                          2012/09/05 
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_prob_unaware
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROB_UNAWARE';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
        o_rowids         table_varchar;
        l_error_out      t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT ppu.id_pat_prob_unaware,
                                     ppu.id_episode,
                                     ppu.dt_last_update                       dt_req,
                                     ppu.flg_status,
                                     ppu.id_prof_last_update                  id_prof_request,
                                     ppu.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     pk_prog_notes_constants.g_task_ongoing_o flg_ongoing,
                                     pk_alert_constant.g_yes                  flg_normal,
                                     NULL                                     id_prof_exec
                                FROM pat_prob_unaware ppu
                                LEFT JOIN episode e
                                  ON e.id_episode = ppu.id_episode
                               WHERE ppu.rowid IN (SELECT vc_1
                                                     FROM tbl_temp)
                              
                              --
                              )
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_no_known_prob;
                    l_new_rec_row.table_name        := pk_prog_notes_constants.g_tl_table_name_pp_unaware;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_patient;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid    := r_cur.id_pat_prob_unaware;
                    l_new_rec_row.dt_begin         := NULL;
                    l_new_rec_row.dt_end           := NULL;
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF (r_cur.flg_status NOT IN (pk_problems.g_status_ppu_outdated, pk_problems.g_status_ppu_cancel) OR
                       r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status IN (pk_problems.g_status_ppu_outdated, pk_problems.g_status_ppu_cancel)
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => l_new_rec_row.dt_end,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'set_tl_prob_unaware',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_prob_unaware;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_problems_group
    * Description:                    Function that updates problems group  information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.2
    * @since                          05-12-2017
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_problems_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROBLEMS_GROUP';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_PROB_GROUP';
    
        l_process_name  VARCHAR2(30);
        l_event_into_ea VARCHAR2(1);
        l_update_reg    NUMBER(24);
        o_rowids        table_varchar;
        l_error_out     t_error_out;
    
        l_dup_del VARCHAR2(4000);
    
        l_get_phd_ids    table_number := table_number();
        l_count          NUMBER(12);
        l_id_pat_problem pat_problem.id_pat_problem%TYPE;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => l_src_table,
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT epg.id_epis_prob_group,
                                     epg.id_episode,
                                     epg.dt_epis_prob_group_tstz dt_req,
                                     epg.id_professional id_prof_request,
                                     e.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     (SELECT flg_status
                                        FROM epis_prob ep
                                       WHERE ep.id_epis_prob_group = epg.id_epis_prob_group
                                         AND rownum = 1) flg_status,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     epg.id_epis_prob_group rank
                                FROM epis_prob_group epg
                                JOIN episode e
                                  ON e.id_episode = epg.id_episode
                               WHERE epg.rowid IN (SELECT vc_1
                                                     FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_problems_groups;
                    l_new_rec_row.table_name        := l_src_table;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --                
                    l_new_rec_row.id_task_refid := r_cur.id_epis_prob_group;
                    l_new_rec_row.dt_begin      := r_cur.dt_req;
                
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing := CASE
                                                     WHEN r_cur.flg_status IN (pk_problems.g_pat_probl_active) THEN
                                                      pk_prog_notes_constants.g_task_ongoing_o
                                                     WHEN r_cur.flg_status IN (pk_problems.g_pat_probl_passive) THEN
                                                     
                                                      pk_prog_notes_constants.g_task_inactive_i
                                                     ELSE
                                                      pk_prog_notes_constants.g_task_ongoing_o
                                                 END;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    l_new_rec_row.rank             := r_cur.rank;
                
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF (r_cur.flg_status <> pk_problems.g_pat_probl_cancel OR r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = pk_problems.g_pat_probl_cancel 
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_TL_PROBLEMS_GROUP',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_problems_group;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_problems_group
    * Description:                    Function that updates problems group  information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.2
    * @since                          05-12-2017
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_problems_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROBLEMS_EPISODE';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_PROB';
    
        l_process_name  VARCHAR2(30);
        l_event_into_ea VARCHAR2(1);
        l_update_reg    NUMBER(24);
        o_rowids        table_varchar;
        l_error_out     t_error_out;
    
        l_dup_del VARCHAR2(4000);
    
        l_count NUMBER(12);
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => l_src_table,
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT ep.id_epis_problem,
                                     epg.id_epis_prob_group,
                                     epg.id_episode,
                                     ep.dt_epis_prob_tstz dt_req,
                                     ep.flg_status,
                                     ep.id_professional id_prof_request,
                                     e.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     CASE
                                          WHEN ep.flg_status IN (pk_problems.g_pat_probl_active) THEN
                                           pk_prog_notes_constants.g_task_ongoing_o
                                          WHEN ep.flg_status IN (pk_problems.g_pat_probl_passive) THEN
                                           pk_prog_notes_constants.g_task_inactive_i
                                          ELSE
                                           pk_prog_notes_constants.g_task_ongoing_o
                                      END flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     ep.rank,
                                     decode(ep.id_problem_new,
                                            NULL,
                                            pk_ea_logic_tasktimeline.g_flg_not_outdated,
                                            pk_ea_logic_tasktimeline.g_flg_outdated) flg_outdated, 
                                            id_problem_new
                                FROM epis_prob ep
                                JOIN epis_prob_group epg
                                  ON ep.id_epis_prob_group = epg.id_epis_prob_group
                                JOIN episode e
                                  ON e.id_episode = epg.id_episode
                               WHERE ep.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_problems_episode;
                    l_new_rec_row.table_name        := l_src_table;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid := r_cur.id_epis_problem;
                    l_new_rec_row.dt_begin      := r_cur.dt_req;
                
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := r_cur.flg_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_req;
                    l_new_rec_row.rank             := r_cur.rank;
                
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF (r_cur.flg_status <> pk_problems.g_pat_probl_cancel OR r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = pk_problems.g_pat_probl_cancel or r_cur.id_problem_new is not null 
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_TL_PROBLEMS_EPISODE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_problems_episode;

    /*******************************************************************************************************************************************
    * Name:                           set_tl_prob_group_assess
    * Description:                    Function that updates problems group assessmente information in the Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.2
    * @since                          19-12-2017
    *******************************************************************************************************************************************/
    PROCEDURE set_tl_prob_group_assess
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TL_PROB_GROUP_ASSESS';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'EPIS_PROB_GROUP_ASSESS';
    
        l_process_name  VARCHAR2(30);
        l_event_into_ea VARCHAR2(1);
        l_update_reg    NUMBER(24);
        o_rowids        table_varchar;
        l_error_out     t_error_out;
    
        l_dup_del VARCHAR2(4000);
    
        l_get_phd_ids    table_number := table_number();
        l_count          NUMBER(12);
        l_id_pat_problem pat_problem.id_pat_problem%TYPE;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => l_src_table,
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
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET SCHEDULE DISCHARGE ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                FOR r_cur IN (SELECT pga.id_epis_prob_group_ass,
                   epg.id_epis_prob_group,
                                     epg.id_episode,
                                     pga.dt_create dt_req,
                                     pga.dt_last_update,
                                     pga.id_prof_create id_prof_request,
                                     pga.id_prof_last_update,
                                     e.id_patient,
                                     e.id_visit,
                                     e.id_institution,
                                     pga.flg_status,
                                     pk_alert_constant.g_yes flg_normal,
                                     NULL id_prof_exec,
                                     epg.id_epis_prob_group rank 
                                     
                                FROM epis_prob_group_assess pga
                                join epis_prob_group epg 
                                on pga.id_epis_prob_group = epg.id_epis_prob_group
                                JOIN episode e
                                  ON e.id_episode = epg.id_episode
                               WHERE pga.rowid IN (SELECT vc_1
                                                     FROM tbl_temp))
                
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_problems_group_ass;
                    l_new_rec_row.table_name        := l_src_table;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --                
                    l_new_rec_row.id_task_refid := r_cur.id_epis_prob_group_ass;
                    l_new_rec_row.dt_begin      := r_cur.dt_req;
                
                    l_new_rec_row.flg_status_req   := r_cur.flg_status;
                    l_new_rec_row.id_prof_req      := r_cur.id_prof_request;
                    l_new_rec_row.dt_req           := r_cur.dt_req;
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.flg_outdated     := pk_ea_logic_tasktimeline.g_flg_not_outdated;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing := 
                                                      pk_prog_notes_constants.g_task_ongoing_o;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec     := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := current_timestamp;
                    l_new_rec_row.rank             := r_cur.rank;
                
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF (r_cur.flg_status <> pk_problems.g_pat_probl_cancel OR r_cur.flg_status IS NULL) -- Active Data                       
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = pk_problems.g_pat_probl_cancel
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin      => FALSE,
                                                table_name_in       => l_new_rec_row.table_name,
                                                flg_show_method_nin => FALSE,
                                                flg_show_method_in  => l_new_rec_row.flg_show_method,
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                rows_out             => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_TL_PROB_GROUP_ASSESS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_prob_group_assess;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_ea_logic_problems;
/
