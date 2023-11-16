/*-- Last Change Revision: $Rev: 2043880 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-08-04 10:37:31 +0100 (qui, 04 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_blood_products_api_db IS

    FUNCTION set_bp_component_add
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type         IN hemo_type.id_hemo_type%TYPE,
        i_qty_rec           IN NUMBER,
        i_unit_mea          IN NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_COMPONENT_ADD';
        IF NOT pk_blood_products_core.set_bp_component_add(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_blood_product_req => i_blood_product_req,
                                                           i_hemo_type         => i_hemo_type,
                                                           i_qty_exec          => i_qty_rec,
                                                           i_unit_mea          => i_unit_mea,
                                                           o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_COMPONENT_ADD',
                                              o_error);
            RETURN FALSE;
    END set_bp_component_add;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_PREPARATION';
        IF NOT pk_blood_products_core.set_bp_preparation(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_blood_product_req  => i_blood_product_req,
                                                         i_hemo_type          => i_hemo_type,
                                                         i_barcode            => i_barcode,
                                                         i_qty_rec            => i_qty_rec,
                                                         i_unit_mea           => i_unit_mea,
                                                         i_expiration_date    => i_expiration_date,
                                                         i_blood_group        => i_blood_group,
                                                         i_blood_group_rh     => i_blood_group_rh,
                                                         i_desc_hemo_type_lab => i_desc_hemo_type_lab,
                                                         i_donation_code      => i_donation_code,
                                                         i_flg_interface      => i_flg_interface,
                                                         o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_PREPARATION',
                                              o_error);
            RETURN FALSE;
    END set_bp_preparation;

    FUNCTION set_bp_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_bp_execution;

    FUNCTION update_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_status        IN blood_product_det.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.UPDATE_BP_STATUS';
        IF NOT pk_blood_products_core.update_bp_status(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_blood_product_det => i_blood_product_det,
                                                       i_flg_status        => i_flg_status,
                                                       o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_BP_STATUS',
                                              o_error);
            RETURN FALSE;
    END update_bp_status;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.CANCEL_BP_ORDER';
        IF NOT pk_blood_products_core.cancel_bp_order(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_blood_product_req => i_blood_product_req,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes_cancel      => i_notes_cancel,
                                                      i_flg_interface     => i_flg_interface,
                                                      i_blood_product_det => i_blood_product_det,
                                                      i_qty_given         => i_qty_given,
                                                      o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_BP_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_order;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.CANCEL_BP_REQUEST';
        IF NOT pk_blood_products_core.cancel_bp_request(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_blood_product_det     => i_blood_product_det,
                                                        i_cancel_reason         => i_cancel_reason,
                                                        i_notes_cancel          => i_notes_cancel,
                                                        i_flg_interface         => i_flg_interface,
                                                        i_blood_product_det_qty => i_blood_product_det_qty,
                                                        i_qty_given             => i_qty_given,
                                                        o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_BP_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_request;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_TRANSFUSIONS_SUMMARY';
        IF NOT pk_blood_products_core.get_bp_transfusions_summary(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_episode             => i_episode,
                                                                  i_blood_product_det   => table_number(i_blood_product_det),
                                                                  i_flg_report          => i_flg_report,
                                                                  o_bp_order            => o_bp_order,
                                                                  o_bp_execution        => o_bp_execution,
                                                                  o_bp_adverse_reaction => o_bp_adverse_reaction,
                                                                  o_bp_reevaluation     => o_bp_reevaluation,
                                                                  o_bp_blood_bank       => o_bp_blood_bank,
                                                                  o_bp_group            => o_bp_group,
                                                                  o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TRANSFUSION_SUMMARY',
                                              o_error);
            RETURN FALSE;
    END get_bp_transfusion_summary;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_TRANSFUSIONS_SUMMARY';
        IF NOT pk_blood_products_core.get_bp_transfusions_summary(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_episode             => i_episode,
                                                                  i_blood_product_det   => i_blood_product_det,
                                                                  i_flg_report          => i_flg_report,
                                                                  i_flg_html            => i_flg_html,
                                                                  o_bp_order            => o_bp_order,
                                                                  o_bp_execution        => o_bp_execution,
                                                                  o_bp_adverse_reaction => o_bp_adverse_reaction,
                                                                  o_bp_reevaluation     => o_bp_reevaluation,
                                                                  o_bp_blood_bank       => o_bp_blood_bank,
                                                                  o_bp_group            => o_bp_group,
                                                                  o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_TRANSFUSIONS_SUMMARY',
                                              o_error);
            RETURN FALSE;
    END get_bp_transfusions_summary;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_DETAIL';
        IF NOT pk_blood_products_core.get_bp_detail(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_episode               => i_episode,
                                                    i_blood_product_det     => i_blood_product_det,
                                                    i_flg_report            => i_flg_report,
                                                    o_bp_detail             => o_bp_detail,
                                                    o_bp_clinical_questions => o_bp_clinical_questions,
                                                    o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_bp_detail;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_DETAIL_HISTORY';
        IF NOT pk_blood_products_core.get_bp_detail_history(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_episode               => i_episode,
                                                            i_blood_product_det     => i_blood_product_det,
                                                            i_flg_report            => i_flg_report,
                                                            o_bp_detail             => o_bp_detail,
                                                            o_bp_clinical_questions => o_bp_clinical_questions,
                                                            o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BP_DETAIL_HISTORY',
                                              o_error);
            RETURN FALSE;
    END get_bp_detail_history;

    FUNCTION set_bp_adv_reaction_confirm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_blood_product_exec IN blood_product_execution.id_blood_product_execution%TYPE,
        i_date               IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.SET_BP_ADV_REACTION_CONFIRM';
        IF NOT pk_blood_products_core.set_bp_adv_reaction_confirm(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_blood_product_det  => i_blood_product_det,
                                                                  i_blood_product_exec => i_blood_product_exec,
                                                                  i_date               => i_date,
                                                                  o_error              => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_ADV_REACTION_CONFIRM',
                                              o_error);
            RETURN FALSE;
    END set_bp_adv_reaction_confirm;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out table_varchar;
        l_num_exec NUMBER;
        l_date     TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        SELECT COUNT(*)
          INTO l_num_exec
          FROM blood_product_execution bpe
         WHERE bpe.id_blood_product_det = i_blood_product_det;
    
        ts_blood_product_execution.ins(id_blood_product_execution_in => seq_blood_product_execution.nextval,
                                       id_blood_product_det_in       => i_blood_product_det,
                                       action_in                     => pk_blood_products_constant.g_bp_action_compability,
                                       id_prof_performed_in          => i_prof.id,
                                       dt_execution_in               => l_date,
                                       exec_number_in                => l_num_exec + 1,
                                       id_professional_in            => i_prof.id,
                                       flg_compatibility_in          => i_flg_compatibility,
                                       notes_compatibility_in        => i_notes,
                                       rows_out                      => l_rows_out);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BP_COMPATIBILITY',
                                              o_error);
            RETURN FALSE;
    END set_bp_compatibility;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_blood_products_api_db;
/
