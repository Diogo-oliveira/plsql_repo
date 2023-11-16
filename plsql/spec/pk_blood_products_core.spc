CREATE OR REPLACE PACKAGE pk_blood_products_core IS

    TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;

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
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number, --15
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number, --20
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --25
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2, --30
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_blood_prod_req_array    OUT NOCOPY table_number,
        o_blood_prod_det_array    OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_bp_request
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE, --5
        i_hemo_type               IN blood_product_det.id_hemo_type%TYPE,
        i_flg_time                IN blood_product_req.flg_time%TYPE,
        i_dt_begin                IN VARCHAR2,
        i_episode_destination     IN episode.id_episode%TYPE,
        i_order_recurrence        IN order_recurr_plan.id_order_recurr_plan%TYPE, --10
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis,
        i_clinical_purpose        IN blood_product_det.id_clinical_purpose%TYPE,
        i_clinical_purpose_notes  IN VARCHAR2,
        i_priority                IN blood_product_det.flg_priority%TYPE,
        i_special_type            IN blood_product_det.id_special_type%TYPE,
        i_screening               IN VARCHAR2,
        i_without_nat             IN VARCHAR2,
        i_not_send_unit           IN VARCHAR2,
        i_transf_type             IN blood_product_det.transfusion_type%TYPE,
        i_qty_exec                IN blood_product_det.qty_exec%TYPE, --15
        i_unit_qty_exec           IN blood_product_det.id_unit_mea_qty_exec%TYPE,
        i_exec_institution        IN blood_product_det.id_exec_institution%TYPE,
        i_not_order_reason        IN not_order_reason.id_not_order_reason%TYPE,
        i_special_instr           IN blood_product_det.special_instr%TYPE,
        i_notes                   IN blood_product_det.notes_tech%TYPE, --20
        i_prof_order              IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order                IN VARCHAR2,
        i_order_type              IN co_sign.id_order_type%TYPE,
        i_health_plan             IN blood_product_det.id_pat_health_plan%TYPE,
        i_exemption               IN blood_product_det.id_pat_exemption%TYPE, --25
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D', --30
        i_flg_mother_lab_tests    IN VARCHAR2 DEFAULT 'N',
        o_blood_prod_det          OUT blood_product_det.id_blood_product_det%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_bp_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_component_add
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_hemo_type         IN hemo_type.id_hemo_type%TYPE,
        i_qty_exec          IN blood_product_det.qty_exec%TYPE,
        i_unit_mea          IN blood_product_det.id_unit_mea_qty_exec%TYPE,
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
        i_desc_hemo_type_lab IN VARCHAR2,
        i_donation_code      IN VARCHAR2,
        i_flg_interface      IN VARCHAR2 DEFAULT 'N',
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_to_state          IN VARCHAR2,
        i_barcode           IN VARCHAR2,
        i_prof_match        IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_compatibility
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_compatibility IN blood_product_execution.flg_compatibility%TYPE,
        i_notes             IN blood_product_execution.notes_compatibility%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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

    FUNCTION set_bp_req_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_req IN blood_product_req.id_blood_product_req%TYPE,
        i_state             IN blood_product_req.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        i_upd_det           IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_state             IN blood_product_det.flg_status%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN blood_product_req.notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_condition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_condition     IN VARCHAR2,
        i_id_reason         IN blood_product_execution.id_action_reason%TYPE,
        i_notes             IN blood_product_execution.notes_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_lab_mother
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_lab_mother    IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bp_transfusion_confirm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_bp_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_blood_product_req       IN blood_product_req.id_blood_product_req%TYPE,
        i_blood_product_det       IN table_number,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_priority                IN table_varchar,
        i_special_type            IN table_number,
        i_screening               IN table_varchar,
        i_without_nat             IN table_varchar,
        i_not_send_unit           IN table_varchar,
        i_transf_type             IN table_varchar,
        i_qty_exec                IN table_number,
        i_unit_qty_exec           IN table_number,
        i_exec_institution        IN table_number,
        i_not_order_reason        IN table_number,
        i_special_instr           IN table_varchar,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --25
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        o_error                   OUT t_error_out
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
        i_notes_cancel      IN blood_product_req.notes%TYPE,
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
        i_notes_cancel          IN blood_product_req.notes%TYPE,
        i_flg_interface         IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_blood_product_det_qty IN table_number DEFAULT NULL,
        i_qty_given             IN table_number DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_selection_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_transport_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_bp_barcode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_barcode           IN blood_product_det.barcode_lab%TYPE DEFAULT NULL,
        i_details           IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_donation_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_donation_code     IN blood_product_det.donation_code%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_transfusions_summary
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_blood_product_det   IN table_number,
        i_flg_report          IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html            IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        o_bp_order            OUT pk_types.cursor_type,
        o_bp_execution        OUT pk_types.cursor_type,
        o_bp_adverse_reaction OUT pk_types.cursor_type,
        o_bp_reevaluation     OUT pk_types.cursor_type,
        o_bp_blood_bank       OUT pk_types.cursor_type,
        o_bp_group            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_bp_response_to_edit
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_blood_product_det    IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time             IN bp_question_response.flg_time%TYPE,
        o_bp_question_response OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_to_match_and_revise
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_list_match_screen OUT pk_types.cursor_type,
        o_list_revised      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_bp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_domain IN sys_domain.code_domain%TYPE,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_time_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_bp_special_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        i_patient       IN patient.id_patient%TYPE,
        i_hemo_type     IN hemo_type.id_hemo_type%TYPE,
        i_priority      IN blood_product_det.flg_priority%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_transfusion_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_special_instr_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_hemo_type IN hemo_type.id_hemo_type%TYPE,
        i_priority  IN blood_product_det.flg_priority%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_health_plan_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_internal_name      IN VARCHAR2,
        i_health_plan_entity IN NUMBER,
        o_error              OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_financial_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_bp_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_det_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_bp_req   blood_product_det.id_blood_product_req%TYPE,
        o_det_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_cancel_det_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_det IN table_number,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_condition_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_exec_number       IN blood_product_execution.exec_number%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html          IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html_mode     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_bp_blood_group_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN NUMBER;

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
    ) RETURN BOOLEAN;

    FUNCTION get_bp_lab_mother_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    FUNCTION get_bp_cancel_req_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_tbl_blood_product_req IN table_number,
        o_bp_req_info           OUT pk_types.cursor_type,
        o_bp_det_info           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bp_permission_cancel_req
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_bp_permission_cancel_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_det IN blood_product_det.id_blood_product_det%TYPE
    ) RETURN VARCHAR2;

    /*
    * Checks if there is any bag being administered or on hold.
    * Used in the filter BloodProductsListview, in order to assess if the modal window of quantities
    * administered should be shown when canceling a request
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_blood_product_req             Blood product requisition id
    *
    * @return    Yes or No
    */
    FUNCTION check_bp_init_admin
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_blood_product_req IN blood_product_req.id_blood_product_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION tf_get_bp_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail;

    FUNCTION tf_get_bp_detail_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail_hist;

    FUNCTION tf_get_bp_detail_history_core
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_report        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_aa_code_messages  IN t_code_messages,
        i_flg_html_det      IN VARCHAR2 DEFAULT pk_blood_products_constant.g_no
    ) RETURN t_tbl_bp_task_detail_hist_core;

    FUNCTION tf_get_bp_clinical_questions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_time          IN bp_question_response.flg_time%TYPE,
        i_flg_history       IN VARCHAR DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_bp_clinical_question;

    PROCEDURE init_params
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
    );

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_blood_products_core;
/
