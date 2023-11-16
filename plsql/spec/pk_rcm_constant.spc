/*-- Last Change Revision: $Rev: 1367007 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2012-08-29 12:01:04 +0100 (qua, 29 ago 2012) $*/

CREATE OR REPLACE PACKAGE pk_rcm_constant IS

    SUBTYPE t_big_byte IS VARCHAR2(4000);
    SUBTYPE t_hug_byte IS VARCHAR2(32700);

    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0500 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0100 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    SUBTYPE t_timestamp IS TIMESTAMP(6)
        WITH LOCAL TIME ZONE;

    SUBTYPE t_msg_char IS VARCHAR2(0255 BYTE);

    SUBTYPE t_low_num IS NUMBER(06);
    SUBTYPE t_med_num IS NUMBER(12);
    SUBTYPE t_big_num IS NUMBER(24);

    TYPE t_ibt_desc_value IS TABLE OF t_big_char INDEX BY t_big_char;
    TYPE t_ibt_large_desc_value IS TABLE OF CLOB INDEX BY t_big_char;

    TYPE t_rec_rcm_rule IS RECORD(
        id_rcm       rcm_rule_inst_rcm.id_rcm%TYPE,
        id_rcm_rule  rcm_rule_inst_rcm.id_rcm_rule%TYPE,
        id_rule_inst rcm_rule_inst_rcm.id_rule_inst%TYPE,
        rule_query   rcm_rule.rule_query%TYPE);

    TYPE t_cur_rcm_rule IS REF CURSOR RETURN t_rec_rcm_rule;
    TYPE t_coll_rcm_rule IS TABLE OF t_rec_rcm_rule;

    TYPE t_rec_rcm_info IS RECORD(
        id_rcm           pat_rcm_det.id_rcm%TYPE,
        id_rcm_det       pat_rcm_det.id_rcm_det%TYPE,
        id_rcm_det_h     pat_rcm_h.id_rcm_det_h%TYPE,
        rcm_summ         pk_translation.t_desc_translation,
        rcm_desc         pk_translation.t_desc_translation,
        rcm_type_desc    pk_translation.t_desc_translation,
        id_workflow      pat_rcm_h.id_workflow%TYPE,
        id_status        pat_rcm_h.id_status%TYPE,
        status_desc      pk_translation.t_desc_translation,
        dt_status_tstz   pat_rcm_h.dt_status%TYPE,
        dt_status        VARCHAR2(100 CHAR),
        dt_status_chr    VARCHAR2(100 CHAR),
        prof_name_status VARCHAR2(1000 CHAR),
        prof_spec_status VARCHAR2(1000 CHAR),
        rcm_notes        pat_rcm_h.notes%TYPE,
        rcm_text         pat_rcm_det.rcm_text%TYPE);

    TYPE t_cur_rcm_info IS REF CURSOR RETURN t_rec_rcm_info;
    TYPE t_coll_rcm_info IS TABLE OF t_rec_rcm_info;

    -- differences
    TYPE t_rec_rcm_info_diff IS RECORD(
        dt_status    pat_rcm_h.dt_status%TYPE,
        id_rcm_det_h pat_rcm_h.id_rcm_det_h%TYPE,
        status_old   pk_translation.t_desc_translation,
        status_new   pk_translation.t_desc_translation,
        rcm_notes    pat_rcm_h.notes%TYPE,
        documented   VARCHAR2(1000 CHAR));

    TYPE t_coll_rcm_info_diff IS TABLE OF t_rec_rcm_info_diff;

    g_limit CONSTANT PLS_INTEGER := 1000;

    -- RCM ORIGIN
    g_orig_rcm_rcm     CONSTANT rcm_orig.id_rcm_orig%TYPE := 100; -- RCM
    g_orig_rcm_cdr     CONSTANT rcm_orig.id_rcm_orig%TYPE := 200; -- CDR    
    g_orig_value_noval CONSTANT pat_rcm_det.id_rcm_orig_value%TYPE := '-1';

    -- RCM TYPE
    g_type_rcm_clin_rcm      CONSTANT rcm_type.id_rcm_type%TYPE := 1; -- Clinical Recommendation
    g_type_rcm_reminder      CONSTANT rcm_type.id_rcm_type%TYPE := 2; -- Patient Reminder 
    g_type_rcm_reminder_auto CONSTANT rcm_type.id_rcm_type%TYPE := 3; -- Patient Reminder auto

    -- RCM props
    g_rcm_prop_epis_ndays   CONSTANT rcm_prop.id_prop%TYPE := 1;
    g_rcm_prop_remind_ndays CONSTANT rcm_prop.id_prop%TYPE := 2;

    -- workflow action to status 'Patient notified'
    g_wf_action_notif      CONSTANT wf_workflow_action.id_workflow_action%TYPE := 504;
    g_wf_action_pend_notif CONSTANT wf_workflow_action.id_workflow_action%TYPE := 501;
    g_wf_action_not_notif  CONSTANT wf_workflow_action.id_workflow_action%TYPE := 505;

    -- status 'Patient notified'
    g_id_status_ignored       CONSTANT wf_status.id_status%TYPE := 81;
    g_id_status_pend_notif    CONSTANT wf_status.id_status%TYPE := 82;
    g_id_status_pat_notif     CONSTANT wf_status.id_status%TYPE := 84;
    g_id_status_pat_not_notif CONSTANT wf_status.id_status%TYPE := 85;

    g_cat_system CONSTANT category.id_category%TYPE := 40;

    g_rank_default CONSTANT NUMBER := 1;

    -- sys_configs
    g_grid_ignored_d CONSTANT sys_config.id_sys_config%TYPE := 'RCM_GRID_IGNORED_DAYS';

    -- RCM parameters
    -- if adding new parameters, add function to pk_rcm_base.get_parameter_value_desc
    --g_param_age_min          CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MIN';
    --g_param_age_max          CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MAX';
    g_param_age_min_y        CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MIN_YEARS';
    g_param_age_max_y        CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MAX_YEARS';
    g_param_age_min_m        CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MIN_MONTHS';
    g_param_age_max_m        CONSTANT rcm_parameter.parameter_name%TYPE := 'AGE_MAX_MONTHS';
    g_param_gender           CONSTANT rcm_parameter.parameter_name%TYPE := 'GENDER';
    g_param_med              CONSTANT rcm_parameter.parameter_name%TYPE := 'MEDICATION';
    g_param_not_med          CONSTANT rcm_parameter.parameter_name%TYPE := 'NOT_MEDICATION';
    g_param_sr_proc          CONSTANT rcm_parameter.parameter_name%TYPE := 'SR_PROC';
    g_param_not_sr_proc      CONSTANT rcm_parameter.parameter_name%TYPE := 'NOT_SR_PROC';
    g_param_probl            CONSTANT rcm_parameter.parameter_name%TYPE := 'PROBLEM';
    g_param_not_probl        CONSTANT rcm_parameter.parameter_name%TYPE := 'NOT_PROBLEM';
    g_param_lab_test         CONSTANT rcm_parameter.parameter_name%TYPE := 'LAB_TEST_REQ';
    g_param_not_lab_test     CONSTANT rcm_parameter.parameter_name%TYPE := 'NOT_LAB_TEST_REQUEST';
    g_param_intv_n_lab_test  CONSTANT rcm_parameter.parameter_name%TYPE := 'INTERVAL_NOT_LABTEST_REQ';
    g_param_intvu_n_lab_test CONSTANT rcm_parameter.parameter_name%TYPE := 'INTERVAL_UNIT_NOT_LABTEST_REQ';

    g_sc_id_prof_background CONSTANT sys_config.id_sys_config%TYPE := 'ID_PROF_BACKGROUND';
    g_sc_id_market          CONSTANT sys_config.id_sys_config%TYPE := 'RCM_MARKET';
    g_sc_id_software        CONSTANT sys_config.id_sys_config%TYPE := 'RCM_SOFTWARE';

    -- contact method
    g_contact_method_sms   CONSTANT contact_method.id_contact_method%TYPE := 4;
    g_contact_method_email CONSTANT contact_method.id_contact_method%TYPE := 2;

    -- default episode
    g_epis_epis_undef CONSTANT episode.id_episode%TYPE := -1;

    g_unit_measure_year  CONSTANT unit_measure.id_unit_measure%TYPE := 10373;
    g_unit_measure_month CONSTANT unit_measure.id_unit_measure%TYPE := 1127;
    g_unit_measure_week  CONSTANT unit_measure.id_unit_measure%TYPE := 10375;
    g_unit_measure_day   CONSTANT unit_measure.id_unit_measure%TYPE := 2680;

    g_unit_label_day   CONSTANT VARCHAR2(10 CHAR) := 'DAY';
    g_unit_label_month CONSTANT VARCHAR2(10 CHAR) := 'MONTH';
    g_unit_label_year  CONSTANT VARCHAR2(10 CHAR) := 'YEAR';

    g_sc_year_desc  CONSTANT sys_config.id_sys_config%TYPE := 'YEAR_DESC';
    g_sc_month_desc CONSTANT sys_config.id_sys_config%TYPE := 'MONTH_DESC';

    g_num_days_week CONSTANT NUMBER := 7;

    -- sys_messages code   
    g_sm_notif_t001 CONSTANT sys_message.code_message%TYPE := 'RCM_SYS_NOTIF_T001';
    g_sm_notif_t002 CONSTANT sys_message.code_message%TYPE := 'RCM_SYS_NOTIF_T002';
    g_sm_notif_t003 CONSTANT sys_message.code_message%TYPE := 'RCM_SYS_NOTIF_T003';
    g_sm_notif_t004 CONSTANT sys_message.code_message%TYPE := 'RCM_SYS_NOTIF_T004';

    g_sm_rcm_t009 CONSTANT sys_message.code_message%TYPE := 'RECOMMENDATION_T009';
    g_sm_rcm_t013 CONSTANT sys_message.code_message%TYPE := 'RECOMMENDATION_T013';
    g_sm_rcm_t014 CONSTANT sys_message.code_message%TYPE := 'RECOMMENDATION_T014';
    g_sm_rcm_t015 CONSTANT sys_message.code_message%TYPE := 'RECOMMENDATION_T015';
    g_sm_rcm_t030 CONSTANT sys_message.code_message%TYPE := 'RECOMMENDATION_T030';

    g_space     CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_colon     CONSTANT VARCHAR2(1 CHAR) := ':';
    g_semicolon CONSTANT VARCHAR2(1 CHAR) := ';';

    g_button_read CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- WEBSERVICES
    g_ws_execution_request CONSTANT VARCHAR2(500 CHAR) := 'execution_request';
    g_ws_get_request_data  CONSTANT VARCHAR2(500 CHAR) := 'get_request_data';

    -- Temp table
    g_temp_type_rules CONSTANT VARCHAR2(20 CHAR) := 'RULES';
    g_temp_type_pat   CONSTANT VARCHAR2(20 CHAR) := 'PAT_DATA';

    -- RCM tokens message
    g_tk_id_epis            CONSTANT t_low_char := 'ID_EPISODE';
    g_tk_id_patient         CONSTANT t_low_char := 'PATIENT_ID';
    g_tk_pat_name           CONSTANT t_low_char := 'PATIENT_NAME';
    g_tk_pat_contact        CONSTANT t_low_char := 'PATIENT_CONTACT';
    g_tk_pat_contact_method CONSTANT t_low_char := 'PATIENT_CONTACT_METHOD';
    g_tk_inst_name          CONSTANT t_low_char := 'INSTITUTION_NAME';
    g_tk_inst_phone         CONSTANT t_low_char := 'INSTITUTION_PHONE';
    g_tk_rcm_summ           CONSTANT t_low_char := 'RCM_SUMM';
    g_tk_lang               CONSTANT t_low_char := 'LANGUAGE';
    g_tk_crm_key            CONSTANT t_low_char := 'CRM_KEY';
    g_tk_templ_value        CONSTANT t_low_char := 'TEMPLATE_VALUE';

    -- tokens needed by CRM to complete the message
    g_crm_att_reminder_desc CONSTANT VARCHAR2(100 CHAR) := 'REMINDER_DESCRIPTION';
    g_crm_att_patient_name  CONSTANT VARCHAR2(100 CHAR) := 'PATIENT_NAME';
    g_crm_att_instit_name   CONSTANT VARCHAR2(100 CHAR) := 'INSTITUTION_NAME';
    g_crm_att_instit_phone  CONSTANT VARCHAR2(100 CHAR) := 'INSTITUTION_PHONE';

    -- response status from CRM
    g_crm_status_processed CONSTANT VARCHAR2(20 CHAR) := 'PROCESSED';
    g_crm_status_error     CONSTANT VARCHAR2(20 CHAR) := 'ERROR';

END pk_rcm_constant;
/
