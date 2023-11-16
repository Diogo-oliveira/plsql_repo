CREATE OR REPLACE PACKAGE pk_orders_utils IS
    -- Public constant declarations

    /*DO NOT TOUCH - G_DS_P1_ALL_ITEMS_SELECTED used by UX layer*/
    g_ds_p1_all_items_selected CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_ALL_ITEMS_SELECTED';
    --

    g_action_edit_no_recurrence   CONSTANT NUMBER(24) := 2340163;
    g_action_edit_with_recurrence CONSTANT NUMBER(24) := 2340164;

    --Root names for referrals
    g_p1_appointment  CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_APPOINTMENT';
    g_p1_lab_test     CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_LAB_TEST';
    g_p1_imaging_exam CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_IMAGING_EXAM';
    g_p1_other_exam   CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_OTHER_EXAM';
    g_p1_intervention CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_INTERVENTION';
    g_p1_rehab        CONSTANT VARCHAR2(50 CHAR) := 'DS_P1_REHAB';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    -- Public function and procedure declarations
    FUNCTION get_value
    (
        i_internal_name_child IN VARCHAR2,
        i_tbl_mkt_rel         IN table_number,
        i_value               IN table_table_varchar,
        i_index               IN NUMBER DEFAULT 1
    ) RETURN VARCHAR2;

    FUNCTION get_ds_cmpt_mkt_rel
    (
        i_internal_name IN VARCHAR2,
        i_tbl_mkt_rel   IN table_number
    ) RETURN NUMBER;

    FUNCTION get_ok_button_control
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_tbl_result     IN OUT t_tbl_ds_get_value,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_other_frequencies_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_data       IN table_table_varchar,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_value_clob     IN table_clob,
        i_value_mea      IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_generic_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_to_execute_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_p1_ok_button_state
    (
        i_lang                         IN NUMBER,
        i_prof                         IN profissional,
        i_episode                      IN NUMBER,
        i_patient                      IN NUMBER,
        i_action                       IN NUMBER, -- edit, new, submit
        i_root_name                    IN VARCHAR2, -- root of dynamic screen
        i_curr_component               IN NUMBER,
        i_tbl_id_pk                    IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel                  IN table_number, -- components needed for default/edit
        i_value                        IN table_table_varchar,
        i_complementary_info_mandatory IN VARCHAR2 DEFAULT NULL,
        o_error                        OUT t_error_out
    ) RETURN t_rec_ds_get_value;

    FUNCTION get_generic_ok_button_state
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_episode                    IN NUMBER,
        i_root_name                  IN VARCHAR2,
        i_idx                        IN NUMBER,
        i_id_ds_cmpt_mkt_rel_control IN NUMBER,
        i_tbl_rec_ds                 IN OUT t_tbl_ds_get_value,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_piped_analysis
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_analysis_inst_soft IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_piped_rehab_interv
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_rehab_area_interv IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_session_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_p1_id_detail
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_episode             IN NUMBER,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_type            IN p1_detail.flg_type%TYPE
    ) RETURN NUMBER;

    FUNCTION get_patient_health_plan_entity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_patient_health_plan_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_patient_beneficiary_number
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_health_plan_entity IN health_plan_entity.id_health_plan_entity%TYPE,
        i_health_plan        IN health_plan.id_health_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_exemptions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_current_date IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN t_tbl_core_domain;

    FUNCTION get_pat_default_exemption
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_current_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_id_exemption   OUT pat_isencao.id_pat_isencao%TYPE,
        o_exemption_desc OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_ds_internal_name(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN VARCHAR;

    FUNCTION get_id_ds_component(i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE) RETURN NUMBER;

    FUNCTION get_multichoice_options
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_multichoice_type IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_priority_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_time_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_default          IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    FUNCTION get_prn_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_fasting_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_mandatory_items
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_root_name          IN VARCHAR2,
        i_tbl_id_pk          IN table_number,
        i_id_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_id_ds_component    IN ds_cmpt_mkt_rel.id_ds_component_child%TYPE,
        i_ds_internal_name   IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        io_tbl_result        IN OUT t_tbl_ds_get_value,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis_xml
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_tbl_id_diagnosis       IN table_number,
        i_tbl_id_alert_diagnosis IN table_number,
        i_tbl_diagnosis_desc     IN table_varchar
    ) RETURN CLOB;

    FUNCTION process_multi_form
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_patient   IN NUMBER,
        i_root_name IN VARCHAR2,
        o_result    IN OUT t_tbl_ds_get_value,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mcdt_documents_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_req_det   IN NUMBER,
        i_mcdt_type IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_unit_measure_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_catalogue_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        i_records   IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_location_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        i_records   IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_alert_languages
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_laterality_event_type
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_root_name            IN VARCHAR2,
        i_laterality_mandatory IN sys_config.value%TYPE,
        i_idx                  IN NUMBER DEFAULT 1,
        i_value_laterality     IN VARCHAR2,
        i_tbl_data             IN table_table_varchar
    ) RETURN VARCHAR2;

    FUNCTION get_prof_institutions
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION set_merge_pat_exemption
    (
        i_lang     language.id_language%TYPE,
        i_prof     profissional,
        i_pat      patient.id_patient%TYPE,
        i_pat_temp patient.id_patient%TYPE,
        o_error    t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_object_info
    (
        i_object_name IN VARCHAR2,
        o_object_info OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    FUNCTION get_co_sign_values
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_episode      IN NUMBER,
        i_patient      IN NUMBER,
        i_root_name    IN VARCHAR2,
        i_idx          IN NUMBER DEFAULT 1,
        i_tbl_id_pk    IN table_number,
        i_tbl_mkt_rel  IN table_number,
        i_tbl_int_name IN table_varchar,
        i_value        IN table_table_varchar,
        i_value_mea    IN table_table_varchar,
        i_value_desc   IN table_table_varchar,
        i_tbl_data     IN table_table_varchar,
        i_value_clob   IN table_clob,
        i_tbl_result   IN OUT t_tbl_ds_get_value,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_bleep_info
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_cq_task_type
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_clinical_question_info IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_cq_id
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_clinical_question_info IN VARCHAR2,
        i_index                  IN NUMBER
    ) RETURN NUMBER;

    /* ###################################################################################################################
    # Functions and procedures beyond this point should not be sent to stable version.                                   #  
    # These are only meant for development environments.                                                                 #  
    ######################################################################################################################*/
    PROCEDURE migrate_dynamic_screens
    (
        i_root          IN VARCHAR2,
        i_market_origin IN market.id_market%TYPE,
        i_market_dest   IN market.id_market%TYPE
    );

    PROCEDURE get_form_scripts
    (
        i_root         IN table_varchar,
        i_market       IN market.id_market%TYPE DEFAULT NULL,
        i_software     IN software.id_software%TYPE DEFAULT NULL,
        i_force_update IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    );

END pk_orders_utils;
/
