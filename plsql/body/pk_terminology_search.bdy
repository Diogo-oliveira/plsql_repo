/*-- Last Change Revision: $Rev: 2006807 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-26 15:42:16 +0000 (qua, 26 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_terminology_search IS
    /**************************************************************************
    * Initializes parameters for Diagnoses filters
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
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         Oct-8-2014
    **************************************************************************/
    PROCEDURE init_params_diagnosis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'INIT_PARAMS_DIAGNOSIS';
        -- context_ids index values
        l_lang_idx             CONSTANT NUMBER(24) := 1;
        l_prof_id_idx          CONSTANT NUMBER(24) := 2;
        l_prof_institution_idx CONSTANT NUMBER(24) := 3;
        l_prof_software_idx    CONSTANT NUMBER(24) := 4;
        l_episode_idx          CONSTANT NUMBER(24) := 5;
        l_patient_idx          CONSTANT NUMBER(24) := 6;
        -- context_vals index values
        l_text_search_idx   CONSTANT NUMBER(24) := 1;
        l_diag_flg_type_idx CONSTANT NUMBER(24) := 2;
        --
        PROCEDURE init_namespace_params IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'INIT_NAMESPACE_PARAMS';
        BEGIN
            g_error := 'CALL SET CONTEXT PARAMS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
        
            pk_context_api.set_parameter(g_lang, i_context_ids(l_lang_idx));
            pk_context_api.set_parameter(g_prof_id, i_context_ids(l_prof_id_idx));
            pk_context_api.set_parameter(g_institution, i_context_ids(l_prof_institution_idx));
            pk_context_api.set_parameter(g_software, i_context_ids(l_prof_software_idx));
            pk_context_api.set_parameter(g_patient, i_context_ids(l_patient_idx));
            pk_context_api.set_parameter(g_episode, i_context_ids(l_episode_idx));
        
            IF i_context_vals.exists(l_text_search_idx)
            THEN
                pk_context_api.set_parameter(g_text_search, i_context_vals(l_text_search_idx));
            END IF;
        
            IF i_context_vals.exists(l_diag_flg_type_idx)
            THEN
                pk_context_api.set_parameter(pk_terminology_search.g_epis_diag_type,
                                             i_context_vals(l_diag_flg_type_idx));
            END IF;
        
        END init_namespace_params;
    BEGIN
        init_namespace_params;
    
        CASE i_name
            WHEN 'i_term_lang' THEN
                o_id := 1; -- TODO - change variable name in the filters, this is used only to force filters to call init_param_diagnosis
            WHEN 'i_prof_id' THEN
                o_id := i_context_ids(l_prof_id_idx);
            WHEN 'i_prof_institution' THEN
                o_id := i_context_ids(l_prof_institution_idx);
            WHEN 'i_prof_software' THEN
                o_id := i_context_ids(l_prof_software_idx);
            WHEN 'i_id_episode' THEN
                o_id := i_context_ids(l_episode_idx);
            WHEN 'i_lang' THEN
                o_id := i_context_ids(l_lang_idx);
            WHEN 'i_flg_type' THEN
                o_vc2 := sys_context(g_alert_context, pk_terminology_search.g_epis_diag_type);
            WHEN 'g_epis_diag_status' THEN
                o_vc2 := pk_diagnosis.g_epis_diag_status;
            WHEN 'g_diag_type_b' THEN
                o_vc2 := pk_diagnosis.g_diag_type_b;
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            WHEN 'g_cancelled' THEN
                o_vc2 := pk_alert_constant.g_cancelled;
            WHEN 'g_epis_diag_type_d' THEN
                o_vc2 := pk_diagnosis.g_epis_diag_type_d;
            WHEN 'g_diag_type_p' THEN
                o_vc2 := pk_diagnosis.g_diag_type_p;
            WHEN 'g_ed_flg_status_d' THEN
                o_vc2 := pk_diagnosis.g_ed_flg_status_d;
            WHEN 'g_ed_flg_status_co' THEN
                o_vc2 := pk_diagnosis.g_ed_flg_status_co;
            WHEN 'g_ed_flg_status_ca' THEN
                o_vc2 := pk_diagnosis.g_ed_flg_status_ca;
            WHEN 'g_ed_flg_status_b' THEN
                o_vc2 := pk_diagnosis.g_ed_flg_status_b;
            WHEN 'g_ed_flg_status_r' THEN
                o_vc2 := pk_diagnosis.g_ed_flg_status_r;
            WHEN 'g_sys_cfg_show_all_diag_states' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_cfg_show_all_diag_states,
                                                 i_prof    => profissional(l_prof_id_idx,
                                                                           l_prof_institution_idx,
                                                                           l_prof_software_idx));
            WHEN 'g_epis_diag_notes_status' THEN
                o_vc2 := pk_diagnosis.g_epis_diag_notes_status;
            WHEN 'g_active' THEN
                o_vc2 := pk_alert_constant.g_active;
            WHEN 'g_text_search' THEN
                o_vc2 := sys_context(g_alert_context, pk_terminology_search.g_text_search);
            WHEN 'g_code_column_name' THEN
                o_vc2 := pk_diagnosis.g_code_column_name;
            WHEN 'g_problem_type_d' THEN
                o_vc2 := pk_problems.g_type_d;
            WHEN 'g_medical_diagnosis_type' THEN
                o_vc2 := g_medical_diagnosis_type;
            WHEN 'i_id_patient' THEN
                o_id := i_context_ids(l_patient_idx);
            WHEN 'g_prob_flg_cancel' THEN
                o_vc2 := pk_problems.g_flg_cancel;
            WHEN 'g_pat_problem' THEN
                o_vc2 := pk_problems.g_pat_problem;
            ELSE
                g_error := 'PARAMETER NOT FOUND: ' || i_name;
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        END CASE;
    END init_params_diagnosis;

    /********************************************************************************************
    * Loads context variables used by filter functions
    *
    * @param o_lang                  Language identifier
    * @param o_prof                  Professional information
    * @param o_profile_template      Profile template ID
    * @param o_id_patient            Patient ID
    * @param o_episode               Episode ID
    * @param o_text_search           Text used in the application to filter the content
    * @param o_epis_diag_type        Diagnosis type (epis_diagnosis.flg_type)
    *
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         Oct-8-2014
    ********************************************************************************************/
    PROCEDURE load_search_values
    (
        o_lang             OUT language.id_language%TYPE,
        o_prof             OUT profissional,
        o_profile_template OUT profile_template.id_profile_template%TYPE,
        o_id_patient       OUT patient.id_patient%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_text_search      OUT VARCHAR2,
        o_epis_diag_type   OUT epis_diagnosis.flg_type%TYPE
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'LOAD_SEARCH_VALUES';
    BEGIN
        g_error := 'GET STANDARD INFO';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        o_lang             := sys_context(g_alert_context, pk_terminology_search.g_lang);
        o_id_patient       := sys_context(g_alert_context, pk_terminology_search.g_patient);
        o_prof             := profissional(id          => sys_context(g_alert_context, pk_terminology_search.g_prof_id),
                                           institution => sys_context(g_alert_context,
                                                                      pk_terminology_search.g_institution),
                                           software    => sys_context(g_alert_context, pk_terminology_search.g_software));
        o_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => o_prof);
        o_episode          := sys_context(g_alert_context, pk_terminology_search.g_episode);
        o_text_search      := sys_context(g_alert_context, pk_terminology_search.g_text_search);
        o_epis_diag_type   := sys_context(g_alert_context, pk_terminology_search.g_epis_diag_type);
    END;

    /**************************************************************************************************************
    * Creates t_coll_diagnosis_config object by diagnosis information existing in the table function t_table_diag_cnt
    *
    * @param i_prof                    Current professional
    * @param i_episode                 Episode identifier
    * @param i_tbl_diagnosis           t_table_diag_cnt table function to be mapped
    *
    * @return                           Returns t_coll_diagnosis_config table function
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION get_t_coll_diagnosis_config
    (
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_diag_type              IN epis_diagnosis.flg_type%TYPE DEFAULT NULL,
        i_tbl_diagnosis          IN t_table_diag_cnt,
        i_flg_is_transaction_tbl IN VARCHAR2,
        i_diagnoses_mechanism    IN sys_config.value%TYPE DEFAULT pk_alert_constant.g_diag_old_search_mechanism
    ) RETURN t_coll_diagnosis_config IS
        l_tbl_all_diagnosis t_coll_diagnosis_config;
        l_func_name         VARCHAR2(32) := 'GET_T_COLL_DIAGNOSIS_CONFIG';
    BEGIN
    
        g_error := 'VALUES - i_prof.id: ' || i_prof.id || ', i_prof.institution: ' || i_prof.institution ||
                   ', i_prof.software: ' || i_prof.software || ', i_episode: ' || i_episode;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF i_tbl_diagnosis.exists(1)
        THEN
            g_error := 'EXISTING VALUES IN I_TBL_DIAGNOSIS  - ' || i_tbl_diagnosis.count;
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            g_error := 'T_COLL_DIAGNOSIS_CONFIG OBJECT CONSTRUCTION';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF i_diagnoses_mechanism = pk_alert_constant.g_diag_old_search_mechanism
            THEN
                SELECT t_rec_diagnosis_config(id_diagnosis            => id_diagnosis,
                                              id_diagnosis_parent     => id_diagnosis_parent,
                                              id_epis_diagnosis       => id_epis_diagnosis,
                                              desc_diagnosis          => desc_diagnosis,
                                              code_icd                => code_icd,
                                              flg_other               => flg_other,
                                              status_diagnosis        => status_diagnosis,
                                              icon_status             => NULL,
                                              avail_for_select        => flg_select,
                                              default_new_status      => NULL,
                                              default_new_status_desc => NULL,
                                              id_alert_diagnosis      => id_alert_diagnosis,
                                              desc_epis_diagnosis     => desc_epis_diagnosis,
                                              flg_terminology         => flg_terminology,
                                              flg_diag_type           => NULL,
                                              rank                    => rank,
                                              code_diagnosis          => code_diagnosis,
                                              flg_icd9                => flg_icd9,
                                              flg_show_term_code      => flg_show_term_code,
                                              id_language             => id_language,
                                              flg_status              => dc_flg_status,
                                              flg_type                => dc_flg_type,
                                              id_tvr_msi              => id_tvr_msi)
                  BULK COLLECT
                  INTO l_tbl_all_diagnosis
                  FROM (SELECT id_diagnosis,
                               id_diagnosis_parent,
                               id_epis_diagnosis   id_epis_diagnosis,
                               desc_diagnosis,
                               code_icd,
                               flg_status          status_diagnosis,
                               id_alert_diagnosis,
                               flg_other,
                               rank,
                               desc_epis_diagnosis desc_epis_diagnosis,
                               flg_terminology,
                               code_translation    code_diagnosis,
                               id_language,
                               flg_icd9,
                               flg_show_term_code,
                               flg_select,
                               dc_flg_status,
                               dc_flg_type,
                               id_tvr_msi
                          FROM (SELECT /*+ opt_estimate(table dc rows=1)  */
                                 dc.id_diagnosis,
                                 dc.id_diagnosis_parent,
                                 dc.desc_translation desc_diagnosis,
                                 dc.code_icd,
                                 dc.id_alert_diagnosis,
                                 dc.flg_other,
                                 NULL rank,
                                 dc.desc_epis_diagnosis,
                                 dc.flg_terminology,
                                 dc.code_translation,
                                 dc.id_language,
                                 dc.flg_icd9,
                                 dc.flg_show_term_code,
                                 dc.flg_select,
                                 decode(i_flg_is_transaction_tbl, pk_alert_constant.g_yes, ed.flg_status, NULL) flg_status,
                                 dc.id_epis_diagnosis,
                                 dc.flg_status dc_flg_status,
                                 dc.flg_type dc_flg_type,
                                 dc.id_tvr_msi
                                  FROM TABLE(i_tbl_diagnosis) dc
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = dc.id_diagnosis
                                  LEFT JOIN epis_diagnosis ed
                                    ON ed.id_diagnosis = dc.id_diagnosis
                                   AND ed.id_alert_diagnosis = dc.id_alert_diagnosis
                                   AND ((ed.desc_epis_diagnosis = dc.desc_translation AND
                                       nvl(d.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes) OR
                                       (nvl(d.flg_other, pk_alert_constant.g_no) != pk_alert_constant.g_yes))
                                   AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca
                                   AND ed.id_episode = i_episode
                                   AND ed.flg_type = i_diag_type));
            ELSE
                SELECT t_rec_diagnosis_config(id_diagnosis            => id_diagnosis,
                                              id_diagnosis_parent     => id_diagnosis_parent,
                                              id_epis_diagnosis       => id_epis_diagnosis,
                                              desc_diagnosis          => desc_diagnosis,
                                              code_icd                => code_icd,
                                              flg_other               => flg_other,
                                              status_diagnosis        => status_diagnosis,
                                              icon_status             => NULL,
                                              avail_for_select        => flg_select,
                                              default_new_status      => NULL,
                                              default_new_status_desc => NULL,
                                              id_alert_diagnosis      => id_alert_diagnosis,
                                              desc_epis_diagnosis     => desc_epis_diagnosis,
                                              flg_terminology         => flg_terminology,
                                              flg_diag_type           => NULL,
                                              rank                    => rank,
                                              code_diagnosis          => code_diagnosis,
                                              flg_icd9                => flg_icd9,
                                              flg_show_term_code      => flg_show_term_code,
                                              id_language             => id_language,
                                              flg_status              => dc_flg_status,
                                              flg_type                => dc_flg_type,
                                              id_tvr_msi              => id_tvr_msi)
                  BULK COLLECT
                  INTO l_tbl_all_diagnosis
                  FROM (SELECT id_diagnosis,
                               id_diagnosis_parent,
                               id_epis_diagnosis   id_epis_diagnosis,
                               desc_diagnosis,
                               code_icd,
                               flg_status          status_diagnosis,
                               id_alert_diagnosis,
                               flg_other,
                               rank,
                               desc_epis_diagnosis desc_epis_diagnosis,
                               flg_terminology,
                               code_translation    code_diagnosis,
                               id_language,
                               flg_icd9,
                               flg_show_term_code,
                               flg_select,
                               dc_flg_status,
                               dc_flg_type,
                               id_tvr_msi
                          FROM (SELECT /*+ opt_estimate(table dc rows=1)  */
                                 dc.id_diagnosis,
                                 dc.id_diagnosis_parent,
                                 dc.desc_translation desc_diagnosis,
                                 dc.code_icd,
                                 dc.id_alert_diagnosis,
                                 dc.flg_other,
                                 NULL rank,
                                 dc.desc_epis_diagnosis,
                                 dc.flg_terminology,
                                 dc.code_translation,
                                 dc.id_language,
                                 dc.flg_icd9,
                                 dc.flg_show_term_code,
                                 dc.flg_select,
                                 decode(i_flg_is_transaction_tbl, pk_alert_constant.g_yes, ed.flg_status, NULL) flg_status,
                                 dc.id_epis_diagnosis,
                                 dc.flg_status dc_flg_status,
                                 dc.flg_type dc_flg_type,
                                 dc.id_tvr_msi
                                  FROM TABLE(i_tbl_diagnosis) dc
                                  LEFT JOIN epis_diagnosis ed
                                    ON ed.id_alert_diagnosis = dc.id_alert_diagnosis
                                   AND ((ed.desc_epis_diagnosis = dc.desc_translation AND
                                       nvl(dc.flg_other, pk_alert_constant.g_no) = pk_alert_constant.g_yes) OR
                                       (nvl(dc.flg_other, pk_alert_constant.g_no) != pk_alert_constant.g_yes))
                                   AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca
                                   AND ed.id_episode = i_episode
                                   AND ed.flg_type = i_diag_type));
            END IF;
        
        ELSE
            l_tbl_all_diagnosis := NULL;
        END IF;
    
        RETURN l_tbl_all_diagnosis;
    END get_t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Creates 'with previous records' string
    *
    * @param i_lang                     Language identifier
    * @param i_id_task_type             Area - Problems (60), Past medical history (62), Diagnoses (63)
    * @param i_date_tstz                Date when diagnoses was registered/Date of initial diagnosis
    *
    * @return                           Returns complete string
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION get_with_prev_rec_msg
    (
        i_lang         IN language.id_language%TYPE,
        i_id_task_type IN NUMBER,
        i_date_tstz    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_date_msg             sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'COMMON_M143');
        l_date_diag_msg        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DIAGNOSIS_M046');
        l_problem_msg          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DIAGNOSIS_M043');
        l_past_medica_hist_msg sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DIAGNOSIS_M044');
        l_diag_msg             sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DIAGNOSIS_M045');
        l_msg                  VARCHAR2(200 CHAR);
    
        l_func_name VARCHAR2(32) := 'GET_WITH_PREV_REC_MSG';
    BEGIN
        g_error := 'GET_WITH_PREV_REC_MSG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT decode(i_id_task_type,
                      pk_alert_constant.g_task_diagnosis,
                      l_diag_msg,
                      pk_alert_constant.g_task_problems,
                      l_problem_msg,
                      pk_alert_constant.g_task_medical_history,
                      l_past_medica_hist_msg) ||
               decode(i_date_tstz,
                      NULL,
                      '',
                      ' (' || decode(i_id_task_type, pk_alert_constant.g_task_diagnosis, l_date_diag_msg, l_date_msg) || ' ' ||
                      i_date_tstz || ')')
          INTO l_msg
          FROM dual;
    
        RETURN l_msg;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_with_prev_rec_msg;

    /***********************************************************************************************
    * Loads "problem type" field in Problems confirmation screen
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   Professional information
    * @param i_patient                Patient ID
    * @param i_id_diagnoses           Diagnosis ID
    * @param i_id_alert_diagnoses     Alert_diagnosis ID
    *
    * @param o_areas_domain           Returns areas available in the multichoice
    * @param o_diagnoses_types        For each diagnosis, returns areas where it is configured
    * @param o_diagnoses_warning      Returns header warning value
    * @param o_error                  Error information
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    FUNCTION get_diagnoses_types
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_id_diagnoses       IN table_number,
        i_id_alert_diagnoses IN table_number,
        o_areas_domain       OUT pk_types.cursor_type,
        o_diagnoses_types    OUT table_table_varchar,
        o_diagnoses_warning  OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DIAGNOSES_TYPES';
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
        l_prob_mechanism      sys_config.value%TYPE;
    
        l_diagnoses_types table_varchar;
    
        l_configured_task_types table_number := table_number();
    
        FUNCTION diagnosis_is_type
        (
            i_task_type          IN task_type.id_task_type%TYPE,
            i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
            i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
        ) RETURN BOOLEAN IS
        
            l_tbl_diags t_table_diag_cnt;
        BEGIN
            g_error := 'CHECK CONTENT AVAILABILITY';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_tbl_diags := pk_terminology_search.tf_diagnoses_search(i_lang                     => i_lang,
                                                                     i_prof                     => i_prof,
                                                                     i_patient                  => i_patient,
                                                                     i_terminologies_task_types => table_number(i_task_type),
                                                                     i_term_task_type           => i_task_type,
                                                                     i_list_type                => g_diag_list_searchable,
                                                                     i_tbl_diagnosis            => table_number(i_id_diagnosis),
                                                                     i_tbl_alert_diagnosis      => table_number(i_id_alert_diagnosis));
            IF l_tbl_diags.count <= 0
            THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END;
    
        FUNCTION diagnosis_is_type
        (
            i_task_type                 IN task_type.id_task_type%TYPE,
            i_tbl_configured_task_types IN table_number
        ) RETURN BOOLEAN IS
        
            l_count NUMBER;
        BEGIN
            g_error := 'CHECK CONTENT AVAILABILITY';
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            SELECT /*+opt_estimate(table t rows=1)*/
             COUNT(1)
              INTO l_count
              FROM TABLE(i_tbl_configured_task_types) t
             WHERE t.column_value = i_task_type;
        
            IF l_count <= 0
            THEN
                RETURN FALSE;
            END IF;
            RETURN TRUE;
        END;
    
    BEGIN
        l_diagnoses_types := table_varchar();
        o_diagnoses_types := table_table_varchar();
    
        g_error := 'CALL PK_PROBLEMS.GET_AREAS_DOMAIN';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_problems.get_areas_domain(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_id_record => NULL,
                                            o_list      => o_areas_domain,
                                            o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_PROBLEMS.GET_DIAG_FLG_WARNING';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF NOT pk_problems.get_diag_flg_warning(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_diag         => i_id_diagnoses,
                                                o_diag_warning => o_diagnoses_warning,
                                                o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, i_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, i_prof);
        l_prob_mechanism      := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, i_prof);
    
        g_error := 'GET DIAGNOSES TYPES';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR i IN 1 .. i_id_diagnoses.count
        LOOP
            l_diagnoses_types.extend;
            l_diagnoses_types(l_diagnoses_types.count) := i_id_alert_diagnoses(i);
            l_diagnoses_types.extend;
        
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
               OR l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
               OR l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
            
                SELECT /*+opt_estimate(table t rows=1)*/
                 *
                  BULK COLLECT
                  INTO l_configured_task_types
                  FROM TABLE(pk_ts3_search.get_term_task_types(i_id_language     => i_lang,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_concept_type    => 'DIAGNOSIS',
                                                               i_id_concept_term => i_id_alert_diagnoses(i),
                                                               i_id_patient      => i_patient)) t;
            END IF;
        
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                IF diagnosis_is_type(i_task_type                 => pk_alert_constant.g_task_problems,
                                     i_tbl_configured_task_types => l_configured_task_types)
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            ELSE
                IF diagnosis_is_type(i_task_type          => pk_alert_constant.g_task_problems,
                                     i_id_diagnosis       => i_id_diagnoses(i),
                                     i_id_alert_diagnosis => i_id_alert_diagnoses(i))
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            l_diagnoses_types.extend;
            IF l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                IF diagnosis_is_type(i_task_type                 => pk_alert_constant.g_task_medical_history,
                                     i_tbl_configured_task_types => l_configured_task_types)
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            ELSE
                IF diagnosis_is_type(i_task_type          => pk_alert_constant.g_task_medical_history,
                                     i_id_diagnosis       => i_id_diagnoses(i),
                                     i_id_alert_diagnosis => i_id_alert_diagnoses(i))
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            l_diagnoses_types.extend;
            IF l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                IF diagnosis_is_type(i_task_type                 => pk_alert_constant.g_task_surgical_history,
                                     i_tbl_configured_task_types => l_configured_task_types)
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            ELSE
                IF diagnosis_is_type(i_task_type          => pk_alert_constant.g_task_surgical_history,
                                     i_id_diagnosis       => i_id_diagnoses(i),
                                     i_id_alert_diagnosis => i_id_alert_diagnoses(i))
                THEN
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_yes;
                ELSE
                    l_diagnoses_types(l_diagnoses_types.count) := pk_alert_constant.g_no;
                END IF;
            END IF;
        
            o_diagnoses_types.extend;
            o_diagnoses_types(o_diagnoses_types.count) := l_diagnoses_types;
        
            l_diagnoses_types := table_varchar();
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_areas_domain);
            pk_types.open_my_cursor(o_diagnoses_warning);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnoses_types;

    /********************************************************************************************************
    * Gets all diagnosis that are associated to a complaint for a task type
    *
    * @param i_task_type                Task type (problems/past history)
    *
    * @return                           Returns complaint diagnoses
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION get_past_hist_complain_diags(i_task_type IN task_type.id_task_type%TYPE) RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(30 CHAR) := 'GET_PAST_HIST_COMPLAIN_DIAGS';
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_tbl_complaint_adiags table_number;
        l_tbl_complaint        table_number;
        l_profile_template     profile_template.id_profile_template%TYPE;
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
    
        l_flg_show_term_code sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD SEARCH VALUES - GET_PAST_HIST_COMPLAIN_DIAGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => l_prof);
    
        IF (i_task_type = pk_alert_constant.g_task_surgical_history AND
           l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (i_task_type = pk_alert_constant.g_task_medical_history AND
           l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
        THEN
            g_error := 'GET COMPLAINTS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT *
              BULK COLLECT
              INTO l_tbl_complaint
              FROM TABLE(pk_complaint.get_epis_act_complaint(i_lang => l_lang, i_prof => l_prof, i_episode => l_episode));
        
            IF l_tbl_complaint.exists(1)
            THEN
                g_error := 'GET DIAGNOSIS(by complaint)';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                RETURN pk_terminology_search.get_diagnoses_search(i_lang                     => l_lang,
                                                                  i_prof                     => l_prof,
                                                                  i_patient                  => l_patient,
                                                                  i_terminologies_task_types => table_number(i_task_type),
                                                                  i_tbl_term_task_type       => table_number(i_task_type),
                                                                  i_list_type                => g_diag_list_searchable,
                                                                  i_text_search              => l_text_search,
                                                                  i_tbl_complaint            => l_tbl_complaint,
                                                                  i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
            END IF;
        ELSE
            g_error := 'GET COMPLAINT DIAGS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT DISTINCT cad.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_complaint_adiags
              FROM complaint_alert_diagnosis cad
             WHERE cad.id_complaint IN
                   (SELECT *
                      FROM TABLE(pk_complaint.get_epis_act_complaint(i_lang    => l_lang,
                                                                     i_prof    => l_prof,
                                                                     i_episode => l_episode)))
               AND cad.flg_available = pk_alert_constant.g_available
               AND cad.id_software IN (l_prof.software, 0)
               AND cad.id_institution IN (l_prof.institution, 0)
               AND cad.id_profile_template IN (l_profile_template, 0);
        
            IF l_tbl_complaint_adiags.exists(1)
            THEN
                g_error := 'GET DIAGNOSIS(by complaint)';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
            
                RETURN pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                                 i_prof                     => l_prof,
                                                                 i_patient                  => l_patient,
                                                                 i_terminologies_task_types => table_number(i_task_type),
                                                                 i_term_task_type           => i_task_type,
                                                                 i_flg_show_term_code       => l_flg_show_term_code,
                                                                 i_list_type                => g_diag_list_searchable,
                                                                 i_text_search              => l_text_search,
                                                                 i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                 i_tbl_alert_diagnosis      => l_tbl_complaint_adiags);
            END IF;
        END IF;
    
        RETURN t_table_diag_cnt();
    END get_past_hist_complain_diags;

    /********************************************************************************************************
    * Gets all diagnosis that are associated to a clinical service for a task type
    *
    * @param i_task_type                Task type (problems/past history)
    *
    * @return                           Returns clinical service diagnoses
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION get_past_hist_clin_serv_diags(i_task_type IN task_type.id_task_type%TYPE) RETURN t_table_diag_cnt IS
        l_func_name         VARCHAR2(30 CHAR) := 'GET_PAST_HIST_CLIN_SERV_DIAGS';
        l_lang              language.id_language%TYPE;
        l_patient           patient.id_patient%TYPE;
        l_prof              profissional;
        l_episode           episode.id_episode%TYPE;
        l_text_search       translation.desc_lang_1%TYPE;
        l_epis_diag_type    epis_diagnosis.flg_type%TYPE;
        l_profile_template  profile_template.id_profile_template%TYPE;
        l_tbl_cs_adiags     table_number;
        l_tbl_clin_serv     table_number;
        l_tbl_dep_clin_serv table_number;
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
    
        l_flg_show_term_code sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - GET_PAST_HIST_CLIN_SERV_DIAGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => l_prof);
    
        g_error := 'GET COMPLAINT DIAGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT t.id_clinical_service
          BULK COLLECT
          INTO l_tbl_clin_serv
          FROM (
                 --Diagnoses by episode's clinical service
                SELECT dcs.id_clinical_service
                  FROM epis_info epo, dep_clin_serv dcs
                 WHERE epo.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND epo.id_episode = l_episode
                UNION
                --Diagnoses by scheduled clinical service
                SELECT dcs.id_clinical_service
                  FROM epis_info epo, dep_clin_serv dcs
                 WHERE epo.id_dcs_requested = dcs.id_dep_clin_serv
                   AND epo.id_episode = l_episode
                UNION
                --Diagnoses by Appointment
                SELECT e.id_clinical_service
                  FROM episode e
                 WHERE e.id_episode = l_episode) t;
    
        IF (i_task_type = pk_alert_constant.g_task_surgical_history AND
           l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (i_task_type = pk_alert_constant.g_task_medical_history AND
           l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
        THEN
        
            g_error := 'GET LIST OF DEP_CLIN_SERV';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT DISTINCT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_tbl_dep_clin_serv
              FROM dep_clin_serv dcs
              JOIN department d
                ON d.id_department = dcs.id_department
              JOIN institution i
                ON i.id_institution = d.id_institution
             WHERE dcs.id_clinical_service IN (SELECT /*+ cardinality(c 10) */
                                                c.column_value
                                                 FROM TABLE(l_tbl_clin_serv) c)
               AND i.id_institution = l_prof.institution
               AND d.id_software = l_prof.software
               AND d.flg_available = pk_alert_constant.g_yes
               AND dcs.flg_available = pk_alert_constant.g_yes;
        
            IF l_tbl_dep_clin_serv.exists(1)
            THEN
                g_error := 'GET DIAGNOSIS(by clin servs)';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                RETURN get_diagnoses_search(i_lang                     => l_lang,
                                            i_prof                     => l_prof,
                                            i_patient                  => l_patient,
                                            i_terminologies_task_types => table_number(i_task_type),
                                            i_tbl_term_task_type       => table_number(i_task_type),
                                            i_list_type                => g_diag_list_searchable,
                                            i_text_search              => l_text_search,
                                            i_tbl_dep_clin_serv        => l_tbl_dep_clin_serv,
                                            i_context_type             => pk_ts_logic.k_ctx_type_d_dep_clin_serv);
            END IF;
        
        ELSE
        
            g_error := 'GET ALERT_DIAGS BY CLINICAL SERVICE';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT DISTINCT csd.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_cs_adiags
              FROM clin_serv_alert_diagnosis csd
             WHERE csd.id_clinical_service IN (SELECT /*+ cardinality(c 10) */
                                                c.column_value
                                                 FROM TABLE(l_tbl_clin_serv) c)
               AND csd.flg_available = pk_alert_constant.g_available
               AND csd.id_software IN (l_prof.software, 0)
               AND csd.id_institution IN (l_prof.institution, 0)
               AND csd.id_profile_template IN (l_profile_template, 0);
        
            IF l_tbl_cs_adiags.exists(1)
            THEN
                g_error := 'GET DIAGNOSIS(by clin servs)';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                RETURN pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                                 i_prof                     => l_prof,
                                                                 i_patient                  => l_patient,
                                                                 i_terminologies_task_types => table_number(i_task_type),
                                                                 i_term_task_type           => i_task_type,
                                                                 i_flg_show_term_code       => l_flg_show_term_code,
                                                                 i_list_type                => g_diag_list_searchable,
                                                                 i_text_search              => l_text_search,
                                                                 i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                 i_tbl_alert_diagnosis      => l_tbl_cs_adiags);
            END IF;
        END IF;
    
        RETURN t_table_diag_cnt();
    END get_past_hist_clin_serv_diags;

    /********************************************************************************************************
    * Gets all diagnosis registered in the current episode.
    *
    * @return                           Returns an episode's diagnoses
    *                                   (used in v_episode_all_diagnoses)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_episode_diagnoses RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_EPISODE_DIAGNOSES';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
        l_ret              t_table_diag_cnt;
        --
        l_code_msg_prev_records sys_message.code_message%TYPE := 'DIAGNOSIS_M033'; --With previous records
        l_code_msg_dt_init_diag sys_message.code_message%TYPE := 'DIAGNOSIS_M034'; --Date of initial diagnosis
        --
        l_desc_msg_prev_records sys_message.code_message%TYPE := 'DIAGNOSIS_M033'; --With previous records
        l_desc_msg_dt_init_diag sys_message.code_message%TYPE := 'DIAGNOSIS_M034'; --Date of initial diagnosis
        --
        l_tbl_diag_trs           t_coll_episode_diagnosis;
        l_tbl_diag_content       t_table_diag_cnt;
        l_tbl_id_diagnosis       table_number;
        l_tbl_id_alert_diagnosis table_number;
    
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_EPISODE_DIAGNOSES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => l_prof);
    
        l_desc_msg_prev_records := pk_message.get_message(i_lang => l_lang, i_code_mess => l_code_msg_prev_records);
        l_desc_msg_dt_init_diag := pk_message.get_message(i_lang => l_lang, i_code_mess => l_code_msg_dt_init_diag);
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, l_prof);
    
        g_error := 'CALL PK_DIAGNOSIS_CORE.TB_GET_EPIS_DIAGNOSIS_LIST - GET PATIENT DIFFERENTIAL DIAGNOSIS BY EPISODE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            --When using the new mechanism, the search for transactional records
            --does not have to be performed using a text search. 
            l_tbl_diag_trs := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang       => l_lang,
                                                                           i_prof       => l_prof,
                                                                           i_patient    => l_patient,
                                                                           i_id_scope   => l_patient,
                                                                           i_flg_scope  => pk_patient.g_scope_patient,
                                                                           i_flg_type   => NULL,
                                                                           i_tbl_status => table_varchar(pk_diagnosis.g_ed_flg_status_co));
        ELSE
            l_tbl_diag_trs := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang                  => l_lang,
                                                                           i_prof                  => l_prof,
                                                                           i_patient               => l_patient,
                                                                           i_id_scope              => l_patient,
                                                                           i_flg_scope             => pk_patient.g_scope_patient,
                                                                           i_flg_type              => NULL,
                                                                           i_criteria              => l_text_search,
                                                                           i_format_text           => pk_alert_constant.g_no,
                                                                           i_translation_desc_only => pk_alert_constant.g_yes,
                                                                           i_tbl_status            => table_varchar(pk_diagnosis.g_ed_flg_status_co));
        END IF;
    
        IF l_tbl_diag_trs.count = 0
        THEN
            RETURN l_ret;
        END IF;
    
        g_error := 'GET TWO TABLE NUMBER OBJECTS THAT CONTAINS ID DIAGNOSIS/ID ALERT DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT epis_diag.id_diagnosis, epis_diag.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
              FROM TABLE(l_tbl_diag_trs) epis_diag;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_id_diagnosis       := table_number();
                l_tbl_id_alert_diagnosis := table_number();
        END;
    
        g_error := '6- CHECK CONTENT AVAILABILITY';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            l_tbl_diag_content := get_diagnoses_search(i_lang                     => l_lang,
                                                       i_prof                     => l_prof,
                                                       i_patient                  => l_patient,
                                                       i_text_search              => l_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                       i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_diagnosis),
                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                       i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
        ELSE
            l_tbl_diag_content := tf_diagnoses_search(i_lang                     => l_lang,
                                                      i_prof                     => l_prof,
                                                      i_patient                  => l_patient,
                                                      i_text_search              => l_text_search,
                                                      i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                      i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                      i_flg_show_term_code       => l_flg_show_term_code,
                                                      i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                      i_tbl_diagnosis            => l_tbl_id_diagnosis,
                                                      i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
        END IF;
    
        g_error := 'TB_GET_EPIS_DIAGNOSIS_LIST - TF_EPISODE_DIAGNOSES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                              id_diagnosis_parent => id_diagnosis_parent,
                              id_alert_diagnosis  => id_alert_diagnosis,
                              code_icd            => code_icd,
                              id_language         => decode(id_language,
                                                            0,
                                                            sys_context('ALERT_CONTEXT', pk_terminology_search.g_lang),
                                                            id_language),
                              code_translation    => NULL,
                              desc_epis_diagnosis => l_desc_msg_prev_records ||
                                                     decode(dt_initial_diag_chr,
                                                            NULL,
                                                            NULL,
                                                            ' (' || l_desc_msg_dt_init_diag || ': ' || dt_initial_diag_chr || ')'),
                              desc_translation    => desc_diagnosis,
                              flg_other           => flg_other,
                              flg_icd9            => flg_icd9,
                              flg_select          => decode(flg_status,
                                                            pk_diagnosis.g_ed_flg_status_r,
                                                            pk_alert_constant.g_yes,
                                                            pk_diagnosis.g_ed_flg_status_ca,
                                                            pk_alert_constant.g_yes,
                                                            NULL,
                                                            pk_alert_constant.g_yes,
                                                            pk_alert_constant.g_no),
                              id_dep_clin_serv    => NULL,
                              flg_terminology     => flg_terminology,
                              rank                => -1, --This records must always be shown in first place
                              id_term_task_type   => NULL,
                              flg_show_term_code  => flg_show_term_code,
                              id_epis_diagnosis   => NULL,
                              flg_status          => NULL,
                              flg_type            => pk_problems.g_type_d,
                              flg_mechanism       => flg_mechanism,
                              id_tvr_msi          => id_tvr_msi)
        /*This flg_type is for check it is patient diagnosis in filter column*/
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+opt_estimate(table tb_epis rows=1)*/
                 tb_epis.id_diagnosis,
                 d.id_diagnosis_parent,
                 tb_epis.id_alert_diagnosis,
                 d.code_icd,
                 ad.id_language,
                 tb_epis.desc_diagnosis,
                 tb_epis.flg_other,
                 ad.flg_icd9,
                 'ID_TERM_VERSION: ' || d.id_terminology_version flg_terminology,
                 tb_epis.id_epis_diagnosis,
                 tb_epis.flg_status,
                 tb_epis.rank,
                 tb_epis.dt_initial_diag_chr,
                 ts.flg_show_term_code,
                 ts.flg_mechanism,
                 ts.id_tvr_msi
                  FROM TABLE(l_tbl_diag_content) ts --Diagnoses that exist in current configuration of terminologies
                  JOIN TABLE(l_tbl_diag_trs) tb_epis --Diagnoses registered for this patient
                    ON tb_epis.id_diagnosis = ts.id_diagnosis
                   AND tb_epis.id_alert_diagnosis = ts.id_alert_diagnosis
                  JOIN diagnosis d
                    ON d.id_diagnosis = tb_epis.id_diagnosis
                  JOIN alert_diagnosis ad
                    ON ad.id_alert_diagnosis = tb_epis.id_alert_diagnosis);
    
        RETURN l_ret;
    
    END tf_episode_diagnoses;

    /********************************************************************************************************
    * Gets all the problems configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_problems)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_problems RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(32 CHAR) := 'TF_COMPLAINT_PROBLEMS';
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_tbl_complaint_diags  table_number;
        l_tbl_complaint_adiags table_number;
        l_diagnosis            table_number;
        l_alert_diagnosis      table_number;
        l_desc_detail          table_varchar;
        l_epis_diagnosis       table_number;
        l_id_complaint         table_number;
        l_error                t_error_out;
    
        l_synonym_list_enable sys_config.value%TYPE;
    
        l_flg_show_term_code sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_COMPLAINT_PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                        i_prof    => l_prof);
    
        g_error := 'GET PREVIOUS PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Obtain the array of id_epis_diagnosis regarding the problems documented in previous episodes
        --(Problems documented via discharge diagnosis)
        IF NOT pk_problems.get_pat_prob_active_diag(i_lang           => l_lang,
                                                    i_prof           => l_prof,
                                                    i_patient        => l_patient,
                                                    i_episode        => l_episode,
                                                    o_epis_diagnosis => l_epis_diagnosis,
                                                    o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL GET_DIAG_FROM_EPIS_DIAG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Obtain the id_diangosis and id_alert_diagnosis for the previously documented problems
        --(These should not be presented on the search list)
        IF NOT pk_diagnosis_core.get_diag_from_epis_diag(i_lang            => l_lang,
                                                         i_prof            => l_prof,
                                                         i_episode         => l_episode,
                                                         i_epis_diagnosis  => l_epis_diagnosis,
                                                         o_diagnosis       => l_diagnosis,
                                                         o_alert_diagnosis => l_alert_diagnosis,
                                                         o_desc_detail     => l_desc_detail,
                                                         o_error           => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET COMPLAINT DIAGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT t.id_diagnosis,
               pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => t.id_diagnosis) id_alert_diagnosis
          BULK COLLECT
          INTO l_tbl_complaint_diags, l_tbl_complaint_adiags
          FROM (SELECT DISTINCT cd.id_diagnosis
                  FROM doc_template_diagnosis cd
                 WHERE cd.id_complaint IN
                       (SELECT *
                          FROM TABLE(pk_complaint.get_epis_act_complaint(i_lang    => l_lang,
                                                                         i_prof    => l_prof,
                                                                         i_episode => l_episode)))
                   AND cd.id_diagnosis NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                column_value
                                                 FROM TABLE(l_diagnosis) t)
                   AND EXISTS (SELECT 1
                          FROM diagnosis_ea e
                          JOIN diagnosis_conf_ea c
                            ON c.flg_terminology = e.flg_terminology
                           AND c.id_institution = e.id_institution
                           AND c.id_software = e.id_software
                           AND c.id_task_type = pk_alert_constant.g_task_diagnosis
                         WHERE e.id_institution = l_prof.institution
                           AND e.id_software = l_prof.software
                           AND e.flg_msi_concept_term = 'P' --searchable_diags
                           AND e.flg_diag_type = 'M' --medical_diags
                           AND e.id_concept_version = cd.id_diagnosis)
                   AND cd.flg_available = pk_alert_constant.g_available) t;
    
        IF l_tbl_complaint_diags.count > 0
           OR l_tbl_complaint_adiags.count > 0
        THEN
            g_error := 'GET DIAGNOSES LIST FILTERED BY COMPLAINT DIAGS';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                             i_prof                     => l_prof,
                                                             i_patient                  => l_patient,
                                                             i_text_search              => l_text_search,
                                                             i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                             i_term_task_type           => pk_alert_constant.g_task_problems,
                                                             i_flg_show_term_code       => l_flg_show_term_code,
                                                             i_list_type                => g_diag_list_searchable,
                                                             i_synonym_list_enable      => l_synonym_list_enable,
                                                             i_tbl_diagnosis            => l_tbl_complaint_diags,
                                                             i_tbl_alert_diagnosis      => l_tbl_complaint_adiags);
        ELSE
            RETURN t_table_diag_cnt();
        END IF;
    
    END tf_complaint_problems;

    FUNCTION tf_get_complaint_problems RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(32 CHAR) := 'TF_GET_COMPLAINT_PROBLEMS';
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_tbl_complaint_diags  table_number;
        l_tbl_complaint_adiags table_number;
        l_diagnosis            table_number;
        l_alert_diagnosis      table_number;
        l_desc_detail          table_varchar;
        l_epis_diagnosis       table_number;
        l_id_complaint         table_number;
        l_error                t_error_out;
    
        l_synonym_list_enable sys_config.value%TYPE;
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
        l_prob_mechanism      sys_config.value%TYPE;
    
        l_show_surgical_history sys_config.id_sys_config%TYPE;
        l_show_medical_history  sys_config.id_sys_config%TYPE; --Attention: O-Own area/A-All areas        
    
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_ret                  t_table_diag_cnt := t_table_diag_cnt();
        l_ret_problems         t_table_diag_cnt := t_table_diag_cnt();
        l_ret_medical_history  t_table_diag_cnt := t_table_diag_cnt();
        l_ret_surgical_history t_table_diag_cnt := t_table_diag_cnt();
    
        l_tlb_task_types table_number := table_number();
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_GET_COMPLAINT_PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
        l_prob_mechanism      := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
    
        l_show_surgical_history := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
        l_show_medical_history  := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                        i_prof    => l_prof);
    
        g_error := 'GET PREVIOUS PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Obtain the array of id_epis_diagnosis regarding the problems documented in previous episodes
        --(Problems documented via discharge diagnosis)
        IF NOT pk_problems.get_pat_prob_active_diag(i_lang           => l_lang,
                                                    i_prof           => l_prof,
                                                    i_patient        => l_patient,
                                                    i_episode        => l_episode,
                                                    o_epis_diagnosis => l_epis_diagnosis,
                                                    o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL GET_DIAG_FROM_EPIS_DIAG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Obtain the id_diangosis and id_alert_diagnosis for the previously documented problems
        --(These should not be presented on the search list)
        IF NOT pk_diagnosis_core.get_diag_from_epis_diag(i_lang            => l_lang,
                                                         i_prof            => l_prof,
                                                         i_episode         => l_episode,
                                                         i_epis_diagnosis  => l_epis_diagnosis,
                                                         o_diagnosis       => l_diagnosis,
                                                         o_alert_diagnosis => l_alert_diagnosis,
                                                         o_desc_detail     => l_desc_detail,
                                                         o_error           => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL GET_EPIS_ACT_COMPLAINT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        --Obtain the list of complainst for the present episode
        l_id_complaint := pk_complaint.get_epis_act_complaint(i_lang    => l_lang,
                                                              i_prof    => l_prof,
                                                              i_episode => l_episode);
    
        IF l_id_complaint.count() > 0
        THEN
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
               AND l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
               AND l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
            
                l_tlb_task_types.extend();
                l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_problems;
            
                -- validates medical history configuration
                IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
                THEN
                    l_tlb_task_types.extend();
                    l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_medical_history;
                END IF;
            
                -- validates surgical history configuration
                IF l_show_surgical_history = pk_alert_constant.g_yes
                THEN
                    l_tlb_task_types.extend();
                    l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_surgical_history;
                END IF;
            
                l_ret := get_diagnoses_search(i_lang                     => l_lang,
                                              i_prof                     => l_prof,
                                              i_patient                  => l_patient,
                                              i_text_search              => l_text_search,
                                              i_terminologies_task_types => l_tlb_task_types,
                                              i_tbl_term_task_type       => l_tlb_task_types,
                                              i_list_type                => g_diag_list_searchable,
                                              i_tbl_complaint            => l_id_complaint,
                                              i_tbl_adiags_exclude       => l_alert_diagnosis,
                                              i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
            
            ELSE
                IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_ret_problems := get_diagnoses_search(i_lang                     => l_lang,
                                                           i_prof                     => l_prof,
                                                           i_patient                  => l_patient,
                                                           i_text_search              => l_text_search,
                                                           i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                           i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_problems),
                                                           i_list_type                => g_diag_list_searchable,
                                                           i_tbl_complaint            => l_id_complaint,
                                                           i_tbl_adiags_exclude       => l_alert_diagnosis,
                                                           i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
                ELSE
                    l_ret_problems := tf_complaint_problems();
                END IF;
            
                IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
                THEN
                    IF l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                    THEN
                        l_ret_medical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                      i_prof                     => l_prof,
                                                                      i_patient                  => l_patient,
                                                                      i_text_search              => l_text_search,
                                                                      i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                      i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_medical_history),
                                                                      i_list_type                => g_diag_list_searchable,
                                                                      i_tbl_complaint            => l_id_complaint,
                                                                      i_tbl_adiags_exclude       => l_alert_diagnosis,
                                                                      i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
                    ELSE
                        l_ret_medical_history := tf_complaint_past_med();
                    END IF;
                END IF;
            
                IF l_show_surgical_history = pk_alert_constant.g_yes
                THEN
                    IF l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                    THEN
                        l_ret_surgical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                       i_prof                     => l_prof,
                                                                       i_patient                  => l_patient,
                                                                       i_text_search              => l_text_search,
                                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_surgical_history),
                                                                       i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_surgical_history),
                                                                       i_list_type                => g_diag_list_searchable,
                                                                       i_tbl_complaint            => l_id_complaint,
                                                                       i_tbl_adiags_exclude       => l_alert_diagnosis,
                                                                       i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
                    ELSE
                        l_ret_surgical_history := tf_complaint_past_surg();
                    END IF;
                END IF;
            
                SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                      id_diagnosis_parent => t.id_diagnosis_parent,
                                      id_alert_diagnosis  => t.id_alert_diagnosis,
                                      code_icd            => t.code_icd,
                                      id_language         => t.id_language,
                                      code_translation    => t.code_translation,
                                      desc_translation    => t.desc_translation,
                                      desc_epis_diagnosis => t.desc_epis_diagnosis,
                                      flg_other           => t.flg_other,
                                      flg_icd9            => t.flg_icd9,
                                      flg_select          => t.flg_select,
                                      id_dep_clin_serv    => NULL,
                                      flg_terminology     => t.flg_terminology,
                                      rank                => t.rank,
                                      id_term_task_type   => t.id_term_task_type,
                                      flg_show_term_code  => t.flg_show_term_code,
                                      id_epis_diagnosis   => t.id_epis_diagnosis,
                                      flg_status          => NULL,
                                      flg_type            => NULL,
                                      flg_mechanism       => t.flg_mechanism,
                                      id_tvr_msi          => t.id_tvr_msi)
                  BULK COLLECT
                  INTO l_ret
                  FROM (SELECT *
                          FROM TABLE(l_ret_problems)
                        UNION
                        SELECT *
                          FROM TABLE(l_ret_medical_history)
                        UNION
                        SELECT *
                          FROM TABLE(l_ret_surgical_history)) t;
            END IF;
        ELSE
            RETURN l_ret;
        END IF;
    
        RETURN l_ret;
    
    END tf_get_complaint_problems;

    /********************************************************************************************************
    * Gets all the past medical history diagnoses configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_past_medical)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_past_med RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(30 CHAR) := 'TF_COMPLAINT_PAST_MED';
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_sys_config_show_diag sys_config.id_sys_config%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_COMPLAINT_PAST_MED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
        l_sys_config_show_diag := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
        IF l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all
        THEN
            -- only returns medical content if it is configured to show all areas in the problems screens
            RETURN get_past_hist_complain_diags(pk_alert_constant.g_task_medical_history);
        ELSE
            RETURN t_table_diag_cnt();
        END IF;
    END tf_complaint_past_med;

    /********************************************************************************************************
    * Gets all the past surgical history diagnoses configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_past_surgical)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_past_surg RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_COMPLAINT_PAST_SURG';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
        l_sc_show_surgical sys_config.id_sys_config%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_COMPLAINT_PAST_SURG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_sc_show_surgical := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
    
        IF l_sc_show_surgical LIKE pk_alert_constant.g_yes
        THEN
            -- only returns surgical content if it is configured
            RETURN get_past_hist_complain_diags(pk_alert_constant.g_task_surgical_history);
        ELSE
            RETURN t_table_diag_cnt();
        END IF;
    END tf_complaint_past_surg;

    /********************************************************************************************************
    * Gets all the problems diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_problems)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_problems RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_CLIN_SERV_PROBLEMS';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_problems_mechanism sys_config.value%TYPE;
    
        l_flg_show_term_code sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_CLIN_SERV_PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                        i_prof    => l_prof);
    
        l_problems_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
        IF l_problems_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            RETURN get_diagnoses_search(i_lang                     => l_lang,
                                        i_prof                     => l_prof,
                                        i_patient                  => l_patient,
                                        i_text_search              => l_text_search,
                                        i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                        i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_problems),
                                        i_list_type                => g_diag_list_most_freq);
        ELSE
            RETURN pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                             i_prof                     => l_prof,
                                                             i_patient                  => l_patient,
                                                             i_text_search              => l_text_search,
                                                             i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                             i_term_task_type           => pk_alert_constant.g_task_problems,
                                                             i_flg_show_term_code       => l_flg_show_term_code,
                                                             i_list_type                => g_diag_list_most_freq);
        END IF;
    
    END tf_clin_serv_problems;

    FUNCTION tf_get_clin_serv_problems RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_GET_CLIN_SERV_PROBLEMS';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
        l_prob_mechanism      sys_config.value%TYPE;
    
        l_show_surgical_history sys_config.id_sys_config%TYPE;
        l_show_medical_history  sys_config.id_sys_config%TYPE; --Attention: O-Own area/A-All areas       
    
        l_ret                  t_table_diag_cnt := t_table_diag_cnt();
        l_ret_problems         t_table_diag_cnt := t_table_diag_cnt();
        l_ret_medical_history  t_table_diag_cnt := t_table_diag_cnt();
        l_ret_surgical_history t_table_diag_cnt := t_table_diag_cnt();
    
        l_tlb_task_types table_number := table_number();
    
        l_flg_show_term_code sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_GET_CLIN_SERV_PROBLEMS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                        i_prof    => l_prof);
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
        l_prob_mechanism      := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
    
        l_show_surgical_history := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
        l_show_medical_history  := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
    
        IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
           AND l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
           AND l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
        
            l_tlb_task_types.extend();
            l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_problems;
        
            -- validates medical history configuration
            IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
            THEN
                l_tlb_task_types.extend();
                l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_medical_history;
            END IF;
        
            -- validates surgical history configuration
            IF l_show_surgical_history = pk_alert_constant.g_yes
            THEN
                l_tlb_task_types.extend();
                l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_surgical_history;
            END IF;
        
            l_ret := get_diagnoses_search(i_lang                     => l_lang,
                                          i_prof                     => l_prof,
                                          i_patient                  => l_patient,
                                          i_text_search              => l_text_search,
                                          i_terminologies_task_types => l_tlb_task_types,
                                          i_tbl_term_task_type       => l_tlb_task_types,
                                          i_list_type                => g_diag_list_most_freq);
        ELSE
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                l_ret_problems := get_diagnoses_search(i_lang                     => l_lang,
                                                       i_prof                     => l_prof,
                                                       i_patient                  => l_patient,
                                                       i_text_search              => l_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                       i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_problems),
                                                       i_list_type                => g_diag_list_most_freq);
            ELSE
                l_ret_problems := tf_diagnoses_search(i_lang                     => l_lang,
                                                      i_prof                     => l_prof,
                                                      i_patient                  => l_patient,
                                                      i_text_search              => l_text_search,
                                                      i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                      i_term_task_type           => pk_alert_constant.g_task_problems,
                                                      i_flg_show_term_code       => l_flg_show_term_code,
                                                      i_list_type                => g_diag_list_most_freq);
            
            END IF;
        
            IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
            THEN
                IF l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_ret_medical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                  i_prof                     => l_prof,
                                                                  i_patient                  => l_patient,
                                                                  i_text_search              => l_text_search,
                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                  i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_medical_history),
                                                                  i_list_type                => g_diag_list_most_freq);
                ELSE
                    l_ret_medical_history := tf_diagnoses_search(i_lang                     => l_lang,
                                                                 i_prof                     => l_prof,
                                                                 i_patient                  => l_patient,
                                                                 i_text_search              => l_text_search,
                                                                 i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                 i_term_task_type           => pk_alert_constant.g_task_medical_history,
                                                                 i_flg_show_term_code       => l_flg_show_term_code,
                                                                 i_list_type                => g_diag_list_most_freq);
                END IF;
            END IF;
        
            IF l_show_surgical_history = pk_alert_constant.g_yes
            THEN
                IF l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_ret_surgical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                   i_prof                     => l_prof,
                                                                   i_patient                  => l_patient,
                                                                   i_text_search              => l_text_search,
                                                                   i_terminologies_task_types => table_number(pk_alert_constant.g_task_surgical_history),
                                                                   i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_surgical_history),
                                                                   i_list_type                => g_diag_list_most_freq);
                ELSE
                    l_ret_surgical_history := tf_diagnoses_search(i_lang                     => l_lang,
                                                                  i_prof                     => l_prof,
                                                                  i_patient                  => l_patient,
                                                                  i_text_search              => l_text_search,
                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_surgical_history),
                                                                  i_term_task_type           => pk_alert_constant.g_task_surgical_history,
                                                                  i_flg_show_term_code       => l_flg_show_term_code,
                                                                  i_list_type                => g_diag_list_most_freq);
                END IF;
            END IF;
        
            SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                  id_diagnosis_parent => t.id_diagnosis_parent,
                                  id_alert_diagnosis  => t.id_alert_diagnosis,
                                  code_icd            => t.code_icd,
                                  id_language         => t.id_language,
                                  code_translation    => t.code_translation,
                                  desc_translation    => t.desc_translation,
                                  desc_epis_diagnosis => t.desc_epis_diagnosis,
                                  flg_other           => t.flg_other,
                                  flg_icd9            => t.flg_icd9,
                                  flg_select          => t.flg_select,
                                  id_dep_clin_serv    => NULL,
                                  flg_terminology     => t.flg_terminology,
                                  rank                => t.rank,
                                  id_term_task_type   => t.id_term_task_type,
                                  flg_show_term_code  => t.flg_show_term_code,
                                  id_epis_diagnosis   => t.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => t.flg_mechanism,
                                  id_tvr_msi          => t.id_tvr_msi)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT *
                      FROM TABLE(l_ret_problems)
                    UNION ALL
                    SELECT *
                      FROM TABLE(l_ret_medical_history)
                    UNION ALL
                    SELECT *
                      FROM TABLE(l_ret_surgical_history)) t;
        END IF;
    
        RETURN l_ret;
    
    END tf_get_clin_serv_problems;

    /********************************************************************************************************
    * Gets all the past medical history diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_medical)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_past_med RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(30 CHAR) := 'TF_CLIN_SERV_PAST_MED';
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_sys_config_show_diag sys_config.id_sys_config%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_CLIN_SERV_PAST_MED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
        l_sys_config_show_diag := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
        IF l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all
        THEN
            -- only returns medical content if it is configured to show all areas in the problems screens
            RETURN get_past_hist_clin_serv_diags(pk_alert_constant.g_task_medical_history);
        ELSE
            RETURN t_table_diag_cnt();
        END IF;
    END tf_clin_serv_past_med;

    /********************************************************************************************************
    * Gets all the past surgical history diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_surgical)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_past_surg RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_CLIN_SERV_PAST_SURG';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
        l_sc_show_surgical sys_config.id_sys_config%TYPE;
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_CLIN_SERV_PAST_SURG';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_sc_show_surgical := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
    
        IF l_sc_show_surgical LIKE pk_alert_constant.g_yes
        THEN
            -- only returns surgical content if it is configured
            RETURN get_past_hist_clin_serv_diags(pk_alert_constant.g_task_surgical_history);
        ELSE
            RETURN t_table_diag_cnt();
        END IF;
    END tf_clin_serv_past_surg;

    /**************************************************************************************************************************
    * Gets all the diagnoses configured for a task type
    *
    * @param i_task_type                Task type ID to filter content
    * @param i_list_type                Search type (g_diag_list_searchable/g_diag_list_most_freq/g_diag_list_preg_most_freq)
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_surgical)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    **************************************************************************************************************************/
    FUNCTION tf_all_content
    (
        i_task_type IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_problems,
        i_list_type IN VARCHAR2 DEFAULT g_diag_list_searchable
    ) RETURN t_table_diag_cnt IS
        l_func_name            VARCHAR2(30 CHAR) := 'TF_ALL_CONTENT';
        l_ret                  t_table_diag_cnt;
        l_lang                 language.id_language%TYPE;
        l_patient              patient.id_patient%TYPE;
        l_prof                 profissional;
        l_episode              episode.id_episode%TYPE;
        l_text_search          translation.desc_lang_1%TYPE;
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_epis_diag_type       epis_diagnosis.flg_type%TYPE;
        l_sc_show_surgical     sys_config.id_sys_config%TYPE;
        l_sys_config_show_diag sys_config.id_sys_config%TYPE;
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
        l_prob_mechanism      sys_config.value%TYPE;
    
        l_flg_show_term_code sys_config.value%TYPE;
    
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_ALL_CONTENT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        IF i_task_type = pk_alert_constant.g_task_diagnosis
        THEN
            l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                            i_prof    => l_prof);
        
        ELSE
            l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                            i_prof    => l_prof);
        END IF;
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
        l_prob_mechanism      := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
    
        IF i_task_type = pk_alert_constant.g_task_medical_history
        THEN
            -- validates medical history configuration
            l_sys_config_show_diag := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
        
            IF l_sys_config_show_diag NOT LIKE pk_alert_constant.g_diag_area_config_show_all
            THEN
                -- not configured, return null
                RETURN t_table_diag_cnt();
            END IF;
        ELSIF i_task_type = pk_alert_constant.g_task_surgical_history
        THEN
            -- validates surgical history configuration
            l_sc_show_surgical := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
        
            IF l_sc_show_surgical NOT LIKE pk_alert_constant.g_yes
            THEN
                -- not configured, return null
                RETURN t_table_diag_cnt();
            END IF;
        END IF;
    
        IF (i_task_type = pk_alert_constant.g_task_surgical_history AND
           l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (i_task_type = pk_alert_constant.g_task_medical_history AND
           l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
           OR (i_task_type = pk_alert_constant.g_task_problems AND
           l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism)
        THEN
            g_error := 'GET_ALL_CONTENT - CALL GET_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_ret := pk_terminology_search.get_diagnoses_search(i_lang                     => l_lang,
                                                                i_prof                     => l_prof,
                                                                i_patient                  => l_patient,
                                                                i_text_search              => l_text_search,
                                                                i_terminologies_task_types => table_number(i_task_type),
                                                                i_tbl_term_task_type       => table_number(i_task_type),
                                                                i_list_type                => i_list_type,
                                                                i_context_type             => pk_ts_logic.k_ctx_type_s_searchable);
        ELSE
            g_error := 'TF_ALL_CONTENT - CALL TF_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_ret := pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                               i_prof                     => l_prof,
                                                               i_patient                  => l_patient,
                                                               i_text_search              => l_text_search,
                                                               i_terminologies_task_types => table_number(i_task_type),
                                                               i_term_task_type           => i_task_type,
                                                               i_flg_show_term_code       => l_flg_show_term_code,
                                                               i_list_type                => i_list_type,
                                                               i_include_other_diagnosis  => pk_alert_constant.g_yes);
        END IF;
    
        RETURN l_ret;
    
    END tf_all_content;

    /**************************************************************************************************************************
    * Gets all the diagnoses configured for a task type
    *
    * @param i_origin                   Request origin: D-Diagnoses/P-Problems
    * @param i_list_type                Search type (g_diag_list_searchable/g_diag_list_most_freq/g_diag_list_preg_most_freq)
    *
    * @return                           Returns diagnoses list
    *                                   Used in: V_PROBLEMS_ALL_CONTENT
    *
    * @version                          2.8.0.0
    * @since                            Jul-01-2019
    **************************************************************************************************************************/
    FUNCTION tf_get_all_content
    (
        i_origin    IN VARCHAR2,
        i_list_type IN VARCHAR2 DEFAULT g_diag_list_searchable
    ) RETURN t_table_diag_cnt IS
        l_func_name        VARCHAR2(30 CHAR) := 'TF_GET_PROBLEMS_LIST';
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_show_surgical_history sys_config.id_sys_config%TYPE;
        l_show_medical_history  sys_config.id_sys_config%TYPE; --Attention: O-Own area/A-All areas
    
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_tlb_task_types table_number := table_number();
    
        l_surg_hist_mechanism sys_config.value%TYPE;
        l_med_hist_mechanism  sys_config.value%TYPE;
        l_prob_mechanism      sys_config.value%TYPE;
    
        l_ret                  t_table_diag_cnt;
        l_ret_problems         t_table_diag_cnt;
        l_ret_medical_history  t_table_diag_cnt;
        l_ret_surgical_history t_table_diag_cnt;
    
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_ALL_CONTENT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_surg_hist_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism, l_prof);
        l_med_hist_mechanism  := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism, l_prof);
        l_prob_mechanism      := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
    
        l_show_surgical_history := pk_sysconfig.get_config(pk_alert_constant.g_problems_show_surgical_hist, l_prof);
        l_show_medical_history  := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config, l_prof);
    
        --DEFINIR SE ESTAMOS A VIR DOS DIAGNÓSTICOS OU DOS PROBLEMAS (PARAMETRO DE ENTRADA)
        IF i_origin = 'D'
        THEN
            l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                            i_prof    => l_prof);
        ELSE
            l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_problem,
                                                            i_prof    => l_prof);
        END IF;
    
        l_tlb_task_types.extend();
        l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_problems;
    
        IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
           AND l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
           AND l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            -- validates medical history configuration
            IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
            THEN
                l_tlb_task_types.extend();
                l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_medical_history;
            END IF;
        
            -- validates surgical history configuration
            IF l_show_surgical_history = pk_alert_constant.g_yes
            THEN
                l_tlb_task_types.extend();
                l_tlb_task_types(l_tlb_task_types.count) := pk_alert_constant.g_task_surgical_history;
            END IF;
        
            g_error := 'TF_GET_PROBLEMS_LIST - CALL GET_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_ret := get_diagnoses_search(i_lang                     => l_lang,
                                          i_prof                     => l_prof,
                                          i_patient                  => l_patient,
                                          i_text_search              => l_text_search,
                                          i_terminologies_task_types => l_tlb_task_types,
                                          i_tbl_term_task_type       => l_tlb_task_types,
                                          i_list_type                => i_list_type,
                                          i_context_type             => pk_ts_logic.k_ctx_type_s_searchable);
        
            RETURN l_ret;
        
        ELSE
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                l_ret_problems := get_diagnoses_search(i_lang                     => l_lang,
                                                       i_prof                     => l_prof,
                                                       i_patient                  => l_patient,
                                                       i_text_search              => l_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                       i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_problems),
                                                       i_list_type                => i_list_type,
                                                       i_context_type             => pk_ts_logic.k_ctx_type_s_searchable);
            
            ELSE
                l_ret_problems := tf_all_content(pk_alert_constant.g_task_problems);
            END IF;
            --medical history
            IF l_show_medical_history = pk_alert_constant.g_diag_area_config_show_all
            THEN
                IF l_med_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_ret_medical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                  i_prof                     => l_prof,
                                                                  i_patient                  => l_patient,
                                                                  i_text_search              => l_text_search,
                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                  i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_medical_history),
                                                                  i_list_type                => i_list_type,
                                                                  i_context_type             => pk_ts_logic.k_ctx_type_s_searchable);
                ELSE
                    l_ret_medical_history := tf_all_content(pk_alert_constant.g_task_medical_history);
                END IF;
            ELSE
                l_ret_medical_history := t_table_diag_cnt();
            END IF;
            --surgical history                               
            IF l_show_surgical_history = pk_alert_constant.g_yes
            THEN
                IF l_surg_hist_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_ret_surgical_history := get_diagnoses_search(i_lang                     => l_lang,
                                                                   i_prof                     => l_prof,
                                                                   i_patient                  => l_patient,
                                                                   i_text_search              => l_text_search,
                                                                   i_terminologies_task_types => table_number(pk_alert_constant.g_task_surgical_history),
                                                                   i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_surgical_history),
                                                                   i_list_type                => i_list_type,
                                                                   i_context_type             => pk_ts_logic.k_ctx_type_s_searchable);
                
                ELSE
                    l_ret_surgical_history := tf_all_content(pk_alert_constant.g_task_surgical_history);
                END IF;
            ELSE
                l_ret_surgical_history := t_table_diag_cnt();
            END IF;
        END IF;
    
        SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                              id_diagnosis_parent => t.id_diagnosis_parent,
                              id_alert_diagnosis  => t.id_alert_diagnosis,
                              code_icd            => t.code_icd,
                              id_language         => t.id_language,
                              code_translation    => t.code_translation,
                              desc_translation    => t.desc_translation,
                              desc_epis_diagnosis => t.desc_epis_diagnosis,
                              flg_other           => t.flg_other,
                              flg_icd9            => t.flg_icd9,
                              flg_select          => t.flg_select,
                              id_dep_clin_serv    => NULL,
                              flg_terminology     => t.flg_terminology,
                              rank                => t.rank,
                              id_term_task_type   => t.id_term_task_type,
                              flg_show_term_code  => t.flg_show_term_code,
                              id_epis_diagnosis   => t.id_epis_diagnosis,
                              flg_status          => NULL,
                              flg_type            => NULL,
                              flg_mechanism       => t.flg_mechanism,
                              id_tvr_msi          => t.id_tvr_msi)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT *
                  FROM TABLE(l_ret_problems)
                UNION
                SELECT *
                  FROM TABLE(l_ret_medical_history)
                UNION
                SELECT *
                  FROM TABLE(l_ret_surgical_history)) t;
    
        RETURN l_ret;
    
    END tf_get_all_content;

    /***********************************************************************************************
    * Loads diagnoses information to be used in diagnoses listing
    *
    * @param i_lang                           Language identifier
    * @param i_prof                           Professional information
    * @param i_patient                        Patient ID
    * @param i_format_text                    Highlight search text Y/N
    * @param i_terminologies_task_types       Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type                 Area of the application where the term will be shown
    * @param i_list_type                      Type of list to be returned
    * @param i_synonym_list_enable            Enable/disable synonyms result sets
    * @param i_synonym_search_enable          Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis        Include other diagnoses in the result set
    * @param i_tbl_terminologies              Filter by flg_terminology (NULL for all terminologies). This is useful when the user
    *                                           has a multichoice with the available terminologies and can select them
    *
    * @param o_inst                           Return institution
    * @param o_soft                           Return software
    * @param o_pat_age                        Return patient age
    * @param o_pat_gender                     Return patient gender
    * @param o_tbl_flg_terminologies          Return available terminologies
    * @param o_term_task_type                 Return termonilogy task type
    * @param o_flg_type_alert_diagnosis       Return flg_type_alert_diagnosis
    * @param o_flg_type_dep_clin              Return flg_type_dep_clin
    * @param o_synonym_list_enable            Enable/disable synonyms result sets
    * @param o_synonym_search_enable          Enable/disable synonyms in search sets
    * @param o_include_other_diagnosis        Include other diagnoses in the result set
    * @param o_tbl_prof_dep_clin_serv         Return professional dep_clin_serv information
    * @param o_terminologies_lang             Return terminologies language
    * @param o_format_text                    Highlight search text Y/N
    * @param o_validate_max_age               Return if it should validate maximum age
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    PROCEDURE get_diagnoses_default_args
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        o_inst                     OUT institution.id_institution%TYPE,
        o_soft                     OUT software.id_software%TYPE,
        o_pat_age                  OUT NUMBER,
        o_pat_gender               OUT patient.gender%TYPE,
        o_tbl_flg_terminologies    OUT table_varchar,
        o_term_task_type           OUT task_type.id_task_type%TYPE,
        o_flg_type_alert_diagnosis OUT diagnosis_content.flg_type_alert_diagnosis%TYPE,
        o_flg_type_dep_clin        OUT diagnosis_content.flg_type_dep_clin%TYPE,
        o_synonym_list_enable      OUT sys_config.value%TYPE,
        o_synonym_search_enable    OUT sys_config.value%TYPE,
        o_include_other_diagnosis  OUT sys_config.value%TYPE,
        o_tbl_prof_dep_clin_serv   OUT table_number,
        o_terminologies_lang       OUT language.id_language%TYPE,
        o_format_text              OUT VARCHAR2,
        o_validate_max_age         OUT VARCHAR2
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'GET_DIAGNOSES_DEFAULT_ARGS';
        --
        c_years CONSTANT VARCHAR2(30 CHAR) := pk_patient.k_format_age_ynr;
        --
        c_synonym_list_enable     CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSIS_SYNONYMS_LIST_ENABLE';
        c_synonym_search_enable   CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSIS_SYNONYMS_SEARCH_ENABLE';
        c_include_other_diagnosis CONSTANT sys_config.id_sys_config%TYPE := 'PERMISSION_FOR_OTHER_DIAGNOSIS';
        --
        l_terminologies_task_types table_number;
        --
        l_error t_error_out;
    
        l_surg_hist_mechanism sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_surg_hist_search_mechanism,
                                                                               i_prof);
        l_med_hist_mechanism  sys_config.value%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_med_hist_search_mechanism,
                                                                               i_prof);
    
    BEGIN
        <<patient_info>>
        BEGIN
            g_error := 'CALL PK_PATIENT.GET_PAT_AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            o_pat_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                i_dt_birth    => NULL,
                                                i_dt_deceased => NULL,
                                                i_age         => NULL,
                                                i_age_format  => c_years,
                                                i_patient     => i_patient);
        
            g_error := 'CALL PK_PATIENT.GET_PAT_GENDER';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            o_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
        END patient_info;
    
        <<get_terminologies_to_use>>
        BEGIN
            g_error := 'SET TERMINOLOGIES TASK TYPES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_terminologies_task_types.exists(1)
            THEN
                l_terminologies_task_types := i_terminologies_task_types;
            ELSE
                l_terminologies_task_types := table_number(pk_alert_constant.g_task_diagnosis);
            END IF;
        
            IF i_tbl_terminologies.exists(1)
            THEN
                g_error := 'FILTER DIAG/SOFT/TASK_TYPE TERMINOLOGIES BY USER SELECTION';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                SELECT t.flg_terminology
                  BULK COLLECT
                  INTO o_tbl_flg_terminologies
                  FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_tbl_task_type => l_terminologies_task_types)) t
                 WHERE t.flg_terminology IN (SELECT /*+opt_estimate(TABLE, ft, rows = 1)*/
                                              column_value flg_terminology
                                               FROM TABLE(i_tbl_terminologies) ft);
            ELSE
                g_error := 'GET DIAG/SOFT/TASK_TYPE TERMINOLOGIES';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                SELECT /*+opt_estimate(TABLE, ft, rows = 1)*/
                 ft.flg_terminology
                  BULK COLLECT
                  INTO o_tbl_flg_terminologies
                  FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_tbl_task_type => l_terminologies_task_types)) ft;
            END IF;
        
            g_error := 'SET TERMINOLOGY TASK TYPE TERM';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_term_task_type IS NOT NULL
            THEN
                o_term_task_type := i_term_task_type;
            ELSE
                o_term_task_type := pk_alert_constant.g_task_diagnosis;
            END IF;
        
            IF o_tbl_flg_terminologies.exists(1)
            THEN
                g_error := 'GET CONFIGURED TERMINOLOGIES INST/SOFT';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                BEGIN
                    SELECT id_institution, id_software
                      INTO o_inst, o_soft
                      FROM (SELECT c.id_institution,
                                   c.id_software,
                                   row_number() over(ORDER BY decode(c.id_institution, i_prof.institution, 1, 2), decode(c.id_software, i_prof.software, 1, 2)) line_number
                              FROM diagnosis_conf_ea c
                             WHERE c.id_institution IN (i_prof.institution, 0)
                               AND c.id_software IN (i_prof.software, 0)
                               AND c.id_task_type = o_term_task_type)
                     WHERE line_number = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_inst := i_prof.institution;
                        o_soft := i_prof.software;
                END;
            
                g_error := 'SET TERMINOLOGY TERM LANGUAGE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                BEGIN
                    SELECT nvl(decode(t.id_language, 0, i_lang, t.id_language), i_lang)
                      INTO o_terminologies_lang
                      FROM (SELECT DISTINCT dc.id_language
                              FROM diagnosis_conf_ea dc
                             WHERE dc.flg_terminology IN
                                   (SELECT /*+opt_estimate(TABLE, tdgc, rows = 1)*/
                                     column_value flg_terminology
                                      FROM TABLE(o_tbl_flg_terminologies) tdgc)
                               AND dc.id_institution = o_inst
                               AND dc.id_software = o_soft) t
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_terminologies_lang := i_lang;
                END;
            ELSE
                g_error := 'SET TERMINOLOGY TERM LANGUAGE TO APPLICATION LANGUAGE - NO TERMINOLOGIES CONFIGURED';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                o_terminologies_lang := i_lang;
            END IF;
        
            --Current rules are:
            --   . For past history diagnoses, diagnosis_ea is filled with inst and soft equal to 0
            --   . For all the other areas, diagnosis_ea is filled with user inst and soft
            g_error := 'SET INST/SOFT VARS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF (i_term_task_type = pk_alert_constant.g_task_medical_history AND
               l_med_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
               OR (i_term_task_type = pk_alert_constant.g_task_surgical_history AND
               l_surg_hist_mechanism <> pk_alert_constant.g_diag_new_search_mechanism)
            THEN
                o_inst := pk_alert_constant.g_inst_all;
                o_soft := pk_alert_constant.g_soft_all;
            ELSE
                o_inst := i_prof.institution;
                o_soft := i_prof.software;
            END IF;
        END get_terminologies_to_use;
    
        <<get_configurations>>
        BEGIN
            g_error := 'GET SYS_CFG - ' || c_synonym_list_enable;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            -- enable/disable synonyms in search and reply result sets
            IF i_synonym_list_enable IS NOT NULL
            THEN
                o_synonym_list_enable := i_synonym_list_enable;
            ELSE
                o_synonym_list_enable := nvl(pk_sysconfig.get_config(c_synonym_list_enable, i_prof),
                                             pk_alert_constant.g_no);
            END IF;
        
            g_error := 'GET SYS_CFG - ' || c_synonym_search_enable;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            -- include the official diagnoses descriptions if search was done using a synonym
            IF i_synonym_search_enable IS NOT NULL
            THEN
                o_synonym_search_enable := i_synonym_search_enable;
            ELSE
                o_synonym_search_enable := nvl(pk_sysconfig.get_config(c_synonym_search_enable, i_prof),
                                               pk_alert_constant.g_no);
            END IF;
        
            g_error := 'GET SYS_CFG - ' || c_include_other_diagnosis;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            --include other diagnosis
            IF i_include_other_diagnosis IS NOT NULL
            THEN
                o_include_other_diagnosis := i_include_other_diagnosis;
            ELSE
                o_include_other_diagnosis := nvl(pk_sysconfig.get_config(c_include_other_diagnosis, i_prof),
                                                 pk_alert_constant.g_no);
            END IF;
        
            g_error := 'HIGHLIGHT SEARCH TEXT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_format_text IS NOT NULL
            THEN
                o_format_text := i_format_text;
            ELSE
                o_format_text := pk_alert_constant.g_no;
            END IF;
        END get_configurations;
    
        <<type_of_list_to_return>>
        BEGIN
            g_error := 'SET FLG_TYPE_ALERT_DIAGNOSIS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_term_task_type IN (pk_alert_constant.g_task_problems,
                                    pk_alert_constant.g_task_medical_history,
                                    pk_alert_constant.g_task_diagnosis)
            THEN
                o_flg_type_alert_diagnosis := g_medical_diagnosis_type;
            ELSIF i_term_task_type = pk_alert_constant.g_task_surgical_history
            THEN
                o_flg_type_alert_diagnosis := g_surgical_diagnosis_type;
            ELSIF i_term_task_type = pk_alert_constant.g_task_congenital_anomalies
            THEN
                o_flg_type_alert_diagnosis := g_cong_anom_diagnosis_type;
            ELSE
                --Default value
                o_flg_type_alert_diagnosis := g_medical_diagnosis_type;
            END IF;
        
            g_error := 'SET FLG_TYPE_DEP_CLIN';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            CASE i_list_type
                WHEN g_diag_list_searchable THEN
                    IF i_term_task_type IN (pk_alert_constant.g_task_problems,
                                            pk_alert_constant.g_task_diagnosis,
                                            pk_alert_constant.g_task_congenital_anomalies)
                    THEN
                        o_flg_type_dep_clin := g_searchable_diag;
                    ELSIF i_term_task_type IN
                          (pk_alert_constant.g_task_medical_history, pk_alert_constant.g_task_surgical_history)
                    THEN
                        o_flg_type_dep_clin := g_searchable_past_hist;
                    ELSE
                        --Default value
                        o_flg_type_dep_clin := g_searchable_diag;
                    END IF;
                WHEN g_diag_list_most_freq THEN
                    o_flg_type_dep_clin := g_most_freq_diag;
                WHEN g_diag_list_preg_most_freq THEN
                    o_flg_type_dep_clin := g_most_freq_preg;
                ELSE
                    --Defautl value
                    o_flg_type_dep_clin := g_most_freq_diag;
            END CASE;
        END type_of_list_to_return;
    
        <<dep_clin_serv_filters>>
        BEGIN
            g_error := 'SET PROF DEP_CLIN_SERV';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_list_type IN (g_diag_list_most_freq, g_diag_list_preg_most_freq)
            THEN
                g_error := 'CALL PK_PROF_UTILS.GET_PROF_DCS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                --IF THE USER HAS A PREFERRED DCS USED IT
                o_tbl_prof_dep_clin_serv := table_number(pk_prof_utils.get_prof_dcs(i_prof => i_prof));
            
                --IF IT DOESN'T HAVE THEN GET ALL SELECTED DCS
                IF NOT o_tbl_prof_dep_clin_serv.exists(1)
                THEN
                    g_error := 'CALL PK_PROF_UTILS.GET_LIST_PROF_DEP_CLIN_SERV';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                    o_tbl_prof_dep_clin_serv := pk_prof_utils.get_list_prof_dep_clin_serv(i_lang  => i_lang,
                                                                                          i_prof  => i_prof,
                                                                                          o_error => l_error);
                END IF;
            ELSE
                o_tbl_prof_dep_clin_serv := NULL;
            END IF;
        END dep_clin_serv_filters;
    
        <<max_age_validation>>
        BEGIN
            g_error := 'IS TO VALIDATE MAXIMUM AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_term_task_type IN
               (pk_alert_constant.g_task_medical_history, pk_alert_constant.g_task_surgical_history)
            THEN
                o_validate_max_age := pk_alert_constant.g_no;
            ELSE
                o_validate_max_age := pk_alert_constant.g_yes;
            END IF;
        END max_age_validation;
    END get_diagnoses_default_args;

    PROCEDURE get_diagnoses_default_args_new
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_tbl_term_task_type       IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        o_inst                     OUT institution.id_institution%TYPE,
        o_soft                     OUT software.id_software%TYPE,
        o_pat_age                  OUT NUMBER,
        o_pat_gender               OUT patient.gender%TYPE,
        o_tbl_flg_terminologies    OUT table_varchar,
        o_flg_type_dep_clin        OUT diagnosis_content.flg_type_dep_clin%TYPE,
        o_tbl_prof_dep_clin_serv   OUT table_number,
        o_format_text              OUT VARCHAR2,
        o_validate_max_age         OUT VARCHAR2
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'GET_DIAGNOSES_DEFAULT_ARGS_NEW';
        --
        c_years CONSTANT VARCHAR2(30 CHAR) := pk_patient.k_format_age_ynr;
        --
        l_terminologies_task_types table_number;
        --
        l_error t_error_out;
    
    BEGIN
        <<patient_info>>
        BEGIN
            g_error := 'CALL PK_PATIENT.GET_PAT_AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            o_pat_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                                i_dt_birth    => NULL,
                                                i_dt_deceased => NULL,
                                                i_age         => NULL,
                                                i_age_format  => c_years,
                                                i_patient     => i_patient);
        
            g_error := 'CALL PK_PATIENT.GET_PAT_GENDER';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            o_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
        END patient_info;
    
        <<get_terminologies_to_use>>
        BEGIN
            g_error := 'SET TERMINOLOGIES TASK TYPES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_terminologies_task_types.exists(1)
            THEN
                l_terminologies_task_types := i_terminologies_task_types;
            ELSE
                l_terminologies_task_types := table_number(pk_alert_constant.g_task_diagnosis);
            END IF;
        
            IF i_tbl_terminologies.exists(1)
            THEN
                g_error := 'FILTER DIAG/SOFT/TASK_TYPE TERMINOLOGIES BY USER SELECTION';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                SELECT t.flg_terminology
                  BULK COLLECT
                  INTO o_tbl_flg_terminologies
                  FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_tbl_task_type => l_terminologies_task_types)) t
                 WHERE t.flg_terminology IN (SELECT /*+opt_estimate(TABLE, ft, rows = 1)*/
                                              column_value flg_terminology
                                               FROM TABLE(i_tbl_terminologies) ft);
            ELSE
                g_error := 'GET DIAG/SOFT/TASK_TYPE TERMINOLOGIES';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                SELECT /*+opt_estimate(TABLE, ft, rows = 1)*/
                 ft.flg_terminology
                  BULK COLLECT
                  INTO o_tbl_flg_terminologies
                  FROM TABLE(pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                     i_prof          => i_prof,
                                                                     i_tbl_task_type => l_terminologies_task_types)) ft;
            END IF;
        
            g_error := 'SET INST/SOFT VARS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            o_inst := i_prof.institution;
            o_soft := i_prof.software;
        END get_terminologies_to_use;
    
        <<get_configurations>>
        BEGIN
            g_error := 'HIGHLIGHT SEARCH TEXT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_format_text IS NOT NULL
            THEN
                o_format_text := i_format_text;
            ELSE
                o_format_text := pk_alert_constant.g_no;
            END IF;
        END get_configurations;
    
        <<type_of_list_to_return>>
        BEGIN
            g_error := 'SET FLG_TYPE_DEP_CLIN';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            /*            CASE i_list_type
                WHEN g_diag_list_searchable THEN
                    IF i_term_task_type IN (pk_alert_constant.g_task_problems,
                                            pk_alert_constant.g_task_diagnosis,
                                            pk_alert_constant.g_task_congenital_anomalies)
                    THEN
                        o_flg_type_dep_clin := g_searchable_diag;
                    ELSIF i_term_task_type IN
                          (pk_alert_constant.g_task_medical_history, pk_alert_constant.g_task_surgical_history)
                    THEN
                        o_flg_type_dep_clin := g_searchable_past_hist;
                    ELSE
                        --Default value
                        o_flg_type_dep_clin := g_searchable_diag;
                    END IF;
                WHEN g_diag_list_most_freq THEN
                    o_flg_type_dep_clin := g_most_freq_diag;
                WHEN g_diag_list_preg_most_freq THEN
                    o_flg_type_dep_clin := g_most_freq_preg;
                ELSE
                    --Defautl value
                    o_flg_type_dep_clin := g_most_freq_diag;
            END CASE;*/
        END type_of_list_to_return;
    
        <<dep_clin_serv_filters>>
        BEGIN
            g_error := 'SET PROF DEP_CLIN_SERV';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_list_type IN (g_diag_list_most_freq, g_diag_list_preg_most_freq)
            THEN
                g_error := 'CALL PK_PROF_UTILS.GET_PROF_DCS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                --IF THE USER HAS A PREFERRED DCS USED IT
                o_tbl_prof_dep_clin_serv := table_number(pk_prof_utils.get_prof_dcs(i_prof => i_prof));
            
                --IF IT DOESN'T HAVE THEN GET ALL SELECTED DCS
                IF NOT o_tbl_prof_dep_clin_serv.exists(1)
                THEN
                    g_error := 'CALL PK_PROF_UTILS.GET_LIST_PROF_DEP_CLIN_SERV';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                    o_tbl_prof_dep_clin_serv := pk_prof_utils.get_list_prof_dep_clin_serv(i_lang  => i_lang,
                                                                                          i_prof  => i_prof,
                                                                                          o_error => l_error);
                END IF;
            ELSE
                o_tbl_prof_dep_clin_serv := NULL;
            END IF;
        END dep_clin_serv_filters;
    
        /*        <<max_age_validation>>
        BEGIN
            g_error := 'IS TO VALIDATE MAXIMUM AGE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            IF i_term_task_type IN
               (pk_alert_constant.g_task_medical_history, pk_alert_constant.g_task_surgical_history)
            THEN
                o_validate_max_age := pk_alert_constant.g_no;
            ELSE
                o_validate_max_age := pk_alert_constant.g_yes;
            END IF;
        END max_age_validation;*/
    END get_diagnoses_default_args_new;

    /***********************************************************************************************
    * Sets context information to be used later in content queries
    *
    * @param i_institution                   Institution ID
    * @param i_software                      Software ID
    * @param i_pat_age                       Patient age
    * @param i_pat_gender                    Patient gender
    * @param i_term_task_type                Terminology task type
    * @param i_flg_type_alert_diagnosis      Alert diagnosis flag type
    * @param i_flg_type_dep_clin             msi_concept_term flag
    * @param i_synonym_list_enable           Enable/disable synonyms result sets
    * @param i_include_other_diagnosis       Include other diagnoses in the result set
    * @param i_only_other_diags              Include only other diagnoses in the result set
    * @param i_tbl_dep_clin_serv             dep_clin_serv IDs table
    * @param i_tbl_diagnosis                 Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis           Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_row_limit                     Limit the number of rows returned (NULL return all)
    * @param i_parent_diagnosis              Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt       Return only diagnoses filtered by i_parent_diagnosis
    * @param i_validate_max_age              Indicates if the query should validate maximum age
    * @param i_terminologies_lang            Terminology language
    * @param i_text_search                   Search string used by the user
    * @param i_format_text                   Highlight search text Y/N
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    PROCEDURE set_diag_search_args
    (
        i_institution              IN institution.id_institution%TYPE,
        i_software                 IN software.id_software%TYPE,
        i_pat_age                  IN NUMBER, --patient.age%TYPE,
        i_pat_gender               IN patient.gender%TYPE,
        i_term_task_type           IN task_type.id_task_type%TYPE,
        i_flg_type_alert_diagnosis IN diagnosis_content.flg_type_alert_diagnosis%TYPE,
        i_flg_type_dep_clin        IN diagnosis_content.flg_type_dep_clin%TYPE,
        i_synonym_list_enable      IN sys_config.value%TYPE,
        i_include_other_diagnosis  IN sys_config.value%TYPE,
        i_only_other_diags         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_dep_clin_serv        IN table_number,
        i_tbl_diagnosis            IN table_number,
        i_tbl_alert_diagnosis      IN table_number,
        i_row_limit                IN NUMBER,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE,
        i_only_diag_filter_by_prt  IN VARCHAR2,
        i_validate_max_age         IN VARCHAR2,
        i_terminologies_lang       IN language.id_language%TYPE,
        i_text_search              IN VARCHAR2,
        i_format_text              IN VARCHAR2,
        i_language                 IN language.id_language%TYPE DEFAULT NULL
    ) IS
        l_func_name VARCHAR2(30 CHAR) := 'SET_DIAG_SEARCH_ARGS';
    BEGIN
        g_error := 'SET_DIAG_SEARCH_ARGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        pk_context_api.set_parameter(pk_diagnosis_core.g_institution, i_institution);
        pk_context_api.set_parameter(pk_diagnosis_core.g_software, i_software);
        pk_context_api.set_parameter(pk_diagnosis_core.g_pat_age, i_pat_age);
        pk_context_api.set_parameter(pk_diagnosis_core.g_pat_gender, i_pat_gender);
        pk_context_api.set_parameter(pk_diagnosis_core.g_term_task_type, i_term_task_type);
        pk_context_api.set_parameter(pk_diagnosis_core.g_flg_type_alert_diagnosis, i_flg_type_alert_diagnosis);
        pk_context_api.set_parameter(pk_diagnosis_core.g_flg_type_dep_clin, i_flg_type_dep_clin);
        pk_context_api.set_parameter(pk_diagnosis_core.g_synonym_list_enable, i_synonym_list_enable);
        pk_context_api.set_parameter(pk_diagnosis_core.g_include_other_diagnosis, i_include_other_diagnosis);
        pk_context_api.set_parameter(pk_diagnosis_core.g_only_other_diags, i_only_other_diags);
        pk_context_api.set_parameter(pk_diagnosis_core.g_row_limit, i_row_limit);
        pk_context_api.set_parameter(pk_diagnosis_core.g_parent_diagnosis, i_parent_diagnosis);
        pk_context_api.set_parameter(pk_diagnosis_core.g_only_diag_filter_by_prt, i_only_diag_filter_by_prt);
        pk_context_api.set_parameter(pk_diagnosis_core.g_validate_max_age, i_validate_max_age);
        pk_context_api.set_parameter(pk_diagnosis_core.g_terminologies_lang, i_terminologies_lang);
        pk_context_api.set_parameter(pk_diagnosis_core.g_text_search, i_text_search);
        pk_context_api.set_parameter(pk_diagnosis_core.g_format_text, i_format_text);
    
        pk_context_api.set_parameter(pk_diagnosis_core.g_tbl_dcs_has_rows,
                                     sys.diutil.bool_to_int(i_tbl_dep_clin_serv.exists(1)));
        pk_context_api.set_parameter(pk_diagnosis_core.g_tbl_diag_has_rows,
                                     sys.diutil.bool_to_int(i_tbl_diagnosis.exists(1)));
        pk_context_api.set_parameter(pk_diagnosis_core.g_tbl_adiag_has_rows,
                                     sys.diutil.bool_to_int(i_tbl_alert_diagnosis.exists(1)));
        pk_context_api.set_parameter(pk_diagnosis_core.g_language, i_language);
    END set_diag_search_args;

    /***********************************************************************************************
    * Returns diagnoses table
    *
    * @param i_tbl_diagnosis            Diagnoses ID table
    * @param i_tbl_alert_diagnosis      Alert diagnoses ID table
    * @param i_tbl_terminologies        Terminologies table
    * @param i_tbl_dep_clin_serv        Dep_clin_serv table
    *
    * @return                           Diagnoses table
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    FUNCTION tf_diagnoses_cnt
    (
        i_tbl_diagnosis       IN table_number,
        i_tbl_alert_diagnosis IN table_number,
        i_tbl_terminologies   IN table_varchar,
        i_tbl_dep_clin_serv   IN table_number
    ) RETURN t_table_diag_cnt IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_DIAGNOSES_CNT';
        --
        l_without_text_search_type CONSTANT VARCHAR2(1 CHAR) := 'N';
        l_tf_description_type      CONSTANT VARCHAR2(1 CHAR) := 'D';
        l_tf_code_type             CONSTANT VARCHAR2(1 CHAR) := 'C';
        --
        l_sql         CLOB;
        l_text_search pk_translation.t_desc_translation;
        --
        l_ret t_table_diag_cnt;
        --                 
        FUNCTION get_main_content_sql(i_search_type IN VARCHAR2) RETURN CLOB IS
            l_ret CLOB;
        BEGIN
        
            l_ret := 'SELECT a.id_diagnosis,
                             a.id_diagnosis_parent,
                             a.id_alert_diagnosis,
                             a.code_icd,
                             decode(a.id_language, 0, :i_terminologies_lang, a.id_language) id_language,
                             a.code_translation,
                             a.desc_translation,
                             a.flg_other,
                             a.flg_icd9,
                             a.flg_select,
                             a.id_dep_clin_serv,
                             a.flg_terminology,
                             a.rank,
                             NULL id_term_task_type,
                             NULL flg_show_term_code,
                             NULL id_epis_diagnosis,
                             NULL flg_status,
                             NULL flg_type ';
        
            IF i_search_type = l_tf_description_type
            THEN
                l_ret := l_ret || --
                         'FROM (SELECT /*+opt_estimate(TABLE, tf, rows = 10) */ d.id_concept_version id_diagnosis, ';
            ELSE
                l_ret := l_ret || --
                         'FROM (SELECT d.id_concept_version id_diagnosis, ';
            END IF;
        
            l_ret := l_ret || --
                     ' CAST((SELECT id_concept_version_2
                               FROM diagnosis_relations_ea dr
                              WHERE dr.cncpt_rel_type_int_name = ''IS_A''
                                AND dr.concept_type_int_name1 = dr.concept_type_int_name2
                                AND dr.id_concept_version_1 = d.id_concept_version
                                AND dr.id_institution = d.id_institution
                                AND dr.id_software = d.id_software) AS NUMBER(24)) id_diagnosis_parent,
                       d.id_concept_term id_alert_diagnosis,
                       d.concept_code code_icd,
                       d.id_language,
                       decode(sys_context(''ALERT_CONTEXT'', ''TERM_TASK_TYPE''),
                              60,
                              d.code_problems,
                              62,
                              d.code_medical,
                              61,
                              d.code_surgical,
                              64,
                              d.code_cong_anomalies,
                              d.code_diagnosis) code_translation, ';
        
            IF i_search_type = l_tf_description_type
            THEN
                l_ret := l_ret || '                  tf.desc_translation desc_translation, ';
            ELSE
                l_ret := l_ret || '                  NULL desc_translation, ';
            END IF;
        
            l_ret := l_ret || --
                     ' d.flg_other,
                       d.flg_icd9,
                       d.flg_select,
                       d.id_dep_clin_serv,
                       d.flg_terminology,
                       d.gender,
                       d.age_min,
                       d.age_max, ';
        
            IF i_search_type != l_without_text_search_type --WITH TEXT
            THEN
                l_ret := l_ret || --
                         '                  tf.position rank ';
            ELSE
                l_ret := l_ret || --
                         '                  decode(d.rank, 0, 999999999, d.rank) rank ';
            END IF;
        
            l_ret := l_ret || --
                     ' FROM diagnosis_ea d ';
        
            IF i_search_type = l_tf_description_type
            THEN
                l_ret := l_ret || --
                         '  JOIN TABLE(pk_translation.get_search_translation(i_lang => :i_terminologies_lang, i_search => :i_text_search, i_column_name => :i_code_column_name, i_highlight => :i_format_text)) tf ' || --
                         '    ON tf.code_translation = decode(sys_context(''ALERT_CONTEXT'', ''TERM_TASK_TYPE''),
                                                              60,
                                                              d.code_problems,
                                                              62,
                                                              d.code_medical,
                                                              61,
                                                              d.code_surgical,
                                                              64,
                                                              d.code_cong_anomalies,
                                                              d.code_diagnosis) ';
            ELSIF i_search_type = l_tf_code_type
            THEN
                l_ret := l_ret || --
                         '  JOIN (SELECT /*+ opt_estimate(table c rows=1) */ cv.id_concept_version, c.position ' || --
                         '          FROM TABLE(pk_api_termin_server_func.get_search_concept_code(i_lang => :i_terminologies_lang, i_search => :i_text_search)) c ' || --
                         '          JOIN concept_version cv ' || --
                         '            ON cv.id_concept = c.id_concept) tf ' || --
                         '    ON tf.id_concept_version = d.id_concept_version ';
            END IF;
        
            l_ret := l_ret || --
                     ' WHERE rownum > 0 --DUMMY CONDITION IN ORDER TO PREVENT PERFORMANCE ISSUES
                         AND d.flg_is_diagnosis = ''Y''
                             --Content for the current inst., soft. and area
                         AND d.id_institution = sys_context(''ALERT_CONTEXT'', ''INSTITUTION'')
                         AND d.id_software = sys_context(''ALERT_CONTEXT'', ''SOFTWARE'')
                         AND d.flg_terminology IN (SELECT /*+ opt_estimate(table t rows=2) */ * FROM TABLE(SELECT tbl_terminologies FROM params) t )
                         #DEP_CLIN_SERV
                         #DIAGNOSIS
                         #ALERT_DIAGNOSIS
                         AND d.flg_diag_type = sys_context(''ALERT_CONTEXT'', ''FLG_TYPE_ALERT_DIAGNOSIS'')
                         AND d.flg_msi_concept_term = sys_context(''ALERT_CONTEXT'', ''FLG_TYPE_DEP_CLIN'')) a
                  WHERE ((nvl(sys_context(''ALERT_CONTEXT'', ''ONLY_DIAG_FILTER_BY_PRT''), ''N'') = ''N'' AND a.flg_select = ''Y'') OR
                        (sys_context(''ALERT_CONTEXT'', ''ONLY_DIAG_FILTER_BY_PRT'') = ''Y''))
                    AND (sys_context(''ALERT_CONTEXT'', ''SYNONYM_LIST_ENABLE'') = ''Y'' OR a.flg_icd9 = ''Y'')
                    AND ((sys_context(''ALERT_CONTEXT'', ''INCLUDE_OTHER_DIAGNOSIS'') = ''Y'') OR
                        (sys_context(''ALERT_CONTEXT'', ''INCLUDE_OTHER_DIAGNOSIS'') = ''N'' AND a.flg_other != ''Y''))
                    AND (sys_context(''ALERT_CONTEXT'', ''ONLY_OTHER_DIAGS'') = ''N'' OR
                        (sys_context(''ALERT_CONTEXT'', ''ONLY_OTHER_DIAGS'') = ''Y'' AND a.flg_other = ''Y''))
                        --DIAGNOSES AGE AND GENDER FILTERS
                    AND ((sys_context(''ALERT_CONTEXT'', ''PAT_GENDER'') IS NOT NULL AND
                        nvl(a.gender, ''I'') IN (''I'', sys_context(''ALERT_CONTEXT'', ''PAT_GENDER''))) OR
                        sys_context(''ALERT_CONTEXT'', ''PAT_GENDER'') IS NULL OR
                        sys_context(''ALERT_CONTEXT'', ''PAT_GENDER'') IN (''I'', ''U'', ''N''))
                    AND ((sys_context(''ALERT_CONTEXT'', ''VALIDATE_MAX_AGE'') = ''Y'' AND
                        nvl(sys_context(''ALERT_CONTEXT'', ''PAT_AGE''), 0) BETWEEN nvl(a.age_min, 0) AND
                        nvl(a.age_max, nvl(sys_context(''ALERT_CONTEXT'', ''PAT_AGE''), 0))) OR
                        (sys_context(''ALERT_CONTEXT'', ''VALIDATE_MAX_AGE'') = ''N'' AND
                        nvl(sys_context(''ALERT_CONTEXT'', ''PAT_AGE''), 0) >= nvl(a.age_min, 0)) OR
                        nvl(sys_context(''ALERT_CONTEXT'', ''PAT_AGE''), 0) = 0)
                        --AVAILABLITITY OF THE DESCRIPTION FILTER
                    AND a.code_translation IS NOT NULL
                    --
                    AND ((nvl(sys_context(''ALERT_CONTEXT'', ''ONLY_DIAG_FILTER_BY_PRT''), ''N'') = ''N'' AND
                        nvl(a.id_diagnosis_parent, 0) =
                        nvl(sys_context(''ALERT_CONTEXT'', ''PARENT_DIAGNOSIS''), nvl(a.id_diagnosis_parent, 0))) --
                        OR (sys_context(''ALERT_CONTEXT'', ''ONLY_DIAG_FILTER_BY_PRT'') = ''Y'' AND
                        nvl(a.id_diagnosis_parent, 0) = nvl(sys_context(''ALERT_CONTEXT'', ''PARENT_DIAGNOSIS''), 0)))';
        
            RETURN l_ret;
        END get_main_content_sql;
    
        FUNCTION get_query(i_search_type IN VARCHAR2) RETURN CLOB IS
            l_ret CLOB;
        BEGIN
            g_error := 'SELECT PK_TERMINOLOGY_SEARCH.TF_TERMINOLOGIES_CONTENT_TBL';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_ret := get_main_content_sql(i_search_type => i_search_type);
        
            IF i_tbl_dep_clin_serv.exists(1)
               AND sys_context('ALERT_CONTEXT', 'FLG_TYPE_DEP_CLIN') IN (g_most_freq_diag, g_most_freq_preg)
            THEN
                g_error := 'ADD FILTER ID_DEP_CLIN_SERV IN TBL_DEP_CLIN_SERV';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret,
                                      p_what => '#DEP_CLIN_SERV',
                                      p_with => 'AND d.id_dep_clin_serv IN (SELECT /*+ opt_estimate(table t1 rows=1)  */ * FROM TABLE(SELECT tbl_dep_clin_serv FROM params) t1)');
            ELSE
                g_error := 'CLEAR #DEP_CLIN_SERV';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret, p_what => '#DEP_CLIN_SERV', p_with => ' ');
            END IF;
        
            IF i_tbl_diagnosis.exists(1)
            THEN
                g_error := 'ADD FILTER ID_DIAGNOSIS IN TBL_DIAGNOSIS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret,
                                      p_what => '#DIAGNOSIS',
                                      p_with => 'AND d.id_concept_version IN (SELECT /*+ opt_estimate(table t2 rows=1)  */* FROM TABLE(SELECT tbl_diagnosis FROM params) t2)');
            ELSE
                g_error := 'CLEAR #DIAGNOSIS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret, p_what => '#DIAGNOSIS', p_with => ' ');
            END IF;
        
            IF i_tbl_alert_diagnosis.exists(1)
            THEN
                g_error := 'ADD FILTER ID_ALERT_DIAGNOSIS IN TBL_ALERT_DIAGNOSIS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret,
                                      p_what => '#ALERT_DIAGNOSIS',
                                      p_with => 'AND d.id_concept_term IN (SELECT /*+ opt_estimate(table t3 rows=1)  */* FROM TABLE(SELECT tbl_alert_diagnosis FROM params) t3)');
            ELSE
                g_error := 'CLEAR #ALERT_DIAGNOSIS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_ret := replace_clob(p_clob => l_ret, p_what => '#ALERT_DIAGNOSIS', p_with => ' ');
            
            END IF;
            RETURN l_ret;
        END get_query;
    BEGIN
        g_error := 'GET TEXT_SEARCH CONTEXT VAR';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_text_search := sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_text_search);
    
        l_sql := ' WITH params AS (SELECT :tbl_dep_clin_serv tbl_dep_clin_serv, :tbl_diagnosis tbl_diagnosis, :tbl_alert_diagnosis tbl_alert_diagnosis, :tbl_terminologies tbl_terminologies FROM dual) ' || --
                 ' SELECT /*+opt_param(''_optimizer_use_feedback'',''false'')*/ ' || --
                 '       t_rec_diag_cnt(id_diagnosis        => c.id_diagnosis, ' || --
                 '                      id_diagnosis_parent => c.id_diagnosis_parent, ' || --
                 '                      id_alert_diagnosis  => c.id_alert_diagnosis, ' || --
                 '                      code_icd            => c.code_icd, ' || --
                 '                      id_language         => c.id_language, ' ||
                 '                      code_translation    => c.code_translation, ' || --
                 '                      desc_translation    => c.desc_translation, ' || --
                 '                      desc_epis_diagnosis => NULL, ' || --
                 '                      flg_other           => c.flg_other, ' || --
                 '                      flg_icd9            => c.flg_icd9, ' || --
                 '                      flg_select          => c.flg_select, ' || --
                 '                      id_dep_clin_serv    => c.id_dep_clin_serv, ' || --
                 '                      flg_terminology     => c.flg_terminology, ' || --
                 '                      id_term_task_type   => NULL, ' || --
                 '                      flg_show_term_code  => NULL, ' || --
                 '                      rank                => c.rank, ' || --
                 '                      id_epis_diagnosis   => NULL, ' || --
                 '                      flg_status          => NULL, ' || --
                 '                      flg_type            => NULL,
                                        flg_mechanism       => NULL) ' || --
                 ' FROM (';
    
        IF l_text_search IS NULL
        THEN
            l_sql := l_sql || --
                     get_query(i_search_type => l_without_text_search_type);
        ELSE
            l_sql := l_sql || --
                     get_query(i_search_type => l_tf_description_type) || chr(13) || --
                     'UNION' || chr(13) || --
                     get_query(i_search_type => l_tf_code_type);
        END IF;
    
        l_sql := l_sql || --
                 ') c'; --DUMMY CONDITION IN ORDER TO PREVENT PERFORMANCE ISSUES
    
        g_error := 'GENERATED SQL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        pk_alertlog.log_debug(text => l_sql, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_text_search IS NOT NULL
        THEN
            pk_alertlog.log_debug(text            => to_clob('GENERATED SQL: ' || l_sql),
                                  object_name     => g_package,
                                  sub_object_name => l_func_name);
            EXECUTE IMMEDIATE l_sql BULK COLLECT
                INTO l_ret
                USING i_tbl_dep_clin_serv, --
            i_tbl_diagnosis, --
            i_tbl_alert_diagnosis, --
            i_tbl_terminologies, --
            sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_terminologies_lang), --
            sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_terminologies_lang), --
            l_text_search, --
            pk_diagnosis.g_code_column_name, --
            sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_format_text), sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_terminologies_lang), --
            sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_terminologies_lang), --
            l_text_search;
        ELSE
            pk_alertlog.log_debug(text            => to_clob('GENERATED SQL: ' || l_sql),
                                  object_name     => g_package,
                                  sub_object_name => l_func_name);
            EXECUTE IMMEDIATE l_sql BULK COLLECT
                INTO l_ret
                USING i_tbl_dep_clin_serv, --
            i_tbl_diagnosis, --
            i_tbl_alert_diagnosis, --
            i_tbl_terminologies, --
            sys_context('ALERT_CONTEXT', pk_diagnosis_core.g_terminologies_lang);
        END IF;
        RETURN l_ret;
    END tf_diagnoses_cnt;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                     language identifier
    * @param i_prof                     logged professional structure
    * @param i_patient                  patient ID
    * @param i_text_search              search input
    * @param i_format_text              Apply styles to diagnoses names? Y/N
    * @param i_terminologies_task_types Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type           Area of the application where the term will be shown
    * @param i_flg_show_term_code       Is to concatenate the terminology code to the diagnosis description
    * @param i_list_type                Type of list to be returned
    * @param i_synonym_list_enable      Enable/disable synonyms in result sets
    * @param i_synonym_search_enable    Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis  Include other diagnoses in result sets
    * @param i_tbl_diagnosis            Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis      Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_terminologies        Filter by flg_terminology (NULL for all terminologies). This is useful when the user
    *                                   has a multichoice with the available terminologies and can select them
    * @param i_row_limit                Limit the number of rows returned (NULL return all)
    * @param i_parent_diagnosis         Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt  Return only diagnoses filtered by i_parent_diagnosis
    *
    * @values i_list_type               S - Searchable diagnoses list
    *                                   F - Most frequent diagnoses list
    *                                   G - Pregnancy most frequent diagnoses list
    *
    * @return                           Diagnoses searchable table
    *
    * @author                           Alexandre Santos
    * @version                          2.6.3
    * @since                            2013/11/08
    **********************************************************************************************/
    FUNCTION tf_diagnoses_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_flg_show_term_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_diagnosis            IN table_number DEFAULT NULL,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_diag_cnt IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_DIAGNOSES_SEARCH';
        --
        l_code_msg_txt CONSTANT sys_message.code_message%TYPE := 'COMMON_M136';
        l_desc_msg_txt sys_message.desc_message%TYPE;
        --
        l_tbl_diagnoses     t_table_diag_cnt;
        l_tbl_search_result t_table_diag_cnt;
        l_tbl_synonyms      t_table_diag_cnt;
        l_tbl_aux_synonyms  t_table_diag_cnt;
        l_tbl_other_diag    t_table_diag_cnt;
        --
        l_pat_age    NUMBER;
        l_pat_gender patient.gender%TYPE;
        --
        l_tbl_flg_terminologies table_varchar;
        l_terminologies_lang    language.id_language%TYPE;
        l_inst                  institution.id_institution%TYPE;
        l_soft                  software.id_software%TYPE;
        l_term_task_type        task_type.id_task_type%TYPE;
        --
        l_synonym_list_enable     sys_config.value%TYPE;
        l_synonym_search_enable   sys_config.value%TYPE;
        l_include_other_diagnosis sys_config.value%TYPE;
        --
        l_format_text VARCHAR2(1 CHAR);
        --
        l_flg_type_alert_diagnosis diagnosis_content.flg_type_alert_diagnosis%TYPE;
        l_flg_type_dep_clin        diagnosis_content.flg_type_dep_clin%TYPE;
        --
        l_tbl_aux_diag table_number;
        --
        l_tbl_prof_dep_clin_serv table_number;
        --
        l_validate_max_age VARCHAR2(1 CHAR);
        --
        l_row_limit NUMBER;
        --      
        --This function encapsulates the logic of querying data with or without limit
        --If we have a limit we need to obtain translations for each record and then order the data, this process is much slower
        FUNCTION tf_aux_limit(i_limit IN NUMBER) RETURN t_table_diag_cnt IS
            l_inner_func_name CONSTANT VARCHAR2(32) := 'TF_AUX_LIMIT';
            --
            l_tbl_aux t_table_diag_cnt;
        BEGIN
            IF i_limit IS NULL
            THEN
                g_error := 'QUERY DATA WITHOUT LIMIT - DATA ISN''T ORDERED';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_func_name);
                SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                                      id_diagnosis_parent => id_diagnosis_parent,
                                      id_alert_diagnosis  => id_alert_diagnosis,
                                      code_icd            => code_icd,
                                      id_language         => id_language,
                                      code_translation    => code_translation,
                                      desc_translation    => desc_translation,
                                      desc_epis_diagnosis => NULL,
                                      flg_other           => flg_other,
                                      flg_icd9            => flg_icd9,
                                      flg_select          => flg_select,
                                      id_dep_clin_serv    => id_dep_clin_serv,
                                      flg_terminology     => flg_terminology,
                                      rank                => rank,
                                      id_term_task_type   => l_term_task_type,
                                      flg_show_term_code  => i_flg_show_term_code,
                                      id_epis_diagnosis   => id_epis_diagnosis,
                                      flg_status          => NULL,
                                      flg_type            => NULL,
                                      flg_mechanism       => pk_alert_constant.g_diag_old_search_mechanism)
                  BULK COLLECT
                  INTO l_tbl_aux
                  FROM (SELECT /*+opt_estimate(TABLE, dc, rows = 100)*/
                         dc.id_diagnosis,
                         dc.id_diagnosis_parent,
                         dc.id_alert_diagnosis,
                         dc.code_icd,
                         dc.id_language,
                         dc.code_translation,
                         dc.desc_translation,
                         dc.flg_other,
                         dc.flg_icd9,
                         dc.flg_select,
                         dc.id_dep_clin_serv,
                         dc.flg_terminology,
                         dc.rank,
                         dc.id_epis_diagnosis
                          FROM TABLE(pk_terminology_search.tf_diagnoses_cnt(i_tbl_diagnosis       => i_tbl_diagnosis,
                                                                            i_tbl_alert_diagnosis => i_tbl_alert_diagnosis,
                                                                            i_tbl_terminologies   => l_tbl_flg_terminologies,
                                                                            i_tbl_dep_clin_serv   => l_tbl_prof_dep_clin_serv)) dc);
            ELSE
                g_error := 'QUERY DATA WITH LIMIT = ' || i_limit;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_func_name);
                SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                                      id_diagnosis_parent => id_diagnosis_parent,
                                      id_alert_diagnosis  => id_alert_diagnosis,
                                      code_icd            => code_icd,
                                      id_language         => id_language,
                                      code_translation    => code_translation,
                                      desc_translation    => desc_translation,
                                      desc_epis_diagnosis => NULL,
                                      flg_other           => flg_other,
                                      flg_icd9            => flg_icd9,
                                      flg_select          => flg_select,
                                      id_dep_clin_serv    => id_dep_clin_serv,
                                      flg_terminology     => flg_terminology,
                                      rank                => rank,
                                      id_term_task_type   => l_term_task_type,
                                      flg_show_term_code  => i_flg_show_term_code,
                                      id_epis_diagnosis   => id_epis_diagnosis,
                                      flg_status          => NULL,
                                      flg_type            => NULL,
                                      flg_mechanism       => flg_mechanism)
                  BULK COLLECT
                  INTO l_tbl_aux
                  FROM (SELECT a.*
                          FROM (SELECT /*+opt_estimate(TABLE, v, rows = 100)*/
                                 dc.id_diagnosis,
                                 dc.id_diagnosis_parent,
                                 dc.id_alert_diagnosis,
                                 dc.code_icd,
                                 dc.id_language,
                                 dc.code_translation,
                                 nvl(dc.desc_translation,
                                     pk_translation.get_translation(i_lang      => dc.id_language,
                                                                    i_code_mess => dc.code_translation)) desc_translation,
                                 dc.flg_other,
                                 dc.flg_icd9,
                                 dc.flg_select,
                                 dc.id_dep_clin_serv,
                                 dc.flg_terminology,
                                 dc.rank,
                                 dc.id_epis_diagnosis,
                                 dc.flg_mechanism
                                  FROM TABLE(tf_diagnoses_cnt(i_tbl_diagnosis       => i_tbl_diagnosis,
                                                              i_tbl_alert_diagnosis => i_tbl_alert_diagnosis,
                                                              i_tbl_terminologies   => l_tbl_flg_terminologies,
                                                              i_tbl_dep_clin_serv   => l_tbl_prof_dep_clin_serv)) dc) a
                         ORDER BY a.rank, a.desc_translation) dc
                 WHERE rownum <= i_limit;
            END IF;
        
            RETURN l_tbl_aux;
        END tf_aux_limit;
    BEGIN
    
        g_error := 'CALL GET_DIAGNOSES_DEFAULT_ARGS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        get_diagnoses_default_args(i_lang                     => i_lang,
                                   i_prof                     => i_prof,
                                   i_patient                  => i_patient,
                                   i_format_text              => i_format_text,
                                   i_terminologies_task_types => i_terminologies_task_types,
                                   i_term_task_type           => i_term_task_type,
                                   i_list_type                => i_list_type,
                                   i_synonym_list_enable      => i_synonym_list_enable,
                                   i_synonym_search_enable    => i_synonym_search_enable,
                                   i_include_other_diagnosis  => i_include_other_diagnosis,
                                   i_tbl_terminologies        => i_tbl_terminologies,
                                   o_inst                     => l_inst,
                                   o_soft                     => l_soft,
                                   o_pat_age                  => l_pat_age,
                                   o_pat_gender               => l_pat_gender,
                                   o_tbl_flg_terminologies    => l_tbl_flg_terminologies,
                                   o_term_task_type           => l_term_task_type,
                                   o_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                   o_flg_type_dep_clin        => l_flg_type_dep_clin,
                                   o_synonym_list_enable      => l_synonym_list_enable,
                                   o_synonym_search_enable    => l_synonym_search_enable,
                                   o_include_other_diagnosis  => l_include_other_diagnosis,
                                   o_tbl_prof_dep_clin_serv   => l_tbl_prof_dep_clin_serv,
                                   o_terminologies_lang       => l_terminologies_lang,
                                   o_format_text              => l_format_text,
                                   o_validate_max_age         => l_validate_max_age);
    
        IF i_list_type = g_diag_list_searchable
        THEN
            IF i_text_search IS NOT NULL
            THEN
                g_error := 'SET SEARCH CONTEXT VARS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                set_diag_search_args(i_institution              => l_inst,
                                     i_software                 => l_soft,
                                     i_pat_age                  => l_pat_age,
                                     i_pat_gender               => l_pat_gender,
                                     i_term_task_type           => l_term_task_type,
                                     i_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                     i_flg_type_dep_clin        => l_flg_type_dep_clin,
                                     i_synonym_list_enable      => l_synonym_list_enable,
                                     i_include_other_diagnosis  => l_include_other_diagnosis,
                                     i_only_other_diags         => pk_alert_constant.g_no,
                                     i_tbl_dep_clin_serv        => l_tbl_prof_dep_clin_serv,
                                     i_tbl_diagnosis            => i_tbl_diagnosis,
                                     i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                     i_row_limit                => NULL,
                                     i_parent_diagnosis         => i_parent_diagnosis,
                                     i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                     i_validate_max_age         => l_validate_max_age,
                                     i_terminologies_lang       => l_terminologies_lang,
                                     i_text_search              => i_text_search,
                                     i_format_text              => l_format_text,
                                     i_language                 => i_lang);
            
                g_error := 'SEARCHABLE DIAGNOSES - FILTER DIAGNOSIS_CONTENT BY USER INPUT TEXT: ' || i_text_search;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_tbl_search_result := tf_aux_limit(i_limit => i_row_limit);
            
                IF l_synonym_search_enable = pk_alert_constant.g_yes
                   AND l_synonym_list_enable = pk_alert_constant.g_yes
                   AND l_tbl_search_result.exists(1)
                   AND nvl(i_row_limit, l_tbl_search_result.count) > l_tbl_search_result.count
                THEN
                    g_error := 'GET IDs DIAGNOSES JUST SEARCHED';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    SELECT /*+opt_estimate(TABLE, t, rows = 10)*/
                    DISTINCT id_diagnosis
                      BULK COLLECT
                      INTO l_tbl_aux_diag
                      FROM TABLE(l_tbl_search_result) t;
                
                    g_error := 'SET SYNONYM CONTEXT VARS';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    set_diag_search_args(i_institution              => l_inst,
                                         i_software                 => l_soft,
                                         i_pat_age                  => l_pat_age,
                                         i_pat_gender               => l_pat_gender,
                                         i_term_task_type           => l_term_task_type,
                                         i_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                         i_flg_type_dep_clin        => l_flg_type_dep_clin,
                                         i_synonym_list_enable      => l_synonym_list_enable,
                                         i_include_other_diagnosis  => l_include_other_diagnosis,
                                         i_only_other_diags         => pk_alert_constant.g_no,
                                         i_tbl_dep_clin_serv        => l_tbl_prof_dep_clin_serv,
                                         i_tbl_diagnosis            => l_tbl_aux_diag,
                                         i_tbl_alert_diagnosis      => NULL,
                                         i_row_limit                => NULL,
                                         i_parent_diagnosis         => i_parent_diagnosis,
                                         i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                         i_validate_max_age         => l_validate_max_age,
                                         i_terminologies_lang       => l_terminologies_lang,
                                         i_text_search              => NULL,
                                         i_format_text              => l_format_text,
                                         i_language                 => i_lang);
                
                    g_error := 'SEARCHABLE DIAGNOSES - GET SYNONYMS';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                                          id_diagnosis_parent => id_diagnosis_parent,
                                          id_alert_diagnosis  => id_alert_diagnosis,
                                          code_icd            => code_icd,
                                          id_language         => id_language,
                                          code_translation    => code_translation,
                                          desc_translation    => desc_translation,
                                          desc_epis_diagnosis => NULL,
                                          flg_other           => flg_other,
                                          flg_icd9            => flg_icd9,
                                          flg_select          => flg_select,
                                          id_dep_clin_serv    => id_dep_clin_serv,
                                          flg_terminology     => flg_terminology,
                                          rank                => rank,
                                          id_term_task_type   => l_term_task_type,
                                          flg_show_term_code  => i_flg_show_term_code,
                                          id_epis_diagnosis   => id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => flg_mechanism)
                      BULK COLLECT
                      INTO l_tbl_synonyms
                      FROM (SELECT /*+opt_estimate(TABLE, dc, rows = 100)*/
                             dc.id_diagnosis,
                             dc.id_diagnosis_parent,
                             dc.id_alert_diagnosis,
                             dc.code_icd,
                             dc.id_language,
                             dc.code_translation,
                             dc.desc_translation,
                             dc.flg_other,
                             dc.flg_icd9,
                             dc.flg_select,
                             dc.id_dep_clin_serv,
                             dc.flg_terminology,
                             dc.rank + 1000000 rank,
                             dc.id_epis_diagnosis,
                             dc.flg_mechanism
                              FROM TABLE(pk_terminology_search.tf_diagnoses_cnt(i_tbl_diagnosis       => l_tbl_aux_diag,
                                                                                i_tbl_alert_diagnosis => i_tbl_alert_diagnosis,
                                                                                i_tbl_terminologies   => l_tbl_flg_terminologies,
                                                                                i_tbl_dep_clin_serv   => l_tbl_prof_dep_clin_serv)) dc
                             WHERE dc.id_alert_diagnosis NOT IN
                                   (SELECT /*+opt_estimate(TABLE, t, rows = 10)*/
                                    DISTINCT id_alert_diagnosis
                                      FROM TABLE(l_tbl_search_result) t)) syn;
                
                    g_error := 'CALCULATE ROW_LIMIT';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_row_limit := CASE
                                       WHEN i_row_limit IS NULL THEN
                                        NULL
                                       ELSE
                                        i_row_limit - l_tbl_search_result.count
                                   END;
                
                    IF l_row_limit IS NOT NULL
                    THEN
                        g_error := 'SEARCHABLE DIAGNOSES - LIMIT SYNONYMS RESULTS BY - ' || l_row_limit;
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                                              id_diagnosis_parent => id_diagnosis_parent,
                                              id_alert_diagnosis  => id_alert_diagnosis,
                                              code_icd            => code_icd,
                                              id_language         => id_language,
                                              code_translation    => code_translation,
                                              desc_translation    => desc_translation,
                                              desc_epis_diagnosis => NULL,
                                              flg_other           => flg_other,
                                              flg_icd9            => flg_icd9,
                                              flg_select          => flg_select,
                                              id_dep_clin_serv    => id_dep_clin_serv,
                                              flg_terminology     => flg_terminology,
                                              rank                => rank,
                                              id_term_task_type   => l_term_task_type,
                                              flg_show_term_code  => i_flg_show_term_code,
                                              id_epis_diagnosis   => id_epis_diagnosis,
                                              flg_status          => NULL,
                                              flg_type            => NULL,
                                              flg_mechanism       => flg_mechanism)
                          BULK COLLECT
                          INTO l_tbl_aux_synonyms
                          FROM (SELECT b.*
                                  FROM (SELECT /*+opt_estimate(TABLE, dc, rows = 100)*/
                                         dc.id_diagnosis,
                                         dc.id_diagnosis_parent,
                                         dc.id_alert_diagnosis,
                                         dc.code_icd,
                                         dc.id_language,
                                         dc.code_translation,
                                         nvl(dc.desc_translation,
                                             pk_translation.get_translation(i_lang      => dc.id_language,
                                                                            i_code_mess => dc.code_translation)) desc_translation,
                                         dc.flg_other,
                                         dc.flg_icd9,
                                         dc.flg_select,
                                         dc.id_dep_clin_serv,
                                         dc.flg_terminology,
                                         dc.rank + 1000000 rank,
                                         dc.id_epis_diagnosis,
                                         dc.flg_mechanism
                                          FROM TABLE(l_tbl_synonyms) dc) b
                                 ORDER BY b.rank, b.desc_translation) trf
                         WHERE rownum <= l_row_limit;
                    
                        l_tbl_synonyms := l_tbl_aux_synonyms;
                    END IF;
                
                    g_error := 'SEARCHABLE DIAGNOSES - UNION SEARCH RESULT AND SYNONYMS TABLES';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_tbl_diagnoses := l_tbl_search_result MULTISET UNION l_tbl_synonyms;
                ELSE
                    l_tbl_diagnoses := l_tbl_search_result;
                END IF;
            
                IF l_include_other_diagnosis = pk_alert_constant.g_yes
                   AND nvl(i_list_type, g_diag_list_searchable) = g_diag_list_searchable
                THEN
                    g_error := 'GET FREE TEXT MSG';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    l_desc_msg_txt := pk_message.get_message(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_code_mess => l_code_msg_txt);
                
                    g_error := 'SET SYNONYM CONTEXT VARS';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    set_diag_search_args(i_institution              => l_inst,
                                         i_software                 => l_soft,
                                         i_pat_age                  => l_pat_age,
                                         i_pat_gender               => l_pat_gender,
                                         i_term_task_type           => l_term_task_type,
                                         i_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                         i_flg_type_dep_clin        => l_flg_type_dep_clin,
                                         i_synonym_list_enable      => l_synonym_list_enable,
                                         i_include_other_diagnosis  => l_include_other_diagnosis,
                                         i_only_other_diags         => pk_alert_constant.g_yes,
                                         i_tbl_dep_clin_serv        => l_tbl_prof_dep_clin_serv,
                                         i_tbl_diagnosis            => NULL,
                                         i_tbl_alert_diagnosis      => NULL,
                                         i_row_limit                => NULL,
                                         i_parent_diagnosis         => i_parent_diagnosis,
                                         i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                         i_validate_max_age         => l_validate_max_age,
                                         i_terminologies_lang       => l_terminologies_lang,
                                         i_text_search              => NULL,
                                         i_format_text              => l_format_text,
                                         i_language                 => i_lang);
                
                    g_error := 'SEARCHABLE DIAGNOSES - ADD OTHER DIAGNOSIS';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    SELECT t_rec_diag_cnt(id_diagnosis        => id_diagnosis,
                                          id_diagnosis_parent => id_diagnosis_parent,
                                          id_alert_diagnosis  => id_alert_diagnosis,
                                          code_icd            => code_icd,
                                          id_language         => id_language,
                                          code_translation    => code_translation,
                                          desc_translation    => desc_translation,
                                          desc_epis_diagnosis => NULL,
                                          flg_other           => flg_other,
                                          flg_icd9            => flg_icd9,
                                          flg_select          => flg_select,
                                          id_dep_clin_serv    => id_dep_clin_serv,
                                          flg_terminology     => flg_terminology,
                                          rank                => rank,
                                          id_term_task_type   => l_term_task_type,
                                          flg_show_term_code  => i_flg_show_term_code,
                                          id_epis_diagnosis   => id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => flg_mechanism)
                      BULK COLLECT
                      INTO l_tbl_other_diag
                      FROM (SELECT /*+opt_estimate(TABLE, dc, rows = 1)*/
                             dc.id_diagnosis,
                             dc.id_diagnosis_parent,
                             dc.id_alert_diagnosis,
                             dc.code_icd,
                             dc.id_language,
                             dc.code_translation,
                             i_text_search || ' ' || l_desc_msg_txt desc_translation,
                             dc.flg_other,
                             dc.flg_icd9,
                             dc.flg_select,
                             dc.id_dep_clin_serv,
                             dc.flg_terminology,
                             dc.rank + 2000000 rank,
                             dc.id_epis_diagnosis,
                             dc.flg_mechanism
                              FROM TABLE(pk_terminology_search.tf_diagnoses_cnt(i_tbl_diagnosis       => i_tbl_diagnosis,
                                                                                i_tbl_alert_diagnosis => i_tbl_alert_diagnosis,
                                                                                i_tbl_terminologies   => l_tbl_flg_terminologies,
                                                                                i_tbl_dep_clin_serv   => l_tbl_prof_dep_clin_serv)) dc) trf;
                
                    IF l_tbl_other_diag.exists(1)
                    THEN
                        g_error := 'SEARCHABLE DIAGNOSES - UNION DIAGNOSES AND OTHER DIAG TABLES';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        l_tbl_diagnoses := l_tbl_diagnoses MULTISET UNION l_tbl_other_diag;
                    END IF;
                END IF;
            ELSE
                g_error := 'SET CONTEXT VARS TO RETURN ALL CONTENT';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                set_diag_search_args(i_institution              => l_inst,
                                     i_software                 => l_soft,
                                     i_pat_age                  => l_pat_age,
                                     i_pat_gender               => l_pat_gender,
                                     i_term_task_type           => l_term_task_type,
                                     i_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                     i_flg_type_dep_clin        => l_flg_type_dep_clin,
                                     i_synonym_list_enable      => l_synonym_list_enable,
                                     i_include_other_diagnosis  => l_include_other_diagnosis,
                                     i_only_other_diags         => pk_alert_constant.g_no,
                                     i_tbl_dep_clin_serv        => l_tbl_prof_dep_clin_serv,
                                     i_tbl_diagnosis            => i_tbl_diagnosis,
                                     i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                     i_row_limit                => NULL,
                                     i_parent_diagnosis         => i_parent_diagnosis,
                                     i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                     i_validate_max_age         => l_validate_max_age,
                                     i_terminologies_lang       => l_terminologies_lang,
                                     i_text_search              => NULL,
                                     i_format_text              => l_format_text,
                                     i_language                 => i_lang);
            
                --If there isn't any text to search return all available content
                l_tbl_diagnoses := tf_aux_limit(i_limit => i_row_limit);
            END IF;
        ELSE
            g_error := 'SET MOST_FREQ CONTEXT VARS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            set_diag_search_args(i_institution              => l_inst,
                                 i_software                 => l_soft,
                                 i_pat_age                  => l_pat_age,
                                 i_pat_gender               => l_pat_gender,
                                 i_term_task_type           => l_term_task_type,
                                 i_flg_type_alert_diagnosis => l_flg_type_alert_diagnosis,
                                 i_flg_type_dep_clin        => l_flg_type_dep_clin,
                                 i_synonym_list_enable      => l_synonym_list_enable,
                                 i_include_other_diagnosis  => l_include_other_diagnosis,
                                 i_only_other_diags         => pk_alert_constant.g_no,
                                 i_tbl_dep_clin_serv        => l_tbl_prof_dep_clin_serv,
                                 i_tbl_diagnosis            => i_tbl_diagnosis,
                                 i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                 i_row_limit                => NULL,
                                 i_parent_diagnosis         => i_parent_diagnosis,
                                 i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                 i_validate_max_age         => l_validate_max_age,
                                 i_terminologies_lang       => l_terminologies_lang,
                                 i_text_search              => i_text_search,
                                 i_format_text              => l_format_text,
                                 i_language                 => i_lang);
        
            g_error := 'MOST FREQUENT DIAGNOSES - FILTER BY USER INPUT TEXT: ' || i_text_search || '; ' || CASE
                           WHEN i_row_limit IS NOT NULL THEN
                            'RETURN FIRST ' || i_row_limit || ' ROWS'
                           ELSE
                            'RETURN ALL CONTENT'
                       END;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_tbl_diagnoses := tf_aux_limit(i_limit => i_row_limit);
        END IF;
    
        RETURN l_tbl_diagnoses;
    END tf_diagnoses_search;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                     language identifier
    * @param i_prof                     logged professional structure
    * @param i_patient                  patient ID
    * @param i_text_search              search input
    * @param i_format_text              Apply styles to diagnoses names? Y/N
    * @param i_terminologies_task_types Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type           Area of the application where the term will be shown
    * @param i_flg_show_term_code       Is to concatenate the terminology code to the diagnosis description
    * @param i_list_type                Type of list to be returned
    * @param i_synonym_list_enable      Enable/disable synonyms in result sets
    * @param i_synonym_search_enable    Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis  Include other diagnoses in result sets
    * @param i_tbl_diagnosis            Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis      Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_terminologies        Filter by flg_terminology (NULL for all terminologies). This is useful when the user
    *                                   has a multichoice with the available terminologies and can select them
    * @param i_row_limit                Limit the number of rows returned (NULL return all)
    * @param i_parent_diagnosis         Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt  Return only diagnoses filtered by i_parent_diagnosis
    *
    * @values i_list_type               S - Searchable diagnoses list
    *                                   F - Most frequent diagnoses list
    *                                   G - Pregnancy most frequent diagnoses list
    *
    * @return                           Diagnoses searchable table
    *
    * @author                           Alexandre Santos
    * @version                          2.6.3
    * @since                            2013/11/08
    **********************************************************************************************/
    FUNCTION tf_diagnoses_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_flg_show_term_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_diagnosis            IN table_number DEFAULT NULL,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_diagnosis_config IS
        l_func_name     VARCHAR2(30 CHAR) := 'TF_DIAGNOSES_LIST';
        l_tbl_diagnosis t_coll_diagnosis_config;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    BEGIN
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, i_prof);
    
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            g_error := 'get_diagnoses_search - CALL get_diagnoses_search';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                          id_diagnosis_parent     => a.id_diagnosis_parent,
                                          id_epis_diagnosis       => NULL,
                                          desc_diagnosis          => a.desc_diagnosis,
                                          code_icd                => a.code_icd,
                                          flg_other               => a.flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => a.flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => a.id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => a.flg_terminology,
                                          rank                    => a.rank)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM (SELECT b.id_diagnosis,
                           b.id_diagnosis_parent,
                           pk_diagnosis.std_diag_desc(i_lang                => b.id_language,
                                                      i_prof                => i_prof,
                                                      i_id_diagnosis        => b.id_diagnosis,
                                                      i_id_alert_diagnosis  => b.id_alert_diagnosis,
                                                      i_code_diagnosis      => b.code_translation,
                                                      i_diagnosis_language  => b.id_language,
                                                      i_desc_epis_diagnosis => nvl(b.desc_translation,
                                                                                   pk_translation.get_translation(i_lang      => b.id_language,
                                                                                                                  i_code_mess => b.code_translation)),
                                                      i_id_task_type        => i_term_task_type,
                                                      i_code                => b.code_icd,
                                                      i_flg_other           => b.flg_other,
                                                      i_flg_std_diag        => b.flg_icd9,
                                                      i_flg_search_mode     => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code  => i_flg_show_term_code) desc_diagnosis,
                           b.code_icd,
                           b.flg_other,
                           b.flg_select,
                           b.id_alert_diagnosis,
                           b.flg_terminology,
                           b.rank
                      FROM TABLE(pk_terminology_search.get_diagnoses_search(i_lang                     => i_lang,
                                                                            i_prof                     => i_prof,
                                                                            i_patient                  => i_patient,
                                                                            i_text_search              => i_text_search,
                                                                            i_format_text              => i_format_text,
                                                                            i_terminologies_task_types => i_terminologies_task_types,
                                                                            i_tbl_term_task_type       => table_number(i_term_task_type),
                                                                            i_list_type                => i_list_type,
                                                                            i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                                                            i_tbl_terminologies        => i_tbl_terminologies,
                                                                            i_row_limit                => i_row_limit,
                                                                            i_parent_diagnosis         => i_parent_diagnosis,
                                                                            i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt)) b) a
             ORDER BY a.rank, a.desc_diagnosis;
        ELSE
            g_error := 'TF_DIAGNOSES_LIST - CALL TF_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                          id_diagnosis_parent     => a.id_diagnosis_parent,
                                          id_epis_diagnosis       => NULL,
                                          desc_diagnosis          => a.desc_diagnosis,
                                          code_icd                => a.code_icd,
                                          flg_other               => a.flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => a.flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => a.id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => a.flg_terminology,
                                          rank                    => a.rank)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM (SELECT b.id_diagnosis,
                           b.id_diagnosis_parent,
                           pk_diagnosis.std_diag_desc(i_lang                => b.id_language,
                                                      i_prof                => i_prof,
                                                      i_id_diagnosis        => b.id_diagnosis,
                                                      i_id_alert_diagnosis  => b.id_alert_diagnosis,
                                                      i_code_diagnosis      => b.code_translation,
                                                      i_diagnosis_language  => b.id_language,
                                                      i_desc_epis_diagnosis => nvl(b.desc_translation,
                                                                                   pk_translation.get_translation(i_lang      => b.id_language,
                                                                                                                  i_code_mess => b.code_translation)),
                                                      i_id_task_type        => i_term_task_type,
                                                      i_code                => b.code_icd,
                                                      i_flg_other           => b.flg_other,
                                                      i_flg_std_diag        => b.flg_icd9,
                                                      i_flg_search_mode     => pk_alert_constant.g_yes,
                                                      i_flg_show_term_code  => i_flg_show_term_code) desc_diagnosis,
                           b.code_icd,
                           b.flg_other,
                           b.flg_select,
                           b.id_alert_diagnosis,
                           b.flg_terminology,
                           b.rank
                      FROM TABLE(pk_terminology_search.tf_diagnoses_search(i_lang                     => i_lang,
                                                                           i_prof                     => i_prof,
                                                                           i_patient                  => i_patient,
                                                                           i_text_search              => i_text_search,
                                                                           i_format_text              => i_format_text,
                                                                           i_terminologies_task_types => i_terminologies_task_types,
                                                                           i_term_task_type           => i_term_task_type,
                                                                           i_flg_show_term_code       => i_flg_show_term_code,
                                                                           i_list_type                => i_list_type,
                                                                           i_synonym_list_enable      => i_synonym_list_enable,
                                                                           i_synonym_search_enable    => i_synonym_search_enable,
                                                                           i_include_other_diagnosis  => i_include_other_diagnosis,
                                                                           i_tbl_diagnosis            => i_tbl_diagnosis,
                                                                           i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                                                           i_tbl_terminologies        => i_tbl_terminologies,
                                                                           i_row_limit                => i_row_limit,
                                                                           i_parent_diagnosis         => i_parent_diagnosis,
                                                                           i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt)) b) a
             ORDER BY a.rank, a.desc_diagnosis;
        END IF;
    
        RETURN l_tbl_diagnosis;
    END tf_diagnoses_list;

    /********************************************************************************************************
    * Gets all patient diferential diagnosis registered in the current episode.
    *
    * @return                           Returns a patient's differential diagnoses
    *                                   (used in the final diagnoses screen filter)
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    ********************************************************************************************************/
    FUNCTION tf_patient_diagnoses_diff RETURN t_coll_diagnosis_config IS
        l_lang              language.id_language%TYPE;
        l_patient           patient.id_patient%TYPE;
        l_prof              profissional;
        l_episode           episode.id_episode%TYPE;
        l_text_search       translation.desc_lang_1%TYPE;
        l_profile_template  profile_template.id_profile_template%TYPE;
        l_epis_diag_type    epis_diagnosis.flg_type%TYPE;
        l_tbl_diagnosis     t_table_diag_cnt;
        l_tbl_diagnosis_aux t_table_diag_cnt;
    
        l_tbl_status             table_varchar := table_varchar(pk_diagnosis.g_ed_flg_status_d,
                                                                pk_diagnosis.g_ed_flg_status_co,
                                                                pk_diagnosis.g_ed_flg_status_p);
        l_tbl_id_diagnosis       table_number;
        l_tbl_id_alert_diagnosis table_number;
    
        l_tbl_diag_diff_tmp  t_coll_episode_diagnosis;
        l_tbl_diagnosis_diff t_coll_episode_diagnosis;
    
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    
        l_func_name VARCHAR2(100 CHAR) := 'TF_PATIENT_DIAGNOSES_DIFF';
        l_error     t_error_out;
    BEGIN
        g_error := '1- LOAD SEARCH VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => l_prof);
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, l_prof);
    
        g_error := '2- LOADED VALUES - l_lang: ' || l_lang || ', l_patient: ' || l_patient || ', l_prof.id: ' ||
                   l_prof.id || ', l_prof.institution: ' || l_prof.institution || ', l_prof.software: ' ||
                   l_prof.software || ', l_episode: ' || l_episode || ', l_text_search: ' || l_text_search ||
                   ', l_epis_diag_type : ' || l_epis_diag_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := '3.0- CALL PK_DIAGNOSIS_CORE.TB_GET_EPIS_DIAGNOSIS_LIST - GET PATIENT DIFFERENTIAL DIAGNOSIS BY ID EPISODE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            l_tbl_diag_diff_tmp := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => l_lang,
                                                                                i_prof        => l_prof,
                                                                                i_patient     => l_patient,
                                                                                i_id_scope    => l_episode,
                                                                                i_flg_scope   => pk_diagnosis_core.g_scope_episode,
                                                                                i_flg_type    => pk_diagnosis.g_diag_type_p,
                                                                                i_criteria    => l_text_search,
                                                                                i_format_text => pk_alert_constant.g_no,
                                                                                i_tbl_status  => l_tbl_status);
        
            g_error := '3.1- CALL PK_DIAGNOSIS_CORE.TB_GET_EPIS_DIAGNOSIS_LIST - GET PATIENT DIFFERENTIAL DIAGNOSIS BY ID PATIENT';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT a.obj
              BULK COLLECT
              INTO l_tbl_diagnosis_diff
              FROM (SELECT VALUE(t) obj
                      FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => l_lang,
                                                                              i_prof        => l_prof,
                                                                              i_patient     => l_patient,
                                                                              i_id_scope    => l_patient,
                                                                              i_flg_scope   => pk_diagnosis_core.g_scope_patient,
                                                                              i_flg_type    => pk_diagnosis.g_diag_type_d,
                                                                              i_criteria    => l_text_search,
                                                                              i_format_text => pk_alert_constant.g_no,
                                                                              i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_co))) t
                     WHERE t.id_episode != l_episode
                       AND (t.id_diagnosis, t.id_alert_diagnosis, t.desc_diagnosis) NOT IN
                           (SELECT t1.id_diagnosis, t1.id_alert_diagnosis, t1.desc_diagnosis
                              FROM TABLE(l_tbl_diag_diff_tmp) t1)
                    UNION ALL
                    SELECT VALUE(t) obj
                      FROM TABLE(l_tbl_diag_diff_tmp) t) a;
        ELSE
            l_tbl_diag_diff_tmp := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => l_lang,
                                                                                i_prof        => l_prof,
                                                                                i_patient     => l_patient,
                                                                                i_id_scope    => l_episode,
                                                                                i_flg_scope   => pk_diagnosis_core.g_scope_episode,
                                                                                i_flg_type    => pk_diagnosis.g_diag_type_p,
                                                                                i_criteria    => l_text_search,
                                                                                i_format_text => pk_alert_constant.g_no,
                                                                                i_tbl_status  => l_tbl_status);
        
            g_error := '3.1- CALL PK_DIAGNOSIS_CORE.TB_GET_EPIS_DIAGNOSIS_LIST - GET PATIENT DIFFERENTIAL DIAGNOSIS BY ID PATIENT';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT a.obj
              BULK COLLECT
              INTO l_tbl_diagnosis_diff
              FROM (SELECT VALUE(t) obj
                      FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => l_lang,
                                                                              i_prof        => l_prof,
                                                                              i_patient     => l_patient,
                                                                              i_id_scope    => l_patient,
                                                                              i_flg_scope   => pk_diagnosis_core.g_scope_patient,
                                                                              i_flg_type    => pk_diagnosis.g_diag_type_d,
                                                                              i_criteria    => l_text_search,
                                                                              i_format_text => pk_alert_constant.g_no,
                                                                              i_tbl_status  => table_varchar(pk_diagnosis.g_ed_flg_status_co))) t
                     WHERE t.id_episode != l_episode
                       AND (t.id_diagnosis, t.id_alert_diagnosis, t.desc_diagnosis) NOT IN
                           (SELECT t1.id_diagnosis, t1.id_alert_diagnosis, t1.desc_diagnosis
                              FROM TABLE(l_tbl_diag_diff_tmp) t1)
                    UNION ALL
                    SELECT VALUE(t) obj
                      FROM TABLE(l_tbl_diag_diff_tmp) t) a;
        
        END IF;

        g_error := '4- GET TWO TABLE NUMBER OBJECTS THAT CONTAINS ID DIAGNOSIS/ID ALERT DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT DISTINCT epis_diag.id_diagnosis, epis_diag.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
              FROM TABLE(l_tbl_diagnosis_diff) epis_diag;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_id_diagnosis       := table_number();
                l_tbl_id_alert_diagnosis := table_number();
        END;
    
        g_error := '5- VERIFY IF PATIENT HAVE DIFF DIAGNOSES REGISTERED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_tbl_id_diagnosis.exists(1)
           AND l_tbl_id_alert_diagnosis.exists(1)
        THEN
            g_error := '6- CHECK CONTENT AVAILABILITY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                l_tbl_diagnosis := get_diagnoses_search(i_lang                     => l_lang,
                                                        i_prof                     => l_prof,
                                                        i_patient                  => l_patient,
                                                        i_text_search              => l_text_search,
                                                        i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                        i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
            ELSE
            
                l_tbl_diagnosis := tf_diagnoses_search(i_lang                     => l_lang,
                                                       i_prof                     => l_prof,
                                                       i_patient                  => l_patient,
                                                       i_text_search              => l_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                       i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                       i_flg_show_term_code       => l_flg_show_term_code,
                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                       i_tbl_diagnosis            => l_tbl_id_diagnosis,
                                                       i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
            
            END IF;
        
            g_error := '7- FILL OTHER_DIAG RECORDS WITH "WITH PREVIOUS RECORDS"';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diag_cnt(id_diagnosis        => tf.id_diagnosis,
                                  id_diagnosis_parent => tf.id_diagnosis_parent,
                                  id_alert_diagnosis  => tf.id_alert_diagnosis,
                                  code_icd            => tf.code_icd,
                                  id_language         => tf.id_language,
                                  code_translation    => tf.code_translation,
                                  desc_epis_diagnosis => get_with_prev_rec_msg(i_lang         => l_lang,
                                                                               i_id_task_type => pk_alert_constant.g_task_diagnosis,
                                                                               i_date_tstz    => pk_past_history.get_partial_date_format(i_lang      => l_lang,
                                                                                                                                         i_prof      => l_prof,
                                                                                                                                         i_date      => tf.dt_initial_diag,
                                                                                                                                         i_precision => pk_past_history.g_past_hist_date_precision_day)),
                                  desc_translation    => decode(tf.flg_other,
                                                                pk_alert_constant.g_yes,
                                                                tf.desc_diagnosis,
                                                                NULL),
                                  flg_other           => tf.flg_other,
                                  flg_icd9            => tf.flg_icd9,
                                  flg_select          => tf.flg_select,
                                  id_dep_clin_serv    => tf.id_dep_clin_serv,
                                  flg_terminology     => tf.flg_terminology,
                                  rank                => tf.rank,
                                  id_term_task_type   => tf.id_term_task_type,
                                  flg_show_term_code  => tf.flg_show_term_code,
                                  id_epis_diagnosis   => tf.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => NULL,
                                  id_tvr_msi          => tf.id_tvr_msi)
              BULK COLLECT
              INTO l_tbl_diagnosis_aux
              FROM (SELECT ts.id_diagnosis,
                           ts.id_diagnosis_parent,
                           ts.id_alert_diagnosis,
                           ts.code_icd,
                           ts.id_language,
                           ts.code_translation,
                           te.dt_initial_diag,
                           te.desc_diagnosis,
                           ts.flg_other,
                           ts.flg_icd9,
                           ts.flg_select,
                           ts.id_dep_clin_serv,
                           ts.flg_terminology,
                           ts.rank,
                           ts.id_term_task_type,
                           ts.flg_show_term_code,
                           te.id_epis_diagnosis,
                           ts.id_tvr_msi,
                           row_number() over(PARTITION BY ts.id_diagnosis, ts.id_alert_diagnosis, ed.desc_epis_diagnosis, ed.id_diagnosis_condition, ed.id_sub_analysis, ed.id_anatomical_area, ed.id_anatomical_side --
                           ORDER BY te.dt_epis_diagnosis DESC) ln
                      FROM TABLE(l_tbl_diagnosis) ts --Diagnoses that exist in current configuration of terminologies
                      JOIN TABLE(l_tbl_diagnosis_diff) te --Diagnoses registered for this patient
                    --ON te.id_diagnosis = ts.id_diagnosis
                        ON te.id_alert_diagnosis = ts.id_alert_diagnosis
                      JOIN epis_diagnosis ed
                        ON ed.id_epis_diagnosis = te.id_epis_diagnosis
                     WHERE pk_diagnosis_core.check_if_diag_registered(i_lang                => l_lang,
                                                                      i_prof                => l_prof,
                                                                      i_episode             => l_episode,
                                                                      i_diagnosis           => ed.id_diagnosis,
                                                                      i_flg_type            => pk_diagnosis.g_diag_type_d,
                                                                      i_desc_diag           => ed.desc_epis_diagnosis,
                                                                      i_diagnosis_condition => ed.id_diagnosis_condition,
                                                                      i_sub_analysis        => ed.id_sub_analysis,
                                                                      i_anatomical_area     => ed.id_anatomical_area,
                                                                      i_anatomical_side     => ed.id_anatomical_side) =
                           pk_alert_constant.g_no) tf
             WHERE tf.ln = 1;
        ELSE
            l_tbl_diagnosis_aux := t_table_diag_cnt();
        END IF;
    
        g_error := '8- CALL PK_TERMINOLOGY_SEARCH.GET_T_COLL_DIAGNOSIS_CONFIG TO PARSE L_TBL_DIAGNOSIS TO T_COLL_DIAGNOSIS_CONFIG OBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN get_t_coll_diagnosis_config(i_prof                   => l_prof,
                                           i_episode                => l_episode,
                                           i_diag_type              => l_epis_diag_type,
                                           i_tbl_diagnosis          => l_tbl_diagnosis_aux,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_yes,
                                           i_diagnoses_mechanism    => l_diagnoses_mechanism);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_patient_diagnoses_diff;

    /********************************************************************************************************
    * Gets all patient final diagnosis with 'Confirmed' status registered in the current and previous visits.
    *
    * @return                            Returns a patient's final diagnoses
    *                                   (used in the differential diagnoses screen filter)
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    ********************************************************************************************************/
    FUNCTION tf_patient_diagnoses_final RETURN t_coll_diagnosis_config IS
        l_lang             language.id_language%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_prof             profissional;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_tbl_diagnosis          t_table_diag_cnt;
        l_tbl_status             table_varchar := table_varchar(pk_diagnosis.g_ed_flg_status_co);
        l_tbl_id_diagnosis       table_number;
        l_tbl_id_alert_diagnosis table_number;
        l_tbl_diagnosis_final    t_coll_episode_diagnosis;
        l_tbl_diagnosis_aux      t_table_diag_cnt;
        l_func_name              VARCHAR2(100 CHAR) := 'TF_PATIENT_DIAGNOSES_FINAL';
        l_error                  t_error_out;
    
        l_allow_diagnoses_same_icd sys_config.value%TYPE;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    
    BEGIN
        g_error := 'LOAD SEARCH VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_allow_diagnoses_same_icd := pk_sysconfig.get_config('ALLOW_DIFF_DIAGNOSIS_SAME_ICD', l_prof);
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, l_prof);
    
        g_error := 'LOADED VALUES - l_lang: ' || l_lang || ', l_patient: ' || l_patient || ', l_prof.id: ' || l_prof.id ||
                   ', l_prof.institution: ' || l_prof.institution || ', l_prof.software: ' || l_prof.software ||
                   ', l_episode: ' || l_episode || ', l_text_search: ' || l_text_search || ', l_epis_diag_type : ' ||
                   l_epis_diag_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL PK_DIAGNOSIS_CORE.TB_GET_EPIS_DIAGNOSIS_LIST - GET PATIENT FINAL DIAGNOSIS BY ID PATIENT (CURRENT AND PREVIOUS EPISODES)';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            --When using the new mechanism, the search for transactional records
            --does not have to be performed using a text search.  
            l_tbl_diagnosis_final := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang       => l_lang,
                                                                                  i_prof       => l_prof,
                                                                                  i_patient    => l_patient,
                                                                                  i_id_scope   => l_patient,
                                                                                  i_flg_scope  => pk_diagnosis_core.g_scope_patient,
                                                                                  i_flg_type   => pk_diagnosis.g_diag_type_d,
                                                                                  i_tbl_status => l_tbl_status);
        
        ELSE
        
            l_tbl_diagnosis_final := pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang        => l_lang,
                                                                                  i_prof        => l_prof,
                                                                                  i_patient     => l_patient,
                                                                                  i_id_scope    => l_patient,
                                                                                  i_flg_scope   => pk_diagnosis_core.g_scope_patient,
                                                                                  i_flg_type    => pk_diagnosis.g_diag_type_d,
                                                                                  i_criteria    => l_text_search,
                                                                                  i_format_text => pk_alert_constant.g_no,
                                                                                  i_tbl_status  => l_tbl_status);
        END IF;
    
        g_error := 'GET TWO TABLE NUMBER OBJECTS THAT CONTAINS ID DIAGNOSIS/ID ALERT DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        BEGIN
            SELECT DISTINCT epis_diag.id_diagnosis, epis_diag.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
              FROM TABLE(l_tbl_diagnosis_final) epis_diag
             WHERE epis_diag.id_episode <> l_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_id_diagnosis       := table_number();
                l_tbl_id_alert_diagnosis := table_number();
        END;
    
        g_error := 'VERIFY IF PATIENT HAVE FINAL DIAGNOSES REGISTERED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        IF l_tbl_id_diagnosis.exists(1)
           AND l_tbl_id_alert_diagnosis.exists(1)
        THEN
            g_error := 'CHECK CONTENT AVAILABILITY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
            
                l_tbl_diagnosis := get_diagnoses_search(i_lang                     => l_lang,
                                                        i_prof                     => l_prof,
                                                        i_patient                  => l_patient,
                                                        i_text_search              => l_text_search,
                                                        i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                        i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
            
            ELSE
                l_tbl_diagnosis := tf_diagnoses_search(i_lang                     => l_lang,
                                                       i_prof                     => l_prof,
                                                       i_patient                  => l_patient,
                                                       i_text_search              => l_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                       i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                       i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                       i_tbl_diagnosis            => l_tbl_id_diagnosis,
                                                       i_tbl_alert_diagnosis      => l_tbl_id_alert_diagnosis);
            END IF;
        
            g_error := '7- FILL OTHER_DIAG RECORDS WITH "WITH PREVIOUS RECORDS"';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diag_cnt(id_diagnosis        => tf.id_diagnosis,
                                  id_diagnosis_parent => tf.id_diagnosis_parent,
                                  id_alert_diagnosis  => tf.id_alert_diagnosis,
                                  code_icd            => tf.code_icd,
                                  id_language         => tf.id_language,
                                  code_translation    => tf.code_translation,
                                  desc_epis_diagnosis => get_with_prev_rec_msg(i_lang         => l_lang,
                                                                               i_id_task_type => pk_alert_constant.g_task_diagnosis,
                                                                               i_date_tstz    => pk_past_history.get_partial_date_format(i_lang      => l_lang,
                                                                                                                                         i_prof      => l_prof,
                                                                                                                                         i_date      => tf.dt_initial_diag,
                                                                                                                                         i_precision => pk_past_history.g_past_hist_date_precision_day)),
                                  desc_translation    => decode(tf.flg_other,
                                                                pk_alert_constant.g_yes,
                                                                tf.desc_diagnosis,
                                                                decode(l_allow_diagnoses_same_icd,
                                                                       pk_alert_constant.g_yes,
                                                                       tf.desc_diagnosis,
                                                                       NULL)),
                                  flg_other           => tf.flg_other,
                                  flg_icd9            => tf.flg_icd9,
                                  flg_select          => tf.flg_select,
                                  id_dep_clin_serv    => tf.id_dep_clin_serv,
                                  flg_terminology     => tf.flg_terminology,
                                  rank                => tf.rank,
                                  id_term_task_type   => tf.id_term_task_type,
                                  flg_show_term_code  => tf.flg_show_term_code,
                                  id_epis_diagnosis   => tf.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => NULL,
                                  id_tvr_msi          => tf.id_tvr_msi)
              BULK COLLECT
              INTO l_tbl_diagnosis_aux
              FROM (SELECT ts.id_diagnosis,
                           ts.id_diagnosis_parent,
                           ts.id_alert_diagnosis,
                           ts.code_icd,
                           ts.id_language,
                           ts.code_translation,
                           te.dt_initial_diag,
                           te.desc_diagnosis,
                           ts.flg_other,
                           ts.flg_icd9,
                           ts.flg_select,
                           ts.id_dep_clin_serv,
                           ts.flg_terminology,
                           ts.rank,
                           ts.id_term_task_type,
                           ts.flg_show_term_code,
                           te.id_epis_diagnosis,
                           ts.id_tvr_msi,
                           row_number() over(PARTITION BY ts.id_diagnosis, ts.id_alert_diagnosis, ed.desc_epis_diagnosis, ed.id_diagnosis_condition, ed.id_sub_analysis, ed.id_anatomical_area, ed.id_anatomical_side ORDER BY te.dt_epis_diagnosis DESC) ln
                      FROM TABLE(l_tbl_diagnosis) ts --Diagnoses that exist in current configuration of terminologies
                      JOIN TABLE(l_tbl_diagnosis_final) te --Diagnoses registered for this patient
                    -- ON te.id_diagnosis = ts.id_diagnosis
                        ON te.id_alert_diagnosis = ts.id_alert_diagnosis
                       AND te.id_episode <> l_episode
                      JOIN epis_diagnosis ed
                        ON ed.id_epis_diagnosis = te.id_epis_diagnosis
                     WHERE pk_diagnosis_core.check_if_diag_registered(i_lang                => l_lang,
                                                                      i_prof                => l_prof,
                                                                      i_episode             => l_episode,
                                                                      i_diagnosis           => ed.id_diagnosis,
                                                                      i_flg_type            => pk_diagnosis.g_diag_type_p,
                                                                      i_desc_diag           => ed.desc_epis_diagnosis,
                                                                      i_diagnosis_condition => ed.id_diagnosis_condition,
                                                                      i_sub_analysis        => ed.id_sub_analysis,
                                                                      i_anatomical_area     => ed.id_anatomical_area,
                                                                      i_anatomical_side     => ed.id_anatomical_side) =
                           pk_alert_constant.g_no) tf
             WHERE tf.ln = 1;
        
        ELSE
            l_tbl_diagnosis_aux := t_table_diag_cnt();
        END IF;
    
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.GET_T_COLL_DIAGNOSIS_CONFIG TO PARSE L_TBL_DIAGNOSIS TO T_COLL_DIAGNOSIS_CONFIG OBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN get_t_coll_diagnosis_config(i_prof                   => l_prof,
                                           i_episode                => l_episode,
                                           i_diag_type              => l_epis_diag_type,
                                           i_tbl_diagnosis          => l_tbl_diagnosis_aux,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_yes,
                                           i_diagnoses_mechanism    => l_diagnoses_mechanism);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_patient_diagnoses_final;

    /**************************************************************************************************************
    * Gets patient past medical history/Problems and diagnosis registered in problems area information
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_patient         Patient identifier
    * @param i_criteria        Text to search
    *
    * @return                  Returns t_table_diag_cnt with all information
    *
    * @author                  Gisela Couto
    * @version                 2.6.4.2
    * @since                   23/09/2014
    **************************************************************************************************************/
    FUNCTION get_patient_hist_prob
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_criteria IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_diag_cnt IS
        l_tbl_diag t_table_diag_cnt;
    
        l_func_name VARCHAR2(100 CHAR) := 'GET_PATIENT_HIST_PROB';
        l_error     t_error_out;
    BEGIN
    
        g_error := 'VALUES - i_lang: ' || i_lang || ', i_patient: ' || i_patient || ', i_prof.id: ' || i_prof.id ||
                   ', i_prof.institution: ' || i_prof.institution || ', i_prof.software: ' || i_prof.software;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        BEGIN
            g_error := 'GET ACTIVE PAST MEDICAL/PROBLEMS AND ACTIVE DIAGNOSIS ADDED IN THE PROBLEMS AREA';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diag_cnt(id_diagnosis        => b.id_diagnosis,
                                  id_diagnosis_parent => NULL,
                                  id_alert_diagnosis  => b.id_alert_diagnosis,
                                  code_icd            => NULL,
                                  id_language         => decode(ad.id_language, 0, i_lang, ad.id_language),
                                  code_translation    => ad.code_alert_diagnosis,
                                  --Diagnoses description
                                  desc_translation => b.desc_pat_history_diagnosis,
                                  --With previous records description
                                  desc_epis_diagnosis => pk_terminology_search.get_with_prev_rec_msg(i_lang         => i_lang,
                                                                                                     i_id_task_type => b.id_task_type,
                                                                                                     i_date_tstz    => b.dt_diagnosed),
                                  flg_other           => d.flg_other,
                                  flg_icd9            => ad.flg_icd9,
                                  flg_select          => pk_alert_constant.g_yes,
                                  id_dep_clin_serv    => NULL,
                                  flg_terminology     => d.flg_type,
                                  rank                => NULL,
                                  id_term_task_type   => b.id_task_type,
                                  flg_show_term_code  => NULL,
                                  id_epis_diagnosis   => NULL,
                                  flg_status          => b.flg_status,
                                  flg_type            => b.flg_type,
                                  flg_mechanism       => NULL)
              BULK COLLECT
              INTO l_tbl_diag
              FROM (SELECT l.id_diagnosis,
                           l.id_alert_diagnosis,
                           l.desc_pat_history_diagnosis,
                           l.dt_diagnosed,
                           l.id_task_type,
                           l.flg_status,
                           l.flg_type
                      FROM (SELECT a.*,
                                   --When the same diagnosis is registered in more than one area (past medical/problems/diagnosis area), the record to be shown
                                   -- is only one and the task type must respect the following order:
                                   -- first - Diagnosis
                                   -- second - Past Medical History
                                   -- Third - Problem
                                   row_number() over(PARTITION BY a.id_diagnosis, a.id_alert_diagnosis, a.desc_pat_history_diagnosis --
                                   ORDER BY decode(a.id_task_type, pk_alert_constant.g_task_diagnosis, 1, pk_alert_constant.g_task_problems, 2, 3)) ln
                              FROM (SELECT t.id_task_type,
                                           t.id_diagnosis,
                                           t.id_alert_diagnosis,
                                           t.desc_pat_history_diagnosis,
                                           t.dt_diagnosed,
                                           t.flg_status,
                                           t.flg_type
                                      FROM (
                                            --Getting past medical histoy/problems registered
                                            SELECT pk_problems.get_flg_area_task_type(i_flg_area => phd.flg_area,
                                                                                       i_flg_type => phd.flg_type) id_task_type,
                                                    phd.id_diagnosis,
                                                    phd.id_alert_diagnosis,
                                                    phd.desc_pat_history_diagnosis,
                                                    pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                                            i_prof      => i_prof,
                                                                                            i_date      => phd.dt_diagnosed,
                                                                                            i_precision => decode(phd.dt_diagnosed_precision,
                                                                                                                  pk_past_history.g_date_precision_hour,
                                                                                                                  pk_past_history.g_past_hist_date_precision_day,
                                                                                                                  phd.dt_diagnosed_precision)) dt_diagnosed,
                                                    phd.flg_status,
                                                    phd.flg_area flg_type
                                              FROM pat_history_diagnosis phd
                                             WHERE phd.id_patient = i_patient
                                               AND phd.flg_status IN (pk_problems.g_active, pk_problems.g_passive)
                                               AND phd.id_pat_history_diagnosis_new IS NULL
                                               AND phd.flg_recent_diag = pk_alert_constant.g_yes) t
                                     WHERE t.id_task_type IN
                                           (pk_alert_constant.g_task_problems, pk_alert_constant.g_task_medical_history)
                                    UNION ALL
                                    --Getting past medical history records registered in free text mode
                                    SELECT pk_alert_constant.g_task_medical_history id_task_type,
                                           dea.id_concept_version,
                                           dea.id_concept_term,
                                           to_char(p.text) desc_pat_history_diagnosis,
                                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_date      => p.dt_register,
                                                                                   i_precision => pk_past_history.g_past_hist_date_precision_day) dt_diagnosed,
                                           p.flg_status,
                                           pk_problems.g_ph_medical_hist flg_type
                                    
                                      FROM pat_past_hist_free_text p
                                      JOIN diagnosis_conf_ea dce
                                        ON dce.id_institution = i_prof.institution
                                       AND dce.id_software = i_prof.software
                                       AND dce.id_task_type = pk_alert_constant.g_task_medical_history
                                      JOIN diagnosis_ea dea
                                        ON dea.id_institution = pk_alert_constant.g_inst_all
                                       AND dea.id_software = pk_alert_constant.g_soft_all
                                       AND dea.flg_terminology = dce.flg_terminology
                                       AND dea.flg_diag_type = g_medical_diagnosis_type
                                       AND dea.flg_msi_concept_term = g_searchable_past_hist
                                       AND dea.flg_other = pk_alert_constant.g_yes
                                     WHERE p.id_patient = i_patient
                                       AND p.flg_type = g_medical_diagnosis_type
                                       AND p.flg_status IN (pk_past_history.g_flg_status_active_free_text)
                                    UNION ALL
                                    --Get diagnosis registered in problems area
                                    SELECT pk_alert_constant.g_task_diagnosis id_task_type,
                                           pp.id_diagnosis,
                                           pp.id_alert_diagnosis,
                                           nvl(pp.desc_pat_problem, ed.desc_epis_diagnosis) desc_pat_history_diagnosis,
                                           pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_date      => ed.dt_initial_diag,
                                                                                   i_precision => pk_past_history.g_past_hist_date_precision_day) dt_diagnosed,
                                           pp.flg_status,
                                           pk_problems.g_pat_problem flg_type
                                    /*pk_problems.g_pat_problem:'PP' 
                                    it is for check: create diagnosis and add to problem=> create problem
                                    the same with this(create diagnosis and add to problem)=> cancel the problem
                                    ==>This kind of situation, we need to check, so I set this type 
                                    */
                                      FROM pat_problem pp
                                      JOIN epis_diagnosis ed
                                        ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                                     WHERE pp.id_epis_diagnosis IS NOT NULL
                                       AND pp.flg_status = pk_problems.g_active
                                       AND pp.id_patient = i_patient) a) l
                     WHERE l.ln = 1) b
              JOIN diagnosis d
                ON d.id_diagnosis = b.id_diagnosis
              JOIN alert_diagnosis ad
                ON ad.id_alert_diagnosis = b.id_alert_diagnosis
            --If i_criteria is passed and if the record is free text, returns only related free texts
             WHERE (d.flg_other = pk_alert_constant.g_yes AND b.desc_pat_history_diagnosis LIKE i_criteria || '%')
                OR (d.flg_other = pk_alert_constant.g_no);
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_diag := t_table_diag_cnt();
        END;
    
        RETURN l_tbl_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END;

    /**************************************************************************************************************
    * Gets patient past medical history/Problems and diagnosis registered in problems area information
    *
    * @return                           Returns t_table_diag_cnt with all information
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION get_patient_hist_prob RETURN t_table_diag_cnt IS
        l_func_name VARCHAR2(100 CHAR) := 'GET_PATIENT_HIST_PROB()';
        --
        l_lang             language.id_language%TYPE;
        l_prof             profissional;
        l_patient          patient.id_patient%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    BEGIN
    
        g_error := 'LOAD SEARCH VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.GET_PATIENT_HIST_PROB TO GET ID DIAGNOSIS TABLE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN get_patient_hist_prob(i_lang => l_lang, i_prof => l_prof, i_patient => l_patient);
    
    END;

    FUNCTION get_diagnoses
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN patient.id_patient%TYPE,
        i_text_search                IN VARCHAR2 DEFAULT NULL,
        i_format_text                IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_term_task_type         IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_only_diag_filter_by_prt    IN VARCHAR2 DEFAULT NULL,
        i_context_type               IN VARCHAR2 DEFAULT pk_ts_logic.k_ctx_type_s_searchable,
        i_parent_diagnosis           IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_tbl_alert_diagnosis        IN table_number DEFAULT NULL,
        i_tbl_dep_clin_serv          IN table_number DEFAULT NULL,
        i_tbl_clin_serv              IN table_number DEFAULT NULL,
        i_tbl_complaint              IN table_number DEFAULT NULL,
        i_tbl_id_terminology_version IN table_number,
        i_tbl_adiags_exclude         IN table_number DEFAULT NULL,
        i_diag_area                  IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_not_defined
    ) RETURN t_coll_diagnosis_config IS
        l_tbl_aux     t_coll_diagnosis_config := t_coll_diagnosis_config();
        l_tbl_context table_number := table_number();
    
        l_count NUMBER := 0;
    BEGIN
    
        IF i_tbl_dep_clin_serv.exists(1)
           AND i_context_type = pk_ts_logic.k_ctx_type_d_dep_clin_serv
        THEN
            l_tbl_context := i_tbl_dep_clin_serv;
        ELSIF i_tbl_clin_serv.exists(1)
              AND i_context_type = pk_ts_logic.k_ctx_type_s_clin_serv
        THEN
            l_tbl_context := i_tbl_clin_serv;
        ELSIF i_tbl_complaint.exists(1)
              AND i_context_type = pk_ts_logic.k_ctx_type_c_complaint
        THEN
            l_tbl_context := i_tbl_complaint;
        END IF;
    
        IF i_context_type <> pk_ts_logic.k_ctx_type_s_searchable
        THEN
            l_count := pk_ts3_search.get_terms_count(i_id_language             => i_lang,
                                                     i_id_institution          => i_prof.institution,
                                                     i_id_software             => i_prof.software,
                                                     i_concept_type            => 'DIAGNOSIS',
                                                     i_id_task_types_or        => i_tbl_term_task_type,
                                                     i_context_type            => i_context_type,
                                                     i_id_contexts             => l_tbl_context,
                                                     i_id_terminology_versions => i_tbl_id_terminology_version,
                                                     --i_concept_term_types      => table_varchar(NULL),
                                                     i_flg_select => NULL,
                                                     i_id_patient => i_patient);
        END IF;
    
        IF l_count > 0
           OR i_context_type = pk_ts_logic.k_ctx_type_s_searchable
        THEN
        
            SELECT t_rec_diagnosis_config(id_diagnosis            => id_diagnosis,
                                          id_diagnosis_parent     => NULL,
                                          id_epis_diagnosis       => id_epis_diagnosis,
                                          desc_diagnosis          => desc_translation,
                                          code_icd                => code_icd,
                                          flg_other               => flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => flg_terminology,
                                          flg_diag_type           => NULL,
                                          rank                    => rank,
                                          code_diagnosis          => code_translation,
                                          flg_icd9                => decode(term_type,
                                                                            pk_api_diagnosis_func.g_ctt_int_name_pref,
                                                                            pk_api_diagnosis_func.g_flg_preferred,
                                                                            pk_api_diagnosis_func.g_ctt_int_name_syn,
                                                                            pk_api_diagnosis_func.g_flg_synonym,
                                                                            pk_api_diagnosis_func.g_ctt_int_name_rep,
                                                                            pk_api_diagnosis_func.g_flg_reportable,
                                                                            pk_api_diagnosis_func.g_empty_string),
                                          flg_show_term_code      => NULL,
                                          id_language             => NULL,
                                          flg_status              => NULL,
                                          flg_type                => NULL,
                                          id_tvr_msi              => nvl(id_tvr_msi, -1))
              BULK COLLECT
              INTO l_tbl_aux
              FROM (SELECT t.id_concept_version       id_diagnosis,
                           NULL                       id_epis_diagnosis,
                           t.description              desc_translation,
                           t.code                     code_icd,
                           t.flg_is_free_text         flg_other,
                           t.flg_select,
                           t.id_concept_term          id_alert_diagnosis,
                           tt.termin_version_int_name flg_terminology,
                           t.rank,
                           t.code_translation,
                           t.term_type,
                           t.id_tvr_msi
                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                             *
                              FROM TABLE(pk_ts3_search.tf_search_terms(i_id_language              => i_lang,
                                                                        i_id_institution           => i_prof.institution,
                                                                        i_id_software              => i_prof.software,
                                                                        i_concept_type             => 'DIAGNOSIS',
                                                                        i_id_task_types_or         => i_tbl_term_task_type,
                                                                        i_context_type             => i_context_type,
                                                                        i_id_contexts              => l_tbl_context,
                                                                        i_id_terminology_versions  => i_tbl_id_terminology_version,
                                                                        i_id_concept_terms_filter  => i_tbl_alert_diagnosis,
                                                                        i_id_concept_terms_exclude => i_tbl_adiags_exclude,
                                                                        i_text_search              => i_text_search,
                                                                        i_text_highlight           => i_format_text,
                                                                        i_id_patient               => i_patient,
                                                                        i_flg_load_option          => CASE
                                                                                                          WHEN i_diag_area = pk_alert_constant.g_diag_area_past_history THEN
                                                                                                           pk_ts3_search.k_flg_load_option_all
                                                                                                          ELSE
                                                                                                           pk_ts3_search.k_flg_load_option_partial
                                                                                                      END))) t
                      LEFT JOIN TABLE(pk_ts3_search.tf_get_termin_versions(i_id_language => i_lang, i_id_institution => i_prof.institution, i_id_software => i_prof.software, i_concept_type => 'DIAGNOSIS', i_id_task_types_or => i_tbl_term_task_type)) tt
                        ON tt.id_terminology = t.id_terminology_version)
             WHERE ((nvl(i_only_diag_filter_by_prt, pk_alert_constant.g_no) = pk_alert_constant.g_no) OR
                   (i_only_diag_filter_by_prt = pk_alert_constant.g_yes))
               AND ((nvl(i_only_diag_filter_by_prt, pk_alert_constant.g_no) = pk_alert_constant.g_no AND
                   flg_select = pk_alert_constant.g_yes) OR (i_only_diag_filter_by_prt = pk_alert_constant.g_yes));
        
            RETURN l_tbl_aux;
        
        ELSE
            RETURN t_coll_diagnosis_config();
        END IF;
    END get_diagnoses;

    FUNCTION get_diagnoses_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_tbl_term_task_type       IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL,
        i_tbl_dep_clin_serv        IN table_number DEFAULT NULL,
        i_tbl_clin_serv            IN table_number DEFAULT NULL,
        i_tbl_complaint            IN table_number DEFAULT NULL,
        i_context_type             IN VARCHAR2 DEFAULT pk_ts_logic.k_ctx_type_s_searchable,
        i_diag_area                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_not_defined
    ) RETURN t_coll_diagnosis_config IS
    
        l_func_name CONSTANT VARCHAR2(32) := 'GET_DIAGNOSES_LIST';
        l_tbl_diagnosis t_coll_diagnosis_config;
    BEGIN
    
        g_error := 'GET_DIAGNOSES_LIST - CALL GET_DIAGNOSES_SEARCH';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                      id_diagnosis_parent     => a.id_diagnosis_parent,
                                      id_epis_diagnosis       => a.id_epis_diagnosis,
                                      desc_diagnosis          => a.desc_diagnosis,
                                      code_icd                => a.code_icd,
                                      flg_other               => a.flg_other,
                                      status_diagnosis        => NULL,
                                      icon_status             => NULL,
                                      avail_for_select        => a.flg_select,
                                      default_new_status      => NULL,
                                      default_new_status_desc => NULL,
                                      id_alert_diagnosis      => a.id_alert_diagnosis,
                                      desc_epis_diagnosis     => a.desc_epis_diagnosis,
                                      flg_terminology         => a.flg_terminology,
                                      flg_diag_type           => NULL,
                                      rank                    => a.rank,
                                      code_diagnosis          => NULL,
                                      flg_icd9                => NULL,
                                      flg_show_term_code      => NULL,
                                      id_language             => NULL,
                                      flg_status              => NULL,
                                      flg_type                => NULL,
                                      id_tvr_msi              => a.id_tvr_msi)
          BULK COLLECT
          INTO l_tbl_diagnosis
          FROM (SELECT b.id_diagnosis,
                       b.id_diagnosis_parent,
                       b.desc_translation desc_diagnosis,
                       b.code_icd,
                       b.flg_other,
                       b.flg_select,
                       b.id_alert_diagnosis,
                       b.flg_terminology,
                       b.rank,
                       b.id_tvr_msi,
                       b.id_epis_diagnosis,
                       b.desc_epis_diagnosis
                  FROM TABLE(get_diagnoses_search(i_lang                     => i_lang,
                                                  i_prof                     => i_prof,
                                                  i_patient                  => i_patient,
                                                  i_text_search              => i_text_search,
                                                  i_format_text              => i_format_text,
                                                  i_terminologies_task_types => i_terminologies_task_types,
                                                  i_tbl_term_task_type       => i_tbl_term_task_type,
                                                  i_list_type                => i_list_type,
                                                  i_tbl_alert_diagnosis      => i_tbl_alert_diagnosis,
                                                  i_tbl_terminologies        => i_tbl_terminologies,
                                                  i_row_limit                => i_row_limit,
                                                  i_parent_diagnosis         => i_parent_diagnosis,
                                                  i_only_diag_filter_by_prt  => i_only_diag_filter_by_prt,
                                                  i_tbl_dep_clin_serv        => i_tbl_dep_clin_serv,
                                                  i_tbl_clin_serv            => i_tbl_clin_serv,
                                                  i_tbl_complaint            => i_tbl_complaint,
                                                  i_context_type             => i_context_type,
                                                  i_diag_area                => i_diag_area)) b) a;
    
        RETURN l_tbl_diagnosis;
    
    END get_diagnoses_list;

    FUNCTION get_diagnoses_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_tbl_term_task_type       IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL,
        i_tbl_dep_clin_serv        IN table_number DEFAULT NULL,
        i_tbl_clin_serv            IN table_number DEFAULT NULL,
        i_tbl_complaint            IN table_number DEFAULT NULL,
        i_tbl_adiags_exclude       IN table_number DEFAULT NULL,
        i_context_type             IN VARCHAR2 DEFAULT pk_ts_logic.k_ctx_type_s_searchable,
        i_diag_area                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_not_defined
    ) RETURN t_table_diag_cnt IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_DIAGNOSES_SEARCH';
        --
        l_tbl_diagnoses     t_table_diag_cnt;
        l_tbl_search_result t_table_diag_cnt;
        --
        l_pat_age    NUMBER;
        l_pat_gender patient.gender%TYPE;
        --
        l_tbl_flg_terminologies table_varchar;
        l_inst                  institution.id_institution%TYPE;
        l_soft                  software.id_software%TYPE;
        --
        l_format_text VARCHAR2(1 CHAR);
        --
        l_tbl_prof_dep_clin_serv table_number;
        --
        l_validate_max_age VARCHAR2(1 CHAR);
        --        
        l_flg_type_dep_clin diagnosis_content.flg_type_dep_clin%TYPE;
        --      
        l_tbl_id_terminology_version table_number := table_number();
        l_tbl_aux                    t_coll_diagnosis_config := t_coll_diagnosis_config();
    BEGIN
    
        g_error := 'CALL GET_DIAGNOSES_DEFAULT_ARGS_NEW';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        get_diagnoses_default_args_new(i_lang                     => i_lang,
                                       i_prof                     => i_prof,
                                       i_patient                  => i_patient,
                                       i_format_text              => i_format_text,
                                       i_terminologies_task_types => i_terminologies_task_types,
                                       i_tbl_term_task_type       => i_tbl_term_task_type,
                                       i_list_type                => i_list_type,
                                       i_tbl_terminologies        => i_tbl_terminologies,
                                       o_inst                     => l_inst,
                                       o_soft                     => l_soft,
                                       o_pat_age                  => l_pat_age,
                                       o_pat_gender               => l_pat_gender,
                                       o_tbl_flg_terminologies    => l_tbl_flg_terminologies,
                                       o_flg_type_dep_clin        => l_flg_type_dep_clin,
                                       o_tbl_prof_dep_clin_serv   => l_tbl_prof_dep_clin_serv,
                                       o_format_text              => l_format_text,
                                       o_validate_max_age         => l_validate_max_age);
    
        --Obtain the list of terminologies ids to be used on the Terminology Server 
        --(The old model used the terminology flags instead of ids)        
        IF l_tbl_flg_terminologies.exists(1)
        THEN
            SELECT tv.id_terminology_version
              BULK COLLECT
              INTO l_tbl_id_terminology_version
              FROM TABLE(pk_ts3_search.tf_get_termin_versions(i_id_language      => i_lang,
                                                              i_id_institution   => l_inst,
                                                              i_id_software      => l_soft,
                                                              i_concept_type     => 'DIAGNOSIS',
                                                              i_id_task_types_or => i_tbl_term_task_type)) tv
             WHERE tv.termin_version_int_name IN
                   (SELECT /*+ opt_estimate(table t rows=1)*/
                     *
                      FROM TABLE(l_tbl_flg_terminologies) t);
        END IF;
    
        IF i_list_type = g_diag_list_searchable
        THEN
            IF i_text_search IS NOT NULL
            THEN
                g_error := 'SEARCHABLE DIAGNOSES - FILTER DIAGNOSIS_CONTENT BY USER INPUT TEXT: ' || i_text_search;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_tbl_aux := get_diagnoses(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_patient                 => i_patient,
                                           i_text_search             => i_text_search,
                                           i_format_text             => l_format_text,
                                           i_tbl_term_task_type      => i_tbl_term_task_type,
                                           i_only_diag_filter_by_prt => i_only_diag_filter_by_prt,
                                           i_context_type            => i_context_type,
                                           i_parent_diagnosis        => i_parent_diagnosis,
                                           --i_tbl_diagnosis              => i_tbl_diagnosis,
                                           i_tbl_alert_diagnosis        => i_tbl_alert_diagnosis,
                                           i_tbl_dep_clin_serv          => i_tbl_dep_clin_serv,
                                           i_tbl_clin_serv              => i_tbl_clin_serv,
                                           i_tbl_complaint              => i_tbl_complaint,
                                           i_tbl_id_terminology_version => l_tbl_id_terminology_version,
                                           i_tbl_adiags_exclude         => i_tbl_adiags_exclude,
                                           i_diag_area                  => i_diag_area);
            
                IF i_row_limit IS NULL
                THEN
                    SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                          id_diagnosis_parent => t.id_diagnosis_parent,
                                          id_alert_diagnosis  => t.id_alert_diagnosis,
                                          code_icd            => t.code_icd,
                                          id_language         => t.id_language,
                                          code_translation    => t.code_diagnosis,
                                          desc_translation    => t.desc_diagnosis,
                                          desc_epis_diagnosis => t.desc_epis_diagnosis,
                                          flg_other           => t.flg_other,
                                          flg_icd9            => t.flg_icd9,
                                          flg_select          => t.avail_for_select,
                                          id_dep_clin_serv    => NULL,
                                          flg_terminology     => t.flg_terminology,
                                          rank                => t.rank,
                                          id_term_task_type   => NULL, --l_term_task_type,
                                          flg_show_term_code  => t.flg_show_term_code,
                                          id_epis_diagnosis   => t.id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => pk_alert_constant.g_diag_new_search_mechanism,
                                          id_tvr_msi          => t.id_tvr_msi)
                      BULK COLLECT
                      INTO l_tbl_search_result
                      FROM TABLE(l_tbl_aux) t;
                
                ELSE
                    SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                          id_diagnosis_parent => t.id_diagnosis_parent,
                                          id_alert_diagnosis  => t.id_alert_diagnosis,
                                          code_icd            => t.code_icd,
                                          id_language         => t.id_language,
                                          code_translation    => t.code_diagnosis,
                                          desc_translation    => t.desc_diagnosis,
                                          desc_epis_diagnosis => t.desc_epis_diagnosis,
                                          flg_other           => t.flg_other,
                                          flg_icd9            => t.flg_icd9,
                                          flg_select          => t.avail_for_select,
                                          id_dep_clin_serv    => NULL,
                                          flg_terminology     => t.flg_terminology,
                                          rank                => t.rank,
                                          id_term_task_type   => NULL, --l_term_task_type,
                                          flg_show_term_code  => t.flg_show_term_code,
                                          id_epis_diagnosis   => t.id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => pk_alert_constant.g_diag_new_search_mechanism,
                                          id_tvr_msi          => t.id_tvr_msi)
                      BULK COLLECT
                      INTO l_tbl_search_result
                      FROM (SELECT /*+opt_estimate(TABLE, v, rows = 100)*/
                             *
                              FROM TABLE(l_tbl_aux)
                             ORDER BY rank ASC) t
                     WHERE rownum <= i_row_limit
                        OR t.flg_other = pk_alert_constant.g_yes;
                END IF;
            
                l_tbl_diagnoses := l_tbl_search_result;
            ELSE
                --SEARCHABLE SEM TEXTO DE PESQUISA            
                l_tbl_aux := get_diagnoses(i_lang                       => i_lang,
                                           i_prof                       => i_prof,
                                           i_patient                    => i_patient,
                                           i_text_search                => i_text_search,
                                           i_format_text                => l_format_text,
                                           i_tbl_term_task_type         => i_tbl_term_task_type,
                                           i_only_diag_filter_by_prt    => i_only_diag_filter_by_prt,
                                           i_context_type               => i_context_type,
                                           i_parent_diagnosis           => i_parent_diagnosis,
                                           i_tbl_alert_diagnosis        => i_tbl_alert_diagnosis,
                                           i_tbl_dep_clin_serv          => i_tbl_dep_clin_serv,
                                           i_tbl_clin_serv              => i_tbl_clin_serv,
                                           i_tbl_complaint              => i_tbl_complaint,
                                           i_tbl_id_terminology_version => l_tbl_id_terminology_version,
                                           i_tbl_adiags_exclude         => i_tbl_adiags_exclude,
                                           i_diag_area                  => i_diag_area);
            
                IF i_row_limit IS NULL
                THEN
                    SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                          id_diagnosis_parent => t.id_diagnosis_parent,
                                          id_alert_diagnosis  => t.id_alert_diagnosis,
                                          code_icd            => t.code_icd,
                                          id_language         => t.id_language,
                                          code_translation    => t.code_diagnosis,
                                          desc_translation    => t.desc_diagnosis,
                                          desc_epis_diagnosis => t.desc_epis_diagnosis,
                                          flg_other           => t.flg_other,
                                          flg_icd9            => t.flg_icd9,
                                          flg_select          => t.avail_for_select,
                                          id_dep_clin_serv    => NULL,
                                          flg_terminology     => t.flg_terminology,
                                          rank                => t.rank,
                                          id_term_task_type   => NULL, --l_term_task_type,
                                          flg_show_term_code  => t.flg_show_term_code,
                                          id_epis_diagnosis   => t.id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => pk_alert_constant.g_diag_new_search_mechanism,
                                          id_tvr_msi          => t.id_tvr_msi)
                      BULK COLLECT
                      INTO l_tbl_diagnoses
                      FROM TABLE(l_tbl_aux) t;
                ELSE
                    SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                          id_diagnosis_parent => t.id_diagnosis_parent,
                                          id_alert_diagnosis  => t.id_alert_diagnosis,
                                          code_icd            => t.code_icd,
                                          id_language         => t.id_language,
                                          code_translation    => t.code_diagnosis,
                                          desc_translation    => t.desc_diagnosis,
                                          desc_epis_diagnosis => t.desc_epis_diagnosis,
                                          flg_other           => t.flg_other,
                                          flg_icd9            => t.flg_icd9,
                                          flg_select          => t.avail_for_select,
                                          id_dep_clin_serv    => NULL,
                                          flg_terminology     => t.flg_terminology,
                                          rank                => t.rank,
                                          id_term_task_type   => NULL, --l_term_task_type,
                                          flg_show_term_code  => t.flg_show_term_code,
                                          id_epis_diagnosis   => t.id_epis_diagnosis,
                                          flg_status          => NULL,
                                          flg_type            => NULL,
                                          flg_mechanism       => pk_alert_constant.g_diag_new_search_mechanism,
                                          id_tvr_msi          => t.id_tvr_msi)
                      BULK COLLECT
                      INTO l_tbl_diagnoses
                      FROM (SELECT /*+opt_estimate(TABLE, v, rows = 100)*/
                             *
                              FROM TABLE(l_tbl_aux)
                             ORDER BY rank ASC) t
                     WHERE rownum <= i_row_limit
                        OR t.flg_other = pk_alert_constant.g_yes;
                END IF;
            END IF;
        ELSE
            --NOT SEARCHABLE (MOST FREQUENT BY CLINICAL SERVICE)        
            g_error := 'MOST FREQUENT DIAGNOSES - FILTER BY USER INPUT TEXT: ' || i_text_search || '; ' || CASE
                           WHEN i_row_limit IS NOT NULL THEN
                            'RETURN FIRST ' || i_row_limit || ' ROWS'
                           ELSE
                            'RETURN ALL CONTENT'
                       END;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_tbl_aux := get_diagnoses(i_lang                       => i_lang,
                                       i_prof                       => i_prof,
                                       i_patient                    => i_patient,
                                       i_text_search                => i_text_search,
                                       i_format_text                => l_format_text,
                                       i_tbl_term_task_type         => i_tbl_term_task_type,
                                       i_context_type               => pk_ts_logic.k_ctx_type_d_dep_clin_serv,
                                       i_tbl_dep_clin_serv          => l_tbl_prof_dep_clin_serv,
                                       i_tbl_id_terminology_version => l_tbl_id_terminology_version,
                                       i_tbl_adiags_exclude         => i_tbl_adiags_exclude,
                                       i_diag_area                  => i_diag_area);
        
            SELECT t_rec_diag_cnt(id_diagnosis        => t.id_diagnosis,
                                  id_diagnosis_parent => t.id_diagnosis_parent,
                                  id_alert_diagnosis  => t.id_alert_diagnosis,
                                  code_icd            => t.code_icd,
                                  id_language         => t.id_language,
                                  code_translation    => t.code_diagnosis,
                                  desc_translation    => t.desc_diagnosis,
                                  desc_epis_diagnosis => t.desc_epis_diagnosis,
                                  flg_other           => t.flg_other,
                                  flg_icd9            => t.flg_icd9,
                                  flg_select          => t.avail_for_select,
                                  id_dep_clin_serv    => NULL,
                                  flg_terminology     => t.flg_terminology,
                                  rank                => t.rank,
                                  id_term_task_type   => NULL, --l_term_task_type,
                                  flg_show_term_code  => t.flg_show_term_code,
                                  id_epis_diagnosis   => t.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => pk_alert_constant.g_diag_new_search_mechanism,
                                  id_tvr_msi          => t.id_tvr_msi)
              BULK COLLECT
              INTO l_tbl_diagnoses
              FROM (SELECT /*+opt_estimate(TABLE, v, rows = 100)*/
                     *
                      FROM TABLE(l_tbl_aux)
                     ORDER BY rank ASC) t
             WHERE i_row_limit IS NULL
                OR t.flg_other = pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_tbl_diagnoses;
    END get_diagnoses_search;

    /**************************************************************************************************************
    * Patient problems and past history table function
    *
    * @return                           Returns patient's problems and past history
    *                                   (used in the differential and final diagnoses screens filters)
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION tf_patient_hist_prob(i_filter_diagnosis IN VARCHAR2 DEFAULT pk_alert_constant.g_yes)
        RETURN t_coll_diagnosis_config IS
    
        --
        l_lang             language.id_language%TYPE;
        l_prof             profissional;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
        --
        l_tbl_pmh_p_diagnosis table_number;
        l_tbl_pmh_p_adiags    table_number;
        l_tbl_diagnosis       t_table_diag_cnt;
        l_tbl_aux_diagnosis   t_table_diag_cnt;
        l_tbl_pat_hist_prob   t_table_diag_cnt;
    
        l_prob_mechanism sys_config.value%TYPE;
        --
        l_func_name VARCHAR2(100 CHAR) := 'TF_PATIENT_HIST_PROB';
        l_error     t_error_out;
    BEGIN
        g_error := '1- LOAD SEARCH VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        g_error := '2- LOADED VALUES - l_lang: ' || l_lang || ', l_patient: ' || l_patient || ', l_prof.id: ' ||
                   l_prof.id || ', l_prof.institution: ' || l_prof.institution || ', l_prof.software: ' ||
                   l_prof.software || ', l_episode: ' || l_episode || ', l_text_search: ' || l_text_search ||
                   ', l_epis_diag_type : ' || l_epis_diag_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := '3- CALL GET_PATIENT_HIST_PROB';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_tbl_pat_hist_prob := get_patient_hist_prob(i_lang     => l_lang,
                                                     i_prof     => l_prof,
                                                     i_patient  => l_patient,
                                                     i_criteria => l_text_search);
    
        g_error := '4- FILL TBL DIAGS AND ADIAGS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        SELECT t.id_diagnosis, t.id_alert_diagnosis
          BULK COLLECT
          INTO l_tbl_pmh_p_diagnosis, l_tbl_pmh_p_adiags
          FROM TABLE(l_tbl_pat_hist_prob) t;
    
        g_error := '5- VERIFY IF PATIENT HAVE FINAL DIAGNOSES REGISTERED';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_tbl_pmh_p_diagnosis.exists(1)
           AND l_tbl_pmh_p_adiags.exists(1)
        THEN
            g_error := '6- GET DIAGNOSES LIST FILTERED';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            l_prob_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_problems_search_mechanism, l_prof);
        
            IF l_prob_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                l_tbl_diagnosis := get_diagnoses_search(i_lang                     => l_lang,
                                                        i_prof                     => l_prof,
                                                        i_patient                  => l_patient,
                                                        i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                        i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_problems),
                                                        i_list_type                => g_diag_list_searchable,
                                                        i_text_search              => l_text_search,
                                                        i_tbl_alert_diagnosis      => l_tbl_pmh_p_adiags);
            ELSE
            
                l_tbl_diagnosis := pk_terminology_search.tf_diagnoses_search(i_lang                     => l_lang,
                                                                             i_prof                     => l_prof,
                                                                             i_patient                  => l_patient,
                                                                             i_terminologies_task_types => table_number(pk_alert_constant.g_task_problems),
                                                                             i_term_task_type           => pk_alert_constant.g_task_problems,
                                                                             i_list_type                => g_diag_list_searchable,
                                                                             i_text_search              => l_text_search,
                                                                             i_tbl_diagnosis            => l_tbl_pmh_p_diagnosis,
                                                                             i_tbl_alert_diagnosis      => l_tbl_pmh_p_adiags);
            END IF;
        
            IF l_tbl_diagnosis.exists(1)
            THEN
                g_error := '7- FILL OTHER_DIAG RECORDS WITH SAVED FREE_TEXT';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                SELECT t_rec_diag_cnt(id_diagnosis        => d.id_diagnosis,
                                      id_diagnosis_parent => d.id_diagnosis_parent,
                                      id_alert_diagnosis  => d.id_alert_diagnosis,
                                      code_icd            => d.code_icd,
                                      id_language         => d.id_language,
                                      code_translation    => d.code_translation,
                                      desc_translation    => decode(d.flg_other,
                                                                    pk_alert_constant.g_yes,
                                                                    php.desc_translation,
                                                                    d.desc_translation),
                                      desc_epis_diagnosis => php.desc_epis_diagnosis,
                                      flg_other           => d.flg_other,
                                      flg_icd9            => d.flg_icd9,
                                      flg_select          => d.flg_select,
                                      id_dep_clin_serv    => d.id_dep_clin_serv,
                                      flg_terminology     => d.flg_terminology,
                                      rank                => d.rank,
                                      id_term_task_type   => d.id_term_task_type,
                                      flg_show_term_code  => d.flg_show_term_code,
                                      id_epis_diagnosis   => php.id_epis_diagnosis,
                                      flg_status          => php.flg_status,
                                      flg_type            => php.flg_type,
                                      flg_mechanism       => NULL,
                                      id_tvr_msi          => d.id_tvr_msi)
                  BULK COLLECT
                  INTO l_tbl_aux_diagnosis
                  FROM TABLE(l_tbl_diagnosis) d
                  JOIN TABLE(l_tbl_pat_hist_prob) php
                --   ON php.id_diagnosis = d.id_diagnosis
                    ON php.id_alert_diagnosis = d.id_alert_diagnosis
                 WHERE (pk_diagnosis_core.check_if_diag_registered(i_lang                => l_lang,
                                                                   i_prof                => l_prof,
                                                                   i_episode             => l_episode,
                                                                   i_diagnosis           => php.id_diagnosis,
                                                                   i_flg_type            => pk_diagnosis.g_diag_type_d,
                                                                   i_desc_diag           => php.desc_translation,
                                                                   i_diagnosis_condition => NULL,
                                                                   i_sub_analysis        => NULL,
                                                                   i_anatomical_area     => NULL,
                                                                   i_anatomical_side     => NULL) =
                       pk_alert_constant.g_no AND i_filter_diagnosis = pk_alert_constant.g_yes)
                    OR i_filter_diagnosis = pk_alert_constant.g_no;
            
                l_tbl_diagnosis := l_tbl_aux_diagnosis;
            ELSE
                l_tbl_diagnosis := t_table_diag_cnt();
            END IF;
        ELSE
            l_tbl_diagnosis := t_table_diag_cnt();
        END IF;
    
        g_error := '10- CALL PK_TERMINOLOGY_SEARCH.GET_T_COLL_DIAGNOSIS_CONFIG TO PARSE L_TBL_DIAGNOSIS TO T_COLL_DIAGNOSIS_CONFIG OBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN get_t_coll_diagnosis_config(i_prof                   => l_prof,
                                           i_episode                => l_episode,
                                           i_diag_type              => l_epis_diag_type,
                                           i_tbl_diagnosis          => l_tbl_diagnosis,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_no,
                                           i_diagnoses_mechanism    => l_prob_mechanism);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_patient_hist_prob;

    /**************************************************************************************************************
    * Gets most frequent diagnosis by diagnosis type (C - Chief Complaint, M - Clinical Service)
    *
    * @return                           Returns the most frequent diagnosis table by diagnosis type
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_get_diagnosis_by_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_type    IN diagnosis_dep_clin_serv.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_text_search IN translation.desc_lang_1%TYPE,
        i_diag_type   IN epis_diagnosis.flg_type%TYPE
    ) RETURN t_coll_diagnosis_config IS
    
        l_tbl_complaint_diags  table_number;
        l_tbl_complaint_adiags table_number;
        l_tbl_diagnosis        t_table_diag_cnt;
        l_id_complaint         table_number;
    
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    
        l_func_name VARCHAR2(100 CHAR) := 'PK_TERMINOLOGY_SEARCH.TF_GET_DIAGNOSIS_BY_TYPE';
        l_error     t_error_out;
    BEGIN
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => i_prof);
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, i_prof);
    
        IF i_flg_type = pk_diagnosis_core.g_filter_freq
        THEN
            g_error := 'CHECK CONTENT AVAILABILITY';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
            THEN
                l_tbl_diagnosis := get_diagnoses_search(i_lang                     => i_lang,
                                                        i_prof                     => i_prof,
                                                        i_patient                  => i_patient,
                                                        i_text_search              => i_text_search,
                                                        i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_diagnosis),
                                                        i_list_type                => g_diag_list_most_freq);
            ELSE
                l_tbl_diagnosis := tf_diagnoses_search(i_lang                     => i_lang,
                                                       i_prof                     => i_prof,
                                                       i_patient                  => i_patient,
                                                       i_text_search              => i_text_search,
                                                       i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                       i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                       i_flg_show_term_code       => l_flg_show_term_code,
                                                       i_list_type                => g_diag_list_most_freq);
            END IF;
        ELSIF i_flg_type = pk_diagnosis_core.g_filter_complaint
        THEN
        
            g_error := 'GET CHIEF COMPLAINT IDENTIFIER  - i_patient:' || i_patient || ' i_episode:' || i_episode;
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        
            IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_episode,
                                                       o_id_complaint => l_id_complaint,
                                                       o_error        => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_id_complaint IS NOT NULL
               AND l_id_complaint.count > 0
            THEN
                g_error := 'GET DIAGS BY CHIEF COMPLAINT';
                alertlog.pk_alertlog.log_info(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
            
                IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
                THEN
                    l_tbl_diagnosis := get_diagnoses_search(i_lang                     => i_lang,
                                                            i_prof                     => i_prof,
                                                            i_patient                  => i_patient,
                                                            i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                            i_tbl_term_task_type       => table_number(pk_alert_constant.g_task_diagnosis),
                                                            i_list_type                => g_diag_list_searchable,
                                                            i_text_search              => i_text_search,
                                                            i_tbl_complaint            => l_id_complaint,
                                                            i_context_type             => pk_ts_logic.k_ctx_type_c_complaint);
                
                ELSE
                    BEGIN
                        SELECT t.id_diagnosis,
                               pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => t.id_diagnosis) id_alert_diagnosis
                          BULK COLLECT
                          INTO l_tbl_complaint_diags, l_tbl_complaint_adiags
                          FROM (SELECT DISTINCT cd.id_diagnosis
                                  FROM doc_template_diagnosis cd
                                 WHERE cd.id_complaint IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                            *
                                                             FROM TABLE(l_id_complaint) t)
                                   AND EXISTS (SELECT 1
                                          FROM diagnosis_ea e
                                          JOIN diagnosis_conf_ea c
                                            ON c.flg_terminology = e.flg_terminology
                                           AND c.id_institution = e.id_institution
                                           AND c.id_software = e.id_software
                                           AND c.id_task_type = pk_alert_constant.g_task_diagnosis
                                         WHERE e.id_institution = i_prof.institution
                                           AND e.id_software = i_prof.software
                                           AND e.flg_msi_concept_term = g_searchable_diag --searchable_diags
                                           AND e.flg_diag_type = g_medical_diagnosis_type --medical_diags
                                           AND e.id_concept_version = cd.id_diagnosis)
                                   AND cd.flg_available = pk_alert_constant.g_available) t;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_tbl_complaint_diags  := table_number();
                            l_tbl_complaint_adiags := table_number();
                    END;
                
                    IF l_tbl_complaint_diags.exists(1)
                       AND l_tbl_complaint_adiags.exists(1)
                    THEN
                        g_error := 'CHECK CONTENT AVAILABILITY';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package,
                                                      sub_object_name => l_func_name);
                    
                        l_tbl_diagnosis := tf_diagnoses_search(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_flg_show_term_code       => l_flg_show_term_code,
                                                               i_list_type                => g_diag_list_searchable,
                                                               i_text_search              => i_text_search,
                                                               i_tbl_diagnosis            => l_tbl_complaint_diags,
                                                               i_tbl_alert_diagnosis      => l_tbl_complaint_adiags);
                    ELSE
                        l_tbl_diagnosis := t_table_diag_cnt();
                    END IF;
                END IF;
            END IF;
        ELSE
            l_tbl_diagnosis := t_table_diag_cnt();
        END IF;
    
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.GET_T_COLL_DIAGNOSIS_CONFIG TO PARSE L_TBL_DIAGNOSIS TO T_COLL_DIAGNOSIS_CONFIG OBJECT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN get_t_coll_diagnosis_config(i_prof                   => i_prof,
                                           i_episode                => i_episode,
                                           i_diag_type              => i_diag_type,
                                           i_tbl_diagnosis          => l_tbl_diagnosis,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_no,
                                           i_diagnoses_mechanism    => l_diagnoses_mechanism);
    END tf_get_diagnosis_by_type;

    /**************************************************************************************************************
    * Get most frequent patient diagnoses/problems by chief complaint
    *
    * @return                           Returns the most frequent diagnoses by clinical service
    *                                   (used in the differential and final diagnoses screens filters)
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_complaint_diagnoses RETURN t_coll_diagnosis_config IS
        l_lang             language.id_language%TYPE;
        l_prof             profissional;
        l_patient          patient.id_patient%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_func_name VARCHAR2(100 CHAR) := 'TF_COMPLAINT_DIAGNOSES';
        l_error     t_error_out;
    BEGIN
        g_error := 'LOAD SEARCH VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        g_error := 'LOADED VALUES - l_lang: ' || l_lang || ', l_patient: ' || l_patient || ', l_prof.id: ' || l_prof.id ||
                   ', l_prof.institution: ' || l_prof.institution || ', l_prof.software: ' || l_prof.software ||
                   ', l_episode: ' || l_episode || ', l_text_search: ' || l_text_search || ', l_epis_diag_type : ' ||
                   l_epis_diag_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.TF_GET_DIAGNOSIS_BY_TYPE - BY CHIEF COMPLAINT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        RETURN tf_get_diagnosis_by_type(i_lang        => l_lang,
                                        i_prof        => l_prof,
                                        i_patient     => l_patient,
                                        i_flg_type    => pk_diagnosis_core.g_filter_complaint,
                                        i_episode     => l_episode,
                                        i_text_search => l_text_search,
                                        i_diag_type   => l_epis_diag_type);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END tf_complaint_diagnoses;

    /**************************************************************************************************************
    * Get most frequent patient diagnoses/problems by clinical service
    *
    * @return                           Returns the most frequent diagnoses by clinical service
    *                                   (used in the differential and final diagnoses screens filters)
    *
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_clin_serv_diagnoses RETURN t_coll_diagnosis_config IS
    
        l_lang             language.id_language%TYPE;
        l_prof             profissional;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_text_search      translation.desc_lang_1%TYPE;
        l_epis_diag_type   epis_diagnosis.flg_type%TYPE;
    
        l_func_name VARCHAR2(100 CHAR) := 'TF_CLIN_SERV_DIAGNOSES';
        l_error     t_error_out;
    BEGIN
        g_error := 'LOAD SEARCH VALUES - TF_CLIN_SERV_DIAGNOSES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        g_error := 'LOADED VALUES - l_lang: ' || l_lang || ', l_patient: ' || l_patient || ', l_prof.id: ' || l_prof.id ||
                   ', l_prof.institution: ' || l_prof.institution || ', l_prof.software: ' || l_prof.software ||
                   ', l_episode: ' || l_episode || ', l_text_search: ' || l_text_search || ', l_epis_diag_type : ' ||
                   l_epis_diag_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.TF_GET_DIAGNOSIS_BY_TYPE - BY CLINICAL SERVICE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN tf_get_diagnosis_by_type(i_lang        => l_lang,
                                        i_prof        => l_prof,
                                        i_patient     => l_patient,
                                        i_flg_type    => pk_diagnosis_core.g_filter_freq,
                                        i_episode     => l_episode,
                                        i_text_search => l_text_search,
                                        i_diag_type   => l_epis_diag_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END;

    /**************************************************************************************************************
    * Returns all diagnoses content
    *
    * @return                           Returns the all diagnoses
    *                                   (used in v_diagnosis_all_content)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_all_diagnoses RETURN t_coll_diagnosis_config IS
        l_func_name          VARCHAR2(30 CHAR) := 'TF_ALL_DIAGNOSES';
        l_lang               language.id_language%TYPE;
        l_patient            patient.id_patient%TYPE;
        l_prof               profissional;
        l_episode            episode.id_episode%TYPE;
        l_text_search        translation.desc_lang_1%TYPE;
        l_profile_template   profile_template.id_profile_template%TYPE;
        l_epis_diag_type     epis_diagnosis.flg_type%TYPE;
        l_tbl_diagnosis      t_coll_diagnosis_config;
        l_flg_show_term_code sys_config.value%TYPE;
    
        l_diagnoses_mechanism sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD SEARCH VALUES - TF_ALL_DIAGNOSES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        load_search_values(o_lang             => l_lang,
                           o_prof             => l_prof,
                           o_profile_template => l_profile_template,
                           o_id_patient       => l_patient,
                           o_episode          => l_episode,
                           o_text_search      => l_text_search,
                           o_epis_diag_type   => l_epis_diag_type);
    
        l_flg_show_term_code := pk_sysconfig.get_config(i_code_cf => pk_diagnosis.g_sys_config_show_term_diagnos,
                                                        i_prof    => l_prof);
    
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, l_prof);
    
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
            g_error := 'TF_ALL_DIAGNOSES CALL GET_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                          id_diagnosis_parent     => a.id_diagnosis_parent,
                                          id_epis_diagnosis       => NULL,
                                          desc_diagnosis          => a.desc_translation,
                                          code_icd                => a.code_icd,
                                          flg_other               => a.flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => a.flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => a.id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => a.flg_terminology,
                                          flg_diag_type           => NULL,
                                          rank                    => a.rank,
                                          code_diagnosis          => a.code_translation,
                                          flg_icd9                => a.flg_icd9,
                                          flg_show_term_code      => a.flg_show_term_code,
                                          id_language             => a.id_language,
                                          flg_status              => NULL,
                                          flg_type                => NULL,
                                          id_tvr_msi              => a.id_tvr_msi)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM (SELECT b.*
                      FROM (TABLE(get_diagnoses_search(i_lang        => l_lang,
                                                       i_prof        => l_prof,
                                                       i_patient     => l_patient,
                                                       i_text_search => l_text_search,
                                                       i_list_type   => g_diag_list_searchable)) b)) a;
        
        ELSE
            g_error := 'TF_ALL_DIAGNOSES CALL TF_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                          id_diagnosis_parent     => a.id_diagnosis_parent,
                                          id_epis_diagnosis       => NULL,
                                          desc_diagnosis          => a.desc_translation,
                                          code_icd                => a.code_icd,
                                          flg_other               => a.flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => a.flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => a.id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => a.flg_terminology,
                                          flg_diag_type           => NULL,
                                          rank                    => a.rank,
                                          code_diagnosis          => a.code_translation,
                                          flg_icd9                => a.flg_icd9,
                                          flg_show_term_code      => a.flg_show_term_code,
                                          id_language             => a.id_language)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM (SELECT b.*
                      FROM (TABLE(pk_terminology_search.tf_diagnoses_search(i_lang               => l_lang,
                                                                            i_prof               => l_prof,
                                                                            i_patient            => l_patient,
                                                                            i_text_search        => l_text_search,
                                                                            i_list_type          => g_diag_list_searchable,
                                                                            i_flg_show_term_code => l_flg_show_term_code)) b)) a;
        END IF;
    
        RETURN l_tbl_diagnosis;
    END tf_all_diagnoses;

    /**************************************************************************************************************
    * Validates if a diagnosis record content is valid considering current terminology configuration
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional information
    * @param i_tbl_epis_diagnosis   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_diagnoses
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_tbl_epis_diagnosis IN table_number
    ) RETURN t_coll_diagnosis_config IS
        l_tbl_diagnosis       t_table_diag_cnt;
        l_diagnoses_mechanism sys_config.value%TYPE;
    BEGIN
        l_diagnoses_mechanism := pk_sysconfig.get_config(pk_alert_constant.g_diagnoses_search_mechanism, i_prof);
        IF l_diagnoses_mechanism = pk_alert_constant.g_diag_new_search_mechanism
        THEN
        
            SELECT t_rec_diag_cnt(id_diagnosis        => tf.id_diagnosis,
                                  id_diagnosis_parent => tf.id_diagnosis_parent,
                                  id_alert_diagnosis  => tf.id_alert_diagnosis,
                                  code_icd            => tf.code_icd,
                                  id_language         => tf.id_language,
                                  code_translation    => tf.code_translation,
                                  desc_translation    => nvl(tf.desc_translation,
                                                             pk_translation.get_translation(i_lang      => tf.id_language,
                                                                                            i_code_mess => tf.code_translation)),
                                  desc_epis_diagnosis => tf.desc_epis_diagnosis,
                                  flg_other           => tf.flg_other,
                                  flg_icd9            => tf.flg_icd9,
                                  flg_select          => tf.flg_select,
                                  id_dep_clin_serv    => tf.id_dep_clin_serv,
                                  flg_terminology     => tf.flg_terminology,
                                  rank                => tf.rank,
                                  id_term_task_type   => tf.id_term_task_type,
                                  flg_show_term_code  => tf.flg_show_term_code,
                                  id_epis_diagnosis   => ed.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => tf.flg_mechanism)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM epis_diagnosis ed
              JOIN TABLE(pk_terminology_search.get_diagnoses_search(i_lang => i_lang, i_prof => i_prof, i_patient => ed.id_patient, i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis), i_tbl_term_task_type => table_number(pk_alert_constant.g_task_diagnosis), i_list_type => pk_diagnosis_core.g_diag_list_searchable, i_tbl_alert_diagnosis => table_number(ed.id_alert_diagnosis))) tf
            --ON tf.id_diagnosis = ed.id_diagnosis
                ON tf.id_alert_diagnosis = ed.id_alert_diagnosis
             WHERE ed.id_epis_diagnosis IN (SELECT column_value id_epis_diagnosis
                                              FROM TABLE(i_tbl_epis_diagnosis));
        ELSE
            SELECT t_rec_diag_cnt(id_diagnosis        => tf.id_diagnosis,
                                  id_diagnosis_parent => tf.id_diagnosis_parent,
                                  id_alert_diagnosis  => tf.id_alert_diagnosis,
                                  code_icd            => tf.code_icd,
                                  id_language         => tf.id_language,
                                  code_translation    => tf.code_translation,
                                  desc_translation    => nvl(tf.desc_translation,
                                                             pk_translation.get_translation(i_lang      => tf.id_language,
                                                                                            i_code_mess => tf.code_translation)),
                                  desc_epis_diagnosis => tf.desc_epis_diagnosis,
                                  flg_other           => tf.flg_other,
                                  flg_icd9            => tf.flg_icd9,
                                  flg_select          => tf.flg_select,
                                  id_dep_clin_serv    => tf.id_dep_clin_serv,
                                  flg_terminology     => tf.flg_terminology,
                                  rank                => tf.rank,
                                  id_term_task_type   => tf.id_term_task_type,
                                  flg_show_term_code  => tf.flg_show_term_code,
                                  id_epis_diagnosis   => ed.id_epis_diagnosis,
                                  flg_status          => NULL,
                                  flg_type            => NULL,
                                  flg_mechanism       => tf.flg_mechanism)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM epis_diagnosis ed
              JOIN TABLE(pk_terminology_search.tf_diagnoses_search(i_lang => i_lang, i_prof => i_prof, i_patient => ed.id_patient, i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis), i_term_task_type => pk_alert_constant.g_task_diagnosis, i_list_type => pk_terminology_search.g_diag_list_searchable, i_text_search => NULL, i_tbl_diagnosis => table_number(ed.id_diagnosis), i_tbl_alert_diagnosis => table_number(ed.id_alert_diagnosis))) tf
                ON tf.id_diagnosis = ed.id_diagnosis
               AND tf.id_alert_diagnosis = ed.id_alert_diagnosis
             WHERE ed.id_epis_diagnosis IN (SELECT column_value id_epis_diagnosis
                                              FROM TABLE(i_tbl_epis_diagnosis));
        
        END IF;
        RETURN get_t_coll_diagnosis_config(i_prof                   => i_prof,
                                           i_episode                => NULL,
                                           i_diag_type              => NULL,
                                           i_tbl_diagnosis          => l_tbl_diagnosis,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_yes,
                                           i_diagnoses_mechanism    => l_diagnoses_mechanism);
    END tf_get_valid_diagnoses;

    /**************************************************************************************************************
    * Validates if a record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    * @param i_task_type               Task type identifier
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_content
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number,
        i_task_type             IN task_type.id_task_type%TYPE
    ) RETURN t_coll_diagnosis_config IS
        l_tbl_diagnosis t_table_diag_cnt;
    BEGIN
        SELECT t_rec_diag_cnt(id_diagnosis        => tf.id_diagnosis,
                              id_diagnosis_parent => tf.id_diagnosis_parent,
                              id_alert_diagnosis  => tf.id_alert_diagnosis,
                              code_icd            => tf.code_icd,
                              id_language         => tf.id_language,
                              code_translation    => tf.code_translation,
                              desc_translation    => nvl(tf.desc_translation,
                                                         pk_translation.get_translation(i_lang      => tf.id_language,
                                                                                        i_code_mess => tf.code_translation)),
                              desc_epis_diagnosis => tf.desc_epis_diagnosis,
                              flg_other           => tf.flg_other,
                              flg_icd9            => tf.flg_icd9,
                              flg_select          => tf.flg_select,
                              id_dep_clin_serv    => tf.id_dep_clin_serv,
                              flg_terminology     => tf.flg_terminology,
                              rank                => tf.rank,
                              id_term_task_type   => tf.id_term_task_type,
                              flg_show_term_code  => tf.flg_show_term_code,
                              id_epis_diagnosis   => NULL,
                              flg_status          => NULL,
                              flg_type            => NULL,
                              flg_mechanism       => tf.flg_mechanism)
          BULK COLLECT
          INTO l_tbl_diagnosis
          FROM pat_history_diagnosis phd
          JOIN TABLE(pk_terminology_search.tf_diagnoses_search(i_lang => i_lang, i_prof => i_prof, i_patient => phd.id_patient, i_terminologies_task_types => table_number(i_task_type), i_term_task_type => i_task_type, i_list_type => pk_terminology_search.g_diag_list_searchable, i_text_search => NULL, i_tbl_diagnosis => table_number(phd.id_diagnosis), i_tbl_alert_diagnosis => table_number(phd.id_alert_diagnosis))) tf
            ON tf.id_diagnosis = phd.id_diagnosis
           AND tf.id_alert_diagnosis = phd.id_alert_diagnosis
         WHERE phd.id_pat_history_diagnosis IN
               (SELECT /*+ opt_estimate(table t rows=1)*/
                 column_value id_pat_history_diagnosis
                  FROM TABLE(i_tbl_transaccional_ids) t);
    
        RETURN get_t_coll_diagnosis_config(i_prof                   => i_prof,
                                           i_episode                => NULL,
                                           i_diag_type              => NULL,
                                           i_tbl_diagnosis          => l_tbl_diagnosis,
                                           i_flg_is_transaction_tbl => pk_alert_constant.g_yes);
    END tf_get_valid_content;

    /**************************************************************************************************************
    * Validates if a past medical history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_past_medical_hist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config IS
    BEGIN
        RETURN tf_get_valid_content(i_lang                  => i_lang,
                                    i_prof                  => i_prof,
                                    i_tbl_transaccional_ids => i_tbl_transaccional_ids,
                                    i_task_type             => pk_alert_constant.g_task_medical_history);
    END tf_get_valid_past_medical_hist;

    /**************************************************************************************************************
    * Validates if a past surgical history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_past_surgic_hist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config IS
    BEGIN
        RETURN tf_get_valid_content(i_lang                  => i_lang,
                                    i_prof                  => i_prof,
                                    i_tbl_transaccional_ids => i_tbl_transaccional_ids,
                                    i_task_type             => pk_alert_constant.g_task_surgical_history);
    END tf_get_valid_past_surgic_hist;

    /**************************************************************************************************************
    * Validates if a birth history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_cong_anomalies
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config IS
    BEGIN
        RETURN tf_get_valid_content(i_lang                  => i_lang,
                                    i_prof                  => i_prof,
                                    i_tbl_transaccional_ids => i_tbl_transaccional_ids,
                                    i_task_type             => pk_alert_constant.g_task_congenital_anomalies);
    END tf_get_valid_cong_anomalies;

    /**************************************************************************************************************
    * Validates if a problems record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_problems
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config IS
    BEGIN
        RETURN tf_get_valid_content(i_lang                  => i_lang,
                                    i_prof                  => i_prof,
                                    i_tbl_transaccional_ids => i_tbl_transaccional_ids,
                                    i_task_type             => pk_alert_constant.g_task_problems);
    END tf_get_valid_problems;

    FUNCTION tf_concept_by_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_type     IN table_number,
        i_id_content    IN table_varchar,
        i_relation_type IN VARCHAR2
    ) RETURN t_tbl_concept_term IS
    
        l_empty NUMBER(2) := 0;
    
        l_tbl_concept_term t_tbl_concept_term := t_tbl_concept_term();
    
    BEGIN
        IF i_task_type IS NULL
           OR i_task_type.count = 0
           OR i_id_content IS NULL
           OR i_id_content.count = 0
        THEN
            l_empty := 1;
        END IF;
    
        IF l_empty = 0
        THEN
            SELECT t_concept_term(id_concept_term,
                                  id_cncpt_trm_inst_owner,
                                  id_task_type,
                                  terminology_1,
                                  code_1,
                                  concept_rel_type,
                                  terminology_2,
                                  code_2,
                                  institution,
                                  software,
                                  rank,
                                  flg_active,
                                  flg_default,
                                  id_terminology_1,
                                  id_concept1,
                                  id_concept_version_1,
                                  id_terminology_version_1,
                                  id_concept_relation,
                                  id_concept_rel_type,
                                  id_terminology_2,
                                  id_concept2,
                                  id_concept_version_2,
                                  id_terminology_version_2,
                                  id_institution,
                                  id_software,
                                  id_cncpt_rel_inst_owner,
                                  id_concept_inst_owner1,
                                  id_concept_inst_owner2,
                                  id_cncpt_vrs_inst_owner1,
                                  id_cncpt_vrs_inst_owner2)
              BULK COLLECT
              INTO l_tbl_concept_term
              FROM (SELECT /*+opt_param('_optimizer_use_feedback' 'false')*/
                     mcttt.id_concept_term,
                     mcttt.id_cncpt_trm_inst_owner,
                     mcttt.id_task_type,
                     mcr.terminology_1,
                     mcr.code_1,
                     mcr.concept_rel_type,
                     mcr.terminology_2,
                     mcr.code_2,
                     mcr.institution,
                     mcr.software,
                     mcr.rank,
                     mcr.flg_active,
                     mcr.flg_default,
                     mcr.id_terminology_1,
                     mcr.id_concept1,
                     mcr.id_concept_version_1,
                     mcr.id_terminology_version_1,
                     mcr.id_concept_relation,
                     mcr.id_concept_rel_type,
                     mcr.id_terminology_2,
                     mcr.id_concept2,
                     mcr.id_concept_version_2,
                     mcr.id_terminology_version_2,
                     mcr.id_institution,
                     mcr.id_software,
                     mcr.id_cncpt_rel_inst_owner,
                     mcr.id_concept_inst_owner1,
                     mcr.id_concept_inst_owner2,
                     mcr.id_cncpt_vrs_inst_owner1,
                     mcr.id_cncpt_vrs_inst_owner2
                      FROM v_msi_concept_relations mcr
                      JOIN v_msi_concept_terms_task_types mcttt
                        ON mcttt.id_terminology = mcr.id_terminology_2
                       AND mcttt.id_concept = mcr.id_concept2
                       AND mcttt.id_concept_version = mcr.id_concept_version_2
                       AND mcttt.id_institution = mcr.id_institution
                       AND mcttt.id_software = mcr.id_software
                     WHERE mcr.concept_rel_type = i_relation_type
                       AND mcr.code_1 IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           *
                                            FROM TABLE(i_id_content) t)
                       AND mcr.id_institution = i_prof.institution
                       AND mcr.id_software = i_prof.software
                       AND mcr.flg_active = pk_alert_constant.g_yes
                       AND mcttt.id_task_type IN (SELECT /*+opt_estimate (table t rows=2)*/
                                                   *
                                                    FROM TABLE(i_task_type) t)) tt;
        END IF;
    
        RETURN l_tbl_concept_term;
    
    END tf_concept_by_id_content;

BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(g_package);
END pk_terminology_search;
/
