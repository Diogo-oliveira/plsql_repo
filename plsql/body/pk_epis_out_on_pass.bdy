/*-- Last Change Revision: $Rev: 2027125 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:06 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_epis_out_on_pass IS

    /* CAN'T TOUCH THIS */
    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval       BOOLEAN;

    -- indexes to be used in workflows (table_varchar)
    g_idx_id_epis_out_on_pass CONSTANT PLS_INTEGER := 1;

    /**********************************************************************************************
    * Initialize params for filters - Epis out on pass
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Adriana Ramos
    * @since                         10/04/2019
    **********************************************************************************************/
    PROCEDURE init_params_epis_out_on_pass
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
        
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT NUMBER := i_context_ids(g_patient);
        l_episode CONSTANT NUMBER := i_context_ids(g_episode);
        l_error t_error_out;
    
    BEGIN
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'INIT_PARAMS_EPIS_OUT_ON_PASS');
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_institution', l_prof.institution);
        pk_context_api.set_parameter('i_software', l_prof.software);
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'g_id_visit' THEN
                o_id := pk_visit.get_visit(i_episode => l_episode, o_error => l_error);
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            WHEN 'g_status_out_on_pass_completed' THEN
                o_id := pk_alert_constant.g_status_out_on_pass_completed;
            WHEN 'g_status_out_on_pass_cancelled' THEN
                o_id := pk_alert_constant.g_status_out_on_pass_cancelled;
            WHEN 'g_status_out_on_pass_active' THEN
                o_id := pk_alert_constant.g_status_out_on_pass_active;
            WHEN 'g_status_out_on_pass_ongoing' THEN
                o_id := pk_alert_constant.g_status_out_on_pass_ongoing;
        END CASE;
        --dbms_output.put_line(i_name || ':' || o_vc2 || ' ' || to_char(o_id));
    END init_params_epis_out_on_pass;

    /********************************************************************************************
    * Process EPIS_OUT_ON_PASS data gov events - EPIS_OUT_ON_PASS_H inserts/updates
    *
    * @author          Adriana Ramos
    * @since           10/04/2019
    ********************************************************************************************/
    PROCEDURE set_epis_out_on_pass_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids table_varchar;
    
        coll_epis_out_on_pass_h ts_epis_out_on_pass_h.epis_out_on_pass_h_tc;
        coll_epis_out_on_pass   ts_epis_out_on_pass.epis_out_on_pass_tc;
    
        l_hist_code_transaction      epis_out_on_pass_h.hist_code_transaction%TYPE;
        l_hist_dbid                  epis_out_on_pass_h.hist_dbid%TYPE;
        l_code_request_reason        CLOB;
        l_code_note_admission_office CLOB;
        l_code_other_notes           CLOB;
        l_code_cancel_reason         CLOB;
        l_code_conclude_notes        CLOB;
        l_code_start_notes           CLOB;
        l_code_requested_by          CLOB;
    
        l_where    VARCHAR2(1000);
        l_hist_rec PLS_INTEGER;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT alert.t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                       i_source_table_name      => i_source_table_name,
                                                       i_dg_table_name          => i_dg_table_name,
                                                       i_expected_table_name    => 'EPIS_OUT_ON_PASS',
                                                       i_expected_dg_table_name => 'EPIS_OUT_ON_PASS_H',
                                                       i_list_columns           => i_list_columns,
                                                       i_expected_columns       => NULL)
        THEN
            RAISE alert.t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        g_error := 'LOOP INSERTED';
        IF i_rowids IS NOT NULL
           AND i_rowids.count > 0
        THEN
        
            SELECT /*+RULE */
             *
              BULK COLLECT
              INTO coll_epis_out_on_pass
              FROM epis_out_on_pass
             WHERE ROWID IN (SELECT column_value
                               FROM TABLE(i_rowids) t);
        
            IF (coll_epis_out_on_pass.count > 0)
            THEN
            
                FOR i IN coll_epis_out_on_pass.first .. coll_epis_out_on_pass.last
                LOOP
                    l_hist_code_transaction := pk_utils.get_transaction_code();
                    l_hist_dbid             := pk_utils.get_dbid();
                
                    l_code_request_reason        := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_request_reason);
                    l_code_note_admission_office := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_note_admission_office);
                    l_code_other_notes           := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_other_notes);
                    l_code_cancel_reason         := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_cancel_reason);
                    l_code_conclude_notes        := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_conclude_notes);
                    l_code_start_notes           := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_start_notes);
                    l_code_requested_by          := pk_translation.get_translation_trs(coll_epis_out_on_pass(i).code_requested_by);
                
                    SELECT COUNT(*)
                      INTO l_hist_rec
                      FROM epis_out_on_pass_h
                     WHERE hist_code_transaction = l_hist_code_transaction
                       AND id_epis_out_on_pass = coll_epis_out_on_pass(i).id_epis_out_on_pass;
                
                    coll_epis_out_on_pass_h(i).id_epis_out_on_pass := coll_epis_out_on_pass(i).id_epis_out_on_pass;
                    coll_epis_out_on_pass_h(i).id_patient := coll_epis_out_on_pass(i).id_patient;
                    coll_epis_out_on_pass_h(i).id_episode := coll_epis_out_on_pass(i).id_episode;
                    coll_epis_out_on_pass_h(i).id_status := coll_epis_out_on_pass(i).id_status;
                    coll_epis_out_on_pass_h(i).id_request_reason := coll_epis_out_on_pass(i).id_request_reason;
                    coll_epis_out_on_pass_h(i).code_request_reason := l_code_request_reason;
                    coll_epis_out_on_pass_h(i).dt_out := coll_epis_out_on_pass(i).dt_out;
                    coll_epis_out_on_pass_h(i).dt_in := coll_epis_out_on_pass(i).dt_in;
                    coll_epis_out_on_pass_h(i).total_allowed_hours := coll_epis_out_on_pass(i).total_allowed_hours;
                    coll_epis_out_on_pass_h(i).flg_attending_physic_agree := coll_epis_out_on_pass(i).flg_attending_physic_agree;
                    coll_epis_out_on_pass_h(i).code_note_admission_office := l_code_note_admission_office;
                    coll_epis_out_on_pass_h(i).code_other_notes := l_code_other_notes;
                    coll_epis_out_on_pass_h(i).id_conclude_reason := coll_epis_out_on_pass(i).id_conclude_reason;
                    coll_epis_out_on_pass_h(i).id_cancel_reason := coll_epis_out_on_pass(i).id_cancel_reason;
                    coll_epis_out_on_pass_h(i).code_cancel_reason := l_code_cancel_reason;
                    coll_epis_out_on_pass_h(i).dt_last_update := coll_epis_out_on_pass(i).dt_last_update;
                    coll_epis_out_on_pass_h(i).id_prof_last_update := coll_epis_out_on_pass(i).id_prof_last_update;
                    coll_epis_out_on_pass_h(i).id_workflow := coll_epis_out_on_pass(i).id_workflow;
                    coll_epis_out_on_pass_h(i).dt_in_returned := coll_epis_out_on_pass(i).dt_in_returned;
                    coll_epis_out_on_pass_h(i).code_conclude_notes := l_code_conclude_notes;
                    coll_epis_out_on_pass_h(i).code_start_notes := l_code_start_notes;
                    coll_epis_out_on_pass_h(i).id_requested_by := coll_epis_out_on_pass(i).id_requested_by;
                    coll_epis_out_on_pass_h(i).code_requested_by := l_code_requested_by;
                    coll_epis_out_on_pass_h(i).patient_contact_number := coll_epis_out_on_pass(i).patient_contact_number;
                    coll_epis_out_on_pass_h(i).flg_all_med_adm := coll_epis_out_on_pass(i).flg_all_med_adm;
                    --
                    coll_epis_out_on_pass_h(i).create_user := coll_epis_out_on_pass(i).create_user;
                    coll_epis_out_on_pass_h(i).create_time := coll_epis_out_on_pass(i).create_time;
                    coll_epis_out_on_pass_h(i).create_institution := coll_epis_out_on_pass(i).create_institution;
                    coll_epis_out_on_pass_h(i).update_user := coll_epis_out_on_pass(i).update_user;
                    coll_epis_out_on_pass_h(i).update_time := coll_epis_out_on_pass(i).update_time;
                    coll_epis_out_on_pass_h(i).update_institution := coll_epis_out_on_pass(i).update_institution;
                    ---
                    coll_epis_out_on_pass_h(i).hist_dml := i_event_type;
                    coll_epis_out_on_pass_h(i).hist_code_transaction := l_hist_code_transaction;
                    coll_epis_out_on_pass_h(i).hist_dbid := l_hist_dbid;
                    coll_epis_out_on_pass_h(i).hist_dt_create := current_timestamp;
                
                    -- Check event type
                    IF i_event_type = alert.t_data_gov_mnt.g_event_insert
                    THEN
                    
                        g_error := 'ts_epis_out_on_pass_h.ins /';
                        ts_epis_out_on_pass_h.ins(rec_in          => coll_epis_out_on_pass_h(i),
                                                  handle_error_in => FALSE,
                                                  rows_out        => l_rowids);
                    
                    ELSIF i_event_type = alert.t_data_gov_mnt.g_event_update
                          AND l_hist_rec > 0
                    THEN
                        l_where := ' hist_code_transaction = ''' || l_hist_code_transaction ||
                                   ''' AND id_epis_out_on_pass = ' || coll_epis_out_on_pass(i).id_epis_out_on_pass;
                    
                        g_error := 'ts_epis_out_on_pass_h.upd / WHERE=' || l_where; --double_check
                        pk_alertlog.log_debug(g_error);
                        ts_epis_out_on_pass_h.upd(id_patient_in                 => coll_epis_out_on_pass_h(i).id_patient,
                                                  id_episode_in                 => coll_epis_out_on_pass_h(i).id_episode,
                                                  id_status_in                  => coll_epis_out_on_pass_h(i).id_status,
                                                  id_request_reason_in          => coll_epis_out_on_pass_h(i).id_request_reason,
                                                  code_request_reason_in        => coll_epis_out_on_pass_h(i).code_request_reason,
                                                  dt_out_in                     => coll_epis_out_on_pass_h(i).dt_out,
                                                  dt_in_in                      => coll_epis_out_on_pass_h(i).dt_in,
                                                  total_allowed_hours_in        => coll_epis_out_on_pass_h(i).total_allowed_hours,
                                                  flg_attending_physic_agree_in => coll_epis_out_on_pass_h(i).flg_attending_physic_agree,
                                                  code_note_admission_office_in => coll_epis_out_on_pass_h(i).code_note_admission_office,
                                                  code_other_notes_in           => coll_epis_out_on_pass_h(i).code_other_notes,
                                                  id_conclude_reason_in         => coll_epis_out_on_pass_h(i).id_conclude_reason,
                                                  id_cancel_reason_in           => coll_epis_out_on_pass_h(i).id_cancel_reason,
                                                  code_cancel_reason_in         => coll_epis_out_on_pass_h(i).code_cancel_reason,
                                                  dt_last_update_in             => coll_epis_out_on_pass_h(i).dt_last_update,
                                                  id_prof_last_update_in        => coll_epis_out_on_pass_h(i).id_prof_last_update,
                                                  id_workflow_in                => coll_epis_out_on_pass_h(i).id_workflow,
                                                  dt_in_returned_in             => coll_epis_out_on_pass_h(i).dt_in_returned,
                                                  code_conclude_notes_in        => coll_epis_out_on_pass_h(i).code_conclude_notes,
                                                  code_start_notes_in           => coll_epis_out_on_pass_h(i).code_start_notes,
                                                  id_requested_by_in            => coll_epis_out_on_pass_h(i).id_requested_by,
                                                  code_requested_by_in          => coll_epis_out_on_pass_h(i).code_requested_by,
                                                  patient_contact_number_in     => coll_epis_out_on_pass_h(i).patient_contact_number,
                                                  flg_all_med_adm_in            => coll_epis_out_on_pass_h(i).flg_all_med_adm,
                                                  where_in                      => l_where,
                                                  handle_error_in               => FALSE,
                                                  rows_out                      => l_rowids);
                    
                    ELSIF i_event_type = alert.t_data_gov_mnt.g_event_update
                          AND l_hist_rec = 0
                    THEN
                        g_error := 'ts_epis_out_on_pass_h.ins /';
                        pk_alertlog.log_debug(g_error);
                        ts_epis_out_on_pass_h.ins(rec_in          => coll_epis_out_on_pass_h(i),
                                                  handle_error_in => FALSE,
                                                  rows_out        => l_rowids);
                    
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN alert.t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_epis_out_on_pass_h;

    /********************************************************************************************
    * Return rank of the status
    *
    * @author          Adriana Ramos
    * @since           12/04/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN epis_out_on_pass.id_status%TYPE
    ) RETURN NUMBER IS
        l_rank wf_status.rank%TYPE;
    
    BEGIN
        SELECT ws.rank
          INTO l_rank
          FROM wf_status ws
         WHERE ws.id_status = i_id_status;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_out_on_pass_rank;

    /**
    * Initializes table_varchar as input of workflow transition function
    *
    * @param   i_lang                    Professional preferred language
    * @param   i_prof                    Professional identification and its context (institution and software)   
    * @param   i_id_epis_out_on_pass     Epis out on pass identifier
    *
    * @return  table_varchar             input of workflow transition function
    *
    * @author  Adriana Ramos
    * @since   17/04/2019
    **/
    FUNCTION init_wf_params
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'init_wf_params';
        l_params VARCHAR2(1000 CHAR);
        l_result table_varchar;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_epis_out_on_pass=' ||
                    i_id_epis_out_on_pass;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        l_result := table_varchar();
        l_result.extend(1);
    
        l_result(g_idx_id_epis_out_on_pass) := i_id_epis_out_on_pass;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END init_wf_params;

    /**
    * Check if a transition is valid
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_workflow                Workflow identifier
    * @param   i_id_status_begin            Begin status identifier
    * @param   i_id_status_end              End status identifier
    * @param   i_id_workflow_action         Workflow action identifier
    * @param   i_id_category                Category identifier
    * @param   i_id_profile_template        Profile template identifier   
    * @param   i_id_epis_out_on_pass        Epis out on pass identifier
    *
    * @return  varchar2                     'Y'- transition allowed 'N'- transition denied
    *
    * @author  Adriana Ramos
    * @since   17/04/2019
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN print_list_job.id_workflow%TYPE,
        i_id_status_begin     IN print_list_job.id_status%TYPE,
        i_id_status_end       IN print_list_job.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_transition';
        l_params              VARCHAR2(1000 CHAR);
        l_wf_params           table_varchar;
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_result              VARCHAR2(1 CHAR);
        l_error_out           t_error_out;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_workflow=' ||
                    i_id_workflow || ' i_id_status_begin=' || i_id_status_begin || ' i_id_status_end=' ||
                    i_id_status_end || ' i_id_workflow_action=' || i_id_workflow_action || ' i_id_category=' ||
                    i_id_category || ' i_id_profile_template=' || i_id_profile_template || ' i_id_epis_out_on_pass=' ||
                    i_id_epis_out_on_pass;
    
        -- init
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        l_result := pk_alert_constant.g_no;
    
        -- func
        l_id_category         := nvl(i_id_category, pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
        l_id_profile_template := nvl(i_id_profile_template, pk_tools.get_prof_profile_template(i_prof));
    
        -- check workflow permission
        g_error     := 'Call init_wf_params / ' || l_params;
        l_wf_params := init_wf_params(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_epis_out_on_pass => i_id_epis_out_on_pass);
    
        g_error  := 'Call pk_workflow.check_transition / ' || l_params;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => i_id_workflow,
                                                 i_id_status_begin     => i_id_status_begin,
                                                 i_id_status_end       => i_id_status_end,
                                                 i_id_workflow_action  => i_id_workflow_action,
                                                 i_id_category         => l_id_category,
                                                 i_id_profile_template => l_id_profile_template,
                                                 i_id_functionality    => 0,
                                                 i_param               => l_wf_params,
                                                 o_flg_available       => l_result,
                                                 o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_no;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN pk_alert_constant.g_no;
    END check_transition;

    /**
    * Gets parameter values of framework workflow into separate variables
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_wf_params            Epis out on pass information 
    * @param   o_id_epis_out_on_pass  Epis out on pass identifier
    * @param   o_error                Error information
    *   
    * @RETURN  boolean              TRUE if sucess, FALSE otherwise
    *
    * @author  Adriana Ramos
    * @since   17/04/2019
    */
    FUNCTION get_wf_params_values
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_wf_params           IN table_varchar,
        o_id_epis_out_on_pass OUT epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_wf_params_values';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_wf_params=' ||
                    pk_utils.to_string(i_wf_params);
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- getting values from i_wf_params
        IF i_wf_params.exists(g_idx_id_epis_out_on_pass)
        THEN
            o_id_epis_out_on_pass := i_wf_params(g_idx_id_epis_out_on_pass);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_wf_params_values;

    /**
    * Check if star action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_start
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'CHECK_CAN_START';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
        l_exists              NUMBER;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_epis_out_on_pass => l_id_epis_out_on_pass,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        IF i_category = 4
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        SELECT COUNT(1)
          INTO l_exists
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = l_id_epis_out_on_pass
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass
           AND eoop.id_status IN (pk_alert_constant.g_status_out_on_pass_ongoing,
                                  pk_alert_constant.g_status_out_on_pass_completed,
                                  pk_alert_constant.g_status_out_on_pass_cancelled);
    
        IF l_exists > 0
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        RETURN pk_workflow.g_transition_allow;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_workflow.g_transition_deny;
    END check_can_start;

    /**
    * Check if edit action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_edit';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
        l_id_category         category.id_category%TYPE;
        l_id_status           epis_out_on_pass.id_status%TYPE;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_epis_out_on_pass => l_id_epis_out_on_pass,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        SELECT eoop.id_status
          INTO l_id_status
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = l_id_epis_out_on_pass
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass
           AND eoop.id_status IN
               (pk_alert_constant.g_status_out_on_pass_active, pk_alert_constant.g_status_out_on_pass_ongoing);
    
        IF l_id_status != pk_alert_constant.g_status_out_on_pass_active
           AND l_id_category != pk_alert_constant.g_cat_id_administrative_clerk
        THEN
            RETURN pk_workflow.g_transition_deny;
        ELSE
            RETURN pk_workflow.g_transition_allow;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_workflow.g_transition_deny;
    END check_can_edit;

    /**
    * Check if complete action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_complete';
        l_params    VARCHAR2(1000 CHAR);
        l_error_out t_error_out;
    
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
        l_exists              NUMBER;
    
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_epis_out_on_pass => l_id_epis_out_on_pass,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        IF i_category = 4
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        SELECT COUNT(1)
          INTO l_exists
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = l_id_epis_out_on_pass
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass
           AND eoop.id_status IN (pk_alert_constant.g_status_out_on_pass_active,
                                  pk_alert_constant.g_status_out_on_pass_completed,
                                  pk_alert_constant.g_status_out_on_pass_cancelled);
    
        IF l_exists > 0
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        RETURN pk_workflow.g_transition_allow;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_workflow.g_transition_deny;
    END check_can_complete;

    /**
    * Check if cancel action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_cancel';
        l_params              VARCHAR2(1000 CHAR);
        l_error_out           t_error_out;
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
    
        l_exists NUMBER;
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_workflow=' || i_workflow ||
                    ' i_status_begin=' || i_status_begin || ' i_status_end=' || i_status_end || ' i_workflow_action=' ||
                    i_workflow_action || ' i_category=' || i_category || ' i_profile=' || i_profile || ' i_func=' ||
                    i_func || ' i_param=' || pk_utils.to_string(i_param);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func       
        g_retval := get_wf_params_values(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_wf_params           => i_param,
                                         o_id_epis_out_on_pass => l_id_epis_out_on_pass,
                                         o_error               => l_error_out);
    
        IF NOT g_retval
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        IF i_category = 4
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        SELECT COUNT(1)
          INTO l_exists
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = l_id_epis_out_on_pass
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass
           AND eoop.id_status IN (pk_alert_constant.g_status_out_on_pass_completed,
                                  pk_alert_constant.g_status_out_on_pass_cancelled,
                                  pk_alert_constant.g_status_out_on_pass_ongoing);
    
        IF l_exists > 0
        THEN
            RETURN pk_workflow.g_transition_deny;
        END IF;
    
        RETURN pk_workflow.g_transition_allow;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_workflow.g_transition_deny;
    END check_can_cancel;

    /**
    * Checks an action is active or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)        
    * @param   i_id_action                  Action identifier
    * @param   i_internal_name              Action internal name
    * @param   i_id_epis_out_on_pass        Epis out on pass identifier
    * @param   o_error                      Error information
    *
    * @return  varchar2                     'A'- action is active 'I'- action is inactive
    *
    * @author  Adriana Ramos
    * @since   17/04/2019
    */
    FUNCTION check_action_active
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_internal_name       IN action.internal_name%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_action_active';
        l_params              VARCHAR2(1000 CHAR);
        l_error               t_error_out;
        l_result              VARCHAR2(1 CHAR);
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_count               PLS_INTEGER;
        l_epis_out_on_pass    epis_out_on_pass%ROWTYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_action=' || i_id_action || ' i_internal_name=' ||
                    i_internal_name || ' i_id_epis_out_on_pass=' || i_id_epis_out_on_pass;
    
        -- init
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
        l_result := pk_alert_constant.g_no;
    
        -- func
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        SELECT eoop.*
          INTO l_epis_out_on_pass
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        g_error := 'Call PK_WORKFLOW.get_wf_action_trans / ' || l_params;
        SELECT /*+opt_estimate (table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM TABLE(CAST(pk_workflow.get_wf_action_trans(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_action          => i_id_action,
                                                          i_id_workflow     => l_epis_out_on_pass.id_workflow,
                                                          i_id_status_begin => l_epis_out_on_pass.id_status) AS
                          t_coll_wf_action)) t
         WHERE check_transition(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_id_workflow         => t.id_workflow,
                                i_id_status_begin     => t.id_status_begin,
                                i_id_status_end       => t.id_status_end,
                                i_id_workflow_action  => t.id_workflow_action,
                                i_id_category         => l_id_category,
                                i_id_profile_template => l_id_profile_template,
                                i_id_epis_out_on_pass => l_epis_out_on_pass.id_epis_out_on_pass) =
               pk_alert_constant.g_yes;
    
        IF l_count > 0
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        -- convert yes and no to active and inactive
        g_error := 'l_result=' || l_result || ' / ' || l_params;
        IF l_result = pk_alert_constant.g_yes
        THEN
            l_result := pk_alert_constant.g_active;
        ELSIF l_result = pk_alert_constant.g_no
        THEN
            l_result := pk_alert_constant.g_inactive;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN pk_alert_constant.g_inactive;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_inactive;
    END check_action_active;

    /**
    * Gets actions available for the out on pass
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_epis_out_on_pass        Epis_out_on_pass identifier
    * @param   o_actions                    List of actions available
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Adriana Ramos
    * @since   2019/04/17
    */
    FUNCTION get_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_actions';
        l_params  VARCHAR2(1000 CHAR);
        l_actions t_coll_action;
    BEGIN
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func
        -- all actions are listed in table action under subject OUT_ON_PASS
        -- Each action is checked with function check_action_active
        g_error   := 'Call pk_action.tf_get_actions_permissions / ' || l_params;
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => pk_alert_constant.g_subject_out_on_pass,
                                              i_from_state => NULL);
    
        g_error := 'OPEN o_list FOR / ' || l_params;
        OPEN o_actions FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             t.id_action,
             t.id_parent,
             t.level_nr AS "LEVEL",
             t.from_state,
             t.to_state,
             t.desc_action,
             t.icon,
             t.flg_default,
             check_action_active(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_id_action           => t.id_action,
                                 i_internal_name       => t.action,
                                 i_id_epis_out_on_pass => i_id_epis_out_on_pass) flg_active,
             t.action
              FROM TABLE(CAST(l_actions AS t_coll_action)) t
             ORDER BY t.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION check_epis_out_on_pass_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count  PLS_INTEGER;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_out_on_pass eoop
         WHERE eoop.id_episode = i_id_episode
           AND eoop.id_status = pk_alert_constant.g_status_out_on_pass_ongoing
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass;
    
        IF l_count > 0
        THEN
            l_result := pk_alert_constant.g_yes;
        ELSE
            l_result := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_epis_out_on_pass_active;

    FUNCTION set_cancel_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_id_cancel_reason    IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_reason       IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_CANCEL_EPIS_OUT_ON_PASS';
    
        l_code_cancel_reason epis_out_on_pass.code_cancel_reason%TYPE;
        l_timestamp          TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_rowid              table_varchar;
    
    BEGIN
    
        IF i_id_epis_out_on_pass IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_cancel_reason IS NOT NULL
        THEN
            l_code_cancel_reason := pk_alert_constant.g_out_on_pass_cancel_reason || i_id_epis_out_on_pass;
        
            g_error := 'CALL pk_translation.insert_translation_trs_bulk-cancel_reason';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
            pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                       i_code   => table_varchar(l_code_cancel_reason),
                                                       i_desc   => table_clob(i_cancel_reason),
                                                       i_module => pk_alert_constant.g_out_on_pass_cancel_reason_ar);
        END IF;
    
        g_error := 'Call ts_epis_out_on_pass.upd: ';
        g_error := g_error || 'id_epis_out_on_pass = ' || i_id_epis_out_on_pass;
        pk_alertlog.log_debug(g_error);
        -- update epis_out_on_pass
        ts_epis_out_on_pass.upd(id_epis_out_on_pass_in => i_id_epis_out_on_pass,
                                id_status_in           => pk_alert_constant.g_status_out_on_pass_cancelled,
                                id_cancel_reason_in    => i_id_cancel_reason,
                                dt_last_update_in      => l_timestamp,
                                id_prof_last_update_in => i_prof.id,
                                id_workflow_in         => pk_alert_constant.g_wf_epis_out_on_pass,
                                handle_error_in        => FALSE,
                                rows_out               => l_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_OUT_ON_PASS',
                                      i_rowids     => l_rowid,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END set_cancel_epis_out_on_pass;

    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        o_dt_in               OUT epis_out_on_pass.dt_in%TYPE,
        o_dt_out              OUT epis_out_on_pass.dt_out%TYPE,
        o_total_allowed_hours OUT epis_out_on_pass.total_allowed_hours%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(60 CHAR) := 'get_epis_out_on_pass_info';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        SELECT eoop.dt_in, eoop.dt_out, eoop.total_allowed_hours
          INTO o_dt_in, o_dt_out, o_total_allowed_hours
          FROM epis_out_on_pass eoop
         WHERE eoop.id_episode = i_id_episode
           AND eoop.id_status = pk_alert_constant.g_status_out_on_pass_ongoing
           AND eoop.id_workflow = pk_alert_constant.g_wf_epis_out_on_pass
           AND rownum = 1
         ORDER BY eoop.dt_out DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_info;

    FUNCTION update_epis_out_on_pass
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_epis_out_on_pass        IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_id_request_reason          IN epis_out_on_pass.id_request_reason%TYPE,
        i_request_reason             IN VARCHAR2,
        i_dt_out                     IN epis_out_on_pass.dt_out%TYPE,
        i_dt_in                      IN epis_out_on_pass.dt_in%TYPE,
        i_total_allowed_hours        IN epis_out_on_pass.total_allowed_hours%TYPE,
        i_flg_attending_physic_agree IN epis_out_on_pass.flg_attending_physic_agree%TYPE,
        i_id_requested_by            IN epis_out_on_pass.id_requested_by%TYPE,
        i_requested_by               IN VARCHAR2,
        i_patient_contact_number     IN epis_out_on_pass.patient_contact_number%TYPE,
        i_other_notes                IN VARCHAR2,
        i_note_admission_office      IN VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'UPDATE_EPIS_OUT_ON_PASS';
    
        l_code_request_reason        epis_out_on_pass.code_request_reason%TYPE;
        l_code_other_notes           epis_out_on_pass.code_other_notes%TYPE;
        l_code_note_admission_office epis_out_on_pass.code_note_admission_office%TYPE;
        l_code_requested_by          epis_out_on_pass.code_requested_by%TYPE;
        l_id_status                  epis_out_on_pass.id_status%TYPE;
        l_timestamp                  TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_rowid                      table_varchar;
    
    BEGIN
    
        IF i_id_epis_out_on_pass IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_code_request_reason := pk_alert_constant.g_out_on_pass_request_reason || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_request_reason),
                                                   i_desc   => table_clob(i_request_reason),
                                                   i_module => pk_alert_constant.g_out_on_pass_reqst_reason_ar);
    
        l_code_requested_by := pk_alert_constant.g_out_on_pass_requested_by || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_requested_by),
                                                   i_desc   => table_clob(i_requested_by),
                                                   i_module => pk_alert_constant.g_out_on_pass_requested_by_ar);
    
        l_code_other_notes := pk_alert_constant.g_out_on_pass_other_notes || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_other_notes),
                                                   i_desc   => table_clob(i_other_notes),
                                                   i_module => pk_alert_constant.g_out_on_pass_other_notes_ar);
    
        l_code_note_admission_office := pk_alert_constant.g_out_on_pass_note_admis_offic || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_note_admission_office),
                                                   i_desc   => table_clob(i_note_admission_office),
                                                   i_module => pk_alert_constant.g_out_on_pass_note_adm_offi_ar);
    
        SELECT eoop.id_status
          INTO l_id_status
          FROM epis_out_on_pass eoop
         WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        g_error := 'Call ts_epis_out_on_pass.upd: ';
        g_error := g_error || 'id_epis_out_on_pass = ' || i_id_epis_out_on_pass;
        pk_alertlog.log_debug(g_error);
        -- update epis_out_on_pass
        ts_epis_out_on_pass.upd(id_epis_out_on_pass_in        => i_id_epis_out_on_pass,
                                id_status_in                  => l_id_status,
                                id_request_reason_in          => i_id_request_reason,
                                dt_out_in                     => i_dt_out,
                                dt_in_in                      => i_dt_in,
                                total_allowed_hours_in        => i_total_allowed_hours,
                                flg_attending_physic_agree_in => i_flg_attending_physic_agree,
                                dt_last_update_in             => l_timestamp,
                                id_prof_last_update_in        => i_prof.id,
                                id_workflow_in                => pk_alert_constant.g_wf_epis_out_on_pass,
                                id_requested_by_in            => i_id_requested_by,
                                patient_contact_number_in     => i_patient_contact_number,
                                handle_error_in               => FALSE,
                                rows_out                      => l_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_OUT_ON_PASS',
                                      i_rowids     => l_rowid,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END update_epis_out_on_pass;

    FUNCTION create_epis_out_on_pass
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_patient                 IN epis_out_on_pass.id_patient%TYPE,
        i_id_episode                 IN epis_out_on_pass.id_episode%TYPE,
        i_id_request_reason          IN epis_out_on_pass.id_request_reason%TYPE,
        i_request_reason             IN VARCHAR2,
        i_dt_out                     IN epis_out_on_pass.dt_out%TYPE,
        i_dt_in                      IN epis_out_on_pass.dt_in%TYPE,
        i_total_allowed_hours        IN epis_out_on_pass.total_allowed_hours%TYPE,
        i_flg_attending_physic_agree IN epis_out_on_pass.flg_attending_physic_agree%TYPE,
        i_id_requested_by            IN epis_out_on_pass.id_requested_by%TYPE,
        i_requested_by               IN VARCHAR2,
        i_patient_contact_number     IN epis_out_on_pass.patient_contact_number%TYPE,
        i_other_notes                IN VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'CREATE_EPIS_OUT_ON_PASS';
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
        l_code_request_reason epis_out_on_pass.code_request_reason%TYPE;
        l_code_other_notes    epis_out_on_pass.code_other_notes%TYPE;
        l_code_requested_by   epis_out_on_pass.code_requested_by%TYPE;
        l_timestamp           TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_rowid               table_varchar;
    
    BEGIN
    
        g_error := 'Call ts_epis_out_on_pass.ins: ';
        -- create epis_out_on_pass
        l_id_epis_out_on_pass := ts_epis_out_on_pass.ins(id_patient_in                 => i_id_patient,
                                                         id_episode_in                 => i_id_episode,
                                                         id_status_in                  => pk_alert_constant.g_status_out_on_pass_active,
                                                         id_request_reason_in          => i_id_request_reason,
                                                         dt_out_in                     => i_dt_out,
                                                         dt_in_in                      => i_dt_in,
                                                         total_allowed_hours_in        => i_total_allowed_hours,
                                                         flg_attending_physic_agree_in => i_flg_attending_physic_agree,
                                                         dt_last_update_in             => l_timestamp,
                                                         id_prof_last_update_in        => i_prof.id,
                                                         id_workflow_in                => pk_alert_constant.g_wf_epis_out_on_pass,
                                                         id_requested_by_in            => i_id_requested_by,
                                                         patient_contact_number_in     => i_patient_contact_number,
                                                         handle_error_in               => FALSE,
                                                         rows_out                      => l_rowid);
    
        l_code_request_reason := pk_alert_constant.g_out_on_pass_request_reason || l_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_request_reason),
                                                   i_desc   => table_clob(i_request_reason),
                                                   i_module => pk_alert_constant.g_out_on_pass_reqst_reason_ar);
    
        l_code_other_notes := pk_alert_constant.g_out_on_pass_other_notes || l_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_other_notes),
                                                   i_desc   => table_clob(i_other_notes),
                                                   i_module => pk_alert_constant.g_out_on_pass_other_notes_ar);
    
        l_code_requested_by := pk_alert_constant.g_out_on_pass_requested_by || l_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-requested_by';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_requested_by),
                                                   i_desc   => table_clob(i_requested_by),
                                                   i_module => pk_alert_constant.g_out_on_pass_requested_by_ar);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_OUT_ON_PASS',
                                      i_rowids     => l_rowid,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END create_epis_out_on_pass;

    FUNCTION complete_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_dt_in_returned      IN epis_out_on_pass.dt_in_returned%TYPE,
        i_id_conclude_reason  IN epis_out_on_pass.id_conclude_reason%TYPE,
        i_conclude_notes      IN VARCHAR2,
        i_flg_all_med_adm     IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'COMPLETE_EPIS_OUT_ON_PASS';
        l_code_conclude_notes epis_out_on_pass.code_conclude_notes%TYPE;
        l_timestamp           TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_rowid               table_varchar;
    
    BEGIN
    
        -- complete epis_out_on_pass
        IF i_id_epis_out_on_pass IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_code_conclude_notes := pk_alert_constant.g_out_on_pass_conclude_notes || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_conclude_notes),
                                                   i_desc   => table_clob(i_conclude_notes),
                                                   i_module => pk_alert_constant.g_out_on_pass_conclu_notes_ar);
    
        g_error := 'Call ts_epis_out_on_pass.upd: ';
        g_error := g_error || 'id_epis_out_on_pass = ' || i_id_epis_out_on_pass;
        pk_alertlog.log_debug(g_error);
        -- update epis_out_on_pass
        ts_epis_out_on_pass.upd(id_epis_out_on_pass_in => i_id_epis_out_on_pass,
                                id_status_in           => pk_alert_constant.g_status_out_on_pass_completed,
                                id_conclude_reason_in  => i_id_conclude_reason,
                                dt_in_returned_in      => i_dt_in_returned,
                                dt_last_update_in      => l_timestamp,
                                id_prof_last_update_in => i_prof.id,
                                id_workflow_in         => pk_alert_constant.g_wf_epis_out_on_pass,
                                flg_all_med_adm_in     => i_flg_all_med_adm,
                                handle_error_in        => FALSE,
                                rows_out               => l_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_OUT_ON_PASS',
                                      i_rowids     => l_rowid,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END complete_epis_out_on_pass;

    FUNCTION start_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_start_notes         IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'START_EPIS_OUT_ON_PASS';
        l_code_start_notes epis_out_on_pass.code_start_notes%TYPE;
        l_timestamp        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_rowid            table_varchar;
    
    BEGIN
    
        -- start epis_out_on_pass
        IF i_id_epis_out_on_pass IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_code_start_notes := pk_alert_constant.g_out_on_pass_start_notes || i_id_epis_out_on_pass;
    
        g_error := 'CALL pk_translation.insert_translation_trs_bulk-request_reason';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_db_object_name);
        pk_translation.insert_translation_trs_bulk(i_lang   => i_lang,
                                                   i_code   => table_varchar(l_code_start_notes),
                                                   i_desc   => table_clob(i_start_notes),
                                                   i_module => pk_alert_constant.g_out_on_pass_start_notes_ar);
    
        g_error := 'Call ts_epis_out_on_pass.upd: ';
        g_error := g_error || 'id_epis_out_on_pass = ' || i_id_epis_out_on_pass;
        pk_alertlog.log_debug(g_error);
        -- update epis_out_on_pass
        ts_epis_out_on_pass.upd(id_epis_out_on_pass_in => i_id_epis_out_on_pass,
                                id_status_in           => pk_alert_constant.g_status_out_on_pass_ongoing,
                                dt_last_update_in      => l_timestamp,
                                id_prof_last_update_in => i_prof.id,
                                id_workflow_in         => pk_alert_constant.g_wf_epis_out_on_pass,
                                handle_error_in        => FALSE,
                                rows_out               => l_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_OUT_ON_PASS',
                                      i_rowids     => l_rowid,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END start_epis_out_on_pass;

    /********************************************************************************************
    * Return icon of the status
    *
    * @author          Adriana Ramos
    * @since           14/05/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN epis_out_on_pass.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_icon wf_status.icon%TYPE;
    
    BEGIN
        SELECT ws.icon
          INTO l_icon
          FROM wf_status ws
         WHERE ws.id_status = i_id_status;
    
        RETURN l_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_out_on_pass_icon;

    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(60 CHAR) := 'get_epis_out_on_pass_info';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_epis_out_on_pass=' ||
                    i_id_epis_out_on_pass;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        g_error := 'OPEN o_info';
        OPEN o_info FOR
            SELECT eoop.id_epis_out_on_pass,
                   eoop.id_prof_last_update id_prof,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, eoop.id_prof_last_update)
                      FROM dual) name_prof,
                   decode(eoop.id_request_reason,
                          -1,
                          to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_request_reason)),
                          pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_id_option => eoop.id_request_reason)) request_reason,
                   decode(eoop.id_requested_by,
                          pk_alert_constant.g_out_on_pass_req_by_patient,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_req_by_patient,
                   decode(eoop.id_requested_by,
                          pk_alert_constant.g_out_on_pass_req_by_leg_gard,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_req_by_legal_guardian,
                   decode(eoop.id_requested_by,
                          pk_alert_constant.g_out_on_pass_req_by_next_kin,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_req_by_next_kin,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_requested_by)) requested_by_other,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_note_admission_office)) notes_admission_office,
                   (SELECT pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                       i_date => eoop.dt_in,
                                                       i_inst => i_prof.institution,
                                                       i_soft => i_prof.software)
                      FROM dual) AS dt_in_str,
                   (SELECT pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                       i_date => eoop.dt_out,
                                                       i_inst => i_prof.institution,
                                                       i_soft => i_prof.software)
                      FROM dual) AS dt_out_str,
                   pk_date_utils.date_send_tsz(i_lang, eoop.dt_in, i_prof) dt_in,
                   pk_date_utils.date_send_tsz(i_lang, eoop.dt_out, i_prof) dt_out,
                   pk_utils.number_to_char(i_prof, eoop.total_allowed_hours) total_allowed_hours,
                   eoop.patient_contact_number,
                   eoop.flg_attending_physic_agree
              FROM epis_out_on_pass eoop
             WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_info;

    FUNCTION get_epis_out_on_pass_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(60 CHAR) := 'get_epis_out_on_pass_data';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' id_epis_out_on_pass=' ||
                    i_id_epis_out_on_pass;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        g_error := 'OPEN o_data';
        OPEN o_data FOR
            SELECT eoop.id_epis_out_on_pass,
                   eoop.id_request_reason,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_request_reason)) request_reason,
                   eoop.id_requested_by,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_requested_by)) requested_by_other,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_note_admission_office)) notes_admission_office,
                   to_char(pk_translation.get_translation_trs(i_code_mess => eoop.code_other_notes)) other_notes,
                   pk_date_utils.date_send_tsz(i_lang, eoop.dt_in, i_prof) dt_in,
                   pk_date_utils.date_send_tsz(i_lang, eoop.dt_out, i_prof) dt_out,
                   eoop.total_allowed_hours,
                   eoop.patient_contact_number,
                   eoop.flg_attending_physic_agree
              FROM epis_out_on_pass eoop
             WHERE eoop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_data;

    /********************************************************************************************
    * Get Epis-oop Detail
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_DET';
    
        l_tab_dd_block_data      t_tab_dd_block_data;
        l_tab_dd_block_prod_desc t_tab_dd_block_data;
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
        l_exists_prod      VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_episode_oop      epis_out_on_pass.id_episode%TYPE;
        l_prod_desc_and_instr table_varchar := table_varchar();
    
        k_active    NUMBER := pk_alert_constant.g_status_out_on_pass_active;
        k_ongoing   NUMBER := pk_alert_constant.g_status_out_on_pass_ongoing;
        k_completed NUMBER := pk_alert_constant.g_status_out_on_pass_completed;
        k_cancelled NUMBER := pk_alert_constant.g_status_out_on_pass_cancelled;
    BEGIN
        -----------------------------------------------------------------------------    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL, --hist_dt_create
                                   NULL, --hist_code_transaction
                                   dd.id_status,
                                   NULL, -- id_prev_status
                                   NULL, --c_n
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL --(dd.c_n, g_flg_changed, dd.data_source_val_old, NULL)
                                   )
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT id_status, data_source, data_source_val
                  FROM (SELECT op.id_status,
                               pk_translation.get_translation(i_lang, 'WF_STATUS.CODE_STATUS.' || op.id_status) status,
                               ----------------
                               decode(op.id_request_reason,
                                      -1,
                                      to_char(pk_translation.get_translation_trs(i_code_mess => op.code_request_reason)),
                                      pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_id_option => op.id_request_reason)) desc_reason,
                               
                               CASE
                                    WHEN op.id_requested_by IN (g_requested_by_legal_guardian, g_requested_by_next_of_kint) THEN
                                     pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                    i_prof      => i_prof,
                                                                                    i_id_option => op.id_requested_by) ||
                                     ' - ' ||
                                     to_char(pk_translation.get_translation_trs(i_code_mess => op.code_requested_by))
                                    ELSE
                                     pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                    i_prof      => i_prof,
                                                                                    i_id_option => op.id_requested_by)
                                END requested_by,
                               CASE
                                    WHEN op.id_conclude_reason IS NOT NULL THEN
                                     pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                    i_prof      => i_prof,
                                                                                    i_id_option => op.id_conclude_reason)
                                    ELSE
                                     NULL
                                END conclude_reason,
                               decode(op.id_cancel_reason,
                                      pk_cancel_reason.c_reason_other,
                                      to_char(pk_translation.get_translation_trs(i_code_mess => op.code_cancel_reason)),
                                      pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_id_cancel_reason => op.id_cancel_reason)) cancel_reason,
                               decode(op.id_cancel_reason,
                                      pk_cancel_reason.c_reason_other,
                                      NULL,
                                      to_char(pk_translation.get_translation_trs(op.code_cancel_reason))) cancel_notes,
                               ----------------
                               pk_date_utils.date_char_tsz(i_lang, op.dt_out, i_prof.institution, i_prof.software) dt_out,
                               pk_date_utils.date_char_tsz(i_lang, op.dt_in, i_prof.institution, i_prof.software) dt_in,
                               pk_utils.number_to_char(i_prof, op.total_allowed_hours) allowed_hours,
                               to_char(op.patient_contact_number) pat_contact_num,
                               (SELECT pk_sysdomain.get_domain('EPIS_OUT_ON_PASS.FLG_ATTENDING_PHYSIC',
                                                               op.flg_attending_physic_agree,
                                                               i_lang)
                                  FROM dual) physic_aggrement,
                               to_char(pk_translation.get_translation_trs(op.code_start_notes)) start_notes,
                               to_char(pk_translation.get_translation_trs(op.code_note_admission_office)) admission_office_notes,
                               to_char(pk_translation.get_translation_trs(op.code_other_notes)) other_notes,
                               NULL prod_out_on_pass,
                               
                               pk_date_utils.date_char_tsz(i_lang, op.dt_in_returned, i_prof.institution, i_prof.software) dt_return,
                               CASE
                                    WHEN op.flg_all_med_adm = pk_alert_constant.g_yes THEN
                                     pk_message.get_message(i_lang, 'COMMON_M022')
                                    ELSE
                                     pk_message.get_message(i_lang, 'COMMON_M023')
                                END all_med_taken,
                               to_char(pk_translation.get_translation_trs(op.code_conclude_notes)) conclude_notes,
                               (SELECT pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_id_episode          => op.id_episode,
                                                                          i_date_last_change    => op.dt_last_update,
                                                                          i_id_prof_last_change => op.id_prof_last_update)
                                  FROM dual) prof_last_updated,
                               NULL wl
                          FROM epis_out_on_pass op
                         WHERE op.id_epis_out_on_pass = i_id_epis_out_on_pass) --
                       unpivot include NULLS(data_source_val FOR data_source IN(status,
                                                                                --desc_status,
                                                                                desc_reason,
                                                                                requested_by,
                                                                                dt_out,
                                                                                dt_in,
                                                                                allowed_hours,
                                                                                pat_contact_num,
                                                                                physic_aggrement,
                                                                                prof_last_updated,
                                                                                prod_out_on_pass,
                                                                                start_notes,
                                                                                dt_return,
                                                                                all_med_taken,
                                                                                conclude_notes,
                                                                                conclude_reason,
                                                                                admission_office_notes,
                                                                                other_notes,
                                                                                cancel_reason,
                                                                                cancel_notes,
                                                                                wl)) --
                ) dd
          JOIN dd_block ddb
            ON to_number(ddb.condition_val) IN --
              -- passar para código externo se parecer muito complexo
               (SELECT *
                  FROM TABLE (SELECT CASE
                                          WHEN dd.id_status = k_active THEN
                                           table_number(k_active)
                                          WHEN dd.id_status = k_ongoing THEN
                                           table_number(k_active, k_ongoing)
                                          WHEN dd.id_status = k_completed THEN
                                           table_number(k_active, k_ongoing, k_completed)
                                          WHEN dd.id_status = k_cancelled THEN
                                           table_number(k_active, k_cancelled)
                                          ELSE
                                           table_number(k_active, k_ongoing, k_completed, k_cancelled)
                                      END a
                                FROM dual))
           AND ddb.area = 'OUT_ON_PASS'
           AND ddb.flg_available = pk_alert_constant.g_yes
         WHERE ((ddb.condition_val IN (k_ongoing, k_completed, k_cancelled) AND
               data_source NOT IN ('STATUS', 'DESC_STATUS')) OR ddb.condition_val = k_active)
           AND ((ddb.condition_val != dd.id_status AND data_source != 'PROF_LAST_UPDATED') OR
               ddb.condition_val = dd.id_status)
         ORDER BY ddb.rank;
    
        -----------------------------------------------------------------------------        
        -- obtain list of product description and instructions
        SELECT oop.id_episode
          INTO l_id_episode_oop
          FROM epis_out_on_pass oop
         WHERE oop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        l_prod_desc_and_instr := get_detail_prod_and_instr(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_episode          => l_id_episode_oop,
                                                           i_id_epis_out_on_pass => i_id_epis_out_on_pass);
    
        IF l_prod_desc_and_instr.exists(1)
        THEN
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       ddb.rank,
                                       NULL, --hist_dt_create
                                       NULL, --hist_code_transaction
                                       pd.id_status,
                                       NULL, -- id_prev_status
                                       NULL, --c_n
                                       pd.data_source,
                                       pd.data_source_val,
                                       NULL --(dd.c_n, g_flg_changed, dd.data_source_val_old, NULL)
                                       )
              BULK COLLECT
              INTO l_tab_dd_block_prod_desc
              FROM (SELECT 'PROD_DESC_AND_INSTR' data_source, k_ongoing id_status, column_value data_source_val
                      FROM TABLE(l_prod_desc_and_instr)) pd
              JOIN dd_block ddb
                ON to_number(ddb.condition_val) = pd.id_status
               AND ddb.area = 'OUT_ON_PASS'
               AND ddb.flg_available = pk_alert_constant.g_yes
             ORDER BY ddb.rank;
        
            --dbms_output.put_line(l_tab_dd_block_prod_desc.count);
        
            IF l_tab_dd_block_prod_desc.exists(1)
            THEN
                l_exists_prod       := pk_alert_constant.g_yes;
                l_tab_dd_block_data := l_tab_dd_block_data MULTISET UNION ALL l_tab_dd_block_prod_desc;
            END IF;
        END IF;
    
        -----------------------------------------------------------------------------    
        SELECT t_rec_dd_data(get_detail_descr(i_lang,
                                               i_prof,
                                               data_code_message,
                                               id_ds_component,
                                               data_source_val,
                                               NULL,
                                               flg_type,
                                               NULL,
                                               NULL,
                                               CASE
                                                   WHEN ddc.data_source = 'PROD_DESC_AND_INSTR' THEN
                                                    pk_alert_constant.g_no
                                                   ELSE
                                                    pk_alert_constant.g_yes
                                               END),
                              CASE
                                  WHEN data_code_message IS NULL
                                       AND id_ds_component IS NULL
                                       AND ddc.data_source != 'PROD_DESC_AND_INSTR' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END,
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob),
               ddc.data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM TABLE(l_tab_dd_block_data) db
          JOIN dd_content ddc
            ON ddc.data_source = db.data_source
           AND ddc.flg_available = pk_alert_constant.g_yes
           AND ddc.area = 'OUT_ON_PASS'
         WHERE ddc.id_dd_block = db.id_dd_block
         ORDER BY db.rnk, rank;
    
        -----------------------------------------------------------------------------
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ': '
                            END descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           d.val_clob,
                           d.flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn
                     WHERE (d.val IS NULL AND ds.data_source IN ('STATUS', 'WL'))
                        OR (d.val IS NULL AND ds.data_source IN ('PROD_OUT_ON_PASS') AND
                           l_exists_prod = pk_alert_constant.g_yes)
                        OR d.val IS NOT NULL)
             ORDER BY rn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_det;

    /********************************************************************************************
    * Get Epis-oop Detail History
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_HIST';
    
        l_tab_dd_block_data      t_tab_dd_block_data;
        l_tab_dd_block_prod_desc t_tab_dd_block_data;
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
        l_exists_prod      VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_episode_oop      epis_out_on_pass.id_episode%TYPE;
        l_prod_desc_and_instr table_varchar := table_varchar();
    
        k_ongoing NUMBER := pk_alert_constant.g_status_out_on_pass_ongoing;
        k_flg_new     CONSTANT VARCHAR2(1 CHAR) := 'N';
        k_flg_changed CONSTANT VARCHAR2(1 CHAR) := 'C';
    BEGIN
        --------------------------------------------------------------------------------------------    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   NULL, --rank
                                   dd.hist_dt_create,
                                   dd.hist_code_transaction,
                                   dd.id_status,
                                   dd.id_prev_status,
                                   dd.c_n,
                                   dd.data_source,
                                   dd.data_source_val,
                                   decode(dd.c_n, k_flg_changed, dd.data_source_val_old, NULL))
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT hist_dt_create,
                       hist_code_transaction,
                       id_status,
                       id_prev_status,
                       decode(id_status, id_prev_status, k_flg_changed, k_flg_new) c_n,
                       data_source,
                       data_source_val,
                       lag(data_source_val) over(PARTITION BY data_source ORDER BY hist_dt_create) AS data_source_val_old
                  FROM (SELECT op.hist_dt_create,
                               hist_code_transaction,
                               op.id_status,
                               lag(id_status) over(ORDER BY hist_dt_create) AS id_prev_status,
                               --rank() over(PARTITION BY op.id_status ORDER BY op.hist_dt_create) rnk,
                               pk_translation.get_translation(i_lang, 'WF_STATUS.CODE_STATUS.' || op.id_status) status,
                               ----------------
                               decode(op.id_request_reason,
                                      -1,
                                      to_char(op.code_request_reason),
                                      pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_id_option => op.id_request_reason)) desc_reason,
                               
                               CASE
                                    WHEN op.id_requested_by IN (g_requested_by_legal_guardian, g_requested_by_next_of_kint) THEN
                                     pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                    i_prof      => i_prof,
                                                                                    i_id_option => op.id_requested_by) ||
                                     ' - ' || to_char(op.code_requested_by)
                                    ELSE
                                     pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                    i_prof      => i_prof,
                                                                                    i_id_option => op.id_requested_by)
                                END requested_by,
                               pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_id_option => op.id_conclude_reason) conclude_reason,
                               decode(op.id_cancel_reason,
                                      pk_cancel_reason.c_reason_other,
                                      to_char(op.code_cancel_reason),
                                      pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_id_cancel_reason => op.id_cancel_reason)) cancel_reason,
                               decode(op.id_cancel_reason,
                                      pk_cancel_reason.c_reason_other,
                                      NULL,
                                      to_char(op.code_cancel_reason)) cancel_notes,
                               ----------------
                               
                               pk_date_utils.date_char_tsz(i_lang, op.dt_out, i_prof.institution, i_prof.software) dt_out,
                               pk_date_utils.date_char_tsz(i_lang, op.dt_in, i_prof.institution, i_prof.software) dt_in,
                               pk_utils.number_to_char(i_prof, op.total_allowed_hours) allowed_hours,
                               to_char(op.patient_contact_number) pat_contact_num,
                               (SELECT pk_sysdomain.get_domain('EPIS_OUT_ON_PASS.FLG_ATTENDING_PHYSIC',
                                                               op.flg_attending_physic_agree,
                                                               i_lang)
                                  FROM dual) physic_aggrement,
                               to_char(op.code_start_notes) start_notes,
                               to_char(op.code_note_admission_office) admission_office_notes,
                               to_char(op.code_other_notes) other_notes,
                               NULL prod_out_on_pass,
                               pk_date_utils.date_char_tsz(i_lang, op.dt_in_returned, i_prof.institution, i_prof.software) dt_return,
                               CASE
                                    WHEN op.flg_all_med_adm = pk_alert_constant.get_yes THEN
                                     pk_message.get_message(i_lang, 'COMMON_M022')
                                    ELSE
                                     pk_message.get_message(i_lang, 'COMMON_M023')
                                END all_med_taken,
                               to_char(op.code_conclude_notes) conclude_notes,
                               (SELECT pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                          i_prof                => i_prof,
                                                                          i_id_episode          => op.id_episode,
                                                                          i_date_last_change    => op.dt_last_update,
                                                                          i_id_prof_last_change => op.id_prof_last_update)
                                  FROM dual) prof_documented,
                               NULL wl
                          FROM epis_out_on_pass_h op
                         WHERE op.id_epis_out_on_pass = i_id_epis_out_on_pass
                         ORDER BY op.hist_dt_create DESC) unpivot include NULLS(data_source_val FOR data_source IN(status,
                                                                                                                   --desc_status,
                                                                                                                   desc_reason,
                                                                                                                   requested_by,
                                                                                                                   dt_out,
                                                                                                                   dt_in,
                                                                                                                   allowed_hours,
                                                                                                                   pat_contact_num,
                                                                                                                   physic_aggrement,
                                                                                                                   prof_documented,
                                                                                                                   prod_out_on_pass,
                                                                                                                   start_notes,
                                                                                                                   dt_return,
                                                                                                                   all_med_taken,
                                                                                                                   conclude_notes,
                                                                                                                   conclude_reason,
                                                                                                                   admission_office_notes,
                                                                                                                   other_notes,
                                                                                                                   cancel_reason,
                                                                                                                   cancel_notes,
                                                                                                                   wl)) --
                ) dd
          JOIN dd_block ddb
            ON to_number(ddb.condition_val) = dd.id_status
           AND ddb.area = 'OUT_ON_PASS'
           AND ddb.flg_available = pk_alert_constant.g_yes
         WHERE c_n = k_flg_new
            OR (c_n = k_flg_changed AND nvl(data_source_val, '_N') != nvl(data_source_val_old, '_N'))
            OR data_source IN ('STATUS', 'WL', 'PROF_DOCUMENTED')
         ORDER BY hist_dt_create DESC;
    
        -----------------------------------------------------------------------------        
        -- obtain list of product description and instructions
        SELECT oop.id_episode
          INTO l_id_episode_oop
          FROM epis_out_on_pass oop
         WHERE oop.id_epis_out_on_pass = i_id_epis_out_on_pass;
    
        l_prod_desc_and_instr := get_detail_prod_and_instr(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_episode          => l_id_episode_oop,
                                                           i_id_epis_out_on_pass => i_id_epis_out_on_pass);
    
        IF l_prod_desc_and_instr.exists(1)
        THEN
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       ddb.rank,
                                       op.hist_dt_create, --hist_dt_create
                                       op.hist_code_transaction,
                                       pd.id_status,
                                       NULL, -- id_prev_status
                                       'N', --c_n
                                       pd.data_source,
                                       pd.data_source_val,
                                       NULL --(dd.c_n, g_flg_changed, dd.data_source_val_old, NULL)
                                       )
              BULK COLLECT
              INTO l_tab_dd_block_prod_desc
              FROM (SELECT 'PROD_DESC_AND_INSTR' data_source, k_ongoing id_status, column_value data_source_val
                      FROM TABLE(l_prod_desc_and_instr)) pd
              JOIN dd_block ddb
                ON to_number(ddb.condition_val) = pd.id_status
               AND ddb.area = 'OUT_ON_PASS'
               AND ddb.flg_available = pk_alert_constant.g_yes
              JOIN epis_out_on_pass_h op
                ON op.id_status = k_ongoing
               AND op.id_epis_out_on_pass = i_id_epis_out_on_pass
             ORDER BY ddb.rank;
        
            --dbms_output.put_line(l_tab_dd_block_prod_desc.count);
        
            IF l_tab_dd_block_prod_desc.exists(1)
            THEN
                l_exists_prod       := pk_alert_constant.g_yes;
                l_tab_dd_block_data := l_tab_dd_block_data MULTISET UNION ALL l_tab_dd_block_prod_desc;
            END IF;
        END IF;
    
        -----------------------------------------------------------------------------    
        SELECT t_rec_dd_data(get_detail_descr(i_lang,
                                               i_prof,
                                               data_code_message,
                                               id_ds_component,
                                               data_source_val,
                                               data_source_val_old,
                                               flg_type,
                                               c_n,
                                               n_level,
                                               CASE
                                                   WHEN ddc_source = 'PROD_DESC_AND_INSTR' THEN
                                                    pk_alert_constant.g_no
                                                   ELSE
                                                    pk_alert_constant.g_yes
                                               END),
                              CASE
                                  WHEN data_code_message IS NULL
                                       AND id_ds_component IS NULL
                                       AND ddc_source != 'PROD_DESC_AND_INSTR' THEN
                                   NULL
                                  ELSE
                                   CASE
                                       WHEN n_level = 1 THEN
                                        data_source_val
                                       ELSE
                                        data_source_val_old
                                   END
                              END,
                              CASE
                                   WHEN c_n = k_flg_changed
                                        AND flg_type NOT IN (g_det_level_1, g_det_level_prof, g_det_white_line)
                                        AND n_level = 1 THEN
                                    flg_type || k_flg_new
                                   ELSE -- if flg_type = L1 or LP, then don't add the 'N' (New) on the flg_type
                                   flg_type
                              END,
                              aa.flg_html,
                              NULL,
                              aa.flg_clob),
               ddc_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (
                -------------------------------- 
                SELECT 1 n_level, ddc.data_source ddc_source, db.*, ddc.*
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                 WHERE ddc.id_dd_block = db.id_dd_block --
                   AND ddc.area = 'OUT_ON_PASS'
                UNION ALL --
                --------------------------------
                SELECT 2 n_level, ddc.data_source ddc_source, db.*, ddc.*
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND ddc.area = 'OUT_ON_PASS'
                   AND db.data_source_val_old IS NOT NULL
                   AND (db.data_source_val_old != db.data_source_val OR db.data_source_val IS NULL)
                   AND ddc.flg_type != g_det_level_prof -- dont need prof info in the previous state detail
                --
                ) aa
         ORDER BY hist_dt_create DESC, rank;
    
        -----------------------------------------------------------------------------
        OPEN o_detail FOR
            SELECT CASE
                        WHEN d.val IS NULL THEN
                         d.descr
                        WHEN d.descr IS NULL THEN
                         NULL
                        ELSE
                         d.descr || ': '
                    END descr,
                   d.val,
                   d.flg_type,
                   d.flg_html,
                   d.val_clob,
                   d.flg_clob
              FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                      FROM TABLE(l_tab_dd_data)) d
              JOIN (SELECT rownum rn, column_value data_source
                      FROM TABLE(l_data_source_list)) ds
                ON ds.rn = d.rn
             WHERE (d.val IS NULL AND ds.data_source IN ('STATUS', 'WL'))
                OR (d.val IS NULL AND ds.data_source IN ('PROD_OUT_ON_PASS') AND
                   l_exists_prod = pk_alert_constant.g_yes)
                OR d.val IS NOT NULL
                OR substr(d.flg_type, -1, 1) = k_flg_new;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_hist;

    /********************************************************************************************
    * Get Epis-oop Report
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE,
        i_flg_hist   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_EPIS_OUT_ON_PASS_REP';
    
        l_id_epis_out_on_pass table_number := table_number();
    
        c_detail pk_types.cursor_type;
    
        l_cur_descr    table_varchar := table_varchar();
        l_cur_val      table_varchar := table_varchar();
        l_cur_type     table_varchar := table_varchar();
        l_cur_flg_html table_varchar := table_varchar();
        l_cur_flg_clob table_varchar := table_varchar();
        l_cur_clob     table_clob := table_clob();
    
        l_total_descr    table_varchar := table_varchar();
        l_total_val      table_varchar := table_varchar();
        l_total_type     table_varchar := table_varchar();
        l_total_flg_html table_varchar := table_varchar();
        l_total_flg_clob table_varchar := table_varchar();
        l_total_clob     table_clob := table_clob();
    BEGIN
        SELECT oop.id_epis_out_on_pass
          BULK COLLECT
          INTO l_id_epis_out_on_pass
          FROM epis_out_on_pass oop
         WHERE oop.id_episode = i_id_episode;
    
        -----------------------------------------------------------------------------        
        IF l_id_epis_out_on_pass.exists(1)
        THEN
            FOR i IN l_id_epis_out_on_pass.first .. l_id_epis_out_on_pass.last
            LOOP
                l_cur_descr := table_varchar();
                l_cur_val   := table_varchar();
                l_cur_type  := table_varchar();
            
                IF i_flg_hist = pk_alert_constant.g_yes
                THEN
                    IF NOT get_epis_out_on_pass_hist(i_lang                => i_lang,
                                                     i_prof                => i_prof,
                                                     i_id_epis_out_on_pass => l_id_epis_out_on_pass(i),
                                                     o_detail              => c_detail,
                                                     o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    IF NOT get_epis_out_on_pass_det(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_epis_out_on_pass => l_id_epis_out_on_pass(i),
                                                    o_detail              => c_detail,
                                                    o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                FETCH c_detail BULK COLLECT
                    INTO l_cur_descr, l_cur_val, l_cur_type, l_cur_flg_html, l_cur_clob, l_cur_flg_clob;
                CLOSE c_detail;
            
                IF l_cur_descr.exists(1)
                THEN
                    l_total_descr := l_total_descr MULTISET UNION ALL l_cur_descr;
                    l_total_val   := l_total_val MULTISET UNION ALL l_cur_val;
                    l_total_type  := l_total_type MULTISET UNION ALL l_cur_type;
                END IF;
            END LOOP;
        END IF;
    
        -----------------------------------------------------------------------------        
        OPEN o_detail FOR
            SELECT descr, val, flg_type
              FROM (SELECT rownum AS rn, column_value AS descr
                      FROM TABLE(l_total_descr)) p1
              JOIN (SELECT rownum AS rn, column_value AS val
                      FROM TABLE(l_total_val)) p2
                ON p1.rn = p2.rn
              JOIN (SELECT rownum AS rn, column_value AS flg_type
                      FROM TABLE(l_total_type)) p3
                ON p1.rn = p3.rn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_detail);
            RETURN TRUE;
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_out_on_pass_rep;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_detail_prod_and_instr
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN table_varchar IS
        l_error t_error_out;
    
        c_presc_data pk_types.cursor_type;
    
        l_desc_prod   table_varchar := table_varchar();
        l_last_instr  table_varchar := table_varchar();
        l_id_presc    table_number := table_number();
        l_server_time table_varchar := table_varchar();
    
        l_return_val table_varchar := table_varchar();
    BEGIN
        IF NOT pk_api_pfh_in.get_presc_out_on_pass_complete(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_episode              => i_id_episode,
                                                            i_id_epis_out_on_pass     => i_id_epis_out_on_pass,
                                                            i_flg_html                => pk_alert_constant.g_no,
                                                            i_flg_force_pp_oop_status => pk_alert_constant.g_no,
                                                            o_presc_data              => c_presc_data,
                                                            o_error                   => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH c_presc_data BULK COLLECT
            INTO l_desc_prod, l_last_instr, l_id_presc; -- l_server_time;
        CLOSE c_presc_data;
    
        IF l_desc_prod.exists(1)
        THEN
            FOR i IN l_desc_prod.first .. l_desc_prod.last
            LOOP
                l_return_val.extend;
                l_return_val(l_return_val.last) := l_desc_prod(i);
                l_return_val.extend;
                l_return_val(l_return_val.last) := l_last_instr(i);
            END LOOP;
        END IF;
    
        RETURN l_return_val;
    END get_detail_prod_and_instr;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_detail_descr
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_data_code_message        IN dd_content.data_code_message%TYPE,
        i_id_ds_component          IN dd_content.id_ds_component%TYPE,
        i_data_source_val          IN VARCHAR2,
        i_data_source_val_old      IN VARCHAR2,
        i_flg_type                 IN dd_content.flg_type%TYPE,
        i_c_n                      IN VARCHAR2,
        i_level                    IN VARCHAR2,
        i_flg_data_source_as_descr IN VARCHAR2 DEFAULT pk_alert_constant.g_yes -- if source will substitute description, for example product name and instructions (do not have description)
    ) RETURN VARCHAR2 IS
        l_descr VARCHAR2(2000 CHAR);
    
        k_flg_changed CONSTANT VARCHAR2(1 CHAR) := 'C';
    
        l_new_msg     VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M152');
        l_updated_msg VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M153');
        l_deleted_msg VARCHAR2(100 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_code_mess => 'COMMON_M154');
    BEGIN
        l_descr := CASE
                       WHEN i_data_code_message IS NOT NULL THEN
                        pk_message.get_message(i_lang, i_data_code_message)
                       WHEN i_id_ds_component IS NOT NULL THEN
                        pk_message.get_message(i_lang, 'DS_COMPONENT.CODE_DS_COMPONENT.' || i_id_ds_component)
                       WHEN i_flg_data_source_as_descr = pk_alert_constant.g_no THEN
                        NULL
                       ELSE
                        i_data_source_val
                   END || --
                   CASE
                       WHEN i_c_n = k_flg_changed
                            AND i_flg_type NOT IN (g_det_level_1, g_det_level_prof, g_det_white_line)
                            AND i_level = 1 THEN
                        CASE
                            WHEN i_data_source_val_old IS NULL THEN
                             l_new_msg
                            WHEN i_data_source_val_old IS NOT NULL
                                 AND i_data_source_val IS NULL THEN
                             l_deleted_msg
                            ELSE
                             l_updated_msg
                        END
                       ELSE
                        NULL
                   END;
    
        RETURN l_descr;
    END get_detail_descr;

    /**
    * Check if add button can be active
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_id_episode           Episode identifier
    * @param   i_id_patient       Patient identifier
    *
    * @RETURN  VARCHAR2             'Y' - can be active / 'N' - can't be active
    *
    * @author  Adriana Ramos
    * @since   04/07/2019
    */
    FUNCTION check_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_out_on_pass.id_episode%TYPE,
        i_id_patient  IN epis_out_on_pass.id_patient%TYPE,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exists NUMBER;
        l_db_object_name CONSTANT VARCHAR2(24 CHAR) := 'CHECK_CAN_CANCEL';
    BEGIN
    
        o_flg_can_add := pk_alert_constant.g_yes;
    
        SELECT COUNT(1)
          INTO l_exists
          FROM epis_out_on_pass eoop
         WHERE eoop.id_episode = i_id_episode
           AND eoop.id_patient = i_id_patient
           AND eoop.id_status IN
               (pk_alert_constant.g_status_out_on_pass_active, pk_alert_constant.g_status_out_on_pass_ongoing);
    
        IF l_exists > 0
        THEN
            o_flg_can_add := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            o_flg_can_add := pk_alert_constant.g_no;
            RETURN FALSE;
    END check_can_add;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_VALUES - EPIS_OUT_ON_PASS';
    
        l_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE;
    
        l_current_ds_component       ds_component.id_ds_component%TYPE;
        l_config_total_allowed_hours NUMBER;
        l_flg_validation             VARCHAR2(5 CHAR);
        l_err_msg                    VARCHAR2(4000);
    
        l_ds_request_reason         VARCHAR2(4000 CHAR);
        l_ds_request_reason_other   VARCHAR2(4000 CHAR);
        l_ds_requested_by           VARCHAR2(4000 CHAR);
        l_ds_request_by_other       VARCHAR2(4000 CHAR);
        l_ds_dt_out                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_ds_dt_in                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_ds_total_allowed_hours    NUMBER;
        l_ds_patient_contact_number VARCHAR2(4000 CHAR);
        l_ds_attending_physic_agree VARCHAR2(4000 CHAR);
        l_ds_note_admission_office  VARCHAR2(4000 CHAR);
        l_ds_other_notes            VARCHAR2(4000 CHAR);
    
        -----------------------------------------------------------
        FUNCTION get_component_from_rel(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE)
            RETURN ds_component.id_ds_component%TYPE IS
        
            l_result ds_component.id_ds_component%TYPE;
        BEGIN
            SELECT dcr.id_ds_component_child
              INTO l_result
              FROM ds_cmpt_mkt_rel dcr
             WHERE dcr.id_ds_cmpt_mkt_rel = i_id_ds_cmpt_mkt_rel;
        
            RETURN l_result;
        END;
    
        -----------------------------------------------------------
        PROCEDURE get_list_of_ds_data IS
            l_id_ds_component ds_component.id_ds_component%TYPE;
        BEGIN
            IF i_tbl_mkt_rel.exists(1)
            THEN
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    l_id_ds_component := get_component_from_rel(i_tbl_mkt_rel(i));
                
                    CASE l_id_ds_component
                        WHEN g_ds_request_reason THEN
                            l_ds_request_reason := i_value(i) (1);
                        WHEN g_ds_request_reason_other THEN
                            l_ds_request_reason_other := i_value(i) (1);
                        WHEN g_ds_requested_by THEN
                            l_ds_requested_by := i_value(i) (1);
                        WHEN g_ds_request_by_other THEN
                            l_ds_request_by_other := i_value(i) (1);
                        WHEN g_ds_dt_out THEN
                            l_ds_dt_out := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                         i_prof      => i_prof,
                                                                         i_timestamp => i_value(i) (1),
                                                                         i_timezone  => NULL);
                        WHEN g_ds_dt_in THEN
                            l_ds_dt_in := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_timestamp => i_value(i) (1),
                                                                        i_timezone  => NULL);
                        WHEN g_ds_total_allowed_hours THEN
                            IF pk_utils.is_number(i_value(i) (1)) = pk_alert_constant.g_yes
                            THEN
                                l_ds_total_allowed_hours := pk_utils.char_to_number(i_prof, i_value(i) (1));
                            ELSE
                                l_ds_total_allowed_hours := NULL;
                            END IF;
                        WHEN g_ds_patient_contact_number THEN
                            l_ds_patient_contact_number := i_value(i) (1);
                        WHEN g_ds_attending_physic_agree THEN
                            l_ds_attending_physic_agree := i_value(i) (1);
                        WHEN g_ds_note_admission_office THEN
                            l_ds_note_admission_office := i_value(i) (1);
                        WHEN g_ds_other_notes THEN
                            l_ds_other_notes := i_value(i) (1);
                        ELSE
                            NULL;
                    END CASE;
                END LOOP;
            END IF;
        END;
    
        -----------------------------------------------------------
        FUNCTION get_config_allowed_hours RETURN NUMBER IS
        
            l_allowed_hours VARCHAR2(4000 CHAR);
        BEGIN
            -- configuration per:
            -- market: i_inst_mkt
            -- institution: i_prof (institution of prefessional)
            -- service: i_episode (internally it is obtained epis_dep_clin_serv by pk_episode.get_epis_dep_clin_serv)
            SELECT field_01
              INTO l_allowed_hours
              FROM (SELECT row_number() over(PARTITION BY config_table ORDER BY vc.id_market DESC, vc.id_institution DESC, vc.id_epis_dep_clin_serv DESC) rn,
                           t.field_01
                      FROM TABLE(pk_core_config.tf_config(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_config_table => 'OUT_ON_PASS_ALLOWED_HOURS',
                                                          i_inst_mkt     => pk_utils.get_institution_market(i_lang           => i_lang,
                                                                                                            i_id_institution => i_prof.institution),
                                                          i_episode      => i_episode)) t
                      JOIN v_config vc
                        ON vc.id_config = t.id_config)
             WHERE rn = 1;
        
            IF pk_utils.is_number(l_allowed_hours) = pk_alert_constant.g_yes
            THEN
                RETURN l_allowed_hours;
            ELSE
                RETURN NULL;
            END IF;
        END;
    
    BEGIN
        -- obtain pk_value (id_epis_out_on_pass
        IF i_tbl_id_pk.exists(1)
        THEN
            l_id_epis_out_on_pass := i_tbl_id_pk(1);
        ELSE
            l_id_epis_out_on_pass := NULL;
        END IF;
    
        ---------------------------------------------------------------------
        -- obtain ds_component from i_curr_component
        -- necessary to determine what to do with data
        IF i_curr_component IS NOT NULL
        THEN
            get_list_of_ds_data(); -- fill local variable with data from i_tbl_mkt_rel and i_value
            l_current_ds_component := get_component_from_rel(i_curr_component);
        END IF;
    
        ---------------------------------------------------------------------
        -- processing of i_curr_component specific data
        IF l_id_epis_out_on_pass IS NOT NULL -- if l_id_epis_out_on_pass is not null, it means it is an edition
          --AND l_current_ds_component IS NULL
           AND i_action = g_action_edit
        THEN
            -- obtain the values of id_epis_out_on_pass when editing a record
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => t.id_ds_component_child,
                                      internal_name      => t.internal_name_child,
                                      VALUE              => t.value,
                                      value_clob         => NULL,
                                      min_value          => null,
                                      max_value          => null,
                                      desc_value         => t.desc_value,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => t.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           CASE dc.id_ds_component_child
                               WHEN g_ds_request_reason THEN
                                to_char(op.id_request_reason)
                               WHEN g_ds_request_reason_other THEN
                                to_char(pk_translation.get_translation_trs(i_code_mess => op.code_request_reason))
                               WHEN g_ds_requested_by THEN
                                to_char(op.id_requested_by)
                               WHEN g_ds_request_by_other THEN
                                to_char(pk_translation.get_translation_trs(i_code_mess => op.code_requested_by))
                               WHEN g_ds_dt_out THEN
                                pk_date_utils.date_send_tsz(i_lang, op.dt_out, i_prof)
                               WHEN g_ds_dt_in THEN
                                pk_date_utils.date_send_tsz(i_lang, op.dt_in, i_prof)
                               WHEN g_ds_total_allowed_hours THEN
                                pk_utils.number_to_char(i_prof, op.total_allowed_hours)
                               WHEN g_ds_patient_contact_number THEN
                                to_char(op.patient_contact_number)
                               WHEN g_ds_attending_physic_agree THEN
                                to_char(op.flg_attending_physic_agree)
                               WHEN g_ds_note_admission_office THEN
                                to_char(pk_translation.get_translation_trs(op.code_note_admission_office))
                               WHEN g_ds_other_notes THEN
                                to_char(pk_translation.get_translation_trs(op.code_other_notes))
                               ELSE
                                NULL
                           END VALUE,
                           CASE dc.id_ds_component_child
                               WHEN g_ds_request_reason THEN
                                pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_id_option => op.id_request_reason)
                               WHEN g_ds_request_reason_other THEN
                                to_char(pk_translation.get_translation_trs(i_code_mess => op.code_request_reason))
                               WHEN g_ds_requested_by THEN
                                pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_id_option => op.id_requested_by)
                               WHEN g_ds_request_by_other THEN
                                to_char(pk_translation.get_translation_trs(i_code_mess => op.code_requested_by))
                               WHEN g_ds_dt_out THEN
                                pk_date_utils.date_send_tsz(i_lang, op.dt_out, i_prof)
                               WHEN g_ds_dt_in THEN
                                pk_date_utils.date_send_tsz(i_lang, op.dt_in, i_prof)
                               WHEN g_ds_total_allowed_hours THEN
                                pk_utils.number_to_char(i_prof, op.total_allowed_hours)
                               WHEN g_ds_patient_contact_number THEN
                                op.patient_contact_number
                               WHEN g_ds_attending_physic_agree THEN
                                (SELECT pk_sysdomain.get_domain('EPIS_OUT_ON_PASS.FLG_ATTENDING_PHYSIC',
                                                                op.flg_attending_physic_agree,
                                                                i_lang)
                                   FROM dual)
                               WHEN g_ds_note_admission_office THEN
                                to_char(pk_translation.get_translation_trs(op.code_note_admission_office))
                               WHEN g_ds_other_notes THEN
                                to_char(pk_translation.get_translation_trs(op.code_other_notes))
                               ELSE
                                NULL
                           END desc_value,
                           'NA' flg_event_type --dc.flg_event_type
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc
                      JOIN epis_out_on_pass op
                        ON op.id_epis_out_on_pass = l_id_epis_out_on_pass
                     ORDER BY dc.rn) t
             WHERE t.desc_value IS NOT NULL;
            ----------------------------------------------
        ELSIF l_current_ds_component IN (g_ds_dt_out, g_ds_dt_in) -- calculation of allowed hours when dt_out is filled
        -- does not matter what the id_action is
        THEN
            l_ds_total_allowed_hours     := pk_date_utils.get_date_hour_diff(l_ds_dt_in, l_ds_dt_out);
            l_ds_total_allowed_hours     := round(l_ds_total_allowed_hours, 2);
            l_config_total_allowed_hours := get_config_allowed_hours();
        
            IF (l_ds_dt_in IS NOT NULL AND l_ds_dt_out IS NULL)
               OR (l_ds_dt_in IS NULL AND l_ds_dt_out IS NOT NULL)
            THEN
                -- if one of the dates is filled and the other is not, no problem, simply do not calculate allowed_hours
                l_ds_total_allowed_hours := NULL; -- clean allowed_hours when error occurs
                l_flg_validation         := pk_alert_constant.g_yes;
                l_err_msg                := NULL;
            ELSIF l_ds_dt_in IS NULL
                  OR l_ds_dt_out IS NULL
                  OR l_ds_total_allowed_hours IS NULL
                  OR l_config_total_allowed_hours IS NULL
                  OR l_ds_total_allowed_hours > l_config_total_allowed_hours
                  OR l_ds_total_allowed_hours <= 0
            THEN
                -- if not vallid then show error_message
                IF l_current_ds_component = g_ds_dt_in
                THEN
                    l_ds_dt_in := NULL; -- clean dt_in when error occurs
                ELSIF l_current_ds_component = g_ds_dt_out
                THEN
                    l_ds_dt_out := NULL; -- clean dt_out when error occurs
                ELSE
                    l_ds_dt_in  := NULL;
                    l_ds_dt_out := NULL;
                END IF;
            
                l_ds_total_allowed_hours := NULL; -- clean allowed_hours when error occurs
            
                l_flg_validation := g_flg_validation_error;
                l_err_msg        := REPLACE(pk_message.get_message(i_lang, i_prof, 'OUT_ON_PASS_020'),
                                            '@1',
                                            l_config_total_allowed_hours);
            ELSE
                l_flg_validation := pk_alert_constant.g_yes;
                l_err_msg        := NULL;
            END IF;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => dc.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => dc.id_ds_component_child,
                                      internal_name      => dc.internal_name_child,
                                      VALUE              => CASE dc.id_ds_component_child
                                                                WHEN g_ds_total_allowed_hours THEN
                                                                 pk_utils.number_to_char(i_prof, lv.value)
                                                                WHEN g_ds_dt_in THEN
                                                                 lv.value
                                                                WHEN g_ds_dt_out THEN
                                                                 lv.value
                                                                ELSE
                                                                 NULL
                                                            END,
                                      value_clob         => NULL,
                                      min_value          => null,
                                      max_value          => null,
                                      desc_value         => CASE dc.id_ds_component_child
                                                                WHEN g_ds_total_allowed_hours THEN
                                                                 pk_utils.number_to_char(i_prof, lv.value)
                                                                WHEN g_ds_dt_in THEN
                                                                 lv.value
                                                                WHEN g_ds_dt_out THEN
                                                                 lv.value
                                                                ELSE
                                                                 NULL
                                                            END,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => CASE ld.id_ds_component
                                                                WHEN g_ds_total_allowed_hours THEN
                                                                 l_flg_validation
                                                                ELSE
                                                                 pk_alert_constant.g_yes
                                                            END,
                                      err_msg            => CASE ld.id_ds_component
                                                                WHEN g_ds_total_allowed_hours THEN
                                                                 l_err_msg
                                                                ELSE
                                                                 NULL
                                                            END,
                                      flg_event_type     => dc.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx => 1)
              BULK COLLECT
              INTO tbl_result
              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_patient        => NULL,
                                                 i_component_name => i_root_name,
                                                 i_action         => NULL)) dc
              JOIN (SELECT rownum rn, column_value id_ds_component
                      FROM TABLE(table_number(g_ds_total_allowed_hours, g_ds_dt_out, g_ds_dt_in))) ld
                ON dc.id_ds_component_child = ld.id_ds_component
              JOIN (SELECT rownum rn, column_value VALUE
                      FROM TABLE(table_varchar(l_ds_total_allowed_hours,
                                               pk_date_utils.date_send_tsz(i_lang, l_ds_dt_out, i_prof),
                                               pk_date_utils.date_send_tsz(i_lang, l_ds_dt_in, i_prof)))) lv
                ON lv.rn = ld.rn
             ORDER BY dc.rn;
            ----------------------------------------------
        ELSIF i_action = g_action_submit
        -- if it gets here and action = submit, it means it is a final submit (OK button clicked) and no extra validation is needed
        -- all validations needed are done in data specific code: l_current_ds_component IN (g_ds_dt_out, g_ds_dt_in)
        -- also there is no need to return any data
        THEN
            NULL;
            ----------------------------------------------
        ELSE
            -- if it gets here, it means we ane initializing the OOP, and it is needed to return the default values:
            -- patient_contact_number, attending_physic_agree, requested_by
            l_ds_patient_contact_number := pk_patient.get_patient_phone(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_patient => i_patient);
            l_ds_attending_physic_agree := g_attending_agree;
            l_ds_requested_by           := to_char(pk_alert_constant.g_out_on_pass_req_by_patient);
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => dc.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => dc.id_ds_component_child,
                                      internal_name      => dc.internal_name_child,
                                      VALUE              => lv.value,
                                      desc_value         => CASE dc.id_ds_component_child
                                                                WHEN g_ds_patient_contact_number THEN
                                                                 lv.value
                                                                WHEN g_ds_attending_physic_agree THEN
                                                                 (SELECT pk_sysdomain.get_domain('EPIS_OUT_ON_PASS.FLG_ATTENDING_PHYSIC',
                                                                                                 lv.value,
                                                                                                 i_lang)
                                                                    FROM dual)
                                                                WHEN g_ds_requested_by THEN
                                                                 pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                                                i_prof      => i_prof,
                                                                                                                i_id_option => lv.value)
                                                                ELSE
                                                                 NULL
                                                            END,
                                      value_clob         => NULL,
                                      min_value          => null,
                                      max_value          => null,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => dc.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx => 1)
              BULK COLLECT
              INTO tbl_result
              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_patient        => NULL,
                                                 i_component_name => i_root_name,
                                                 i_action         => NULL)) dc
              JOIN (SELECT rownum rn, column_value id_ds_component
                      FROM TABLE(table_number(g_ds_patient_contact_number,
                                              g_ds_attending_physic_agree,
                                              g_ds_requested_by,
                                              g_ds_request_reason))) ld
                ON dc.id_ds_component_child = ld.id_ds_component
              JOIN (SELECT rownum rn, column_value VALUE
                      FROM TABLE(table_varchar(l_ds_patient_contact_number,
                                               l_ds_attending_physic_agree,
                                               l_ds_requested_by,
                                               l_ds_request_reason))) lv
                ON lv.rn = ld.rn
             ORDER BY dc.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_values;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_epis_out_on_pass;
/
