CREATE OR REPLACE PACKAGE BODY pk_api_blood_products IS

    FUNCTION set_bp_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type         IN hemo_type.id_hemo_type%TYPE,
        i_qty_rec           IN NUMBER,
        i_unit_mea          IN NUMBER,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.SET_BP_COMPONENT_ADD';
        IF NOT pk_blood_products_api_db.set_bp_component_add(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_blood_product_req => i_blood_product_req,
                                                             i_hemo_type         => i_hemo_type,
                                                             i_qty_rec           => i_qty_rec,
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
                                              'SET_BP_DET',
                                              o_error);
            RETURN FALSE;
    END set_bp_det;

    FUNCTION cancel_transfusion
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes_cancel%TYPE,
        i_date              IN VARCHAR2,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_qty_given         IN table_number DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.CANCEL_BP_ORDER';
        IF NOT pk_blood_products_api_db.cancel_bp_order(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_blood_product_req => table_number(i_blood_product_req),
                                                        i_cancel_reason     => i_cancel_reason,
                                                        i_notes_cancel      => i_notes_cancel,
                                                        i_flg_interface     => pk_alert_constant.g_yes,
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
                                              'CANCEL_TRANSFUSION',
                                              o_error);
            RETURN FALSE;
    END cancel_transfusion;

    FUNCTION cancel_bp_component
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel          IN blood_product_req.notes_cancel%TYPE,
        i_date                  IN VARCHAR2,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.CANCEL_BP_REQUEST';
        IF NOT pk_blood_products_api_db.cancel_bp_request(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_blood_product_det     => table_number(i_blood_product_det),
                                                          i_cancel_reason         => i_cancel_reason,
                                                          i_notes_cancel          => i_notes_cancel,
                                                          i_flg_interface         => pk_alert_constant.g_yes,
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
                                              'CANCEL_BP_COMPONENT',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_component;

    FUNCTION set_bp_component_execution
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
                                              'SET_BP_COMPONENT_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_bp_component_execution;

    FUNCTION set_bp_component_prepared
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
        i_date               IN VARCHAR2,
        i_donation_code      IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.SET_BP_PREPARATION';
        IF NOT pk_blood_products_api_db.set_bp_preparation(i_lang               => i_lang,
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
                                                           i_flg_interface      => pk_alert_constant.g_yes,
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
                                              'SET_BP_COMPONENT_PREPARED',
                                              o_error);
            RETURN FALSE;
    END set_bp_component_prepared;

    FUNCTION set_bp_component_harvest
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_date              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.UPDATE_BP_STATUS';
        IF NOT pk_blood_products_api_db.update_bp_status(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_blood_product_det => i_blood_product_det,
                                                         i_flg_status        => pk_blood_products_constant.g_status_det_r_cc,
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
                                              'SET_BP_COMPONENT_HARVEST',
                                              o_error);
            RETURN FALSE;
    END set_bp_component_harvest;

    FUNCTION set_bp_adv_react_confirm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_blood_product_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_blood_product_exec IN blood_product_execution.id_blood_product_execution%TYPE,
        i_date               IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.SET_BP_ADV_REACTION_CONFIRM';
        IF NOT pk_blood_products_api_db.set_bp_adv_reaction_confirm(i_lang               => i_lang,
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
                                              'SET_BP_ADV_REACT_CONFIRM',
                                              o_error);
            RETURN FALSE;
    END set_bp_adv_react_confirm;

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
    BEGIN
        g_error := 'CALL PK_BLOOD_PRODUCTS_API_DB.SET_BP_COMPATIBILITY';
        IF NOT pk_blood_products_api_db.set_bp_compatibility(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_blood_product_det => i_blood_product_det,
                                                             i_flg_compatibility => i_flg_compatibility,
                                                             i_notes             => i_notes,
                                                             i_date              => i_date,
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
                                              'SET_BP_COMPATIBILITY',
                                              o_error);
            RETURN FALSE;
    END set_bp_compatibility;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_blood_products;
/
