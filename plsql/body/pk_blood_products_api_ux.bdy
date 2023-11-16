CREATE OR REPLACE PACKAGE BODY pk_blood_products_api_ux IS

    FUNCTION create_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_hemo_type               IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar, --15
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar, --20
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number, --25
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number, --30
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2,
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2, --35
        o_msg_req                 OUT VARCHAR2,
        o_blood_prod_req_array    OUT NOCOPY table_number,
        o_blood_prod_det_array    OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.CREATE_BP_ORDER';
        IF NOT pk_blood_products_core.create_bp_order(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_patient                 => i_patient,
                                                      i_episode                 => i_episode,
                                                      i_hemo_type               => i_hemo_type,
                                                      i_flg_time                => i_flg_time,
                                                      i_dt_begin                => i_dt_begin,
                                                      i_episode_destination     => i_episode_destination,
                                                      i_order_recurrence        => i_order_recurrence,
                                                      i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                             i_prof   => i_prof,
                                                                                                             i_params => i_diagnosis),
                                                      i_clinical_purpose        => i_clinical_purpose,
                                                      i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                      i_priority                => i_priority,
                                                      i_special_type            => i_special_type,
                                                      i_screening               => i_screening,
                                                      i_without_nat             => i_without_nat,
                                                      i_not_send_unit           => i_not_send_unit,
                                                      i_transf_type             => i_transf_type,
                                                      i_qty_exec                => i_qty_exec,
                                                      i_unit_qty_exec           => i_unit_qty_exec,
                                                      i_exec_institution        => i_exec_institution,
                                                      i_not_order_reason        => i_not_order_reason,
                                                      i_special_instr           => i_special_instr,
                                                      i_notes                   => i_notes,
                                                      i_prof_order              => i_prof_order,
                                                      i_dt_order                => i_dt_order,
                                                      i_order_type              => i_order_type,
                                                      i_health_plan             => i_health_plan,
                                                      i_exemption               => i_exemption,
                                                      i_clinical_question       => i_clinical_question,
                                                      i_response                => i_response,
                                                      i_clinical_question_notes => i_clinical_question_notes,
                                                      i_clinical_decision_rule  => i_clinical_decision_rule,
                                                      i_flg_origin_req          => i_flg_origin_req,
                                                      i_test                    => i_test,
                                                      i_flg_mother_lab_tests    => i_flg_mother_lab_tests,
                                                      o_flg_show                => o_flg_show,
                                                      o_msg_title               => o_msg_title,
                                                      o_msg_req                 => o_msg_req,
                                                      o_blood_prod_req_array    => o_blood_prod_req_array,
                                                      o_blood_prod_det_array    => o_blood_prod_det_array,
                                                      o_error                   => o_error)
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
                                              'CREATE_BLOOD_PRODUCT_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_bp_order;

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
        i_desc_hemo_type_lab IN VARCHAR2,
        i_donation_code      IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_PREPARATION';
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_preparation;

    FUNCTION set_bp_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_to_state          IN VARCHAR2,
        i_barcode           IN VARCHAR2,
        i_prof_match        IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_REQUEST_TRANSPORT';
        IF NOT pk_blood_products_core.set_bp_transport(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_blood_product_det => i_blood_product_det,
                                                       i_to_state          => i_to_state,
                                                       i_barcode           => i_barcode,
                                                       i_prof_match        => i_prof_match,
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
                                              'SET_BP_TRANSPORT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_transport;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_COMPATIBILITY';
        IF NOT pk_blood_products_core.set_bp_compatibility(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_blood_product_det => i_blood_product_det,
                                                           i_flg_compatibility => i_flg_compatibility,
                                                           i_notes             => i_notes,
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_compatibility;

    FUNCTION set_bp_transfusion
    (
        i_lang                  IN language.id_language%TYPE, --1
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_from_state            IN action.to_state%TYPE DEFAULT NULL, --5
        i_to_state              IN action.to_state%TYPE DEFAULT NULL,
        i_performed_by          IN professional.id_professional%TYPE,
        i_start_date            IN VARCHAR2,
        i_duration              IN blood_product_execution.duration%TYPE, --10
        i_duration_unit_measure IN blood_product_execution.id_unit_mea_duration%TYPE,
        i_end_date              IN VARCHAR2,
        i_description           IN blood_product_execution.description%TYPE,
        i_prof_match            IN NUMBER DEFAULT NULL,
        i_documentation_notes   IN epis_interv.notes%TYPE, --15
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number, --20
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number, --25
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number, --30
        i_amount_given          IN blood_product_det.qty_given%TYPE,
        i_amount_given_unit     IN blood_product_det.id_unit_mea_qty_given%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_TRANSFUSION';
        IF NOT pk_blood_products_core.set_bp_transfusion(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_episode               => i_episode,
                                                         i_blood_product_det     => i_blood_product_det,
                                                         i_from_state            => i_from_state,
                                                         i_to_state              => i_to_state,
                                                         i_performed_by          => i_performed_by,
                                                         i_start_date            => i_start_date,
                                                         i_duration              => i_duration,
                                                         i_duration_unit_measure => i_duration_unit_measure,
                                                         i_end_date              => i_end_date,
                                                         i_description           => i_description,
                                                         i_prof_match            => i_prof_match,
                                                         i_documentation_notes   => i_documentation_notes,
                                                         i_doc_template          => i_doc_template,
                                                         i_flg_type              => i_flg_type,
                                                         i_id_documentation      => i_id_documentation,
                                                         i_id_doc_element        => i_id_doc_element,
                                                         i_id_doc_element_crit   => i_id_doc_element_crit,
                                                         i_value                 => i_value,
                                                         i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                         i_vs_element_list       => i_vs_element_list,
                                                         i_vs_save_mode_list     => i_vs_save_mode_list,
                                                         i_vs_list               => i_vs_list,
                                                         i_vs_value_list         => i_vs_value_list,
                                                         i_vs_uom_list           => i_vs_uom_list,
                                                         i_vs_scales_list        => i_vs_scales_list,
                                                         i_vs_date_list          => i_vs_date_list,
                                                         i_vs_read_list          => i_vs_read_list,
                                                         i_amount_given          => i_amount_given,
                                                         i_amount_given_unit     => i_amount_given_unit,
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
                                              'SET_BP_TRANSFUSION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_transfusion;

    FUNCTION set_bp_adverse_reaction
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_documentation_notes   IN epis_interv.notes%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_ADVERSE_REACTION';
        IF NOT pk_blood_products_core.set_bp_adverse_reaction(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_episode               => i_episode,
                                                              i_blood_product_det     => i_blood_product_det,
                                                              i_documentation_notes   => i_documentation_notes,
                                                              i_doc_template          => i_doc_template,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => i_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_vs_element_list       => i_vs_element_list,
                                                              i_vs_save_mode_list     => i_vs_save_mode_list,
                                                              i_vs_list               => i_vs_list,
                                                              i_vs_value_list         => i_vs_value_list,
                                                              i_vs_uom_list           => i_vs_uom_list,
                                                              i_vs_scales_list        => i_vs_scales_list,
                                                              i_vs_date_list          => i_vs_date_list,
                                                              i_vs_read_list          => i_vs_read_list,
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
                                              'SET_BP_ADVERSE_REACTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_adverse_reaction;

    FUNCTION set_bp_req_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_state             IN blood_product_req.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_REQ_STATUS';
        IF NOT pk_blood_products_core.set_bp_req_status(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_blood_product_req => i_blood_product_req,
                                                        i_state             => i_state,
                                                        i_cancel_reason     => i_cancel_reason,
                                                        i_notes_cancel      => i_notes_cancel,
                                                        i_upd_det           => TRUE,
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
                                              'SET_BP_REQ_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_req_status;

    FUNCTION set_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_state             IN blood_product_det.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_STATUS';
        IF NOT pk_blood_products_core.set_bp_status(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_blood_product_det => i_blood_product_det,
                                                    i_state             => i_state,
                                                    i_cancel_reason     => i_cancel_reason,
                                                    i_notes_cancel      => i_notes_cancel,
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
                                              'SET_BP_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_status;

    FUNCTION set_bp_compatibility_warning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_warning_type IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN AS
    
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
                                              'SET_BP_COMPATIBILITY_WARNING',
                                              o_error);
            RETURN FALSE;
    END set_bp_compatibility_warning;

    FUNCTION set_bp_condition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_condition     IN VARCHAR2,
        i_id_reason         IN blood_product_execution.id_action_reason%TYPE,
        i_notes             IN blood_product_execution.notes_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_CONDITION';
        IF NOT pk_blood_products_core.set_bp_condition(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_blood_product_det => i_blood_product_det,
                                                       i_flg_condition     => i_flg_condition,
                                                       i_id_reason         => i_id_reason,
                                                       i_notes             => i_notes,
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
                                              'SET_BP_condition',
                                              o_error);
            RETURN FALSE;
    END set_bp_condition;

    FUNCTION set_bp_crossmatch_credential
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
    
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
                                              'SET_BP_CROSSMATCH_CREDENTIAL',
                                              o_error);
            RETURN FALSE;
    END set_bp_crossmatch_credential;

    FUNCTION set_bp_transfusion_confirm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.SET_BP_TRANSFUSION_CONFIRM';
        IF NOT pk_blood_products_core.set_bp_transfusion_confirm(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_blood_product_det => i_blood_product_det,
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
                                              'SET_BP_TRANSFUSION_CONFIRM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_bp_transfusion_confirm;

    FUNCTION update_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE,
        i_blood_product_det       IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN table_clob,
        i_clinical_purpose        IN table_number, --10
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number, --15
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar, --20
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --25
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.UPDATE_BP_ORDER';
        IF NOT pk_blood_products_core.update_bp_order(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_episode                 => i_episode,
                                                      i_blood_product_req       => i_blood_product_req,
                                                      i_blood_product_det       => i_blood_product_det,
                                                      i_flg_time                => i_flg_time,
                                                      i_dt_begin                => i_dt_begin,
                                                      i_order_recurrence        => i_order_recurrence,
                                                      i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                             i_prof   => i_prof,
                                                                                                             i_params => i_diagnosis),
                                                      i_clinical_purpose        => i_clinical_purpose,
                                                      i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                      i_priority                => i_priority,
                                                      i_special_type            => i_special_type,
                                                      i_screening               => i_screening,
                                                      i_without_nat             => i_without_nat,
                                                      i_not_send_unit           => i_not_send_unit,
                                                      i_transf_type             => i_transf_type,
                                                      i_qty_exec                => i_qty_exec,
                                                      i_unit_qty_exec           => i_unit_qty_exec,
                                                      i_exec_institution        => i_exec_institution,
                                                      i_not_order_reason        => i_not_order_reason,
                                                      i_special_instr           => i_special_instr,
                                                      i_notes                   => i_notes,
                                                      i_prof_order              => i_prof_order,
                                                      i_dt_order                => i_dt_order,
                                                      i_order_type              => i_order_type,
                                                      i_health_plan             => i_health_plan,
                                                      i_exemption               => i_exemption,
                                                      i_clinical_question       => i_clinical_question,
                                                      i_response                => i_response,
                                                      i_clinical_question_notes => i_clinical_question_notes,
                                                      i_clinical_decision_rule  => i_clinical_decision_rule,
                                                      o_error                   => o_error)
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
                                              'UPDATE_BP_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_bp_order;

    FUNCTION cancel_bp_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN table_number,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        i_blood_product_det IN table_number DEFAULT NULL,
        i_qty_given         IN table_number DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.CANCEL_BP_ORDER';
        IF NOT pk_blood_products_core.cancel_bp_order(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_blood_product_req => i_blood_product_req,
                                                      i_cancel_reason     => i_cancel_reason,
                                                      i_notes_cancel      => i_notes_cancel,
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_bp_order;

    FUNCTION cancel_bp_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_blood_product_det     IN table_number,
        i_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel          IN blood_product_req.notes%TYPE,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.CANCEL_BP_REQUEST';
        IF NOT pk_blood_products_core.cancel_bp_request(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_blood_product_det     => i_blood_product_det,
                                                        i_cancel_reason         => i_cancel_reason,
                                                        i_notes_cancel          => i_notes_cancel,
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_bp_request;

    FUNCTION get_bp_selection_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_SELECTION_LIST';
        IF NOT pk_blood_products_core.get_bp_selection_list(i_lang  => i_lang,
                                                            i_prof  => i_prof,
                                                            o_list  => o_list,
                                                            o_error => o_error)
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
                                              'GET_BP_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_selection_list;

    FUNCTION get_bp_transport_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_TRANSPORT_LISTVIEW';
        IF NOT pk_blood_products_core.get_bp_transport_listview(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_episode => i_episode,
                                                                o_list    => o_list,
                                                                o_error   => o_error)
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
                                              'GET_BP_TRANSPORT_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_transport_listview;

    FUNCTION get_bp_compatibility
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_show_popup       OUT VARCHAR2,
        o_title            OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_shortcut         OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_bp_det        OUT blood_product_det.id_blood_product_det%TYPE,
        o_flg_warning_type OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_COMPATIBILITY';
        IF NOT pk_blood_products_core.get_bp_compatibility(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_episode          => i_episode,
                                                           o_show_popup       => o_show_popup,
                                                           o_title            => o_title,
                                                           o_msg              => o_msg,
                                                           o_shortcut         => o_shortcut,
                                                           o_id_bp_det        => o_id_bp_det,
                                                           o_flg_warning_type => o_flg_warning_type,
                                                           o_error            => o_error)
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
                                              'GET_BP_COMPATIBILITY',
                                              o_error);
            RETURN FALSE;
    END get_bp_compatibility;

    FUNCTION get_bp_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_QUESTIONNAIRE';
        IF NOT pk_blood_products_core.get_bp_questionnaire(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_patient       => i_patient,
                                                           i_episode       => i_episode,
                                                           i_hemo_type     => i_hemo_type,
                                                           i_flg_time      => i_flg_time,
                                                           i_dep_clin_serv => i_dep_clin_serv,
                                                           o_list          => o_list,
                                                           o_error         => o_error)
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
                                              'GET_BP_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_questionnaire;

    FUNCTION get_bp_barcode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_barcode           IN blood_product_det.barcode_lab%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_BARCODE';
        IF NOT pk_blood_products_core.get_bp_barcode(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_blood_product_det => i_blood_product_det,
                                                     i_barcode           => i_barcode,
                                                     o_list              => o_list,
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
                                              'GET_BP_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_barcode;

    FUNCTION get_bp_donation_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_donation_code     IN blood_product_det.donation_code%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_BARCODE';
        IF NOT pk_blood_products_core.get_bp_donation_code(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_blood_product_det => i_blood_product_det,
                                                           i_donation_code     => i_donation_code,
                                                           o_list              => o_list,
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
                                              'GET_BP_DONATION_CODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_donation_code;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_API_DB.GET_BP_DETAIL';
        IF NOT pk_blood_products_api_db.get_bp_detail(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_episode               => i_episode,
                                                      i_blood_product_det     => i_blood_product_det,
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
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            RETURN FALSE;
    END get_bp_detail;

    FUNCTION get_bp_detail_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_DETAIL_HTML';
        IF NOT pk_blood_products_core.get_bp_detail_html(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_blood_product_det => i_blood_product_det,
                                                         o_detail            => o_detail,
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
                                              'GET_BP_DETAIL_HTML',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_bp_detail_html;

    FUNCTION get_bp_detail_history_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_DETAIL_HISTORY_HTML';
        IF NOT pk_blood_products_core.get_bp_detail_history_html(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_blood_product_det => i_blood_product_det,
                                                                 o_detail            => o_detail,
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
                                              'GET_BP_DETAIL_HISTORY_HTML',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_bp_detail_history_html;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_API_DB.GET_BP_DETAIL_HISTORY';
        IF NOT pk_blood_products_api_db.get_bp_detail_history(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_episode               => i_episode,
                                                              i_blood_product_det     => i_blood_product_det,
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
            pk_types.open_my_cursor(o_bp_detail);
            pk_types.open_my_cursor(o_bp_clinical_questions);
            RETURN FALSE;
    END get_bp_detail_history;

    FUNCTION get_bp_transfusion_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_API_DB.GET_BP_TRANSFUSION_SUMMARY';
        IF NOT pk_blood_products_api_db.get_bp_transfusions_summary(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_episode             => i_episode,
                                                                    i_blood_product_det   => table_number(i_blood_product_det),
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
            pk_types.open_my_cursor(o_bp_order);
            pk_types.open_my_cursor(o_bp_execution);
            pk_types.open_my_cursor(o_bp_adverse_reaction);
            pk_types.open_my_cursor(o_bp_reevaluation);
            pk_types.open_my_cursor(o_bp_blood_bank);
            RETURN FALSE;
    END get_bp_transfusion_summary;

    FUNCTION get_bp_transfusions_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN table_number,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_API_DB.GET_BP_TRANSFUSION_SUMMARY';
        IF NOT pk_blood_products_api_db.get_bp_transfusions_summary(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_episode             => i_episode,
                                                                    i_blood_product_det   => i_blood_product_det,
                                                                    i_flg_html            => pk_alert_constant.g_yes,
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
            pk_types.open_my_cursor(o_bp_order);
            pk_types.open_my_cursor(o_bp_execution);
            pk_types.open_my_cursor(o_bp_adverse_reaction);
            pk_types.open_my_cursor(o_bp_reevaluation);
            pk_types.open_my_cursor(o_bp_blood_bank);
            RETURN FALSE;
    END get_bp_transfusions_summary;

    FUNCTION get_bp_to_edit
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_bp_req                IN table_number,
        i_bp_det                IN table_number,
        o_list                  OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_TO_EDIT';
        IF NOT pk_blood_products_core.get_bp_to_edit(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_episode               => i_episode,
                                                     i_bp_req                => i_bp_req,
                                                     i_bp_det                => i_bp_det,
                                                     o_list                  => o_list,
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
                                              'GET_BP_TO_EDIT',
                                              o_error);
            RETURN FALSE;
    END get_bp_to_edit;

    FUNCTION get_bp_response_to_edit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_blood_product_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time             IN exam_question_response.flg_time%TYPE,
        o_bp_question_response OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_RESPONSE_TO_EDIT';
        IF NOT pk_blood_products_core.get_bp_response_to_edit(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_blood_product_det    => i_blood_product_det,
                                                              i_flg_time             => i_flg_time,
                                                              o_bp_question_response => o_bp_question_response,
                                                              o_error                => o_error)
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
                                              'GET_BP_RESPONSE_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_bp_question_response);
            RETURN FALSE;
    END get_bp_response_to_edit;

    FUNCTION get_bp_to_match_and_revise
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_list_match_screen OUT pk_types.cursor_type,
        o_list_revised      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.get_bp_to_match_and_revise';
        IF NOT pk_blood_products_core.get_bp_to_match_and_revise(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_episode           => i_episode,
                                                                 o_list_match_screen => o_list_match_screen,
                                                                 o_list_revised      => o_list_revised,
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
                                              'GET_BP_TO_MATCH_AND_REVISE',
                                              o_error);
            pk_types.open_my_cursor(o_list_match_screen);
            pk_types.open_my_cursor(o_list_revised);
            RETURN FALSE;
    END get_bp_to_match_and_revise;

    FUNCTION get_bp_action_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_subject               IN action.subject%TYPE,
        i_from_state            IN action.from_state%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_actions               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_ACTION_LIST';
        IF NOT pk_blood_products_core.get_bp_action_list(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_episode               => i_episode,
                                                         i_subject               => i_subject,
                                                         i_from_state            => i_from_state,
                                                         i_tbl_blood_product_req => i_tbl_blood_product_req,
                                                         o_actions               => o_actions,
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
                                              'GET_BP_ACTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_bp_action_list;

    FUNCTION get_bp_cross_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN table_varchar,
        i_blood_product_det IN table_number,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_CROSS_ACTIONS';
        IF NOT pk_blood_products_core.get_bp_cross_actions(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_episode           => i_episode,
                                                           i_subject           => i_subject,
                                                           i_from_state        => i_from_state,
                                                           i_blood_product_det => i_blood_product_det,
                                                           o_actions           => o_actions,
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
                                              'GET_BP_CROSS_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_bp_cross_actions;

    FUNCTION get_bp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_domain IN sys_domain.code_domain%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_LIST';
        IF NOT pk_blood_products_core.get_bp_list(i_lang   => i_lang,
                                                  i_prof   => i_prof,
                                                  i_domain => i_domain,
                                                  o_list   => o_list,
                                                  o_error  => o_error)
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
                                              'GET_BP_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_list;

    FUNCTION get_bp_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_BP_TIME_LIST';
        IF NOT pk_blood_products_core.get_bp_time_list(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_epis_type => i_epis_type,
                                                       o_list      => o_list,
                                                       o_error     => o_error)
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
                                              'GET_BP_TIME_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_time_list;

    FUNCTION get_bp_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_DIAGNOSIS_LIST';
        IF NOT pk_blood_products_core.get_bp_diagnosis_list(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_episode => i_episode,
                                                            o_list    => o_list,
                                                            o_error   => o_error)
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
                                              'GET_BP_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_diagnosis_list;

    FUNCTION get_bp_special_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_priority      IN blood_product_det.flg_priority%TYPE,
        o_flg_mandatory OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_SPECIAL_TYPE_LIST';
        IF NOT pk_blood_products_core.get_bp_special_type_list(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_patient       => i_patient,
                                                               i_hemo_type     => i_hemo_type,
                                                               i_priority      => i_priority,
                                                               o_flg_mandatory => o_flg_mandatory,
                                                               o_list          => o_list,
                                                               o_error         => o_error)
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
                                              'GET_BP_SPECIAL_TYPE_LIST',
                                              o_error);
            RETURN FALSE;
    END get_bp_special_type_list;

    FUNCTION get_bp_transfusion_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_TRANSFUSION_TYPE_LIST';
        IF NOT pk_blood_products_core.get_bp_transfusion_type_list(i_lang  => i_lang,
                                                                   i_prof  => i_prof,
                                                                   o_list  => o_list,
                                                                   o_error => o_error)
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
                                              'GET_BP_TRANSFUSION_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_transfusion_type_list;

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_SPECIAL_INSTR_LIST';
        IF NOT pk_blood_products_core.get_bp_special_instr_list(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_hemo_type => i_hemo_type,
                                                                i_priority  => i_priority,
                                                                o_list      => o_list,
                                                                o_error     => o_error)
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
                                              'GET_BP_SPECIAL_INSTR_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_special_instr_list;

    FUNCTION get_bp_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_HEALTH_PLAN_LIST';
        IF NOT pk_blood_products_core.get_bp_health_plan_list(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => i_patient,
                                                              o_list    => o_list,
                                                              o_error   => o_error)
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
                                              'GET_BP_HEALTH_PLAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_health_plan_list;

    FUNCTION get_bp_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_PROF_LIST';
        IF NOT pk_blood_products_core.get_bp_prof_list(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       o_list  => o_list,
                                                       o_error => o_error)
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
                                              'GET_BP_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_bp_prof_list;

    FUNCTION get_bp_det_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_bp_req   blood_product_det.id_blood_product_req%TYPE,
        o_det_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_BLOOD_PRODUCTS_CORE.GET_BP_DET_INFO';
        IF NOT pk_blood_products_core.get_bp_det_info(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_bp_req   => i_bp_req,
                                                      o_det_info => o_det_info,
                                                      o_error    => o_error)
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
                                              'GET_BP_DET_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_det_info);
            RETURN FALSE;
    END get_bp_det_info;

    FUNCTION get_bp_newborn
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_tbl_hemo_type IN table_number,
        o_show_popup    OUT VARCHAR2,
        o_title         OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_NEWBORN';
        IF NOT pk_blood_products_core.get_bp_newborn(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_patient       => i_patient,
                                                     i_tbl_hemo_type => i_tbl_hemo_type,
                                                     o_show_popup    => o_show_popup,
                                                     o_title         => o_title,
                                                     o_msg           => o_msg,
                                                     o_error         => o_error)
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
                                              'GET_BP_NEWBORN',
                                              o_error);
            RETURN FALSE;
    END get_bp_newborn;

    FUNCTION get_bp_cancel_req_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_bp_req_info           OUT pk_types.cursor_type,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_CANCEL_REQ_INFO';
        IF NOT pk_blood_products_core.get_bp_cancel_req_info(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_patient               => i_patient,
                                                             i_tbl_blood_product_req => i_tbl_blood_product_req,
                                                             o_bp_req_info           => o_bp_req_info,
                                                             o_bp_det_info           => o_bp_det_info,
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
                                              'GET_BP_CANCEL_REQ_INFO',
                                              o_error);
            RETURN FALSE;
    END get_bp_cancel_req_info;

    FUNCTION get_bp_cancel_det_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_det IN table_number,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN AS
    BEGIN
    
        g_error := 'CALL PK_BLOOD_PRODUCTS_CORE.GET_BP_CANCEL_DET_INFO';
        IF NOT pk_blood_products_core.get_bp_cancel_det_info(i_lang                  => i_lang,
                                                             i_prof                  => i_prof,
                                                             i_patient               => i_patient,
                                                             i_tbl_blood_product_det => i_tbl_blood_product_det,
                                                             o_bp_det_info           => o_bp_det_info,
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
                                              'GET_BP_CANCEL_DET_INFO',
                                              o_error);
            RETURN FALSE;
    END get_bp_cancel_det_info;

    FUNCTION send_ref_to_bdnp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_ref   IN p1_external_request.id_external_request%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_ref_ext_sys.send_ref_to_bdnp(i_lang => i_lang, i_prof => i_prof, i_ref => i_ref, o_error => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SEND_REF_TO_BDNP',
                                                     o_error    => o_error);
    END send_ref_to_bdnp;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_blood_products_api_ux;
