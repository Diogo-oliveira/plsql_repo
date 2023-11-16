/*-- Last Change Revision: $Rev: 2043880 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-08-04 10:37:31 +0100 (qui, 04 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_blood_products_api_db IS

    FUNCTION set_bp_component_add
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type         IN hemo_type.id_hemo_type%TYPE,
        i_qty_rec           IN NUMBER,
        i_unit_mea          IN NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_preparation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_req  IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type          IN hemo_type.id_hemo_type%TYPE,
        i_barcode            IN VARCHAR2,
        i_qty_rec            IN NUMBER,
        i_unit_mea           IN NUMBER,
        i_expiration_date    IN VARCHAR2,
        i_blood_group        IN VARCHAR2,
        i_blood_group_rh     IN VARCHAR2,
        i_desc_hemo_type_lab IN VARCHAR,
        i_donation_code      IN VARCHAR2,
        i_flg_interface      IN VARCHAR2 DEFAULT 'N',
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_status        IN blood_product_det.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_bp_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN table_number,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes_cancel%TYPE,
        i_flg_interface     IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_qty_given         IN table_number DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_bp_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_blood_product_det     IN table_number,
        i_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel          IN blood_product_req.notes_cancel%TYPE,
        i_flg_interface         IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_transfusion_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report          IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_transfusions_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN table_number,
        i_flg_report          IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_flg_html            IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_adv_reaction_confirm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_blood_product_exec IN blood_product_execution.id_blood_product_execution%TYPE,
        i_date               IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

END pk_blood_products_api_db;
/
