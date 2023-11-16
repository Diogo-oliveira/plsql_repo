/*-- Last Change Revision: $Rev: 2055614 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:26:38 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_blood_products_utils IS

    FUNCTION get_bp_status_to_update
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_det.id_blood_product_req%TYPE,
        o_status            OUT blood_product_req.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_questionnaire_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_hemo_type  IN hemo_type.id_hemo_type%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_bp_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_bp_permission
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_button              IN VARCHAR2,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_current_episode IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_bp_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diagnosis_list IN interv_presc_det_hist.id_diagnosis_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_status_string
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_bp_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_force_anc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_bp_number_bags
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_quantity        IN blood_product_det.qty_exec%TYPE,
        i_id_unit_measure IN blood_product_det.id_unit_mea_qty_exec%TYPE
    ) RETURN NUMBER;

    FUNCTION get_bp_quantity_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_quantity        IN blood_product_det.qty_exec%TYPE,
        i_id_unit_measure IN blood_product_det.id_unit_mea_qty_exec%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_flg_time      IN VARCHAR2
    ) RETURN table_varchar;

    FUNCTION get_bp_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN interv_question_response.notes%TYPE
    ) RETURN bp_question_response.notes%TYPE;

    FUNCTION get_bp_episode_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_questionnaire IN bp_question_response.id_questionnaire%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_pat_blood_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_bp_adverse_reaction_req
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_bp_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_desc_hemo_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_lab_hemo_type     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_compatibility_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_color             IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    FUNCTION get_bp_compatibility_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_compatibility_reg_tstz
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_bp_unsafe_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_det.id_blood_product_req%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE DEFAULT NULL,
        i_limit             IN sys_config.id_sys_config%TYPE
    ) RETURN sys_domain.val%TYPE;

    FUNCTION get_bp_status_over_limit --usada no filtro
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_limit   IN sys_config.id_sys_config%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_status_string_req
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_bp_req IN blood_product_req.id_blood_product_req%TYPE,
        i_limit  IN sys_config.id_sys_config%TYPE,
        
        i_status_str_req  IN VARCHAR2,
        i_status_msg_req  IN VARCHAR2,
        i_status_icon_req IN VARCHAR2,
        i_status_flg_req  IN VARCHAR2
        
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_result_blood
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis     IN table_number,
        i_sample_type  IN table_number,
        i_flg_html_det IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_result_data  OUT table_varchar,
        o_result_date  OUT table_varchar,
        o_result_reg   OUT table_varchar,
        o_match        OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_returned_bag_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_hemo_type     hemo_type.id_hemo_type %TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_blood_products_utils;
/
