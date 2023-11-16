/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_nnn_core IS

    -- Private type declarations

    -- Private constant declarations

    --Module responsable of insertions in the transactional translation table (required by insert_translation_trs() for retro-compatibility)
    g_module_pfh CONSTANT pk_translation.t_module := 'PFH';

    --Traslation prefix code_notes in NNN_EPIS_DIAG_EVAL
    g_epis_diag_eval_code_notes CONSTANT nnn_epis_diag_eval.code_notes%TYPE := 'NNN_EPIS_DIAG_EVAL.CODE_NOTES.';
    --Translation prefix code_notes_prn in NNN_EPIS_OUTCOME
    g_epis_outcome_code_notes_prn CONSTANT nnn_epis_outcome.code_notes_prn%TYPE := 'NNN_EPIS_OUTCOME.CODE_NOTES_PRN.';
    --Translation prefix code_notes_prn in NNN_EPIS_ACTIVITY
    g_epis_activity_code_notes_prn CONSTANT nnn_epis_activity.code_notes_prn%TYPE := 'NNN_EPIS_ACTIVITY.CODE_NOTES_PRN.';
    --Translation prefix code_notes_prn in NNN_EPIS_INDICATOR
    g_epis_ind_code_notes_prn CONSTANT nnn_epis_indicator.code_notes_prn%TYPE := 'NNN_EPIS_INDICATOR.CODE_NOTES_PRN.';
    --Translation prefix code_notes in NNN_EPIS_IND_EVAL    
    g_epis_ind_eval_code_notes_prn CONSTANT nnn_epis_ind_eval.code_notes%TYPE := 'NNN_EPIS_IND_EVAL.CODE_NOTES.';
    --Translation prefix code_notes in NNN_EPIS_OUTCOME_EVAL
    g_epis_outcome_eval_code_notes CONSTANT nnn_epis_outcome_eval.code_notes%TYPE := 'NNN_EPIS_OUTCOME_EVAL.CODE_NOTES.';
    --Translation prefix code_notes in NNN_EPIS_ACTIVITY_DET
    g_epis_activity_det_code_notes CONSTANT nnn_epis_activity_det.code_notes%TYPE := 'NNN_EPIS_ACTIVITY_DET.CODE_NOTES.';
    --Translation prefix code_notes in NNN_EPIS_ACTV_DET_TASK    
    g_epis_actv_det_tsk_code_notes CONSTANT nnn_epis_actv_det_task.code_notes%TYPE := 'NNN_EPIS_ACTV_DET_TASK.CODE_NOTES.';

    /* Action Menus for the Patient's Care Plan according with the kind of selected item */

    -- Action Menu for a NANDA Diagnoses within a care plan
    g_act_subj_diagnosis CONSTANT action.subject%TYPE := 'NNN_DIAGNOSIS';
    -- Action Menu for NOC Outcomes within a care plan
    g_act_subj_outcome CONSTANT action.subject%TYPE := 'NNN_OUTCOME';
    -- Action Menu for NOC Indicators within a care plan
    g_act_subj_indicator CONSTANT action.subject%TYPE := 'NNN_INDICATOR';
    -- Action Menu for NIC Interventions within a care plan
    g_act_subj_intervention CONSTANT action.subject%TYPE := 'NNN_INTERVENTION';
    -- Action Menu for NIC Activities within a care plan
    g_act_subj_activity CONSTANT action.subject%TYPE := 'NNN_ACTIVITY';

    -- Action Menu in the "Add button" for Nursing Care Plan
    g_act_subj_careplan_add_btn CONSTANT action.subject%TYPE := 'NNN_CAREPLAN_ADD_BTN';

    /* Action Menus for the Staging Area according with the kind of selected item */

    -- Action Menu for a NANDA Diagnoses within the staging area
    g_act_subj_diagnosis_sa CONSTANT action.subject%TYPE := 'NNN_DIAGNOSIS_STAGING';
    -- Action Menu for NOC Outcomes within the staging area
    g_act_subj_outcome_sa CONSTANT action.subject%TYPE := 'NNN_OUTCOME_STAGING';
    -- Action Menu for NOC Indicators within the staging area
    g_act_subj_indicator_sa CONSTANT action.subject%TYPE := 'NNN_INDICATOR_STAGING';
    -- Action Menu for NIC Interventions within the staging area
    g_act_subj_intervention_sa CONSTANT action.subject%TYPE := 'NNN_INTERVENTION_STAGING';
    -- Action Menu for NIC Activities within the staging area
    g_act_subj_activity_sa CONSTANT action.subject%TYPE := 'NNN_ACTIVITY_STAGING';

    /* Action Menus for the Evaluations/Executions in timeline according with the kind of selected item */

    -- Action Menu for NANDA Diagnoses evaluations
    g_act_subj_diagnosis_eval CONSTANT action.subject%TYPE := 'NNN_DIAGNOSIS_EVAL';
    -- Action Menu for NOC Outcomes evaluations 
    g_act_subj_outcome_eval CONSTANT action.subject%TYPE := 'NNN_OUTCOME_EVAL';
    -- Action Menu for NOC Indicators evaluations
    g_act_subj_indicator_eval CONSTANT action.subject%TYPE := 'NNN_INDICATOR_EVAL';
    -- Action Menu for NIC Activities executions
    g_act_subj_activity_exec CONSTANT action.subject%TYPE := 'NNN_ACTIVITY_EXEC';

    -- Constant declarations that in the future sould be reallocated to another package like pk_dt_constant
    k_minute_format CONSTANT pk_types.t_low_char := 'MI';

    -- Private variable declarations
    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Public function and procedure implementations

    PROCEDURE render_template
    (
        io_template   IN OUT NOCOPY CLOB,
        i_hash_values IN pk_types.vc2_hash_table
    ) IS
        l_key pk_types.t_big_byte;
    BEGIN
        l_key := i_hash_values.first;
        WHILE l_key IS NOT NULL
        LOOP
            io_template := REPLACE(io_template, '{{' || l_key || '}}', htf.escape_sc(i_hash_values(l_key)));
            l_key       := i_hash_values.next(l_key);
        END LOOP;
    END;

    FUNCTION get_inst_nnn_term_version
    (
        i_terminology_name IN terminology.internal_name%TYPE,
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE
    ) RETURN terminology_version.id_terminology_version%TYPE result_cache relies_on(msi_termin_version) IS
        l_terminology_version terminology_version.id_terminology_version%TYPE;
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_inst_nnn_term_version';
        l_mkt msi_termin_version.id_market%TYPE;
    BEGIN
        IF i_inst > 0
        THEN
            SELECT i.id_market
              INTO l_mkt
              FROM institution i
             WHERE i.id_institution = i_inst;
        END IF;
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_terminology_name = ' || coalesce(i_terminology_name, '<null>');
        g_error := g_error || ' i_inst = ' || coalesce(to_char(i_inst), '<null>');
        g_error := g_error || ' i_soft = ' || coalesce(to_char(i_soft), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT t.id_terminology_version
          INTO l_terminology_version
          FROM (SELECT tv.id_terminology_version,
                       row_number() over(PARTITION BY mtv.version ORDER BY mtv.id_institution DESC, mtv.id_market DESC, mtv.id_software DESC, mtv.id_language DESC) precedence_level
                  FROM msi_termin_version mtv
                 INNER JOIN terminology_version tv
                    ON mtv.id_terminology = tv.id_terminology
                 INNER JOIN terminology t
                    ON t.id_terminology = tv.id_terminology
                   AND mtv.version = tv.version
                   AND mtv.id_terminology_mkt = tv.id_terminology_mkt
                   AND mtv.id_language = tv.id_language
                 WHERE mtv.id_institution IN (i_inst, 0)
                   AND mtv.id_market IN (l_mkt, 0)
                   AND mtv.id_software IN (i_soft, 0)
                   AND t.internal_name = i_terminology_name
                   AND mtv.flg_active = pk_alert_constant.g_yes
                      -- filter NANDA, NIC, NOC, NNN-Linkages content
                   AND mtv.id_task_type IN (pk_nnn_constant.g_task_type_nanda,
                                            pk_nnn_constant.g_task_type_noc,
                                            pk_nnn_constant.g_task_type_nic,
                                            pk_nnn_constant.g_task_type_nnn_linkages)) t
         WHERE t.precedence_level = 1;
    
        RETURN l_terminology_version;
    EXCEPTION
        WHEN no_data_found THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                g_error := 'Missing configuration in MSI_TERMIN_VERSION. The terminology version of "' ||
                           coalesce(i_terminology_name, '<null>') ||
                           '" Classification to be used in this institution was not defined.';
                pk_alert_exceptions.register_error(error_name_in       => 'e_missing_cfg_term_version',
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'i_terminology_name',
                                                   value1_in           => coalesce(i_terminology_name, '<null>'),
                                                   name2_in            => 'i_inst',
                                                   value2_in           => coalesce(to_char(i_inst), '<null>'),
                                                   name3_in            => 'i_soft',
                                                   value3_in           => coalesce(to_char(i_soft), '<null>'));
                RAISE e_missing_cfg_term_version;
            END;
        
    END get_inst_nnn_term_version;

    FUNCTION get_terminology_language
    (
        i_terminology_name IN terminology.internal_name%TYPE,
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE
    ) RETURN terminology_version.id_language%TYPE result_cache relies_on(terminology_version, msi_termin_version) IS
    
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_terminology_language';
    BEGIN
    
        RETURN get_terminology_language(i_terminology_version => get_inst_nnn_term_version(i_terminology_name => i_terminology_name,
                                                                                           i_inst             => i_inst,
                                                                                           i_soft             => i_soft));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
        
    END get_terminology_language;

    FUNCTION get_terminology_language(i_terminology_version IN terminology_version.id_terminology_version%TYPE)
        RETURN terminology_version.id_language%TYPE result_cache relies_on(terminology_version) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_terminology_language';
        l_language terminology_version.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT tv.id_language
          INTO l_language
          FROM terminology_version tv
         WHERE tv.id_terminology_version = i_terminology_version;
    
        RETURN l_language;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
    END get_terminology_language;

    FUNCTION check_epis_nan_diagnosis
    (
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE
    ) RETURN BOOLEAN IS
        l_exists PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_exists
          FROM nnn_epis_diagnosis ed
         WHERE ed.id_patient = i_patient
           AND ed.id_episode = i_episode
           AND ed.id_nan_diagnosis = i_nan_diagnosis
           AND ed.flg_req_status != pk_nnn_constant.g_req_status_cancelled;
    
        IF l_exists > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    END check_epis_nan_diagnosis;

    PROCEDURE get_pat_nursing_careplan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_diagnosis    OUT pk_types.cursor_type,
        o_outcome      OUT pk_types.cursor_type,
        o_indicator    OUT pk_types.cursor_type,
        o_intervention OUT pk_types.cursor_type,
        o_activity     OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_nursing_careplan';
        l_error   t_error_out;
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        IF l_patient != i_patient
        THEN
            g_error := 'The I_PATIENT / I_SCOPE / I_SCOPE_TYPE don''t match';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Retrieving Nursing Diagnoses (NANDA Diagnosis) that were defined in this patient''s nursing care plan';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- !!! WARNING !!!!  For performance reasons the same query is replicated and adjusted according each scope (Episode/Visit/Patient)
        -- !!! WARNING !!!!  So, if you need to add/modify something in the query, please
        -- !!! WARNING !!!!  make sure that this modification is applied/validated also in all of these queries and be consistent with the output
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode  
                OPEN o_diagnosis FOR
                    SELECT /*+ opt_estimate(table lede rows=1)*/
                     ed.id_nnn_epis_diagnosis,
                     ed.id_nan_diagnosis,
                     pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                         i_code_format     => pk_nan_model.g_code_format_end,
                                                         i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     CAST(MULTISET (SELECT to_char(di.id_nnn_epis_intervention)
                             FROM nnn_epis_lnk_dg_intrv di
                            WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                     pk_date_utils.date_send_tsz(i_lang, ed.dt_diagnosis, i_prof) dt_diagnosis,
                     ed.flg_req_status,
                     pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status, ed.flg_req_status, i_lang) desc_flg_req_status,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                         ELSE
                          lede.id_nnn_epis_diag_eval
                     END id_nnn_epis_diag_eval_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_date_utils.date_send_tsz(i_lang, ed.dt_trs_time_start, i_prof)
                         ELSE
                          pk_date_utils.date_send_tsz(i_lang, lede.dt_evaluation, i_prof)
                     END dt_evaluation_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_nnn_constant.g_diagnosis_status_cancelled
                         ELSE
                          lede.flg_status
                     END flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  pk_nnn_constant.g_diagnosis_status_cancelled,
                                                  i_lang)
                         ELSE
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  lede.flg_status,
                                                  i_lang)
                     END desc_flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                     
                         ELSE
                          pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                  i_use_html_format    => pk_alert_constant.g_yes)
                     END last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_diagnosis,
                                       i_status  => ed.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                    
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                       AND ed.id_episode = l_episode
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            
                g_error := 'Retrieving Nursing Outcomes (NOC Outcome) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_outcome FOR
                    SELECT /*+ opt_estimate(table leoe rows=1)*/
                     eo.id_nnn_epis_outcome,
                     eo.id_noc_outcome,
                     pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                   i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_diagnosis)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_indicator)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_indicators,
                     eo.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                             i_val      => eo.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                          i_val      => eo.flg_req_status) icon_req_status,
                     pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                           i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                     eo.flg_priority,
                     eo.flg_time,
                     eo.flg_prn,
                     eo.id_order_recurr_plan,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => eo.flg_priority,
                                                  i_flg_prn           => eo.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => eo.code_notes_prn),
                                                  i_flg_time          => eo.flg_time,
                                                  i_order_recurr_plan => eo.id_order_recurr_plan) desc_instructions,
                     leoe.id_nnn_epis_outcome_eval id_nnn_epis_outcome_eval_ltest,
                     leoe.target_value target_value_ltest,
                     leoe.outcome_value outcome_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leoe.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_outcome,
                                       i_status  => eo.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                      FROM nnn_epis_outcome eo
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE eo.id_patient = i_patient
                       AND eo.id_episode = l_episode
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_prn,
                                                    i_val      => eo.flg_prn),
                              outcome_name;
            
                g_error := 'Retrieving Nursing Indicators (NOC Indicator) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_indicator FOR
                    SELECT /*+ opt_estimate(table leie rows=1)*/
                     ei.id_nnn_epis_indicator,
                     pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => noc_i.id_terminology_version),
                                                    i_code_mess => noc_i.code_description) indicator_name,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     ei.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                             i_val      => ei.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                          i_val      => ei.flg_req_status) icon_req_status,
                     pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                             i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                     ei.flg_priority,
                     ei.flg_time,
                     ei.flg_prn,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => ei.flg_priority,
                                                  i_flg_prn           => ei.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ei.code_notes_prn),
                                                  i_flg_time          => ei.flg_time,
                                                  i_order_recurr_plan => ei.id_order_recurr_plan) desc_instructions,
                     
                     leie.id_nnn_epis_ind_eval id_nnn_epis_ind_eval_ltest,
                     leie.target_value target_value_ltest,
                     leie.indicator_value indicator_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leie.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_nnn_epis_outcome  => NULL,
                                                            i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                            i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_indicator,
                                       i_status  => ei.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                      FROM nnn_epis_indicator ei
                      LEFT JOIN noc_indicator noc_i
                        ON ei.id_noc_indicator = noc_i.id_noc_indicator
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                        ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                     WHERE ei.id_patient = i_patient
                       AND ei.id_episode = l_episode
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ei.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ei.flg_prn),
                              indicator_name;
            
                g_error := 'Retrieving Nursing Interventions (NIC Intervention) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_intervention FOR
                    SELECT ei.id_nnn_epis_intervention,
                           ei.id_nic_intervention,
                           pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                              i_code_format      => pk_nic_model.g_code_format_end) intervention_name,
                           CAST(MULTISET (SELECT to_char(di.id_nnn_epis_diagnosis)
                                   FROM nnn_epis_lnk_dg_intrv di
                                  WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_activity)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_activities,
                           ei.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                   i_val      => ei.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                i_val      => ei.flg_req_status) icon_req_status,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_intervention,
                                             i_status  => ei.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                    
                      FROM nnn_epis_intervention ei
                     WHERE ei.id_patient = i_patient
                       AND ei.id_episode = l_episode
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              intervention_name;
            
                g_error := 'Retrieving Nursing Activities (NIC Activity) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_activity FOR
                    SELECT ea.id_nnn_epis_activity,
                           pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => nic_a.id_terminology_version),
                                                          i_code_mess => nic_a.code_description) activity_name,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_intervention)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                           ea.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                   i_val      => ea.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                i_val      => ea.flg_req_status) icon_req_status,
                           pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                 
                                                                 i_prof              => i_prof,
                                                                 i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                 i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                           ea.flg_priority,
                           ea.flg_time,
                           ea.flg_prn,
                           pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_flg_priority      => ea.flg_priority,
                                                        i_flg_prn           => ea.flg_prn,
                                                        i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ea.code_notes_prn),
                                                        i_flg_time          => ea.flg_time,
                                                        i_order_recurr_plan => ea.id_order_recurr_plan) desc_instructions,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_activity,
                                             i_status  => ea.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                      FROM nnn_epis_activity ea
                      LEFT JOIN nic_activity nic_a
                        ON ea.id_nic_activity = nic_a.id_nic_activity
                     WHERE ea.id_patient = i_patient
                       AND ea.id_episode = l_episode
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                    i_val      => ea.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ea.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ea.flg_prn),
                              activity_name;
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit             
            
                OPEN o_diagnosis FOR
                    SELECT /*+ opt_estimate(table lede rows=1)*/
                     ed.id_nnn_epis_diagnosis,
                     ed.id_nan_diagnosis,
                     pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                         i_code_format     => pk_nan_model.g_code_format_end,
                                                         i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     CAST(MULTISET (SELECT to_char(di.id_nnn_epis_intervention)
                             FROM nnn_epis_lnk_dg_intrv di
                            WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                     pk_date_utils.date_send_tsz(i_lang, ed.dt_diagnosis, i_prof) dt_diagnosis,
                     ed.flg_req_status,
                     pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status, ed.flg_req_status, i_lang) desc_flg_req_status,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                         ELSE
                          lede.id_nnn_epis_diag_eval
                     END id_nnn_epis_diag_eval_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_date_utils.date_send_tsz(i_lang, ed.dt_trs_time_start, i_prof)
                         ELSE
                          pk_date_utils.date_send_tsz(i_lang, lede.dt_evaluation, i_prof)
                     END dt_evaluation_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_nnn_constant.g_diagnosis_status_cancelled
                         ELSE
                          lede.flg_status
                     END flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  pk_nnn_constant.g_diagnosis_status_cancelled,
                                                  i_lang)
                         ELSE
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  lede.flg_status,
                                                  i_lang)
                     END desc_flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                     
                         ELSE
                          pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                  i_use_html_format    => pk_alert_constant.g_yes)
                     END last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_diagnosis,
                                       i_status  => ed.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                    
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                       AND ed.id_visit = l_visit
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            
                g_error := 'Retrieving Nursing Outcomes (NOC Outcome) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_outcome FOR
                    SELECT /*+ opt_estimate(table leoe rows=1)*/
                     eo.id_nnn_epis_outcome,
                     eo.id_noc_outcome,
                     pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                   i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_diagnosis)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_indicator)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_indicators,
                     eo.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                             i_val      => eo.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                          i_val      => eo.flg_req_status) icon_req_status,
                     pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                           i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                     eo.flg_priority,
                     eo.flg_time,
                     eo.flg_prn,
                     eo.id_order_recurr_plan,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => eo.flg_priority,
                                                  i_flg_prn           => eo.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => eo.code_notes_prn),
                                                  i_flg_time          => eo.flg_time,
                                                  i_order_recurr_plan => eo.id_order_recurr_plan) desc_instructions,
                     leoe.id_nnn_epis_outcome_eval id_nnn_epis_outcome_eval_ltest,
                     leoe.target_value target_value_ltest,
                     leoe.outcome_value outcome_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leoe.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_outcome,
                                       i_status  => eo.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                      FROM nnn_epis_outcome eo
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE eo.id_patient = i_patient
                       AND eo.id_visit = l_visit
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_prn,
                                                    i_val      => eo.flg_prn),
                              outcome_name;
            
                g_error := 'Retrieving Nursing Indicators (NOC Indicator) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_indicator FOR
                    SELECT /*+ opt_estimate(table leie rows=1)*/
                     ei.id_nnn_epis_indicator,
                     pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => noc_i.id_terminology_version),
                                                    i_code_mess => noc_i.code_description) indicator_name,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     ei.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                             i_val      => ei.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                          i_val      => ei.flg_req_status) icon_req_status,
                     pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                             i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                     ei.flg_priority,
                     ei.flg_time,
                     ei.flg_prn,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => ei.flg_priority,
                                                  i_flg_prn           => ei.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ei.code_notes_prn),
                                                  i_flg_time          => ei.flg_time,
                                                  i_order_recurr_plan => ei.id_order_recurr_plan) desc_instructions,
                     
                     leie.id_nnn_epis_ind_eval id_nnn_epis_ind_eval_ltest,
                     leie.target_value target_value_ltest,
                     leie.indicator_value indicator_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leie.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_nnn_epis_outcome  => NULL,
                                                            i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                            i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_indicator,
                                       i_status  => ei.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                      FROM nnn_epis_indicator ei
                      LEFT JOIN noc_indicator noc_i
                        ON ei.id_noc_indicator = noc_i.id_noc_indicator
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                        ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                     WHERE ei.id_patient = i_patient
                       AND ei.id_visit = l_visit
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ei.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ei.flg_prn),
                              indicator_name;
            
                g_error := 'Retrieving Nursing Interventions (NIC Intervention) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_intervention FOR
                    SELECT ei.id_nnn_epis_intervention,
                           ei.id_nic_intervention,
                           pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                              i_code_format      => pk_nic_model.g_code_format_end) intervention_name,
                           CAST(MULTISET (SELECT to_char(di.id_nnn_epis_diagnosis)
                                   FROM nnn_epis_lnk_dg_intrv di
                                  WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_activity)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_activities,
                           ei.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                   i_val      => ei.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                i_val      => ei.flg_req_status) icon_req_status,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_intervention,
                                             i_status  => ei.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                    
                      FROM nnn_epis_intervention ei
                     WHERE ei.id_patient = i_patient
                       AND ei.id_visit = l_visit
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              intervention_name;
            
                g_error := 'Retrieving Nursing Activities (NIC Activity) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_activity FOR
                    SELECT ea.id_nnn_epis_activity,
                           pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => nic_a.id_terminology_version),
                                                          i_code_mess => nic_a.code_description) activity_name,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_intervention)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                           ea.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                   i_val      => ea.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                i_val      => ea.flg_req_status) icon_req_status,
                           pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                 
                                                                 i_prof              => i_prof,
                                                                 i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                 i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                           ea.flg_priority,
                           ea.flg_time,
                           ea.flg_prn,
                           pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_flg_priority      => ea.flg_priority,
                                                        i_flg_prn           => ea.flg_prn,
                                                        i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ea.code_notes_prn),
                                                        i_flg_time          => ea.flg_time,
                                                        i_order_recurr_plan => ea.id_order_recurr_plan) desc_instructions,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_activity,
                                             i_status  => ea.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                      FROM nnn_epis_activity ea
                      LEFT JOIN nic_activity nic_a
                        ON ea.id_nic_activity = nic_a.id_nic_activity
                     WHERE ea.id_patient = i_patient
                       AND ea.id_visit = l_visit
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                    i_val      => ea.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ea.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ea.flg_prn),
                              activity_name;
            
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient                              
                OPEN o_diagnosis FOR
                    SELECT /*+ opt_estimate(table lede rows=1)*/
                     ed.id_nnn_epis_diagnosis,
                     ed.id_nan_diagnosis,
                     pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                         i_code_format     => pk_nan_model.g_code_format_end,
                                                         i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     CAST(MULTISET (SELECT to_char(di.id_nnn_epis_intervention)
                             FROM nnn_epis_lnk_dg_intrv di
                            WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                              AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                     pk_date_utils.date_send_tsz(i_lang, ed.dt_diagnosis, i_prof) dt_diagnosis,
                     ed.flg_req_status,
                     pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status, ed.flg_req_status, i_lang) desc_flg_req_status,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                         ELSE
                          lede.id_nnn_epis_diag_eval
                     END id_nnn_epis_diag_eval_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_date_utils.date_send_tsz(i_lang, ed.dt_trs_time_start, i_prof)
                         ELSE
                          pk_date_utils.date_send_tsz(i_lang, lede.dt_evaluation, i_prof)
                     END dt_evaluation_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_nnn_constant.g_diagnosis_status_cancelled
                         ELSE
                          lede.flg_status
                     END flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  pk_nnn_constant.g_diagnosis_status_cancelled,
                                                  i_lang)
                         ELSE
                          pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                  lede.flg_status,
                                                  i_lang)
                     END desc_flg_status_ltest,
                     CASE ed.flg_req_status
                         WHEN pk_nnn_constant.g_req_status_cancelled THEN
                          NULL
                     
                         ELSE
                          pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                  i_use_html_format    => pk_alert_constant.g_yes)
                     END last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_diagnosis,
                                       i_status  => ed.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                    
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            
                g_error := 'Retrieving Nursing Outcomes (NOC Outcome) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_outcome FOR
                    SELECT /*+ opt_estimate(table leoe rows=1)*/
                     eo.id_nnn_epis_outcome,
                     eo.id_noc_outcome,
                     pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                   i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                     CAST(MULTISET (SELECT to_char(do.id_nnn_epis_diagnosis)
                             FROM nnn_epis_lnk_dg_outc do
                            WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND do.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_indicator)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_indicators,
                     eo.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                             i_val      => eo.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                          i_val      => eo.flg_req_status) icon_req_status,
                     pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                           i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                     eo.flg_priority,
                     eo.flg_time,
                     eo.flg_prn,
                     eo.id_order_recurr_plan,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => eo.flg_priority,
                                                  i_flg_prn           => eo.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => eo.code_notes_prn),
                                                  i_flg_time          => eo.flg_time,
                                                  i_order_recurr_plan => eo.id_order_recurr_plan) desc_instructions,
                     leoe.id_nnn_epis_outcome_eval id_nnn_epis_outcome_eval_ltest,
                     leoe.target_value target_value_ltest,
                     leoe.outcome_value outcome_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leoe.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_outcome,
                                       i_status  => eo.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                      FROM nnn_epis_outcome eo
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE eo.id_patient = i_patient
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_prn,
                                                    i_val      => eo.flg_prn),
                              outcome_name;
            
                g_error := 'Retrieving Nursing Indicators (NOC Indicator) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_indicator FOR
                    SELECT /*+ opt_estimate(table leie rows=1)*/
                     ei.id_nnn_epis_indicator,
                     pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => noc_i.id_terminology_version),
                                                    i_code_mess => noc_i.code_description) indicator_name,
                     CAST(MULTISET (SELECT to_char(oi.id_nnn_epis_outcome)
                             FROM nnn_epis_lnk_outc_ind oi
                            WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                              AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_outcomes,
                     ei.flg_req_status,
                     pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                             i_val      => ei.flg_req_status,
                                             i_lang     => i_lang) desc_flg_req_status,
                     pk_sysdomain.get_img(i_lang     => i_lang,
                                          i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                          i_val      => ei.flg_req_status) icon_req_status,
                     pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                             i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                     ei.flg_priority,
                     ei.flg_time,
                     ei.flg_prn,
                     pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_priority      => ei.flg_priority,
                                                  i_flg_prn           => ei.flg_prn,
                                                  i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ei.code_notes_prn),
                                                  i_flg_time          => ei.flg_time,
                                                  i_order_recurr_plan => ei.id_order_recurr_plan) desc_instructions,
                     
                     leie.id_nnn_epis_ind_eval id_nnn_epis_ind_eval_ltest,
                     leie.target_value target_value_ltest,
                     leie.indicator_value indicator_value_ltest,
                     pk_date_utils.date_send_tsz(i_lang, leie.dt_evaluation, i_prof) dt_evaluation_ltest,
                     pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_nnn_epis_outcome  => NULL,
                                                            i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                            i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                     check_permissions(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_subject => g_act_subj_indicator,
                                       i_status  => ei.flg_req_status,
                                       i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                      FROM nnn_epis_indicator ei
                      LEFT JOIN noc_indicator noc_i
                        ON ei.id_noc_indicator = noc_i.id_noc_indicator
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                        ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                     WHERE ei.id_patient = i_patient
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ei.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ei.flg_prn),
                              indicator_name;
            
                g_error := 'Retrieving Nursing Interventions (NIC Intervention) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_intervention FOR
                    SELECT ei.id_nnn_epis_intervention,
                           ei.id_nic_intervention,
                           pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                              i_code_format      => pk_nic_model.g_code_format_end) intervention_name,
                           CAST(MULTISET (SELECT to_char(di.id_nnn_epis_diagnosis)
                                   FROM nnn_epis_lnk_dg_intrv di
                                  WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_diagnoses,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_activity)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_activities,
                           ei.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                   i_val      => ei.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                i_val      => ei.flg_req_status) icon_req_status,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_intervention,
                                             i_status  => ei.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                    
                      FROM nnn_epis_intervention ei
                     WHERE ei.id_patient = i_patient
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                    i_val      => ei.flg_req_status),
                              intervention_name;
            
                g_error := 'Retrieving Nursing Activities (NIC Activity) that were defined in this patient''s nursing care plan';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                OPEN o_activity FOR
                    SELECT ea.id_nnn_epis_activity,
                           pk_translation.get_translation(i_lang      => get_terminology_language(i_terminology_version => nic_a.id_terminology_version),
                                                          i_code_mess => nic_a.code_description) activity_name,
                           CAST(MULTISET (SELECT to_char(ia.id_nnn_epis_intervention)
                                   FROM nnn_epis_lnk_int_actv ia
                                  WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                    AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_interventions,
                           ea.flg_req_status,
                           pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                   i_val      => ea.flg_req_status,
                                                   i_lang     => i_lang) desc_flg_req_status,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                i_val      => ea.flg_req_status) icon_req_status,
                           pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                 
                                                                 i_prof              => i_prof,
                                                                 i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                 i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                           ea.flg_priority,
                           ea.flg_time,
                           ea.flg_prn,
                           pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_flg_priority      => ea.flg_priority,
                                                        i_flg_prn           => ea.flg_prn,
                                                        i_notes_prn         => pk_translation.get_translation_trs(i_code_mess => ea.code_notes_prn),
                                                        i_flg_time          => ea.flg_time,
                                                        i_order_recurr_plan => ea.id_order_recurr_plan) desc_instructions,
                           check_permissions(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_subject => g_act_subj_activity,
                                             i_status  => ea.flg_req_status,
                                             i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                      FROM nnn_epis_activity ea
                      LEFT JOIN nic_activity nic_a
                        ON ea.id_nic_activity = nic_a.id_nic_activity
                     WHERE ea.id_patient = i_patient
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                    i_val      => ea.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                                    i_val      => ea.flg_priority),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                                    i_val      => ea.flg_prn),
                              activity_name;
            
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
    EXCEPTION
        -- Log an raise the error      
        WHEN pk_nnn_constant.e_invalid_argument THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_invalid_argument', text_in => g_error);
        
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error', text_in => g_error);
        
    END get_pat_nursing_careplan;

    FUNCTION tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE)
        RETURN ts_nnn_epis_diag_eval.nnn_epis_diag_eval_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_diag_eval.nnn_epis_diag_eval_ntt;
    BEGIN
        SELECT dxevl.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_diag_eval dxevl
         WHERE dxevl.rowid = (SELECT t.rowid
                                FROM (SELECT row_number() over(PARTITION BY dxevl.id_nnn_epis_diagnosis ORDER BY dxevl.dt_evaluation DESC) rn
                                        FROM nnn_epis_diag_eval dxevl
                                       WHERE dxevl.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
                                         AND dxevl.flg_status != pk_nnn_constant.g_diagnosis_status_cancelled) t
                               WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    END tf_latest_nnn_epis_diag_eval;

    FUNCTION tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE)
        RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt;
    BEGIN
        SELECT oevl.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_outcome_eval oevl
         WHERE oevl.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY oevl.id_nnn_epis_outcome ORDER BY oevl.dt_evaluation DESC, oevl.dt_trs_time_start DESC) rn
                                       FROM nnn_epis_outcome_eval oevl
                                      WHERE oevl.id_nnn_epis_outcome = i_nnn_epis_outcome
                                        AND oevl.flg_status = pk_nnn_constant.g_task_status_finished) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    END tf_latest_nnn_epis_outc_eval;

    FUNCTION tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE)
        RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt;
    BEGIN
        SELECT ievl.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_ind_eval ievl
         WHERE ievl.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY ievl.id_nnn_epis_indicator ORDER BY ievl.dt_evaluation DESC, ievl.dt_trs_time_start DESC) rn
                                       FROM nnn_epis_ind_eval ievl
                                      WHERE ievl.id_nnn_epis_indicator = i_nnn_epis_indicator
                                        AND ievl.flg_status = pk_nnn_constant.g_task_status_finished) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    END tf_latest_nnn_epis_ind_eval;

    FUNCTION tf_latest_nnn_epis_activ_det(i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE)
        RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt;
    BEGIN
    
        SELECT adet.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_activity_det adet
         WHERE adet.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY adet.id_nnn_epis_activity ORDER BY decode(adet.flg_status, pk_nnn_constant.g_task_status_ongoing, 1, pk_nnn_constant.g_task_status_ordered, 1, 2), adet.dt_plan, adet.exec_number) rn
                                       FROM nnn_epis_activity_det adet
                                      WHERE adet.id_nnn_epis_activity = i_nnn_epis_activity
                                        AND adet.flg_status = pk_nnn_constant.g_task_status_finished) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    
    END tf_latest_nnn_epis_activ_det;

    --// History tracking methods - Start

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_diagnosis        Careplan's NANDA Diagnosis ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_nan_diagnosis_hist
    (
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_dt_trs_time_end    IN nnn_epis_diagnosis_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_diagnosis%ROWTYPE;
        l_entry_hist nnn_epis_diagnosis_h%ROWTYPE;
        l_time_end   nnn_epis_diagnosis_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_diagnosis IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_diagnosis t
             WHERE t.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis;
        
            l_entry_hist.id_nnn_epis_diagnosis_h := ts_nnn_epis_diagnosis_h.next_key();
            l_entry_hist.id_nnn_epis_diagnosis   := l_entry.id_nnn_epis_diagnosis;
            l_entry_hist.id_nan_diagnosis        := l_entry.id_nan_diagnosis;
            l_entry_hist.id_patient              := l_entry.id_patient;
            l_entry_hist.id_episode              := l_entry.id_episode;
            l_entry_hist.id_visit                := l_entry.id_visit;
            l_entry_hist.id_professional         := l_entry.id_professional;
            l_entry_hist.id_cancel_reason        := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes            := l_entry.cancel_notes;
            l_entry_hist.nanda_code              := l_entry.nanda_code;
            l_entry_hist.edited_diagnosis_name   := l_entry.edited_diagnosis_name;
            l_entry_hist.dt_diagnosis            := l_entry.dt_diagnosis;
            l_entry_hist.flg_req_status          := l_entry.flg_req_status;
            l_entry_hist.dt_val_time_start       := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end         := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start       := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end         := l_time_end;
        
            ts_nnn_epis_diagnosis_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_nan_diagnosis_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_diag_eval        Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_nan_diag_eval_hist
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_end    IN nnn_epis_diag_eval_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_diag_eval%ROWTYPE;
        l_entry_hist nnn_epis_diag_eval_h%ROWTYPE;
        l_time_end   nnn_epis_diag_eval_h.dt_trs_time_end%TYPE;
    
        l_lst_diag_relf_h ts_nnn_epis_diag_relf_h.nnn_epis_diag_relf_h_tc;
        l_lst_diag_rskf_h ts_nnn_epis_diag_rskf_h.nnn_epis_diag_rskf_h_tc;
        l_lst_diag_defc_h ts_nnn_epis_diag_defc_h.nnn_epis_diag_defc_h_tc;
    BEGIN
    
        IF i_nnn_epis_diag_eval IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_diag_eval t
             WHERE t.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            l_entry_hist.id_nnn_epis_diag_eval_h := ts_nnn_epis_diag_eval_h.next_key();
            l_entry_hist.id_nnn_epis_diag_eval   := l_entry.id_nnn_epis_diag_eval;
            l_entry_hist.id_nnn_epis_diagnosis   := l_entry.id_nnn_epis_diagnosis;
            l_entry_hist.id_patient              := l_entry.id_patient;
            l_entry_hist.id_episode              := l_entry.id_episode;
            l_entry_hist.id_visit                := l_entry.id_visit;
            l_entry_hist.id_professional         := l_entry.id_professional;
            l_entry_hist.id_cancel_reason        := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes            := l_entry.cancel_notes;
            l_entry_hist.flg_status              := l_entry.flg_status;
            l_entry_hist.dt_evaluation           := l_entry.dt_evaluation;
            l_entry_hist.notes                   := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes);
            l_entry_hist.dt_trs_time_start       := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end         := l_time_end;
        
            ts_nnn_epis_diag_eval_h.ins(rec_in => l_entry_hist);
        
            -- An evaluation of NANDA nursing diagnosis is also composed by a list of related factors, risk factors and defining characteristics.
            -- So when a change to a evaluation is made, these tables are also copied to historical.
        
            -- Related factors
            SELECT seq_nnn_epis_diag_relf_h.nextval id_nnn_epis_diag_relf_h,
                   relf.id_nnn_epis_diag_eval,
                   l_entry.dt_trs_time_start        dt_trs_time_start,
                   relf.id_nan_related_factor,
                   NULL                             create_user,
                   NULL                             create_time,
                   NULL                             create_institution,
                   NULL                             update_user,
                   NULL                             update_time,
                   NULL                             update_institution
              BULK COLLECT
              INTO l_lst_diag_relf_h
              FROM nnn_epis_diag_relf relf
             WHERE relf.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            -- Risk factors
            SELECT seq_nnn_epis_diag_rskf_h.nextval id_nnn_epis_diag_rskf_h,
                   rskf.id_nnn_epis_diag_eval,
                   l_entry.dt_trs_time_start        dt_trs_time_start,
                   rskf.id_nan_risk_factor,
                   NULL                             create_user,
                   NULL                             create_time,
                   NULL                             create_institution,
                   NULL                             update_user,
                   NULL                             update_time,
                   NULL                             update_institution
              BULK COLLECT
              INTO l_lst_diag_rskf_h
              FROM nnn_epis_diag_rskf rskf
             WHERE rskf.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            -- Defining characteristics
            SELECT seq_nnn_epis_diag_defc_h.nextval id_nnn_epis_diag_defc_h,
                   defc.id_nnn_epis_diag_eval,
                   l_entry.dt_trs_time_start        dt_trs_time_start,
                   defc.id_nan_def_chars,
                   NULL                             create_user,
                   NULL                             create_time,
                   NULL                             create_institution,
                   NULL                             update_user,
                   NULL                             update_time,
                   NULL                             update_institution
              BULK COLLECT
              INTO l_lst_diag_defc_h
              FROM nnn_epis_diag_defc defc
             WHERE defc.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            ts_nnn_epis_diag_defc_h.ins(rows_in => l_lst_diag_defc_h);
            ts_nnn_epis_diag_rskf_h.ins(rows_in => l_lst_diag_rskf_h);
            ts_nnn_epis_diag_relf_h.ins(rows_in => l_lst_diag_relf_h);
        
        END IF;
    END set_epis_nan_diag_eval_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_lnk_dg_intrv     Linkage Diagnosis Intervention ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_lnk_dg_intrv_hist
    (
        i_nnn_epis_lnk_dg_intrv IN nnn_epis_lnk_dg_intrv.id_nnn_epis_lnk_dg_intrv%TYPE,
        i_dt_trs_time_end       IN nnn_epis_lnk_dg_intrv_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_lnk_dg_intrv%ROWTYPE;
        l_entry_hist nnn_epis_lnk_dg_intrv_h%ROWTYPE;
        l_time_end   nnn_epis_lnk_dg_intrv_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_lnk_dg_intrv IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_lnk_dg_intrv t
             WHERE t.id_nnn_epis_lnk_dg_intrv = i_nnn_epis_lnk_dg_intrv;
        
            l_entry_hist.id_nnn_epis_lnk_dg_intrv_h := ts_nnn_epis_lnk_dg_intrv_h.next_key();
            l_entry_hist.id_nnn_epis_lnk_dg_intrv   := l_entry.id_nnn_epis_lnk_dg_intrv;
            l_entry_hist.id_nnn_epis_diagnosis      := l_entry.id_nnn_epis_diagnosis;
            l_entry_hist.id_nnn_epis_intervention   := l_entry.id_nnn_epis_intervention;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.flg_lnk_status             := l_entry.flg_lnk_status;
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_lnk_dg_intrv_h.ins(rec_in => l_entry_hist);
        
        END IF;
    END set_epis_lnk_dg_intrv_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_lnk_dg_outc      Linkage Diagnosis Outcome ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_lnk_dg_outc_hist
    (
        i_nnn_epis_lnk_dg_outc IN nnn_epis_lnk_dg_outc.id_nnn_epis_lnk_dg_outc%TYPE,
        i_dt_trs_time_end      IN nnn_epis_lnk_dg_outc_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_lnk_dg_outc%ROWTYPE;
        l_entry_hist nnn_epis_lnk_dg_outc_h%ROWTYPE;
        l_time_end   nnn_epis_lnk_dg_outc_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_lnk_dg_outc IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_lnk_dg_outc t
             WHERE t.id_nnn_epis_lnk_dg_outc = i_nnn_epis_lnk_dg_outc;
        
            l_entry_hist.id_nnn_epis_lnk_dg_outc_h := ts_nnn_epis_lnk_dg_outc_h.next_key();
            l_entry_hist.id_nnn_epis_lnk_dg_outc   := l_entry.id_nnn_epis_lnk_dg_outc;
            l_entry_hist.id_nnn_epis_diagnosis     := l_entry.id_nnn_epis_diagnosis;
            l_entry_hist.id_nnn_epis_outcome       := l_entry.id_nnn_epis_outcome;
            l_entry_hist.id_episode                := l_entry.id_episode;
            l_entry_hist.id_professional           := l_entry.id_professional;
            l_entry_hist.flg_lnk_status            := l_entry.flg_lnk_status;
            l_entry_hist.dt_trs_time_start         := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end           := l_time_end;
        
            ts_nnn_epis_lnk_dg_outc_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_lnk_dg_outc_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_intervention     Careplan's NIC Intervention ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_nic_intervention_hist
    (
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_dt_trs_time_end       IN nnn_epis_intervention.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_intervention%ROWTYPE;
        l_entry_hist nnn_epis_intervention_h%ROWTYPE;
        l_time_end   nnn_epis_intervention_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_intervention IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_intervention t
             WHERE t.id_nnn_epis_intervention = i_nnn_epis_intervention;
        
            l_entry_hist.id_nnn_epis_intervention_h := ts_nnn_epis_intervention_h.next_key();
            l_entry_hist.id_nnn_epis_intervention   := l_entry.id_nnn_epis_intervention;
            l_entry_hist.id_nic_intervention        := l_entry.id_nic_intervention;
            l_entry_hist.id_patient                 := l_entry.id_patient;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_visit                   := l_entry.id_visit;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.id_cancel_reason           := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes               := l_entry.cancel_notes;
            l_entry_hist.nic_code                   := l_entry.nic_code;
            l_entry_hist.flg_req_status             := l_entry.flg_req_status;
            l_entry_hist.dt_val_time_start          := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end            := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_intervention_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_nic_intervention_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_lnk_int_actv     Linkage Intervention Activity ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_lnk_int_actv_hist
    (
        i_nnn_epis_lnk_int_actv IN nnn_epis_lnk_int_actv.id_nnn_epis_lnk_int_actv%TYPE,
        i_dt_trs_time_end       IN nnn_epis_lnk_int_actv_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_lnk_int_actv%ROWTYPE;
        l_entry_hist nnn_epis_lnk_int_actv_h%ROWTYPE;
        l_time_end   nnn_epis_lnk_int_actv_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_lnk_int_actv IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_lnk_int_actv t
             WHERE t.id_nnn_epis_lnk_int_actv = i_nnn_epis_lnk_int_actv;
        
            l_entry_hist.id_nnn_epis_lnk_int_actv_h := ts_nnn_epis_lnk_int_actv_h.next_key();
            l_entry_hist.id_nnn_epis_lnk_int_actv   := l_entry.id_nnn_epis_lnk_int_actv;
            l_entry_hist.id_nnn_epis_intervention   := l_entry.id_nnn_epis_intervention;
            l_entry_hist.id_nnn_epis_activity       := l_entry.id_nnn_epis_activity;
            l_entry_hist.interv_activity_code       := l_entry.interv_activity_code;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.flg_lnk_status             := l_entry.flg_lnk_status;
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_lnk_int_actv_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_lnk_int_actv_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_activity         Careplan's NIC Activity ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_nic_activity_hist
    (
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_dt_trs_time_end   IN nnn_epis_activity_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_activity%ROWTYPE;
        l_entry_hist nnn_epis_activity_h%ROWTYPE;
        l_time_end   nnn_epis_activity_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_activity IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_activity t
             WHERE t.id_nnn_epis_activity = i_nnn_epis_activity;
        
            l_entry_hist.id_nnn_epis_activity_h := ts_nnn_epis_activity_h.next_key();
            l_entry_hist.id_nnn_epis_activity   := l_entry.id_nnn_epis_activity;
            l_entry_hist.id_nic_activity        := l_entry.id_nic_activity;
            l_entry_hist.id_nic_othr_actv_vrsn  := l_entry.id_nic_othr_actv_vrsn;
            l_entry_hist.id_patient             := l_entry.id_patient;
            l_entry_hist.id_episode             := l_entry.id_episode;
            l_entry_hist.id_visit               := l_entry.id_visit;
            l_entry_hist.id_professional        := l_entry.id_professional;
            l_entry_hist.id_cancel_reason       := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes           := l_entry.cancel_notes;
            l_entry_hist.id_episode_origin      := l_entry.id_episode_origin;
            l_entry_hist.id_episode_destination := l_entry.id_episode_destination;
            l_entry_hist.flg_prn                := l_entry.flg_prn;
            l_entry_hist.notes_prn              := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes_prn);
            l_entry_hist.flg_time               := l_entry.flg_time;
            l_entry_hist.flg_priority           := l_entry.flg_priority;
            l_entry_hist.id_order_recurr_plan   := l_entry.id_order_recurr_plan;
            l_entry_hist.flg_doc_type           := l_entry.flg_doc_type;
            l_entry_hist.doc_parameter          := l_entry.doc_parameter;
            l_entry_hist.flg_req_status         := l_entry.flg_req_status;
            l_entry_hist.dt_val_time_start      := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end        := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start      := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end        := l_time_end;
        
            ts_nnn_epis_activity_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_nic_activity_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_activity_det     Careplan's NIC Activity execution ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_nic_activity_det_hist
    (
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_dt_trs_time_end       IN nnn_epis_activity_det_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_activity_det%ROWTYPE;
        l_entry_hist nnn_epis_activity_det_h%ROWTYPE;
        l_time_end   nnn_epis_activity_det_h.dt_trs_time_end%TYPE;
    
        l_lst_actv_det_task_h ts_nnn_epis_actv_det_tskh.nnn_epis_actv_det_tskh_tc;
    BEGIN
    
        IF i_nnn_epis_activity_det IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_activity_det t
             WHERE t.id_nnn_epis_activity_det = i_nnn_epis_activity_det;
        
            l_entry_hist.id_nnn_epis_activity_det_h := ts_nnn_epis_activity_det_h.next_key();
            l_entry_hist.id_nnn_epis_activity_det   := l_entry.id_nnn_epis_activity_det;
            l_entry_hist.id_nnn_epis_activity       := l_entry.id_nnn_epis_activity;
            l_entry_hist.id_patient                 := l_entry.id_patient;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_visit                   := l_entry.id_visit;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.id_cancel_reason           := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes               := l_entry.cancel_notes;
            l_entry_hist.dt_plan                    := l_entry.dt_plan;
            l_entry_hist.id_order_recurr_plan       := l_entry.id_order_recurr_plan;
            l_entry_hist.exec_number                := l_entry.exec_number;
            l_entry_hist.notes                      := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes);
            l_entry_hist.id_epis_documentation      := l_entry.id_epis_documentation;
            l_entry_hist.vital_sign_read_list       := l_entry.vital_sign_read_list;
            l_entry_hist.flg_status                 := l_entry.flg_status;
            l_entry_hist.dt_val_time_start          := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end            := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_activity_det_h.ins(rec_in => l_entry_hist);
        
            -- An execution of NIC activity can be also composed by a list of activity tasks (when activity was defined as tasklist).
            -- So when a change to a execution is made, these entries are also copied to historical.
        
            -- Activity tasks
            SELECT seq_nnn_epis_actv_det_tskh.nextval id_nnn_epis_actv_det_tskh,
                   eadt.id_nnn_epis_activity_det,
                   l_entry.dt_trs_time_start dt_trs_time_start,
                   eadt.id_nic_activity,
                   eadt.flg_executed,
                   pk_translation.get_translation_trs(i_code_mess => eadt.code_notes) notes,
                   NULL create_user,
                   NULL create_time,
                   NULL create_institution,
                   NULL update_user,
                   NULL update_time,
                   NULL update_institution
              BULK COLLECT
              INTO l_lst_actv_det_task_h
              FROM nnn_epis_actv_det_task eadt
             WHERE eadt.id_nnn_epis_activity_det = i_nnn_epis_activity_det;
        
            ts_nnn_epis_actv_det_tskh.ins(rows_in => l_lst_actv_det_task_h);
        
        END IF;
    END set_epis_nic_activity_det_hist;

    FUNCTION get_id_hist_epis_activity_det
    (
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_dt_trs_time_end       IN nnn_epis_activity_det_h.dt_trs_time_end%TYPE
    ) RETURN nnn_epis_activity_det_h.id_nnn_epis_activity_det_h%TYPE IS
        l_id nnn_epis_activity_det_h.id_nnn_epis_activity_det_h%TYPE;
    BEGIN
    
        SELECT hst.id_nnn_epis_activity_det_h
          INTO l_id
          FROM nnn_epis_activity_det_h hst
         WHERE hst.id_nnn_epis_activity_det = i_nnn_epis_activity_det
           AND hst.dt_trs_time_end = i_dt_trs_time_end;
        RETURN l_id;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_id_hist_epis_activity_det;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_outcome          Careplan's NOC Outcome ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_noc_outcome_hist
    (
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_dt_trs_time_end  IN nnn_epis_outcome_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_outcome%ROWTYPE;
        l_entry_hist nnn_epis_outcome_h%ROWTYPE;
        l_time_end   nnn_epis_outcome_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_outcome IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_outcome t
             WHERE t.id_nnn_epis_outcome = i_nnn_epis_outcome;
        
            l_entry_hist.id_nnn_epis_outcome_h  := ts_nnn_epis_outcome_h.next_key();
            l_entry_hist.id_nnn_epis_outcome    := l_entry.id_nnn_epis_outcome;
            l_entry_hist.id_noc_outcome         := l_entry.id_noc_outcome;
            l_entry_hist.id_patient             := l_entry.id_patient;
            l_entry_hist.id_episode             := l_entry.id_episode;
            l_entry_hist.id_visit               := l_entry.id_visit;
            l_entry_hist.id_professional        := l_entry.id_professional;
            l_entry_hist.id_cancel_reason       := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes           := l_entry.cancel_notes;
            l_entry_hist.noc_code               := l_entry.noc_code;
            l_entry_hist.id_episode_origin      := l_entry.id_episode_origin;
            l_entry_hist.id_episode_destination := l_entry.id_episode_destination;
            l_entry_hist.flg_prn                := l_entry.flg_prn;
            l_entry_hist.notes_prn              := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes_prn);
            l_entry_hist.flg_time               := l_entry.flg_time;
            l_entry_hist.flg_priority           := l_entry.flg_priority;
            l_entry_hist.id_order_recurr_plan   := l_entry.id_order_recurr_plan;
            l_entry_hist.flg_req_status         := l_entry.flg_req_status;
            l_entry_hist.dt_val_time_start      := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end        := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start      := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end        := l_time_end;
        
            ts_nnn_epis_outcome_h.ins(rec_in => l_entry_hist);
        
        END IF;
    END set_epis_noc_outcome_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_outcome_eval     Careplan's NOC Outcome Evaluation ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_noc_outcome_eval_hist
    (
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_dt_trs_time_end       IN nnn_epis_outcome_eval.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_outcome_eval%ROWTYPE;
        l_entry_hist nnn_epis_outcome_eval_h%ROWTYPE;
        l_time_end   nnn_epis_outcome_eval_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_outcome_eval IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_outcome_eval t
             WHERE t.id_nnn_epis_outcome_eval = i_nnn_epis_outcome_eval;
        
            l_entry_hist.id_nnn_epis_outcome_eval_h := ts_nnn_epis_outcome_eval_h.next_key();
            l_entry_hist.id_nnn_epis_outcome_eval   := l_entry.id_nnn_epis_outcome_eval;
            l_entry_hist.id_nnn_epis_outcome        := l_entry.id_nnn_epis_outcome;
            l_entry_hist.id_patient                 := l_entry.id_patient;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_visit                   := l_entry.id_visit;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.id_cancel_reason           := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes               := l_entry.cancel_notes;
            l_entry_hist.dt_plan                    := l_entry.dt_plan;
            l_entry_hist.id_order_recurr_plan       := l_entry.id_order_recurr_plan;
            l_entry_hist.exec_number                := l_entry.exec_number;
            l_entry_hist.flg_status                 := l_entry.flg_status;
            l_entry_hist.dt_evaluation              := l_entry.dt_evaluation;
            l_entry_hist.target_value               := l_entry.target_value;
            l_entry_hist.outcome_value              := l_entry.outcome_value;
            l_entry_hist.notes                      := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes);
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_outcome_eval_h.ins(rec_in => l_entry_hist);
        
        END IF;
    END set_epis_noc_outcome_eval_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_lnk_outc_ind     Linkage Outcome Indicator ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_lnk_outc_ind_hist
    (
        i_nnn_epis_lnk_outc_ind IN nnn_epis_lnk_outc_ind.id_nnn_epis_lnk_outc_ind%TYPE,
        i_dt_trs_time_end       IN nnn_epis_lnk_outc_ind_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_lnk_outc_ind%ROWTYPE;
        l_entry_hist nnn_epis_lnk_outc_ind_h%ROWTYPE;
        l_time_end   nnn_epis_lnk_outc_ind_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_lnk_outc_ind IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_lnk_outc_ind t
             WHERE t.id_nnn_epis_lnk_outc_ind = i_nnn_epis_lnk_outc_ind;
        
            l_entry_hist.id_nnn_epis_lnk_outc_ind_h := ts_nnn_epis_lnk_outc_ind_h.next_key();
            l_entry_hist.id_nnn_epis_lnk_outc_ind   := l_entry.id_nnn_epis_lnk_outc_ind;
            l_entry_hist.id_nnn_epis_outcome        := l_entry.id_nnn_epis_outcome;
            l_entry_hist.id_nnn_epis_indicator      := l_entry.id_nnn_epis_indicator;
            l_entry_hist.id_episode                 := l_entry.id_episode;
            l_entry_hist.id_professional            := l_entry.id_professional;
            l_entry_hist.outcome_indicator_code     := l_entry.outcome_indicator_code;
            l_entry_hist.flg_lnk_status             := l_entry.flg_lnk_status;
            l_entry_hist.dt_trs_time_start          := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end            := l_time_end;
        
            ts_nnn_epis_lnk_outc_ind_h.ins(rec_in => l_entry_hist);
        
        END IF;
    END set_epis_lnk_outc_ind_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_indicator        Careplan's NOC Indicator ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_noc_indicator_hist
    (
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_dt_trs_time_end    IN nnn_epis_indicator_h.dt_trs_time_end%TYPE
    ) IS
        l_entry      nnn_epis_indicator%ROWTYPE;
        l_entry_hist nnn_epis_indicator_h%ROWTYPE;
        l_time_end   nnn_epis_indicator_h.dt_trs_time_end%TYPE;
    BEGIN
    
        IF i_nnn_epis_indicator IS NOT NULL
        THEN
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_indicator t
             WHERE t.id_nnn_epis_indicator = i_nnn_epis_indicator;
        
            l_entry_hist.id_nnn_epis_indicator_h := ts_nnn_epis_indicator_h.next_key();
            l_entry_hist.id_nnn_epis_indicator   := l_entry.id_nnn_epis_indicator;
            l_entry_hist.id_noc_indicator        := l_entry.id_noc_indicator;
            l_entry_hist.id_noc_othr_ind_vrsn    := l_entry.id_noc_othr_ind_vrsn;
            l_entry_hist.id_patient              := l_entry.id_patient;
            l_entry_hist.id_episode              := l_entry.id_episode;
            l_entry_hist.id_visit                := l_entry.id_visit;
            l_entry_hist.id_professional         := l_entry.id_professional;
            l_entry_hist.id_cancel_reason        := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes            := l_entry.cancel_notes;
            l_entry_hist.id_episode_origin       := l_entry.id_episode_origin;
            l_entry_hist.id_episode_destination  := l_entry.id_episode_destination;
            l_entry_hist.flg_prn                 := l_entry.flg_prn;
            l_entry_hist.notes_prn               := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes_prn);
            l_entry_hist.flg_time                := l_entry.flg_time;
            l_entry_hist.flg_priority            := l_entry.flg_priority;
            l_entry_hist.id_order_recurr_plan    := l_entry.id_order_recurr_plan;
            l_entry_hist.flg_req_status          := l_entry.flg_req_status;
            l_entry_hist.dt_val_time_start       := l_entry.dt_val_time_start;
            l_entry_hist.dt_val_time_end         := l_entry.dt_val_time_end;
            l_entry_hist.dt_trs_time_start       := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end         := l_time_end;
        
            ts_nnn_epis_indicator_h.ins(rec_in => l_entry_hist);
        END IF;
    END set_epis_noc_indicator_hist;

    /**
    * Copy an entry to the history tracking table to record all attributes prior to the change.
    *
    * @param    i_nnn_epis_ind_eval         Careplan's NOC Indicator Evaluation ID
    * @param    i_dt_trs_time_end           Time of the change
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    1/17/2014
    */
    PROCEDURE set_epis_noc_ind_eval_hist
    (
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_dt_trs_time_end   IN nnn_epis_ind_eval.dt_trs_time_end%TYPE
    ) IS
        l_time_end   nnn_epis_ind_eval.dt_trs_time_end%TYPE;
        l_entry      nnn_epis_ind_eval%ROWTYPE;
        l_entry_hist nnn_epis_ind_eval_h%ROWTYPE;
    BEGIN
    
        IF i_nnn_epis_ind_eval IS NOT NULL
        THEN
        
            -- In order to generate unique retained keys, start and end datetime change tracking is required.
            l_time_end := coalesce(i_dt_trs_time_end, current_timestamp);
        
            SELECT t.*
              INTO l_entry
              FROM nnn_epis_ind_eval t
             WHERE t.id_nnn_epis_ind_eval = i_nnn_epis_ind_eval;
        
            l_entry_hist.id_nnn_epis_ind_eval_h := ts_nnn_epis_ind_eval_h.next_key();
            l_entry_hist.id_nnn_epis_ind_eval   := l_entry.id_nnn_epis_ind_eval;
            l_entry_hist.id_nnn_epis_indicator  := l_entry.id_nnn_epis_indicator;
            l_entry_hist.id_patient             := l_entry.id_patient;
            l_entry_hist.id_episode             := l_entry.id_episode;
            l_entry_hist.id_visit               := l_entry.id_visit;
            l_entry_hist.id_professional        := l_entry.id_professional;
            l_entry_hist.id_cancel_reason       := l_entry.id_cancel_reason;
            l_entry_hist.cancel_notes           := l_entry.cancel_notes;
            l_entry_hist.flg_status             := l_entry.flg_status;
            l_entry_hist.dt_plan                := l_entry.dt_plan;
            l_entry_hist.id_order_recurr_plan   := l_entry.id_order_recurr_plan;
            l_entry_hist.exec_number            := l_entry.exec_number;
            l_entry_hist.dt_evaluation          := l_entry.dt_evaluation;
            l_entry_hist.target_value           := l_entry.target_value;
            l_entry_hist.indicator_value        := l_entry.indicator_value;
            l_entry_hist.notes                  := pk_translation.get_translation_trs(i_code_mess => l_entry.code_notes);
            l_entry_hist.dt_trs_time_start      := l_entry.dt_trs_time_start;
            l_entry_hist.dt_trs_time_end        := l_time_end;
        
            ts_nnn_epis_ind_eval_h.ins(rec_in => l_entry_hist);
        
        END IF;
    END set_epis_noc_ind_eval_hist;
    --// History tracking methods - End

    FUNCTION get_epis_nan_diag_defc_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_def_chars IS
        l_lst_defining_characteristic t_coll_obj_nan_def_chars;
    BEGIN
        /*  
         This method fetches defining characteristics documented in a given evaluation at a given date
         allowing in the evaluations that were edited several times be able to obtain which the values that were documented at that point in time.
        
         These two queries in the union should be mutually exclusive and only one returns data; 
         The data of a documented assessment in a specific time (i_dt_trs_time_start) or is the current record 
         or is a past record that is stored in the historic (but cannot be in both).
        */
        SELECT t_obj_nan_def_chars(i_id_nan_def_chars => x.id_nan_def_chars, i_description => x.description)
          BULK COLLECT
          INTO l_lst_defining_characteristic
          FROM (
                -- Historical data
                SELECT ndc.id_nan_def_chars,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ndc.id_terminology_version),
                                                       ndc.code_description) description
                  FROM nnn_epis_diag_defc_h neddh
                 INNER JOIN nan_def_chars ndc
                    ON ndc.id_nan_def_chars = neddh.id_nan_def_chars
                 WHERE neddh.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND neddh.dt_trs_time_start = i_dt_trs_time_start
                UNION ALL
                -- Current data
                SELECT ndc.id_nan_def_chars,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ndc.id_terminology_version),
                                                       ndc.code_description) description
                  FROM nnn_epis_diag_defc nedd
                 INNER JOIN nnn_epis_diag_eval nede
                    ON nede.id_nnn_epis_diag_eval = nedd.id_nnn_epis_diag_eval
                 INNER JOIN nan_def_chars ndc
                    ON ndc.id_nan_def_chars = nedd.id_nan_def_chars
                 WHERE nede.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nede.dt_trs_time_start = i_dt_trs_time_start) x
         ORDER BY x.description;
    
        RETURN l_lst_defining_characteristic;
    END get_epis_nan_diag_defc_h;

    FUNCTION get_epis_nan_diag_rskf_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_risk_factor IS
        l_lst_risk_factor t_coll_obj_nan_risk_factor;
    BEGIN
        /*  
         This method fetches risk factors documented in a given evaluation at a given date
         allowing in the evaluations that were edited several times be able to obtain which the values that were documented at that point in time.
        
         These two queries in the union should be mutually exclusive and only one returns data; 
         The data of a documented assessment in a specific time (i_dt_trs_time_start) or is the current record 
         or is a past record that is stored in the historic (but cannot be in both).
        */
        SELECT t_obj_nan_risk_factor(i_id_nan_risk_factor => x.id_nan_risk_factor, i_description => x.description) rsk
          BULK COLLECT
          INTO l_lst_risk_factor
          FROM (
                -- Historical data
                SELECT nrf.id_nan_risk_factor,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => nrf.id_terminology_version),
                                                       nrf.code_description) description
                  FROM nnn_epis_diag_rskf_h nedrh
                 INNER JOIN nan_risk_factor nrf
                    ON nrf.id_nan_risk_factor = nedrh.id_nan_risk_factor
                 WHERE nedrh.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nedrh.dt_trs_time_start = i_dt_trs_time_start
                UNION ALL
                -- Current data
                SELECT nrf.id_nan_risk_factor,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => nrf.id_terminology_version),
                                                       nrf.code_description) description
                  FROM nnn_epis_diag_rskf nedr
                 INNER JOIN nnn_epis_diag_eval nede
                    ON nede.id_nnn_epis_diag_eval = nedr.id_nnn_epis_diag_eval
                 INNER JOIN nan_risk_factor nrf
                    ON nrf.id_nan_risk_factor = nedr.id_nan_risk_factor
                 WHERE nede.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nede.dt_trs_time_start = i_dt_trs_time_start) x
         ORDER BY x.description;
    
        RETURN l_lst_risk_factor;
    END get_epis_nan_diag_rskf_h;

    FUNCTION get_epis_nan_diag_relf_h
    (
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval_h.id_nnn_epis_diag_eval%TYPE,
        i_dt_trs_time_start  IN nnn_epis_diag_eval_h.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nan_related_factor IS
        l_lst_related_factor t_coll_obj_nan_related_factor;
    
    BEGIN
        /*  
         This method fetches related factors documented in a given evaluation at a given date
         allowing in the evaluations that were edited several times be able to obtain which the values that were documented at that point in time.
        
         These two queries in the union should be mutually exclusive and only one returns data; 
         The data of a documented assessment in a specific time (i_dt_trs_time_start) or is the current record 
         or is a past record that is stored in the historic (but cannot be in both).
        */
        SELECT t_obj_nan_related_factor(i_id_nan_related_factor => x.id_nan_related_factor,
                                        i_description           => x.description)
          BULK COLLECT
          INTO l_lst_related_factor
          FROM (
                -- Historical data
                SELECT nrf.id_nan_related_factor,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => nrf.id_terminology_version),
                                                       nrf.code_description) description
                  FROM nnn_epis_diag_relf_h nedrh
                 INNER JOIN nan_related_factor nrf
                    ON nrf.id_nan_related_factor = nedrh.id_nan_related_factor
                 WHERE nedrh.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nedrh.dt_trs_time_start = i_dt_trs_time_start
                UNION ALL
                -- Current data 
                SELECT nrf.id_nan_related_factor,
                        pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => nrf.id_terminology_version),
                                                       nrf.code_description) description
                  FROM nnn_epis_diag_relf nedr
                 INNER JOIN nnn_epis_diag_eval nede
                    ON nede.id_nnn_epis_diag_eval = nedr.id_nnn_epis_diag_eval
                 INNER JOIN nan_related_factor nrf
                    ON nrf.id_nan_related_factor = nedr.id_nan_related_factor
                 WHERE nede.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nede.dt_trs_time_start = i_dt_trs_time_start) x
         ORDER BY x.description;
    
        RETURN l_lst_related_factor;
    END get_epis_nan_diag_relf_h;

    PROCEDURE upd_noc_outcome_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_current_status nnn_epis_outcome.flg_req_status%TYPE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        SELECT eo.flg_req_status
          INTO l_current_status
          FROM nnn_epis_outcome eo
         WHERE eo.id_nnn_epis_outcome = i_nnn_epis_outcome;
        IF l_current_status != i_flg_req_status
           AND NOT is_req_final_state(i_flg_req_status => l_current_status)
        THEN
            --Add original entry to tracking history of changes
            set_epis_noc_outcome_hist(i_nnn_epis_outcome => i_nnn_epis_outcome, i_dt_trs_time_end => l_timestamp);
            -- Update entry
            ts_nnn_epis_outcome.upd(id_nnn_epis_outcome_in => i_nnn_epis_outcome,
                                    id_professional_in     => i_prof.id,
                                    flg_req_status_in      => i_flg_req_status,
                                    dt_trs_time_start_in   => l_timestamp,
                                    dt_val_time_end_in     => CASE
                                                               is_req_final_state(i_flg_req_status => i_flg_req_status)
                                                                  WHEN TRUE THEN
                                                                   l_timestamp
                                                                  ELSE
                                                                   NULL
                                                              END,
                                    
                                    rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_OUTCOME',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
    END upd_noc_outcome_status;

    PROCEDURE upd_noc_indicator_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_current_status nnn_epis_indicator.flg_req_status%TYPE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        SELECT ei.flg_req_status
          INTO l_current_status
          FROM nnn_epis_indicator ei
         WHERE ei.id_nnn_epis_indicator = i_nnn_epis_indicator;
    
        IF l_current_status != i_flg_req_status
           AND NOT is_req_final_state(i_flg_req_status => l_current_status)
        THEN
            -- Add original entry to tracking history of changes
            set_epis_noc_indicator_hist(i_nnn_epis_indicator => i_nnn_epis_indicator, i_dt_trs_time_end => l_timestamp);
            -- Update entry          
            ts_nnn_epis_indicator.upd(id_nnn_epis_indicator_in => i_nnn_epis_indicator,
                                      id_professional_in       => i_prof.id,
                                      flg_req_status_in        => i_flg_req_status,
                                      dt_trs_time_start_in     => l_timestamp,
                                      dt_val_time_end_in       => CASE
                                                                   is_req_final_state(i_flg_req_status => i_flg_req_status)
                                                                      WHEN TRUE THEN
                                                                       l_timestamp
                                                                      ELSE
                                                                       NULL
                                                                  END,
                                      rows_out                 => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INDICATOR',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    END upd_noc_indicator_status;

    FUNCTION get_outcome_eval_progress
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_order_recurr_plan IN nnn_epis_outcome.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_outcome_eval_progress';
        l_rec_plan_info        t_recurr_plan_info_rec;
        l_total_evaluations    NUMBER(24);
        l_executed_evaluations NUMBER(24);
        l_format               VARCHAR(1000 CHAR) := '';
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_order_recurr_plan IS NOT NULL
        THEN
        
            l_rec_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                        i_prof              => i_prof,
                                                                                        i_order_recurr_plan => i_order_recurr_plan);
        END IF;
        l_total_evaluations := coalesce(l_rec_plan_info.occurrences, 0);
    
        SELECT COUNT(*)
          INTO l_executed_evaluations
          FROM nnn_epis_outcome_eval eoe
         WHERE eoe.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND eoe.flg_status = pk_nnn_constant.g_task_status_finished;
    
        IF l_total_evaluations > 0
           AND l_executed_evaluations <= l_total_evaluations
        THEN
        
            l_format := to_char(l_executed_evaluations) || '/' || to_char(l_total_evaluations);
        ELSE
            l_format := to_char(l_executed_evaluations) || '/' || pk_icnp_constant.g_word_no_record;
        END IF;
    
        RETURN l_format;
    
    END get_outcome_eval_progress;

    FUNCTION get_indicator_eval_progress
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_order_recurr_plan  IN nnn_epis_indicator.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_indicator_eval_progress';
        l_rec_plan_info        t_recurr_plan_info_rec;
        l_total_evaluations    NUMBER(24);
        l_executed_evaluations NUMBER(24);
        l_format               VARCHAR(1000 CHAR) := '';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_order_recurr_plan IS NOT NULL
        THEN
            l_rec_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                        i_prof              => i_prof,
                                                                                        i_order_recurr_plan => i_order_recurr_plan);
        END IF;
        l_total_evaluations := coalesce(l_rec_plan_info.occurrences, 0);
    
        SELECT COUNT(*)
          INTO l_executed_evaluations
          FROM nnn_epis_ind_eval eie
         WHERE eie.id_nnn_epis_indicator = i_nnn_epis_indicator
           AND eie.flg_status = pk_nnn_constant.g_task_status_finished;
    
        IF l_total_evaluations > 0
           AND l_executed_evaluations <= l_total_evaluations
        THEN
            l_format := to_char(l_executed_evaluations) || '/' || to_char(l_total_evaluations);
        ELSE
            l_format := to_char(l_executed_evaluations) || '/' || pk_icnp_constant.g_word_no_record;
        END IF;
    
        RETURN l_format;
    END get_indicator_eval_progress;

    FUNCTION get_activity_det_progress
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_activity_det_progress';
        l_rec_plan_info    t_recurr_plan_info_rec;
        l_total_executions NUMBER(24);
        l_executed         NUMBER(24);
        l_format           VARCHAR(1000 CHAR) := '';
    BEGIN
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec_plan_info    := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                       i_prof              => i_prof,
                                                                                       i_order_recurr_plan => i_order_recurr_plan);
        l_total_executions := coalesce(l_rec_plan_info.occurrences, 0);
    
        SELECT COUNT(*)
          INTO l_executed
          FROM nnn_epis_activity_det ead
         WHERE ead.id_nnn_epis_activity = i_nnn_epis_activity
           AND ead.flg_status = pk_nnn_constant.g_task_status_finished;
    
        IF l_total_executions > 0
           AND l_executed <= l_total_executions
        THEN
            l_format := to_char(l_executed) || '/' || to_char(l_total_executions);
        ELSE
            l_format := to_char(l_executed) || '/' || pk_icnp_constant.g_word_no_record;
        END IF;
    
        RETURN l_format;
    END get_activity_det_progress;

    PROCEDURE get_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_diagnosis          OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nan_diagnosis';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- get the information about diagnosis
        OPEN o_diagnosis FOR
            SELECT ed.id_nnn_epis_diagnosis,
                   pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ed.id_nan_diagnosis) diagnosis_name,
                   ed.id_nan_diagnosis,
                   ed.id_cancel_reason,
                   ed.cancel_notes,
                   ed.nanda_code,
                   ed.edited_diagnosis_name diagnosis_notes,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_diagnosis, i_prof) dt_diagnosis,
                   ed.flg_req_status,
                   pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status, ed.flg_req_status, i_lang) desc_flg_req_status
              FROM nnn_epis_diagnosis ed
             WHERE ed.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis;
    
    END get_epis_nan_diagnosis;

    FUNCTION get_epis_nan_diagnosis_row(i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE)
        RETURN nnn_epis_diagnosis%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nan_diagnosis_row';
        l_rec nnn_epis_diagnosis%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT ned.*
          INTO l_rec
          FROM nnn_epis_diagnosis ned
         WHERE ned.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis;
    
        RETURN l_rec;
    END get_epis_nan_diagnosis_row;

    PROCEDURE get_epis_nan_diagnosis_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_eval               OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nan_diagnosis_eval';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_diag_eval = ' || coalesce(to_char(i_nnn_epis_diag_eval), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --get the information of evaluation diagnosis
        OPEN o_eval FOR
            SELECT nede.id_nnn_epis_diag_eval,
                   nede.id_nnn_epis_diagnosis,
                   ned.id_nan_diagnosis,
                   pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ned.id_nan_diagnosis,
                                                       i_code_format   => pk_nan_model.g_code_format_end) diagnosis_name,
                   pk_date_utils.date_send_tsz(i_lang, ned.dt_diagnosis, i_prof) dt_diagnosis,
                   ned.edited_diagnosis_name diagnosis_notes,
                   nede.flg_status,
                   pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status, nede.flg_status, i_lang) desc_flg_status,
                   pk_date_utils.date_send_tsz(i_lang, nede.dt_evaluation, i_prof) dt_evaluation,
                   pk_translation.get_translation_trs(nede.code_notes) desc_notes,
                   -- get the list of defining characterists
                   CAST(MULTISET (SELECT nedd.id_nan_def_chars
                           FROM nnn_epis_diag_defc nedd
                          WHERE nedd.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval) AS table_number) lst_def_chars,
                   -- get the list of risk factors
                   CAST(MULTISET (SELECT nedr.id_nan_risk_factor
                           FROM nnn_epis_diag_rskf nedr
                          WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval) AS table_number) lst_risk_factors,
                   -- get the list of related factors                        
                   CAST(MULTISET (SELECT nedr.id_nan_related_factor
                           FROM nnn_epis_diag_relf nedr
                          WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval) AS table_number) lst_rel_factors
              FROM nnn_epis_diag_eval nede
             INNER JOIN nnn_epis_diagnosis ned
                ON nede.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
             WHERE nede.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
    
    END get_epis_nan_diagnosis_eval;

    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_priority      IN nnn_epis_activity.flg_priority%TYPE,
        i_flg_prn           IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn         IN CLOB DEFAULT NULL,
        i_flg_time          IN nnn_epis_activity.flg_time%TYPE,
        i_start_date        IN nnn_epis_activity.dt_val_time_start%TYPE DEFAULT NULL,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        i_mask              IN pk_translation.t_low_char DEFAULT pk_nnn_constant.g_inst_format_mask_default
    ) RETURN pk_translation.t_hug_byte IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_instructions';
    
        -- Text that is going to be returned
        l_instruction_desc pk_translation.t_hug_byte;
    
        -- Gets the text with the priority of the task
        FUNCTION get_priority_desc RETURN pk_translation.t_big_char IS
            l_priority_desc pk_translation.t_big_char := '';
        BEGIN
            l_priority_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_nnn_constant.g_mcode_priority);
            IF i_flg_priority IS NOT NULL
            THEN
                l_priority_desc := pk_string_utils.concat_if_exists(i_str1 => l_priority_desc,
                                                                    i_str2 => pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority,
                                                                                                      i_val      => i_flg_priority,
                                                                                                      i_lang     => i_lang),
                                                                    i_sep  => pk_icnp_constant.g_word_space);
            ELSE
                l_priority_desc := pk_string_utils.concat_if_exists(i_str1 => l_priority_desc,
                                                                    i_str2 => pk_icnp_constant.g_word_no_record,
                                                                    i_sep  => pk_icnp_constant.g_word_space);
            END IF;
            RETURN l_priority_desc;
        END get_priority_desc;
    
        -- Gets the text with the PRN of the task
        FUNCTION get_prn_desc RETURN pk_translation.t_big_char IS
            l_prn_desc pk_translation.t_big_char := '';
        BEGIN
            l_prn_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_nnn_constant.g_mcode_prn);
            IF i_flg_prn IS NOT NULL
            THEN
                -- Label "PRN:"
                l_prn_desc := pk_string_utils.concat_if_exists(i_str1 => l_prn_desc,
                                                               i_str2 => pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn,
                                                                                                 i_val      => i_flg_prn,
                                                                                                 i_lang     => i_lang),
                                                               i_sep  => pk_icnp_constant.g_word_space);
                IF i_flg_prn = pk_alert_constant.g_yes
                   AND dbms_lob.getlength(i_notes_prn) > 0
                THEN
                    -- Label "PRN Condition:"
                    l_prn_desc := pk_string_utils.concat_if_exists(i_str1 => l_prn_desc,
                                                                   i_str2 => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => pk_nnn_constant.g_mcode_prn_cond),
                                                                   i_sep  => pk_icnp_constant.g_word_sep);
                    -- Condition
                    l_prn_desc := pk_string_utils.concat_if_exists(i_str1 => l_prn_desc,
                                                                   i_str2 => i_notes_prn,
                                                                   i_sep  => pk_icnp_constant.g_word_space);
                END IF;
            
            ELSE
                l_prn_desc := pk_string_utils.concat_if_exists(i_str1 => l_prn_desc,
                                                               i_str2 => pk_icnp_constant.g_word_no_record,
                                                               i_sep  => pk_icnp_constant.g_word_space);
            END IF;
            RETURN l_prn_desc;
        
        END get_prn_desc;
    
        -- Gets the text that describes in which episode the task should be performed
        FUNCTION get_perform_desc RETURN pk_translation.t_big_char IS
            l_perform_desc pk_translation.t_big_char := '';
        BEGIN
            l_perform_desc := pk_message.get_message(i_lang      => i_lang,
                                                     i_code_mess => pk_nnn_constant.g_mcode_to_be_perform);
            IF i_flg_time IS NOT NULL
            THEN
                l_perform_desc := pk_string_utils.concat_if_exists(i_str1 => l_perform_desc,
                                                                   i_str2 => pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_time,
                                                                                                     i_val      => i_flg_time,
                                                                                                     i_lang     => i_lang),
                                                                   i_sep  => pk_icnp_constant.g_word_space);
            ELSE
                l_perform_desc := pk_string_utils.concat_if_exists(i_str1 => l_perform_desc,
                                                                   i_str2 => pk_icnp_constant.g_word_no_record,
                                                                   i_sep  => pk_icnp_constant.g_word_space);
            END IF;
            RETURN l_perform_desc;
        END get_perform_desc;
    
        -- Gets the text with the frequency of the executions
        FUNCTION get_frequency_desc RETURN pk_translation.t_big_char IS
            l_frequency_desc pk_translation.t_big_char := '';
        BEGIN
            l_frequency_desc := pk_message.get_message(i_lang      => i_lang,
                                                       i_code_mess => pk_nnn_constant.g_mcode_frequency);
        
            IF i_order_recurr_plan IS NOT NULL
            THEN
                l_frequency_desc := pk_string_utils.concat_if_exists(i_str1 => l_frequency_desc,
                                                                     i_str2 => pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                                                                                     i_prof              => i_prof,
                                                                                                                                     i_order_recurr_plan => i_order_recurr_plan),
                                                                     i_sep  => pk_icnp_constant.g_word_space);
            ELSE
                l_frequency_desc := pk_string_utils.concat_if_exists(i_str1 => l_frequency_desc,
                                                                     i_str2 => pk_translation.get_translation(i_lang      => i_lang,
                                                                                                              i_code_mess => pk_nnn_constant.g_dom_order_rec_option_no_sch),
                                                                     i_sep  => pk_icnp_constant.g_word_space);
            
            END IF;
        
            RETURN l_frequency_desc;
        END get_frequency_desc;
    
        -- Gets the text that describes when the task should be performed
        FUNCTION get_start_date_desc RETURN pk_translation.t_big_char IS
            l_dt_begin_desc pk_translation.t_big_char := '';
        BEGIN
        
            l_dt_begin_desc := pk_string_utils.concat_if_exists(i_str1 => pk_message.get_message(i_lang      => i_lang,
                                                                                                 i_code_mess => pk_nnn_constant.g_mcode_start_date),
                                                                i_str2 => coalesce(pk_nnn_core.get_start_date_desc(i_lang              => i_lang,
                                                                                                                   i_prof              => i_prof,
                                                                                                                   i_order_recurr_plan => i_order_recurr_plan,
                                                                                                                   i_start_date        => i_start_date),
                                                                                   pk_icnp_constant.g_word_no_record),
                                                                i_sep  => pk_icnp_constant.g_word_space);
            RETURN l_dt_begin_desc;
        END get_start_date_desc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_flg_priority = ' || coalesce(i_flg_priority, '<null>');
        g_error := g_error || ' i_flg_prn = ' || coalesce(i_flg_prn, '<null>');
        g_error := g_error || ' i_flg_time = ' || coalesce(i_flg_time, '<null>');
        g_error := g_error || ' i_start_date = ' || coalesce(to_char(i_start_date, 'DD-MON-YYYY HH24:MI'), '<null>');
        g_error := g_error || ' i_order_recurr_plan = ' || coalesce(to_char(i_order_recurr_plan), '<null>');
        g_error := g_error || ' i_mask = ' || coalesce(i_mask, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Loop through the mask options and add them to the instructions string
        FOR i IN 1 .. length(i_mask)
        LOOP
            CASE substr(i_mask, i, 1)
                WHEN pk_nnn_constant.g_inst_format_opt_priority THEN
                    l_instruction_desc := pk_string_utils.concat_if_exists(i_str1 => l_instruction_desc,
                                                                           i_str2 => get_priority_desc(),
                                                                           i_sep  => pk_icnp_constant.g_word_sep);
                WHEN pk_nnn_constant.g_inst_format_opt_prn THEN
                    l_instruction_desc := pk_string_utils.concat_if_exists(i_str1 => l_instruction_desc,
                                                                           i_str2 => get_prn_desc(),
                                                                           i_sep  => pk_icnp_constant.g_word_sep);
                WHEN pk_nnn_constant.g_inst_format_opt_time_perform THEN
                    l_instruction_desc := pk_string_utils.concat_if_exists(i_str1 => l_instruction_desc,
                                                                           i_str2 => get_perform_desc(),
                                                                           i_sep  => pk_icnp_constant.g_word_sep);
                WHEN pk_nnn_constant.g_inst_format_opt_frequency THEN
                    l_instruction_desc := pk_string_utils.concat_if_exists(i_str1 => l_instruction_desc,
                                                                           i_str2 => get_frequency_desc(),
                                                                           i_sep  => pk_icnp_constant.g_word_sep);
                WHEN pk_nnn_constant.g_inst_format_opt_start_date THEN
                    l_instruction_desc := pk_string_utils.concat_if_exists(i_str1 => l_instruction_desc,
                                                                           i_str2 => get_start_date_desc(),
                                                                           i_sep  => pk_icnp_constant.g_word_sep);
                ELSE
                    NULL;
            END CASE;
        END LOOP;
    
        RETURN l_instruction_desc;
    END get_instructions;

    FUNCTION get_frequency_desc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_option  IN order_recurr_plan.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_frequency_desc';
        l_order_plan_desc VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_id_order_recurr_plan = ' || coalesce(to_char(i_id_order_recurr_plan), '<null>');
        g_error := g_error || ' i_order_recurr_option = ' || coalesce(to_char(i_order_recurr_option), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Gets the text with the frequency of the executions
        CASE i_order_recurr_option
            WHEN pk_nnn_constant.g_order_recurr_option_once THEN
                l_order_plan_desc := pk_translation.get_translation(i_lang, pk_nnn_constant.g_dom_order_rec_option_once);
            
            WHEN pk_nnn_constant.g_order_recurr_option_no_sch THEN
                l_order_plan_desc := pk_translation.get_translation(i_lang,
                                                                    pk_nnn_constant.g_dom_order_rec_option_no_sch);
            ELSE
                IF i_id_order_recurr_plan IS NOT NULL
                THEN
                
                    l_order_plan_desc := pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                                               i_prof              => i_prof,
                                                                                               i_order_recurr_plan => i_id_order_recurr_plan);
                ELSE
                    l_order_plan_desc := pk_translation.get_translation(i_lang,
                                                                        pk_nnn_constant.g_dom_order_rec_option_no_sch);
                END IF;
        END CASE;
    
        RETURN l_order_plan_desc;
    END get_frequency_desc;

    FUNCTION get_start_date_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_start_date        IN order_recurr_plan.start_date%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_start_date       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_desc    pk_translation.t_big_char;
        l_recurr_plan_info t_recurr_plan_info_rec;
    BEGIN
    
        IF i_start_date IS NULL
           AND i_order_recurr_plan IS NOT NULL
        THEN
            l_recurr_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                           i_prof              => i_prof,
                                                                                           i_order_recurr_plan => i_order_recurr_plan);
            l_start_date       := l_recurr_plan_info.start_date;
        ELSE
            l_start_date := i_start_date;
        END IF;
    
        IF l_start_date IS NOT NULL
        THEN
            l_dt_begin_desc := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                           i_date => l_start_date,
                                                           i_inst => i_prof.institution,
                                                           i_soft => i_prof.software);
        END IF;
    
        RETURN l_dt_begin_desc;
    
    END get_start_date_desc;

    FUNCTION get_start_date
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN order_recurr_plan.start_date%TYPE IS
        l_start_date       order_recurr_plan.start_date%TYPE;
        l_recurr_plan_info t_recurr_plan_info_rec;
    BEGIN
        IF i_order_recurr_plan IS NOT NULL
        THEN
            l_recurr_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                           i_prof              => i_prof,
                                                                                           i_order_recurr_plan => i_order_recurr_plan);
            l_start_date       := l_recurr_plan_info.start_date;
        END IF;
        RETURN l_start_date;
    END get_start_date;

    FUNCTION recurr_option_to_freq_type(i_order_recurr_option IN order_recurr_plan.id_order_recurr_option%TYPE)
        RETURN VARCHAR2 IS
        l_freq_type VARCHAR2(1 CHAR);
    BEGIN
        IF i_order_recurr_option IS NOT NULL
        THEN
            CASE i_order_recurr_option
                WHEN pk_order_recurrence_core.g_order_recurr_option_once THEN
                    l_freq_type := pk_nnn_constant.g_req_freq_once;
                WHEN pk_order_recurrence_core.g_order_recurr_option_no_sched THEN
                    l_freq_type := pk_nnn_constant.g_req_freq_no_schedule;
                ELSE
                    l_freq_type := pk_nnn_constant.g_req_freq_recurrence;
            END CASE;
        ELSE
            l_freq_type := pk_nnn_constant.g_req_freq_no_schedule;
        END IF;
    
        RETURN l_freq_type;
    END recurr_option_to_freq_type;

    PROCEDURE get_epis_noc_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_outcome          OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome';
        l_dt_last_evaluation nnn_epis_outcome_eval.dt_evaluation%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' id_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --The minimum start date for an outcome's request is the start date of the episode or, if available, the date of the last evaluation.
        BEGIN
            SELECT t.dt_evaluation
              INTO l_dt_last_evaluation
              FROM TABLE(tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => i_nnn_epis_outcome)) t;
        EXCEPTION
            WHEN no_data_found THEN
                -- No evaluations yet
                l_dt_last_evaluation := NULL;
        END;
    
        -- get info about outcome and it's instructions
        OPEN o_outcome FOR
            SELECT neo.id_nnn_epis_outcome,
                   neo.id_noc_outcome,
                   pk_noc_model.get_outcome_name(i_noc_outcome => neo.id_noc_outcome) outcome_name,
                   neo.flg_priority,
                   neo.flg_time,
                   neo.flg_prn,
                   pk_translation.get_translation_trs(neo.code_notes_prn) desc_notes_prn,
                   neo.id_order_recurr_plan,
                   neo.flg_req_status,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => decode(l_dt_last_evaluation,
                                                                NULL,
                                                                e.dt_begin_tstz,
                                                                l_dt_last_evaluation),
                                               i_prof => i_prof) dt_min_start_date
              FROM nnn_epis_outcome neo
             INNER JOIN episode e
                ON neo.id_episode = e.id_episode
             WHERE neo.id_nnn_epis_outcome = i_nnn_epis_outcome;
    
    END get_epis_noc_outcome;

    FUNCTION get_epis_noc_outcome_row(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN nnn_epis_outcome%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_row';
        l_rec nnn_epis_outcome%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neo.*
          INTO l_rec
          FROM nnn_epis_outcome neo
         WHERE neo.id_nnn_epis_outcome = i_nnn_epis_outcome;
    
        RETURN l_rec;
    END get_epis_noc_outcome_row;

    FUNCTION get_epis_noc_outcome_eval_row(i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE)
        RETURN nnn_epis_outcome_eval%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_eval_row';
        l_rec nnn_epis_outcome_eval%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome_eval = ' || coalesce(to_char(i_nnn_epis_outcome_eval), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neoe.*
          INTO l_rec
          FROM nnn_epis_outcome_eval neoe
         WHERE neoe.id_nnn_epis_outcome_eval = i_nnn_epis_outcome_eval;
    
        RETURN l_rec;
    END get_epis_noc_outcome_eval_row;

    PROCEDURE get_epis_noc_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_indicator          OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_indicator';
        l_dt_last_evaluation nnn_epis_ind_eval.dt_evaluation%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --The minimum start date for an outcome's request is the start date of the episode or, if available, the date of the last evaluation.
        BEGIN
            SELECT t.dt_evaluation
              INTO l_dt_last_evaluation
              FROM TABLE(tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => i_nnn_epis_indicator)) t;
        EXCEPTION
            WHEN no_data_found THEN
                -- No evaluations yet
                l_dt_last_evaluation := NULL;
        END;
    
        -- get info about indicator and it's instructions
        OPEN o_indicator FOR
            SELECT nei.id_nnn_epis_indicator,
                   nei.id_noc_indicator,
                   pk_noc_model.get_indicator_name(i_noc_indicator => nei.id_noc_indicator) indicator_name,
                   nei.flg_priority,
                   nei.flg_time,
                   nei.flg_prn,
                   pk_translation.get_translation_trs(nei.code_notes_prn) desc_notes_prn,
                   nei.id_order_recurr_plan,
                   nei.flg_req_status,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => decode(l_dt_last_evaluation,
                                                                NULL,
                                                                e.dt_begin_tstz,
                                                                l_dt_last_evaluation),
                                               i_prof => i_prof) dt_min_start_date
              FROM nnn_epis_indicator nei
             INNER JOIN episode e
                ON nei.id_episode = e.id_episode
             WHERE nei.id_nnn_epis_indicator = i_nnn_epis_indicator;
    
    END get_epis_noc_indicator;

    FUNCTION get_epis_noc_indicator_row(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN nnn_epis_indicator%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_indicator_row';
        l_rec nnn_epis_indicator%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nei.*
          INTO l_rec
          FROM nnn_epis_indicator nei
         WHERE nei.id_nnn_epis_indicator = i_nnn_epis_indicator;
    
        RETURN l_rec;
    END get_epis_noc_indicator_row;

    PROCEDURE get_epis_noc_indicator_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_eval              OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_indicator_eval';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_nnn_epis_ind_eval = ' || coalesce(to_char(i_nnn_epis_ind_eval), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- get info about evaluation indicator
        -- checks whether the indicator has its scale in noc_outcome_indicator
        -- if there will fetch the scale of outcome in noc_outcome
        OPEN o_eval FOR
            SELECT t.id_nnn_epis_indicator,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_evaluation, i_prof) dt_evaluation,
                   t.target_value,
                   t.indicator_value,
                   pk_noc_model.get_scale_level_name(i_lang              => i_lang,
                                                     i_noc_scale         => t.id_noc_scale,
                                                     i_scale_level_value => t.target_value) desc_target_value,
                   pk_noc_model.get_scale_level_name(i_lang              => i_lang,
                                                     i_noc_scale         => t.id_noc_scale,
                                                     i_scale_level_value => t.indicator_value) desc_indicator_value,
                   pk_translation.get_translation_trs(t.code_notes) desc_notes
              FROM (SELECT neie.id_nnn_epis_indicator,
                           neie.dt_evaluation,
                           neie.target_value,
                           neie.indicator_value,
                           pk_noc_model.get_indicator_scale(i_noc_outcome   => neo.id_noc_outcome,
                                                            i_noc_indicator => nei.id_noc_indicator) id_noc_scale,
                           neie.code_notes
                      FROM nnn_epis_ind_eval neie
                     INNER JOIN nnn_epis_indicator nei
                        ON neie.id_nnn_epis_indicator = nei.id_nnn_epis_indicator
                     INNER JOIN nnn_epis_lnk_outc_ind neloi
                        ON nei.id_nnn_epis_indicator = neloi.id_nnn_epis_indicator
                     INNER JOIN nnn_epis_outcome neo
                        ON neloi.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
                     WHERE neloi.id_nnn_epis_outcome = i_nnn_epis_outcome
                       AND neie.id_nnn_epis_ind_eval = i_nnn_epis_ind_eval) t;
    
    END get_epis_noc_indicator_eval;

    FUNCTION get_epis_noc_ind_eval_row(i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE)
        RETURN nnn_epis_ind_eval%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_ind_eval_row';
        l_rec nnn_epis_ind_eval%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_ind_eval = ' || coalesce(to_char(i_nnn_epis_ind_eval), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neie.*
          INTO l_rec
          FROM nnn_epis_ind_eval neie
         WHERE neie.id_nnn_epis_ind_eval = i_nnn_epis_ind_eval;
    
        RETURN l_rec;
    END get_epis_noc_ind_eval_row;

    PROCEDURE get_epis_nic_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_activity          OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_activity';
        l_dt_last_execution nnn_epis_activity_det.dt_val_time_start%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --The minimum start date for an activity's request is the start date of the episode or, if available, the date of the last execution.
        BEGIN
            SELECT dt_val_time_start
              INTO l_dt_last_execution
              FROM (SELECT t.dt_val_time_start
                      FROM (SELECT row_number() over(PARTITION BY nead.id_nnn_epis_activity ORDER BY nead.dt_val_time_start DESC, nead.dt_trs_time_start DESC) rn,
                                   nead.dt_val_time_start
                              FROM nnn_epis_activity_det nead
                             WHERE nead.id_nnn_epis_activity = i_nnn_epis_activity
                               AND nead.flg_status = pk_nnn_constant.g_task_status_finished) t
                     WHERE t.rn = 1);
        EXCEPTION
            WHEN no_data_found THEN
                -- No executions yet
                l_dt_last_execution := NULL;
        END;
    
        -- get info about activity and it's instructions
        OPEN o_activity FOR
            SELECT nea.id_nnn_epis_activity,
                   nea.id_nic_activity,
                   pk_nic_model.get_activity_name(i_nic_activity => nea.id_nic_activity) activity_name,
                   nea.flg_priority,
                   nea.flg_time,
                   nea.flg_prn,
                   pk_translation.get_translation_trs(nea.code_notes_prn) desc_notes_prn,
                   nea.id_order_recurr_plan,
                   nea.flg_req_status,
                   pk_date_utils.date_send_tsz(i_lang => i_lang,
                                               i_date => decode(l_dt_last_execution,
                                                                NULL,
                                                                e.dt_begin_tstz,
                                                                l_dt_last_execution),
                                               i_prof => i_prof) dt_min_start_date,
                   nea.flg_doc_type,
                   nea.doc_parameter
              FROM nnn_epis_activity nea
             INNER JOIN episode e
                ON nea.id_episode = e.id_episode
             WHERE nea.id_nnn_epis_activity = i_nnn_epis_activity;
    
    END get_epis_nic_activity;

    FUNCTION get_epis_nic_activity_det_row(i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE)
        RETURN nnn_epis_activity_det%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_row';
        l_rec nnn_epis_activity_det%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_activity_det = ' || coalesce(to_char(i_nnn_epis_activity_det), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nead.*
          INTO l_rec
          FROM nnn_epis_activity_det nead
         WHERE nead.id_nnn_epis_activity_det = i_nnn_epis_activity_det;
    
        RETURN l_rec;
    END get_epis_nic_activity_det_row;

    FUNCTION get_epis_nic_activity_row(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE)
        RETURN nnn_epis_activity%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_activity_row';
        l_rec nnn_epis_activity%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_nic_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nea.*
          INTO l_rec
          FROM nnn_epis_activity nea
         WHERE nea.id_nnn_epis_activity = i_nnn_epis_activity;
    
        RETURN l_rec;
    END get_epis_nic_activity_row;

    FUNCTION get_epis_nic_intervention_row(i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE)
        RETURN nnn_epis_intervention%ROWTYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_intervention_row';
        l_rec nnn_epis_intervention%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nei.*
          INTO l_rec
          FROM nnn_epis_intervention nei
         WHERE nei.id_nnn_epis_intervention = i_nnn_epis_intervention;
    
        RETURN l_rec;
    END get_epis_nic_intervention_row;

    PROCEDURE set_lnk_diagnosis_outcome
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN nnn_epis_lnk_dg_outc.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_outc.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_outcome   IN nnn_epis_lnk_dg_outc.id_nnn_epis_outcome%TYPE,
        i_flg_lnk_status     IN nnn_epis_lnk_dg_outc.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_diagnosis_outcome';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_lnk_dg_outc%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error     := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error     := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error     := g_error || ' i_flg_lnk_status = ' || coalesce(to_char(i_flg_lnk_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Check if already exists a link between the two itens retrieving the ID
        BEGIN
            SELECT lnkdo.id_nnn_epis_lnk_dg_outc
              INTO l_rec.id_nnn_epis_lnk_dg_outc
              FROM nnn_epis_lnk_dg_outc lnkdo
             WHERE lnkdo.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
               AND lnkdo.id_nnn_epis_outcome = i_nnn_epis_outcome;
        EXCEPTION
            WHEN no_data_found THEN
                l_rec.id_nnn_epis_lnk_dg_outc := NULL; -- There is not yet a link between these two items. Just ignore.
        END;
    
        l_rec.id_nnn_epis_diagnosis := i_nnn_epis_diagnosis;
        l_rec.id_nnn_epis_outcome   := i_nnn_epis_outcome;
        l_rec.id_episode            := i_episode;
        l_rec.id_professional       := i_prof.id;
        l_rec.flg_lnk_status        := i_flg_lnk_status;
        l_rec.dt_trs_time_start     := l_timestamp;
    
        IF l_rec.id_nnn_epis_lnk_dg_outc IS NULL
        THEN
            l_rec.id_nnn_epis_lnk_dg_outc := ts_nnn_epis_lnk_dg_outc.next_key();
            ts_nnn_epis_lnk_dg_outc.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_DG_OUTC',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        ELSE
            -- Add original entry to tracking history of changes          
            set_epis_lnk_dg_outc_hist(i_nnn_epis_lnk_dg_outc => l_rec.id_nnn_epis_lnk_dg_outc,
                                      i_dt_trs_time_end      => l_timestamp);
            -- Update entry                    
            ts_nnn_epis_lnk_dg_outc.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_DG_OUTC',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
    END set_lnk_diagnosis_outcome;

    FUNCTION set_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nan_diagnosis      IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_dt_diagnosis       IN nnn_epis_diagnosis.dt_diagnosis%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE DEFAULT NULL,
        i_notes              IN nnn_epis_diagnosis.edited_diagnosis_name%TYPE DEFAULT NULL,
        i_flg_req_status     IN nnn_epis_diagnosis.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nan_diagnosis';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_diagnosis%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_nnn_epis_diagnosis IS NOT NULL
        THEN
            l_rec := get_epis_nan_diagnosis_row(i_nnn_epis_diagnosis => i_nnn_epis_diagnosis);
        END IF;
    
        l_rec.id_nnn_epis_diagnosis := i_nnn_epis_diagnosis;
        l_rec.id_nan_diagnosis      := i_nan_diagnosis;
        l_rec.id_patient            := i_patient;
        l_rec.id_episode            := i_episode;
        l_rec.id_visit              := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional       := i_prof.id;
        l_rec.nanda_code            := pk_nan_model.get_nanda_code(i_nan_diagnosis => i_nan_diagnosis);
        l_rec.edited_diagnosis_name := i_notes;
        l_rec.dt_diagnosis          := i_dt_diagnosis;
        l_rec.flg_req_status        := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_ordered);
        l_rec.dt_trs_time_start     := l_timestamp;
        l_rec.dt_trs_time_end       := NULL;
        IF l_rec.id_nnn_epis_diagnosis IS NULL
        THEN
            l_rec.id_nnn_epis_diagnosis := ts_nnn_epis_diagnosis.next_key();
            l_rec.dt_val_time_start     := l_timestamp; -- The valid time start of the Dx request (sets once when is created and inmutable during the lifecycle of this request)
            l_rec.dt_val_time_end       := NULL; -- The valid time end of the Dx request (sets once when is cancelated/finished)
        
            ts_nnn_epis_diagnosis.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_DIAGNOSIS',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            -- Add original entry to tracking history of changes
            set_epis_nan_diagnosis_hist(i_nnn_epis_diagnosis => l_rec.id_nnn_epis_diagnosis,
                                        i_dt_trs_time_end    => l_timestamp);
            -- Update entry        
            ts_nnn_epis_diagnosis.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_DIAGNOSIS',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
        RETURN l_rec.id_nnn_epis_diagnosis;
    END set_epis_nan_diagnosis;

    FUNCTION set_epis_nan_diagnosis_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE DEFAULT NULL,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_dt_evaluation      IN nnn_epis_diag_eval.dt_evaluation%TYPE,
        i_notes              IN CLOB DEFAULT NULL,
        i_lst_nan_relf       IN table_number DEFAULT NULL,
        i_lst_nan_riskf      IN table_number DEFAULT NULL,
        i_lst_nan_defc       IN table_number DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nan_diagnosis_eval';
    
        l_rec           nnn_epis_diag_eval%ROWTYPE;
        l_lst_rowid     table_varchar;
        l_lst_nan_relf  table_number;
        l_lst_nan_riskf table_number;
        l_lst_nan_defc  table_number;
        l_id_relf       PLS_INTEGER;
        l_id_riskf      PLS_INTEGER;
        l_id_defc       PLS_INTEGER;
    
        -- Collections only for update
        l_lst_epis_diag_relf  table_number;
        l_lst_epis_diag_riskf table_number;
        l_lst_epis_diag_defc  table_number;
    
        l_lst_epis_diag_relf_add  table_number;
        l_lst_epis_diag_riskf_add table_number;
        l_lst_epis_diag_defc_add  table_number;
    
        l_lst_epis_diag_relf_del  table_number;
        l_lst_epis_diag_riskf_del table_number;
        l_lst_epis_diag_defc_del  table_number;
    
        l_error     t_error_out;
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        g_error := g_error || ' i_dt_evaluation = ' || coalesce(to_char(i_dt_evaluation), '<null>');
        g_error := g_error || ' i_lst_nan_relf = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_nan_relf, i_delim => ','), '<null>');
        g_error := g_error || ' i_lst_nan_riskf = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_nan_riskf, i_delim => ','), '<null>');
        g_error := g_error || ' i_lst_nan_defc = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_nan_defc, i_delim => ','), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nan_relf  := coalesce(i_lst_nan_relf, table_number());
        l_lst_nan_riskf := coalesce(i_lst_nan_riskf, table_number());
        l_lst_nan_defc  := coalesce(i_lst_nan_defc, table_number());
    
        l_rec.id_nnn_epis_diagnosis := i_nnn_epis_diagnosis;
        l_rec.id_patient            := i_patient;
        l_rec.id_episode            := i_episode;
        l_rec.id_visit              := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional       := i_prof.id;
        l_rec.flg_status            := i_flg_status;
        l_rec.dt_evaluation         := i_dt_evaluation;
        l_rec.dt_trs_time_start     := l_timestamp;
        l_rec.dt_trs_time_end       := NULL;
    
        -- INSERT DATA
        IF i_nnn_epis_diag_eval IS NULL
        THEN
        
            l_rec.id_nnn_epis_diag_eval := seq_nnn_epis_diag_eval.nextval;
        
            g_error := 'Insert new record in NNN_EPIS_DIAG_EVAL';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            ts_nnn_epis_diag_eval.ins(rec_in => l_rec, rows_out => l_lst_rowid);
        
            FOR l_id_relf IN 1 .. l_lst_nan_relf.count
            LOOP
                g_error := 'Insert new record in NNN_EPIS_DIAG_RELF: ';
                g_error := g_error || ' id_nan_related_factor = ' ||
                           coalesce(to_char(l_lst_nan_relf(l_id_relf)), '<null>');
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                ts_nnn_epis_diag_relf.ins(id_nnn_epis_diag_eval_in => l_rec.id_nnn_epis_diag_eval,
                                          id_nan_related_factor_in => l_lst_nan_relf(l_id_relf));
            END LOOP;
        
            FOR l_id_riskf IN 1 .. l_lst_nan_riskf.count
            LOOP
                g_error := 'Insert new record in NNN_EPIS_DIAG_RSKF: ';
                g_error := g_error || ' id_nan_risk_factor = ' ||
                           coalesce(to_char(l_lst_nan_riskf(l_id_riskf)), '<null>');
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                ts_nnn_epis_diag_rskf.ins(id_nnn_epis_diag_eval_in => l_rec.id_nnn_epis_diag_eval,
                                          id_nan_risk_factor_in    => l_lst_nan_riskf(l_id_riskf));
            END LOOP;
        
            FOR l_id_defc IN 1 .. l_lst_nan_defc.count
            LOOP
                g_error := 'Insert new record in NNN_EPIS_DIAG_DEFC: ';
                g_error := g_error || ' id_nan_def_chars = ' || coalesce(to_char(l_lst_nan_defc(l_id_defc)), '<null>');
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
                ts_nnn_epis_diag_defc.ins(id_nnn_epis_diag_eval_in => l_rec.id_nnn_epis_diag_eval,
                                          id_nan_def_chars_in      => l_lst_nan_defc(l_id_defc));
            END LOOP;
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_DIAG_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
            -- UPDATE DATA
        ELSE
            l_rec.id_nnn_epis_diag_eval := i_nnn_epis_diag_eval;
        
            -- Add original entry to tracking history of changes
            set_epis_nan_diag_eval_hist(i_nnn_epis_diag_eval => i_nnn_epis_diag_eval, i_dt_trs_time_end => l_timestamp);
        
            g_error := 'Update record in NNN_EPIS_DIAG_EVAL';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            ts_nnn_epis_diag_eval.upd(rec_in => l_rec, rows_out => l_lst_rowid);
        
            -- Related Factors 
            SELECT nedr.id_nan_related_factor
              BULK COLLECT
              INTO l_lst_epis_diag_relf
              FROM nnn_epis_diag_relf nedr
             WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            l_lst_epis_diag_relf_add := l_lst_nan_relf MULTISET except l_lst_epis_diag_relf;
            l_lst_epis_diag_relf_del := l_lst_epis_diag_relf MULTISET except l_lst_nan_relf;
        
            -- insert
            IF l_lst_epis_diag_relf_add.count > 0
            THEN
                INSERT INTO nnn_epis_diag_relf
                    (id_nnn_epis_diag_relf, id_nnn_epis_diag_eval, id_nan_related_factor)
                    SELECT seq_nnn_epis_diag_relf.nextval, i_nnn_epis_diag_eval, t.column_value id_nan_related_factor
                      FROM TABLE(l_lst_epis_diag_relf_add) t;
            
            END IF;
        
            -- delete        
            IF l_lst_epis_diag_relf_del.count > 0
            THEN
                DELETE FROM nnn_epis_diag_relf nedr
                 WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nedr.id_nan_related_factor IN
                       (SELECT /*+ opt_estimate(table t rows=5)*/
                         t.column_value id_nan_related_factor
                          FROM TABLE(l_lst_epis_diag_relf_del) t);
            
            END IF;
        
            -- Risk Factors         
            SELECT nedr.id_nan_risk_factor
              BULK COLLECT
              INTO l_lst_epis_diag_riskf
              FROM nnn_epis_diag_rskf nedr
             WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            l_lst_epis_diag_riskf_add := l_lst_nan_riskf MULTISET except l_lst_epis_diag_riskf;
            l_lst_epis_diag_riskf_del := l_lst_epis_diag_riskf MULTISET except l_lst_nan_riskf;
        
            -- insert
            IF l_lst_epis_diag_riskf_add.count > 0
            THEN
                INSERT INTO nnn_epis_diag_rskf
                    (id_nnn_epis_diag_rskf, id_nnn_epis_diag_eval, id_nan_risk_factor)
                    SELECT seq_nnn_epis_diag_rskf.nextval, i_nnn_epis_diag_eval, t.column_value id_nan_risk_factor
                      FROM TABLE(l_lst_epis_diag_riskf_add) t;
            
            END IF;
        
            -- delete        
            IF l_lst_epis_diag_riskf_del.count > 0
            THEN
                DELETE FROM nnn_epis_diag_rskf nedr
                 WHERE nedr.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nedr.id_nan_risk_factor IN
                       (SELECT /*+ opt_estimate(table t rows=5)*/
                         t.column_value id_nan_risk_factor
                          FROM TABLE(l_lst_epis_diag_riskf_del) t);
            
            END IF;
        
            -- Defining Characterists 
            SELECT nedd.id_nan_def_chars
              BULK COLLECT
              INTO l_lst_epis_diag_defc
              FROM nnn_epis_diag_defc nedd
             WHERE nedd.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval;
        
            l_lst_epis_diag_defc_add := l_lst_nan_defc MULTISET except l_lst_epis_diag_defc;
            l_lst_epis_diag_defc_del := l_lst_epis_diag_defc MULTISET except l_lst_nan_defc;
        
            -- insert
            IF l_lst_epis_diag_defc_add.count > 0
            THEN
                INSERT INTO nnn_epis_diag_defc
                    (id_nnn_epis_diag_defc, id_nnn_epis_diag_eval, id_nan_def_chars)
                    SELECT seq_nnn_epis_diag_defc.nextval, i_nnn_epis_diag_eval, t.column_value id_nan_def_chars
                      FROM TABLE(l_lst_epis_diag_defc_add) t;
            
            END IF;
        
            -- delete        
            IF l_lst_epis_diag_defc_del.count > 0
            THEN
                DELETE FROM nnn_epis_diag_defc nedd
                 WHERE nedd.id_nnn_epis_diag_eval = i_nnn_epis_diag_eval
                   AND nedd.id_nan_def_chars IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                  t.column_value id_nan_def_chars
                                                   FROM TABLE(l_lst_epis_diag_defc_del) t);
            
            END IF;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_DIAG_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
    
        IF i_notes IS NOT NULL
        THEN
            g_error := 'Call pk_translation.insert_translation_trs: ';
            g_error := g_error || ' i_code = ' || g_epis_diag_eval_code_notes || to_char(l_rec.id_nnn_epis_diag_eval);
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_diag_eval_code_notes ||
                                                              to_char(l_rec.id_nnn_epis_diag_eval),
                                                  i_desc   => i_notes,
                                                  i_module => g_module_pfh);
        END IF;
        RETURN l_rec.id_nnn_epis_diag_eval;
    END set_epis_nan_diagnosis_eval;

    FUNCTION set_epis_nan_diagnosis_eval_st
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE
    ) RETURN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nan_diagnosis_eval_st';
        l_last_diag_eval     nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE;
        l_last_diag_estatus  nnn_epis_diag_eval.flg_status%TYPE;
        l_obj_last_diag_eval t_obj_nnn_epis_diag_eval;
        l_lst_nan_relf       table_number;
        l_lst_nan_riskf      table_number;
        l_lst_nan_defc       table_number;
        l_timestamp          TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_episode IS NULL
           OR i_nnn_epis_diagnosis IS NULL
           OR i_flg_status IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        -- Retrieve ID and status of the last diagnosis evaluation
        BEGIN
            SELECT t.id_nnn_epis_diag_eval, t.flg_status
              INTO l_last_diag_eval, l_last_diag_estatus
              FROM TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => i_nnn_epis_diagnosis)) t;
        
        EXCEPTION
            WHEN no_data_found THEN
                -- No evaluation yet
                l_last_diag_eval    := NULL;
                l_last_diag_estatus := NULL;
            
        END;
    
        IF l_last_diag_estatus = i_flg_status
        THEN
            -- Please see the comment in the function spec about this assumption
            g_error := 'The latest evaluation for the NANDA Diagnosis with id_nnn_epis_diagnosis = ' ||
                       to_char(i_nnn_epis_diagnosis) || ' seems to be already with the status i_flg_status = ' ||
                       i_flg_status;
            g_error := g_error || chr(10) || ' No new evaluation will be created';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            RAISE pk_nnn_constant.e_invalid_argument;
        
        END IF;
    
        IF l_last_diag_eval IS NOT NULL
        THEN
            -- Retrieves information of the last evaluation
            l_obj_last_diag_eval := pk_nnn_api_db.get_epis_nan_diagnosis_eval(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_nnn_epis_diag_eval => l_last_diag_eval);
        
            -- Copy the related factors,risk factors and defining characteristics from the last diagnosis evaluation to the new one
            l_lst_nan_relf := table_number();
            FOR i IN 1 .. l_obj_last_diag_eval.lst_related_factor.count()
            LOOP
                l_lst_nan_relf.extend(1);
                l_lst_nan_relf(l_lst_nan_relf.last) := l_obj_last_diag_eval.lst_related_factor(i).id_nan_related_factor;
            END LOOP;
        
            l_lst_nan_riskf := table_number();
            FOR i IN 1 .. l_obj_last_diag_eval.lst_risk_factor.count()
            LOOP
                l_lst_nan_riskf.extend(1);
                l_lst_nan_riskf(l_lst_nan_riskf.last) := l_obj_last_diag_eval.lst_risk_factor(i).id_nan_risk_factor;
            END LOOP;
        
            l_lst_nan_defc := table_number();
            FOR i IN 1 .. l_obj_last_diag_eval.lst_defining_characteristic.count()
            LOOP
                l_lst_nan_defc.extend(1);
                l_lst_nan_defc(l_lst_nan_defc.last) := l_obj_last_diag_eval.lst_defining_characteristic(i).id_nan_def_chars;
            END LOOP;
        
        END IF;
    
        RETURN pk_nnn_core.set_epis_nan_diagnosis_eval(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_patient            => i_patient,
                                                       i_episode            => i_episode,
                                                       i_nnn_epis_diagnosis => i_nnn_epis_diagnosis,
                                                       i_nnn_epis_diag_eval => NULL,
                                                       i_flg_status         => i_flg_status,
                                                       i_dt_evaluation      => l_timestamp,
                                                       i_notes              => NULL,
                                                       i_lst_nan_relf       => l_lst_nan_relf,
                                                       i_lst_nan_riskf      => l_lst_nan_riskf,
                                                       i_lst_nan_defc       => l_lst_nan_defc,
                                                       i_timestamp          => l_timestamp);
    
    END set_epis_nan_diagnosis_eval_st;

    FUNCTION set_epis_noc_outcome
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_outcome.id_patient%TYPE,
        i_episode             IN nnn_epis_outcome.id_episode%TYPE,
        i_noc_outcome         IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_nnn_epis_outcome    IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_outcome.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_outcome.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_outcome.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_outcome.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_outcome.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_outcome.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_outcome.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome.id_nnn_epis_outcome%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_noc_outcome';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_outcome%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_flg_prn = ' || coalesce(i_flg_prn, '<null>');
        g_error := g_error || ' i_flg_time = ' || coalesce(i_flg_time, '<null>');
        g_error := g_error || ' i_flg_priority = ' || coalesce(i_flg_priority, '<null>');
        g_error := g_error || ' i_order_recurr_plan = ' || coalesce(to_char(i_order_recurr_plan), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_nnn_epis_outcome IS NOT NULL
        THEN
            l_rec := get_epis_noc_outcome_row(i_nnn_epis_outcome => i_nnn_epis_outcome);
        END IF;
    
        l_rec.id_nnn_epis_outcome    := i_nnn_epis_outcome;
        l_rec.id_noc_outcome         := i_noc_outcome;
        l_rec.id_patient             := i_patient;
        l_rec.id_episode             := i_episode;
        l_rec.id_visit               := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional        := i_prof.id;
        l_rec.noc_code               := pk_noc_model.get_outcome_code(i_noc_outcome => i_noc_outcome);
        l_rec.id_episode_origin      := i_episode_origin;
        l_rec.id_episode_destination := i_episode_destination;
        l_rec.flg_prn                := coalesce(i_flg_prn, pk_alert_constant.g_no);
        l_rec.flg_time               := coalesce(i_flg_time, pk_nnn_constant.g_time_performed_episode);
        l_rec.flg_priority           := coalesce(i_flg_priority, pk_nnn_constant.g_priority_normal);
        l_rec.id_order_recurr_plan   := i_order_recurr_plan;
        l_rec.flg_req_status         := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_ordered);
        l_rec.dt_trs_time_start      := l_timestamp;
        l_rec.dt_trs_time_end        := NULL;
    
        IF l_rec.id_nnn_epis_outcome IS NULL
        THEN
            l_rec.id_nnn_epis_outcome := ts_nnn_epis_outcome.next_key();
            l_rec.dt_val_time_start   := l_timestamp; -- The valid time start of the Outcome request (sets once when is created and inmutable during the lifecycle of this request)
            l_rec.dt_val_time_end     := NULL; -- The valid time end of the Outcome request (sets once when is cancelated/finished)
        
            ts_nnn_epis_outcome.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_OUTCOME',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            -- Add original entry to tracking history of changes
            set_epis_noc_outcome_hist(i_nnn_epis_outcome => l_rec.id_nnn_epis_outcome,
                                      i_dt_trs_time_end  => l_timestamp);
            -- Update entry        
            ts_nnn_epis_outcome.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_OUTCOME',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
    
        IF i_notes_prn IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_outcome_code_notes_prn ||
                                                              to_char(l_rec.id_nnn_epis_outcome),
                                                  i_desc   => i_notes_prn,
                                                  i_module => g_module_pfh);
        END IF;
        RETURN l_rec.id_nnn_epis_outcome;
    END set_epis_noc_outcome;

    FUNCTION set_epis_noc_outcome_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_outcome.id_patient%TYPE,
        i_episode               IN nnn_epis_outcome.id_episode%TYPE,
        i_nnn_epis_outcome      IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE DEFAULT NULL,
        i_dt_evaluation         IN nnn_epis_outcome_eval.dt_evaluation%TYPE,
        i_target_value          IN nnn_epis_outcome_eval.target_value%TYPE,
        i_outcome_value         IN nnn_epis_outcome_eval.outcome_value%TYPE,
        i_notes                 IN CLOB DEFAULT NULL,
        i_dt_plan               IN nnn_epis_outcome_eval.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan     IN nnn_epis_outcome_eval.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number           IN nnn_epis_outcome_eval.exec_number%TYPE DEFAULT NULL,
        i_flg_status            IN nnn_epis_outcome_eval.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_noc_outcome_eval';
        l_rec       nnn_epis_outcome_eval%ROWTYPE;
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_nnn_epis_outcome_eval = ' || coalesce(to_char(i_nnn_epis_outcome_eval), '<null>');
        g_error := g_error || ' i_dt_evaluation = ' ||
                   coalesce(to_char(i_dt_evaluation, 'DD-MON-YYYY HH24:MI:SS TZR'), '<null>');
        g_error := g_error || ' i_target_value = ' || coalesce(to_char(i_target_value), '<null>');
        g_error := g_error || ' i_outcome_value = ' || coalesce(to_char(i_outcome_value), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(i_flg_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec.id_nnn_epis_outcome_eval := i_nnn_epis_outcome_eval;
        l_rec.id_nnn_epis_outcome      := i_nnn_epis_outcome;
        l_rec.id_patient               := i_patient;
        l_rec.id_episode               := i_episode;
        l_rec.id_visit                 := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional          := i_prof.id;
        l_rec.dt_plan                  := i_dt_plan;
        l_rec.id_order_recurr_plan     := i_order_recurr_plan;
        l_rec.exec_number              := i_exec_number;
        l_rec.flg_status               := coalesce(i_flg_status, pk_nnn_constant.g_task_status_finished);
        l_rec.dt_evaluation            := i_dt_evaluation;
        l_rec.target_value             := i_target_value;
        l_rec.outcome_value            := i_outcome_value;
        l_rec.dt_trs_time_start        := l_timestamp;
        l_rec.dt_trs_time_end          := NULL;
    
        IF l_rec.id_nnn_epis_outcome_eval IS NULL
        THEN
            l_rec.id_nnn_epis_outcome_eval := ts_nnn_epis_outcome_eval.next_key();
            ts_nnn_epis_outcome_eval.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_OUTCOME_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            -- Add original entry to tracking history of changes
            set_epis_noc_outcome_eval_hist(i_nnn_epis_outcome_eval => l_rec.id_nnn_epis_outcome_eval,
                                           i_dt_trs_time_end       => l_timestamp);
            -- Update entry        
            ts_nnn_epis_outcome_eval.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_OUTCOME_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
        IF i_notes IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_outcome_eval_code_notes ||
                                                              to_char(l_rec.id_nnn_epis_outcome_eval),
                                                  i_desc   => i_notes,
                                                  i_module => g_module_pfh);
        
        END IF;
    
        RETURN l_rec.id_nnn_epis_outcome_eval;
    END set_epis_noc_outcome_eval;

    PROCEDURE get_prn_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_prn_list';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_list FOR
            SELECT /*+ result_cache */
             s.val data,
             s.rank,
             s.desc_val label,
             decode(s.val, pk_alert_constant.g_no, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM sys_domain s
             WHERE id_language = i_lang
               AND code_domain = pk_nnn_constant.g_dom_epis_act_flg_prn
               AND s.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY rank;
    
    END get_prn_list;

    FUNCTION get_default_flg_prn(i_lang IN language.id_language%TYPE) RETURN VARCHAR2 result_cache relies_on(sys_domain) IS
        l_prn_val         sys_domain.val%TYPE;
        l_default_prn_val sys_domain.val%TYPE;
        l_prn_rank        sys_domain.rank%TYPE;
        l_prn_desc_val    sys_domain.desc_val%TYPE;
        l_prn_flg_default VARCHAR2(1 CHAR);
    
        c_data pk_types.cursor_type;
    BEGIN
    
        -- get nnn prn options
        pk_nnn_core.get_prn_list(i_lang => i_lang, o_list => c_data);
    
        -- get default prn option
        LOOP
            FETCH c_data
                INTO l_prn_val, l_prn_rank, l_prn_desc_val, l_prn_flg_default;
        
            EXIT WHEN c_data%NOTFOUND;
        
            -- check if prn option is default or not
            IF l_default_prn_val IS NULL
               OR l_prn_flg_default = pk_alert_constant.g_yes
            THEN
                l_default_prn_val := l_prn_val;
            END IF;
        
        END LOOP;
    
        RETURN l_default_prn_val;
    
    END get_default_flg_prn;

    PROCEDURE get_time_list
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE,
        o_time OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_time_list';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_inst = ' || coalesce(to_char(i_inst), '<null>');
        g_error := g_error || ' i_soft = ' || coalesce(to_char(i_soft), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- TODO: may be needed to implement a own version of this method instead of using the icnp
        pk_icnp_fo.get_time(i_lang => i_lang,
                            i_prof => profissional(NULL, i_inst, i_soft),
                            i_soft => table_number(i_soft),
                            o_time => o_time);
    END get_time_list;

    FUNCTION get_default_flg_time
    (
        i_lang IN language.id_language%TYPE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 result_cache relies_on(sys_domain, sys_domain_mkt, sys_domain_instit_soft_dcs, sys_config) IS
        l_time_val         sys_domain.val%TYPE;
        l_default_time_val sys_domain.val%TYPE;
        l_time_rank        sys_domain.rank%TYPE;
        l_time_desc_val    sys_domain.desc_val%TYPE;
        l_time_flg_default VARCHAR2(1 CHAR);
    
        c_data pk_types.cursor_type;
    BEGIN
    
        -- get icnp time options
        pk_nnn_core.get_time_list(i_lang => i_lang, i_inst => i_inst, i_soft => i_soft, o_time => c_data);
    
        -- get default time option
        LOOP
            FETCH c_data
                INTO l_time_val, l_time_rank, l_time_desc_val, l_time_flg_default;
        
            EXIT WHEN c_data%NOTFOUND;
        
            -- check if time option is default or not
            IF l_default_time_val IS NULL
               OR l_time_flg_default = pk_alert_constant.g_yes
            THEN
                l_default_time_val := l_time_val;
            END IF;
        
        END LOOP;
    
        RETURN l_default_time_val;
    
    END get_default_flg_time;

    PROCEDURE get_priority_list
    (
        i_lang IN language.id_language%TYPE,
        o_list OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_priority_list';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_list FOR
            SELECT /*+ result_cache */
             s.val data,
             s.rank,
             s.desc_val label,
             decode(s.val, pk_alert_constant.g_no, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM sys_domain s
             WHERE id_language = i_lang
               AND code_domain = pk_nnn_constant.g_dom_epis_act_flg_priority
               AND s.domain_owner = pk_sysdomain.k_default_schema
             ORDER BY rank;
    
    END get_priority_list;

    FUNCTION get_default_flg_priority RETURN VARCHAR2 result_cache IS
    BEGIN
        RETURN pk_nnn_constant.g_priority_normal;
    END get_default_flg_priority;

    PROCEDURE create_default_instructions
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_lst_outcome                IN table_number,
        i_lst_indicator              IN table_number,
        i_lst_activity               IN table_number,
        o_default_outcome_instruct   OUT pk_types.cursor_type,
        o_default_indicator_instruct OUT pk_types.cursor_type,
        o_default_activity_instruct  OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'create_default_instructions';
        l_default_instructions t_tbl_nnn_default_instruct;
    
        -- local exception
        l_exception EXCEPTION;
        l_error t_error_out;
    
        -- Create a default recurrence plan for each instruction
        PROCEDURE create_recurrence_plan
        (
            i_order_recurr_area IN order_recurr_area.internal_name%TYPE,
            io_lst_instructions IN OUT NOCOPY t_tbl_nnn_default_instruct
        ) IS
            -- variables used to create recurrence plans
            l_order_recurr_desc   VARCHAR2(1000 CHAR);
            l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
            l_start_date          order_recurr_plan.start_date%TYPE;
            l_occurrences         order_recurr_plan.occurrences%TYPE;
            l_duration            order_recurr_plan.duration%TYPE;
            l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
            l_end_date            order_recurr_plan.end_date%TYPE;
            l_flg_end_by_editable VARCHAR2(1 CHAR);
            l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        BEGIN
            -- loop default instructions of each composition
            FOR i IN 1 .. io_lst_instructions.count
            LOOP
            
                -- create new recurrence plan for this recurrence option            
                g_error := 'Call function PK_ORDER_RECURRENCE_API_DB.CREATE_ORDER_RECURR_PLAN for id_noc_outcome = ' ||
                           to_char(l_default_instructions(i).id_nnn_entity);
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            
                IF NOT pk_order_recurrence_api_db.create_order_recurr_plan(i_lang                => i_lang,
                                                                           i_prof                => i_prof,
                                                                           i_order_recurr_area   => i_order_recurr_area,
                                                                           i_order_recurr_option => io_lst_instructions(i).id_order_recurr_option,
                                                                           o_order_recurr_desc   => l_order_recurr_desc,
                                                                           o_order_recurr_option => l_order_recurr_option,
                                                                           o_start_date          => l_start_date,
                                                                           o_occurrences         => l_occurrences,
                                                                           o_duration            => l_duration,
                                                                           o_unit_meas_duration  => l_unit_meas_duration,
                                                                           o_end_date            => l_end_date,
                                                                           o_flg_end_by_editable => l_flg_end_by_editable,
                                                                           o_order_recurr_plan   => l_order_recurr_plan,
                                                                           o_error               => l_error)
                THEN
                
                    DECLARE
                        l_err_id PLS_INTEGER;
                    BEGIN
                        g_error := 'error found while calling PK_ORDER_RECURRENCE_API_DB.CREATE_ORDER_RECURR_PLAN';
                        pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nnn_epis_out_rec_plan',
                                                           err_instance_id_out => l_err_id,
                                                           text_in             => g_error,
                                                           name1_in            => 'function_name',
                                                           value1_in           => k_function_name,
                                                           name2_in            => 'i_order_recurr_area',
                                                           value2_in           => coalesce(i_order_recurr_area, '<null>'),
                                                           name3_in            => 'i_order_recurr_option',
                                                           value3_in           => coalesce(to_char(io_lst_instructions(i).id_order_recurr_option),
                                                                                           '<null>'));
                        RAISE pk_nnn_constant.e_call_error;
                    END;
                END IF;
            
                -- set record with the new recurrence plan
                io_lst_instructions(i).id_order_recurr_plan := l_order_recurr_plan;
                io_lst_instructions(i).start_date := l_start_date;
            END LOOP;
        END create_recurrence_plan;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_lst_outcome = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_outcome, i_delim => ','), '<null>');
        g_error := g_error || ' i_lst_indicator = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_indicator, i_delim => ','), '<null>');
        g_error := g_error || ' i_lst_activity = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_activity, i_delim => ','), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- NOC Outcomes   
        -- Retrieve the default instructions of each NOC Outcome that were defined at NOC_CFG_OUTCOME by the BackOffice.
        -- If no configurations were defined yet, assume default settings (see table function tf_inst_outcome)    
        SELECT /*+ dynamic_sampling(nocfg_o 2 ) dynamic_sampling(t 2 ) */
         t_rec_nnn_default_instruct(id_nnn_entity          => nocfg_o.id_noc_outcome,
                                    id_order_recurr_option => nocfg_o.id_order_recurr_option,
                                    id_order_recurr_plan   => NULL,
                                    start_date             => NULL,
                                    flg_priority           => nocfg_o.flg_priority,
                                    flg_time               => nocfg_o.flg_time,
                                    flg_prn                => nocfg_o.flg_prn,
                                    prn_notes              => CASE nocfg_o.code_notes_prn
                                                                  WHEN NULL THEN
                                                                   NULL
                                                                  ELSE
                                                                   pk_translation.get_translation_trs(i_code_mess => nocfg_o.code_notes_prn)
                                                              END)
          BULK COLLECT
          INTO l_default_instructions
          FROM TABLE(pk_noc_cfg.tf_inst_outcome(i_inst => i_prof.institution, i_soft => i_prof.software)) nocfg_o
         INNER JOIN TABLE(i_lst_outcome) t
            ON t.column_value = nocfg_o.id_noc_outcome;
    
        -- Creates a temporary recurrence plan for each NOC Outcome
        create_recurrence_plan(i_order_recurr_area => pk_nnn_constant.g_ordrecurr_area_noc_outcome,
                               io_lst_instructions => l_default_instructions);
    
        -- Returns default instructions for each outcome with its recurrence plan ID that was generated (as temporary)
        OPEN o_default_outcome_instruct FOR
            SELECT def_instr.id_nnn_entity id_noc_outcome,
                   def_instr.id_order_recurr_plan,
                   def_instr.flg_priority,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                           i_val      => def_instr.flg_priority,
                                           i_lang     => i_lang) priority,
                   def_instr.flg_time,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_time,
                                           i_val      => def_instr.flg_time,
                                           i_lang     => i_lang) to_be_performed,
                   def_instr.flg_prn,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_prn,
                                           i_val      => def_instr.flg_prn,
                                           i_lang     => i_lang) prn,
                   def_instr.prn_notes,
                   pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_flg_priority      => def_instr.flg_priority,
                                                i_flg_prn           => def_instr.flg_prn,
                                                i_notes_prn         => def_instr.prn_notes,
                                                i_flg_time          => def_instr.flg_time,
                                                i_start_date        => def_instr.start_date,
                                                i_order_recurr_plan => def_instr.id_order_recurr_plan) desc_instructions,
                   pk_date_utils.date_send_tsz(i_lang, def_instr.start_date, i_prof) AS start_date
              FROM TABLE(l_default_instructions) def_instr;
    
        -- NOC Indicators   
        -- Retrieve the default instructions of each NOC Indicator that were defined at NOC_CFG_INDICATOR by the BackOffice.
        -- If no configurations were defined yet, assume default settings (see table function tf_inst_indicators)    
        SELECT /*+ dynamic_sampling(nocfg_i 2 ) dynamic_sampling(t 2 ) */
         t_rec_nnn_default_instruct(id_nnn_entity          => nocfg_i.id_noc_indicator,
                                    id_order_recurr_option => nocfg_i.id_order_recurr_option,
                                    id_order_recurr_plan   => NULL,
                                    start_date             => NULL,
                                    flg_priority           => nocfg_i.flg_priority,
                                    flg_time               => nocfg_i.flg_time,
                                    flg_prn                => nocfg_i.flg_prn,
                                    prn_notes              => CASE nocfg_i.code_notes_prn
                                                                  WHEN NULL THEN
                                                                   NULL
                                                                  ELSE
                                                                   pk_translation.get_translation_trs(i_code_mess => nocfg_i.code_notes_prn)
                                                              END)
          BULK COLLECT
          INTO l_default_instructions
          FROM TABLE(pk_noc_cfg.tf_inst_indicator(i_inst => i_prof.institution, i_soft => i_prof.software)) nocfg_i
         INNER JOIN TABLE(i_lst_indicator) t
            ON t.column_value = nocfg_i.id_noc_indicator;
    
        -- Creates a temporary recurrence plan for each NOC Indicator
        create_recurrence_plan(i_order_recurr_area => pk_nnn_constant.g_ordrecurr_area_noc_indicator,
                               io_lst_instructions => l_default_instructions);
    
        -- Returns default instructions for each indicator with its recurrence plan ID that was generated (as temporary)
        OPEN o_default_indicator_instruct FOR
            SELECT def_instr.id_nnn_entity id_noc_indicator,
                   def_instr.id_order_recurr_plan,
                   def_instr.flg_priority,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                           i_val      => def_instr.flg_priority,
                                           i_lang     => i_lang) priority,
                   def_instr.flg_time,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_time,
                                           i_val      => def_instr.flg_time,
                                           i_lang     => i_lang) to_be_performed,
                   def_instr.flg_prn,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                           i_val      => def_instr.flg_prn,
                                           i_lang     => i_lang) prn,
                   def_instr.prn_notes,
                   pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_flg_priority      => def_instr.flg_priority,
                                                i_flg_prn           => def_instr.flg_prn,
                                                i_flg_time          => def_instr.flg_time,
                                                i_start_date        => def_instr.start_date,
                                                i_order_recurr_plan => def_instr.id_order_recurr_plan) desc_instructions,
                   pk_date_utils.date_send_tsz(i_lang, def_instr.start_date, i_prof) AS start_date
              FROM TABLE(l_default_instructions) def_instr;
    
        -- NIC Activities
        -- Retrieve the default instructions of each NIC Activitiy that were defined at NIC_CFG_ACTIVITY by the BackOffice.
        -- If no configurations were defined yet, assume default settings (see table function tf_inst_activity)    
        SELECT /*+ dynamic_sampling(nicfg_a 2 ) dynamic_sampling(t 2 ) */
         t_rec_nnn_default_instruct(id_nnn_entity          => nicfg_a.id_nic_activity,
                                    id_order_recurr_option => nicfg_a.id_order_recurr_option,
                                    id_order_recurr_plan   => NULL,
                                    start_date             => NULL,
                                    flg_priority           => nicfg_a.flg_priority,
                                    flg_time               => nicfg_a.flg_time,
                                    flg_prn                => nicfg_a.flg_prn,
                                    prn_notes              => CASE nicfg_a.code_notes_prn
                                                                  WHEN NULL THEN
                                                                   NULL
                                                                  ELSE
                                                                   pk_translation.get_translation_trs(i_code_mess => nicfg_a.code_notes_prn)
                                                              END)
          BULK COLLECT
          INTO l_default_instructions
          FROM TABLE(pk_nic_cfg.tf_inst_activity(i_inst => i_prof.institution, i_soft => i_prof.software)) nicfg_a
         INNER JOIN TABLE(i_lst_activity) t
            ON t.column_value = nicfg_a.id_nic_activity;
    
        -- Creates a temporary recurrence plan for each NIC Activity
        create_recurrence_plan(i_order_recurr_area => pk_nnn_constant.g_ordrecurr_area_nic_activity,
                               io_lst_instructions => l_default_instructions);
    
        -- Returns default instructions for each activity with its recurrence plan ID that was generated (as temporary)
        OPEN o_default_activity_instruct FOR
            SELECT def_instr.id_nnn_entity id_nic_activity,
                   def_instr.id_order_recurr_plan,
                   def_instr.flg_priority,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority,
                                           i_val      => def_instr.flg_priority,
                                           i_lang     => i_lang) priority,
                   def_instr.flg_time,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_time,
                                           i_val      => def_instr.flg_time,
                                           i_lang     => i_lang) to_be_performed,
                   def_instr.flg_prn,
                   pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn,
                                           i_val      => def_instr.flg_prn,
                                           i_lang     => i_lang) prn,
                   def_instr.prn_notes,
                   pk_nnn_core.get_instructions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_flg_priority      => def_instr.flg_priority,
                                                i_flg_prn           => def_instr.flg_prn,
                                                i_flg_time          => def_instr.flg_time,
                                                i_start_date        => def_instr.start_date,
                                                i_order_recurr_plan => def_instr.id_order_recurr_plan) desc_instructions,
                   pk_date_utils.date_send_tsz(i_lang, def_instr.start_date, i_prof) AS start_date
              FROM TABLE(l_default_instructions) def_instr;
    
    END create_default_instructions;

    FUNCTION set_epis_nic_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_intervention.id_patient%TYPE,
        i_episode               IN nnn_epis_intervention.id_episode%TYPE,
        i_nic_intervention      IN nnn_epis_intervention.id_nic_intervention %TYPE,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE DEFAULT NULL,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_intervention.id_nnn_epis_intervention%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nic_intervention';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_intervention%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nic_intervention = ' || coalesce(to_char(i_nic_intervention), '<null>');
        g_error := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_nnn_epis_intervention IS NOT NULL
        THEN
            l_rec := get_epis_nic_intervention_row(i_nnn_epis_intervention => i_nnn_epis_intervention);
        END IF;
    
        l_rec.id_nnn_epis_intervention := i_nnn_epis_intervention;
        l_rec.id_nic_intervention      := i_nic_intervention;
        l_rec.id_patient               := i_patient;
        l_rec.id_episode               := i_episode;
        l_rec.id_visit                 := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional          := i_prof.id;
        l_rec.nic_code                 := pk_nic_model.get_intervention_code(i_nic_intervention => i_nic_intervention);
        l_rec.flg_req_status           := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_ordered);
        l_rec.dt_trs_time_start        := l_timestamp;
        l_rec.dt_trs_time_end          := NULL;
    
        IF l_rec.id_nnn_epis_intervention IS NULL
        THEN
            l_rec.id_nnn_epis_intervention := ts_nnn_epis_intervention.next_key();
            l_rec.dt_val_time_start        := l_timestamp; -- The valid time start of the Intervention request (sets once when is created and inmutable during the lifecycle of this request)
            l_rec.dt_val_time_end          := NULL; -- The valid time end of the Intervention request (sets once when is cancelated/finished)
        
            ts_nnn_epis_intervention.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INTERVENTION',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            --Add original entry to tracking history of changes
            set_epis_nic_intervention_hist(i_nnn_epis_intervention => l_rec.id_nnn_epis_intervention,
                                           i_dt_trs_time_end       => l_timestamp);
            -- Update entry        
            ts_nnn_epis_intervention.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INTERVENTION',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
        RETURN l_rec.id_nnn_epis_intervention;
    
    END set_epis_nic_intervention;

    FUNCTION set_epis_nic_activity
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_activity.id_patient%TYPE,
        i_episode             IN nnn_epis_activity.id_episode%TYPE,
        i_nic_activity        IN nnn_epis_activity.id_nic_activity%TYPE,
        i_nnn_epis_activity   IN nnn_epis_activity.id_nnn_epis_activity%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_activity.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_activity.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_activity.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_activity.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_activity.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_activity.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_activity.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity.id_nnn_epis_activity%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nic_activity';
        l_timestamp        TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec              nnn_epis_activity%ROWTYPE;
        l_error            t_error_out;
        l_lst_rowid        table_varchar;
        l_activity_doctype pk_nic_cfg.t_nic_activity_doctype;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nic_activity = ' || coalesce(to_char(i_nic_activity), '<null>');
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_flg_prn = ' || coalesce(i_flg_prn, '<null>');
        g_error := g_error || ' i_flg_time = ' || coalesce(i_flg_time, '<null>');
        g_error := g_error || ' i_flg_priority = ' || coalesce(i_flg_priority, '<null>');
        g_error := g_error || ' i_order_recurr_plan = ' || coalesce(to_char(i_order_recurr_plan), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_nnn_epis_activity IS NOT NULL
        THEN
            l_rec := get_epis_nic_activity_row(i_nnn_epis_activity => i_nnn_epis_activity);
        END IF;
    
        l_rec.id_nnn_epis_activity   := i_nnn_epis_activity;
        l_rec.id_nic_activity        := i_nic_activity;
        l_rec.id_patient             := i_patient;
        l_rec.id_episode             := i_episode;
        l_rec.id_visit               := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional        := i_prof.id;
        l_rec.id_episode_origin      := i_episode_origin;
        l_rec.id_episode_destination := i_episode_destination;
        l_rec.flg_prn                := i_flg_prn;
        l_rec.flg_time               := i_flg_time;
        l_rec.flg_priority           := i_flg_priority;
        l_rec.id_order_recurr_plan   := i_order_recurr_plan;
        l_rec.flg_req_status         := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_ordered);
        l_rec.dt_trs_time_start      := l_timestamp;
        l_rec.dt_trs_time_end        := NULL;
    
        IF l_rec.id_nnn_epis_activity IS NULL
        THEN
            l_activity_doctype := pk_nic_cfg.get_activity_doctype(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_nic_activity => i_nic_activity);
        
            l_rec.id_nnn_epis_activity := ts_nnn_epis_activity.next_key();
            l_rec.flg_doc_type         := l_activity_doctype.flg_doc_type;
            l_rec.doc_parameter        := l_activity_doctype.doc_parameter;
            l_rec.dt_val_time_start    := l_timestamp; -- The valid time start of the Activity request (sets once when is created and inmutable during the lifecycle of this request)
            l_rec.dt_val_time_end      := NULL; -- The valid time end of the Activity request (sets once when is cancelated/finished)            
        
            ts_nnn_epis_activity.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_ACTIVITY',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
        
            --Add original entry to tracking history of changes
            set_epis_nic_activity_hist(i_nnn_epis_activity => l_rec.id_nnn_epis_activity,
                                       i_dt_trs_time_end   => l_timestamp);
            -- Update entry        
            ts_nnn_epis_activity.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_ACTIVITY',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
        IF i_notes_prn IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_activity_code_notes_prn ||
                                                              to_char(l_rec.id_nnn_epis_activity),
                                                  i_desc   => i_notes_prn,
                                                  i_module => g_module_pfh);
        END IF;
        RETURN l_rec.id_nnn_epis_activity;
    END set_epis_nic_activity;

    FUNCTION get_activity_has_execs(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE) RETURN BOOLEAN IS
        l_count     PLS_INTEGER := 0;
        l_has_evals BOOLEAN;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_activity_det nead
         WHERE nead.id_nnn_epis_activity = i_nnn_epis_activity
           AND nead.flg_status = pk_nnn_constant.g_task_status_finished;
    
        l_has_evals := l_count > 0;
        RETURN l_has_evals;
    
    END get_activity_has_execs;

    FUNCTION get_activity_planned_exe_count(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity %TYPE)
        RETURN PLS_INTEGER IS
        l_count PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_activity_det nead
         WHERE nead.id_nnn_epis_activity = i_nnn_epis_activity
           AND nead.flg_status IN (pk_nnn_constant.g_task_status_ordered,
                                   pk_nnn_constant.g_task_status_ongoing,
                                   pk_nnn_constant.g_task_status_suspended);
        RETURN l_count;
    
    END get_activity_planned_exe_count;

    /**
     * Checks if a given NIC Activity has planned executions.
     * Are considered planned executions all of them that were not executed or cancelled.
    *
    * @param    i_nnn_epis_activity              Careplan's NIC Activity ID
    *
    * @return   True if there is at least one planned executions.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/2/2014
    */
    FUNCTION get_activity_has_planned_execs(i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE)
        RETURN BOOLEAN IS
    
        l_count             PLS_INTEGER;
        l_has_planned_evals BOOLEAN;
    
    BEGIN
    
        l_count             := get_activity_planned_exe_count(i_nnn_epis_activity => i_nnn_epis_activity);
        l_has_planned_evals := l_count > 0;
        RETURN l_has_planned_evals;
    
    END get_activity_has_planned_execs;

    FUNCTION get_fsm_activity_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE,
        i_action            IN action.internal_name%TYPE
    ) RETURN nnn_epis_activity.flg_req_status%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_fsm_outcome_status';
        l_rec_plan_info t_recurr_plan_info_rec;
        c_invalid_status CONSTANT nnn_epis_outcome.flg_req_status%TYPE := '-';
        l_new_status        nnn_epis_outcome.flg_req_status%TYPE := c_invalid_status;
        l_order_recurr_plan nnn_epis_outcome.id_order_recurr_plan%TYPE;
        l_has_execs         BOOLEAN;
        l_has_planned_execs BOOLEAN;
        l_freq_type         VARCHAR(1 CHAR);
    
        /**
         * Calculates the status of the activity when a cancel request action is 
         * performed. 
        */
        PROCEDURE calc_st_for_cancel_req IS
        BEGIN
        
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_draft -- Transition D2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            END IF;
        END;
    
        /**
         * Calculates the status of the activity when an activity is executed and
         * the type of recurrence for the activity is "once" or "with recurrence".
        */
        PROCEDURE calc_st_for_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND l_has_planned_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND NOT l_has_planned_execs) -- Transition R2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND NOT l_has_planned_execs) -- Transition O4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND l_has_planned_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the activity when an activity is executed and
         * the type recurrence of the activity is "no schedule".
        */
        PROCEDURE calc_st_for_exec_no_sched IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the activity when the pause action is performed.
        */
        PROCEDURE calc_st_for_pause IS
        BEGIN
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R5
               OR i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_suspended;
            END IF;
        END;
    
        /**
         * Calculates the status of the activity when the resume action is performed.
        */
        PROCEDURE calc_st_for_resume IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the activity when the cancel execution action is 
         * performed. This algorithm is only executed for the recurrence of type "once" 
         * or "with recurrence".
        */
        PROCEDURE calc_st_for_cancel_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_planned_execs AND NOT l_has_execs) -- Transition R1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND NOT l_has_planned_execs AND
                  NOT l_has_execs) -- Transition R4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_planned_execs AND l_has_execs) -- Transition O1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND NOT l_has_planned_execs) -- Transition O2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            END IF;
        END;
    
    BEGIN
        IF pk_nnn_core.is_req_final_state(i_flg_req_status => i_flg_req_status)
        THEN
            -- If the current state of the intervention is a final no state transitions is allowed.
            l_new_status := i_flg_req_status;
        ELSE
        
            -- Gets the execution information for the given activity
            l_has_execs         := get_activity_has_execs(i_nnn_epis_activity);
            l_has_planned_execs := get_activity_has_planned_execs(i_nnn_epis_activity);
        
            SELECT nea.id_order_recurr_plan
              INTO l_order_recurr_plan
              FROM nnn_epis_activity nea
             WHERE nea.id_nnn_epis_activity = i_nnn_epis_activity;
        
            -- By default assumes no schedule
            l_freq_type := pk_nnn_constant.g_req_freq_no_schedule;
            IF l_order_recurr_plan IS NOT NULL
            THEN
                l_rec_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_order_recurr_plan => l_order_recurr_plan);
                l_freq_type     := pk_nnn_core.recurr_option_to_freq_type(i_order_recurr_option => l_rec_plan_info.order_recurr_option);
            END IF;
        
            /*
             * Calculate the new activity status.
             * First the action is evaluated, then the current activity status.
            */
            CASE i_action
                WHEN pk_nnn_constant.g_action_activity_cancel THEN
                    -- Cancel a NIC Activity within a care plan                  
                    calc_st_for_cancel_req();
                WHEN pk_nnn_constant.g_action_activity_execute THEN
                    -- Execution of a NIC Activity within a care plan
                    IF l_freq_type = pk_nnn_constant.g_req_freq_no_schedule
                    THEN
                        calc_st_for_exec_no_sched();
                    ELSE
                        calc_st_for_exec_recurr();
                    END IF;
                WHEN pk_nnn_constant.g_action_activity_hold THEN
                    -- Hold a NIC Activity within a care plan                          
                    calc_st_for_pause();
                WHEN pk_nnn_constant.g_action_activity_resume THEN
                    -- Resume a NIC Activity within a care plan                          
                    calc_st_for_resume();
                ELSE
                    g_error := 'The following action is not considered to evaluate the next activity state: ' ||
                               i_action;
                    pk_alertlog.log_warn(text            => g_error,
                                         object_name     => g_package,
                                         sub_object_name => k_function_name,
                                         owner           => g_owner);
                
            END CASE;
        END IF;
    
        -- When the new status is not resolved by the previous algorithm, something is wrong, so
        -- an exception must be thrown
        IF l_new_status = c_invalid_status
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_nnn_constant.g_excep_inv_status_transition,
                                            text_in       => 'Unable to determine the new status when the action is ' ||
                                                             i_action || ', the current status is ' || i_flg_req_status ||
                                                             ', recurrence type is ' || l_freq_type || ', has execs ' ||
                                                             pk_utils.bool_to_flag(l_has_execs) ||
                                                             ', has planned execs ' ||
                                                             pk_utils.bool_to_flag(l_has_planned_execs),
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        END IF;
    
        RETURN l_new_status;
    
    END get_fsm_activity_status;

    PROCEDURE set_lnk_intervention_activity
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN nnn_epis_lnk_int_actv.id_episode%TYPE,
        i_nnn_epis_intervention IN nnn_epis_lnk_int_actv.id_nnn_epis_intervention%TYPE,
        i_nnn_epis_activity     IN nnn_epis_lnk_int_actv.id_nnn_epis_activity%TYPE,
        i_flg_lnk_status        IN nnn_epis_lnk_int_actv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_intervention_activity';
        l_timestamp        TIMESTAMP WITH LOCAL TIME ZONE;
        l_nic_intervention nic_intervention.id_nic_intervention%TYPE;
        l_nic_activity     nic_activity.id_nic_activity %TYPE;
        l_rec              nnn_epis_lnk_int_actv%ROWTYPE;
        l_error            t_error_out;
        l_lst_rowid        table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error     := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error     := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error     := g_error || ' i_flg_lnk_status = ' || coalesce(to_char(i_flg_lnk_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Get NIC Intervention Id';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT nei.id_nic_intervention
          INTO l_nic_intervention
          FROM nnn_epis_intervention nei
         WHERE nei.id_nnn_epis_intervention = i_nnn_epis_intervention;
    
        g_error := 'Get NIC Activity Id';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT nea.id_nic_activity
          INTO l_nic_activity
          FROM nnn_epis_activity nea
         WHERE nea.id_nnn_epis_activity = i_nnn_epis_activity;
    
        BEGIN
            SELECT lnkia.id_nnn_epis_lnk_int_actv
              INTO l_rec.id_nnn_epis_lnk_int_actv
              FROM nnn_epis_lnk_int_actv lnkia
             WHERE lnkia.id_nnn_epis_intervention = i_nnn_epis_intervention
               AND lnkia.id_nnn_epis_activity = i_nnn_epis_activity;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_rec.id_nnn_epis_lnk_int_actv := NULL; -- There is not yet a link between these two items. Just ignore.
        END;
    
        l_rec.id_nnn_epis_intervention := i_nnn_epis_intervention;
        l_rec.id_nnn_epis_activity     := i_nnn_epis_activity;
        l_rec.interv_activity_code     := pk_nic_model.get_interv_activity_code(i_nic_intervention => l_nic_intervention,
                                                                                i_nic_activity     => l_nic_activity);
        l_rec.id_episode               := i_episode;
        l_rec.id_professional          := i_prof.id;
        l_rec.flg_lnk_status           := i_flg_lnk_status;
        l_rec.dt_trs_time_start        := l_timestamp;
        l_rec.dt_trs_time_end          := NULL;
    
        IF l_rec.id_nnn_epis_lnk_int_actv IS NULL
        THEN
            l_rec.id_nnn_epis_lnk_int_actv := ts_nnn_epis_lnk_int_actv.next_key();
            ts_nnn_epis_lnk_int_actv.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_INT_ACTV',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            --Add original entry to tracking history of changes          
            set_epis_lnk_int_actv_hist(i_nnn_epis_lnk_int_actv => l_rec.id_nnn_epis_lnk_int_actv,
                                       i_dt_trs_time_end       => l_timestamp);
            -- Update entry                                                   
            ts_nnn_epis_lnk_int_actv.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_INT_ACTV',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
    
    END set_lnk_intervention_activity;

    PROCEDURE set_lnk_outcome_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN nnn_epis_lnk_outc_ind.id_episode%TYPE,
        i_nnn_epis_outcome   IN nnn_epis_lnk_outc_ind.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_lnk_outc_ind.id_nnn_epis_indicator%TYPE,
        i_flg_lnk_status     IN nnn_epis_lnk_outc_ind.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_outcome_indicator';
        l_timestamp     TIMESTAMP WITH LOCAL TIME ZONE;
        l_noc_outcome   noc_outcome.id_noc_outcome%TYPE;
        l_noc_indicator noc_indicator.id_noc_indicator%TYPE;
        l_rec           nnn_epis_lnk_outc_ind%ROWTYPE;
        l_error         t_error_out;
        l_lst_rowid     table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error     := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error     := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error     := g_error || ' i_flg_lnk_status = ' || coalesce(to_char(i_flg_lnk_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Get noc outcome Id';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT nei.id_noc_outcome
          INTO l_noc_outcome
          FROM nnn_epis_outcome nei
         WHERE nei.id_nnn_epis_outcome = i_nnn_epis_outcome;
    
        g_error := 'Get noc indicator Id';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        SELECT nei.id_noc_indicator
          INTO l_noc_indicator
          FROM nnn_epis_indicator nei
         WHERE nei.id_nnn_epis_indicator = i_nnn_epis_indicator;
    
        BEGIN
        
            SELECT lnkoi.id_nnn_epis_lnk_outc_ind
              INTO l_rec.id_nnn_epis_lnk_outc_ind
              FROM nnn_epis_lnk_outc_ind lnkoi
             WHERE lnkoi.id_nnn_epis_outcome = i_nnn_epis_outcome
               AND lnkoi.id_nnn_epis_indicator = i_nnn_epis_indicator;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_rec.id_nnn_epis_lnk_outc_ind := NULL; -- There is not yet a link between these two items. Just ignore.
        END;
    
        l_rec.id_nnn_epis_outcome    := i_nnn_epis_outcome;
        l_rec.id_nnn_epis_indicator  := i_nnn_epis_indicator;
        l_rec.id_episode             := i_episode;
        l_rec.id_professional        := i_prof.id;
        l_rec.outcome_indicator_code := pk_noc_model.get_outcome_indicator_code(i_noc_outcome   => l_noc_outcome,
                                                                                i_noc_indicator => l_noc_indicator);
        l_rec.flg_lnk_status         := i_flg_lnk_status;
        l_rec.dt_trs_time_start      := l_timestamp;
        l_rec.dt_trs_time_end        := NULL;
    
        IF l_rec.id_nnn_epis_lnk_outc_ind IS NULL
        THEN
            l_rec.id_nnn_epis_lnk_outc_ind := ts_nnn_epis_lnk_outc_ind.next_key();
            ts_nnn_epis_lnk_outc_ind.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_OUTC_IND',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        ELSE
            -- Add original entry to tracking history of changes          
            set_epis_lnk_outc_ind_hist(i_nnn_epis_lnk_outc_ind => l_rec.id_nnn_epis_lnk_outc_ind,
                                       i_dt_trs_time_end       => l_timestamp);
            -- Update entry        
            ts_nnn_epis_lnk_outc_ind.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_OUTC_IND',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
    END set_lnk_outcome_indicator;

    PROCEDURE set_lnk_diagnosis_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_nnn_epis_diagnosis    IN nnn_epis_lnk_dg_intrv.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_intervention IN nnn_epis_lnk_dg_intrv.id_nnn_epis_intervention%TYPE,
        i_flg_lnk_status        IN nnn_epis_lnk_dg_intrv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_diagnosis_intervention';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_lnk_dg_intrv%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error     := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error     := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error     := g_error || ' i_flg_lnk_status = ' || coalesce(to_char(i_flg_lnk_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            -- Check if already exists a link between the two itens retrieving the ID
            SELECT lnkdi.id_nnn_epis_lnk_dg_intrv
              INTO l_rec.id_nnn_epis_lnk_dg_intrv
              FROM nnn_epis_lnk_dg_intrv lnkdi
             WHERE lnkdi.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
               AND lnkdi.id_nnn_epis_intervention = i_nnn_epis_intervention;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- There is not yet a link between these two items. Just ignore.
        END;
    
        l_rec.id_nnn_epis_diagnosis    := i_nnn_epis_diagnosis;
        l_rec.id_nnn_epis_intervention := i_nnn_epis_intervention;
        l_rec.id_episode               := i_episode;
        l_rec.id_professional          := i_prof.id;
        l_rec.flg_lnk_status           := i_flg_lnk_status;
        l_rec.dt_trs_time_start        := l_timestamp;
        l_rec.dt_trs_time_end          := NULL;
    
        IF l_rec.id_nnn_epis_lnk_dg_intrv IS NULL
        THEN
            l_rec.id_nnn_epis_lnk_dg_intrv := ts_nnn_epis_lnk_dg_intrv.next_key();
            ts_nnn_epis_lnk_dg_intrv.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_DG_INTRV',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        ELSE
            -- Add original entry to tracking history of changes           
            set_epis_lnk_dg_intrv_hist(i_nnn_epis_lnk_dg_intrv => l_rec.id_nnn_epis_lnk_dg_intrv,
                                       i_dt_trs_time_end       => l_timestamp);
            -- Update entry                                                           
            ts_nnn_epis_lnk_dg_intrv.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_LNK_DG_INTRV',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
    
    END set_lnk_diagnosis_intervention;

    PROCEDURE upd_nic_interv_status
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'upd_nic_interv_status';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_current_status nnn_epis_intervention.flg_req_status%TYPE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT ei.flg_req_status
          INTO l_current_status
          FROM nnn_epis_intervention ei
         WHERE ei.id_nnn_epis_intervention = i_nnn_epis_intervention;
    
        IF l_current_status != i_flg_req_status
           AND NOT is_req_final_state(i_flg_req_status => l_current_status)
        THEN
            --Add original entry to tracking history of changes
            set_epis_nic_intervention_hist(i_nnn_epis_intervention => i_nnn_epis_intervention,
                                           i_dt_trs_time_end       => l_timestamp);
            -- Update entry              
            ts_nnn_epis_intervention.upd(id_nnn_epis_intervention_in => i_nnn_epis_intervention,
                                         id_professional_in          => i_prof.id,
                                         flg_req_status_in           => i_flg_req_status,
                                         dt_trs_time_start_in        => l_timestamp,
                                         dt_val_time_end_in          => CASE
                                                                         is_req_final_state(i_flg_req_status => i_flg_req_status)
                                                                            WHEN TRUE THEN
                                                                             l_timestamp
                                                                            ELSE
                                                                             NULL
                                                                        END,
                                         rows_out                    => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INTERVENTION',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    END upd_nic_interv_status;

    PROCEDURE upd_nic_activity_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'upd_nic_activity_status';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_current_status nnn_epis_activity.flg_req_status%TYPE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT ea.flg_req_status
          INTO l_current_status
          FROM nnn_epis_activity ea
        
         WHERE ea.id_nnn_epis_activity = i_nnn_epis_activity;
    
        IF l_current_status != i_flg_req_status
           AND NOT is_req_final_state(i_flg_req_status => l_current_status)
        THEN
            --Add original entry to tracking history of changes
            set_epis_nic_activity_hist(i_nnn_epis_activity => i_nnn_epis_activity, i_dt_trs_time_end => l_timestamp);
            -- Update entry              
            ts_nnn_epis_activity.upd(id_nnn_epis_activity_in => i_nnn_epis_activity,
                                     id_professional_in      => i_prof.id,
                                     flg_req_status_in       => i_flg_req_status,
                                     dt_trs_time_start_in    => l_timestamp,
                                     dt_val_time_end_in      => CASE
                                                                 is_req_final_state(i_flg_req_status => i_flg_req_status)
                                                                    WHEN TRUE THEN
                                                                     l_timestamp
                                                                    ELSE
                                                                     NULL
                                                                END,
                                     rows_out                => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_ACTIVITY',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    END upd_nic_activity_status;

    PROCEDURE cancel_epis_noc_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_cancel_reason    IN nnn_epis_outcome.id_cancel_reason%TYPE,
        i_cancel_notes     IN nnn_epis_outcome.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_outcome';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
        l_flg_req_status nnn_epis_outcome.flg_req_status%TYPE;
    BEGIN
        g_error := 'Cancel NOC outcome with id_nnn_epis_outcome = ' || to_char(i_nnn_epis_outcome);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_timestamp      := coalesce(i_timestamp, current_timestamp);
        l_flg_req_status := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_cancelled);
    
        -- Add original entry to tracking history of changes
        set_epis_noc_outcome_hist(i_nnn_epis_outcome => i_nnn_epis_outcome, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_outcome.upd(id_nnn_epis_outcome_in => i_nnn_epis_outcome,
                                id_professional_in     => i_prof.id,
                                id_cancel_reason_in    => i_cancel_reason,
                                cancel_notes_in        => i_cancel_notes,
                                flg_req_status_in      => l_flg_req_status,
                                dt_val_time_end_in     => l_timestamp,
                                dt_trs_time_start_in   => l_timestamp);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_OUTCOME',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_noc_outcome;

    PROCEDURE cancel_epis_noc_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_cancel_reason      IN nnn_epis_indicator.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_indicator.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_indicator';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
        l_flg_req_status nnn_epis_indicator.flg_req_status%TYPE;
    BEGIN
        g_error := 'Cancel NOC indicator with i_nnn_epis_indicator = ' || to_char(i_nnn_epis_indicator);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_timestamp      := coalesce(i_timestamp, current_timestamp);
        l_flg_req_status := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_cancelled);
    
        -- Add original entry to tracking history of changes
        set_epis_noc_indicator_hist(i_nnn_epis_indicator => i_nnn_epis_indicator, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_indicator.upd(id_nnn_epis_indicator_in => i_nnn_epis_indicator,
                                  id_professional_in       => i_prof.id,
                                  id_cancel_reason_in      => i_cancel_reason,
                                  cancel_notes_in          => i_cancel_notes,
                                  flg_req_status_in        => l_flg_req_status,
                                  dt_val_time_end_in       => l_timestamp,
                                  dt_trs_time_start_in     => l_timestamp);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_INDICATOR',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_noc_indicator;

    PROCEDURE cancel_epis_nic_intervention
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_cancel_reason         IN nnn_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_intervention.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nic_intervention';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
        l_flg_req_status nnn_epis_intervention.flg_req_status%TYPE;
    BEGIN
        g_error := 'Cancel NIC intervention with i_nnn_epis_intervention = ' || to_char(i_nnn_epis_intervention);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_timestamp      := coalesce(i_timestamp, current_timestamp);
        l_flg_req_status := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_cancelled);
    
        --Add original entry to tracking history of changes
        set_epis_nic_intervention_hist(i_nnn_epis_intervention => i_nnn_epis_intervention,
                                       i_dt_trs_time_end       => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_intervention.upd(id_nnn_epis_intervention_in => i_nnn_epis_intervention,
                                     id_professional_in          => i_prof.id,
                                     id_cancel_reason_in         => i_cancel_reason,
                                     cancel_notes_in             => i_cancel_notes,
                                     flg_req_status_in           => l_flg_req_status,
                                     dt_val_time_end_in          => l_timestamp,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_INTERVENTION',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_nic_intervention;

    PROCEDURE cancel_epis_nic_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_cancel_reason     IN nnn_epis_activity.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_activity.cancel_notes%TYPE DEFAULT NULL,
        i_flg_req_status    IN nnn_epis_activity.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_cancelled,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nic_activity';
        l_timestamp      TIMESTAMP WITH LOCAL TIME ZONE;
        l_error          t_error_out;
        l_lst_rowid      table_varchar;
        l_flg_req_status nnn_epis_activity.flg_req_status%TYPE;
    BEGIN
        g_error := 'Cancel NIC activity with i_nnn_epis_activity = ' || to_char(i_nnn_epis_activity);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_timestamp      := coalesce(i_timestamp, current_timestamp);
        l_flg_req_status := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_cancelled);
    
        --Add original entry to tracking history of changes
        set_epis_nic_activity_hist(i_nnn_epis_activity => i_nnn_epis_activity, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_activity.upd(id_nnn_epis_activity_in => i_nnn_epis_activity,
                                 id_professional_in      => i_prof.id,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 cancel_notes_in         => i_cancel_notes,
                                 flg_req_status_in       => l_flg_req_status,
                                 dt_val_time_end_in      => l_timestamp,
                                 dt_trs_time_start_in    => l_timestamp,
                                 rows_out                => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_ACTIVITY',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_nic_activity;

    FUNCTION set_epis_nic_activity_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode               IN nnn_epis_activity_det.id_episode%TYPE,
        i_nnn_epis_activity     IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE DEFAULT NULL,
        i_time_start            IN nnn_epis_activity_det.dt_val_time_start%TYPE,
        i_time_end              IN nnn_epis_activity_det.dt_val_time_end%TYPE,
        i_epis_documentation    IN nnn_epis_activity_det.id_epis_documentation%TYPE,
        i_vital_sign_read_list  IN nnn_epis_activity_det.vital_sign_read_list%TYPE,
        i_notes                 IN CLOB DEFAULT NULL,
        i_lst_task_activity     IN table_number DEFAULT NULL,
        i_lst_task_executed     IN table_varchar DEFAULT NULL,
        i_lst_task_notes        IN table_varchar DEFAULT NULL,
        i_dt_plan               IN nnn_epis_activity_det.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan     IN nnn_epis_activity_det.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number           IN nnn_epis_activity_det.exec_number%TYPE DEFAULT NULL,
        i_flg_status            IN nnn_epis_activity_det.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_nic_activity_det';
    
        e_invalid_array_size EXCEPTION;
    
        l_rec               nnn_epis_activity_det%ROWTYPE;
        l_rec_task          nnn_epis_actv_det_task%ROWTYPE;
        l_timestamp         TIMESTAMP WITH LOCAL TIME ZONE;
        l_error             t_error_out;
        l_lst_rowid         table_varchar;
        l_lst_task_activity table_number;
        l_lst_task_executed table_varchar;
        l_lst_task_notes    table_varchar;
        l_idx               PLS_INTEGER;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_nnn_epis_activity_det = ' || coalesce(to_char(i_nnn_epis_activity_det), '<null>');
        g_error := g_error || ' i_time_start = ' ||
                   coalesce(to_char(i_time_start, 'DD-MON-YYYY HH24:MI:SS TZR'), '<null>');
        g_error := g_error || ' i_time_end = ' || coalesce(to_char(i_time_end, 'DD-MON-YYYY HH24:MI:SS TZR'), '<null>');
        g_error := g_error || ' i_epis_documentation = ' || coalesce(to_char(i_epis_documentation), '<null>');
        g_error := g_error || ' i_vital_sign_read_list = ' || coalesce(i_vital_sign_read_list, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_task_activity := coalesce(i_lst_task_activity, table_number());
        l_lst_task_executed := coalesce(i_lst_task_executed, table_varchar());
        l_lst_task_notes    := coalesce(i_lst_task_notes, table_varchar());
    
        --Sanity check: all task arrays must have same size
        IF l_lst_task_activity.count != l_lst_task_executed.count
           OR l_lst_task_activity.count != l_lst_task_notes.count
        THEN
            RAISE e_invalid_array_size;
        END IF;
    
        l_rec.id_nnn_epis_activity_det := i_nnn_epis_activity_det;
        l_rec.id_nnn_epis_activity     := i_nnn_epis_activity;
        l_rec.id_patient               := i_patient;
        l_rec.id_episode               := i_episode;
        l_rec.id_visit                 := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional          := i_prof.id;
        l_rec.dt_plan                  := i_dt_plan;
        l_rec.id_order_recurr_plan     := i_order_recurr_plan;
        l_rec.exec_number              := i_exec_number;
        l_rec.flg_status               := coalesce(i_flg_status, pk_nnn_constant.g_task_status_finished);
        l_rec.id_epis_documentation    := i_epis_documentation;
        l_rec.vital_sign_read_list     := i_vital_sign_read_list;
        l_rec.dt_val_time_start        := i_time_start;
        l_rec.dt_val_time_end          := i_time_end;
        l_rec.dt_trs_time_start        := l_timestamp;
        l_rec.dt_trs_time_end          := NULL;
    
        IF l_rec.id_nnn_epis_activity_det IS NULL
        THEN
            l_rec.id_nnn_epis_activity_det := ts_nnn_epis_activity_det.next_key();
            ts_nnn_epis_activity_det.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_ACTIVITY_DET',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        ELSE
            -- Add original entry to tracking history of changes
            set_epis_nic_activity_det_hist(i_nnn_epis_activity_det => l_rec.id_nnn_epis_activity_det,
                                           i_dt_trs_time_end       => l_timestamp);
            -- Update entry        
            ts_nnn_epis_activity_det.upd(rec_in => l_rec, rows_out => l_lst_rowid);
        
            -- When is an edition should delete outdated activity tasks
            ts_nnn_epis_actv_det_task.del_by_col(colname_in  => 'ID_NNN_EPIS_ACTIVITY_DET',
                                                 colvalue_in => l_rec.id_nnn_epis_activity_det);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_ACTIVITY_DET',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
        -- Saves a list of activity tasks (only applicable for activities defined as tasklist)
        FOR l_idx IN 1 .. l_lst_task_activity.count
        LOOP
            g_error := 'Insert new record in NNN_EPIS_ACTV_DET_TASK: ';
            g_error := g_error || ' id_nan_risk_factor = ' || coalesce(to_char(l_lst_task_activity(l_idx)), '<null>');
        
            l_rec_task.id_nnn_epis_actv_det_task := ts_nnn_epis_actv_det_task.next_key;
            l_rec_task.id_nnn_epis_activity_det  := l_rec.id_nnn_epis_activity_det;
            l_rec_task.id_nic_activity           := l_lst_task_activity(l_idx);
            l_rec_task.flg_executed              := l_lst_task_executed(l_idx);
            ts_nnn_epis_actv_det_task.ins(rec_in => l_rec_task);
        
            IF l_lst_task_notes(l_idx) IS NOT NULL
               OR i_nnn_epis_activity_det IS NOT NULL
            THEN
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => g_epis_actv_det_tsk_code_notes ||
                                                                  to_char(l_rec_task.id_nnn_epis_actv_det_task),
                                                      i_desc   => l_lst_task_notes(l_idx),
                                                      i_module => g_module_pfh);
            END IF;
        END LOOP;
    
        IF i_notes IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_activity_det_code_notes ||
                                                              to_char(l_rec.id_nnn_epis_activity),
                                                  i_desc   => i_notes,
                                                  i_module => g_module_pfh);
        END IF;
    
        RETURN l_rec.id_nnn_epis_activity_det;
    EXCEPTION
        WHEN e_invalid_array_size THEN
            g_error := 'Invalid input parameters. Input arrays must have same size';
            pk_alert_exceptions.raise_error(error_name_in => 'e_invalid_array_size',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        
    END set_epis_nic_activity_det;

    PROCEDURE cancel_epis_nic_activity_exec
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_cancel_reason         IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_activity_det.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nic_activity_exec';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Cancel the execution of NIC activity with i_nnn_epis_activity_det = ' ||
                   to_char(i_nnn_epis_activity_det);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_nic_activity_det_hist(i_nnn_epis_activity_det => i_nnn_epis_activity_det,
                                       i_dt_trs_time_end       => l_timestamp);
        -- Update entry
        ts_nnn_epis_activity_det.upd(id_nnn_epis_activity_det_in => i_nnn_epis_activity_det,
                                     id_professional_in          => i_prof.id,
                                     id_cancel_reason_in         => i_cancel_reason,
                                     cancel_notes_in             => i_cancel_notes,
                                     flg_status_in               => pk_nnn_constant.g_task_status_cancelled,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_ACTIVITY_DET',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_nic_activity_exec;

    FUNCTION get_epis_nic_activity_execs
    (
        i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nic_activity_execs';
        l_epis_activity_det_rows ts_nnn_epis_activity_det.nnn_epis_activity_det_tc;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nead.*
          BULK COLLECT
          INTO l_epis_activity_det_rows
          FROM nnn_epis_activity_det nead
         WHERE nead.id_nnn_epis_activity = i_nnn_epis_activity
           AND instr(i_fltr_status, nead.flg_status) > 0;
    
        RETURN l_epis_activity_det_rows;
    
    END get_epis_nic_activity_execs;

    PROCEDURE cancel_epis_nic_activity_execs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE,
        i_cancel_reason     IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_activity_det.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nic_activity_execs';
    
        l_epis_nic_activity_det_rows ts_nnn_epis_activity_det.nnn_epis_activity_det_tc;
        l_epis_nic_activity_det_row  nnn_epis_activity_det%ROWTYPE;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_cancel_reason = ' || coalesce(to_char(i_cancel_reason), '<null>');
        g_error := g_error || ' i_cancel_notes = ' || coalesce(i_cancel_notes, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Get all the planned executions with status "Ordered" for the NIC activity
        l_epis_nic_activity_det_rows := get_epis_nic_activity_execs(i_nnn_epis_activity => i_nnn_epis_activity,
                                                                    i_fltr_status       => pk_nnn_constant.g_task_status_ordered);
    
        FOR i IN 1 .. l_epis_nic_activity_det_rows.count()
        LOOP
            l_epis_nic_activity_det_row := l_epis_nic_activity_det_rows(i);
        
            cancel_epis_nic_activity_exec(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_nnn_epis_activity_det => l_epis_nic_activity_det_row.id_nnn_epis_activity_det,
                                          i_cancel_reason         => i_cancel_reason,
                                          i_cancel_notes          => i_cancel_notes,
                                          i_timestamp             => i_timestamp);
        END LOOP;
    END cancel_epis_nic_activity_execs;

    PROCEDURE cancel_epis_nan_diag_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_cancel_reason      IN nnn_epis_diag_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diag_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nan_diag_eval';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Cancel NANDA diagnosis evaluation with i_nnn_epis_diag_eval = ' ||
                       to_char(i_nnn_epis_diag_eval);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_nan_diag_eval_hist(i_nnn_epis_diag_eval => i_nnn_epis_diag_eval, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_diag_eval.upd(id_nnn_epis_diag_eval_in => i_nnn_epis_diag_eval,
                                  id_professional_in       => i_prof.id,
                                  id_cancel_reason_in      => i_cancel_reason,
                                  cancel_notes_in          => i_cancel_notes,
                                  flg_status_in            => pk_nnn_constant.g_diagnosis_status_cancelled,
                                  dt_trs_time_start_in     => l_timestamp,
                                  rows_out                 => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_DIAG_EVAL',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_nan_diag_eval;

    PROCEDURE cancel_epis_noc_outcome_eval
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_cancel_reason         IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_outcome_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_outcome_eval';
        l_rec       nnn_epis_outcome_eval%ROWTYPE;
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Cancel the evaluation of NOC outcome with i_nnn_epis_outcome_eval = ' ||
                       to_char(i_nnn_epis_outcome_eval);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_noc_outcome_eval_hist(i_nnn_epis_outcome_eval => l_rec.id_nnn_epis_outcome_eval,
                                       i_dt_trs_time_end       => l_timestamp);
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_outcome_eval.upd(id_nnn_epis_outcome_eval_in => i_nnn_epis_outcome_eval,
                                     id_professional_in          => i_prof.id,
                                     id_cancel_reason_in         => i_cancel_reason,
                                     cancel_notes_in             => i_cancel_notes,
                                     flg_status_in               => pk_nnn_constant.g_task_status_cancelled,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_OUTCOME_EVAL',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_noc_outcome_eval;

    PROCEDURE cancel_epis_noc_ind_eval
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_cancel_reason     IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes      IN nnn_epis_ind_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_ind_eval';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Cancel the evaluation of NOC indicator with i_nnn_epis_ind_eval = ' || to_char(i_nnn_epis_ind_eval);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_noc_ind_eval_hist(i_nnn_epis_ind_eval => i_nnn_epis_ind_eval, i_dt_trs_time_end => l_timestamp);
        -- Update entry
        ts_nnn_epis_ind_eval.upd(id_nnn_epis_ind_eval_in => i_nnn_epis_ind_eval,
                                 id_professional_in      => i_prof.id,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 cancel_notes_in         => i_cancel_notes,
                                 flg_status_in           => pk_nnn_constant.g_task_status_cancelled,
                                 dt_trs_time_start_in    => l_timestamp,
                                 rows_out                => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_IND_EVAL',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_noc_ind_eval;

    PROCEDURE cancel_lnk_dg_intrv
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_dg_intrv IN nnn_epis_lnk_dg_intrv.id_nnn_epis_lnk_dg_intrv%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_lnk_dg_intrv';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Cancel the linkage between NANDA diagnosis and NIC intervention with i_nnn_epis_lnk_dg_intrv = ' ||
                   to_char(i_nnn_epis_lnk_dg_intrv);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --Add original entry to tracking history of changes        
        set_epis_lnk_dg_intrv_hist(i_nnn_epis_lnk_dg_intrv => i_nnn_epis_lnk_dg_intrv,
                                   i_dt_trs_time_end       => l_timestamp);
    
        -- Update entry status as cancelled, who and timestamp.
        ts_nnn_epis_lnk_dg_intrv.upd(id_nnn_epis_lnk_dg_intrv_in => i_nnn_epis_lnk_dg_intrv,
                                     id_professional_in          => i_prof.id,
                                     flg_lnk_status_in           => pk_alert_constant.g_cancelled,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_LNK_DG_INTRV',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_lnk_dg_intrv;

    PROCEDURE cancel_lnk_dg_outc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_nnn_epis_lnk_dg_outc IN nnn_epis_lnk_dg_outc.id_nnn_epis_lnk_dg_outc%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_lnk_dg_outc';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Cancel the linkage between NANDA diagnosis and NOC outcome with i_nnn_epis_lnk_dg_outc = ' ||
                   to_char(i_nnn_epis_lnk_dg_outc);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --Add original entry to tracking history of changes
        set_epis_lnk_dg_outc_hist(i_nnn_epis_lnk_dg_outc => i_nnn_epis_lnk_dg_outc, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who and timestamp.
        ts_nnn_epis_lnk_dg_outc.upd(id_nnn_epis_lnk_dg_outc_in => i_nnn_epis_lnk_dg_outc,
                                    id_professional_in         => i_prof.id,
                                    flg_lnk_status_in          => pk_alert_constant.g_cancelled,
                                    dt_trs_time_start_in       => l_timestamp,
                                    rows_out                   => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_LNK_DG_OUTC',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_lnk_dg_outc;

    PROCEDURE cancel_lnk_outc_ind
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_outc_ind IN nnn_epis_lnk_outc_ind.id_nnn_epis_lnk_outc_ind%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_lnk_outc_ind';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Cancel the linkage between NOC outcome and NOC indicator with i_nnn_epis_lnk_outc_ind = ' ||
                   to_char(i_nnn_epis_lnk_outc_ind);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_lnk_outc_ind_hist(i_nnn_epis_lnk_outc_ind => i_nnn_epis_lnk_outc_ind,
                                   i_dt_trs_time_end       => l_timestamp);
    
        -- Update entry status as cancelled, who and timestamp.
        ts_nnn_epis_lnk_outc_ind.upd(id_nnn_epis_lnk_outc_ind_in => i_nnn_epis_lnk_outc_ind,
                                     id_professional_in          => i_prof.id,
                                     flg_lnk_status_in           => pk_alert_constant.g_cancelled,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_LNK_OUTC_IND',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_lnk_outc_ind;

    PROCEDURE cancel_lnk_int_actv
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_lnk_int_actv IN nnn_epis_lnk_int_actv.id_nnn_epis_lnk_int_actv%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_lnk_int_actv';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Cancel the linkage between NIC intervention and NIC activity with i_nnn_epis_lnk_outc_ind = ' ||
                   to_char(i_nnn_epis_lnk_int_actv);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Add original entry to tracking history of changes
        set_epis_lnk_int_actv_hist(i_nnn_epis_lnk_int_actv => i_nnn_epis_lnk_int_actv,
                                   i_dt_trs_time_end       => l_timestamp);
    
        -- Update entry status as cancelled, who and timestamp.
        ts_nnn_epis_lnk_int_actv.upd(id_nnn_epis_lnk_int_actv_in => i_nnn_epis_lnk_int_actv,
                                     id_professional_in          => i_prof.id,
                                     flg_lnk_status_in           => pk_alert_constant.g_cancelled,
                                     dt_trs_time_start_in        => l_timestamp,
                                     rows_out                    => l_lst_rowid);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_LNK_INT_ACTV',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_lnk_int_actv;

    FUNCTION get_lnk_dg_outc_by_diag
    (
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_outc.id_nnn_epis_diagnosis%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_outc_by_diag';
        l_epis_lnk_dg_outc_rows ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neldo.*
          BULK COLLECT
          INTO l_epis_lnk_dg_outc_rows
          FROM nnn_epis_lnk_dg_outc neldo
         INNER JOIN nnn_epis_outcome neo
            ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
         WHERE neldo.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
           AND instr(i_fltr_status, neo.flg_req_status) > 0
           AND neldo.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_outc_rows;
    
    END get_lnk_dg_outc_by_diag;

    FUNCTION get_lnk_dg_outc_by_outc
    (
        i_nnn_epis_outcome IN nnn_epis_lnk_dg_outc.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_outc_by_outc';
        l_epis_lnk_dg_outc_rows ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neldo.*
          BULK COLLECT
          INTO l_epis_lnk_dg_outc_rows
          FROM nnn_epis_lnk_dg_outc neldo
         INNER JOIN nnn_epis_diagnosis ned
            ON neldo.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
         WHERE neldo.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND instr(i_fltr_status, ned.flg_req_status) > 0
           AND neldo.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_outc_rows;
    
    END get_lnk_dg_outc_by_outc;

    FUNCTION get_lnk_dg_outc_by_diags
    (
        i_lst_nnn_epis_diag IN table_number,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_outc_by_diags';
        l_epis_lnk_dg_outc_rows ts_nnn_epis_lnk_dg_outc.nnn_epis_lnk_dg_outc_tc;
        l_lst_nnn_epis_diag     table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lst_nnn_epis_diag = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_nnn_epis_diag, i_delim => ','), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_diag := coalesce(i_lst_nnn_epis_diag, table_number());
    
        SELECT neldo.*
          BULK COLLECT
          INTO l_epis_lnk_dg_outc_rows
          FROM nnn_epis_lnk_dg_outc neldo
         INNER JOIN nnn_epis_outcome neo
            ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
         WHERE neldo.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                t.column_value id_nnn_epis_diagnosis
                                                 FROM TABLE(l_lst_nnn_epis_diag) t)
           AND instr(i_fltr_status, neo.flg_req_status) > 0
           AND neldo.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_outc_rows;
    
    END get_lnk_dg_outc_by_diags;

    FUNCTION get_lnk_outc_ind_by_outc
    (
        i_nnn_epis_outcome IN nnn_epis_lnk_outc_ind.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_outc_ind_by_outc';
        l_epis_lnk_outc_ind_rows ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neloi.*
          BULK COLLECT
          INTO l_epis_lnk_outc_ind_rows
          FROM nnn_epis_lnk_outc_ind neloi
         INNER JOIN nnn_epis_indicator nei
            ON neloi.id_nnn_epis_indicator = nei.id_nnn_epis_indicator
         WHERE neloi.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND instr(i_fltr_status, nei.flg_req_status) > 0
           AND neloi.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_outc_ind_rows;
    
    END get_lnk_outc_ind_by_outc;

    FUNCTION get_lnk_outc_ind_by_ind
    (
        i_nnn_epis_indicator IN nnn_epis_lnk_outc_ind.id_nnn_epis_indicator%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_outc_ind_by_ind';
        l_epis_lnk_outc_ind_rows ts_nnn_epis_lnk_outc_ind.nnn_epis_lnk_outc_ind_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neloi.*
          BULK COLLECT
          INTO l_epis_lnk_outc_ind_rows
          FROM nnn_epis_lnk_outc_ind neloi
         INNER JOIN nnn_epis_outcome neo
            ON neloi.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
         WHERE neloi.id_nnn_epis_indicator = i_nnn_epis_indicator
           AND instr(i_fltr_status, neo.flg_req_status) > 0
           AND neloi.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_outc_ind_rows;
    
    END get_lnk_outc_ind_by_ind;

    FUNCTION get_lnk_dg_intrv_by_diag
    (
        i_nnn_epis_diagnosis IN nnn_epis_lnk_dg_intrv.id_nnn_epis_diagnosis%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_intrv_by_diag';
        l_epis_lnk_dg_intrv_rows ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_diagnosis = ' || coalesce(to_char(i_nnn_epis_diagnosis), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neldi.*
          BULK COLLECT
          INTO l_epis_lnk_dg_intrv_rows
          FROM nnn_epis_lnk_dg_intrv neldi
         INNER JOIN nnn_epis_intervention nei
            ON neldi.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
         WHERE neldi.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
           AND instr(i_fltr_status, nei.flg_req_status) > 0
           AND neldi.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_intrv_rows;
    
    END get_lnk_dg_intrv_by_diag;

    FUNCTION get_lnk_dg_intrv_by_diags
    (
        i_lst_nnn_epis_diag IN table_number,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc IS
    
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_intrv_by_diags';
        l_epis_lnk_dg_intrv_rows ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;
        l_lst_nnn_epis_diag      table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lst_nnn_epis_diag = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_lst_nnn_epis_diag, i_delim => ','), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_diag := coalesce(i_lst_nnn_epis_diag, table_number());
    
        SELECT neldi.*
          BULK COLLECT
          INTO l_epis_lnk_dg_intrv_rows
          FROM nnn_epis_lnk_dg_intrv neldi
         INNER JOIN nnn_epis_intervention nei
            ON neldi.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
         WHERE instr(i_fltr_status, nei.flg_req_status) > 0
           AND neldi.id_nnn_epis_diagnosis IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                t.column_value id_nnn_epis_diagnosis
                                                 FROM TABLE(l_lst_nnn_epis_diag) t)
           AND neldi.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_intrv_rows;
    
    END get_lnk_dg_intrv_by_diags;

    FUNCTION get_lnk_dg_intrv_by_intrv
    (
        i_nnn_epis_intervention IN nnn_epis_lnk_dg_intrv.id_nnn_epis_intervention%TYPE,
        i_fltr_status           IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_dg_intrv_by_intrv';
        l_epis_lnk_dg_intrv_rows ts_nnn_epis_lnk_dg_intrv.nnn_epis_lnk_dg_intrv_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neldi.*
          BULK COLLECT
          INTO l_epis_lnk_dg_intrv_rows
          FROM nnn_epis_lnk_dg_intrv neldi
         INNER JOIN nnn_epis_diagnosis ned
            ON neldi.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
         WHERE neldi.id_nnn_epis_intervention = i_nnn_epis_intervention
           AND instr(i_fltr_status, ned.flg_req_status) > 0
           AND neldi.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_dg_intrv_rows;
    
    END get_lnk_dg_intrv_by_intrv;

    FUNCTION get_lnk_int_actv_by_intrv
    (
        i_nnn_epis_intervention IN nnn_epis_lnk_int_actv.id_nnn_epis_intervention%TYPE,
        i_fltr_status           IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_int_actv_by_intrv';
        l_epis_lnk_int_actv_rows ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_intervention = ' || coalesce(to_char(i_nnn_epis_intervention), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nelia.*
          BULK COLLECT
          INTO l_epis_lnk_int_actv_rows
          FROM nnn_epis_lnk_int_actv nelia
         INNER JOIN nnn_epis_activity nea
            ON nelia.id_nnn_epis_activity = nea.id_nnn_epis_activity
         WHERE nelia.id_nnn_epis_intervention = i_nnn_epis_intervention
           AND instr(i_fltr_status, nea.flg_req_status) > 0
           AND nelia.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_int_actv_rows;
    
    END get_lnk_int_actv_by_intrv;

    FUNCTION get_lnk_int_actv_by_actv
    (
        i_nnn_epis_activity IN nnn_epis_lnk_int_actv.id_nnn_epis_activity%TYPE,
        i_fltr_status       IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_lnk_int_actv_by_actv';
        l_epis_lnk_int_actv_rows ts_nnn_epis_lnk_int_actv.nnn_epis_lnk_int_actv_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_activity = ' || coalesce(to_char(i_nnn_epis_activity), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT nelia.*
          BULK COLLECT
          INTO l_epis_lnk_int_actv_rows
          FROM nnn_epis_lnk_int_actv nelia
         INNER JOIN nnn_epis_intervention nei
            ON nelia.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
         WHERE nelia.id_nnn_epis_activity = i_nnn_epis_activity
           AND instr(i_fltr_status, nei.flg_req_status) > 0
           AND nelia.flg_lnk_status = pk_alert_constant.g_active;
    
        RETURN l_epis_lnk_int_actv_rows;
    
    END get_lnk_int_actv_by_actv;

    PROCEDURE cancel_epis_nan_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_cancel_reason      IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diagnosis.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_nan_diagnosis';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Cancel NANDA diagnosis with id_nnn_epis_diagnosis = ' || to_char(i_nnn_epis_diagnosis);
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        -- Add original entry to tracking history of changes
        set_epis_nan_diagnosis_hist(i_nnn_epis_diagnosis => i_nnn_epis_diagnosis, i_dt_trs_time_end => l_timestamp);
    
        -- Update entry status as cancelled, who, reason, notes and timestamp.
        ts_nnn_epis_diagnosis.upd(id_nnn_epis_diagnosis_in => i_nnn_epis_diagnosis,
                                  id_professional_in       => i_prof.id,
                                  id_cancel_reason_in      => i_cancel_reason,
                                  cancel_notes_in          => i_cancel_notes,
                                  flg_req_status_in        => pk_nnn_constant.g_req_status_cancelled,
                                  dt_val_time_end_in       => l_timestamp,
                                  dt_trs_time_start_in     => l_timestamp,
                                  rows_out                 => l_lst_rowid);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NNN_EPIS_DIAGNOSIS',
                                      i_rowids     => l_lst_rowid,
                                      o_error      => l_error);
    
    END cancel_epis_nan_diagnosis;

    FUNCTION get_epis_noc_outcome_evals
    (
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_fltr_status      IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_outcome_evals';
        l_epis_outcome_eval_rows ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_tc;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neoe.*
          BULK COLLECT
          INTO l_epis_outcome_eval_rows
          FROM nnn_epis_outcome_eval neoe
         WHERE neoe.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND instr(i_fltr_status, neoe.flg_status) > 0;
    
        RETURN l_epis_outcome_eval_rows;
    
    END get_epis_noc_outcome_evals;

    PROCEDURE cancel_epis_noc_outcome_evals
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_cancel_reason    IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes     IN nnn_epis_outcome_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_outcome_evals';
    
        l_epis_outcome_eval_rows ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_tc;
        l_epis_outcome_eval_row  nnn_epis_outcome_eval%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_outcome = ' || coalesce(to_char(i_nnn_epis_outcome), '<null>');
        g_error := g_error || ' i_cancel_reason = ' || coalesce(to_char(i_cancel_reason), '<null>');
        g_error := g_error || ' i_cancel_notes = ' || coalesce(i_cancel_notes, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Get all the Outcomes Evaluation associated a one NOC Outcome with status "Ordered"
        l_epis_outcome_eval_rows := get_epis_noc_outcome_evals(i_nnn_epis_outcome => i_nnn_epis_outcome,
                                                               i_fltr_status      => pk_nnn_constant.g_task_status_ordered);
    
        FOR i IN 1 .. l_epis_outcome_eval_rows.count()
        LOOP
            l_epis_outcome_eval_row := l_epis_outcome_eval_rows(i);
        
            cancel_epis_noc_outcome_eval(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_nnn_epis_outcome_eval => l_epis_outcome_eval_row.id_nnn_epis_outcome_eval,
                                         i_cancel_reason         => i_cancel_reason,
                                         i_cancel_notes          => i_cancel_notes,
                                         i_timestamp             => i_timestamp);
        END LOOP;
    
    END cancel_epis_noc_outcome_evals;

    FUNCTION get_epis_noc_ind_evals
    (
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_fltr_status        IN VARCHAR DEFAULT pk_nnn_constant.g_req_status_filter_any
    ) RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_tc IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_noc_ind_evals';
    
        l_epis_ind_eval_rows ts_nnn_epis_ind_eval.nnn_epis_ind_eval_tc;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error := g_error || ' i_fltr_status = ' || coalesce(i_fltr_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT neie.*
          BULK COLLECT
          INTO l_epis_ind_eval_rows
          FROM nnn_epis_ind_eval neie
         WHERE neie.id_nnn_epis_indicator = i_nnn_epis_indicator
           AND instr(i_fltr_status, neie.flg_status) > 0;
    
        RETURN l_epis_ind_eval_rows;
    
    END get_epis_noc_ind_evals;

    PROCEDURE cancel_epis_noc_ind_evals
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_cancel_reason      IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_ind_eval.cancel_notes%TYPE DEFAULT NULL,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_noc_ind_evals';
    
        l_epis_ind_eval_rows ts_nnn_epis_ind_eval.nnn_epis_ind_eval_tc;
        l_epis_ind_eval_row  nnn_epis_ind_eval%ROWTYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error := g_error || ' i_cancel_reason = ' || coalesce(to_char(i_cancel_reason), '<null>');
        g_error := g_error || ' i_cancel_notes = ' || coalesce(i_cancel_notes, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Get all the Indicators Evaluation active associated a one NOC Indicator with status "Ordered"
        l_epis_ind_eval_rows := get_epis_noc_ind_evals(i_nnn_epis_indicator => i_nnn_epis_indicator,
                                                       i_fltr_status        => pk_nnn_constant.g_task_status_ordered);
    
        FOR i IN 1 .. l_epis_ind_eval_rows.count()
        LOOP
            l_epis_ind_eval_row := l_epis_ind_eval_rows(i);
        
            cancel_epis_noc_ind_eval(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_nnn_epis_ind_eval => l_epis_ind_eval_row.id_nnn_epis_ind_eval,
                                     i_cancel_reason     => i_cancel_reason,
                                     i_cancel_notes      => i_cancel_notes,
                                     i_timestamp         => i_timestamp);
        END LOOP;
    
    END cancel_epis_noc_ind_evals;

    PROCEDURE get_epis_diag_intrv_by_intrvs
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_lst_nnn_epis_intervention IN table_number,
        o_interventions             OUT pk_types.cursor_type,
        o_diagnoses                 OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_diag_intrv_by_intrvs';
        l_lst_nnn_epis_intervention table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_intervention := coalesce(i_lst_nnn_epis_intervention, table_number());
    
        -- Get the Interventions
        OPEN o_interventions FOR
            SELECT DISTINCT neldi.id_nnn_epis_intervention,
                            pk_nic_model.get_intervention_name(i_nic_intervention => nei.id_nic_intervention) intervention_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T014') intervention_type
              FROM nnn_epis_lnk_dg_intrv neldi
             INNER JOIN nnn_epis_intervention nei
                ON neldi.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
             WHERE neldi.id_nnn_epis_intervention IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_intervention) t);
    
        -- Get the Diagnoses            
        OPEN o_diagnoses FOR
            SELECT neldi.id_nnn_epis_diagnosis,
                   pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ned.id_nan_diagnosis) diagnosis_name,
                   pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T007') diagnosis_type,
                   neldi.id_nnn_epis_intervention
              FROM nnn_epis_lnk_dg_intrv neldi
             INNER JOIN nnn_epis_diagnosis ned
                ON neldi.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
             WHERE neldi.id_nnn_epis_intervention IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_intervention) t)
               AND neldi.flg_lnk_status = pk_alert_constant.g_active;
    
    END get_epis_diag_intrv_by_intrvs;

    PROCEDURE get_epis_intrv_actv_by_actvs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_lst_nnn_epis_activity IN table_number,
        o_activities            OUT pk_types.cursor_type,
        o_interventions         OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_intrv_actv_by_actvs';
        l_lst_nnn_epis_activity table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_activity := coalesce(i_lst_nnn_epis_activity, table_number());
    
        -- Get the Activities
        OPEN o_activities FOR
            SELECT DISTINCT nelia.id_nnn_epis_intervention,
                            pk_nic_model.get_activity_name(i_nic_activity => nea.id_nic_activity) activity_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T019') activity_type
              FROM nnn_epis_lnk_int_actv nelia
             INNER JOIN nnn_epis_activity nea
                ON nelia.id_nnn_epis_activity = nea.id_nnn_epis_activity
             WHERE nelia.id_nnn_epis_activity IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_activity) t);
    
        -- Get the Interventions
        OPEN o_interventions FOR
            SELECT DISTINCT nelia.id_nnn_epis_intervention,
                            pk_nic_model.get_intervention_name(i_nic_intervention => nei.id_nic_intervention) intervention_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T014') intervention_type
              FROM nnn_epis_lnk_int_actv nelia
             INNER JOIN nnn_epis_intervention nei
                ON nelia.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
             WHERE nelia.id_nnn_epis_activity IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_activity) t)
               AND nelia.flg_lnk_status = pk_alert_constant.g_active;
    
    END get_epis_intrv_actv_by_actvs;

    PROCEDURE get_epis_diag_outc_by_outcs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_lst_nnn_epis_outcome IN table_number,
        o_outcomes             OUT pk_types.cursor_type,
        o_diagnoses            OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_diag_outc_by_outcs';
        l_lst_nnn_epis_outcome table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_outcome := coalesce(i_lst_nnn_epis_outcome, table_number());
    
        -- Get the outcomes
        OPEN o_outcomes FOR
            SELECT DISTINCT neldo.id_nnn_epis_outcome,
                            pk_noc_model.get_outcome_name(i_noc_outcome => neo.id_noc_outcome) outcome_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T010') outcome_type
              FROM nnn_epis_lnk_dg_outc neldo
             INNER JOIN nnn_epis_outcome neo
                ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
             WHERE neldo.id_nnn_epis_outcome IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(l_lst_nnn_epis_outcome) t);
    
        -- Get the Diagnoses            
        OPEN o_diagnoses FOR
            SELECT neldo.id_nnn_epis_diagnosis,
                   pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ned.id_nan_diagnosis) diagnosis_name,
                   pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T007') diagnosis_type,
                   neldo.id_nnn_epis_outcome
              FROM nnn_epis_lnk_dg_outc neldo
             INNER JOIN nnn_epis_diagnosis ned
                ON neldo.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
             WHERE neldo.id_nnn_epis_outcome IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                  column_value
                                                   FROM TABLE(l_lst_nnn_epis_outcome) t)
               AND neldo.flg_lnk_status = pk_alert_constant.g_active;
    
    END get_epis_diag_outc_by_outcs;

    PROCEDURE get_epis_outc_ind_by_inds
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_lst_nnn_epis_indicator IN table_number,
        o_indicators             OUT pk_types.cursor_type,
        o_outcomes               OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_outc_ind_by_inds';
        l_lst_nnn_epis_indicator table_number;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_indicator := coalesce(i_lst_nnn_epis_indicator, table_number());
    
        -- Get the indicators
        OPEN o_indicators FOR
            SELECT DISTINCT neldo.id_nnn_epis_indicator,
                            pk_noc_model.get_indicator_name(i_noc_indicator => nei.id_noc_indicator) indicator_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T020') indicator_type
              FROM nnn_epis_lnk_outc_ind neldo
             INNER JOIN nnn_epis_indicator nei
                ON neldo.id_nnn_epis_indicator = nei.id_nnn_epis_indicator
             WHERE neldo.id_nnn_epis_indicator IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_indicator) t);
    
        -- Get the outcomes
        OPEN o_outcomes FOR
            SELECT DISTINCT neldo.id_nnn_epis_outcome,
                            pk_noc_model.get_outcome_name(i_noc_outcome => neo.id_noc_outcome) outcome_name,
                            pk_message.get_message(i_lang => i_lang, i_code_mess => 'NNN_CPLAN_T010') outcome_type,
                            neldo.id_nnn_epis_indicator
              FROM nnn_epis_lnk_outc_ind neldo
             INNER JOIN nnn_epis_outcome neo
                ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
             WHERE neldo.id_nnn_epis_indicator IN
                   (SELECT /*+opt_estimate(table t rows=1)*/
                     column_value
                      FROM TABLE(l_lst_nnn_epis_indicator) t)
               AND neldo.flg_lnk_status = pk_alert_constant.g_active;
    
    END get_epis_outc_ind_by_inds;

    FUNCTION set_epis_noc_indicator
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_indicator.id_patient%TYPE,
        i_episode             IN nnn_epis_indicator.id_episode%TYPE,
        i_noc_indicator       IN nnn_epis_indicator.id_noc_indicator%TYPE,
        i_nnn_epis_indicator  IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE DEFAULT NULL,
        i_episode_origin      IN nnn_epis_indicator.id_episode_origin%TYPE DEFAULT NULL,
        i_episode_destination IN nnn_epis_indicator.id_episode_destination%TYPE DEFAULT NULL,
        i_flg_prn             IN nnn_epis_indicator.flg_prn%TYPE DEFAULT pk_alert_constant.g_no,
        i_notes_prn           IN CLOB DEFAULT NULL,
        i_flg_time            IN nnn_epis_indicator.flg_time%TYPE DEFAULT pk_nnn_constant.g_time_performed_episode,
        i_flg_priority        IN nnn_epis_indicator.flg_priority%TYPE DEFAULT pk_nnn_constant.g_priority_normal,
        i_order_recurr_plan   IN nnn_epis_indicator.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_flg_req_status      IN nnn_epis_indicator.flg_req_status%TYPE DEFAULT pk_nnn_constant.g_req_status_ordered,
        i_timestamp           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_indicator.id_nnn_epis_indicator%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_noc_indicator';
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_rec       nnn_epis_indicator%ROWTYPE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_noc_indicator = ' || coalesce(to_char(i_noc_indicator), '<null>');
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error := g_error || ' i_flg_prn = ' || coalesce(i_flg_prn, '<null>');
        g_error := g_error || ' i_flg_time = ' || coalesce(i_flg_time, '<null>');
        g_error := g_error || ' i_flg_priority = ' || coalesce(i_flg_priority, '<null>');
        g_error := g_error || ' i_order_recurr_plan = ' || coalesce(to_char(i_order_recurr_plan), '<null>');
        g_error := g_error || ' i_flg_req_status = ' || coalesce(i_flg_req_status, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        IF i_nnn_epis_indicator IS NOT NULL
        THEN
            l_rec := get_epis_noc_indicator_row(i_nnn_epis_indicator => i_nnn_epis_indicator);
        END IF;
    
        l_rec.id_nnn_epis_indicator  := i_nnn_epis_indicator;
        l_rec.id_noc_indicator       := i_noc_indicator;
        l_rec.id_patient             := i_patient;
        l_rec.id_episode             := i_episode;
        l_rec.id_visit               := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional        := i_prof.id;
        l_rec.id_episode_origin      := i_episode_origin;
        l_rec.id_episode_destination := i_episode_destination;
        l_rec.flg_prn                := coalesce(i_flg_prn, pk_alert_constant.g_no);
        l_rec.flg_time               := coalesce(i_flg_time, pk_nnn_constant.g_time_performed_episode);
        l_rec.flg_priority           := coalesce(i_flg_priority, pk_nnn_constant.g_priority_normal);
        l_rec.id_order_recurr_plan   := i_order_recurr_plan;
        l_rec.flg_req_status         := coalesce(i_flg_req_status, pk_nnn_constant.g_req_status_ordered);
        l_rec.dt_trs_time_start      := l_timestamp;
        l_rec.dt_trs_time_end        := NULL;
    
        IF l_rec.id_nnn_epis_indicator IS NULL
        THEN
            l_rec.id_nnn_epis_indicator := ts_nnn_epis_indicator.next_key();
            l_rec.dt_val_time_start     := l_timestamp; -- The valid time start of the Indicator request (sets once when is created and inmutable during the lifecycle of this request)
            l_rec.dt_val_time_end       := NULL; -- The valid time end of the Indicator request (sets once when is cancelated/finished)
        
            ts_nnn_epis_indicator.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INDICATOR',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            --Add original entry to tracking history of changes
            set_epis_noc_indicator_hist(i_nnn_epis_indicator => l_rec.id_nnn_epis_indicator,
                                        i_dt_trs_time_end    => l_timestamp);
            -- Update entry
            ts_nnn_epis_indicator.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_INDICATOR',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        END IF;
    
        IF i_notes_prn IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_ind_code_notes_prn ||
                                                              to_char(l_rec.id_nnn_epis_indicator),
                                                  i_desc   => i_notes_prn,
                                                  i_module => g_module_pfh);
        END IF;
        RETURN l_rec.id_nnn_epis_indicator;
    END set_epis_noc_indicator;
    FUNCTION set_epis_noc_indicator_eval
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN nnn_epis_ind_eval.id_patient%TYPE,
        i_episode            IN nnn_epis_ind_eval.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_ind_eval  IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE DEFAULT NULL,
        i_dt_evaluation      IN nnn_epis_ind_eval.dt_evaluation%TYPE,
        i_target_value       IN nnn_epis_ind_eval.target_value%TYPE,
        i_indicator_value    IN nnn_epis_ind_eval.indicator_value%TYPE,
        i_notes              IN CLOB DEFAULT NULL,
        i_dt_plan            IN nnn_epis_ind_eval.dt_plan%TYPE DEFAULT NULL,
        i_order_recurr_plan  IN nnn_epis_ind_eval.id_order_recurr_plan%TYPE DEFAULT NULL,
        i_exec_number        IN nnn_epis_ind_eval.exec_number%TYPE DEFAULT NULL,
        i_flg_status         IN nnn_epis_ind_eval.flg_status%TYPE DEFAULT pk_nnn_constant.g_task_status_finished,
        i_timestamp          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_epis_noc_indicator_eval';
        l_rec       nnn_epis_ind_eval%ROWTYPE;
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_error     t_error_out;
        l_lst_rowid table_varchar;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        g_error := g_error || ' i_nnn_epis_indicator = ' || coalesce(to_char(i_nnn_epis_indicator), '<null>');
        g_error := g_error || ' i_nnn_epis_ind_eval = ' || coalesce(to_char(i_nnn_epis_ind_eval), '<null>');
        g_error := g_error || ' i_dt_evaluation = ' ||
                   coalesce(to_char(i_dt_evaluation, 'DD-MON-YYYY HH24:MI:SS TZR'), '<null>');
        g_error := g_error || ' i_target_value = ' || coalesce(to_char(i_target_value), '<null>');
        g_error := g_error || ' i_indicator_value = ' || coalesce(to_char(i_indicator_value), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec.id_nnn_epis_ind_eval  := i_nnn_epis_ind_eval;
        l_rec.id_nnn_epis_indicator := i_nnn_epis_indicator;
        l_rec.id_patient            := i_patient;
        l_rec.id_episode            := i_episode;
        l_rec.id_visit              := pk_visit.get_visit(i_episode => i_episode, o_error => l_error);
        l_rec.id_professional       := i_prof.id;
        l_rec.dt_plan               := i_dt_plan;
        l_rec.id_order_recurr_plan  := i_order_recurr_plan;
        l_rec.exec_number           := i_exec_number;
        l_rec.flg_status            := coalesce(i_flg_status, pk_nnn_constant.g_task_status_finished);
        l_rec.dt_evaluation         := i_dt_evaluation;
        l_rec.target_value          := i_target_value;
        l_rec.indicator_value       := i_indicator_value;
        l_rec.dt_trs_time_start     := l_timestamp;
        l_rec.dt_trs_time_end       := NULL;
    
        IF l_rec.id_nnn_epis_ind_eval IS NULL
        THEN
            l_rec.id_nnn_epis_ind_eval := ts_nnn_epis_ind_eval.next_key();
            ts_nnn_epis_ind_eval.ins(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_IND_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        ELSE
            -- Add original entry to tracking history of changes
            set_epis_noc_ind_eval_hist(i_nnn_epis_ind_eval => l_rec.id_nnn_epis_ind_eval,
                                       i_dt_trs_time_end   => l_timestamp);
            -- Update entry
            ts_nnn_epis_ind_eval.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'NNN_EPIS_IND_EVAL',
                                          i_rowids     => l_lst_rowid,
                                          o_error      => l_error);
        
        END IF;
        IF i_notes IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => g_epis_ind_eval_code_notes_prn ||
                                                              to_char(l_rec.id_nnn_epis_ind_eval),
                                                  i_desc   => i_notes,
                                                  i_module => g_module_pfh);
        END IF;
    
        RETURN l_rec.id_nnn_epis_ind_eval;
    END set_epis_noc_indicator_eval;

    PROCEDURE set_lnk_diagnosis_intervention
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_diagnosis    IN table_number,
        i_lst_nnn_epis_intervention IN table_number,
        i_flg_lnk_status            IN nnn_epis_lnk_dg_intrv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_diagnosis_intervention';
        l_timestamp                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_lst_nnn_epis_diagnosis    table_number;
        l_lst_nnn_epis_intervention table_number;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_diagnosis    := coalesce(i_lst_nnn_epis_diagnosis, table_number());
        l_lst_nnn_epis_intervention := coalesce(i_lst_nnn_epis_intervention, table_number());
    
        FOR i IN 1 .. l_lst_nnn_epis_diagnosis.count()
        LOOP
            set_lnk_diagnosis_intervention(i_lang                  => i_lang,
                                           i_prof                  => i_prof,
                                           i_episode               => i_episode,
                                           i_nnn_epis_diagnosis    => l_lst_nnn_epis_diagnosis(i),
                                           i_nnn_epis_intervention => l_lst_nnn_epis_intervention(i),
                                           i_flg_lnk_status        => i_flg_lnk_status,
                                           i_timestamp             => l_timestamp);
        
        END LOOP;
    END set_lnk_diagnosis_intervention;

    PROCEDURE set_lnk_intervention_activity
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_lst_nnn_epis_activity     IN table_number,
        i_flg_lnk_status            IN nnn_epis_lnk_int_actv.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp                 IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_intervention_activity';
        l_timestamp                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_lst_nnn_epis_intervention table_number;
        l_lst_nnn_epis_activity     table_number;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_intervention := coalesce(i_lst_nnn_epis_intervention, table_number());
        l_lst_nnn_epis_activity     := coalesce(i_lst_nnn_epis_activity, table_number());
    
        FOR i IN 1 .. l_lst_nnn_epis_intervention.count()
        LOOP
            set_lnk_intervention_activity(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_episode               => i_episode,
                                          i_nnn_epis_intervention => l_lst_nnn_epis_intervention(i),
                                          i_nnn_epis_activity     => l_lst_nnn_epis_activity(i),
                                          i_flg_lnk_status        => i_flg_lnk_status,
                                          i_timestamp             => l_timestamp);
        
        END LOOP;
    END set_lnk_intervention_activity;

    PROCEDURE set_lnk_diagnosis_outcome
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_diagnosis IN table_number,
        i_lst_nnn_epis_outcome   IN table_number,
        i_flg_lnk_status         IN nnn_epis_lnk_dg_outc.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_diagnosis_outcome';
        l_timestamp              TIMESTAMP WITH LOCAL TIME ZONE;
        l_lst_nnn_epis_diagnosis table_number;
        l_lst_nnn_epis_outcome   table_number;
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_diagnosis := coalesce(i_lst_nnn_epis_diagnosis, table_number());
        l_lst_nnn_epis_outcome   := coalesce(i_lst_nnn_epis_outcome, table_number());
    
        FOR i IN 1 .. l_lst_nnn_epis_diagnosis.count()
        LOOP
            pk_nnn_core.set_lnk_diagnosis_outcome(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_episode            => i_episode,
                                                  i_nnn_epis_diagnosis => l_lst_nnn_epis_diagnosis(i),
                                                  i_nnn_epis_outcome   => l_lst_nnn_epis_outcome(i),
                                                  i_flg_lnk_status     => i_flg_lnk_status,
                                                  i_timestamp          => l_timestamp);
        
        END LOOP;
    END set_lnk_diagnosis_outcome;

    PROCEDURE set_lnk_outcome_indicator
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN nnn_epis_lnk_dg_intrv.id_episode%TYPE,
        i_lst_nnn_epis_outcome   IN table_number,
        i_lst_nnn_epis_indicator IN table_number,
        i_flg_lnk_status         IN nnn_epis_lnk_outc_ind.flg_lnk_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_timestamp              IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_lnk_outcome_indicator';
        l_timestamp              TIMESTAMP WITH LOCAL TIME ZONE;
        l_lst_nnn_epis_outcome   table_number;
        l_lst_nnn_epis_indicator table_number;
    
    BEGIN
        l_timestamp := coalesce(i_timestamp, current_timestamp);
        g_error     := 'Input arguments:';
        g_error     := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error     := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error     := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error     := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lst_nnn_epis_outcome   := coalesce(i_lst_nnn_epis_outcome, table_number());
        l_lst_nnn_epis_indicator := coalesce(i_lst_nnn_epis_indicator, table_number());
    
        FOR i IN 1 .. i_lst_nnn_epis_indicator.count()
        LOOP
            set_lnk_outcome_indicator(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_episode            => i_episode,
                                      i_nnn_epis_outcome   => l_lst_nnn_epis_outcome(i),
                                      i_nnn_epis_indicator => l_lst_nnn_epis_indicator(i),
                                      i_flg_lnk_status     => i_flg_lnk_status,
                                      i_timestamp          => l_timestamp);
        
        END LOOP;
    END set_lnk_outcome_indicator;

    FUNCTION check_epis_nic_activity
    (
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_nan_diagnosis    IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_nic_intervention IN nnn_epis_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nnn_epis_activity.id_nic_activity%TYPE
    ) RETURN BOOLEAN IS
        l_exists PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_exists
          FROM nnn_epis_activity nea
         INNER JOIN nnn_epis_lnk_int_actv nelia
            ON nea.id_nnn_epis_activity = nelia.id_nnn_epis_activity
         INNER JOIN nnn_epis_intervention nei
            ON nelia.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
         INNER JOIN nnn_epis_lnk_dg_intrv neldi
            ON nei.id_nnn_epis_intervention = neldi.id_nnn_epis_intervention
         INNER JOIN nnn_epis_diagnosis ned
            ON neldi.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
         WHERE nea.id_patient = i_patient
           AND nea.id_episode = i_episode
           AND nea.id_nic_activity = i_nic_activity
           AND nei.id_nic_intervention = i_nic_intervention
           AND ned.id_nan_diagnosis = i_nan_diagnosis
           AND nea.flg_req_status != pk_nnn_constant.g_req_status_cancelled
           AND nei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
           AND ned.flg_req_status != pk_nnn_constant.g_req_status_cancelled;
    
        IF l_exists > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    END check_epis_nic_activity;

    FUNCTION check_epis_noc_indicator
    (
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN nnn_epis_indicator.id_noc_indicator%TYPE
    ) RETURN BOOLEAN IS
        l_exists PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_exists
          FROM nnn_epis_indicator nei
         INNER JOIN nnn_epis_lnk_outc_ind neloi
            ON nei.id_nnn_epis_indicator = neloi.id_nnn_epis_indicator
         INNER JOIN nnn_epis_outcome neo
            ON neloi.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
         INNER JOIN nnn_epis_lnk_dg_outc neldo
            ON neo.id_nnn_epis_outcome = neldo.id_nnn_epis_outcome
         INNER JOIN nnn_epis_diagnosis ned
            ON neldo.id_nnn_epis_diagnosis = ned.id_nnn_epis_diagnosis
         WHERE nei.id_patient = i_patient
           AND nei.id_episode = i_episode
           AND nei.id_noc_indicator = i_noc_indicator
           AND neo.id_noc_outcome = i_noc_outcome
           AND ned.id_nan_diagnosis = i_nan_diagnosis
           AND nei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
           AND neo.flg_req_status != pk_nnn_constant.g_req_status_cancelled
           AND ned.flg_req_status != pk_nnn_constant.g_req_status_cancelled;
    
        IF l_exists > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    END check_epis_noc_indicator;

    FUNCTION get_next_outcome_eval(i_nnn_epis_outcome nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE IS
    
        CURSOR c_next_outcome_eval IS
            SELECT eoe.id_nnn_epis_outcome_eval
              FROM TABLE(tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => i_nnn_epis_outcome)) eoe;
    
        l_nnn_epis_outcome_eval nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE;
    BEGIN
        OPEN c_next_outcome_eval;
        FETCH c_next_outcome_eval
            INTO l_nnn_epis_outcome_eval;
        CLOSE c_next_outcome_eval;
    
        RETURN l_nnn_epis_outcome_eval;
    
    END get_next_outcome_eval;

    FUNCTION get_next_indicator_eval(i_nnn_epis_indicator nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE IS
    
        CURSOR c_next_indicator_eval IS
            SELECT eie.id_nnn_epis_ind_eval
              FROM TABLE(tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => i_nnn_epis_indicator)) eie;
    
        l_nnn_epis_ind_eval nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE;
    BEGIN
        OPEN c_next_indicator_eval;
        FETCH c_next_indicator_eval
            INTO l_nnn_epis_ind_eval;
        CLOSE c_next_indicator_eval;
    
        RETURN l_nnn_epis_ind_eval;
    END get_next_indicator_eval;

    FUNCTION get_next_activity_det(i_nnn_epis_activity nnn_epis_activity.id_nnn_epis_activity%TYPE)
        RETURN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE IS
    
        CURSOR c_next_activity_det IS
            SELECT ead.id_nnn_epis_activity_det
              FROM TABLE(tf_next_nnn_epis_activ_det(i_nnn_epis_activity => i_nnn_epis_activity)) ead;
    
        l_nnn_epis_activity_det nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE;
    BEGIN
        OPEN c_next_activity_det;
        FETCH c_next_activity_det
            INTO l_nnn_epis_activity_det;
        CLOSE c_next_activity_det;
    
        RETURN l_nnn_epis_activity_det;
    END get_next_activity_det;

    FUNCTION get_outcome_has_evals(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE) RETURN BOOLEAN IS
        l_count     PLS_INTEGER := 0;
        l_has_evals BOOLEAN;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_outcome_eval neoe
         WHERE neoe.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND neoe.flg_status = pk_nnn_constant.g_task_status_finished;
    
        l_has_evals := l_count > 0;
        RETURN l_has_evals;
    
    END get_outcome_has_evals;

    FUNCTION get_outcome_planned_eval_count(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE)
        RETURN PLS_INTEGER IS
        l_count PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_outcome_eval neoe
         WHERE neoe.id_nnn_epis_outcome = i_nnn_epis_outcome
           AND neoe.flg_status IN (pk_nnn_constant.g_task_status_ordered,
                                   pk_nnn_constant.g_task_status_ongoing,
                                   pk_nnn_constant.g_task_status_suspended);
        RETURN l_count;
    
    END get_outcome_planned_eval_count;

    /**
     * Checks if a given NOC Outome has planned evaluations.
     * Are considered planned evaluation all of them that were not executed or cancelled.
    *
    * @param    i_nnn_epis_outcome              Careplan's NOC Outcome ID
    *
    * @return   True if there is at least one planned evaluation.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/24/2014
    */
    FUNCTION get_outcome_has_planned_evals(i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE) RETURN BOOLEAN IS
    
        l_count             PLS_INTEGER;
        l_has_planned_evals BOOLEAN;
    
    BEGIN
    
        l_count             := get_outcome_planned_eval_count(i_nnn_epis_outcome => i_nnn_epis_outcome);
        l_has_planned_evals := l_count > 0;
        RETURN l_has_planned_evals;
    
    END get_outcome_has_planned_evals;

    FUNCTION get_fsm_outcome_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_req_status   IN nnn_epis_outcome.flg_req_status%TYPE,
        i_action           IN action.internal_name%TYPE
    ) RETURN nnn_epis_outcome.flg_req_status%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_fsm_outcome_status';
        l_rec_plan_info t_recurr_plan_info_rec;
        c_invalid_status CONSTANT nnn_epis_outcome.flg_req_status%TYPE := '-';
        l_new_status        nnn_epis_outcome.flg_req_status%TYPE := c_invalid_status;
        l_order_recurr_plan nnn_epis_outcome.id_order_recurr_plan%TYPE;
        l_has_execs         BOOLEAN;
        l_has_planned_execs BOOLEAN;
        l_freq_type         VARCHAR(1 CHAR);
    
        /**
         * Calculates the status of the outcome when a cancel request action is 
         * performed. 
        */
        PROCEDURE calc_st_for_cancel_req IS
        BEGIN
        
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_draft -- Transition D2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when an evaluation is executed and
         * the type of recurrence for the outcome is "once" or "with recurrence".
        */
        PROCEDURE calc_st_for_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND l_has_planned_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND NOT l_has_planned_execs) -- Transition R2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND NOT l_has_planned_execs) -- Transition O4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND l_has_planned_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when an outcome is evaluated and
         * the type recurrence of the outcome is "no schedule".
        */
        PROCEDURE calc_st_for_exec_no_sched IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when the pause action is performed.
        */
        PROCEDURE calc_st_for_pause IS
        BEGIN
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R5
               OR i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_suspended;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when the resume action is performed.
        */
        PROCEDURE calc_st_for_resume IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when the cancel evaluation action is 
         * performed. This algorithm is only executed for the recurrence of type "once" 
         * or "with recurrence".
        */
        PROCEDURE calc_st_for_cancel_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_planned_execs AND NOT l_has_execs) -- Transition R1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND NOT l_has_planned_execs AND
                  NOT l_has_execs) -- Transition R4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_planned_execs AND l_has_execs) -- Transition O1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND NOT l_has_planned_execs) -- Transition O2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            END IF;
        END;
    
    BEGIN
        IF pk_nnn_core.is_req_final_state(i_flg_req_status => i_flg_req_status)
        THEN
            -- If the current state of the intervention is a final no state transitions is allowed.
            l_new_status := i_flg_req_status;
        ELSE
            -- Gets the execution information for the given outcome
            l_has_execs         := get_outcome_has_evals(i_nnn_epis_outcome);
            l_has_planned_execs := get_outcome_has_planned_evals(i_nnn_epis_outcome);
        
            SELECT neo.id_order_recurr_plan
              INTO l_order_recurr_plan
              FROM nnn_epis_outcome neo
             WHERE neo.id_nnn_epis_outcome = i_nnn_epis_outcome;
        
            -- By default assumes no schedule
            l_freq_type := pk_nnn_constant.g_req_freq_no_schedule;
            IF l_order_recurr_plan IS NOT NULL
            THEN
                l_rec_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_order_recurr_plan => l_order_recurr_plan);
                l_freq_type     := pk_nnn_core.recurr_option_to_freq_type(i_order_recurr_option => l_rec_plan_info.order_recurr_option);
            END IF;
        
            /*
             * Calculate the new outcome status.
             * First the action is evaluated, then the current outcome status.
            */
            CASE i_action
                WHEN pk_nnn_constant.g_action_outcome_cancel THEN
                    -- Cancel a NOC Outcome within a care plan                  
                    calc_st_for_cancel_req();
                WHEN pk_nnn_constant.g_action_outcome_evaluate THEN
                    -- Evaluate a NOC Outcome within a care plan                          
                    IF l_freq_type = pk_nnn_constant.g_req_freq_no_schedule
                    THEN
                        calc_st_for_exec_no_sched();
                    ELSE
                        calc_st_for_exec_recurr();
                    END IF;
                WHEN pk_nnn_constant.g_action_outcome_hold THEN
                    -- Hold a NOC Outcome within a care plan                          
                    calc_st_for_pause();
                WHEN pk_nnn_constant.g_action_outcome_resume THEN
                    -- Resume a NOC Outcome within a care plan                          
                    calc_st_for_resume();
                ELSE
                    g_error := 'The following action is not considered to evaluate the next outcome state: ' ||
                               i_action;
                    pk_alertlog.log_warn(text            => g_error,
                                         object_name     => g_package,
                                         sub_object_name => k_function_name,
                                         owner           => g_owner);
                
            END CASE;
        END IF;
    
        -- When the new status is not resolved by the previous algorithm, something is wrong, so
        -- an exception must be thrown
        IF l_new_status = c_invalid_status
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_nnn_constant.g_excep_inv_status_transition,
                                            text_in       => 'Unable to determine the new status when the action is ' ||
                                                             i_action || ', the current status is ' || i_flg_req_status ||
                                                             ', recurrence type is ' || l_freq_type || ', has execs ' ||
                                                             pk_utils.bool_to_flag(l_has_execs) ||
                                                             ', has planned execs ' ||
                                                             pk_utils.bool_to_flag(l_has_planned_execs));
        END IF;
    
        RETURN l_new_status;
    
    END get_fsm_outcome_status;

    FUNCTION get_ind_has_evals(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE) RETURN BOOLEAN IS
        l_count     PLS_INTEGER := 0;
        l_has_evals BOOLEAN;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_ind_eval neie
         WHERE neie.id_nnn_epis_indicator = i_nnn_epis_indicator
           AND neie.flg_status = pk_nnn_constant.g_task_status_finished;
    
        l_has_evals := l_count > 0;
        RETURN l_has_evals;
    
    END get_ind_has_evals;

    FUNCTION get_ind_planned_eval_count(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN PLS_INTEGER IS
        l_count PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM nnn_epis_ind_eval neie
         WHERE neie.id_nnn_epis_indicator = i_nnn_epis_indicator
           AND neie.flg_status IN (pk_nnn_constant.g_task_status_ordered,
                                   pk_nnn_constant.g_task_status_ongoing,
                                   pk_nnn_constant.g_task_status_suspended);
        RETURN l_count;
    
    END get_ind_planned_eval_count;

    /**
     * Checks if a given NOC Indicator has planned evaluations.
     * Are considered planned evaluation all of them that were not executed or cancelled.
    *
    * @param    i_nnn_epis_indicator              Careplan's NOC Indicator ID
    *
    * @return   True if there is at least one planned evaluation.
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    4/28/2014
    */
    FUNCTION get_ind_has_planned_evals(i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE)
        RETURN BOOLEAN IS
    
        l_count             PLS_INTEGER;
        l_has_planned_evals BOOLEAN;
    
    BEGIN
    
        l_count             := get_ind_planned_eval_count(i_nnn_epis_indicator => i_nnn_epis_indicator);
        l_has_planned_evals := l_count > 0;
        RETURN l_has_planned_evals;
    
    END get_ind_has_planned_evals;

    FUNCTION get_fsm_indicator_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_req_status     IN nnn_epis_indicator.flg_req_status%TYPE,
        i_action             IN action.internal_name%TYPE
    ) RETURN nnn_epis_indicator.flg_req_status%TYPE IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_fsm_indicator_status';
        l_rec_plan_info t_recurr_plan_info_rec;
        c_invalid_status CONSTANT nnn_epis_outcome.flg_req_status%TYPE := '-';
        l_new_status        nnn_epis_outcome.flg_req_status%TYPE := c_invalid_status;
        l_order_recurr_plan nnn_epis_outcome.id_order_recurr_plan%TYPE;
        l_has_execs         BOOLEAN;
        l_has_planned_execs BOOLEAN;
        l_freq_type         VARCHAR(1 CHAR);
    
        -- TODO: Refactor this fsm to reuse methods that calculate the state transitions rather than repeat them.
    
        /**
         * Calculates the status of the indicator when a cancel request action is 
         * performed. 
        */
        PROCEDURE calc_st_for_cancel_req IS
        BEGIN
        
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF i_flg_req_status = pk_nnn_constant.g_req_status_draft -- Transition D2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            END IF;
        END;
    
        /**
         * Calculates the status of the indicator when an evaluation is executed and
         * the type of recurrence for the outcome is "once" or "with recurrence".
        */
        PROCEDURE calc_st_for_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND l_has_planned_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs AND NOT l_has_planned_execs) -- Transition R2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND NOT l_has_planned_execs) -- Transition O4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs AND l_has_planned_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the indicator when an indicator is evaluated and
         * the type recurrence of the outcome is "no schedule".
        */
        PROCEDURE calc_st_for_exec_no_sched IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_execs) -- Transition R6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_execs) -- Transition O5
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the outcome when the pause action is performed.
        */
        PROCEDURE calc_st_for_pause IS
        BEGIN
            IF i_flg_req_status = pk_nnn_constant.g_req_status_ordered -- Transition R5
               OR i_flg_req_status = pk_nnn_constant.g_req_status_ongoing -- Transition O6
            THEN
                l_new_status := pk_nnn_constant.g_req_status_suspended;
            END IF;
        END;
    
        /**
         * Calculates the status of the indicator when the resume action is performed.
        */
        PROCEDURE calc_st_for_resume IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND NOT l_has_execs) -- Transition P3
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_suspended AND l_has_execs) -- Transition P4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the indicator when the cancel evaluation action is 
         * performed. This algorithm is only executed for the recurrence of type "once" 
         * or "with recurrence".
        */
        PROCEDURE calc_st_for_cancel_exec_recurr IS
        BEGIN
            IF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND l_has_planned_execs AND NOT l_has_execs) -- Transition R1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ordered AND NOT l_has_planned_execs AND
                  NOT l_has_execs) -- Transition R4
            THEN
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND l_has_planned_execs AND l_has_execs) -- Transition O1
            THEN
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            ELSIF (i_flg_req_status = pk_nnn_constant.g_req_status_ongoing AND NOT l_has_planned_execs) -- Transition O2
            THEN
                l_new_status := pk_nnn_constant.g_req_status_finished;
            END IF;
        END;
    
    BEGIN
        IF pk_nnn_core.is_req_final_state(i_flg_req_status => i_flg_req_status)
        THEN
            -- If the current state of the intervention is a final no state transitions is allowed.
            l_new_status := i_flg_req_status;
        ELSE
            -- Gets the execution information for the given indicator
            l_has_execs         := get_ind_has_evals(i_nnn_epis_indicator);
            l_has_planned_execs := get_ind_has_planned_evals(i_nnn_epis_indicator);
        
            SELECT nei.id_order_recurr_plan
              INTO l_order_recurr_plan
              FROM nnn_epis_indicator nei
             WHERE nei.id_nnn_epis_indicator = i_nnn_epis_indicator;
        
            -- By default assumes no schedule
            l_freq_type := pk_nnn_constant.g_req_freq_no_schedule;
            IF l_order_recurr_plan IS NOT NULL
            THEN
                l_rec_plan_info := pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_order_recurr_plan => l_order_recurr_plan);
                l_freq_type     := pk_nnn_core.recurr_option_to_freq_type(i_order_recurr_option => l_rec_plan_info.order_recurr_option);
            END IF;
        
            /*
             * Calculate the new outcome status.
             * First the action is evaluated, then the current outcome status.
            */
            CASE i_action
                WHEN pk_nnn_constant.g_action_indicator_cancel THEN
                    -- Cancel a NOC Indicator within a care plan                  
                    calc_st_for_cancel_req();
                WHEN pk_nnn_constant.g_action_indicator_evaluate THEN
                    -- Evaluate a NOC Indicator within a care plan                          
                    IF l_freq_type = pk_nnn_constant.g_req_freq_no_schedule
                    THEN
                        calc_st_for_exec_no_sched();
                    ELSE
                        calc_st_for_exec_recurr();
                    END IF;
                WHEN pk_nnn_constant.g_action_indicator_hold THEN
                    -- Hold a NOC Indicator within a care plan                          
                    calc_st_for_pause();
                WHEN pk_nnn_constant.g_action_indicator_resume THEN
                    -- Resume a NOC Indicator within a care plan                          
                    calc_st_for_resume();
                ELSE
                    g_error := 'The following action is not considered to evaluate the next indicator state: ' ||
                               i_action;
                    pk_alertlog.log_warn(text            => g_error,
                                         object_name     => g_package,
                                         sub_object_name => k_function_name,
                                         owner           => g_owner);
                
            END CASE;
        
        END IF;
    
        -- When the new status is not resolved by the previous algorithm, something is wrong, so
        -- an exception must be thrown
        IF l_new_status = c_invalid_status
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_nnn_constant.g_excep_inv_status_transition,
                                            text_in       => 'Unable to determine the new status when the action is ' ||
                                                             i_action || ', the current status is ' || i_flg_req_status ||
                                                             ', recurrence type is ' || l_freq_type || ', has execs ' ||
                                                             pk_utils.bool_to_flag(l_has_execs) ||
                                                             ', has planned execs ' ||
                                                             pk_utils.bool_to_flag(l_has_planned_execs),
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        END IF;
    
        RETURN l_new_status;
    
    END get_fsm_indicator_status;

    FUNCTION get_fsm_intervention_status
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_req_status        IN nnn_epis_intervention.flg_req_status%TYPE,
        i_action                IN action.internal_name%TYPE
    ) RETURN nnn_epis_intervention.flg_req_status%TYPE IS
        k_function_name  CONSTANT pk_types.t_internal_name_byte := 'get_fsm_intervention_status';
        c_invalid_status CONSTANT nnn_epis_intervention.flg_req_status%TYPE := '-';
        l_new_status nnn_epis_intervention.flg_req_status%TYPE := c_invalid_status;
    
        l_count_activities   PLS_INTEGER;
        l_count_ordered      PLS_INTEGER;
        l_count_ongoing      PLS_INTEGER;
        l_count_finished     PLS_INTEGER;
        l_count_discontinued PLS_INTEGER;
        l_count_cancelled    PLS_INTEGER;
        l_count_suspended    PLS_INTEGER;
    BEGIN
        -- This fsm implementation is a litle different from the previous ones, because the status of the intervention depends on the status of its linked activities.
        --
    
        IF pk_nnn_core.is_req_final_state(i_flg_req_status => i_flg_req_status)
        THEN
            -- If the current state of the intervention is a final no state transitions is allowed.
            l_new_status := i_flg_req_status;
        ELSE
        
            WITH linked_activities_by_state AS
             (SELECT DISTINCT nei.id_nnn_epis_intervention,
                              nei.flg_req_status int_flg_req_status,
                              nea.flg_req_status act_flg_req_status,
                              COUNT(*) over(PARTITION BY nei.id_nnn_epis_intervention, nea.flg_req_status) count_activities_by_req_status,
                              COUNT(*) over(PARTITION BY nei.id_nnn_epis_intervention) count_activities
                FROM nnn_epis_lnk_int_actv lnkia
               INNER JOIN nnn_epis_activity nea
                  ON lnkia.id_nnn_epis_activity = nea.id_nnn_epis_activity
               INNER JOIN nnn_epis_intervention nei
                  ON lnkia.id_nnn_epis_intervention = nei.id_nnn_epis_intervention
               WHERE lnkia.flg_lnk_status = pk_alert_constant.g_active
                 AND nei.id_nnn_epis_intervention = i_nnn_epis_intervention)
            
            SELECT (SELECT DISTINCT count_activities
                      FROM linked_activities_by_state x) count_activities,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_ordered) activites_ordered,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_ongoing) activites_ongoing,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_finished) activites_finished,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_discontinued) activites_discontinued,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_cancelled) activites_cancelled,
                   (SELECT x.count_activities_by_req_status
                      FROM linked_activities_by_state x
                     WHERE x.act_flg_req_status = pk_nnn_constant.g_req_status_suspended) activites_suspended
              INTO l_count_activities,
                   l_count_ordered,
                   l_count_ongoing,
                   l_count_finished,
                   l_count_discontinued,
                   l_count_cancelled,
                   l_count_suspended
              FROM dual;
        
            -- Default state: the current state
            l_new_status := i_flg_req_status;
        
            IF nvl(l_count_ordered, 0) = 0
               AND nvl(l_count_ongoing, 0) = 0
               AND nvl(l_count_suspended, 0) = 0
            THEN
                -- No activities with potential executions, then "Finished"
                l_new_status := pk_nnn_constant.g_req_status_finished;
            END IF;
        
            IF l_count_ordered = l_count_activities
            THEN
                -- All linked activities are currently in the state "Ordered"
                l_new_status := pk_nnn_constant.g_req_status_ordered;
            END IF;
            IF l_count_cancelled = l_count_activities
            THEN
                -- All linked activities are currently in the state "Cancelled"
                l_new_status := pk_nnn_constant.g_req_status_cancelled;
            END IF;
        
            IF l_count_discontinued = l_count_activities
            THEN
                -- All linked activities are currently in the state "Discontinued"
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            END IF;
        
            IF l_count_suspended = l_count_activities
            THEN
                -- All linked activities are currently in the state "Suspended"
                l_new_status := pk_nnn_constant.g_req_status_suspended;
            END IF;
        
            IF l_count_finished = l_count_activities
            THEN
                -- All linked activities are currently in the state "Finished"
                l_new_status := pk_nnn_constant.g_req_status_finished;
            END IF;
        
            IF l_count_ongoing > 0
            THEN
                -- At least one activity is currently in the state "Ongoing"
                l_new_status := pk_nnn_constant.g_req_status_ongoing;
            END IF;
        
            IF i_action = pk_nnn_constant.g_action_intervention_cancel
               AND l_count_finished > 0
            THEN
                l_new_status := pk_nnn_constant.g_req_status_discontinued;
            END IF;
        
            IF i_action = pk_nnn_constant.g_action_intervention_hold
            THEN
                l_new_status := pk_nnn_constant.g_req_status_suspended;
            END IF;
            IF i_action = pk_nnn_constant.g_action_intervention_resume
            THEN
                IF l_count_finished > 0
                THEN
                    l_new_status := pk_nnn_constant.g_req_status_ongoing;
                
                ELSE
                    l_new_status := pk_nnn_constant.g_req_status_ordered;
                END IF;
            
            END IF;
        
        END IF;
    
        -- When the new status is not resolved by the previous algorithm, something is wrong, so
        -- an exception must be thrown
        IF l_new_status = c_invalid_status
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_nnn_constant.g_excep_inv_status_transition,
                                            text_in       => 'Unable to determine the new status when the action is ' ||
                                                             i_action || ', the intervention is ' ||
                                                             to_char(i_nnn_epis_intervention) ||
                                                             ', the current status is ' || i_flg_req_status ||
                                                             ', l_count_activities: ' || l_count_activities ||
                                                             ', l_count_ordered: ' || l_count_ordered ||
                                                             ', l_count_ongoing: ' || l_count_ongoing ||
                                                             ', l_count_finished: ' || l_count_finished ||
                                                             ', l_count_discontinued: ' || l_count_discontinued ||
                                                             ', l_count_cancelled: ' || l_count_cancelled ||
                                                             ', l_count_suspended: ' || l_count_suspended,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        END IF;
    
        RETURN l_new_status;
    
    END get_fsm_intervention_status;

    /**
    * Evaluates in the patient care plan if there exist NOC Outcomes / NIC Interventions that can be linked to a Careplan's NANDA Diagnosis
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_nnn_epis_diagnosis           Careplan's NANDA Diagnosis ID
    *
    * @return   True if there exist potential items to establish a linkage with the Careplan's NANDA Diagnosis passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    1/2/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE
    ) RETURN BOOLEAN IS
        l_patient       patient.id_patient%TYPE;
        l_episode       episode.id_episode%TYPE;
        l_nan_diagnosis nan_diagnosis.id_nan_diagnosis%TYPE;
        l_exists        PLS_INTEGER;
    BEGIN
    
        SELECT ed.id_patient, ed.id_episode, ed.id_nan_diagnosis
          INTO l_patient, l_episode, l_nan_diagnosis
          FROM nnn_epis_diagnosis ed
         WHERE ed.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis;
    
        -- A NANDA Diagnosis can be linked to a NOC Outcome and/or to a NIC Intervention
    
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Checks if there is at least one active NOC Outcome that is not yet linked to this NANDA Diagnosis
                -- but it is a valid link according to the NOC/NANDA and/or NNN Linkages classification.
                SELECT 1
                  FROM nnn_epis_outcome eo
                 WHERE eo.id_patient = l_patient
                   AND eo.id_episode = l_episode
                   AND eo.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_dg_outc lnkdo
                         WHERE lnkdo.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                           AND lnkdo.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
                           AND lnkdo.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nan_cfg.is_linkable_diagnosis_outcome(i_prof          => i_prof,
                                                                i_nan_diagnosis => l_nan_diagnosis,
                                                                i_noc_outcome   => eo.id_noc_outcome) =
                       pk_alert_constant.g_yes)
            OR EXISTS
         (
                -- Checks if there is at least one active NIC Intervention that is not yet linked to this NANDA Diagnosis
                -- but it is a valid link according to the NIC/NANDA and/or NNN Linkages classification.
                SELECT 1
                  FROM nnn_epis_intervention ei
                 WHERE ei.id_patient = l_patient
                   AND ei.id_episode = l_episode
                   AND ei.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_dg_intrv lnkdi
                         WHERE lnkdi.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis
                           AND lnkdi.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                           AND lnkdi.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nan_cfg.is_linkable_diagnosis_interv(i_prof             => i_prof,
                                                               i_nan_diagnosis    => l_nan_diagnosis,
                                                               i_nic_intervention => ei.id_nic_intervention) =
                       pk_alert_constant.g_yes);
    
        RETURN(l_exists > 0);
    END exist_potential_links;

    /**
    * Evaluates in the patient care plan if there exist NOC Indicators / NANDA Diagnoses that can be linked to a Careplan's NOC Outcome
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID
    *
    * @return   True if there exist potential items to establish a linkage with the Careplan's NOC Outcome passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    1/2/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE
    ) RETURN BOOLEAN IS
        l_patient     patient.id_patient%TYPE;
        l_episode     episode.id_episode%TYPE;
        l_noc_outcome noc_outcome.id_noc_outcome%TYPE;
        l_exists      PLS_INTEGER;
    BEGIN
    
        SELECT eo.id_patient, eo.id_episode, eo.id_noc_outcome
          INTO l_patient, l_episode, l_noc_outcome
          FROM nnn_epis_outcome eo
         WHERE eo.id_nnn_epis_outcome = i_nnn_epis_outcome;
    
        -- A NOC Outcome can be linked to a NOC Indicator and/or to a NANDA Diagnosis.
    
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Checks if there is at least one active NOC Indicator that is not yet linked to this NOC outcome
                -- but it is a valid link according to the NOC classification.
                SELECT 1
                  FROM nnn_epis_indicator ei
                 WHERE ei.id_patient = l_patient
                   AND ei.id_episode = l_episode
                   AND ei.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_outc_ind lnkoi
                         WHERE lnkoi.id_nnn_epis_outcome = i_nnn_epis_outcome
                           AND lnkoi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                           AND lnkoi.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_noc_cfg.is_linkable_outcome_indicator(i_prof          => i_prof,
                                                                i_noc_outcome   => l_noc_outcome,
                                                                i_noc_indicator => ei.id_noc_indicator) =
                       pk_alert_constant.g_yes)
            OR EXISTS
         (
                -- Checks if there is at least one active NANDA Diangosis that is not yet linked to this NOC outcome
                -- but it is a valid link according to the NOC/NANDA and/or NNN Linkages classification.
                SELECT 1
                  FROM nnn_epis_diagnosis ed
                 WHERE ed.id_patient = l_patient
                   AND ed.id_episode = l_episode
                   AND ed.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_dg_outc lnkdo
                         WHERE lnkdo.id_nnn_epis_outcome = i_nnn_epis_outcome
                           AND lnkdo.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                           AND lnkdo.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nan_cfg.is_linkable_diagnosis_outcome(i_prof          => i_prof,
                                                                i_nan_diagnosis => ed.id_nan_diagnosis,
                                                                i_noc_outcome   => l_noc_outcome) =
                       pk_alert_constant.g_yes);
    
        RETURN(l_exists > 0);
    END exist_potential_links;

    /**
    * Evaluates in the patient care plan if there exist NOC Outcomes that can be linked to a Careplan's NOC Indicator
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID
    *
    * @return   True if there exist potential items to establish a linkage with the Careplan's NOC Indicator passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    1/2/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE
    ) RETURN BOOLEAN IS
        l_patient       patient.id_patient%TYPE;
        l_episode       episode.id_episode%TYPE;
        l_noc_indicator noc_indicator.id_noc_indicator%TYPE;
        l_exists        PLS_INTEGER;
    BEGIN
    
        SELECT ei.id_patient, ei.id_episode, ei.id_noc_indicator
          INTO l_patient, l_episode, l_noc_indicator
          FROM nnn_epis_indicator ei
         WHERE ei.id_nnn_epis_indicator = i_nnn_epis_indicator;
    
        -- A NOC Indicator can be linked to a NOC Outcome
    
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Checks if there is at least one active NOC Outcome that is not yet linked to this NOC Indicator
                -- but it is a valid link according to the NOC classification.
                SELECT 1
                  FROM nnn_epis_outcome eo
                 WHERE eo.id_patient = l_patient
                   AND eo.id_episode = l_episode
                   AND eo.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_outc_ind lnkoi
                         WHERE lnkoi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                           AND lnkoi.id_nnn_epis_indicator = i_nnn_epis_indicator
                           AND lnkoi.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_noc_cfg.is_linkable_outcome_indicator(i_prof          => i_prof,
                                                                i_noc_outcome   => eo.id_noc_outcome,
                                                                i_noc_indicator => l_noc_indicator) =
                       pk_alert_constant.g_yes);
        RETURN(l_exists > 0);
    END exist_potential_links;

    /**
    * Evaluates in the patient care plan if there exist NIC Activities / NANDA Diagnoses that can be linked to a Careplan's NIC Intervention
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_nnn_epis_intervention        Careplan's NIC Intervention ID
    *
    * @return   True if there exist potential items to establish a linkage with the Careplan's NIC Intervention passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    1/2/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE
    ) RETURN BOOLEAN IS
        l_patient          patient.id_patient%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_nic_intervention nic_intervention.id_nic_intervention%TYPE;
        l_exists           PLS_INTEGER;
    BEGIN
    
        SELECT ei.id_patient, ei.id_episode, ei.id_nic_intervention
          INTO l_patient, l_episode, l_nic_intervention
          FROM nnn_epis_intervention ei
         WHERE ei.id_nnn_epis_intervention = i_nnn_epis_intervention;
    
        -- A NIC Intervention can be linked to a NIC Activity and/or to a NANDA Diagnosis.  
    
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Checks if there is at least one active NIC Activity that is not yet linked to this NIC Intervention
                -- but it is a valid link according to the NIC classification.
                SELECT 1
                  FROM nnn_epis_activity ea
                 WHERE ea.id_patient = l_patient
                   AND ea.id_episode = l_episode
                   AND ea.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_int_actv lnkia
                         WHERE lnkia.id_nnn_epis_intervention = i_nnn_epis_intervention
                           AND lnkia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                           AND lnkia.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nic_cfg.is_linkable_interv_activity(i_prof             => i_prof,
                                                              i_nic_intervention => l_nic_intervention,
                                                              i_nic_activity     => ea.id_nic_activity) =
                       pk_alert_constant.g_yes)
            OR EXISTS
         (
                -- Checks if there is at least one active NANDA Diangosis that is not yet linked to this NIC Intervention
                -- but it is a valid link according to the NIC/NANDA and/or NNN Linkages classification.
                SELECT 1
                  FROM nnn_epis_diagnosis ed
                 WHERE ed.id_patient = l_patient
                   AND ed.id_episode = l_episode
                   AND ed.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_dg_intrv lnkdi
                         WHERE lnkdi.id_nnn_epis_intervention = i_nnn_epis_intervention
                           AND lnkdi.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                           AND lnkdi.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nan_cfg.is_linkable_diagnosis_interv(i_prof             => i_prof,
                                                               i_nan_diagnosis    => ed.id_nan_diagnosis,
                                                               i_nic_intervention => l_nic_intervention) =
                       pk_alert_constant.g_yes);
    
        RETURN(l_exists > 0);
    END exist_potential_links;

    /**
    * Evaluates in the patient care plan if there exist NIC Interventions that can be linked to a Careplan's NIC Activity
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
    *
    * @return   True if there exist potential items to establish a linkage with the Careplan's NIC Activity passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    1/2/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE
    ) RETURN BOOLEAN IS
        l_patient      patient.id_patient%TYPE;
        l_episode      episode.id_episode%TYPE;
        l_nic_activity nic_activity.id_nic_activity%TYPE;
        l_exists       PLS_INTEGER;
    BEGIN
    
        SELECT ea.id_patient, ea.id_episode, ea.id_nic_activity
          INTO l_patient, l_episode, l_nic_activity
          FROM nnn_epis_activity ea
         WHERE ea.id_nnn_epis_activity = i_nnn_epis_activity;
    
        -- A NIC Activity can be linked to a NIC Intervention
    
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Checks if there is at least one active NIC Intervention that is not yet linked to this NIC Activity
                -- but it is a valid link according to the NIC classification.
                SELECT 1
                  FROM nnn_epis_intervention ei
                 WHERE ei.id_patient = l_patient
                   AND ei.id_episode = l_episode
                   AND ei.flg_req_status NOT IN (pk_nnn_constant.g_req_status_cancelled,
                                                 pk_nnn_constant.g_req_status_expired,
                                                 pk_nnn_constant.g_req_status_finished)
                   AND NOT EXISTS (SELECT 1
                          FROM nnn_epis_lnk_int_actv lnkia
                         WHERE lnkia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                           AND lnkia.id_nnn_epis_activity = i_nnn_epis_activity
                           AND lnkia.flg_lnk_status = pk_alert_constant.g_active)
                   AND pk_nic_cfg.is_linkable_interv_activity(i_prof             => i_prof,
                                                              i_nic_intervention => ei.id_nic_intervention,
                                                              i_nic_activity     => l_nic_activity) =
                       pk_alert_constant.g_yes);
        RETURN(l_exists > 0);
    END exist_potential_links;

    /**
    * Evaluates in the staging area if there exist NOC Outcomes / NIC Interventions that can be linked to a NANDA Diagnosis
    *
    * @param    i_lang                    Professional preferred language
    * @param    i_rec_diagnosis           Staging's NANDA Diagnosis 
    * @param    i_map_outcomes            Collection of NOC outcomes added to the staging area
    * @param    i_map_interventions       Collection of NIC interventions added to the staging area
    *
    * @return   True if there exist potential items to establish a linkage with the Staging's NANDA Diagnosis passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/13/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof              IN profissional,
        i_rec_diagnosis     IN pk_nnn_type.t_nnn_ux_epis_diagnosis_rec,
        i_map_outcomes      IN pk_nnn_type.t_map_epis_outcome,
        i_map_interventions IN pk_nnn_type.t_map_epis_intervention
    ) RETURN BOOLEAN IS
        l_exists  BOOLEAN := FALSE;
        l_map_key pk_nnn_type.t_map_key;
    BEGIN
        -- A NANDA Diagnosis can be linked to a NOC Outcome and/or to a NIC Intervention
    
        -- Checks if there is at least one active NOC Outcome that is not yet linked to this NANDA Diagnosis
        -- but it is a valid link according to the NOC/NANDA and/or NNN Linkages classification.
        l_map_key := i_map_outcomes.first;
        WHILE l_map_key IS NOT NULL
        LOOP
            IF l_map_key NOT MEMBER OF i_rec_diagnosis.linked_outcomes
            THEN
                IF pk_nan_cfg.is_linkable_diagnosis_outcome(i_prof          => i_prof,
                                                            i_nan_diagnosis => i_rec_diagnosis.id_nan_diagnosis,
                                                            i_noc_outcome   => i_map_outcomes(l_map_key).id_noc_outcome) =
                   pk_alert_constant.g_yes
                THEN
                    l_exists := TRUE;
                    EXIT;
                END IF;
            END IF;
            l_map_key := i_map_outcomes.next(l_map_key);
        END LOOP;
    
        IF NOT l_exists
        THEN
            -- Checks if there is at least one active NIC Intervention that is not yet linked to this NANDA Diagnosis
            -- but it is a valid link according to the NIC/NANDA and/or NNN Linkages classification.
            l_map_key := i_map_interventions.first;
            WHILE l_map_key IS NOT NULL
            LOOP
                IF l_map_key NOT MEMBER OF i_rec_diagnosis.linked_interventions
                THEN
                    IF pk_nan_cfg.is_linkable_diagnosis_interv(i_prof             => i_prof,
                                                               i_nan_diagnosis    => i_rec_diagnosis.id_nan_diagnosis,
                                                               i_nic_intervention => i_map_interventions(l_map_key).id_nic_intervention) =
                       pk_alert_constant.g_yes
                    THEN
                        l_exists := TRUE;
                        EXIT;
                    END IF;
                END IF;
                l_map_key := i_map_interventions.next(l_map_key);
            END LOOP;
        END IF;
    
        RETURN l_exists;
    END exist_potential_links;

    /**
    * Evaluates in the staging area if there exist NOC Indicator / NANDA Diagnosis that can be linked to a NOC Outcome
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_rec_outcome           Staging's NOC Outcome
    * @param    i_map_indicators        Collection of NOC indicators added to the staging area
    * @param    i_map_diagnoses         Collection of NANDA diagnoses added to the staging area
    *
    * @return   True if there exist potential items to establish a linkage with the Staging's NOC Outcome passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/14/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof           IN profissional,
        i_rec_outcome    IN pk_nnn_type.t_nnn_ux_epis_outcome_rec,
        i_map_indicators IN pk_nnn_type.t_map_epis_indicator,
        i_map_diagnoses  IN pk_nnn_type.t_map_epis_diagnosis
    ) RETURN BOOLEAN IS
        l_exists  BOOLEAN := FALSE;
        l_map_key pk_nnn_type.t_map_key;
    BEGIN
        -- A NOC Outcome can be linked to a NOC Indicator and/or to a NANDA Diagnosis.
    
        -- Checks if there is at least one active NOC Indicator that is not yet linked to this NOC outcome
        -- but it is a valid link according to the NOC classification.
        l_map_key := i_map_indicators.first;
        WHILE l_map_key IS NOT NULL
        LOOP
            IF l_map_key NOT MEMBER OF i_rec_outcome.linked_indicators
            THEN
                IF pk_noc_cfg.is_linkable_outcome_indicator(i_prof          => i_prof,
                                                            i_noc_outcome   => i_rec_outcome.id_noc_outcome,
                                                            i_noc_indicator => i_map_indicators(l_map_key).id_noc_indicator) =
                   pk_alert_constant.g_yes
                THEN
                    l_exists := TRUE;
                    EXIT;
                END IF;
            END IF;
            l_map_key := i_map_indicators.next(l_map_key);
        END LOOP;
    
        IF NOT l_exists
        THEN
            -- Checks if there is at least one active NANDA Diangosis that is not yet linked to this NOC outcome
            -- but it is a valid link according to the NOC/NANDA and/or NNN Linkages classification.
            l_map_key := i_map_diagnoses.first;
            WHILE l_map_key IS NOT NULL
            LOOP
                IF l_map_key NOT MEMBER OF i_rec_outcome.linked_diagnoses
                THEN
                    IF pk_nan_cfg.is_linkable_diagnosis_outcome(i_prof          => i_prof,
                                                                i_nan_diagnosis => i_map_diagnoses(l_map_key).id_nan_diagnosis,
                                                                i_noc_outcome   => i_rec_outcome.id_noc_outcome) =
                       pk_alert_constant.g_yes
                    THEN
                        l_exists := TRUE;
                        EXIT;
                    END IF;
                END IF;
            
                l_map_key := i_map_diagnoses.next(l_map_key);
            END LOOP;
        END IF;
    
        RETURN l_exists;
    END exist_potential_links;

    /**
    * Evaluates in the staging area if there exist NOC Outcomes that can be linked to a NOC Indicator
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_rec_indicator         Staging's NOC Indicator
    * @param    i_map_outcomes          Collection of NOC outcomes added to the staging area
    *
    * @return   True if there exist potential items to establish a linkage with the Staging's NOC Indicator passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/14/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof          IN profissional,
        i_rec_indicator IN pk_nnn_type.t_nnn_ux_epis_indicator_rec,
        i_map_outcomes  IN pk_nnn_type.t_map_epis_outcome
    ) RETURN BOOLEAN IS
        l_exists  BOOLEAN := FALSE;
        l_map_key pk_nnn_type.t_map_key;
    BEGIN
        -- A NOC Indicator can be linked to a NOC Outcome
    
        -- Checks if there is at least one active NOC Outcome that is not yet linked to this NOC Indicator
        -- but it is a valid link according to the NOC classification.        
        l_map_key := i_map_outcomes.first;
        WHILE l_map_key IS NOT NULL
        LOOP
            IF l_map_key NOT MEMBER OF i_rec_indicator.linked_outcomes
            THEN
                IF pk_noc_cfg.is_linkable_outcome_indicator(i_prof          => i_prof,
                                                            i_noc_outcome   => i_map_outcomes(l_map_key).id_noc_outcome,
                                                            i_noc_indicator => i_rec_indicator.id_noc_indicator) =
                   pk_alert_constant.g_yes
                THEN
                    l_exists := TRUE;
                    EXIT;
                END IF;
            END IF;
            l_map_key := i_map_outcomes.next(l_map_key);
        END LOOP;
    
        RETURN l_exists;
    END exist_potential_links;

    /**
    * Evaluates in the staging area if there exist NIC Activities / NANDA Diagnoses that can be linked to a NIC Intervention
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_rec_intervention     Staging's NIC Intervention
    * @param    i_map_activities       Collection of NIC activities added to the staging area
    * @param    i_map_diagnoses        Collection of NANDA diagnoses added to the staging area
    *
    * @return   True if there exist potential items to establish a linkage with the Staging's NIC Intervention passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/14/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof             IN profissional,
        i_rec_intervention IN pk_nnn_type.t_nnn_ux_epis_intervention_rec,
        i_map_activities   IN pk_nnn_type.t_map_epis_activity,
        i_map_diagnoses    IN pk_nnn_type.t_map_epis_diagnosis
    ) RETURN BOOLEAN IS
        l_exists  BOOLEAN := FALSE;
        l_map_key pk_nnn_type.t_map_key;
    BEGIN
        -- A NIC Intervention can be linked to a NIC Activity and/or to a NANDA Diagnosis.  
    
        -- Checks if there is at least one active NIC Activity that is not yet linked to this NIC Intervention
        -- but it is a valid link according to the NIC classification.
        l_map_key := i_map_activities.first;
        WHILE l_map_key IS NOT NULL
        LOOP
            IF l_map_key NOT MEMBER OF i_rec_intervention.linked_activities
            THEN
                IF pk_nic_cfg.is_linkable_interv_activity(i_prof             => i_prof,
                                                          i_nic_intervention => i_rec_intervention.id_nic_intervention,
                                                          i_nic_activity     => i_map_activities(l_map_key).id_nic_activity) =
                   pk_alert_constant.g_yes
                THEN
                    l_exists := TRUE;
                    EXIT;
                END IF;
            
            END IF;
            l_map_key := i_map_activities.next(l_map_key);
        END LOOP;
    
        IF NOT l_exists
        THEN
            -- Checks if there is at least one active NANDA Diangosis that is not yet linked to this NIC Intervention
            -- but it is a valid link according to the NIC/NANDA and/or NNN Linkages classification.                 
            l_map_key := i_map_diagnoses.first;
            WHILE l_map_key IS NOT NULL
            LOOP
                IF l_map_key NOT MEMBER OF i_rec_intervention.linked_diagnoses
                THEN
                    IF pk_nan_cfg.is_linkable_diagnosis_interv(i_prof             => i_prof,
                                                               i_nan_diagnosis    => i_map_diagnoses(l_map_key).id_nan_diagnosis,
                                                               i_nic_intervention => i_rec_intervention.id_nic_intervention) =
                       pk_alert_constant.g_yes
                    THEN
                        l_exists := TRUE;
                        EXIT;
                    END IF;
                END IF;
                l_map_key := i_map_diagnoses.next(l_map_key);
            END LOOP;
        END IF;
    
        RETURN l_exists;
    END exist_potential_links;

    /**
    * Evaluates in the staging area if there exist NIC Interventions that can be linked to a NIC Activity
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_rec_activity         Staging's NIC Activity
    * @param    i_map_interventions    Collection of NIC interventions added to the staging area
    *
    * @return   True if there exist potential items to establish a linkage with the Staging's NIC Activity passed by parameter
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/14/2014
    */
    FUNCTION exist_potential_links
    (
        i_prof              IN profissional,
        i_rec_activity      IN pk_nnn_type.t_nnn_ux_epis_activity_rec,
        i_map_interventions IN pk_nnn_type.t_map_epis_intervention
    ) RETURN BOOLEAN IS
        l_exists  BOOLEAN := FALSE;
        l_map_key pk_nnn_type.t_map_key;
    BEGIN
        -- A NIC Activity can be linked to a NIC Intervention
    
        -- Checks if there is at least one active NIC Intervention that is not yet linked to this NIC Activity
        -- but it is a valid link according to the NIC classification.
    
        l_map_key := i_map_interventions.first;
        WHILE l_map_key IS NOT NULL
        LOOP
            IF l_map_key NOT MEMBER OF i_rec_activity.linked_interventions
            THEN
                IF pk_nic_cfg.is_linkable_interv_activity(i_prof             => i_prof,
                                                          i_nic_intervention => i_map_interventions(l_map_key).id_nic_intervention,
                                                          i_nic_activity     => i_rec_activity.id_nic_activity) =
                   pk_alert_constant.g_yes
                THEN
                    l_exists := TRUE;
                    EXIT;
                END IF;
            
            END IF;
            l_map_key := i_map_interventions.next(l_map_key);
        END LOOP;
        RETURN l_exists;
    END exist_potential_links;
    FUNCTION get_actions_perm_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN table_varchar,
        i_flg_time          IN nnn_epis_activity.flg_time%TYPE,
        i_enable_links      IN BOOLEAN,
        i_diag_status_ltest IN nnn_epis_diag_eval.flg_status%TYPE
    ) RETURN t_coll_action_cipe IS
    
        l_actions          t_coll_action_cipe;
        l_profile          action_permission.id_profile_template%TYPE;
        l_category         action_permission.id_category%TYPE;
        l_states           table_varchar := table_varchar();
        l_rec_count        PLS_INTEGER;
        l_flg_enable_links VARCHAR2(1 CHAR);
    
    BEGIN
        l_flg_enable_links := pk_utils.bool_to_flag(i_enable_links);
    
        l_profile  := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF i_from_state IS NOT NULL
           AND i_from_state.count > 0
        THEN
            l_states := i_from_state;
        END IF;
    
        l_rec_count := l_states.count;
    
        SELECT t_rec_action_cipe(MIN(a.id_action),
                                  a.desc_action,
                                  i_subject,
                                  a.to_state,
                                  a.icon,
                                  CASE
                                      WHEN l_rec_count > 1
                                           AND i_subject = g_act_subj_diagnosis
                                           AND a.internal_name IN (pk_nnn_constant.g_action_diagnosis_edit,
                                                                   pk_nnn_constant.g_action_diagnosis_evaluate,
                                                                   pk_nnn_constant.g_action_diagnosis_link,
                                                                   pk_nnn_constant.g_action_diagnosis_set_activ,
                                                                   pk_nnn_constant.g_action_diagnosis_set_inactiv,
                                                                   pk_nnn_constant.g_action_diagnosis_set_resolv) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count > 1
                                           AND i_subject = g_act_subj_outcome
                                           AND a.internal_name IN (pk_nnn_constant.g_action_outcome_edit,
                                                                   pk_nnn_constant.g_action_outcome_evaluate,
                                                                   pk_nnn_constant.g_action_outcome_hold,
                                                                   pk_nnn_constant.g_action_outcome_link,
                                                                   pk_nnn_constant.g_action_outcome_resume) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count > 1
                                           AND i_subject = g_act_subj_indicator
                                           AND a.internal_name IN (pk_nnn_constant.g_action_indicator_edit,
                                                                   pk_nnn_constant.g_action_indicator_evaluate,
                                                                   pk_nnn_constant.g_action_indicator_hold,
                                                                   pk_nnn_constant.g_action_indicator_link,
                                                                   pk_nnn_constant.g_action_indicator_resume) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count > 1
                                           AND i_subject = g_act_subj_intervention
                                           AND a.internal_name IN (pk_nnn_constant.g_action_intervention_hold,
                                                                   pk_nnn_constant.g_action_intervention_link,
                                                                   pk_nnn_constant.g_action_intervention_resume) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_rec_count > 1
                                           AND i_subject = g_act_subj_activity
                                           AND a.internal_name IN (pk_nnn_constant.g_action_activity_edit,
                                                                   pk_nnn_constant.g_action_activity_hold,
                                                                   pk_nnn_constant.g_action_activity_link,
                                                                   pk_nnn_constant.g_action_activity_resume) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN l_flg_enable_links = pk_alert_constant.g_no
                                           AND a.internal_name IN (pk_nnn_constant.g_action_diagnosis_link,
                                                                   pk_nnn_constant.g_action_outcome_link,
                                                                   pk_nnn_constant.g_action_indicator_link,
                                                                   pk_nnn_constant.g_action_intervention_link,
                                                                   pk_nnn_constant.g_action_activity_link) THEN
                                       pk_alert_constant.g_inactive
                                  
                                      WHEN i_flg_time = pk_nnn_constant.g_time_performed_next_epis
                                           AND a.internal_name IN (pk_nnn_constant.g_action_activity_execute,
                                                                   pk_nnn_constant.g_action_indicator_evaluate,
                                                                   pk_nnn_constant.g_action_outcome_evaluate) THEN
                                       pk_alert_constant.g_inactive
                                      WHEN i_diag_status_ltest = pk_nnn_constant.g_diagnosis_status_active
                                           AND a.internal_name = pk_nnn_constant.g_action_diagnosis_set_activ THEN
                                       pk_alert_constant.g_inactive
                                      WHEN i_diag_status_ltest = pk_nnn_constant.g_diagnosis_status_inactive
                                           AND a.internal_name = pk_nnn_constant.g_action_diagnosis_set_inactiv THEN
                                       pk_alert_constant.g_inactive
                                      WHEN i_diag_status_ltest = pk_nnn_constant.g_diagnosis_status_resolved
                                           AND a.internal_name = pk_nnn_constant.g_action_diagnosis_set_resolv THEN
                                       pk_alert_constant.g_inactive
                                      ELSE
                                       decode(instr(concatenate(a.flg_status), pk_alert_constant.g_inactive),
                                              0,
                                              pk_alert_constant.g_active,
                                              pk_alert_constant.g_inactive)
                                  END,
                                  a.rank,
                                  a.flg_default,
                                  a.id_parent,
                                  a.internal_name,
                                  a.action_level)
          BULK COLLECT
          INTO l_actions
          FROM (SELECT a.id_action,
                       a.id_parent,
                       LEVEL action_level,
                       a.from_state,
                       a.to_state,
                       pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                       a.icon,
                       decode(a.flg_default, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                       a.flg_status,
                       a.rank,
                       a.internal_name,
                       a.subject
                  FROM (SELECT a.id_action,
                               a.code_action,
                               a.subject,
                               a.from_state,
                               a.to_state,
                               a.icon,
                               a.flg_status,
                               a.rank,
                               a.flg_default,
                               a.id_parent,
                               a.internal_name
                          FROM action a
                         WHERE a.subject = i_subject) a
                 WHERE (a.from_state IS NULL OR
                       a.from_state IN ((SELECT /*+opt_estimate(table t rows=1)*/
                                          t.column_value from_state
                                           FROM TABLE(l_states) t)))
                   AND EXISTS (SELECT 1
                          FROM action_permission ap
                         WHERE ap.id_action = a.id_action
                           AND ap.id_category = l_category
                           AND ap.id_profile_template IN (0, l_profile)
                           AND ap.id_institution IN (0, i_prof.institution)
                           AND ap.id_software IN (0, i_prof.software)
                           AND ap.flg_available = pk_alert_constant.g_yes)
                CONNECT BY PRIOR a.id_action = a.id_parent) a
         GROUP BY a.id_parent,
                  a.action_level,
                  a.to_state,
                  a.desc_action,
                  a.icon,
                  a.flg_default,
                  a.internal_name,
                  a.rank;
    
        RETURN l_actions;
    END get_actions_perm_int;

    PROCEDURE get_actions_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_lst_from_state IN table_varchar,
        i_lst_entries    IN table_number,
        o_actions        OUT pk_types.cursor_type
    ) IS
        l_actions             t_coll_action_cipe;
        l_entry_flg_time      nnn_epis_activity.flg_time%TYPE;
        l_has_potential_links BOOLEAN;
        l_diag_status_ltest   nnn_epis_diag_eval.flg_status%TYPE;
    
        CURSOR c_last_epis_diagnosis_eval IS
            SELECT t.flg_status
              FROM TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => i_lst_entries(i_lst_entries.first))) t;
    
        CURSOR c_epis_outcome IS
            SELECT eo.flg_time
              FROM nnn_epis_outcome eo
             WHERE eo.id_nnn_epis_outcome = i_lst_entries(i_lst_entries.first);
    
        CURSOR c_epis_indicator IS
            SELECT ei.flg_time
              FROM nnn_epis_indicator ei
             WHERE ei.id_nnn_epis_indicator = i_lst_entries(i_lst_entries.first);
    
        CURSOR c_epis_activity IS
            SELECT ea.flg_time
              FROM nnn_epis_activity ea
             WHERE ea.id_nnn_epis_activity = i_lst_entries(i_lst_entries.first);
    BEGIN
        l_entry_flg_time      := NULL;
        l_has_potential_links := FALSE;
    
        IF i_lst_entries.count = 1
        THEN
        
            CASE i_subject
                WHEN g_act_subj_diagnosis THEN
                    l_has_potential_links := exist_potential_links(i_prof               => i_prof,
                                                                   i_nnn_epis_diagnosis => i_lst_entries(i_lst_entries.first));
                    OPEN c_last_epis_diagnosis_eval;
                    FETCH c_last_epis_diagnosis_eval
                        INTO l_diag_status_ltest;
                    CLOSE c_last_epis_diagnosis_eval;
                
                WHEN g_act_subj_outcome THEN
                    l_has_potential_links := exist_potential_links(i_prof             => i_prof,
                                                                   i_nnn_epis_outcome => i_lst_entries(i_lst_entries.first));
                    OPEN c_epis_outcome;
                    FETCH c_epis_outcome
                        INTO l_entry_flg_time;
                    CLOSE c_epis_outcome;
                
                WHEN g_act_subj_indicator THEN
                    l_has_potential_links := exist_potential_links(i_prof               => i_prof,
                                                                   i_nnn_epis_indicator => i_lst_entries(i_lst_entries.first));
                
                    OPEN c_epis_indicator;
                    FETCH c_epis_indicator
                        INTO l_entry_flg_time;
                    CLOSE c_epis_indicator;
                
                WHEN g_act_subj_intervention THEN
                    l_has_potential_links := exist_potential_links(i_prof                  => i_prof,
                                                                   i_nnn_epis_intervention => i_lst_entries(i_lst_entries.first));
                WHEN g_act_subj_activity THEN
                    l_has_potential_links := exist_potential_links(i_prof              => i_prof,
                                                                   i_nnn_epis_activity => i_lst_entries(i_lst_entries.first));
                    OPEN c_epis_activity;
                    FETCH c_epis_activity
                        INTO l_entry_flg_time;
                    CLOSE c_epis_activity;
                ELSE
                    l_has_potential_links := FALSE;
            END CASE;
        END IF;
    
        l_actions := get_actions_perm_int(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_subject           => i_subject,
                                          i_from_state        => i_lst_from_state,
                                          i_flg_time          => l_entry_flg_time,
                                          i_enable_links      => l_has_potential_links,
                                          i_diag_status_ltest => l_diag_status_ltest);
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.action_level  "LEVEL",
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   a.flg_active,
                   a.internal_name action
              FROM TABLE(l_actions) a
             ORDER BY a.action_level, a.rank, a.desc_action;
    END get_actions_permissions;

    PROCEDURE get_actions_staging_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN action.subject%TYPE,
        i_staging_data IN CLOB,
        o_actions      OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_actions_staging_area';
    
        -- Menu item to Link a NANDA Diagnosis within the staging area
        g_action_diagnosis_stg_link CONSTANT action.internal_name%TYPE := 'DIAG_STAGING_LINK';
        -- Menu item to Link a NOC Outcome within the staging area            
        g_action_outcome_stg_link CONSTANT action.internal_name%TYPE := 'OUTCOME_STAGING_LINK';
        -- Menu item to Link a NOC Indicator within the staging area
        g_action_indicator_stg_link CONSTANT action.internal_name%TYPE := 'INDICATOR_STAGING_LINK';
        -- Menu item to Link a NIC Intervention within the staging area
        g_action_intervention_stg_link CONSTANT action.internal_name%TYPE := 'INTERVENTION_STAGING_LINK';
        -- Menu item to Link a NIC Activity within the staging area
        g_action_activity_stg_link CONSTANT action.internal_name%TYPE := 'ACTIVITY_STAGING_LINK';
    
        l_coll_actions     t_coll_action;
        l_flg_enable_links VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_json_document    json_object_t;
    
        l_rec_diagnosis    pk_nnn_type.t_nnn_ux_epis_diagnosis_rec;
        l_rec_outcome      pk_nnn_type.t_nnn_ux_epis_outcome_rec;
        l_rec_indicator    pk_nnn_type.t_nnn_ux_epis_indicator_rec;
        l_rec_intervention pk_nnn_type.t_nnn_ux_epis_intervention_rec;
        l_rec_activity     pk_nnn_type.t_nnn_ux_epis_activity_rec;
    
        l_map_diagnoses     pk_nnn_type.t_map_epis_diagnosis;
        l_map_outcomes      pk_nnn_type.t_map_epis_outcome;
        l_map_indicators    pk_nnn_type.t_map_epis_indicator;
        l_map_interventions pk_nnn_type.t_map_epis_intervention;
        l_map_activities    pk_nnn_type.t_map_epis_activity;
    
        l_has_potential_links BOOLEAN;
        l_jsn_value           json_element_t;
        l_jsn_selected_item   json_object_t;
    
        PROCEDURE load_map_diagnoses IS
        BEGIN
            g_error := 'Extract and deserialize from JSON object the nested collection of NANDA diagnoses';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_map_diagnoses := pk_nnn_type.get_map_ux_epis_diagnosis(i_lang => i_lang,
                                                                     i_prof => i_prof,
                                                                     i_json => l_json_document);
        
            g_error := '# of NANDA diagnoses: ' || l_map_diagnoses.count();
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        END load_map_diagnoses;
    
        PROCEDURE load_map_outcomes IS
        BEGIN
            g_error := 'Extract and deserialize from JSON object the nested collection of NOC outcomes';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_map_outcomes := pk_nnn_type.get_map_ux_epis_outcome(i_lang => i_lang,
                                                                  i_prof => i_prof,
                                                                  i_json => l_json_document);
        
            g_error := '# of NOC outcomes: ' || l_map_outcomes.count();
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        END load_map_outcomes;
    
        PROCEDURE load_map_indicators IS
        BEGIN
            g_error := 'Extract and deserialize from JSON object the nested collection of NOC indicators';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_map_indicators := pk_nnn_type.get_map_ux_epis_indicator(i_lang => i_lang,
                                                                      i_prof => i_prof,
                                                                      i_json => l_json_document);
        
            g_error := '# of NOC indicators: ' || l_map_indicators.count();
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        END load_map_indicators;
    
        PROCEDURE load_map_interventions IS
        BEGIN
            g_error := 'Extract and deserialize from JSON object the nested collection of NIC interventions';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_map_interventions := pk_nnn_type.get_map_ux_epis_intervention(i_lang => i_lang,
                                                                            i_prof => i_prof,
                                                                            i_json => l_json_document);
        
            g_error := '# of NIC interventions: ' || l_map_interventions.count();
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        END load_map_interventions;
    
        PROCEDURE load_map_activities IS
        BEGIN
            g_error := 'Extract and deserialize from JSON object the nested collection of NIC activities';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_map_activities := pk_nnn_type.get_map_ux_epis_activity(i_lang => i_lang,
                                                                     i_prof => i_prof,
                                                                     i_json => l_json_document);
        
            g_error := '# of NIC activities: ' || l_map_activities.count();
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        END load_map_activities;
    
    BEGIN
        /*g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_subject = ' || coalesce(i_subject, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        
        l_has_potential_links := FALSE;
        
        g_error := 'Create a JSON object with the staging area info passed in i_staging_data parameter';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_json_document := json(i_staging_data);
        
        g_error := 'Extract and deserialize from JSON object the selected item';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_jsn_value := json_ext.get_json_value(l_json_document, 'SELECTED_ITEM');
        IF l_jsn_value IS NULL
        THEN
            pk_alertlog.log_warn(text            => 'No pair-name "SELECTED_ITEM" found in JSON object ',
                                 object_name     => g_package,
                                 sub_object_name => k_function_name);
        
        ELSE
            l_jsn_selected_item := json(l_jsn_value);
        
            
            \* To decrease the overhead of deserializing collections from staging area that may be unnecessary,
               nested subprograms were created (procedures load_map_{...}) to load these items on-demand on the local vars and 
               according with the kind of selected item.
            *\
        
            CASE i_subject
                WHEN g_act_subj_diagnosis_sa THEN
                    -- Deserialize the JSON object that represents the selected item in the staging area into a NANDA Diagnosis-type record
                    l_rec_diagnosis := pk_nnn_type.get_nnn_ux_epis_diagnosis(i_lang => i_lang,
                                                                             i_prof => i_prof,
                                                                             i_json => l_jsn_selected_item);
                
                    --A NANDA Diagnosis can be linked to a NOC Outcome and/or to a NIC Intervention                                                                         
                    load_map_outcomes;
                    load_map_interventions;
                
                    -- Evaluate if the selected diagnosis has potential links with existing items in the staging area
                    l_has_potential_links := exist_potential_links(i_prof              => i_prof,
                                                                   i_rec_diagnosis     => l_rec_diagnosis,
                                                                   i_map_outcomes      => l_map_outcomes,
                                                                   i_map_interventions => l_map_interventions);
                
                WHEN g_act_subj_outcome_sa THEN
                    -- Deserialize the JSON object that represents the selected item in the staging area into a NOC Outcome-type record
                    l_rec_outcome := pk_nnn_type.get_nnn_ux_epis_outcome(i_lang => i_lang,
                                                                         i_prof => i_prof,
                                                                         i_json => l_jsn_selected_item);
                
                    -- A NOC Outcome can be linked to a NOC Indicator and/or to a NANDA Diagnosis
                    load_map_indicators;
                    load_map_diagnoses;
                
                    -- Evaluate if the selected Outcome has potential links with existing items in the staging area
                    l_has_potential_links := exist_potential_links(i_prof           => i_prof,
                                                                   i_rec_outcome    => l_rec_outcome,
                                                                   i_map_indicators => l_map_indicators,
                                                                   i_map_diagnoses  => l_map_diagnoses);
                
                WHEN g_act_subj_indicator_sa THEN
                    -- Deserialize the JSON object that represents the selected item in the staging area into a NOC Indicator-type record
                    l_rec_indicator := pk_nnn_type.get_nnn_ux_epis_indicator(i_lang => i_lang,
                                                                             i_prof => i_prof,
                                                                             i_json => l_jsn_selected_item);
                
                    -- A NOC Indicator can be linked to a NOC Outcome                                                                         
                    load_map_outcomes;
                
                    -- Evaluate if the selected Indicator has potential links with existing items in the staging area                
                    l_has_potential_links := exist_potential_links(i_prof          => i_prof,
                                                                   i_rec_indicator => l_rec_indicator,
                                                                   i_map_outcomes  => l_map_outcomes);
                
                WHEN g_act_subj_intervention_sa THEN
                    -- Deserialize the JSON object that represents the selected item in the staging area into a NIC Intervention-type record
                    l_rec_intervention := pk_nnn_type.get_nnn_ux_epis_intervention(i_lang => i_lang,
                                                                                   i_prof => i_prof,
                                                                                   i_json => l_jsn_selected_item);
                
                    -- A NIC Intervention can be linked to a NIC Activity and/or to a NANDA Diagnosis
                    load_map_activities;
                    load_map_diagnoses;
                
                    -- Evaluate if the selected Intervention has potential links with existing items in the staging area                              
                    l_has_potential_links := exist_potential_links(i_prof             => i_prof,
                                                                   i_rec_intervention => l_rec_intervention,
                                                                   i_map_activities   => l_map_activities,
                                                                   i_map_diagnoses    => l_map_diagnoses);
                WHEN g_act_subj_activity_sa THEN
                    -- Deserialize the JSON object that represents the selected item in the staging area into a NIC Activity-type record
                    l_rec_activity := pk_nnn_type.get_nnn_ux_epis_activity(i_lang => i_lang,
                                                                           i_prof => i_prof,
                                                                           i_json => l_jsn_selected_item);
                
                    -- A NIC Activity can be linked to a NIC Intervention            
                    load_map_interventions;
                
                    -- Evaluate if the selected Activity has potential links with existing items in the staging area                              
                    l_has_potential_links := exist_potential_links(i_prof              => i_prof,
                                                                   i_rec_activity      => l_rec_activity,
                                                                   i_map_interventions => l_map_interventions);
            END CASE;
        END IF;
        
        -- Get the actions for the item. 
        -- By convention, the status of an item in the staging area can be "Ordered" / "Draft" and both status have the same actions.
        l_coll_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_subject    => i_subject,
                                                   i_from_state => pk_nnn_constant.g_req_status_ordered);
        
        l_flg_enable_links := pk_utils.bool_to_flag(l_has_potential_links);
        */
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr AS "LEVEL",
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   CASE
                        WHEN a.action IN (g_action_diagnosis_stg_link,
                                          g_action_outcome_stg_link,
                                          g_action_indicator_stg_link,
                                          g_action_intervention_stg_link,
                                          g_action_activity_stg_link)
                             AND l_flg_enable_links = pk_alert_constant.g_no THEN
                         pk_alert_constant.g_no
                        ELSE
                         a.flg_active
                    END flg_active,
                   a.action
              FROM TABLE(l_coll_actions) a;
    
    END get_actions_staging_area;

    PROCEDURE get_actions_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type
    ) IS
        l_action_cplan CONSTANT action.internal_name%TYPE := 'STANDARD_CAREPLAN_ADD';
        l_count      PLS_INTEGER := 0;
        l_flg_active VARCHAR2(1 CHAR) := pk_alert_constant.g_inactive;
    BEGIN
        -- count available plans for professional 
        -- TODO: Add filters by service 
        SELECT COUNT(*)
          INTO l_count
          FROM sncp_nurse_care_plan sncp
         WHERE sncp.id_institution IN (0, i_prof.institution)
           AND sncp.flg_status = pk_alert_constant.g_active;
    
        -- have standard care plans? toggle flag
        IF l_count > 0
        THEN
            l_flg_active := pk_alert_constant.g_active;
        END IF;
    
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   1 "LEVEL",
                   a.from_state,
                   a.to_state,
                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                   a.icon,
                   decode(a.flg_default, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   decode(a.internal_name, l_action_cplan, l_flg_active, a.flg_status) flg_active,
                   a.internal_name action
              FROM action a
             WHERE a.subject = g_act_subj_careplan_add_btn
             ORDER BY a.rank, desc_action;
    
    END get_actions_add_button;

    FUNCTION check_permissions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN action.subject%TYPE,
        i_status  IN action.from_state%TYPE,
        i_check   IN action.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_return  VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_actions t_coll_action_cipe;
    BEGIN
        l_actions := get_actions_perm_int(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_subject           => i_subject,
                                          i_from_state        => table_varchar(i_status),
                                          i_flg_time          => NULL,
                                          i_enable_links      => FALSE,
                                          i_diag_status_ltest => NULL);
    
        IF l_actions IS NOT NULL
           AND l_actions.count > 0
        THEN
            FOR i IN l_actions.first .. l_actions.last
            LOOP
                -- check if any given action (i_check) is active or not
                IF l_actions(i).internal_name = i_check
                    AND l_actions(i).flg_active = pk_alert_constant.g_active
                THEN
                    l_return := pk_alert_constant.g_yes;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_return;
    END check_permissions;

    PROCEDURE get_nic_filter_dropdown
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_dropdown   OUT pk_types.cursor_type
    ) IS
        k_function_name          CONSTANT pk_types.t_internal_name_byte := 'get_actions_nic_filter';
        k_mcode_filter_diagnoses CONSTANT sys_message.code_message%TYPE := 'NNN_INTERV_NEW_T006'; -- Diagnoses (NANDA/NIC Linkages)
        k_mcode_filter_outcomes  CONSTANT sys_message.code_message%TYPE := 'NNN_INTERV_NEW_T007'; -- Outcomes (NANDA, NOC, and NIC Linkages)        
        l_error              t_error_out;
        l_patient            patient.id_patient%TYPE;
        l_visit              visit.id_visit%TYPE;
        l_episode            episode.id_episode%TYPE;
        l_has_diags_outcomes PLS_INTEGER;
        l_nnn_by_default     VARCHAR2(1 CHAR);
    BEGIN
        /*
        There are two ways for list NIC Interventions when we want to add it to a nursing care plan:
        - Using as input a NANDA Diagnosis, thereby listing the Interventions associated with it (NANDA/NIC Linkages)
        - Using as input a NOC Outcome, in turn, is linked to a NANDA Diagnosis, thereby listing the Interventions associated with this tuple (NANDA/NOC/NIC Linkages) 
        
        This procedure evaluates the nursing care plan has already have Outcomes in order to displays the 2nd option as active.
        */
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        IF l_patient != i_patient
        THEN
            g_error := 'The I_PATIENT / I_SCOPE / I_SCOPE_TYPE don''t match';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        -- Evaluates if exists unresolved diagnoses linked to active outcomes 
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode  
                SELECT COUNT(*)
                  INTO l_has_diags_outcomes
                  FROM nnn_epis_diagnosis ed
                 INNER JOIN nnn_epis_lnk_dg_outc neldo
                    ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                   AND neldo.flg_lnk_status = pk_alert_constant.g_active
                 INNER JOIN nnn_epis_outcome neo
                    ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
                  LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                    ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                 WHERE ed.id_patient = i_patient
                   AND ed.id_episode = l_episode
                   AND ed.flg_req_status IN (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                   AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                   AND neo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                              pk_nnn_constant.g_req_status_ordered,
                                              pk_nnn_constant.g_req_status_ongoing,
                                              pk_nnn_constant.g_req_status_suspended,
                                              pk_nnn_constant.g_req_status_finished);
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit             
                SELECT COUNT(*)
                  INTO l_has_diags_outcomes
                  FROM nnn_epis_diagnosis ed
                 INNER JOIN nnn_epis_lnk_dg_outc neldo
                    ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                   AND neldo.flg_lnk_status = pk_alert_constant.g_active
                 INNER JOIN nnn_epis_outcome neo
                    ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
                  LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                    ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                 WHERE ed.id_patient = i_patient
                   AND ed.id_visit = l_visit
                   AND ed.flg_req_status IN (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                   AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                   AND neo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                              pk_nnn_constant.g_req_status_ordered,
                                              pk_nnn_constant.g_req_status_ongoing,
                                              pk_nnn_constant.g_req_status_suspended,
                                              pk_nnn_constant.g_req_status_finished);
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient   
                SELECT COUNT(*)
                  INTO l_has_diags_outcomes
                  FROM nnn_epis_diagnosis ed
                 INNER JOIN nnn_epis_lnk_dg_outc neldo
                    ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                   AND neldo.flg_lnk_status = pk_alert_constant.g_active
                 INNER JOIN nnn_epis_outcome neo
                    ON neldo.id_nnn_epis_outcome = neo.id_nnn_epis_outcome
                  LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                    ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                 WHERE ed.id_patient = i_patient
                   AND ed.flg_req_status IN (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                   AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                   AND neo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                              pk_nnn_constant.g_req_status_ordered,
                                              pk_nnn_constant.g_req_status_ongoing,
                                              pk_nnn_constant.g_req_status_suspended,
                                              pk_nnn_constant.g_req_status_finished);
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
        -- If the plan of care  already have outcomes, then we prioritize the use of NNN-Linkages to select interventions.
        -- When there is no outcomes we can only use the NIC Linkages to NANDA.
        CASE
            WHEN l_has_diags_outcomes > 0 THEN
                l_nnn_by_default := pk_alert_constant.g_yes;
            ELSE
                l_nnn_by_default := pk_alert_constant.g_no;
        END CASE;
    
        OPEN o_dropdown FOR
            SELECT pk_nnn_constant.g_terminology_nic link_terminology,
                   pk_message.get_message(i_lang, k_mcode_filter_diagnoses) label,
                   CASE l_nnn_by_default
                       WHEN pk_alert_constant.g_yes THEN
                        pk_alert_constant.g_no
                       ELSE
                        pk_alert_constant.g_yes
                   END flg_default,
                   pk_alert_constant.g_active flg_status,
                   20 rank
              FROM dual
            UNION ALL
            SELECT pk_nnn_constant.g_terminology_nnn_linkages link_terminology,
                   pk_message.get_message(i_lang, k_mcode_filter_outcomes) label,
                   l_nnn_by_default flg_default,
                   CASE l_nnn_by_default
                       WHEN pk_alert_constant.g_yes THEN
                        pk_alert_constant.g_active
                       ELSE
                        pk_alert_constant.g_inactive
                   END flg_status,
                   10 rank
              FROM dual
             ORDER BY rank, label;
    
    EXCEPTION
        -- Log an raise the error      
        WHEN pk_nnn_constant.e_invalid_argument THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_invalid_argument', text_in => g_error);
        
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error', text_in => g_error);
    END get_nic_filter_dropdown;

    FUNCTION get_epis_diag_eval_abstract
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_use_html_format    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_diag_eval_abstract';
        k_separator     CONSTANT VARCHAR2(10) := CASE i_use_html_format
                                                     WHEN pk_alert_constant.g_yes THEN
                                                      htf.br() || chr(10)
                                                     ELSE
                                                      chr(10)
                                                 END;
        l_ret           pk_types.t_huge_byte;
        l_output        CLOB;
        l_label         sys_message.desc_message%TYPE;
        l_obj_diag      t_obj_nnn_epis_diagnosis;
        l_obj_diag_eval t_obj_nnn_epis_diag_eval;
        l_lst_strings   table_varchar;
        i               PLS_INTEGER;
    
        FUNCTION format_label_value
        (
            i_label     IN VARCHAR2,
            i_value     IN VARCHAR2,
            i_separator IN VARCHAR DEFAULT k_separator
        ) RETURN VARCHAR2 IS
            l_output pk_types.t_huge_byte;
        BEGIN
            IF i_use_html_format = pk_alert_constant.g_yes
            THEN
                l_output := htf.bold(i_label) || i_separator || htf.escape_sc(i_value);
            ELSE
                l_output := i_label || i_separator || i_value;
            END IF;
            RETURN l_output;
        END format_label_value;
    BEGIN
        IF i_nnn_epis_diag_eval IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'Retrieving information about the NANDA diagnosis evaluation';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_obj_diag_eval := pk_nnn_api_db.get_epis_nan_diagnosis_eval(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_nnn_epis_diag_eval => i_nnn_epis_diag_eval);
    
        g_error := 'Retrieving information about the NANDA diagnosis';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_obj_diag := pk_nnn_api_db.get_epis_nan_diagnosis(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_nnn_epis_diagnosis => l_obj_diag_eval.id_nnn_epis_diagnosis);
    
        g_error := 'Formatting Diagnosis date';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T004'); -- 'Diagnosis date:'
    
        l_ret := format_label_value(i_label => l_label,
                                    i_value => pk_date_utils.date_char_tsz(i_lang,
                                                                           l_obj_diag.dt_diagnosis,
                                                                           i_prof.institution,
                                                                           i_prof.software));
    
        l_output := l_ret;
        g_error  := 'Formatting Status (diagnosis status)';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T007'); -- 'Status:'
    
        l_ret    := format_label_value(i_label => l_label, i_value => l_obj_diag_eval.status.desc_flg_status);
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Evaluation date';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T008'); -- 'Evaluation date:'
    
        l_ret    := format_label_value(i_label => l_label,
                                       i_value => pk_date_utils.date_char_tsz(i_lang,
                                                                              l_obj_diag_eval.dt_evaluation,
                                                                              i_prof.institution,
                                                                              i_prof.software));
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Defining characteristics';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_diag_eval.lst_defining_characteristic IS NOT empty
        THEN
            l_lst_strings := table_varchar();
            l_lst_strings.extend(l_obj_diag_eval.lst_defining_characteristic.count);
        
            i := l_obj_diag_eval.lst_defining_characteristic.first;
            WHILE i IS NOT NULL
            LOOP
                l_lst_strings(i) := l_obj_diag_eval.lst_defining_characteristic(i).description;
                i := l_obj_diag_eval.lst_defining_characteristic.next(i);
            END LOOP;
        
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T009'); -- 'Defining characteristics:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_utils.concat_table_l(i_tab => l_lst_strings, i_delim => '; '));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        --     
        g_error := 'Formatting Related factors';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_diag_eval.lst_related_factor IS NOT empty
        THEN
            l_lst_strings := table_varchar();
            l_lst_strings.extend(l_obj_diag_eval.lst_related_factor.count);
        
            i := l_obj_diag_eval.lst_related_factor.first;
            WHILE i IS NOT NULL
            LOOP
                l_lst_strings(i) := l_obj_diag_eval.lst_related_factor(i).description;
                i := l_obj_diag_eval.lst_related_factor.next(i);
            END LOOP;
        
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T010'); -- 'Related factors:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_utils.concat_table_l(i_tab => l_lst_strings, i_delim => '; '));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        g_error := 'Formatting Risk factors';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_diag_eval.lst_risk_factor IS NOT empty
        THEN
            l_lst_strings := table_varchar();
            l_lst_strings.extend(l_obj_diag_eval.lst_risk_factor.count);
        
            i := l_obj_diag_eval.lst_risk_factor.first;
            WHILE i IS NOT NULL
            LOOP
                l_lst_strings(i) := l_obj_diag_eval.lst_risk_factor(i).description;
                i := l_obj_diag_eval.lst_risk_factor.next(i);
            END LOOP;
        
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T011'); -- 'Risk factors:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_utils.concat_table_l(i_tab => l_lst_strings, i_delim => '; '));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        g_error := 'Formatting Notes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_diag_eval.notes IS NOT NULL
           AND length(l_obj_diag_eval.notes) > 0
        THEN
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T012'); -- 'Notes:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_string_utils.clob_to_plsqlvarchar2(l_obj_diag_eval.notes));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        -- Line feed between the text and signature
        l_output := l_output || k_separator;
    
        g_error := 'Formatting Signature';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := CASE l_obj_diag_eval.has_historical_changes
                       WHEN pk_alert_constant.g_yes THEN
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M127') -- 'Updated:' 
                       ELSE
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M107') -- 'Documented:'
                   END;
    
        l_ret := format_label_value(i_label     => l_label,
                                    i_value     => pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                                      i_prof                => i_prof,
                                                                                      i_id_episode          => l_obj_diag_eval.context_record.id_episode,
                                                                                      i_date_last_change    => l_obj_diag_eval.bitemporal_data.transaction_time.dt_trs_time_start,
                                                                                      i_id_prof_last_change => l_obj_diag_eval.prof_info.id_professional),
                                    i_separator => ' ');
        IF i_use_html_format = pk_alert_constant.g_yes
        THEN
            l_ret := htf.italic(l_ret);
        END IF;
    
        l_output := l_output || k_separator || l_ret;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
    END get_epis_diag_eval_abstract;

    FUNCTION get_epis_outcome_eval_abstract
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_use_html_format       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_outcome_eval_abstract';
        k_separator     CONSTANT VARCHAR2(10) := CASE i_use_html_format
                                                     WHEN pk_alert_constant.g_yes THEN
                                                      htf.br() || chr(10)
                                                     ELSE
                                                      chr(10)
                                                 END;
        l_ret      pk_types.t_huge_byte;
        l_output   CLOB;
        l_label    sys_message.desc_message%TYPE;
        l_obj_eval t_obj_nnn_epis_outcome_eval;
    
        FUNCTION format_label_value
        (
            i_label     IN VARCHAR2,
            i_value     IN VARCHAR2,
            i_separator IN VARCHAR DEFAULT k_separator
        ) RETURN VARCHAR2 IS
            l_output pk_types.t_huge_byte;
        BEGIN
            IF i_use_html_format = pk_alert_constant.g_yes
            THEN
                l_output := htf.bold(i_label) || i_separator || htf.escape_sc(i_value);
            ELSE
                l_output := i_label || i_separator || i_value;
            END IF;
            RETURN l_output;
        END format_label_value;
    BEGIN
        IF i_nnn_epis_outcome_eval IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'Retrieving information about the NOC outcome evaluation';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_obj_eval := pk_nnn_api_db.get_epis_noc_outcome_eval(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_nnn_epis_outcome_eval => i_nnn_epis_outcome_eval);
    
        g_error := 'Expected outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_OUTC_M003'); -- 'Expected outcome:'
    
        l_ret := format_label_value(i_label => l_label,
                                    i_value => pk_string_utils.concat_if_exists(l_obj_eval.target_value.scale_level_value,
                                                                                l_obj_eval.target_value.desc_scale_level_value,
                                                                                ' - '));
    
        l_output := l_ret;
    
        g_error := 'Current evaluation outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_OUTC_M004'); -- 'Evaluation:'
    
        l_ret := format_label_value(i_label => l_label,
                                    i_value => pk_string_utils.concat_if_exists(l_obj_eval.outcome_value.scale_level_value,
                                                                                l_obj_eval.outcome_value.desc_scale_level_value,
                                                                                ' - '));
    
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Evaluation date';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_OUTC_M002'); -- 'Evaluation date:'
    
        l_ret    := format_label_value(i_label => l_label,
                                       i_value => pk_date_utils.date_char_tsz(i_lang,
                                                                              l_obj_eval.dt_evaluation,
                                                                              i_prof.institution,
                                                                              i_prof.software));
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Notes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_eval.notes IS NOT NULL
           AND length(l_obj_eval.notes) > 0
        THEN
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_OUTC_M005'); -- 'Notes:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_string_utils.clob_to_plsqlvarchar2(l_obj_eval.notes));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        IF l_obj_eval.status.flg_status = pk_alert_constant.g_cancelled
        THEN
            g_error := 'Formatting Status ';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T007'); -- 'Status:'
        
            l_ret    := format_label_value(i_label => l_label, i_value => l_obj_eval.status.desc_flg_status);
            l_output := l_output || k_separator || l_ret;
        
        END IF;
    
        -- Line feed between the text and signature
        l_output := l_output || k_separator;
    
        g_error := 'Formatting Signature';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := CASE l_obj_eval.has_historical_changes
                       WHEN pk_alert_constant.g_yes THEN
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M127') -- 'Updated:' 
                       ELSE
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M107') -- 'Documented:'
                   END;
    
        l_ret := format_label_value(i_label     => l_label,
                                    i_value     => pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                                      i_prof                => i_prof,
                                                                                      i_id_episode          => l_obj_eval.context_record.id_episode,
                                                                                      i_date_last_change    => l_obj_eval.bitemporal_data.transaction_time.dt_trs_time_start,
                                                                                      i_id_prof_last_change => l_obj_eval.prof_info.id_professional),
                                    i_separator => ' ');
        IF i_use_html_format = pk_alert_constant.g_yes
        THEN
            l_ret := htf.italic(l_ret);
        END IF;
    
        l_output := l_output || k_separator || l_ret;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
    END get_epis_outcome_eval_abstract;

    FUNCTION get_epis_ind_eval_abstract
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_use_html_format   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_ind_eval_abstract';
        k_separator     CONSTANT VARCHAR2(10) := CASE i_use_html_format
                                                     WHEN pk_alert_constant.g_yes THEN
                                                      htf.br() || chr(10)
                                                     ELSE
                                                      chr(10)
                                                 END;
        l_ret      pk_types.t_huge_byte;
        l_output   CLOB;
        l_label    sys_message.desc_message%TYPE;
        l_obj_eval t_obj_nnn_epis_ind_eval;
    
        FUNCTION format_label_value
        (
            i_label     IN VARCHAR2,
            i_value     IN VARCHAR2,
            i_separator IN VARCHAR DEFAULT k_separator
        ) RETURN VARCHAR2 IS
            l_output pk_types.t_huge_byte;
        BEGIN
            IF i_use_html_format = pk_alert_constant.g_yes
            THEN
                l_output := htf.bold(i_label) || i_separator || htf.escape_sc(i_value);
            ELSE
                l_output := i_label || i_separator || i_value;
            END IF;
            RETURN l_output;
        END format_label_value;
    BEGIN
        IF i_nnn_epis_ind_eval IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'Retrieving information about the NOC indicator evaluation';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_obj_eval := pk_nnn_api_db.get_epis_noc_indicator_eval(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_nnn_epis_outcome  => i_nnn_epis_outcome,
                                                                i_nnn_epis_ind_eval => i_nnn_epis_ind_eval);
    
        g_error := 'Expected outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INDE_M003'); -- 'Expected outcome:'
    
        l_ret := format_label_value(i_label => l_label,
                                    i_value => pk_string_utils.concat_if_exists(l_obj_eval.target_value.scale_level_value,
                                                                                l_obj_eval.target_value.desc_scale_level_value,
                                                                                ' - '));
    
        l_output := l_ret;
    
        g_error := 'Current evaluation outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INDE_M004'); -- 'Evaluation:'
    
        l_ret := format_label_value(i_label => l_label,
                                    i_value => pk_string_utils.concat_if_exists(l_obj_eval.indicator_value.scale_level_value,
                                                                                l_obj_eval.indicator_value.desc_scale_level_value,
                                                                                ' - '));
    
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Evaluation date';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INDE_M002'); -- 'Evaluation date:'
    
        l_ret    := format_label_value(i_label => l_label,
                                       i_value => pk_date_utils.date_char_tsz(i_lang,
                                                                              l_obj_eval.dt_evaluation,
                                                                              i_prof.institution,
                                                                              i_prof.software));
        l_output := l_output || k_separator || l_ret;
    
        g_error := 'Formatting Notes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_eval.notes IS NOT NULL
           AND length(l_obj_eval.notes) > 0
        THEN
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INDE_M005'); -- 'Notes:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_string_utils.clob_to_plsqlvarchar2(l_obj_eval.notes));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        IF l_obj_eval.status.flg_status = pk_alert_constant.g_cancelled
        THEN
            g_error := 'Formatting Status ';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T007'); -- 'Status:'
        
            l_ret    := format_label_value(i_label => l_label, i_value => l_obj_eval.status.desc_flg_status);
            l_output := l_output || k_separator || l_ret;
        
        END IF;
    
        -- Line feed between the text and signature
        l_output := l_output || k_separator;
    
        g_error := 'Formatting Signature';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := CASE l_obj_eval.has_historical_changes
                       WHEN pk_alert_constant.g_yes THEN
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M127') -- 'Updated:' 
                       ELSE
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M107') -- 'Documented:'
                   END;
    
        l_ret := format_label_value(i_label     => l_label,
                                    i_value     => pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                                      i_prof                => i_prof,
                                                                                      i_id_episode          => l_obj_eval.context_record.id_episode,
                                                                                      i_date_last_change    => l_obj_eval.bitemporal_data.transaction_time.dt_trs_time_start,
                                                                                      i_id_prof_last_change => l_obj_eval.prof_info.id_professional),
                                    i_separator => ' ');
        IF i_use_html_format = pk_alert_constant.g_yes
        THEN
            l_ret := htf.italic(l_ret);
        END IF;
    
        l_output := l_output || k_separator || l_ret;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
    END get_epis_ind_eval_abstract;

    FUNCTION get_epis_actv_exec_abstract
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_use_html_format       IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_actv_exec_abstract';
        k_separator     CONSTANT VARCHAR2(10) := CASE i_use_html_format
                                                     WHEN pk_alert_constant.g_yes THEN
                                                      htf.br() || chr(10)
                                                     ELSE
                                                      chr(10)
                                                 END;
        l_ret                   pk_types.t_huge_byte;
        l_output                CLOB;
        l_label                 sys_message.desc_message%TYPE;
        l_obj_eval              t_obj_nnn_epis_activity_det;
        l_obj_nnn_epis_activity t_obj_nnn_epis_activity;
        l_dt_dummy              pk_types.t_timestamp;
        l_num_dummy             pk_types.t_med_num;
    
        FUNCTION format_label_value
        (
            i_label     IN VARCHAR2,
            i_value     IN VARCHAR2,
            i_separator IN VARCHAR DEFAULT k_separator
        ) RETURN VARCHAR2 IS
            l_output pk_types.t_huge_byte;
        BEGIN
            IF i_use_html_format = pk_alert_constant.g_yes
            THEN
                l_output := htf.bold(i_label) || i_separator || htf.escape_sc(i_value);
            ELSE
                l_output := i_label || i_separator || i_value;
            END IF;
            RETURN l_output;
        END format_label_value;
    
    BEGIN
        IF i_nnn_epis_activity_det IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'Retrieving information about the NIC activity execution';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Gets information about an execution of a Careplan's NIC Activity                                                                                       
        l_obj_eval := pk_nnn_api_db.get_epis_nic_activity_det(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_nnn_epis_activity_det => i_nnn_epis_activity_det);
    
        IF l_obj_eval.status.flg_status = pk_nnn_constant.g_task_status_ordered
        THEN
            -- TODO: A planned execution has no abstract. 
            -- May be useful display something like the planned date?
            RETURN NULL;
        END IF;
    
        --Gets information about a Careplan's NIC Activity                                                                                       
        l_obj_nnn_epis_activity := pk_nnn_api_db.get_epis_nic_activity(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_activity => l_obj_eval.id_nnn_epis_activity);
    
        IF l_obj_eval.bitemporal_data.valid_time.dt_val_time_start IS NOT NULL
           AND l_obj_eval.bitemporal_data.valid_time.dt_val_time_end IS NOT NULL
        THEN
            g_error := 'Formatting Start date';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INSTRUCT_T007'); -- 'Start date:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                               i_date => l_obj_eval.bitemporal_data.valid_time.dt_val_time_start,
                                                                               i_inst => i_prof.institution,
                                                                               i_soft => i_prof.software));
        
            l_output := l_output || k_separator || l_ret;
        
            g_error := 'Formatting Duration';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            pk_nnn_core.calculate_duration(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_start_date         => l_obj_eval.bitemporal_data.valid_time.dt_val_time_start,
                                           i_duration           => NULL,
                                           i_unit_meas_duration => NULL,
                                           i_end_date           => l_obj_eval.bitemporal_data.valid_time.dt_val_time_end,
                                           o_start_date         => l_dt_dummy,
                                           o_duration           => l_num_dummy,
                                           o_duration_desc      => l_ret,
                                           o_unit_meas_duration => l_num_dummy,
                                           o_end_date           => l_dt_dummy);
        
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INSTRUCT_T009'); -- 'Duration:'
        
            l_ret := format_label_value(i_label => l_label, i_value => l_ret);
        
            l_output := l_output || k_separator || l_ret;
        
            g_error := 'Formatting End date';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_INSTRUCT_T010'); -- 'End date:'
        
            l_ret    := format_label_value(i_label => l_label,
                                           i_value => pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                  i_date => l_obj_eval.bitemporal_data.valid_time.dt_val_time_end,
                                                                                  i_inst => i_prof.institution,
                                                                                  i_soft => i_prof.software));
            l_output := l_output || k_separator || l_ret;
        
        END IF;
    
        -- Documentation using Vital Signs
        IF l_obj_nnn_epis_activity.flg_doc_type = pk_nic_cfg.g_activity_doctype_vital_sign
           AND l_obj_eval.vital_sign_read_list IS NOT empty
        THEN
            -- Retrieves description of the vital sign associated with this NIC activity 
            -- (flg_doc_type=V then doc_parameter=id_vital_sign)
            l_label := pk_vital_sign.get_vs_desc(i_lang       => i_lang,
                                                 i_vital_sign => l_obj_nnn_epis_activity.doc_parameter,
                                                 i_short_desc => pk_alert_constant.get_no);
        
            -- Retrieves the formatted value for vital sign measurement
            -- Composite vital signs like blood pressure have two or more ID_VITAL_SIGN_READ. This method just need one ID.
            l_ret := pk_touch_option_ti.get_formatted_vsread(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_vsread      => l_obj_eval.vital_sign_read_list(1),
                                                             i_dt_creation => l_obj_eval.bitemporal_data.transaction_time.dt_trs_time_start);
        
            l_ret := format_label_value(i_label => l_label, i_value => l_ret);
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        -- Documentation using Touch-option Template / Free-Text
        l_ret := pk_string_utils.clob_to_plsqlvarchar2(i_clob => pk_touch_option_core.get_plain_text_entry(i_lang               => i_lang,
                                                                                                           i_prof               => i_prof,
                                                                                                           i_epis_documentation => l_obj_eval.id_epis_documentation,
                                                                                                           i_use_html_format    => pk_alert_constant.g_no));
        IF l_ret IS NOT NULL
        THEN
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_ACTV_T012'); --'Documentation'
            l_ret   := format_label_value(i_label => l_label, i_value => l_ret);
        
            l_output := l_output || k_separator || l_ret;
        
        END IF;
    
        g_error := 'Formatting Notes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF l_obj_eval.notes IS NOT NULL
           AND length(l_obj_eval.notes) > 0
        THEN
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_OUTC_M005'); -- 'Notes:'
        
            l_ret := format_label_value(i_label => l_label,
                                        i_value => pk_string_utils.clob_to_plsqlvarchar2(l_obj_eval.notes));
        
            l_output := l_output || k_separator || l_ret;
        END IF;
    
        IF l_obj_eval.status.flg_status = pk_alert_constant.g_cancelled
        THEN
            g_error := 'Formatting Status ';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_label := pk_message.get_message(i_lang, i_prof, 'NNN_DIAG_EDIT_T007'); -- 'Status:'
        
            l_ret    := format_label_value(i_label => l_label, i_value => l_obj_eval.status.desc_flg_status);
            l_output := l_output || k_separator || l_ret;
        
            l_label := pk_message.get_message(i_lang, i_prof, 'DETAIL_COMMON_M006'); -- 'Cancel reason:'
        
            l_ret    := format_label_value(i_label => l_label, i_value => l_obj_eval.cancel_info.cancel_reason_desc);
            l_output := l_output || k_separator || l_ret;
        
            IF l_obj_eval.cancel_info.cancel_notes IS NOT NULL
            THEN
                l_label := pk_message.get_message(i_lang, i_prof, 'DETAIL_COMMON_M007'); -- 'Cancel notes:'
            
                l_ret    := format_label_value(i_label => l_label, i_value => l_obj_eval.cancel_info.cancel_notes);
                l_output := l_output || k_separator || l_ret;
            END IF;
        
        END IF;
    
        -- Line feed between the text and signature
        l_output := l_output || k_separator;
    
        g_error := 'Formatting Signature';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_label := CASE l_obj_eval.has_historical_changes
                       WHEN pk_alert_constant.g_yes THEN
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M127') -- 'Updated:' 
                       ELSE
                        pk_message.get_message(i_lang, i_prof, 'COMMON_M107') -- 'Documented:'
                   END;
    
        l_ret := format_label_value(i_label     => l_label,
                                    i_value     => pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                                      i_prof                => i_prof,
                                                                                      i_id_episode          => l_obj_eval.context_record.id_episode,
                                                                                      i_date_last_change    => l_obj_eval.bitemporal_data.transaction_time.dt_trs_time_start,
                                                                                      i_id_prof_last_change => l_obj_eval.prof_info.id_professional),
                                    i_separator => ' ');
        IF i_use_html_format = pk_alert_constant.g_yes
        THEN
            l_ret := htf.italic(l_ret);
        END IF;
    
        l_output := l_output || k_separator || l_ret;
    
        RETURN l_output;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(NULL,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  k_function_name,
                                                  l_error);
            END;
            RETURN NULL;
    END get_epis_actv_exec_abstract;

    PROCEDURE get_pat_evaluations_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_paging       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_start_column IN NUMBER DEFAULT 1,
        i_num_columns  IN NUMBER DEFAULT 2000,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type
    ) IS
        k_function_name           CONSTANT pk_types.t_internal_name_byte := 'get_pat_evaluations_view';
        k_prefix_key_diagnosis    CONSTANT VARCHAR2(30 CHAR) := g_act_subj_diagnosis || '|';
        k_prefix_key_outcome      CONSTANT VARCHAR2(30 CHAR) := g_act_subj_outcome || '|';
        k_prefix_key_indicator    CONSTANT VARCHAR2(30 CHAR) := g_act_subj_indicator || '|';
        k_prefix_key_intervention CONSTANT VARCHAR2(30 CHAR) := g_act_subj_intervention || '|';
        k_prefix_key_activity     CONSTANT VARCHAR2(30 CHAR) := g_act_subj_activity || '|';
        l_timeline_date_header_format sys_config.value%TYPE;
        l_start_column                pk_types.t_big_num;
        l_end_column                  pk_types.t_big_num;
        l_patient                     patient.id_patient%TYPE;
        l_visit                       visit.id_visit%TYPE;
        l_episode                     episode.id_episode%TYPE;
        l_error                       t_error_out;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(to_char(i_scope_type), '<null>');
        g_error := g_error || ' i_start_column = ' || coalesce(to_char(i_start_column), '<null>');
        g_error := g_error || ' i_num_columns = ' || coalesce(to_char(i_num_columns), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
           OR i_paging IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        pk_alert_exceptions.assert(condition_in => i_patient = l_patient, message_in => 'The i_patient doesn''t match');
    
        l_timeline_date_header_format := pk_sysconfig.get_config(i_code_cf => pk_nnn_constant.g_config_timeline_date_format,
                                                                 i_prof    => i_prof);
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            l_start_column := i_start_column;
            l_end_column   := i_start_column + i_num_columns - 1;
        
            IF l_start_column < 1
            THEN
                -- Minimum inbound 
                l_start_column := 1;
            END IF;
        END IF;
    
        -- !!! WARNING !!!!  For performance reasons the same query is replicated and adjusted according each scope (Episode/Visit/Patient)
        -- !!! WARNING !!!!  So, if you need to add/modify something in the query, please
        -- !!! WARNING !!!!  make sure that this modification is applied/validated also in all of these queries and be consistent with the output
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode  
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    lede.id_nnn_epis_diag_eval last_evaluation_id,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                                 lede.flg_status,
                                                                 i_lang)
                                    END last_evaluation_value,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lede.dt_evaluation, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                            i_use_html_format    => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                                ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                             WHERE ed.id_patient = i_patient
                               AND ed.id_episode = l_episode
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leoe.id_nnn_epis_outcome_eval last_evaluation_id,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leoe.target_value || '|' || coalesce(to_char(leoe.outcome_value), '-')
                                    END last_evaluation_value,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leoe.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                               i_prof                  => i_prof,
                                                                               i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                               i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                                ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                               AND eo.id_episode = l_episode
                               AND eo.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leie.id_nnn_epis_ind_eval last_evaluation_id,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leie.target_value || '|' || coalesce(to_char(leie.indicator_value), '-')
                                    END last_evaluation_value,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leie.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_nnn_epis_outcome  => lnkoi.id_nnn_epis_outcome,
                                                                           i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                                           i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                                ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                               AND ei.id_episode = l_episode
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL last_evaluation_id,
                                    NULL last_evaluation_value,
                                    NULL last_evaluation_date,
                                    NULL last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                               AND ei.id_episode = l_episode
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    lead.id_nnn_epis_activity_det last_evaluation_id,
                                    NULL last_evaluation_value,
                                    CASE lead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lead.dt_val_time_start, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                            i_prof                  => i_prof,
                                                                            i_nnn_epis_activity_det => lead.id_nnn_epis_activity_det,
                                                                            i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                                ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient
                               AND ea.id_episode = l_episode
                               AND ea.flg_req_status != pk_nnn_constant.g_req_status_cancelled) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                       AND ede.id_episode = l_episode
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eoe.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                       AND eoe.id_episode = l_episode
                                       AND eoe.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eie.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                       AND eie.id_episode = l_episode
                                       AND eie.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ead.dt_val_time_start,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient
                                       AND ead.id_episode = l_episode
                                       AND ead.flg_status = pk_nnn_constant.g_task_status_finished) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    lede.id_nnn_epis_diag_eval last_evaluation_id,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                                 lede.flg_status,
                                                                 i_lang)
                                    END last_evaluation_value,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lede.dt_evaluation, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                            i_use_html_format    => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                                ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                             WHERE ed.id_patient = i_patient
                               AND ed.id_visit = l_visit
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leoe.id_nnn_epis_outcome_eval last_evaluation_id,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leoe.target_value || '|' || coalesce(to_char(leoe.outcome_value), '-')
                                    END last_evaluation_value,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leoe.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                               i_prof                  => i_prof,
                                                                               i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                               i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                                ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                               AND eo.id_visit = l_visit
                               AND eo.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leie.id_nnn_epis_ind_eval last_evaluation_id,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leie.target_value || '|' || coalesce(to_char(leie.indicator_value), '-')
                                    END last_evaluation_value,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leie.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_nnn_epis_outcome  => lnkoi.id_nnn_epis_outcome,
                                                                           i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                                           i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                                ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                               AND ei.id_visit = l_visit
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL last_evaluation_id,
                                    NULL last_evaluation_value,
                                    NULL last_evaluation_date,
                                    NULL last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                               AND ei.id_visit = l_visit
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    lead.id_nnn_epis_activity_det last_evaluation_id,
                                    NULL last_evaluation_value,
                                    CASE lead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lead.dt_val_time_start, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                            i_prof                  => i_prof,
                                                                            i_nnn_epis_activity_det => lead.id_nnn_epis_activity_det,
                                                                            i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                                ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient
                               AND ea.id_visit = l_visit
                               AND ea.flg_req_status != pk_nnn_constant.g_req_status_cancelled) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                       AND ede.id_visit = l_visit
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eoe.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                       AND eoe.id_visit = l_visit
                                       AND eoe.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eie.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                       AND eie.id_visit = l_visit
                                       AND eie.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ead.dt_val_time_start,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient
                                       AND ead.id_visit = l_visit
                                       AND ead.flg_status = pk_nnn_constant.g_task_status_finished) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient                
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    lede.id_nnn_epis_diag_eval last_evaluation_id,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                                 lede.flg_status,
                                                                 i_lang)
                                    END last_evaluation_value,
                                    CASE lede.id_nnn_epis_diag_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lede.dt_evaluation, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                            i_use_html_format    => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                                ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                             WHERE ed.id_patient = i_patient
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leoe.id_nnn_epis_outcome_eval last_evaluation_id,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leoe.target_value || '|' || coalesce(to_char(leoe.outcome_value), '-')
                                    END last_evaluation_value,
                                    CASE leoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leoe.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                               i_prof                  => i_prof,
                                                                               i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                               i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                                ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                               AND eo.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    leie.id_nnn_epis_ind_eval last_evaluation_id,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         leie.target_value || '|' || coalesce(to_char(leie.indicator_value), '-')
                                    END last_evaluation_value,
                                    CASE leie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  leie.dt_evaluation,
                                                                  i_prof.institution,
                                                                  i_prof.software)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_nnn_epis_outcome  => lnkoi.id_nnn_epis_outcome,
                                                                           i_nnn_epis_ind_eval => leie.id_nnn_epis_ind_eval,
                                                                           i_use_html_format   => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                                ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL last_evaluation_id,
                                    NULL last_evaluation_value,
                                    NULL last_evaluation_date,
                                    NULL last_evaluation_abstract,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                               AND ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    lead.id_nnn_epis_activity_det last_evaluation_id,
                                    NULL last_evaluation_value,
                                    CASE lead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, lead.dt_val_time_start, i_prof)
                                    END last_evaluation_date,
                                    pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                            i_prof                  => i_prof,
                                                                            i_nnn_epis_activity_det => lead.id_nnn_epis_activity_det,
                                                                            i_use_html_format       => pk_alert_constant.g_yes) last_evaluation_abstract,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                                ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient
                               AND ea.flg_req_status != pk_nnn_constant.g_req_status_cancelled) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eoe.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                       AND eoe.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => eie.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                       AND eie.flg_status = pk_nnn_constant.g_task_status_finished
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ead.dt_val_time_start,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient
                                       AND ead.flg_status = pk_nnn_constant.g_task_status_finished) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
    END get_pat_evaluations_view;

    PROCEDURE get_pat_plan_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_scope        IN NUMBER,
        i_scope_type   IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_paging       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_start_column IN NUMBER DEFAULT 1,
        i_num_columns  IN NUMBER DEFAULT 2000,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type
    ) IS
        k_function_name           CONSTANT pk_types.t_internal_name_byte := 'get_pat_plan_view';
        k_prefix_key_diagnosis    CONSTANT VARCHAR2(30 CHAR) := g_act_subj_diagnosis || '|';
        k_prefix_key_outcome      CONSTANT VARCHAR2(30 CHAR) := g_act_subj_outcome || '|';
        k_prefix_key_indicator    CONSTANT VARCHAR2(30 CHAR) := g_act_subj_indicator || '|';
        k_prefix_key_intervention CONSTANT VARCHAR2(30 CHAR) := g_act_subj_intervention || '|';
        k_prefix_key_activity     CONSTANT VARCHAR2(30 CHAR) := g_act_subj_activity || '|';
        l_timestamp                   TIMESTAMP WITH LOCAL TIME ZONE;
        l_timeline_date_header_format sys_config.value%TYPE;
        l_start_column                pk_types.t_big_num;
        l_end_column                  pk_types.t_big_num;
        l_patient                     patient.id_patient%TYPE;
        l_visit                       visit.id_visit%TYPE;
        l_episode                     episode.id_episode%TYPE;
        l_error                       t_error_out;
    
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(to_char(i_scope_type), '<null>');
        g_error := g_error || ' i_start_column = ' || coalesce(to_char(i_start_column), '<null>');
        g_error := g_error || ' i_num_columns = ' || coalesce(to_char(i_num_columns), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
           OR i_paging IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        pk_alert_exceptions.assert(condition_in => i_patient = l_patient, message_in => 'The i_patient doesn''t match');
    
        l_timeline_date_header_format := pk_sysconfig.get_config(i_code_cf => pk_nnn_constant.g_config_timeline_date_format,
                                                                 i_prof    => i_prof);
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            l_start_column := i_start_column;
            l_end_column   := i_start_column + i_num_columns - 1;
        
            IF l_start_column < 1
            THEN
                -- Minimum inbound 
                l_start_column := 1;
            END IF;
        END IF;
    
        -- !!! WARNING !!!!  For performance reasons the same query is replicated and adjusted according each scope (Episode/Visit/Patient)
        -- !!! WARNING !!!!  So, if you need to add/modify something in the query, please
        -- !!! WARNING !!!!  make sure that this modification is applied/validated also in all of these queries and be consistent with the output
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode  
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                             WHERE ed.id_patient = i_patient
                               AND ed.id_episode = l_episode
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neoe.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neoe.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) neoe
                                ON eo.id_nnn_epis_outcome = neoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                               AND eo.id_episode = l_episode
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neie.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neie.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) neie
                                ON ei.id_nnn_epis_indicator = neie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                               AND ei.id_episode = l_episode
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                               AND ei.id_episode = l_episode
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, nead.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN nead.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) nead
                                ON ea.id_nnn_epis_activity = nead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient
                               AND ea.id_episode = l_episode) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           get_status_str(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_flg_type   => CASE x.prefix
                                                              WHEN k_prefix_key_diagnosis THEN
                                                               pk_nnn_constant.g_type_diagnosis_eval
                                                              WHEN k_prefix_key_outcome THEN
                                                               pk_nnn_constant.g_type_outcome_eval
                                                              WHEN k_prefix_key_indicator THEN
                                                               pk_nnn_constant.g_type_indicator_eval
                                                              WHEN k_prefix_key_activity THEN
                                                               pk_nnn_constant.g_type_activity_det
                                                          END,
                                          i_flg_prn    => x.flg_prn,
                                          i_flg_status => x.flg_status,
                                          i_flg_time   => x.flg_time,
                                          i_dt_plan    => x.dt_evaluation,
                                          i_timestamp  => l_timestamp) status_str,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            NULL flg_prn,
                                            NULL flg_time,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                       AND ede.id_episode = l_episode
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eo.flg_prn,
                                            eo.flg_time,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eoe.dt_evaluation,
                                                                                                     eoe.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => eo.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                       AND eoe.id_episode = l_episode
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            ei.flg_prn,
                                            ei.flg_time,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eie.dt_evaluation,
                                                                                                     eie.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ei.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                       AND eie.id_episode = l_episode
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ea.flg_prn,
                                            ea.flg_time,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(ead.dt_val_time_start,
                                                                                                     ead.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ea.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient
                                       AND ead.id_episode = l_episode) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                             WHERE ed.id_patient = i_patient
                               AND ed.id_visit = l_visit
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neoe.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neoe.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) neoe
                                ON eo.id_nnn_epis_outcome = neoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                               AND eo.id_visit = l_visit
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neie.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neie.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) neie
                                ON ei.id_nnn_epis_indicator = neie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                               AND ei.id_visit = l_visit
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                               AND ei.id_visit = l_visit
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, nead.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN nead.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) nead
                                ON ea.id_nnn_epis_activity = nead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient
                               AND ea.id_visit = l_visit) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           get_status_str(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_flg_type   => CASE x.prefix
                                                              WHEN k_prefix_key_diagnosis THEN
                                                               pk_nnn_constant.g_type_diagnosis_eval
                                                              WHEN k_prefix_key_outcome THEN
                                                               pk_nnn_constant.g_type_outcome_eval
                                                              WHEN k_prefix_key_indicator THEN
                                                               pk_nnn_constant.g_type_indicator_eval
                                                              WHEN k_prefix_key_activity THEN
                                                               pk_nnn_constant.g_type_activity_det
                                                          END,
                                          i_flg_prn    => x.flg_prn,
                                          i_flg_status => x.flg_status,
                                          i_flg_time   => x.flg_time,
                                          i_dt_plan    => x.dt_evaluation,
                                          i_timestamp  => l_timestamp) status_str,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            NULL flg_prn,
                                            NULL flg_time,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                       AND ede.id_visit = l_visit
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eo.flg_prn,
                                            eo.flg_time,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eoe.dt_evaluation,
                                                                                                     eoe.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => eo.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                       AND eoe.id_visit = l_visit
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            ei.flg_prn,
                                            ei.flg_time,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eie.dt_evaluation,
                                                                                                     eie.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ei.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                       AND eie.id_visit = l_visit
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ea.flg_prn,
                                            ea.flg_time,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(ead.dt_val_time_start,
                                                                                                     ead.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ea.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient
                                       AND ead.id_visit = l_visit) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient                
            
                OPEN o_rows FOR
                    SELECT *
                      FROM (
                            -- [-]Diagnoses
                            SELECT 1 rank_by_type,
                                    g_act_subj_diagnosis prefix,
                                    k_prefix_key_diagnosis || to_char(ed.id_nnn_epis_diagnosis) id_key,
                                    NULL id_parent_key,
                                    ed.id_nnn_epis_diagnosis id_item,
                                    pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                                        i_code_format     => pk_nan_model.g_code_format_end,
                                                                        i_additional_info => ed.edited_diagnosis_name) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(do.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_intervention || to_char(di.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_diagnosis = ed.id_nnn_epis_diagnosis
                                             AND di.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ed.flg_req_status,
                                    pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                            ed.flg_req_status,
                                                            i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                         i_val      => ed.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_diagnosis,
                                                      i_status  => ed.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_diagnosis_cancel) flg_cancel
                              FROM nnn_epis_diagnosis ed
                             WHERE ed.id_patient = i_patient
                            
                            UNION ALL
                            -- [-]Outcomes
                            SELECT 3 rank_by_type,
                                    g_act_subj_outcome prefix,
                                    k_prefix_key_outcome || to_char(eo.id_nnn_epis_outcome) id_key,
                                    NULL id_parent_key,
                                    eo.id_nnn_epis_outcome id_item,
                                    pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                                  i_code_format => pk_noc_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(do.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_outc do
                                           WHERE do.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND do.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_indicator || to_char(oi.id_nnn_epis_indicator)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neoe.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neoe.id_nnn_epis_outcome_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neoe.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    eo.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                            i_val      => eo.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                         i_val      => eo.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_outcome_eval_progress(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_outcome  => eo.id_nnn_epis_outcome,
                                                                          i_order_recurr_plan => eo.id_order_recurr_plan) evaluations,
                                    eo.flg_priority,
                                    eo.flg_time,
                                    eo.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_outcome,
                                                      i_status  => eo.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_outcome_cancel) flg_cancel
                              FROM nnn_epis_outcome eo
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) neoe
                                ON eo.id_nnn_epis_outcome = neoe.id_nnn_epis_outcome
                             WHERE eo.id_patient = i_patient
                            
                            UNION ALL
                            -- [-]Indicators        
                            SELECT 3 rank_by_type,
                                    g_act_subj_indicator prefix,
                                    k_prefix_key_indicator || to_char(ei.id_nnn_epis_indicator) id_key,
                                    k_prefix_key_outcome || to_char(lnkoi.id_nnn_epis_outcome) id_parent_key,
                                    
                                    ei.id_nnn_epis_indicator id_item,
                                    pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_outcome || to_char(oi.id_nnn_epis_outcome)
                                            FROM nnn_epis_lnk_outc_ind oi
                                           WHERE oi.id_nnn_epis_indicator = ei.id_nnn_epis_indicator
                                             AND oi.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, neie.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE neie.id_nnn_epis_ind_eval
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN neie.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_indicator_eval_progress(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_nnn_epis_indicator => ei.id_nnn_epis_indicator,
                                                                            i_order_recurr_plan  => ei.id_order_recurr_plan) evaluations,
                                    ei.flg_priority,
                                    ei.flg_time,
                                    ei.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_indicator,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_indicator_cancel) flg_cancel
                              FROM nnn_epis_indicator ei
                             INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                               AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) neie
                                ON ei.id_nnn_epis_indicator = neie.id_nnn_epis_indicator
                             WHERE ei.id_patient = i_patient
                            
                            UNION ALL
                            -- [-]Interventions
                            SELECT 5 rank_by_type,
                                    g_act_subj_intervention prefix,
                                    k_prefix_key_intervention || to_char(ei.id_nnn_epis_intervention) id_key,
                                    NULL id_parent_key,
                                    ei.id_nnn_epis_intervention id_item,
                                    pk_nic_model.get_intervention_name(i_nic_intervention => ei.id_nic_intervention,
                                                                       i_code_format      => pk_nic_model.g_code_format_end) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_diagnosis || to_char(di.id_nnn_epis_diagnosis)
                                            FROM nnn_epis_lnk_dg_intrv di
                                           WHERE di.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND di.flg_lnk_status = pk_alert_constant.g_active
                                          UNION ALL
                                          SELECT k_prefix_key_activity || to_char(ia.id_nnn_epis_activity)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_intervention = ei.id_nnn_epis_intervention
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_keys,
                                    NULL next_performing_date,
                                    NULL next_performing_delayed,
                                    ei.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                            i_val      => ei.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_int_flg_req_status,
                                                         i_val      => ei.flg_req_status) icon_req_status,
                                    NULL evaluations,
                                    NULL flg_priority,
                                    NULL flg_time,
                                    NULL flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_intervention,
                                                      i_status  => ei.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_intervention_cancel) flg_cancel
                              FROM nnn_epis_intervention ei
                             WHERE ei.id_patient = i_patient
                            
                            UNION ALL
                            -- Activities
                            SELECT 5 rank_by_type,
                                    g_act_subj_activity prefix,
                                    k_prefix_key_activity || to_char(ea.id_nnn_epis_activity) id_key,
                                    k_prefix_key_intervention || lnkia.id_nnn_epis_intervention id_parent_key,
                                    ea.id_nnn_epis_activity id_item,
                                    pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) item_name,
                                    CAST(MULTISET (SELECT k_prefix_key_intervention || to_char(ia.id_nnn_epis_intervention)
                                            FROM nnn_epis_lnk_int_actv ia
                                           WHERE ia.id_nnn_epis_activity = ea.id_nnn_epis_activity
                                             AND ia.flg_lnk_status = pk_alert_constant.g_active) AS table_varchar) linked_items,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         pk_date_utils.dt_chr_tsz(i_lang, nead.dt_plan, i_prof.institution, i_prof.software)
                                    END next_performing_date,
                                    CASE nead.id_nnn_epis_activity_det
                                        WHEN NULL THEN
                                         NULL
                                        ELSE
                                         CASE
                                             WHEN nead.dt_plan < l_timestamp THEN
                                              pk_alert_constant.g_yes
                                             ELSE
                                              pk_alert_constant.g_no
                                         END
                                    END next_performing_delayed,
                                    ea.flg_req_status,
                                    pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                            i_val      => ea.flg_req_status,
                                                            i_lang     => i_lang) desc_flg_req_status,
                                    pk_sysdomain.get_img(i_lang     => i_lang,
                                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                         i_val      => ea.flg_req_status) icon_req_status,
                                    pk_nnn_core.get_activity_det_progress(i_lang => i_lang,
                                                                          
                                                                          i_prof              => i_prof,
                                                                          i_nnn_epis_activity => ea.id_nnn_epis_activity,
                                                                          i_order_recurr_plan => ea.id_order_recurr_plan) executions,
                                    ea.flg_priority,
                                    ea.flg_time,
                                    ea.flg_prn,
                                    check_permissions(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_subject => g_act_subj_activity,
                                                      i_status  => ea.flg_req_status,
                                                      i_check   => pk_nnn_constant.g_action_activity_cancel) flg_cancel
                              FROM nnn_epis_activity ea
                             INNER JOIN nnn_epis_lnk_int_actv lnkia
                                ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                               AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) nead
                                ON ea.id_nnn_epis_activity = nead.id_nnn_epis_activity
                             WHERE ea.id_patient = i_patient) f
                    CONNECT BY PRIOR id_key = id_parent_key
                     START WITH id_parent_key IS NULL
                     ORDER SIBLINGS BY rank_by_type, pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status, i_val => flg_req_status), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority, i_val => flg_priority), pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn, i_val => flg_prn), item_name;
            
                OPEN o_cols FOR
                    SELECT x.column_number,
                           x.total_columns,
                           x.prefix || to_char(x.id_item) id_key,
                           x.parent_prefix || to_char(x.id_parent_item) id_parent_key,
                           x.id_item,
                           x.id_item_eval,
                           get_status_str(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_flg_type   => CASE x.prefix
                                                              WHEN k_prefix_key_diagnosis THEN
                                                               pk_nnn_constant.g_type_diagnosis_eval
                                                              WHEN k_prefix_key_outcome THEN
                                                               pk_nnn_constant.g_type_outcome_eval
                                                              WHEN k_prefix_key_indicator THEN
                                                               pk_nnn_constant.g_type_indicator_eval
                                                              WHEN k_prefix_key_activity THEN
                                                               pk_nnn_constant.g_type_activity_det
                                                          END,
                                          i_flg_prn    => x.flg_prn,
                                          i_flg_status => x.flg_status,
                                          i_flg_time   => x.flg_time,
                                          i_dt_plan    => x.dt_evaluation,
                                          i_timestamp  => l_timestamp) status_str,
                           x.flg_status,
                           pk_sysdomain.get_domain(i_code_dom => CASE x.prefix
                                                                     WHEN k_prefix_key_diagnosis THEN
                                                                      pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                     WHEN k_prefix_key_outcome THEN
                                                                      pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                     WHEN k_prefix_key_indicator THEN
                                                                      pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                     WHEN k_prefix_key_activity THEN
                                                                      pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                                 END,
                                                   i_val      => x.flg_status,
                                                   i_lang     => i_lang) desc_flg_status,
                           
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => CASE x.prefix
                                                                  WHEN k_prefix_key_diagnosis THEN
                                                                   pk_nnn_constant.g_dom_epis_diag_evl_flg_status
                                                                  WHEN k_prefix_key_outcome THEN
                                                                   pk_nnn_constant.g_dom_epis_out_evl_flg_status
                                                                  WHEN k_prefix_key_indicator THEN
                                                                   pk_nnn_constant.g_dom_epis_ind_evl_flg_status
                                                                  WHEN k_prefix_key_activity THEN
                                                                   pk_nnn_constant.g_dom_epis_act_det_flg_status
                                                              END,
                                                i_val      => x.flg_status) icon_flg_status,
                           x.target_value,
                           x.current_value,
                           pk_date_utils.date_send_tsz(i_lang, x.dt_evaluation, i_prof) dt_evaluation,
                           pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => x.dt_evaluation,
                                                              i_mask      => l_timeline_date_header_format) desc_dt_evaluation,
                           
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                pk_nnn_core.get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_nnn_epis_diag_eval => x.id_item_eval,
                                                                        i_use_html_format    => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_outcome THEN
                                pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                           i_prof                  => i_prof,
                                                                           i_nnn_epis_outcome_eval => x.id_item_eval,
                                                                           i_use_html_format       => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_indicator THEN
                                pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_nnn_epis_outcome  => x.id_parent_item,
                                                                       i_nnn_epis_ind_eval => x.id_item_eval,
                                                                       i_use_html_format   => pk_alert_constant.g_yes)
                               WHEN k_prefix_key_activity THEN
                                pk_nnn_core.get_epis_actv_exec_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_activity_det => x.id_item_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                           END abstract,
                           CASE x.prefix
                               WHEN k_prefix_key_diagnosis THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_diagnosis_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_diagnosis_eval_cancel)
                               WHEN k_prefix_key_outcome THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_outcome_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_outcome_eval_cancel)
                               WHEN k_prefix_key_indicator THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_indicator_eval,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_indicator_eval_cancel)
                               WHEN k_prefix_key_activity THEN
                                check_permissions(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_subject => g_act_subj_activity_exec,
                                                  i_status  => x.flg_status,
                                                  i_check   => pk_nnn_constant.g_action_activity_exec_cancel)
                           END flg_cancel
                      FROM (SELECT t.*,
                                   dense_rank() over(ORDER BY t.dt_evaluation DESC) column_number,
                                   COUNT(DISTINCT t.dt_evaluation) over() total_columns
                              FROM (
                                    -- [-]Diagnosis evaluations
                                    SELECT 1 rank_by_type,
                                            k_prefix_key_diagnosis prefix,
                                            ede.id_nnn_epis_diagnosis id_item,
                                            ede.id_nnn_epis_diag_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            NULL flg_prn,
                                            NULL flg_time,
                                            ede.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => ede.dt_evaluation,
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_diag_eval ede
                                     WHERE ede.id_patient = i_patient
                                    
                                    UNION ALL
                                    -- [-]Outcome evaluations
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_outcome prefix,
                                            eoe.id_nnn_epis_outcome id_item,
                                            eoe.id_nnn_epis_outcome_eval id_item_eval,
                                            NULL parent_prefix,
                                            NULL id_parent_item,
                                            eo.flg_prn,
                                            eo.flg_time,
                                            eoe.flg_status,
                                            eoe.target_value,
                                            eoe.outcome_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eoe.dt_evaluation,
                                                                                                     eoe.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => eo.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                    
                                      FROM nnn_epis_outcome_eval eoe
                                     INNER JOIN nnn_epis_outcome eo
                                        ON eo.id_nnn_epis_outcome = eoe.id_nnn_epis_outcome
                                     WHERE eoe.id_patient = i_patient
                                    
                                    UNION ALL
                                    -- [-]Indicator evaluations                                    
                                    SELECT 3 rank_by_type,
                                            k_prefix_key_indicator prefix,
                                            eie.id_nnn_epis_indicator id_item,
                                            eie.id_nnn_epis_ind_eval id_item_eval,
                                            k_prefix_key_outcome parent_prefix,
                                            lnkoi.id_nnn_epis_outcome id_parent_item,
                                            ei.flg_prn,
                                            ei.flg_time,
                                            eie.flg_status,
                                            eie.target_value,
                                            eie.indicator_value current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(eie.dt_evaluation,
                                                                                                     eie.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ei.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_ind_eval eie
                                     INNER JOIN nnn_epis_indicator ei
                                        ON ei.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                     INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                                        ON lnkoi.id_nnn_epis_indicator = eie.id_nnn_epis_indicator
                                       AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE eie.id_patient = i_patient
                                    
                                    UNION ALL
                                    -- [-]Activity executions
                                    SELECT 5 rank_by_type,
                                            k_prefix_key_activity prefix,
                                            ead.id_nnn_epis_activity id_item,
                                            ead.id_nnn_epis_activity_det id_item_eval,
                                            k_prefix_key_intervention parent_prefix,
                                            lnkia.id_nnn_epis_intervention id_parent_item,
                                            ea.flg_prn,
                                            ea.flg_time,
                                            ead.flg_status,
                                            NULL target_value,
                                            NULL current_value,
                                            pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                             i_timestamp => coalesce(ead.dt_val_time_start,
                                                                                                     ead.dt_plan,
                                                                                                     get_start_date(i_lang              => i_lang,
                                                                                                                    i_prof              => i_prof,
                                                                                                                    i_order_recurr_plan => ea.id_order_recurr_plan)),
                                                                             i_format    => k_minute_format) dt_evaluation
                                      FROM nnn_epis_activity_det ead
                                     INNER JOIN nnn_epis_activity ea
                                        ON ea.id_nnn_epis_activity = ead.id_nnn_epis_activity
                                     INNER JOIN nnn_epis_lnk_int_actv lnkia
                                        ON ea.id_nnn_epis_activity = lnkia.id_nnn_epis_activity
                                       AND lnkia.flg_lnk_status = pk_alert_constant.g_active
                                     WHERE ead.id_patient = i_patient) t) x
                     WHERE (i_paging = pk_alert_constant.g_yes AND
                           (x.column_number BETWEEN l_start_column AND l_end_column)) -- Paging by columns with same date(dense_rank)
                        OR i_paging = pk_alert_constant.g_no
                     ORDER BY x.dt_evaluation DESC, x.rank_by_type;
            
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
    END get_pat_plan_view;

    PROCEDURE check_outcome_goals_achieved
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_nnn_epis_diagnosis  IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_flg_goals_archieved OUT VARCHAR2,
        o_goals_status        OUT pk_types.cursor_type
    ) IS
        TYPE t_rec_outcome_goal IS RECORD(
            id_nnn_epis_outcome      nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
            id_parent                nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
            outcome_name             pk_translation.t_desc_translation,
            target_value             nnn_epis_outcome_eval.target_value%TYPE,
            desc_target_value        pk_translation.t_desc_translation,
            current_value            nnn_epis_outcome_eval.outcome_value%TYPE,
            desc_current_value       pk_translation.t_desc_translation,
            success                  VARCHAR2(1 CHAR),
            last_evaluation_abstract CLOB);
        TYPE t_cur_outcome_goal IS REF CURSOR RETURN t_rec_outcome_goal;
    
        l_cur_goal        t_cur_outcome_goal;
        l_rec_goal        t_rec_outcome_goal;
        l_goals_archieved VARCHAR2(1 CHAR);
    
        FUNCTION get_goals_status RETURN t_cur_outcome_goal IS
            l_refcur t_cur_outcome_goal;
        BEGIN
            OPEN l_refcur FOR
                WITH outcomes AS
                 (SELECT eo.id_nnn_epis_outcome,
                         NULL id_parent,
                         eo.id_noc_outcome,
                         pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome) outcome_name,
                         leoe.target_value,
                         pk_noc_model.get_outcome_scale_level_name(i_lang              => i_lang,
                                                                   i_noc_outcome       => eo.id_noc_outcome,
                                                                   i_scale_level_value => leoe.target_value) desc_target_value,
                         leoe.outcome_value current_value,
                         pk_noc_model.get_outcome_scale_level_name(i_lang              => i_lang,
                                                                   i_noc_outcome       => eo.id_noc_outcome,
                                                                   i_scale_level_value => leoe.outcome_value) desc_current_value,
                         CASE
                              WHEN leoe.outcome_value >= leoe.target_value THEN
                               pk_alert_constant.g_yes
                              ELSE
                               pk_alert_constant.g_no
                          END success,
                         leoe.id_nnn_epis_outcome_eval id_eval
                  
                    FROM nnn_epis_outcome eo
                   INNER JOIN nnn_epis_lnk_dg_outc lnkdo
                      ON eo.id_nnn_epis_outcome = lnkdo.id_nnn_epis_outcome
                     AND lnkdo.flg_lnk_status = pk_alert_constant.g_active
                    LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                      ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                   WHERE lnkdo.id_nnn_epis_diagnosis = i_nnn_epis_diagnosis -- Filter by NANDA Dx
                     AND eo.flg_req_status != pk_nnn_constant.g_req_status_cancelled),
                
                indicators AS
                 (SELECT NULL id_nnn_epis_outcome,
                         lnkoi.id_nnn_epis_outcome id_parent,
                         NULL id_noc_outcome,
                         pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) indicator_name,
                         leie.target_value,
                         pk_noc_model.get_indicator_scale_level_name(i_lang              => i_lang,
                                                                     i_noc_outcome       => o.id_noc_outcome,
                                                                     i_noc_indicator     => ei.id_noc_indicator,
                                                                     i_scale_level_value => leie.target_value) desc_target_value,
                         leie.indicator_value current_value,
                         pk_noc_model.get_indicator_scale_level_name(i_lang              => i_lang,
                                                                     i_noc_outcome       => o.id_noc_outcome,
                                                                     i_noc_indicator     => ei.id_noc_indicator,
                                                                     i_scale_level_value => leie.indicator_value) desc_current_value,
                         CASE
                              WHEN leie.indicator_value >= leie.target_value THEN
                               pk_alert_constant.g_yes
                              ELSE
                               pk_alert_constant.g_no
                          END success,
                         leie.id_nnn_epis_ind_eval id_eval
                  
                    FROM nnn_epis_indicator ei
                   INNER JOIN nnn_epis_lnk_outc_ind lnkoi
                      ON ei.id_nnn_epis_indicator = lnkoi.id_nnn_epis_indicator
                     AND lnkoi.flg_lnk_status = pk_alert_constant.g_active
                   INNER JOIN outcomes o
                      ON lnkoi.id_nnn_epis_outcome = o.id_nnn_epis_outcome
                    LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                      ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                   WHERE ei.flg_req_status != pk_nnn_constant.g_req_status_cancelled)
                --  Main query
                SELECT t.id_nnn_epis_outcome,
                       t.id_parent,
                       t.outcome_name,
                       t.target_value,
                       t.desc_target_value,
                       t.current_value,
                       t.desc_current_value,
                       t.success,
                       CASE
                            WHEN t.id_nnn_epis_outcome IS NOT NULL THEN
                            -- The row is an outcome
                             pk_nnn_core.get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                        i_prof                  => i_prof,
                                                                        i_nnn_epis_outcome_eval => t.id_eval,
                                                                        i_use_html_format       => pk_alert_constant.g_yes)
                            ELSE
                            -- The row is an indicator (t.id_parent holds the id_nnn_epis_outcome and t.id_nnn_epis_outcome is null in this case)
                             pk_nnn_core.get_epis_ind_eval_abstract(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_nnn_epis_outcome  => t.id_parent,
                                                                    i_nnn_epis_ind_eval => t.id_eval,
                                                                    i_use_html_format   => pk_alert_constant.g_yes)
                        
                        END last_evaluation_abstract
                
                  FROM (SELECT *
                          FROM outcomes
                        UNION ALL
                        SELECT *
                          FROM indicators i) t
                CONNECT BY PRIOR t.id_nnn_epis_outcome = t.id_parent
                 START WITH t.id_parent IS NULL
                 ORDER SIBLINGS BY t.outcome_name;
        
            RETURN l_refcur;
        END get_goals_status;
    
    BEGIN
        -- Checks if there is at least one goal that was not achieved
        l_goals_archieved := pk_alert_constant.g_yes;
        l_cur_goal        := get_goals_status;
        LOOP
            FETCH l_cur_goal
                INTO l_rec_goal;
            EXIT WHEN l_cur_goal%NOTFOUND;
            IF l_rec_goal.success = pk_alert_constant.g_no
            THEN
                l_goals_archieved := pk_alert_constant.g_no;
                EXIT;
            END IF;
        
        END LOOP;
        CLOSE l_cur_goal;
    
        -- Returns 'N' if at least one goal was not achieved
        o_flg_goals_archieved := l_goals_archieved;
    
        -- Returns a cursor with the information of all outcomes and indicators associated with the diagnosis
        o_goals_status := get_goals_status();
    
    END check_outcome_goals_achieved;

    FUNCTION get_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_type   IN VARCHAR,
        i_flg_prn    IN VARCHAR,
        i_flg_status IN VARCHAR,
        i_flg_time   IN VARCHAR,
        i_dt_plan    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_shortcut   IN sys_shortcut.id_sys_shortcut%TYPE DEFAULT NULL,
        i_timestamp  IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_status_str';
        l_retval pk_types.t_huge_byte;
    
        l_display_type  VARCHAR2(2 CHAR);
        l_value_text    sys_message.desc_message%TYPE;
        l_value_date    VARCHAR2(200);
        l_value_icon    sys_domain.code_domain%TYPE;
        l_back_color    VARCHAR2(8 CHAR) := pk_alert_constant.g_color_null;
        l_icon_color    VARCHAR2(8 CHAR) := pk_alert_constant.g_color_null;
        l_message_style sys_message.code_message%TYPE := NULL;
        l_message_color VARCHAR2(8 CHAR) := pk_alert_constant.g_color_null;
    
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_flg_type = ' || coalesce(to_char(i_flg_type), '<null>');
        g_error := g_error || ' i_flg_prn = ' || coalesce(to_char(i_flg_prn), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        g_error := g_error || ' i_flg_time = ' || coalesce(to_char(i_flg_time), '<null>');
        g_error := g_error || ' i_dt_plan = ' || coalesce(to_char(i_dt_plan, 'DD-MON-YYYY HH24:MI:SS TZR'), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- social assistance requests status string logic
        IF i_flg_prn = pk_alert_constant.get_yes
        THEN
            -- PRN requests
            l_display_type  := pk_alert_constant.g_display_type_text;
            l_value_text    := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => pk_nnn_constant.g_mcode_icon_sos);
            l_message_style := pk_nnn_constant.g_mcode_style_msg_sos;
            l_message_color := pk_alert_constant.g_color_icon_medium_grey;
        ELSE
            IF i_flg_time = pk_nnn_constant.g_time_performed_next_epis
            THEN
                -- scheduled request
                l_display_type := pk_alert_constant.g_display_type_text;
                l_value_text   := pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => pk_nnn_constant.g_mcode_icon_scheduled);
                l_back_color   := pk_alert_constant.g_color_green;
            ELSE
                IF i_flg_status IN (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_ongoing)
                   AND i_flg_type != pk_nnn_constant.g_type_diagnosis_eval
                THEN
                    -- pending/ongoing requests                        
                    l_display_type := pk_alert_constant.g_display_type_date;
                    l_value_date   := pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                                         i_timestamp => i_dt_plan,
                                                                         i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                ELSE
                    -- other request status
                    l_display_type := pk_alert_constant.g_display_type_icon;
                    CASE i_flg_type
                        WHEN pk_nnn_constant.g_type_diagnosis_eval THEN
                            l_display_type := pk_alert_constant.g_display_type_text;
                            l_value_text   := pk_sysdomain.get_domain(i_code_dom => pk_nnn_constant.g_dom_epis_diag_evl_flg_status,
                                                                      i_val      => i_flg_status,
                                                                      i_lang     => i_lang);
                        
                            CASE i_flg_status
                                WHEN pk_nnn_constant.g_diagnosis_status_active THEN
                                    l_back_color := pk_alert_constant.g_color_red;
                                WHEN pk_nnn_constant.g_diagnosis_status_inactive THEN
                                    l_back_color := pk_alert_constant.g_color_orange;
                                WHEN pk_nnn_constant.g_diagnosis_status_resolved THEN
                                    l_back_color := pk_alert_constant.g_color_gray;
                                ELSE
                                    l_display_type := pk_alert_constant.g_display_type_icon;
                            END CASE;
                        WHEN pk_nnn_constant.g_type_activity THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_act_flg_req_status;
                        
                        WHEN pk_nnn_constant.g_type_activity_det THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_act_det_flg_status;
                        
                        WHEN pk_nnn_constant.g_type_indicator THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_ind_flg_req_status;
                        
                        WHEN pk_nnn_constant.g_type_indicator_eval THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_ind_evl_flg_status;
                        
                        WHEN pk_nnn_constant.g_type_intervention THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_int_flg_req_status;
                        
                        WHEN pk_nnn_constant.g_type_outcome THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_out_flg_req_status;
                        
                        WHEN pk_nnn_constant.g_type_outcome_eval THEN
                            l_value_icon := pk_nnn_constant.g_dom_epis_out_evl_flg_status;
                        
                        ELSE
                            RAISE pk_nnn_constant.e_call_error;
                    END CASE;
                END IF;
            END IF;
        END IF;
    
        -- generate status string
        l_retval := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_display_type    => l_display_type,
                                                         i_flg_state       => i_flg_status,
                                                         i_value_text      => l_value_text,
                                                         i_value_date      => l_value_date,
                                                         i_value_icon      => l_value_icon,
                                                         i_shortcut        => i_shortcut,
                                                         i_back_color      => l_back_color,
                                                         i_icon_color      => l_icon_color,
                                                         i_message_style   => l_message_style,
                                                         i_message_color   => l_message_color,
                                                         i_flg_text_domain => pk_alert_constant.g_no,
                                                         i_dt_server       => i_timestamp);
        RETURN l_retval;
    END get_status_str;

    FUNCTION tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE)
        RETURN ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_outcome_eval.nnn_epis_outcome_eval_ntt;
    BEGIN
    
        SELECT oevl.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_outcome_eval oevl
         WHERE oevl.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY oevl.id_nnn_epis_outcome ORDER BY decode(oevl.flg_status, pk_nnn_constant.g_task_status_ongoing, 1, pk_nnn_constant.g_task_status_ordered, 1, 2), oevl.dt_plan, oevl.exec_number) rn
                                       FROM nnn_epis_outcome_eval oevl
                                      WHERE oevl.id_nnn_epis_outcome = i_nnn_epis_outcome
                                        AND oevl.flg_status = pk_nnn_constant.g_task_status_ordered) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    
    END tf_next_nnn_epis_outc_eval;

    FUNCTION tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE)
        RETURN ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_ind_eval.nnn_epis_ind_eval_ntt;
    BEGIN
    
        SELECT ievl.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_ind_eval ievl
         WHERE ievl.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY ievl.id_nnn_epis_indicator ORDER BY decode(ievl.flg_status, pk_nnn_constant.g_task_status_ongoing, 1, pk_nnn_constant.g_task_status_ordered, 1, 2), ievl.dt_plan, ievl.exec_number) rn
                                       FROM nnn_epis_ind_eval ievl
                                      WHERE ievl.id_nnn_epis_indicator = i_nnn_epis_indicator
                                        AND ievl.flg_status = pk_nnn_constant.g_task_status_ordered) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    
    END tf_next_nnn_epis_ind_eval;

    FUNCTION tf_next_nnn_epis_activ_det(i_nnn_epis_activity IN nnn_epis_activity_det.id_nnn_epis_activity%TYPE)
        RETURN ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt
        PIPELINED IS
        l_coll ts_nnn_epis_activity_det.nnn_epis_activity_det_ntt;
    BEGIN
    
        SELECT adet.*
          BULK COLLECT
          INTO l_coll
          FROM nnn_epis_activity_det adet
         WHERE adet.rowid = (SELECT t.rowid
                               FROM (SELECT row_number() over(PARTITION BY adet.id_nnn_epis_activity ORDER BY decode(adet.flg_status, pk_nnn_constant.g_task_status_ongoing, 1, pk_nnn_constant.g_task_status_ordered, 1, 2), adet.dt_plan, adet.exec_number) rn
                                       FROM nnn_epis_activity_det adet
                                      WHERE adet.id_nnn_epis_activity = i_nnn_epis_activity
                                        AND adet.flg_status = pk_nnn_constant.g_task_status_ordered) t
                              WHERE t.rn = 1);
    
        FOR i IN 1 .. l_coll.count
        LOOP
            PIPE ROW(l_coll(i));
        END LOOP;
    
    END tf_next_nnn_epis_activ_det;

    FUNCTION get_epis_nnn_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_fltr_type IN pk_types.t_low_char DEFAULT pk_nnn_constant.g_type_filter_req_any,
        o_epis_nnn  OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nnn_summary';
        l_error       t_error_out;
        l_id_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_timestamp   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- This shortcut points to a CareplanLoaderView intended to load the right Nursing care plan screen
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_nnn_constant.g_shortcut_careplan_loaderview,
                                         o_id_shortcut => l_id_shortcut,
                                         o_error       => l_error)
        THEN
            g_error := 'Error found while calling PK_ACCESS.GET_ID_SHORTCUT';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        /*
        -- Notice:
        The output of this method is tightly coupled to the expected format 
        of existent UX nursing summary/dashboard like INPNursingSummary/NursingSummaryGrid02.
        In the future when there is a specific dashboard for NNN care plan 
        and cease to use the existing one that belongs to ICNP, these functions, 
        such as the methods related to NNN that were injected into the PK_ICNP
        should be refactored.
        */
    
        --Retrieving Summary Nursing Outcomes, Indicators and Activities
        OPEN o_epis_nnn FOR
            SELECT x.id_icnp_epis_interv, x.flg_type, x.desc_interv, x.flg_time, x.flg_status, x.status
              FROM (
                    -- OUTCOME 
                    SELECT /*+ opt_estimate(table leoe rows=1)*/
                     eo.id_nnn_epis_outcome id_icnp_epis_interv,
                      pk_nnn_constant.g_type_outcome flg_type,
                      pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                    i_code_format => pk_noc_model.g_code_format_end) desc_interv,
                      eo.flg_time,
                      eo.flg_req_status flg_status,
                      get_status_str(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_flg_type   => pk_nnn_constant.g_type_outcome,
                                     i_flg_prn    => eo.flg_prn,
                                     i_flg_status => eo.flg_req_status,
                                     i_flg_time   => eo.flg_time,
                                     i_dt_plan    => leoe.dt_plan,
                                     i_shortcut   => l_id_shortcut,
                                     i_timestamp  => l_timestamp) status,
                      leoe.dt_plan,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                            i_val      => eo.flg_req_status) rank_status,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                            i_val      => eo.flg_priority) rank_priority,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_prn,
                                            i_val      => eo.flg_prn) rank_prn
                      FROM nnn_epis_outcome eo
                      LEFT JOIN TABLE(tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE eo.id_episode = i_episode
                       AND instr(i_fltr_type, pk_nnn_constant.g_type_outcome) > 0
                       AND eo.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)
                    UNION ALL
                    -- INDICATOR
                    SELECT /*+ opt_estimate(table leie rows=1)*/
                     ei.id_nnn_epis_indicator id_icnp_epis_interv,
                      pk_nnn_constant.g_type_indicator flg_type,
                      pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => noc_i.id_terminology_version),
                                                     i_code_mess => noc_i.code_description) desc_interv,
                      ei.flg_time,
                      ei.flg_req_status flg_status,
                      get_status_str(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_flg_type   => pk_nnn_constant.g_type_indicator,
                                     i_flg_prn    => ei.flg_prn,
                                     i_flg_status => ei.flg_req_status,
                                     i_flg_time   => ei.flg_time,
                                     i_dt_plan    => leie.dt_plan,
                                     i_shortcut   => l_id_shortcut,
                                     i_timestamp  => l_timestamp) status,
                      leie.dt_plan,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                            i_val      => ei.flg_req_status) rank_status,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_priority,
                                            i_val      => ei.flg_priority) rank_priority,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_prn,
                                            i_val      => ei.flg_prn) rank_prn
                      FROM nnn_epis_indicator ei
                      LEFT JOIN noc_indicator noc_i
                        ON ei.id_noc_indicator = noc_i.id_noc_indicator
                      LEFT JOIN TABLE(tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                        ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
                     WHERE ei.id_episode = i_episode
                       AND instr(i_fltr_type, pk_nnn_constant.g_type_indicator) > 0
                       AND ei.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)
                    UNION ALL
                    -- ACTIVITY
                    SELECT /*+ opt_estimate(table lead rows=1)*/
                     ea.id_nnn_epis_activity id_icnp_epis_interv,
                      pk_nnn_constant.g_type_activity flg_type,
                      pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => nic_a.id_terminology_version),
                                                     i_code_mess => nic_a.code_description) desc_interv,
                      ea.flg_time,
                      ea.flg_req_status flg_status,
                      get_status_str(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_flg_type   => pk_nnn_constant.g_type_activity,
                                     i_flg_prn    => ea.flg_prn,
                                     i_flg_status => ea.flg_req_status,
                                     i_flg_time   => ea.flg_time,
                                     i_dt_plan    => lead.dt_plan,
                                     i_shortcut   => l_id_shortcut,
                                     i_timestamp  => l_timestamp) status,
                      lead.dt_plan,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                            i_val      => ea.flg_req_status) rank_status,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_priority,
                                            i_val      => ea.flg_priority) rank_priority,
                      pk_sysdomain.get_rank(i_lang     => i_lang,
                                            i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_prn,
                                            i_val      => ea.flg_prn) rank_prn
                      FROM nnn_epis_activity ea
                      LEFT JOIN nic_activity nic_a
                        ON ea.id_nic_activity = nic_a.id_nic_activity
                      LEFT JOIN TABLE(tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                        ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
                     WHERE ea.id_episode = i_episode
                       AND instr(i_fltr_type, pk_nnn_constant.g_type_activity) > 0
                       AND ea.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)) x
             ORDER BY x.dt_plan NULLS LAST, x.rank_status, x.rank_priority, x.rank_prn, x.desc_interv;
    
        RETURN TRUE;
    
    END get_epis_nnn_summary;

    FUNCTION get_epis_nnn_diag_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_epis_nnn_diag_summary';
        l_error       t_error_out;
        l_id_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_timestamp   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- This shortcut points to a CareplanLoaderView intended to load the right Nursing care plan screen
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_nnn_constant.g_shortcut_careplan_loaderview,
                                         o_id_shortcut => l_id_shortcut,
                                         o_error       => l_error)
        THEN
            g_error := 'Error found while calling PK_ACCESS.GET_ID_SHORTCUT';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        /*
        -- Notice:
        The output of this method is tightly coupled to the expected format 
        of existent UX nursing summary/dashboard like INPNursingSummary.
        In the future when there is a specific dashboard for NNN care plan 
        and cease to use the existing one that belongs to ICNP, these functions, 
        such as the methods related to NNN that were injected into the PK_ICNP
        should be refactored.
        */
        OPEN o_diagnosis FOR
            SELECT ed.id_nnn_epis_diagnosis id_icnp_epis_diag,
                   pk_nnn_constant.g_type_diagnosis_eval flg_type,
                   pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis => ed.id_nan_diagnosis,
                                                       i_code_format   => pk_nan_model.g_code_format_end) description,
                   get_status_str(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_flg_type   => pk_nnn_constant.g_type_diagnosis_eval,
                                  i_flg_prn    => NULL,
                                  i_flg_status => lede.flg_status,
                                  i_flg_time   => NULL,
                                  i_dt_plan    => lede.dt_evaluation,
                                  i_shortcut   => l_id_shortcut,
                                  i_timestamp  => l_timestamp) status,
                   NULL date_target,
                   NULL hour_target,
                   pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_episode          => lede.id_episode,
                                                      i_date_last_change    => lede.dt_trs_time_start,
                                                      i_id_prof_last_change => lede.id_professional) prof,
                   pk_alert_constant.g_active flg_status, -- workaround: UX expects 'A' as status. 
                   NULL dt_ord1,
                   ed.id_nan_diagnosis id_composition,
                   NULL dt_icnp_epis_diag,
                   NULL dt_close,
                   NULL flg_check
              FROM nnn_epis_diagnosis ed
              LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
             WHERE ed.id_episode = i_episode
               AND ed.flg_req_status = pk_nnn_constant.g_req_status_ordered
               AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
             ORDER BY description;
    
        RETURN TRUE;
    
    END get_epis_nnn_diag_summary;

    PROCEDURE set_tasks_outcome
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_tasks_outcome';
        l_mess1 VARCHAR2(200);
        l_mess2 VARCHAR2(200);
        l_error t_error_out;
    
        CURSOR c_outcome IS
            SELECT e.flg_status epis_status,
                   eo.flg_time,
                   nvl(leoe.flg_status, eo.flg_req_status) flg_status,
                   nvl(leoe.dt_plan, eo.dt_trs_time_start) dt_begin,
                   eo.dt_trs_time_start dt_req,
                   pk_sysdomain.get_img(i_lang     => i_lang,
                                        i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                        i_val      => eo.flg_req_status) img_name,
                   pk_sysdomain.get_rank(i_lang     => i_lang,
                                         i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                         i_val      => eo.flg_req_status) rank
              FROM nnn_epis_outcome eo
              JOIN TABLE(tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
             INNER JOIN episode e
                ON eo.id_episode = e.id_episode
             WHERE eo.id_episode = i_episode
               AND eo.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)
               AND (eo.flg_prn <> pk_alert_constant.g_yes OR
                   (eo.flg_prn = pk_alert_constant.g_yes AND eo.flg_time = pk_nnn_constant.g_time_performed_next_epis))
             ORDER BY decode(eo.flg_time,
                             pk_alert_constant.g_flg_time_e,
                             1,
                             pk_alert_constant.g_flg_time_b,
                             2,
                             pk_alert_constant.g_flg_time_n,
                             3),
                      eo.dt_trs_time_start;
    
        TYPE t_coll_outc IS TABLE OF c_outcome%ROWTYPE;
        l_outcome   c_outcome%ROWTYPE;
        l_coll_outc t_coll_outc;
    BEGIN
        g_error := 'OPEN c_outcome';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        OPEN c_outcome;
        FETCH c_outcome BULK COLLECT
            INTO l_coll_outc;
        CLOSE c_outcome;
    
        FOR i IN 1 .. l_coll_outc.count
        LOOP
        
            l_outcome := l_coll_outc(i);
        
            g_error := 'GET L_MESS2 --> CALL get_string_task';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_mess2 := pk_grid.get_string_task(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_episode     => i_episode,
                                               i_epis_status => l_outcome.epis_status,
                                               i_flg_time    => l_outcome.flg_time,
                                               i_flg_status  => l_outcome.flg_status,
                                               i_dt_begin    => l_outcome.dt_begin,
                                               i_dt_req      => l_outcome.dt_req,
                                               i_icon_name   => l_outcome.img_name,
                                               i_rank        => l_outcome.rank,
                                               o_error       => l_error);
        
            g_error := 'GET L_MESS1 --> CALL get_prioritary_task';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            IF l_mess1 IS NOT NULL
            THEN
                -- Compares timestamps embedded in messages i_mess1 and i_mess2 and returns the message with 
                -- the most oldest timestamp.
                l_mess1 := pk_grid.get_prioritary_task(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_mess1    => l_mess1,
                                                       i_mess2    => l_mess2,
                                                       i_domain   => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                       i_prof_cat => pk_alert_constant.g_cat_type_nurse);
            END IF;
        
            -- only one register
            l_mess1 := nvl(l_mess1, l_mess2);
        
        END LOOP;
    
        g_error := 'UPDATE grid_task noc_outcome: ' || l_mess1;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        UPDATE grid_task
           SET noc_outcome = l_mess1
         WHERE id_episode = i_episode;
    
    END set_tasks_outcome;

    PROCEDURE set_tasks_indicator
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_tasks_indicador';
        l_mess1 VARCHAR2(200);
        l_mess2 VARCHAR2(200);
        l_error t_error_out;
    
        CURSOR c_indicator IS
            SELECT e.flg_status epis_status,
                   ei.flg_time,
                   nvl(leie.flg_status, ei.flg_req_status) flg_status,
                   nvl(leie.dt_plan, ei.dt_trs_time_start) dt_begin,
                   ei.dt_trs_time_start dt_req,
                   pk_sysdomain.get_img(i_lang     => i_lang,
                                        i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                        i_val      => ei.flg_req_status) img_name,
                   pk_sysdomain.get_rank(i_lang     => i_lang,
                                         i_code_dom => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                         i_val      => ei.flg_req_status) rank
              FROM nnn_epis_indicator ei
              LEFT JOIN TABLE(tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
             INNER JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE ei.id_episode = i_episode
               AND ei.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)
               AND (ei.flg_prn <> pk_alert_constant.g_yes OR
                   (ei.flg_prn = pk_alert_constant.g_yes AND ei.flg_time = pk_nnn_constant.g_time_performed_next_epis))
             ORDER BY decode(ei.flg_time,
                             pk_alert_constant.g_flg_time_e,
                             1,
                             pk_alert_constant.g_flg_time_b,
                             2,
                             pk_alert_constant.g_flg_time_n,
                             3),
                      ei.dt_trs_time_start;
    
        TYPE t_coll_ind IS TABLE OF c_indicator%ROWTYPE;
        l_indicator c_indicator%ROWTYPE;
        l_coll_ind  t_coll_ind;
    BEGIN
        g_error := 'OPEN c_indicator';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        OPEN c_indicator;
        FETCH c_indicator BULK COLLECT
            INTO l_coll_ind;
        CLOSE c_indicator;
    
        FOR i IN 1 .. l_coll_ind.count
        LOOP
        
            l_indicator := l_coll_ind(i);
        
            g_error := 'GET L_MESS2 --> CALL get_string_task';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            l_mess2 := pk_grid.get_string_task(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_episode     => i_episode,
                                               i_epis_status => l_indicator.epis_status,
                                               i_flg_time    => l_indicator.flg_time,
                                               i_flg_status  => l_indicator.flg_status,
                                               i_dt_begin    => l_indicator.dt_begin,
                                               i_dt_req      => l_indicator.dt_req,
                                               i_icon_name   => l_indicator.img_name,
                                               i_rank        => l_indicator.rank,
                                               o_error       => l_error);
        
            g_error := 'GET L_MESS1 --> CALL get_prioritary_task';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            IF l_mess1 IS NOT NULL
            THEN
                -- Compares timestamps embedded in messages i_mess1 and i_mess2 and returns the message with 
                -- the most oldest timestamp.
                l_mess1 := pk_grid.get_prioritary_task(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_mess1    => l_mess1,
                                                       i_mess2    => l_mess2,
                                                       i_domain   => pk_nnn_constant.g_dom_epis_ind_flg_req_status,
                                                       i_prof_cat => pk_alert_constant.g_cat_type_nurse);
            END IF;
        
            -- only one register
            l_mess1 := nvl(l_mess1, l_mess2);
        
        END LOOP;
    
        g_error := 'UPDATE grid_task noc_indicator: ' || l_mess1;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        UPDATE grid_task
           SET noc_indicator = l_mess1
         WHERE id_episode = i_episode;
    
    END set_tasks_indicator;

    PROCEDURE set_tasks_activity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_tasks_activity';
        l_mess1 VARCHAR2(200);
        l_mess2 VARCHAR2(200);
        l_error t_error_out;
    
        CURSOR c_activity IS
            SELECT e.flg_status epis_status,
                   ea.flg_time,
                   nvl(lead.flg_status, ea.flg_req_status) flg_status,
                   nvl(lead.dt_plan, ea.dt_trs_time_start) dt_begin,
                   ea.dt_trs_time_start dt_req,
                   pk_sysdomain.get_img(i_lang     => i_lang,
                                        i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                        i_val      => ea.flg_req_status) img_name,
                   pk_sysdomain.get_rank(i_lang     => i_lang,
                                         i_code_dom => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                         i_val      => ea.flg_req_status) rank
              FROM nnn_epis_activity ea
              LEFT JOIN nic_activity nic_a
                ON ea.id_nic_activity = nic_a.id_nic_activity
              LEFT JOIN TABLE(tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
             INNER JOIN episode e
                ON ea.id_episode = e.id_episode
             WHERE ea.id_episode = i_episode
               AND ea.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered)
               AND (ea.flg_prn <> pk_alert_constant.g_yes OR
                   (ea.flg_prn = pk_alert_constant.g_yes AND ea.flg_time = pk_nnn_constant.g_time_performed_next_epis))
             ORDER BY decode(ea.flg_time,
                             pk_alert_constant.g_flg_time_e,
                             1,
                             pk_alert_constant.g_flg_time_b,
                             2,
                             pk_alert_constant.g_flg_time_n,
                             3),
                      ea.dt_trs_time_start;
    
        TYPE t_coll_act IS TABLE OF c_activity%ROWTYPE;
        l_activity c_activity%ROWTYPE;
        l_coll_act t_coll_act;
    BEGIN
        g_error := 'OPEN c_activity';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        OPEN c_activity;
        FETCH c_activity BULK COLLECT
            INTO l_coll_act;
        CLOSE c_activity;
    
        g_error := 'Compares timestamps between ' || l_coll_act.count || ' nic_activity tasks to retrieve the oldest';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        FOR i IN 1 .. l_coll_act.count
        LOOP
        
            l_activity := l_coll_act(i);
        
            l_mess2 := pk_grid.get_string_task(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_episode     => i_episode,
                                               i_epis_status => l_activity.epis_status,
                                               i_flg_time    => l_activity.flg_time,
                                               i_flg_status  => l_activity.flg_status,
                                               i_dt_begin    => l_activity.dt_begin,
                                               i_dt_req      => l_activity.dt_req,
                                               i_icon_name   => l_activity.img_name,
                                               i_rank        => l_activity.rank,
                                               o_error       => l_error);
        
            IF l_mess1 IS NOT NULL
            THEN
                -- Compares timestamps embedded in messages i_mess1 and i_mess2 and returns the message with 
                -- the most oldest timestamp.
                l_mess1 := pk_grid.get_prioritary_task(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_mess1    => l_mess1,
                                                       i_mess2    => l_mess2,
                                                       i_domain   => pk_nnn_constant.g_dom_epis_act_flg_req_status,
                                                       i_prof_cat => pk_alert_constant.g_cat_type_nurse);
            END IF;
        
            -- only one register
            l_mess1 := nvl(l_mess1, l_mess2);
        
        END LOOP;
    
        g_error := 'UPDATE grid_task nic_activity: ' || l_mess1;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        UPDATE grid_task
           SET nic_activity = l_mess1
         WHERE id_episode = i_episode;
    
    END set_tasks_activity;

    PROCEDURE get_pat_unresolved_diagnosis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_diagnosis  OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_unresolved_diagnosis';
        l_error   t_error_out;
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        IF l_patient != i_patient
        THEN
            g_error := 'The I_PATIENT / I_SCOPE / I_SCOPE_TYPE don''t match';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Retrieving Nursing Diagnoses (NANDA Diagnosis) that were defined in this patient''s nursing care plan';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode          
                OPEN o_diagnosis FOR
                    SELECT ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                                                     i_prof               => i_prof,
                                                                                                     i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                                                     i_use_html_format    => pk_alert_constant.g_yes)) diagnosis_definition,
                           ed.flg_req_status,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                       AND ed.id_episode = l_episode
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                    
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit             
                OPEN o_diagnosis FOR
                    SELECT ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                                                     i_prof               => i_prof,
                                                                                                     i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                                                     i_use_html_format    => pk_alert_constant.g_yes)) diagnosis_definition,
                           ed.flg_req_status,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                       AND ed.id_visit = l_visit
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient                              
                OPEN o_diagnosis FOR
                    SELECT ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_diag_eval_abstract(i_lang               => i_lang,
                                                                                                     i_prof               => i_prof,
                                                                                                     i_nnn_epis_diag_eval => lede.id_nnn_epis_diag_eval,
                                                                                                     i_use_html_format    => pk_alert_constant.g_yes)) diagnosis_definition,
                           ed.flg_req_status,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                     WHERE ed.id_patient = i_patient
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                    i_val      => ed.flg_req_status),
                              diagnosis_name;
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
    EXCEPTION
        -- Log an raise the error      
        WHEN pk_nnn_constant.e_invalid_argument THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_invalid_argument', text_in => g_error);
        
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error', text_in => g_error);
    END get_pat_unresolved_diagnosis;

    PROCEDURE get_pat_unresolved_outcome
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        o_outcome    OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_pat_unresolved_outcome';
        l_error   t_error_out;
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_prof.id = ' || coalesce(to_char(i_prof.id), '<null>');
        g_error := g_error || ' i_prof.institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_prof.software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        g_error := g_error || ' i_scope = ' || coalesce(to_char(i_scope), '<null>');
        g_error := g_error || ' i_scope_type = ' || coalesce(to_char(i_scope_type), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Analysing input arguments';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF i_patient IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_error := 'An input parameter has an unexpected value';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        g_error := 'Analysing scope type';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => l_error)
        THEN
            g_error := 'Error found while calling PK_TOUCH_OPTION.GET_SCOPE_VARS';
            RAISE pk_nnn_constant.e_call_error;
        END IF;
    
        IF l_patient != i_patient
        THEN
            g_error := 'The I_PATIENT / I_SCOPE / I_SCOPE_TYPE don''t match';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        -- Returns one row for each link between NANDA/NOC items that are in the nursing care plan
    
        g_error := 'Retrieving Nursing Diagnoses (NANDA Diagnosis) and linked Nursing Outcomes (NOC Outcomes) that were defined in this patient''s nursing care plan';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode          
                OPEN o_outcome FOR
                    SELECT eo.id_nnn_epis_outcome,
                           pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                         i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                                                        i_prof                  => i_prof,
                                                                                                        i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                                                        i_use_html_format       => pk_alert_constant.g_yes)) outcome_definition,
                           eo.flg_req_status flg_req_status_outcome,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                   eo.flg_req_status,
                                                   i_lang) desc_flg_req_status_outcome,
                           eo.id_noc_outcome,
                           ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           ed.flg_req_status flg_req_status_diagnosis,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status_diagnosis,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                     INNER JOIN nnn_epis_lnk_dg_outc neldo
                        ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                       AND neldo.flg_lnk_status = pk_alert_constant.g_active
                     INNER JOIN nnn_epis_outcome eo
                        ON neldo.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE ed.id_patient = i_patient
                       AND ed.id_episode = l_episode
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                       AND eo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                                 pk_nnn_constant.g_req_status_ordered,
                                                 pk_nnn_constant.g_req_status_ongoing,
                                                 pk_nnn_constant.g_req_status_suspended,
                                                 pk_nnn_constant.g_req_status_finished)
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              outcome_name,
                              diagnosis_name;
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit             
                OPEN o_outcome FOR
                    SELECT eo.id_nnn_epis_outcome,
                           pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                         i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                                                        i_prof                  => i_prof,
                                                                                                        i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                                                        i_use_html_format       => pk_alert_constant.g_yes)) outcome_definition,
                           eo.flg_req_status flg_req_status_outcome,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                   eo.flg_req_status,
                                                   i_lang) desc_flg_req_status_outcome,
                           eo.id_noc_outcome,
                           ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           ed.flg_req_status flg_req_status_diagnosis,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status_diagnosis,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                     INNER JOIN nnn_epis_lnk_dg_outc neldo
                        ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                       AND neldo.flg_lnk_status = pk_alert_constant.g_active
                     INNER JOIN nnn_epis_outcome eo
                        ON neldo.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE ed.id_patient = i_patient
                       AND ed.id_visit = l_visit
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                       AND eo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                                 pk_nnn_constant.g_req_status_ordered,
                                                 pk_nnn_constant.g_req_status_ongoing,
                                                 pk_nnn_constant.g_req_status_suspended,
                                                 pk_nnn_constant.g_req_status_finished)
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              outcome_name,
                              diagnosis_name;
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient                           
                OPEN o_outcome FOR
                    SELECT eo.id_nnn_epis_outcome,
                           pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome,
                                                         i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => get_epis_outcome_eval_abstract(i_lang                  => i_lang,
                                                                                                        i_prof                  => i_prof,
                                                                                                        i_nnn_epis_outcome_eval => leoe.id_nnn_epis_outcome_eval,
                                                                                                        i_use_html_format       => pk_alert_constant.g_yes)) outcome_definition,
                           eo.flg_req_status flg_req_status_outcome,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                   eo.flg_req_status,
                                                   i_lang) desc_flg_req_status_outcome,
                           eo.id_noc_outcome,
                           ed.id_nnn_epis_diagnosis,
                           pk_nan_model.get_nan_diagnosis_name(i_nan_diagnosis   => ed.id_nan_diagnosis,
                                                               i_code_format     => pk_nan_model.g_code_format_end,
                                                               i_additional_info => ed.edited_diagnosis_name) diagnosis_name,
                           ed.flg_req_status flg_req_status_diagnosis,
                           pk_sysdomain.get_domain(pk_nnn_constant.g_dom_epis_diag_flg_req_status,
                                                   ed.flg_req_status,
                                                   i_lang) desc_flg_req_status_diagnosis,
                           ed.id_nan_diagnosis
                      FROM nnn_epis_diagnosis ed
                     INNER JOIN nnn_epis_lnk_dg_outc neldo
                        ON ed.id_nnn_epis_diagnosis = neldo.id_nnn_epis_diagnosis
                       AND neldo.flg_lnk_status = pk_alert_constant.g_active
                     INNER JOIN nnn_epis_outcome eo
                        ON neldo.id_nnn_epis_outcome = eo.id_nnn_epis_outcome
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_diag_eval(i_nnn_epis_diagnosis => ed.id_nnn_epis_diagnosis)) lede
                        ON ed.id_nnn_epis_diagnosis = lede.id_nnn_epis_diagnosis
                      LEFT JOIN TABLE(pk_nnn_core.tf_latest_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                        ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
                     WHERE ed.id_patient = i_patient
                       AND ed.flg_req_status IN
                           (pk_nnn_constant.g_req_status_ordered, pk_nnn_constant.g_req_status_draft)
                       AND lede.flg_status != pk_nnn_constant.g_diagnosis_status_resolved
                       AND eo.flg_req_status IN (pk_nnn_constant.g_req_status_draft,
                                                 pk_nnn_constant.g_req_status_ordered,
                                                 pk_nnn_constant.g_req_status_ongoing,
                                                 pk_nnn_constant.g_req_status_suspended,
                                                 pk_nnn_constant.g_req_status_finished)
                     ORDER BY pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_req_status,
                                                    i_val      => eo.flg_req_status),
                              pk_sysdomain.get_rank(i_lang     => i_lang,
                                                    i_code_dom => pk_nnn_constant.g_dom_epis_out_flg_priority,
                                                    i_val      => eo.flg_priority),
                              outcome_name,
                              diagnosis_name;
            ELSE
                RAISE pk_nnn_constant.e_invalid_argument;
        END CASE;
    
    EXCEPTION
        -- Log an raise the error      
        WHEN pk_nnn_constant.e_invalid_argument THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_invalid_argument', text_in => g_error);
        
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error', text_in => g_error);
    END get_pat_unresolved_outcome;

    FUNCTION is_req_final_state(i_flg_req_status IN nnn_epis_activity.flg_req_status%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN i_flg_req_status IN(pk_nnn_constant.g_req_status_finished,
                                   pk_nnn_constant.g_req_status_cancelled,
                                   pk_nnn_constant.g_req_status_discontinued,
                                   pk_nnn_constant.g_req_status_expired,
                                   pk_nnn_constant.g_req_status_ignored);
    END is_req_final_state;

    FUNCTION is_task_final_state(i_flg_status IN nnn_epis_activity_det.flg_status%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN i_flg_status IN(pk_nnn_constant.g_task_status_finished,
                               pk_nnn_constant.g_task_status_cancelled,
                               pk_nnn_constant.g_task_status_expired);
    
    END is_task_final_state;

    PROCEDURE refresh_outcome_alert
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'refresh_outcome_alert';
    
        l_error             t_error_out;
        l_dt_record         sys_alert_event.dt_record%TYPE;
        l_dt_req_start_date order_recurr_plan.start_date%TYPE;
        l_dt_next_eval      nnn_epis_outcome_eval.dt_plan%TYPE;
        l_outcome_name      pk_translation.t_desc_translation;
        l_timeout           sys_config.value%TYPE;
    BEGIN
        -- Creates an alert for the due date of next NOC Outcome evaluation.
    
        -- An alert is only applicable if the request is in the state "Ordered" or "Ongoing"
        BEGIN
            -- Retrieves the start date of the request and the date of the next planned evaluation
            SELECT /*+ opt_estimate(table leoe rows=1)*/
             pk_noc_model.get_outcome_name(i_noc_outcome => eo.id_noc_outcome) outcome_name,
             pk_nnn_core.get_start_date(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_order_recurr_plan => eo.id_order_recurr_plan) req_start_date,
             leoe.dt_plan
              INTO l_outcome_name, l_dt_req_start_date, l_dt_next_eval
            
              FROM nnn_epis_outcome eo
              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_outc_eval(i_nnn_epis_outcome => eo.id_nnn_epis_outcome)) leoe
                ON eo.id_nnn_epis_outcome = leoe.id_nnn_epis_outcome
             WHERE eo.id_nnn_epis_outcome = i_nnn_epis_outcome
               AND eo.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered);
        
        EXCEPTION
            WHEN no_data_found THEN
                -- The request is in a state that alerts aren't applicable, so if there is any, delete it
                IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => pk_nnn_constant.g_sys_alert_outcome,
                                                        i_id_record    => i_nnn_epis_outcome,
                                                        o_error        => l_error)
                THEN
                    g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                    RAISE pk_nnn_constant.e_call_error;
                END IF;
            
        END;
    
        IF l_dt_next_eval IS NOT NULL
        THEN
            l_dt_record := l_dt_next_eval;
        ELSIF l_dt_req_start_date IS NOT NULL
              AND NOT pk_nnn_core.get_outcome_has_evals(i_nnn_epis_outcome => i_nnn_epis_outcome)
        THEN
            -- When there is no next planned evaluation, checks that the request has a start date 
            -- and uses it if this outcome do not yet have evaluations
            l_dt_record := l_dt_req_start_date;
        END IF;
    
        IF l_dt_record IS NOT NULL
        THEN
            -- There is an alert to save
        
            -- Past due X minutes
            l_timeout := pk_sysconfig.get_config(i_code_cf => pk_nnn_constant.g_config_alert_task_timeout,
                                                 i_prof    => i_prof);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => pk_nnn_constant.g_sys_alert_outcome,
                                                    i_id_episode          => i_episode,
                                                    i_id_record           => i_nnn_epis_outcome,
                                                    i_dt_record           => l_dt_record,
                                                    i_id_professional     => i_prof.id,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => l_outcome_name,
                                                    i_replace2            => l_timeout,
                                                    o_error               => l_error)
            THEN
                g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                RAISE pk_nnn_constant.e_call_error;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        
    END refresh_outcome_alert;

    PROCEDURE refresh_indicator_alert
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'refresh_indicator_alert';
    
        l_error             t_error_out;
        l_dt_record         sys_alert_event.dt_record%TYPE;
        l_dt_req_start_date order_recurr_plan.start_date%TYPE;
        l_dt_next_eval      nnn_epis_ind_eval.dt_plan%TYPE;
        l_indicator_name    pk_translation.t_desc_translation;
        l_timeout           sys_config.value%TYPE;
    BEGIN
    
        -- An alert is only applicable if the request is in the state "Ordered" or "Ongoing"
        BEGIN
            -- Retrieves the start date of the request and the date of the next planned evaluation
        
            SELECT /*+ opt_estimate(table leie rows=1)*/
             pk_noc_model.get_indicator_name(i_noc_indicator => ei.id_noc_indicator) indicator_name,
             pk_nnn_core.get_start_date(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_order_recurr_plan => ei.id_order_recurr_plan) req_start_date,
             leie.dt_plan
              INTO l_indicator_name, l_dt_req_start_date, l_dt_next_eval
            
              FROM nnn_epis_indicator ei
              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_ind_eval(i_nnn_epis_indicator => ei.id_nnn_epis_indicator)) leie
                ON ei.id_nnn_epis_indicator = leie.id_nnn_epis_indicator
             WHERE ei.id_nnn_epis_indicator = i_nnn_epis_indicator
               AND ei.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered);
        
        EXCEPTION
            WHEN no_data_found THEN
                -- The request is in a state that alerts aren't applicable, so if there is any, delete it
                IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => pk_nnn_constant.g_sys_alert_indicator,
                                                        i_id_record    => i_nnn_epis_indicator,
                                                        o_error        => l_error)
                THEN
                    g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                    RAISE pk_nnn_constant.e_call_error;
                END IF;
            
        END;
    
        IF l_dt_next_eval IS NOT NULL
        THEN
            l_dt_record := l_dt_next_eval;
        ELSIF l_dt_req_start_date IS NOT NULL
              AND NOT pk_nnn_core.get_ind_has_evals(i_nnn_epis_indicator => i_nnn_epis_indicator)
        THEN
            -- When there is no next planned evaluation, checks that the request has a start date 
            -- and uses it if this indicator do not yet have evaluations
            l_dt_record := l_dt_req_start_date;
        END IF;
    
        IF l_dt_record IS NOT NULL
        THEN
            -- There is an alert to save
        
            -- Past due X minutes
            l_timeout := pk_sysconfig.get_config(i_code_cf => pk_nnn_constant.g_config_alert_task_timeout,
                                                 i_prof    => i_prof);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => pk_nnn_constant.g_sys_alert_indicator,
                                                    i_id_episode          => i_episode,
                                                    i_id_record           => i_nnn_epis_indicator,
                                                    i_dt_record           => l_dt_record,
                                                    i_id_professional     => i_prof.id,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => l_indicator_name,
                                                    i_replace2            => l_timeout,
                                                    o_error               => l_error)
            THEN
                g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                RAISE pk_nnn_constant.e_call_error;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        
    END refresh_indicator_alert;

    PROCEDURE refresh_activity_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE
    ) IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'refresh_activity_alert';
    
        l_error             t_error_out;
        l_dt_record         sys_alert_event.dt_record%TYPE;
        l_dt_req_start_date order_recurr_plan.start_date%TYPE;
        l_dt_next_exec      nnn_epis_activity_det.dt_plan%TYPE;
        l_activity_name     pk_translation.t_desc_translation;
        l_timeout           sys_config.value%TYPE;
    BEGIN
    
        -- An alert is only applicable if the request is in the state "Ordered" or "Ongoing"
        BEGIN
            -- Retrieves the start date of the request and the date of the next planned evaluation
        
            SELECT /*+ opt_estimate(table lead rows=1)*/
             pk_nic_model.get_activity_name(i_nic_activity => ea.id_nic_activity) activity_name,
             pk_nnn_core.get_start_date(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_order_recurr_plan => ea.id_order_recurr_plan) req_start_date,
             lead.dt_plan
              INTO l_activity_name, l_dt_req_start_date, l_dt_next_exec
            
              FROM nnn_epis_activity ea
              LEFT JOIN TABLE(pk_nnn_core.tf_next_nnn_epis_activ_det(i_nnn_epis_activity => ea.id_nnn_epis_activity)) lead
                ON ea.id_nnn_epis_activity = lead.id_nnn_epis_activity
             WHERE ea.id_nnn_epis_activity = i_nnn_epis_activity
               AND ea.flg_req_status IN (pk_nnn_constant.g_req_status_ongoing, pk_nnn_constant.g_req_status_ordered);
        
        EXCEPTION
            WHEN no_data_found THEN
                -- The request is in a state that alerts aren't applicable, so if there is any, delete it
                IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_id_sys_alert => pk_nnn_constant.g_sys_alert_activity,
                                                        i_id_record    => i_nnn_epis_activity,
                                                        o_error        => l_error)
                THEN
                    g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                    RAISE pk_nnn_constant.e_call_error;
                END IF;
            
        END;
    
        IF l_dt_next_exec IS NOT NULL
        THEN
            l_dt_record := l_dt_next_exec;
        ELSIF l_dt_req_start_date IS NOT NULL
              AND NOT pk_nnn_core.get_activity_has_execs(i_nnn_epis_activity => i_nnn_epis_activity)
        THEN
            -- When there is no next planned execution, checks that the request has a start date 
            -- and uses it if this activity do not yet have executions
            l_dt_record := l_dt_req_start_date;
        END IF;
    
        IF l_dt_record IS NOT NULL
        THEN
            -- There is an alert to save
        
            -- Past due X minutes
            l_timeout := pk_sysconfig.get_config(i_code_cf => pk_nnn_constant.g_config_alert_task_timeout,
                                                 i_prof    => i_prof);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => pk_nnn_constant.g_sys_alert_activity,
                                                    i_id_episode          => i_episode,
                                                    i_id_record           => i_nnn_epis_activity,
                                                    i_dt_record           => l_dt_record,
                                                    i_id_professional     => i_prof.id,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => l_activity_name,
                                                    i_replace2            => l_timeout,
                                                    o_error               => l_error)
            THEN
                g_error := 'Error found while calling PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                RAISE pk_nnn_constant.e_call_error;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN pk_nnn_constant.e_call_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        
    END refresh_activity_alert;

    PROCEDURE calculate_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_start_date         IN nnn_epis_activity_det.dt_val_time_start%TYPE,
        i_duration           IN pk_types.t_med_num,
        i_unit_meas_duration IN nic_cfg_activity.id_unit_measure_duration%TYPE,
        i_end_date           IN nnn_epis_activity_det.dt_val_time_end%TYPE,
        o_start_date         OUT nnn_epis_activity_det.dt_val_time_start%TYPE,
        o_duration           OUT pk_types.t_med_num,
        o_duration_desc      OUT pk_types.t_big_byte,
        o_unit_meas_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE,
        o_end_date           OUT nnn_epis_activity_det.dt_val_time_end%TYPE
    ) IS
        l_start_date    nnn_epis_activity_det.dt_val_time_start%TYPE;
        l_end_date      nnn_epis_activity_det.dt_val_time_end%TYPE;
        l_duration      nic_cfg_activity.avg_duration%TYPE;
        l_uom           nic_cfg_activity.id_unit_measure_duration%TYPE;
        l_duration_desc pk_types.t_big_byte;
        l_days          NUMBER;
        l_hours         NUMBER;
        l_minutes       NUMBER;
        l_seconds       NUMBER;
    
        l_error t_error_out;
    BEGIN
        IF i_start_date IS NOT NULL
        THEN
            -- Truncate to minutes
            l_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => i_start_date,
                                                             i_format    => k_minute_format);
        ELSE
            -- The i_start_date value is mandatory as basis for arithmetic operations with timestamps
            g_error := 'Invalid input parameter: i_start_date cannot be NULL';
            RAISE pk_nnn_constant.e_invalid_argument;
        END IF;
    
        CASE
            WHEN i_duration IS NOT NULL
                 AND i_unit_meas_duration IS NOT NULL THEN
                -- Calculates end_date
                l_duration := i_duration;
                l_uom      := i_unit_meas_duration;
                l_end_date := pk_order_recurrence_core.add_offset_to_tstz(i_offset    => l_duration,
                                                                          i_timestamp => l_start_date,
                                                                          i_unit      => l_uom);
            
            WHEN i_end_date IS NOT NULL THEN
                -- Calculates duration
            
                l_duration := NULL;
                -- Truncate to minutes
                l_end_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                               i_timestamp => i_end_date,
                                                               i_format    => k_minute_format);
            
                g_error := 'Analysing date interval window';
                IF l_start_date > l_end_date
                THEN
                    g_error := 'Starting date cannot be greater than the ending date';
                    RAISE pk_nnn_constant.e_invalid_argument;
                END IF;
            
                -- Retrieves the differences 
                IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                            i_timestamp_1 => i_end_date,
                                                            i_timestamp_2 => i_start_date,
                                                            o_days        => l_days,
                                                            o_hours       => l_hours,
                                                            o_minutes     => l_minutes,
                                                            o_seconds     => l_seconds,
                                                            o_error       => l_error)
                THEN
                
                    g_error := 'Error found while calling PK_DATE_UTILS.GET_TIMESTAMP_DIFF_SEP';
                    RAISE pk_nnn_constant.e_call_error;
                END IF;
            
                CASE
                    WHEN l_days > 0
                         AND l_hours = 0
                         AND l_minutes = 0 THEN
                        l_duration := l_days;
                        l_uom      := pk_order_recurrence_core.g_unit_measure_day;
                    WHEN l_days = 0
                         AND l_hours > 0
                         AND l_minutes = 0 THEN
                        l_duration := l_hours;
                        l_uom      := pk_order_recurrence_core.g_unit_measure_hour;
                    ELSE
                        l_duration := l_days * 1200 + l_hours * 60 + l_minutes;
                        l_uom      := pk_order_recurrence_core.g_unit_measure_minute;
                    
                END CASE;
            
            ELSE
                l_duration := 0;
                l_uom      := pk_order_recurrence_core.g_unit_measure_minute;
                l_end_date := l_start_date;
        END CASE;
    
        -- Format duration as string including the unit of measure
        l_duration_desc := l_duration || ' ' ||
                           pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_unit_measure => l_uom);
    
        -- Set output parameters with the calculated values
        o_start_date         := l_start_date;
        o_duration           := l_duration;
        o_unit_meas_duration := l_uom;
        o_end_date           := l_end_date;
        o_duration_desc      := l_duration_desc;
    
    END calculate_duration;

    FUNCTION get_epis_nic_actv_det_task_h
    (
        i_nnn_epis_activity_det IN nnn_epis_actv_det_tskh.id_nnn_epis_activity_det%TYPE,
        i_dt_trs_time_start     IN nnn_epis_actv_det_tskh.dt_trs_time_start%TYPE
    ) RETURN t_coll_obj_nnn_epis_actv_tsk IS
        l_lst_activity_task t_coll_obj_nnn_epis_actv_tsk;
    BEGIN
        /*  
         This method fetches activity tasks documented in a given execution at a given date
         allowing in the executions that were edited several times be able to obtain which the tasks that were documented at that point in time.
        
         These two queries in the union should be mutually exclusive and only one returns data; 
         The data of a documented execution in a specific time (i_dt_trs_time_start) or is the current record 
         or is a past record that is stored in the historic (but cannot be in both).
        */
    
        SELECT t_obj_nnn_epis_activity_task(i_id_nic_activity => x.id_nic_activity,
                                            i_activity_name   => x.activity_name,
                                            i_flg_executed    => x.flg_executed,
                                            i_notes           => x.notes)
          BULK COLLECT
          INTO l_lst_activity_task
          FROM (
                -- Historical data
                SELECT eadth.id_nic_activity,
                        pk_nic_model.get_activity_name(i_nic_activity => eadth.id_nic_activity) activity_name,
                        eadth.flg_executed,
                        eadth.notes
                  FROM nnn_epis_actv_det_tskh eadth
                 INNER JOIN nnn_epis_activity_det ead
                    ON ead.id_nnn_epis_activity_det = eadth.id_nnn_epis_activity_det
                 WHERE eadth.id_nnn_epis_activity_det = i_nnn_epis_activity_det
                   AND eadth.dt_trs_time_start = i_dt_trs_time_start
                UNION ALL
                -- Current data
                SELECT eadt.id_nic_activity,
                        pk_nic_model.get_activity_name(i_nic_activity => eadt.id_nic_activity) activity_name,
                        eadt.flg_executed,
                        pk_translation.get_translation_trs(eadt.code_notes)
                  FROM nnn_epis_actv_det_task eadt
                 INNER JOIN nnn_epis_activity_det ead
                    ON ead.id_nnn_epis_activity_det = eadt.id_nnn_epis_activity_det
                 WHERE ead.id_nnn_epis_activity_det = i_nnn_epis_activity_det
                   AND ead.dt_trs_time_start = i_dt_trs_time_start) x
         ORDER BY x.activity_name;
    
        RETURN l_lst_activity_task;
    END get_epis_nic_actv_det_task_h;

    FUNCTION set_match_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_match_episode';
        l_rowids table_varchar;
        l_visit  visit.id_visit%TYPE;
    BEGIN
        g_error := 'Get visit id associated with episode';
        l_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        -- Nursing NANDA Diagnosis
        -- nnn_epis_diagnosis 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis.upd id_visit/id_episode';
        ts_nnn_epis_diagnosis.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  id_visit_in    => l_visit,
                                  id_visit_nin   => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- nnn_epis_diagnosis_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis_h.upd id_visit/id_episode';
        ts_nnn_epis_diagnosis_h.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    id_visit_in    => l_visit,
                                    id_visit_nin   => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Nursing NANDA Diagnosis evaluations
        -- nnn_epis_diag_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval.upd id_visit/id_episode';
        ts_nnn_epis_diag_eval.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  id_visit_in    => l_visit,
                                  id_visit_nin   => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
        -- nnn_epis_diag_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval_h.upd id_visit/id_episode';
        ts_nnn_epis_diag_eval_h.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    id_visit_in    => l_visit,
                                    id_visit_nin   => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Nursing NOC Outcome
        -- nnn_epis_outcome 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome.upd id_visit/id_episode';
        ts_nnn_epis_outcome.upd(id_episode_in  => i_episode,
                                id_episode_nin => FALSE,
                                id_visit_in    => l_visit,
                                id_visit_nin   => FALSE,
                                where_in       => 'id_episode = ' || i_episode_temp,
                                rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome.upd id_episode_origin';
        ts_nnn_epis_outcome.upd(id_episode_origin_in => i_episode,
                                id_episode_nin       => FALSE,
                                where_in             => 'id_episode_origin = ' || i_episode_temp,
                                rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome.upd id_episode_destination';
        ts_nnn_epis_outcome.upd(id_episode_destination_in  => i_episode,
                                id_episode_destination_nin => FALSE,
                                where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
        -- nnn_epis_outcome_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_h.upd id_visit/id_episode';
        ts_nnn_epis_outcome_h.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  id_visit_in    => l_visit,
                                  id_visit_nin   => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome_h.upd id_episode_origin';
        ts_nnn_epis_outcome_h.upd(id_episode_origin_in => i_episode,
                                  id_episode_nin       => FALSE,
                                  where_in             => 'id_episode_origin = ' || i_episode_temp,
                                  rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome_h.upd id_episode_destination';
        ts_nnn_epis_outcome_h.upd(id_episode_destination_in  => i_episode,
                                  id_episode_destination_nin => FALSE,
                                  where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                  rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
    
        -- Nursing NOC Outcome evaluations
        -- nnn_epis_outcome_eval 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval.upd id_visit/id_episode';
        ts_nnn_epis_outcome_eval.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     id_visit_in    => l_visit,
                                     id_visit_nin   => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
        -- nnn_epis_outcome_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval_h.upd id_visit/id_episode';
        ts_nnn_epis_outcome_eval_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       id_visit_in    => l_visit,
                                       id_visit_nin   => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Nursing NOC Indicator
        -- nnn_epis_indicator
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator.upd id_visit/id_episode';
        ts_nnn_epis_indicator.upd(id_episode_in  => i_episode,
                                  id_episode_nin => FALSE,
                                  id_visit_in    => l_visit,
                                  id_visit_nin   => FALSE,
                                  where_in       => 'id_episode = ' || i_episode_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator.upd id_episode_origin';
        ts_nnn_epis_indicator.upd(id_episode_origin_in => i_episode,
                                  id_episode_nin       => FALSE,
                                  where_in             => 'id_episode_origin = ' || i_episode_temp,
                                  rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator.upd id_episode_destination';
        ts_nnn_epis_indicator.upd(id_episode_destination_in  => i_episode,
                                  id_episode_destination_nin => FALSE,
                                  where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                  rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
    
        -- nnn_epis_indicator_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator_h.upd id_visit/id_episode';
        ts_nnn_epis_indicator_h.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    id_visit_in    => l_visit,
                                    id_visit_nin   => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator_h.upd id_episode_origin';
        ts_nnn_epis_indicator_h.upd(id_episode_origin_in => i_episode,
                                    id_episode_nin       => FALSE,
                                    where_in             => 'id_episode_origin = ' || i_episode_temp,
                                    rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator_h.upd id_episode_destination';
        ts_nnn_epis_indicator_h.upd(id_episode_destination_in  => i_episode,
                                    id_episode_destination_nin => FALSE,
                                    where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                    rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
    
        -- Nursing NOC Indicator evaluations
        -- nnn_epis_ind_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval.upd id_visit/id_episode';
        ts_nnn_epis_ind_eval.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 id_visit_in    => l_visit,
                                 id_visit_nin   => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
        -- nnn_epis_ind_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval_h.upd id_visit/id_episode';
        ts_nnn_epis_ind_eval_h.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   id_visit_in    => l_visit,
                                   id_visit_nin   => FALSE,
                                   where_in       => 'id_episode = ' || i_episode_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Nursing NIC Intervention
        -- nnn_epis_intervention
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention.upd id_visit/id_episode';
        ts_nnn_epis_intervention.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     id_visit_in    => l_visit,
                                     id_visit_nin   => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
        -- nnn_epis_intervention_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention_h.upd id_visit/id_episode';
        ts_nnn_epis_intervention_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       id_visit_in    => l_visit,
                                       id_visit_nin   => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Nursing NIC Activity
        -- nnn_epis_activity 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity.upd id_visit/id_episode';
        ts_nnn_epis_activity.upd(id_episode_in  => i_episode,
                                 id_episode_nin => FALSE,
                                 id_visit_in    => l_visit,
                                 id_visit_nin   => FALSE,
                                 where_in       => 'id_episode = ' || i_episode_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity.upd id_episode_origin';
        ts_nnn_epis_activity.upd(id_episode_origin_in => i_episode,
                                 id_episode_nin       => FALSE,
                                 where_in             => 'id_episode_origin = ' || i_episode_temp,
                                 rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity.upd id_episode_destination';
        ts_nnn_epis_activity.upd(id_episode_destination_in  => i_episode,
                                 id_episode_destination_nin => FALSE,
                                 where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                 rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
        -- nnn_epis_activity_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_h.upd id_visit/id_episode';
        ts_nnn_epis_activity_h.upd(id_episode_in  => i_episode,
                                   id_episode_nin => FALSE,
                                   id_visit_in    => l_visit,
                                   id_visit_nin   => FALSE,
                                   where_in       => 'id_episode = ' || i_episode_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity_h.upd id_episode_origin';
        ts_nnn_epis_activity_h.upd(id_episode_origin_in => i_episode,
                                   id_episode_nin       => FALSE,
                                   where_in             => 'id_episode_origin = ' || i_episode_temp,
                                   rows_out             => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity_h.upd id_episode_destination';
        ts_nnn_epis_activity_h.upd(id_episode_destination_in  => i_episode,
                                   id_episode_destination_nin => FALSE,
                                   where_in                   => 'id_episode_destination = ' || i_episode_temp,
                                   rows_out                   => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT',
                                                                      'ID_EPISODE',
                                                                      'ID_EPISODE_ORIGIN',
                                                                      'ID_EPISODE_DESTINATION'));
    
        -- Nursing NIC Activity executions
        -- nnn_epis_activity_det
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det.upd id_visit/id_episode';
        ts_nnn_epis_activity_det.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     id_visit_in    => l_visit,
                                     id_visit_nin   => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- nnn_epis_activity_det_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det_h.upd id_visit/id_episode';
        ts_nnn_epis_activity_det_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       id_visit_in    => l_visit,
                                       id_visit_nin   => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_VISIT', 'ID_EPISODE'));
    
        -- Linkages Diagnosis / Outcome
        -- nnn_epis_lnk_dg_outc 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_dg_outc.upd id_episode';
        ts_nnn_epis_lnk_dg_outc.upd(id_episode_in  => i_episode,
                                    id_episode_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_episode_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_DG_OUTC';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_DG_OUTC',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- nnn_epis_lnk_dg_outc_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_dg_outc_h.upd id_episode';
        ts_nnn_epis_lnk_dg_outc_h.upd(id_episode_in  => i_episode,
                                      id_episode_nin => FALSE,
                                      where_in       => 'id_episode = ' || i_episode_temp,
                                      rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_DG_OUTC_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_DG_OUTC_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- Linkages Diagnosis / Intervention
        -- nnn_epis_lnk_dg_intrv
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_dg_intrv.upd id_episode';
        ts_nnn_epis_lnk_dg_intrv.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_DG_INTRV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_DG_INTRV',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- nnn_epis_lnk_dg_intrv_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_dg_intrv_h.upd id_episode';
        ts_nnn_epis_lnk_dg_intrv_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_DG_INTRV_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_DG_INTRV_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- Linkages Outcome / Indicator
        -- nnn_epis_lnk_outc_ind
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_outc_ind.upd id_episode';
        ts_nnn_epis_lnk_outc_ind.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_OUTC_IND';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_OUTC_IND',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        -- nnn_epis_lnk_outc_ind_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_outc_ind_h.upd id_episode';
        ts_nnn_epis_lnk_outc_ind_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_OUTC_IND_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_OUTC_IND_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        -- Linkages Intervention / Activity
        -- nnn_epis_lnk_int_actv 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_int_actv.upd id_episode';
        ts_nnn_epis_lnk_int_actv.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_INT_ACTV';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_INT_ACTV',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
        -- nnn_epis_lnk_int_actv_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_lnk_int_actv_h.upd id_episode';
        ts_nnn_epis_lnk_int_actv_h.upd(id_episode_in  => i_episode,
                                       id_episode_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_episode_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_LNK_INT_ACTV_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_LNK_INT_ACTV_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END set_match_episode;

    FUNCTION set_match_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_temp IN patient.id_patient%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_match_patient';
        l_rowids table_varchar;
    BEGIN
    
        -- Nursing NANDA Diagnosis
        -- nnn_epis_diagnosis 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis.upd id_patient';
        ts_nnn_epis_diagnosis.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_patient = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_diagnosis_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis_h.upd id_patient';
        ts_nnn_epis_diagnosis_h.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NANDA Diagnosis evaluations
        -- nnn_epis_diag_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval.upd id_patient';
        ts_nnn_epis_diag_eval.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_patient = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_diag_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval_h.upd id_patient';
        ts_nnn_epis_diag_eval_h.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Outcome
        -- nnn_epis_outcome 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome.upd id_patient';
        ts_nnn_epis_outcome.upd(id_patient_in  => i_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_patient = ' || i_patient_temp,
                                rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_outcome_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_h.upd id_patient';
        ts_nnn_epis_outcome_h.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_patient = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Outcome evaluations
        -- nnn_epis_outcome_eval 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval.upd id_patient';
        ts_nnn_epis_outcome_eval.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_patient = ' || i_patient_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_outcome_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval_h.upd id_patient';
        ts_nnn_epis_outcome_eval_h.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_patient = ' || i_patient_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Indicator
        -- nnn_epis_indicator
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator.upd id_patient';
        ts_nnn_epis_indicator.upd(id_patient_in  => i_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_patient = ' || i_patient_temp,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_indicator_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator_h.upd id_patient';
        ts_nnn_epis_indicator_h.upd(id_patient_in  => i_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_patient = ' || i_patient_temp,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Indicator evaluations
        -- nnn_epis_ind_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval.upd id_patient';
        ts_nnn_epis_ind_eval.upd(id_patient_in  => i_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_patient = ' || i_patient_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_ind_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval_h.upd id_patient';
        ts_nnn_epis_ind_eval_h.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Intervention
        -- nnn_epis_intervention
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention.upd id_patient';
        ts_nnn_epis_intervention.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_patient = ' || i_patient_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_intervention_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention_h.upd id_patient';
        ts_nnn_epis_intervention_h.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_patient = ' || i_patient_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Activity
        -- nnn_epis_activity 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity.upd id_patient';
        ts_nnn_epis_activity.upd(id_patient_in  => i_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_patient = ' || i_patient_temp,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_activity_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_h.upd id_patient';
        ts_nnn_epis_activity_h.upd(id_patient_in  => i_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_patient = ' || i_patient_temp,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Activity executions
        -- nnn_epis_activity_det
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det.upd id_patient';
        ts_nnn_epis_activity_det.upd(id_patient_in  => i_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_patient = ' || i_patient_temp,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_activity_det_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det_h.upd id_patient';
        ts_nnn_epis_activity_det_h.upd(id_patient_in  => i_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_patient = ' || i_patient_temp,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END set_match_patient;

    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'set_episode_new_patient';
        l_rowids table_varchar;
    BEGIN
    
        -- Nursing NANDA Diagnosis
        -- nnn_epis_diagnosis 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis.upd id_patient';
        ts_nnn_epis_diagnosis.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_diagnosis_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diagnosis_h.upd id_patient';
        ts_nnn_epis_diagnosis_h.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAGNOSIS_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAGNOSIS_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NANDA Diagnosis evaluations
        -- nnn_epis_diag_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval.upd id_patient';
        ts_nnn_epis_diag_eval.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_diag_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_diag_eval_h.upd id_patient';
        ts_nnn_epis_diag_eval_h.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_DIAG_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_DIAG_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Outcome
        -- nnn_epis_outcome 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome.upd id_patient';
        ts_nnn_epis_outcome.upd(id_patient_in  => i_new_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode = ' || i_old_episode,
                                rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_outcome.upd(id_patient_in  => i_new_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode_origin = ' || i_old_episode,
                                rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_outcome.upd(id_patient_in  => i_new_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode_destination = ' || i_old_episode,
                                rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_outcome_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_h.upd id_patient';
        ts_nnn_epis_outcome_h.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome_h.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_outcome_h.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode_origin = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_outcome_h.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_outcome_h.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode_destination = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Outcome evaluations
        -- nnn_epis_outcome_eval 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval.upd id_patient';
        ts_nnn_epis_outcome_eval.upd(id_patient_in  => i_new_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_old_episode,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_outcome_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_outcome_eval_h.upd id_patient';
        ts_nnn_epis_outcome_eval_h.upd(id_patient_in  => i_new_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_old_episode,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_OUTCOME_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_OUTCOME_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Indicator
        -- nnn_epis_indicator
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator.upd id_patient';
        ts_nnn_epis_indicator.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_indicator.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode_origin = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_indicator.upd(id_patient_in  => i_new_patient,
                                  id_patient_nin => FALSE,
                                  where_in       => 'id_episode_destination = ' || i_old_episode,
                                  rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_indicator_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_indicator_h.upd id_patient';
        ts_nnn_epis_indicator_h.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator_h.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_indicator_h.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode_origin = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_indicator_h.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_indicator_h.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode_destination = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INDICATOR_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INDICATOR_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NOC Indicator evaluations
        -- nnn_epis_ind_eval
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval.upd id_patient';
        ts_nnn_epis_ind_eval.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_old_episode,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_ind_eval_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_ind_eval_h.upd id_patient';
        ts_nnn_epis_ind_eval_h.upd(id_patient_in  => i_new_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_old_episode,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_IND_EVAL_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_IND_EVAL_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Intervention
        -- nnn_epis_intervention
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention.upd id_patient';
        ts_nnn_epis_intervention.upd(id_patient_in  => i_new_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_old_episode,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_intervention_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_intervention_h.upd id_patient';
        ts_nnn_epis_intervention_h.upd(id_patient_in  => i_new_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_old_episode,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_INTERVENTION_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_INTERVENTION_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Activity
        -- nnn_epis_activity 
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity.upd id_patient';
        ts_nnn_epis_activity.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_old_episode,
                                 rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_activity.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode_origin = ' || i_old_episode,
                                 rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_activity.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode_destination = ' || i_old_episode,
                                 rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        -- nnn_epis_activity_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_h.upd id_patient';
        ts_nnn_epis_activity_h.upd(id_patient_in  => i_new_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_old_episode,
                                   rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity_h.upd id_patient (by id_episode_origin)';
        ts_nnn_epis_activity_h.upd(id_patient_in  => i_new_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode_origin = ' || i_old_episode,
                                   rows_out       => l_rowids);
    
        g_error := 'Call ts_nnn_epis_activity_h.upd id_patient (by id_episode_destination)';
        ts_nnn_epis_activity_h.upd(id_patient_in  => i_new_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode_destination = ' || i_old_episode,
                                   rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- Nursing NIC Activity executions
        -- nnn_epis_activity_det
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det.upd id_patient';
        ts_nnn_epis_activity_det.upd(id_patient_in  => i_new_patient,
                                     id_patient_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_old_episode,
                                     rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        -- nnn_epis_activity_det_h
        l_rowids := table_varchar();
        g_error  := 'Call ts_nnn_epis_activity_det_h.upd id_patient';
        ts_nnn_epis_activity_det_h.upd(id_patient_in  => i_new_patient,
                                       id_patient_nin => FALSE,
                                       where_in       => 'id_episode = ' || i_old_episode,
                                       rows_out       => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update NNN_EPIS_ACTIVITY_DET_H';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'NNN_EPIS_ACTIVITY_DET_H',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END set_episode_new_patient;

    FUNCTION inactivate_nnn_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'NNN_INACTIVATE');
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_activity_req  table_number;
        l_outcome_req   table_number;
        l_indicator_req table_number;
    
        l_activity_status  table_varchar;
        l_outcome_status   table_varchar;
        l_indicator_status table_varchar;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_msg_error VARCHAR2(200 CHAR);
    
        CURSOR c_nnn_activity_req IS
            SELECT nep.id_nnn_epis_activity, cfg.field_04
              FROM nnn_epis_activity nep
             INNER JOIN nnn_epis_activity_det nepd
                ON nep.id_nnn_epis_activity = nepd.id_nnn_epis_activity
             INNER JOIN episode e
                ON e.id_episode = nep.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = nep.flg_req_status
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND prev_e.id_episode IS NULL
               AND trunc(pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                    i_amount    => cfg.field_02,
                                                    i_unit      => cfg.field_03)) >= trunc(current_timestamp)
               AND rownum <= l_max_rows;
    
        CURSOR c_nnn_outcome_req IS
            SELECT neo.id_nnn_epis_outcome, cfg.field_04
              FROM nnn_epis_outcome neo
             INNER JOIN episode e
                ON e.id_episode = neo.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = neo.flg_req_status
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND prev_e.id_episode IS NULL
               AND trunc(pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                    i_amount    => cfg.field_02,
                                                    i_unit      => cfg.field_03)) >= trunc(current_timestamp)
               AND rownum <= l_max_rows;
    
        CURSOR c_nnn_indicator_req IS
            SELECT nei.id_nnn_epis_indicator, cfg.field_04
              FROM nnn_epis_indicator nei
             INNER JOIN episode e
                ON e.id_episode = nei.id_episode
              LEFT JOIN episode prev_e
                ON prev_e.id_prev_episode = e.id_episode
               AND e.id_visit = prev_e.id_visit
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          *
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = nei.flg_req_status
             WHERE e.id_institution = i_inst
               AND e.dt_end_tstz IS NOT NULL
               AND prev_e.id_episode IS NULL
               AND trunc(pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                    i_amount    => cfg.field_02,
                                                    i_unit      => cfg.field_03)) >= trunc(current_timestamp)
               AND rownum <= l_max_rows;
    
    BEGIN
    
        o_has_error := FALSE;
    
        OPEN c_nnn_activity_req;
        FETCH c_nnn_activity_req BULK COLLECT
            INTO l_activity_req, l_activity_status;
        CLOSE c_nnn_activity_req;
    
        l_max_rows := l_max_rows - l_activity_req.count;
    
        IF l_max_rows < 0
        THEN
            l_max_rows := 0;
        END IF;
    
        OPEN c_nnn_outcome_req;
        FETCH c_nnn_outcome_req BULK COLLECT
            INTO l_outcome_req, l_outcome_status;
        CLOSE c_nnn_outcome_req;
    
        l_max_rows := l_max_rows - l_outcome_req.count;
    
        IF l_max_rows < 0
        THEN
            l_max_rows := 0;
        END IF;
    
        OPEN c_nnn_indicator_req;
        FETCH c_nnn_indicator_req BULK COLLECT
            INTO l_indicator_req, l_indicator_status;
        CLOSE c_nnn_indicator_req;
    
        IF l_activity_req.count > 0
        THEN
            FOR i IN 1 .. l_activity_req.count
            LOOP
                IF l_activity_status(i) = pk_nnn_constant.g_req_status_cancelled
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_nic_activity(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_nnn_epis_activity => l_activity_req(i),
                                                             i_cancel_reason     => l_cancel_id,
                                                             i_flg_req_status    => pk_nnn_constant.g_req_status_cancelled);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NIC_ACTIVITY FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            
                IF l_activity_status(i) = pk_nnn_constant.g_req_status_discontinued
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_nic_activity(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_nnn_epis_activity => l_activity_req(i),
                                                             i_cancel_reason     => l_descontinued_id,
                                                             i_flg_req_status    => pk_nnn_constant.g_req_status_discontinued);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NIC_ACTIVITY FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            END LOOP;
        END IF;
    
        IF l_outcome_req.count > 0
        THEN
            FOR i IN 1 .. l_outcome_req.count
            LOOP
                IF l_outcome_status(i) = pk_nnn_constant.g_req_status_cancelled
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_noc_outcome(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_nnn_epis_outcome => l_outcome_req(i),
                                                            i_cancel_reason    => l_cancel_id,
                                                            i_flg_req_status   => pk_nnn_constant.g_req_status_cancelled);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NOC_OUTCOME FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            
                IF l_outcome_status(i) = pk_nnn_constant.g_req_status_discontinued
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_noc_outcome(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_nnn_epis_outcome => l_outcome_req(i),
                                                            i_cancel_reason    => l_descontinued_id,
                                                            i_flg_req_status   => pk_nnn_constant.g_req_status_discontinued);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NOC_OUTCOME FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            END LOOP;
        END IF;
    
        IF l_indicator_req.count > 0
        THEN
            FOR i IN 1 .. l_indicator_req.count
            LOOP
            
                IF l_indicator_status(i) = pk_nnn_constant.g_req_status_cancelled
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_noc_indicator(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_nnn_epis_indicator => l_indicator_req(i),
                                                              i_cancel_reason      => l_cancel_id,
                                                              i_flg_req_status     => pk_nnn_constant.g_req_status_cancelled);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NIC_ACTIVITY FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            
                IF l_indicator_status(i) = pk_nnn_constant.g_req_status_discontinued
                THEN
                    BEGIN
                        SAVEPOINT init_cancel;
                        pk_nnn_core.cancel_epis_noc_indicator(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_nnn_epis_indicator => l_indicator_req(i),
                                                              i_cancel_reason      => l_descontinued_id,
                                                              i_flg_req_status     => pk_nnn_constant.g_req_status_discontinued);
                    EXCEPTION
                        WHEN OTHERS THEN
                            ROLLBACK TO init_cancel;
                        
                            o_has_error := TRUE;
                        
                            pk_alert_exceptions.reset_error_state;
                            g_error := 'ERROR CALLING PK_NNN_CORE.CANCEL_EPIS_NIC_ACTIVITY FOR RECORD ' ||
                                       l_activity_req(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              g_error,
                                                              g_owner,
                                                              g_package,
                                                              'INACTIVATE_NNN_TASKS',
                                                              o_error);
                        
                            CONTINUE;
                    END;
                END IF;
            END LOOP;
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
                                              i_function => 'INACTIVATE_NNN_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
    END inactivate_nnn_tasks;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nnn_core;
/
