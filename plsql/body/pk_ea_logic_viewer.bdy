/*-- Last Change Revision: $Rev: 2027069 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_viewer IS
    -- This package provides Easy Access logic procedures to maintain the Viewer's EA table.
    -- @author Sérgio Santos
    -- @version 2.4.3-Denormalized

    ------------------------------------------------ PUBLIC ----------------------------------------------------------

    /**
    * Inserts, Updates or Inserts a Patient (PK) in the Viewer EA table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/25
    */
    PROCEDURE set_patient
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30) := 'SET_PATIENT';
        l_rowids table_varchar;
    
        l_error_out t_error_out;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_patient.patient_tc;
    
    BEGIN
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'PATIENT',
                                                 i_expected_dg_table_name => 'VIEWER_EHR_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        IF i_event_type = t_data_gov_mnt.g_event_insert
        THEN
            g_error := 'GET INSERTED';
            -- Get affected records
            l_affected_records := ts_patient.get_data_rowid(rows_in => i_rowids);
            -- Process insert event
            pk_alertlog.log_debug('Processing insert on PATIENT', g_package_name, l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP INSERTED';
            IF l_affected_records IS NOT NULL
               AND l_affected_records.count > 0
            THEN
                FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                LOOP
                    ts_viewer_ehr_ea.ins(id_patient_in    => l_affected_records(idx_affected).id_patient,
                                         num_allergy_in   => 0,
                                         num_lab_in       => 0,
                                         num_diag_icnp_in => 0,
                                         num_episode_in   => 0,
                                         num_exam_in      => 0,
                                         num_med_in       => 0,
                                         num_problem_in   => 0,
                                         num_interv_in    => 0,
                                         rows_out         => l_rowids);
                
                END LOOP;
            END IF;
        ELSIF i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            g_error := 'GET DELETED';
            -- Get affected records on an autonomous transaction (as the records do not exist on the main transaction)
            l_affected_records := ts_patient.get_data_rowid_pat(rows_in => i_rowids);
        
            -- Process delete  event
            pk_alertlog.log_debug('Processing delete on PATIENT', g_package_name, l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP DELETED';
            IF l_affected_records IS NOT NULL
               AND l_affected_records.count > 0
            THEN
                FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                LOOP
                    ts_viewer_ehr_ea.del(id_patient_in => l_affected_records(idx_affected).id_patient);
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PATIENT',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_patient;

    /**
    * Updates the NUM_PROBLEM, DESC_PROBLEM, DT_PROBLEM and DT_PROBLEM_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    PROCEDURE set_pat_problem
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        l_error_out t_error_out;
    
        --update variables
        l_num_problem    PLS_INTEGER;
        l_desc_problem   viewer_ehr_ea.desc_problem%TYPE;
        l_code_problem   viewer_ehr_ea.code_problem%TYPE;
        l_dt_problem     viewer_ehr_ea.dt_problem%TYPE;
        l_dt_problem_fmt viewer_ehr_ea.dt_problem_fmt%TYPE;
        l_id_problem     viewer_ehr_ea.id_problem%TYPE;
        l_id_task_type   viewer_ehr_ea.id_task_type%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records_pp  ts_pat_problem.pat_problem_tc;
        l_affected_records_pa  ts_pat_allergy.pat_allergy_tc;
        l_affected_records_phd ts_pat_history_diagnosis.pat_history_diagnosis_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        -- auxiliary variable to store the current patient ID
        l_pat_id_aux patient.id_patient%TYPE;
    
        -- auxiliary variable to store flg_warning
        l_flg_warning   viewer_ehr_ea.flg_exclamation%TYPE;
        l_flg_infective viewer_ehr_ea.flg_infective%TYPE;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_PROBLEM';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'PAT_ALLERGY'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'PAT_ALLERGY',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        ELSIF i_source_table_name = 'PAT_HISTORY_DIAGNOSIS'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'PAT_HISTORY_DIAGNOSIS',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        ELSIF i_source_table_name = 'PAT_PROBLEM'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'PAT_PROBLEM',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'PAT_ALLERGY'
            THEN
                g_error               := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records_pa := ts_pat_allergy.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records_pa IS NOT NULL
                   AND l_affected_records_pa.count > 0
                THEN
                    FOR idx_affected IN l_affected_records_pa.first .. l_affected_records_pa.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records_pa(idx_affected).id_patient;
                    
                        --If the id_patient is null, we must search for it in the episode table
                        IF l_pat_id_aux IS NULL
                        THEN
                            SELECT e.id_patient
                              INTO l_pat_id_aux
                              FROM episode e
                             WHERE e.id_episode = l_affected_records_pa(idx_affected).id_episode;
                        END IF;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    END LOOP;
                END IF;
            ELSIF i_source_table_name = 'PAT_PROBLEM'
            THEN
                g_error               := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records_pp := ts_pat_problem.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records_pp IS NOT NULL
                   AND l_affected_records_pp.count > 0
                THEN
                    FOR idx_affected IN l_affected_records_pp.first .. l_affected_records_pp.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records_pp(idx_affected).id_patient;
                    
                        --If the id_patient is null, we must search for it in the episode table
                        IF l_pat_id_aux IS NULL
                        THEN
                            SELECT e.id_patient
                              INTO l_pat_id_aux
                              FROM episode e
                             WHERE e.id_episode = l_affected_records_pp(idx_affected).id_episode;
                        END IF;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    END LOOP;
                END IF;
            ELSIF i_source_table_name = 'PAT_HISTORY_DIAGNOSIS'
            THEN
                g_error                := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records_phd := ts_pat_history_diagnosis.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records_phd IS NOT NULL
                   AND l_affected_records_phd.count > 0
                THEN
                    FOR idx_affected IN l_affected_records_phd.first .. l_affected_records_phd.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records_phd(idx_affected).id_patient;
                    
                        --If the id_patient is null, we must search for it in the episode table
                        IF l_pat_id_aux IS NULL
                        THEN
                            SELECT e.id_patient
                              INTO l_pat_id_aux
                              FROM episode e
                             WHERE e.id_episode = l_affected_records_pa(idx_affected).id_episode;
                        END IF;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            IF i_source_table_name = 'PAT_HISTORY_DIAGNOSIS'
            THEN
                l_flg_warning   := pk_problems.get_pat_flg_warning(i_lang => i_lang,
                                                                   i_pat  => l_pat_list(i),
                                                                   i_prof => i_prof);
                l_flg_infective := pk_problems.check_pat_diag_condition(i_lang => i_lang,
                                                                        i_pat  => l_pat_list(i),
                                                                        i_prof => i_prof);
            END IF;
        
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'pk_problems.get_count_and_first';
            IF NOT pk_problems.get_count_and_first(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_patient            => l_pat_list(i),
                                                   o_count              => l_num_problem,
                                                   o_first              => l_desc_problem,
                                                   o_code               => l_code_problem,
                                                   o_date               => l_dt_problem,
                                                   o_fmt                => l_dt_problem_fmt,
                                                   o_id_alert_diagnosis => l_id_problem,
                                                   o_id_task_type       => l_id_task_type)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update allergy count
            ts_viewer_ehr_ea.upd(id_patient_in      => l_pat_list(i),
                                 num_problem_in     => nvl(l_num_problem, 0),
                                 desc_problem_in    => l_desc_problem,
                                 desc_problem_nin   => FALSE,
                                 code_problem_in    => l_code_problem,
                                 code_problem_nin   => FALSE,
                                 dt_problem_in      => l_dt_problem,
                                 dt_problem_nin     => FALSE,
                                 dt_problem_fmt_in  => l_dt_problem_fmt,
                                 dt_problem_fmt_nin => FALSE,
                                 flg_exclamation_in => l_flg_warning,
                                 flg_infective_in   => l_flg_infective,
                                 id_problem_in      => l_id_problem,
                                 id_problem_nin     => FALSE,
                                 id_task_type_in=>l_id_task_type,
                                 id_task_type_nin => FALSE,
                                 rows_out           => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_PROBLEM',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_problem;

    /*
    * returns a list of id_patients affected by the modifications
    */
    FUNCTION get_interv_affected_patients
    (
        i_lang              IN language.id_language%TYPE,
        i_source_table_name IN VARCHAR2,
        i_rowids            IN table_varchar
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_INTERV_AFFECTED_PATIENTS';
        l_interv_presc_det_recs  ts_interv_presc_det.interv_presc_det_tc;
        l_nurse_tea_req_recs     ts_nurse_tea_req.nurse_tea_req_tc;
        l_icnp_interv_plan_recs  ts_icnp_interv_plan.icnp_interv_plan_tc;
        l_interv_presc_plan_recs ts_interv_presc_plan.interv_presc_plan_tc;
        l_pat_id_aux             patient.id_patient%TYPE;
        l_pat_list               table_number := table_number();
        l_error                  t_error_out;
    BEGIN
        g_error := 'inicio i_source_table_name=' || i_source_table_name;
        pk_alertlog.log_debug(g_error, g_package_name, l_func_name);
    
        IF i_source_table_name = 'INTERV_PRESC_DET'
        THEN
            g_error                 := 'GET AFFECTED ROWS' || i_source_table_name;
            l_interv_presc_det_recs := ts_interv_presc_det.get_data_rowid(rows_in => i_rowids);
        
            IF l_interv_presc_det_recs IS NOT NULL
               AND l_interv_presc_det_recs.count > 0
            THEN
                FOR idx_affected IN l_interv_presc_det_recs.first .. l_interv_presc_det_recs.last
                LOOP
                    --Get the patient ID
                    SELECT ip.id_patient
                      INTO l_pat_id_aux
                      FROM interv_prescription ip
                      JOIN interv_presc_det ipd
                        ON ipd.id_interv_prescription = ip.id_interv_prescription
                     WHERE ipd.id_interv_presc_det = l_interv_presc_det_recs(idx_affected).id_interv_presc_det;
                
                    --Add the information to the list of patient to process
                    IF l_pat_id_aux IS NOT NULL
                       AND pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                    THEN
                        l_pat_list.extend;
                        l_pat_list(l_pat_list.count) := l_pat_id_aux;
                    END IF;
                END LOOP;
            END IF;
        ELSIF i_source_table_name = 'NURSE_TEA_REQ'
        THEN
            g_error              := 'GET AFFECTED ROWS' || i_source_table_name;
            l_nurse_tea_req_recs := ts_nurse_tea_req.get_data_rowid(rows_in => i_rowids);
        
            IF l_nurse_tea_req_recs IS NOT NULL
               AND l_nurse_tea_req_recs.count > 0
            THEN
                FOR idx_affected IN l_nurse_tea_req_recs.first .. l_nurse_tea_req_recs.last
                LOOP
                    --Get the patient ID
                    SELECT ntr.id_patient
                      INTO l_pat_id_aux
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_nurse_tea_req = l_nurse_tea_req_recs(idx_affected).id_nurse_tea_req;
                
                    --Add the information to the list of patient to process
                    IF l_pat_id_aux IS NOT NULL
                       AND pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                    THEN
                        l_pat_list.extend;
                        l_pat_list(l_pat_list.count) := l_pat_id_aux;
                    END IF;
                END LOOP;
            END IF;
        ELSIF i_source_table_name IN ('ICNP_INTERV_PLAN')
        THEN
            g_error                 := 'GET AFFECTED ROWS' || i_source_table_name;
            l_icnp_interv_plan_recs := ts_icnp_interv_plan.get_data_rowid(rows_in => i_rowids);
        
            IF l_icnp_interv_plan_recs IS NOT NULL
               AND l_icnp_interv_plan_recs.count > 0
            THEN
                FOR idx_affected IN l_icnp_interv_plan_recs.first .. l_icnp_interv_plan_recs.last
                LOOP
                    --Get the patient ID
                    SELECT iiea.id_patient
                      INTO l_pat_id_aux
                    --FROM interv_icnp_ea iiea
                      FROM icnp_epis_intervention iiea
                     WHERE iiea.id_icnp_epis_interv = l_icnp_interv_plan_recs(idx_affected).id_icnp_epis_interv;
                
                    --Add the information to the list of patient to process
                    IF l_pat_id_aux IS NOT NULL
                       AND pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                    THEN
                        l_pat_list.extend;
                        l_pat_list(l_pat_list.count) := l_pat_id_aux;
                    END IF;
                END LOOP;
            END IF;
        ELSIF i_source_table_name IN ('INTERV_PRESC_PLAN')
        THEN
            g_error                  := 'GET AFFECTED ROWS' || i_source_table_name;
            l_interv_presc_plan_recs := ts_interv_presc_plan.get_data_rowid(rows_in => i_rowids);
        
            IF l_interv_presc_plan_recs IS NOT NULL
               AND l_interv_presc_plan_recs.count > 0
            THEN
                FOR idx_affected IN l_interv_presc_plan_recs.first .. l_interv_presc_plan_recs.last
                LOOP
                    --Get the patient ID
                    SELECT ip.id_patient
                      INTO l_pat_id_aux
                      FROM interv_prescription ip
                      JOIN interv_presc_det ipd
                        ON ipd.id_interv_prescription = ip.id_interv_prescription
                      JOIN interv_presc_plan ipp
                        ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
                     WHERE ipp.id_interv_presc_plan = l_interv_presc_plan_recs(idx_affected).id_interv_presc_plan;
                
                    --Add the information to the list of patient to process
                    IF l_pat_id_aux IS NOT NULL
                       AND pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                    THEN
                        l_pat_list.extend;
                        l_pat_list(l_pat_list.count) := l_pat_id_aux;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        pk_alertlog.log_debug('fim l_pat_list.count=' || l_pat_list.count, g_package_name, l_func_name);
    
        RETURN l_pat_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn('exception @ ' || g_error, g_package_name, l_func_name);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN l_pat_list;
        
    END get_interv_affected_patients;

    /**
    * Updates the NUM_INTERV, DESC_INTERV, CODE_INTERV and DT_INTERV columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/10
    */
    PROCEDURE set_pat_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30) := 'SET_PAT_INTERV';
    
        --update variables
        l_num_interv  PLS_INTEGER;
        l_desc_interv viewer_ehr_ea.desc_interv%TYPE;
        l_code_interv viewer_ehr_ea.code_interv%TYPE;
        l_dt_interv   viewer_ehr_ea.dt_interv%TYPE;
    
        l_rowids   table_varchar;
        l_pat_list table_number := table_number();
    
        --external function exception
        e_external_function EXCEPTION;
    
        --variable to store the error message
        l_error t_error_out;
    BEGIN
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS ' || i_source_table_name;
        IF i_source_table_name = 'INTERV_PRESC_DET'
        THEN
            g_error := g_error || 'INTERV_PRESC_DET';
            IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                     i_source_table_name      => i_source_table_name,
                                                     i_dg_table_name          => i_dg_table_name,
                                                     i_expected_table_name    => 'INTERV_PRESC_DET',
                                                     i_expected_dg_table_name => 'VIEWER_EHR_EA')
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        ELSIF i_source_table_name = 'ICNP_INTERV_PLAN'
        THEN
            g_error := g_error || 'ICNP_INTERV_PLAN';
            IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                     i_source_table_name      => i_source_table_name,
                                                     i_dg_table_name          => i_dg_table_name,
                                                     i_expected_table_name    => 'ICNP_INTERV_PLAN',
                                                     i_expected_dg_table_name => 'VIEWER_EHR_EA')
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Get affected records
            g_error    := 'GET AFFECTED ROWS';
            l_pat_list := get_interv_affected_patients(i_lang, i_source_table_name, i_rowids);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_PROCEDURES_EXTERNAL_API_DB.GET_COUNT_AND_FIRST';
            IF NOT pk_procedures_external_api_db.get_count_and_first(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_patient     => l_pat_list(i),
                                                                     i_episode     => NULL,
                                                                     i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                                                     o_num_occur   => l_num_interv,
                                                                     o_desc_first  => l_desc_interv,
                                                                     o_code_first  => l_code_interv,
                                                                     o_dt_first    => l_dt_interv,
                                                                     o_error       => l_error)
            THEN
                RAISE e_external_function;
            END IF;
        
            pk_alertlog.log_debug('antes do update à viewer_ehr_ea, count=' || l_num_interv || ', id_patient=' ||
                                  l_pat_list(1),
                                  g_package_name,
                                  l_func_proc_name);
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in   => l_pat_list(i),
                                 num_interv_in   => nvl(l_num_interv, 0),
                                 desc_interv_in  => l_desc_interv,
                                 desc_interv_nin => FALSE,
                                 code_interv_in  => l_code_interv,
                                 code_interv_nin => FALSE,
                                 dt_interv_in    => l_dt_interv,
                                 dt_interv_nin   => FALSE,
                                 rows_out        => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_INTERV',
                                              l_error);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_interv;

    /**
    * Updates the NUM_LAB, DESC_LAB, CODE_LAB and DT_LAB columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/11
    */
    PROCEDURE set_pat_lab
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        --update variables
        l_num_lab  PLS_INTEGER;
        l_desc_lab viewer_ehr_ea.desc_lab%TYPE;
        l_code_lab viewer_ehr_ea.code_lab%TYPE;
        l_dt_lab   viewer_ehr_ea.dt_lab%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_analysis_req_det.analysis_req_det_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_LAB';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'ANALYSIS_REQ_DET'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'ANALYSIS_REQ_DET',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'ANALYSIS_REQ_DET'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_analysis_req_det.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        SELECT ar.id_patient
                          INTO l_pat_id_aux
                          FROM analysis_req ar
                          JOIN analysis_req_det ard
                            ON ard.id_analysis_req = ar.id_analysis_req
                         WHERE ard.id_analysis_req_det = l_affected_records(idx_affected).id_analysis_req_det;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_LAB_TESTS_EXTERNAL_API_DB.GET_COUNT_AND_FIRST';
            IF NOT pk_lab_tests_external_api_db.get_count_and_first(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_patient     => l_pat_list(i),
                                                                    i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                                                    i_episode     => NULL,
                                                                    o_num_occur   => l_num_lab,
                                                                    o_desc_first  => l_desc_lab,
                                                                    o_code_first  => l_code_lab,
                                                                    o_dt_first    => l_dt_lab,
                                                                    o_error       => l_error_out)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in => l_pat_list(i),
                                 num_lab_in    => nvl(l_num_lab, 0),
                                 desc_lab_in   => l_desc_lab,
                                 desc_lab_nin  => FALSE,
                                 code_lab_in   => l_code_lab,
                                 code_lab_nin  => FALSE,
                                 dt_lab_in     => l_dt_lab,
                                 dt_lab_nin    => FALSE,
                                 rows_out      => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_LAB',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_lab;

    /**
    * Updates the NUM_EPISODE, DESC_EPISODE, CODE_EPISODE and DT_EPISODE columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/11
    */
    PROCEDURE set_pat_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        --update variables
        l_num_epis  PLS_INTEGER;
        l_desc_epis viewer_ehr_ea.desc_episode%TYPE;
        l_code_epis viewer_ehr_ea.code_episode%TYPE;
        l_dt_epis   viewer_ehr_ea.dt_episode%TYPE;
        l_fmt_epis  VARCHAR2(40); --not used
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_episode.episode_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_EPISODE';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'EPISODE'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'EPISODE',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'EPISODE'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_episode.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records(idx_affected).id_patient;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        IF NOT pk_episode.upd_viewer_ehr_ea_pat(i_lang => i_lang,
                                                
                                                i_table_id_patients => l_pat_list,
                                                o_error             => l_error_out)
        THEN
            RAISE e_external_function;
        END IF;
    
        /*     -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_EPISODE.GET_COUNT_AND_FIRST';
            IF NOT pk_episode.get_count_and_first(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_patient => l_pat_list(i),
                                                  o_count   => l_num_epis,
                                                  o_first   => l_desc_epis,
                                                  o_code    => l_code_epis,
                                                  o_date    => l_dt_epis,
                                                  o_fmt     => l_fmt_epis)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in    => l_pat_list(i),
                                 num_episode_in   => nvl(l_num_epis, 0),
                                 desc_episode_in  => NULL,
                                 desc_episode_nin => FALSE,
                                 code_episode_in  => l_code_epis,
                                 code_episode_nin => FALSE,
                                 dt_episode_in    => l_dt_epis,
                                 dt_episode_nin   => FALSE,
                                 rows_out         => l_rowids);
        
        END LOOP;*/
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_EPISODE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_episode;

    /**
    * Updates the NUM_ARCHIVE, DESC_ARCHIVE, CODE_ARCHIVE and DT_ARCHIVE columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Mário Mineiro
    * @version 2.6.4
    * @since 10-03-2014
    */
    PROCEDURE set_pat_archive
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        --update variables
        l_num_archive  PLS_INTEGER;
        l_desc_archive viewer_ehr_ea.desc_episode%TYPE;
        l_code_archive viewer_ehr_ea.code_episode%TYPE;
        l_dt_archive   viewer_ehr_ea.dt_episode%TYPE;
    
        -- l_rowids table_varchar;
        l_ret BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records      ts_doc_external.doc_external_tc;
        l_affected_records_diag ts_epis_diagram_detail.epis_diagram_detail_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_ARCHIVE';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'DOC_EXTERNAL'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'DOC_EXTERNAL',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        ELSIF i_source_table_name = 'EPIS_DIAGRAM_DETAIL'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'EPIS_DIAGRAM_DETAIL',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'DOC_EXTERNAL'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_doc_external.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records(idx_affected).id_patient;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            ELSIF i_source_table_name = 'EPIS_DIAGRAM_DETAIL'
            THEN
                g_error                 := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records_diag := ts_epis_diagram_detail.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records_diag IS NOT NULL
                   AND l_affected_records_diag.count > 0
                THEN
                    FOR idx_affected IN l_affected_records_diag.first .. l_affected_records_diag.last
                    LOOP
                        --Get the patient ID
                    
                        SELECT ed.id_patient
                          INTO l_pat_id_aux
                          FROM epis_diagram ed
                          JOIN epis_diagram_layout edl
                            ON edl.id_epis_diagram = ed.id_epis_diagram
                          JOIN epis_diagram_detail edd
                            ON edd.id_epis_diagram_layout = edl.id_epis_diagram_layout
                           AND edd.id_epis_diagram_detail = l_affected_records_diag(idx_affected).id_epis_diagram_detail;
                    
                        -- l_pat_id_aux := l_affected_records_diag(idx_affected).id_patient;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        IF NOT pk_doc.upd_viewer_ehr_ea_pat(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_table_id_patients => l_pat_list,
                                            o_error             => l_error_out)
        THEN
            RAISE e_external_function;
        END IF;
    
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_ARCHIVE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_archive;

    /**
    * Updates the NUM_DIAG_ICNP, DESC_DIAG_ICNP, CODE_DIAG_ICNP and DT_DIAG_ICNP columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/12
    */
    PROCEDURE set_pat_diag_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30) := 'SET_PAT_DIAG_ICNP';
    
        --update variables
        l_num_diag_icnp  PLS_INTEGER;
        l_desc_diag_icnp viewer_ehr_ea.desc_diag_icnp%TYPE;
        l_code_diag_icnp viewer_ehr_ea.code_diag_icnp%TYPE;
        l_dt_diag_icnp   viewer_ehr_ea.dt_diag_icnp%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_icnp_epis_diagnosis.icnp_epis_diagnosis_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'ICNP_EPIS_DIAGNOSIS'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'ICNP_EPIS_DIAGNOSIS',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'ICNP_EPIS_DIAGNOSIS'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_icnp_epis_diagnosis.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        SELECT e.id_patient
                          INTO l_pat_id_aux
                          FROM episode e
                          JOIN icnp_epis_diagnosis iep
                            ON iep.id_episode = e.id_episode
                         WHERE iep.id_icnp_epis_diag = l_affected_records(idx_affected).id_icnp_epis_diag;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_ICNP.GET_COUNT_AND_FIRST';
            IF NOT pk_icnp.get_count_and_first(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_patient     => l_pat_list(i),
                                               i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                               i_episode     => NULL,
                                               o_num_occur   => l_num_diag_icnp,
                                               o_desc_first  => l_desc_diag_icnp,
                                               o_code_first  => l_code_diag_icnp,
                                               o_dt_first    => l_dt_diag_icnp,
                                               o_error       => l_error_out)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in      => l_pat_list(i),
                                 num_diag_icnp_in   => nvl(l_num_diag_icnp, 0),
                                 desc_diag_icnp_in  => l_desc_diag_icnp,
                                 desc_diag_icnp_nin => FALSE,
                                 code_diag_icnp_in  => l_code_diag_icnp,
                                 code_diag_icnp_nin => FALSE,
                                 dt_diag_icnp_in    => l_dt_diag_icnp,
                                 dt_diag_icnp_nin   => FALSE,
                                 rows_out           => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DIAG_ICNP',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_diag_icnp;

    /**
    * Updates the NUM_EXAM, DESC_EXAM, CODE_EXAM and DT_EXAM columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/12/12
    */
    PROCEDURE set_pat_exam
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        --update variables
        l_num_exam  PLS_INTEGER;
        l_desc_exam viewer_ehr_ea.desc_exam%TYPE;
        l_code_exam viewer_ehr_ea.code_exam%TYPE;
        l_dt_exam   viewer_ehr_ea.dt_exam%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_exam_req_det.exam_req_det_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_EXAM';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'EXAM_REQ_DET'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'EXAM_REQ_DET',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'EXAM_REQ_DET'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_exam_req_det.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        SELECT er.id_patient
                          INTO l_pat_id_aux
                          FROM exam_req er, exam_req_det erd
                         WHERE erd.id_exam_req_det = l_affected_records(idx_affected).id_exam_req_det
                           AND erd.id_exam_req = er.id_exam_req;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_EXAMS_EXTERNAL_API_DB.GET_COUNT_AND_FIRST';
            IF NOT pk_exams_external_api_db.get_count_and_first(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_patient     => l_pat_list(i),
                                                                i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                                                i_episode     => NULL,
                                                                o_num_occur   => l_num_exam,
                                                                o_desc_first  => l_desc_exam,
                                                                o_code_first  => l_code_exam,
                                                                o_dt_first    => l_dt_exam,
                                                                o_error       => l_error_out)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in => l_pat_list(i),
                                 num_exam_in   => nvl(l_num_exam, 0),
                                 desc_exam_in  => l_desc_exam,
                                 desc_exam_nin => FALSE,
                                 code_exam_in  => l_code_exam,
                                 code_exam_nin => FALSE,
                                 dt_exam_in    => l_dt_exam,
                                 dt_exam_nin   => FALSE,
                                 rows_out      => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DIAG_ICNP',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_exam;

    /**
    * Updates the NUM_ALLERGY, DESC_ALLERGY, CODE_ALLERGY and DT_ALLERGY columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2009/13/01
    */
    PROCEDURE set_pat_allergy
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        --update variables
        l_num_allergy    PLS_INTEGER;
        l_desc_allergy   viewer_ehr_ea.desc_allergy%TYPE;
        l_code_allergy   viewer_ehr_ea.code_allergy%TYPE;
        l_dt_allergy     viewer_ehr_ea.dt_allergy%TYPE;
        l_dt_allergy_fmt viewer_ehr_ea.dt_allergy_fmt%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records ts_pat_allergy.pat_allergy_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        --auxiliary variable to store the id_patient
        l_pat_id_aux patient.id_patient%TYPE;
    
        --variable to store the error message
        l_error_out t_error_out;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_ALLERGY';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'PAT_ALLERGY'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'PAT_ALLERGY',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
    
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'PAT_ALLERGY'
            THEN
                g_error            := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records := ts_pat_allergy.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records IS NOT NULL
                   AND l_affected_records.count > 0
                THEN
                    FOR idx_affected IN l_affected_records.first .. l_affected_records.last
                    LOOP
                        --Get the patient ID
                        l_pat_id_aux := l_affected_records(idx_affected).id_patient;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        IF NOT pk_allergy.upd_viewer_ehr_ea_pat(i_lang => i_lang,
                                                
                                                i_table_id_patients => l_pat_list,
                                                o_error             => l_error_out)
        THEN
            RAISE e_external_function;
        END IF;
    
        /*    -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_ALLERGY.GET_COUNT_AND_FIRST';
            IF NOT pk_allergy.get_count_and_first(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_patient    => l_pat_list(i),
                                                  o_num_occur  => l_num_allergy,
                                                  o_desc_first => l_desc_allergy,
                                                  o_code       => l_code_allergy,
                                                  o_dt_first   => l_dt_allergy,
                                                  o_dt_fmt     => l_dt_allergy_fmt,
                                                  o_error      => l_error_out)
            THEN
                RAISE e_external_function;
            END IF;
        
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in      => l_pat_list(i),
                                 num_allergy_in     => nvl(l_num_allergy, 0),
                                 desc_allergy_in    => l_desc_allergy,
                                 desc_allergy_nin   => FALSE,
                                 code_allergy_in    => l_code_allergy,
                                 code_allergy_nin   => FALSE,
                                 dt_allergy_in      => l_dt_allergy,
                                 dt_allergy_nin     => FALSE,
                                 dt_allergy_fmt_in  => l_dt_allergy_fmt,
                                 dt_allergy_fmt_nin => FALSE,
                                 rows_out           => l_rowids);
        
        END LOOP;*/
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in      => 'EXTERNAL FUNCTION ERROR',
                                            error_code_in => l_error_out.ora_sqlcode);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_ALLERGY',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_allergy;

    /**
    * Updates the NUM_MED, DESC_MED, CODE_MED and DT_MED columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2009/02/09
    */
    PROCEDURE set_pat_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_db_object_name user_procedures.procedure_name%TYPE := 'SET_PAT_MEDICATION';
        --
        l_current_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowids       table_varchar;
        l_ret          BOOLEAN := FALSE;
        -- patient list to update
        l_pat_list table_number := table_number();
        --variable to store the error message
        l_error_out t_error_out;
    
        l_ordered_list pk_types.cursor_type;
    
        l_code_description VARCHAR2(1000 CHAR);
        l_description      VARCHAR2(1000 CHAR);
        l_dt_req_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_rows_count       NUMBER := 0;
    
        l_task_title pk_translation.t_desc_translation;
    
    BEGIN
        pk_alertlog.log_debug(text            => 'rowid count: ' || i_rowids.count,
                              object_name     => g_package_name,
                              sub_object_name => l_db_object_name);
    
        -- validate arguments
        g_error := 't_data_gov_mnt.validate_arguments';
        l_ret   := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                     i_source_table_name      => i_source_table_name,
                                                     i_dg_table_name          => i_dg_table_name,
                                                     i_expected_table_name    => i_source_table_name,
                                                     i_expected_dg_table_name => 'VIEWER_EHR_EA');
    
        IF (NOT l_ret)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error    := 'pk_api_pfh_in.get_patients_for_rowids';
        l_pat_list := pk_api_pfh_in.get_patients_for_rowids(i_rowids            => i_rowids,
                                                            i_source_table_name => i_source_table_name);
    
        -- loop through the affected patient list and update the information
        g_error := 'LOOP 1';
        FOR i IN 1 .. nvl(cardinality(l_pat_list), 0)
        LOOP
            IF (l_pat_list(i) IS NOT NULL)
            THEN
                g_error := 'pk_rt_med_pfh.get_ordered_list with only 1 record - i_flg_all_rows = FALSE';
                IF NOT pk_rt_med_pfh.get_ordered_list(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_patient          => l_pat_list(i),
                                                      i_flg_all_rows        => FALSE,
                                                      i_auto_complete_takes => FALSE,
                                                      o_ordered_list        => l_ordered_list,
                                                      o_error               => l_error_out)
                THEN
                    raise_application_error(-20001, 'pk_rt_med_pfh.get_ordered_list');
                END IF;
            
                FETCH l_ordered_list
                    INTO l_code_description, l_description, l_dt_req_tstz, l_rows_count, l_task_title;
            
                CLOSE l_ordered_list;
            
                -- update easy access table
                g_error := 'ts_viewer_ehr_ea.upd';
                ts_viewer_ehr_ea.upd(id_patient_in => l_pat_list(i),
                                     num_med_in    => nvl(l_rows_count, 0),
                                     desc_med_in   => l_description,
                                     desc_med_nin  => FALSE,
                                     code_med_in   => l_code_description,
                                     code_med_nin  => FALSE,
                                     dt_med_in     => l_dt_req_tstz,
                                     dt_med_nin    => FALSE,
                                     rows_out      => l_rowids);
            
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_MEDICATION',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RAISE;
    END set_pat_medication;

    /**
    * Gets the number of allergies of a given patient
    *
    * @param i_lang               Language.
    * @param i_patient            The patient ID.
    *
    * @returns The number of allergies of the given patient
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/29 
    */
    FUNCTION get_pat_num_allergies
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_num_allergies NUMBER;
    BEGIN
        SELECT v.num_allergy
          INTO l_num_allergies
          FROM viewer_ehr_ea v
         WHERE v.id_patient = i_patient;
    
        RETURN nvl(l_num_allergies, 0);
    END get_pat_num_allergies;

    /**
    * Gets the number of pending or inactive episodes of a given patient
    *
    * @param i_lang               Language.
    * @param i_patient            The patient ID.
    *
    * @returns The number of pending or inactive episodes of the given patient
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/09/29 
    */
    FUNCTION get_pat_num_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_num_episodes NUMBER;
    BEGIN
    
        SELECT v.num_episode
          INTO l_num_episodes
          FROM viewer_ehr_ea v
         WHERE v.id_patient = i_patient;
    
        RETURN nvl(l_num_episodes, 0);
    END get_pat_num_episodes;

    /**
    * Updates the NUM_VS, DESC_VS, DT_VS and DT_VS_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    
  procedure upd_viewer_ehr_ea( i_tbl_patient in table_number ) is

    l_num_vs  viewer_ehr_ea.num_vs%type;
    l_code_vs viewer_ehr_ea.code_vs%type;
    l_dt_vs   viewer_ehr_ea.dt_vs%type;
    l_desc_vs viewer_ehr_ea.desc_vs%type;

  
    cursor vea_c( i_id_patient in number) is
      SELECT aux.id_patient,
      'VITAL_SIGN.CODE_VITAL_SIGN.' || aux.id_vital_sign code_vital_sign,
      aux.l_count num_records,
      aux.dt_vital_sign_read_tstz date_tstz
      FROM (SELECT t_vs.id_vital_sign_read,
      t_vs.id_vital_sign,
      t_vs.id_patient,
      t_vs.l_count,
      t_vs.dt_vital_sign_read_tstz
      FROM (SELECT t_vs2.id_vital_sign_read,
        t_vs2.id_vital_sign,
        t_vs2.id_patient,
        t_vs2.dt_vital_sign_read_tstz,
        t_vs2.rn,
        COUNT(1) over(PARTITION BY t_vs2.id_patient) l_count
      FROM (SELECT vsr.id_vital_sign_read,
            vspea.id_vital_sign,
            vspea.id_patient,
            vsr.dt_vital_sign_read_tstz,
            row_number() over(PARTITION BY vspea.id_patient ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) rn,
            row_number() over(PARTITION BY vspea.id_patient, vspea.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) rn2
         FROM vs_patient_ea vspea
        INNER JOIN vital_sign_read vsr
           ON vspea.id_last_1_vsr = vsr.id_vital_sign_read
        WHERE vsr.id_patient = i_id_patient 
        AND vsr.flg_state = pk_vital_sign.c_flg_status_active
        ) t_vs2
      WHERE t_vs2.rn2 = 1) t_vs
      WHERE t_vs.rn = 1) aux;

    type vea_c_type is table of vea_c%rowtype;
    
    tbl_vea vea_c_type;
  
  begin
  
    <<LUP_THRU_PATIENTS>>
    for i in 1..i_tbl_patient.count loop
  
      open vea_c( i_tbl_patient(i) );
      fetch vea_c bulk collect into tbl_vea;
      close vea_c;

      l_num_vs  := NULL;
      l_code_vs := NULL;
      l_dt_vs   := NULL;
      l_desc_vs := NULL;

      if tbl_vea.count > 0 then

        l_num_vs  := tbl_vea(i).num_records ;
        l_code_vs := tbl_vea(i).code_vital_sign;
        l_dt_vs   := tbl_vea(i).date_tstz  ;
        
      end if;
      
      update viewer_ehr_ea set
          num_vs  = l_num_vs 
          ,code_vs = l_code_vs
          ,dt_vs   = l_dt_vs  
      where id_patient = i_tbl_patient(i);
  
    end loop LUP_THRU_PATIENTS;
    
  
  end upd_viewer_ehr_ea;
    
    PROCEDURE set_pat_vs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        l_error_out t_error_out;
    
        --update variables
        l_num_vs  PLS_INTEGER;
        l_desc_vs viewer_ehr_ea.desc_vs%TYPE;
        l_code_vs viewer_ehr_ea.code_vs%TYPE;
        l_dt_vs   viewer_ehr_ea.dt_vs%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records_vs ts_vital_sign_read.vital_sign_read_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        -- auxiliary variable to store the current patient ID
        l_pat_id_aux patient.id_patient%TYPE;
    
        --cursor with the final information
        l_vs_info pk_types.cursor_type;
    
        --dummy variables
        l_dummy_vc VARCHAR2(4000 CHAR);
        l_flg_view CONSTANT VARCHAR2(2 CHAR) := 'V2';
        tb_id_patient table_number;
        l_count number;
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_VS';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'VITAL_SIGN_READ'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'VITAL_SIGN_READ',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
        IF NOT l_ret
        THEN
            --[ALERT-210875]
            -- RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            -- It should not produce an error bacause this functions is being called from PK_EA_LOGIC_VS_PATIENT
            -- The entry in table DATA_GOV_EVENT was disable
            NULL;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_source_table_name = 'VITAL_SIGN_READ'
        THEN
            IF i_event_type = t_data_gov_mnt.g_event_insert
               OR i_event_type = t_data_gov_mnt.g_event_update
               OR i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                -- Process insert event
                pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                      g_package_name,
                                      l_func_proc_name);
            
                SELECT DISTINCT vsr.id_patient
                  BULK COLLECT
                  INTO tb_id_patient
                  FROM vital_sign_read vsr
                 WHERE vsr.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      column_value
                                       FROM TABLE(i_rowids) t)
                   AND vsr.id_patient IS NOT NULL
                   --AND vsr.flg_state != 'C'
                   ;
            
                   upd_viewer_ehr_ea( i_tbl_patient => tb_id_patient );
            
/*                IF tb_id_patient.count > 0
                THEN
                    MERGE INTO viewer_ehr_ea d
                    USING (SELECT aux.id_patient,
                                  'VITAL_SIGN.CODE_VITAL_SIGN.' || aux.id_vital_sign code_vital_sign,
                                  aux.l_count num_records,
                                  aux.dt_vital_sign_read_tstz date_tstz
                             FROM (SELECT t_vs.id_vital_sign_read,
                                          t_vs.id_vital_sign,
                                          t_vs.id_patient,
                                          t_vs.l_count,
                                          t_vs.dt_vital_sign_read_tstz
                                     FROM (SELECT t_vs2.id_vital_sign_read,
                                                  t_vs2.id_vital_sign,
                                                  t_vs2.id_patient,
                                                  t_vs2.dt_vital_sign_read_tstz,
                                                  t_vs2.rn,
                                                  COUNT(1) over(PARTITION BY t_vs2.id_patient) l_count
                                             FROM (SELECT vsr.id_vital_sign_read,
                                                          vspea.id_vital_sign,
                                                          vspea.id_patient,
                                                          vsr.dt_vital_sign_read_tstz,
                                                          row_number() over(PARTITION BY vspea.id_patient ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) rn,
                                                          row_number() over(PARTITION BY vspea.id_patient, vspea.id_vital_sign ORDER BY vsr.dt_vital_sign_read_tstz DESC NULLS LAST) rn2
                                                     FROM vs_patient_ea vspea
                                                    INNER JOIN vital_sign_read vsr
                                                       ON vspea.id_last_1_vsr = vsr.id_vital_sign_read
                                                      AND vsr.flg_state = pk_vital_sign.c_flg_status_active
                                                    WHERE 0=0--vsr.flg_state != 'C'
                                                      AND vsr.id_patient IN
                                                          (SELECT \*+opt_estimate (table t rows=1)*\
                                                            column_value
                                                             FROM TABLE(tb_id_patient) t)) t_vs2
                                            WHERE t_vs2.rn2 = 1) t_vs
                                    WHERE t_vs.rn = 1) aux) s
                    ON (d.id_patient = s.id_patient)
                    WHEN MATCHED THEN
                        UPDATE
                           SET d.num_vs  = s.num_records,
                               d.code_vs = s.code_vital_sign,
                               d.dt_vs   = s.date_tstz,
                               d.desc_vs = NULL;
                
                l_count := sql%rowcount;
                
                END IF;*/
            END IF;
        END IF;
    
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_VS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_vs;

    /**
    * Updates the NUM_NOTE, DESC_NOTE, DT_NOTE and DT_NOTE_FMT columns on the VIEWER_EHR_EA easy access table.
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, DELETE)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Sérgio Santos
    * @version 2.4.3-Denormalized
    * @since 2008/11/21
    */
    PROCEDURE set_pat_note
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_viewer_ehr_ea_rec viewer_ehr_ea%ROWTYPE;
    
        l_func_proc_name VARCHAR2(30);
    
        l_error_out t_error_out;
    
        --update variables
        l_num_note  PLS_INTEGER;
        l_desc_note viewer_ehr_ea.desc_note%TYPE;
        l_code_note viewer_ehr_ea.code_note%TYPE;
        l_dt_note   viewer_ehr_ea.dt_note%TYPE;
    
        l_rowids table_varchar;
        l_ret    BOOLEAN := FALSE;
    
        -- Records that were affected by the operation that triggered the event
        l_affected_records_note ts_epis_pn.epis_pn_tc;
    
        -- patient list to update
        l_pat_list table_number;
    
        --external function exception
        e_external_function EXCEPTION;
    
        -- auxiliary variable to store the current patient ID
        l_pat_id_aux patient.id_patient%TYPE;
    
        --cursor with the final information
        l_note_info pk_types.cursor_type;
    
        --title
        l_title VARCHAR2(4000 CHAR);
    
        --dummy variables
        l_dummy_vc VARCHAR2(4000 CHAR);
    
        l_dummy_num NUMBER;
    
        l_epis_pn_deleted ts_epis_pn.epis_pn_tc;
    
    BEGIN
        l_pat_list := table_number();
    
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
        l_func_proc_name := 'SET_PAT_NOTE';
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS';
        IF i_source_table_name = 'EPIS_PN'
        THEN
            l_ret := t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'EPIS_PN',
                                                       i_expected_dg_table_name => 'VIEWER_EHR_EA');
        END IF;
        IF NOT l_ret
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
        THEN
            -- Get affected records
            g_error := 'GET AFFECTED ROWS';
        
            IF i_source_table_name = 'EPIS_PN'
            THEN
                g_error                 := 'GET AFFECTED ROWS' || i_source_table_name;
                l_affected_records_note := ts_epis_pn.get_data_rowid(rows_in => i_rowids);
            
                IF l_affected_records_note IS NOT NULL
                   AND l_affected_records_note.count > 0
                THEN
                    FOR idx_affected IN l_affected_records_note.first .. l_affected_records_note.last
                    LOOP
                        --If the id_patient is null, we must search for it in the episode table
                        IF l_pat_id_aux IS NULL
                        THEN
                            SELECT e.id_patient
                              INTO l_pat_id_aux
                              FROM episode e
                             WHERE e.id_episode = l_affected_records_note(idx_affected).id_episode;
                        END IF;
                    
                        --Add the information to the list of patient to process
                        IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                        THEN
                            l_pat_list.extend;
                            l_pat_list(l_pat_list.count) := l_pat_id_aux;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
        END IF;
    
        IF (i_event_type = t_data_gov_mnt.g_event_delete)
        THEN
            l_epis_pn_deleted := ts_epis_pn.get_data_rowid_pat(rows_in => i_rowids);
            IF l_epis_pn_deleted.exists(1)
            THEN
                FOR i IN l_epis_pn_deleted.first .. l_epis_pn_deleted.last
                LOOP
                    g_error := 'CALL pk_episode.get_id_patient. id_episode: ' || l_epis_pn_deleted(i).id_episode;
                    pk_alertlog.log_debug(g_error, g_package_name, l_func_proc_name);
                    l_pat_id_aux := pk_episode.get_id_patient(i_episode => l_epis_pn_deleted(i).id_episode);
                
                    IF pk_utils.search_table_number(l_pat_list, l_pat_id_aux) = -1
                    THEN
                        l_pat_list.extend;
                        l_pat_list(l_pat_list.count) := l_pat_id_aux;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            pk_alertlog.log_debug('id_patient_in: ' || l_pat_list(i), g_package_name);
        
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'pk_prog_notes_utils.get_viewer_notes';
            IF NOT pk_prog_notes_utils.get_viewer_notes(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_pn_area  => NULL,
                                                        i_scope       => l_pat_list(i),
                                                        i_scope_type  => 'P',
                                                        i_flg_scope   => pk_prog_notes_constants.g_flg_scope_summary_s,
                                                        i_interval    => NULL,
                                                        o_data        => l_note_info,
                                                        o_title       => l_title,
                                                        o_screen_name => l_dummy_vc,
                                                        o_error       => l_error_out)
            THEN
                RAISE e_external_function;
            END IF;
        
            g_error := 'Fetch VS info';
            FETCH l_note_info
                INTO l_desc_note,
                     l_code_note,
                     l_num_note,
                     l_dummy_vc,
                     l_dummy_vc,
                     l_dummy_vc,
                     l_dt_note,
                     l_dummy_num,
                     l_dummy_num;
            CLOSE l_note_info;
        
            pk_alertlog.log_debug('id_patient_in: ' || l_pat_list(i), g_package_name);
            pk_alertlog.log_debug('num_note_in: ' || nvl(l_num_note, 0), g_package_name);
            pk_alertlog.log_debug('desc_note_in: ' || l_desc_note, g_package_name);
            pk_alertlog.log_debug('code_note_in: ' || l_code_note, g_package_name);
            pk_alertlog.log_debug('dt_note_in: ' || l_dt_note, g_package_name);
        
            -- Update easy access
            g_error := 'TS_VIEWER_EHR_EA.UPD';
            ts_viewer_ehr_ea.upd(id_patient_in => l_pat_list(i),
                                 num_note_in   => nvl(l_num_note, 0),
                                 desc_note_in  => l_desc_note,
                                 desc_note_nin => FALSE,
                                 code_note_in  => l_code_note,
                                 code_note_nin => FALSE,
                                 dt_note_in    => l_dt_note,
                                 dt_note_nin   => FALSE,
                                 rows_out      => l_rowids);
        
        END LOOP;
    
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_NOTE',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_note;

    PROCEDURE set_pat_bp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR2
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30) := 'SET_PAT_BP';
    
        --update variables
        l_num_bp  PLS_INTEGER;
        l_desc_bp viewer_ehr_ea.desc_bp%TYPE;
        l_code_bp viewer_ehr_ea.code_bp%TYPE;
        l_dt_bp   viewer_ehr_ea.dt_bp%TYPE;
    
        l_rowids   table_varchar;
        l_pat_list table_number := table_number();
    
        --external function exception
        e_external_function EXCEPTION;
    
        --variable to store the error message
        l_error t_error_out;
    BEGIN
        pk_alertlog.log_debug('ENTROU: ' || i_rowids.count, g_package_name);
    
        -- Validate arguments
        g_error := 'VALIDATE_ARGUMENTS ' || i_source_table_name;
        IF i_source_table_name = 'BLOOD_PRODUCT_DET'
        THEN
            g_error := g_error || 'BLOOD_PRODUCT_DET';
            IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                     i_source_table_name      => i_source_table_name,
                                                     i_dg_table_name          => i_dg_table_name,
                                                     i_expected_table_name    => 'BLOOD_PRODUCT_DET',
                                                     i_expected_dg_table_name => 'VIEWER_EHR_EA')
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
        -- Check event type
        g_error := 'CHECK EVENT TYPE';
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
           OR i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Process insert event
            pk_alertlog.log_debug('Processing ' || i_event_type || ' on ' || i_source_table_name,
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Get affected records
            g_error    := 'GET AFFECTED ROWS';
            l_pat_list := get_interv_affected_patients(i_lang, i_source_table_name, i_rowids);
        
        END IF;
    
        -- Loop through the affected patient list and update the information
        FOR i IN 1 .. l_pat_list.count
        LOOP
            -- Obtain all the information from the patient problems to insert in the viewer_ehr_ea table
            g_error := 'PK_PROCEDURES_EXTERNAL_API_DB.GET_COUNT_AND_FIRST';
            IF NOT pk_bp_external_api_db.get_count_and_first(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_patient     => l_pat_list(i),
                                                             i_episode     => NULL,
                                                             i_viewer_area => pk_hibernate_intf.g_ordered_list_ehr,
                                                             o_num_occur   => l_num_bp,
                                                             o_desc_first  => l_desc_bp,
                                                             o_code_first  => l_code_bp,
                                                             o_dt_first    => l_dt_bp,
                                                             o_error       => l_error)
            THEN
                RAISE e_external_function;
            END IF;
        
            pk_alertlog.log_debug('antes do update à viewer_ehr_ea, count=' || l_num_bp || ', id_patient=' ||
                                  l_pat_list(1),
                                  g_package_name,
                                  l_func_proc_name);
            -- Update easy access table
            ts_viewer_ehr_ea.upd(id_patient_in   => l_pat_list(i),
                                 num_interv_in   => nvl(l_num_bp, 0),
                                 desc_interv_in  => l_desc_bp,
                                 desc_interv_nin => FALSE,
                                 code_interv_in  => l_code_bp,
                                 code_interv_nin => FALSE,
                                 dt_interv_in    => l_dt_bp,
                                 dt_interv_nin   => FALSE,
                                 rows_out        => l_rowids);
        
        END LOOP;
    EXCEPTION
        WHEN e_external_function THEN
            -- External function error
            pk_alert_exceptions.raise_error(name1_in => 'EXTERNAL FUNCTION ERROR', error_code_in => SQLCODE);
            pk_utils.undo_changes;
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            --Invalid arguments error
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_INTERV',
                                              l_error);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
    END set_pat_bp;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ea_logic_viewer;
/
