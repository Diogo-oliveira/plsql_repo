/*-- Last Change Revision: $Rev: 1874685 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2018-10-25 09:48:22 +0100 (qui, 25 out 2018) $*/
CREATE OR REPLACE PACKAGE pk_immunization_ux IS

    FUNCTION get_vacc_summary_all
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_oth_vaccine_time OUT pk_types.cursor_type,
        o_oth_vaccine_par  OUT pk_types.cursor_type,
        o_oth_vaccine_val  OUT pk_types.cursor_type,
        --PNV Vaccines
        o_vaccine_group_name OUT pk_types.cursor_type,
        o_vaccine_time       OUT pk_types.cursor_type,
        o_vaccine_par        OUT pk_types.cursor_type,
        o_vaccine_val        OUT pk_types.cursor_type,
        --Tuberculin tests
        o_tuberculin_group_name OUT VARCHAR2,
        o_tuberculin_time       OUT pk_types.cursor_type,
        o_tuberculin_par        OUT pk_types.cursor_type,
        o_tuberculin_val        OUT pk_types.cursor_type,
        o_review                OUT pk_types.cursor_type,
        o_create                OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_add
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN VARCHAR2,
        i_orig       IN VARCHAR2,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_type_vacc  IN VARCHAR2,
        i_id_reg     IN NUMBER,
        i_flg_status IN VARCHAR2,
        o_val        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pnv_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_review_notes       IN VARCHAR2,
        o_review             OUT pk_types.cursor_type,
        o_vaccine_group_name OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_most_freq_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_type           IN VARCHAR2,
        i_button         IN VARCHAR2,
        o_med_freq_label OUT VARCHAR2,
        o_med_sel_label  OUT VARCHAR2,
        o_search_label   OUT VARCHAR2,
        o_med_freq       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_drug         IN drug_presc_det.id_drug%TYPE, --mi_med.id_drug%TYPE,
        i_dosage       IN drug_presc_det.dosage_description%TYPE,
        i_unit_measure IN drug_presc_det.id_unit_measure%TYPE,
        i_admin_via    IN drug_presc_det.route_id%TYPE,
        --
        i_prof_write          IN professional.id_professional%TYPE,
        i_notes_justif        IN drug_presc_det.notes_justif%TYPE,
        i_notes               IN drug_presc_det.notes%TYPE,
        i_presc_date          IN VARCHAR2,
        i_requested_by        IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --OUT
        o_test_id    OUT drug_prescription.id_drug_prescription%TYPE,
        o_id_admin   OUT drug_presc_plan.id_drug_presc_plan%TYPE,
        o_type_admin OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_application_spot_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_manufacturer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_manufacturer OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_vacc_unit_measure OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_warnings
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_vacc_form_administration
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN drug_prescription.id_drug_prescription%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_viewer_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vacc        IN vacc.id_vacc%TYPE,
        o_detail_info OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_med_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_vacc         IN vacc.id_vacc%TYPE,
        i_orig         IN VARCHAR2,
        o_vacc_med_ext OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_dose_default
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_drug   IN mi_med.id_drug%TYPE,
        o_vacc_dose OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_doc_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_drug  IN mi_med.id_drug%TYPE,
        o_vacc_doc OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_route_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_drug    IN mi_med.id_drug%TYPE,
        o_vacc_route OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_choice_type
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_administration
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_begin      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN drug_presc_det.id_drug%TYPE,
        i_id_vacc       IN vacc.id_vacc%TYPE DEFAULT NULL,
        
        --adverse reaction
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        --Application_spot
        i_application_spot      IN drug_presc_plan.application_spot_code%TYPE DEFAULT '',
        i_application_spot_desc IN drug_presc_plan.application_spot%TYPE,
        
        i_lot_number IN drug_presc_plan.lot_number%TYPE,
        i_dt_exp     IN VARCHAR2,
        
        --Manufactured
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        
        --Administration route
        i_adm_route IN VARCHAR2,
        
        --Vaccine origin
        i_vacc_origin      IN vacc_origin.id_vacc_origin%TYPE,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery IN VARCHAR2,
        i_doc_cat         IN vacc_funding_eligibility.id_vacc_funding_elig%TYPE,
        i_doc_source      IN vacc_funding_source.id_vacc_funding_source%TYPE,
        i_doc_source_desc IN drug_presc_plan.funding_source_desc%TYPE,
        
        --Ordered By
        i_order_by   IN professional.id_professional%TYPE,
        i_order_desc IN VARCHAR2,
        
        --Administer By
        i_administer_by   IN professional.id_professional%TYPE,
        i_administer_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        --Notes
        i_notes IN drug_presc_plan.notes%TYPE,
        
        o_drug_presc_plan OUT NUMBER,
        o_drug_presc_det  OUT NUMBER,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set_pat_administration_all
    *
    * @param i_lang                   Language ID
    * @param i_id_episode             Episode ID
    * @param i_prof                   Profissional ID
    * @param i_id_pat             Patient ID
    * @param i_dt_begin        array data for take date
    * @param i_prof_cat_type            category type
    * @param i_id_drug                      vaccination medication
    * @param i_vacc                            vaccination ID
    * @param o_drug_presc_plan
    * @param o_drug_presc_det        
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_result
    * @param o_msg_title
    * @param o_type_admin          type of admin
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.1.0
    * @since                          04/10/2019
    **************************************************************************/
    FUNCTION set_pat_administration_all
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN drug_prescription.id_episode%TYPE,
        i_prof          IN profissional,
        i_pat           IN patient.id_patient%TYPE,
        i_drug_presc    IN table_number,
        i_dt_begin      IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_drug       IN table_varchar,
        
        i_vacc            IN table_number,
        o_drug_presc_plan OUT NOCOPY table_number,
        o_drug_presc_det  OUT NOCOPY table_number,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_type_admin      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_adm_take_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_drug    IN drug_prescription.id_drug_prescription%TYPE,
        o_desc    OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_adm
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_drug_prescription IN drug_prescription.id_drug_prescription%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_form_report
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_drug     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_form     OUT pk_types.cursor_type,
        o_doc_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_reported
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_next_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_vacc           IN vacc.id_vacc%TYPE,
        i_dt_adm_str     IN VARCHAR2,
        o_info_next_date OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_report
    (
        i_lang               IN language.id_language%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_presc              IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_id_drug            IN mi_med.id_drug%TYPE,
        i_vacc               IN pat_vacc_adm.id_vacc%TYPE,
        i_desc_vaccine       IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_advers_react       IN vacc_adverse_reaction.id_vacc_adverse_reaction%TYPE,
        i_notes_advers_react IN drug_presc_plan.notes_advers_react%TYPE,
        
        i_application_spot_code IN pat_vacc_adm_det.application_spot_code%TYPE,
        i_application_spot      IN pat_vacc_adm_det.application_spot%TYPE DEFAULT '',
        
        i_lot_number        IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str IN VARCHAR2,
        
        i_vacc_manuf      IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        i_vacc_manuf_desc IN VARCHAR2,
        
        i_dosage_admin        IN pat_vacc_adm.dosage_admin%TYPE,
        i_dosage_unit_measure IN pat_vacc_adm.dosage_unit_measure%TYPE,
        
        i_adm_route IN VARCHAR2,
        
        i_vacc_origin      IN pat_vacc_adm_det.id_vacc_origin%TYPE DEFAULT NULL,
        i_vacc_origin_desc IN VARCHAR2,
        
        --Docs
        i_doc_vis      IN vacc_doc_vis.id_vacc_doc_vis%TYPE,
        i_doc_vis_desc IN VARCHAR2,
        
        i_dt_doc_delivery     IN VARCHAR2,
        i_vacc_funding_cat    IN pat_vacc_adm_det.id_vacc_funding_cat%TYPE DEFAULT NULL,
        i_vacc_funding_source IN pat_vacc_adm_det.id_vacc_funding_source%TYPE DEFAULT NULL,
        i_funding_source_desc IN pat_vacc_adm_det.funding_source_desc%TYPE DEFAULT NULL,
        
        i_information_source IN pat_vacc_adm_det.id_information_source%TYPE,
        i_report_orig        IN pat_vacc_adm_det.report_orig%TYPE,
        
        i_administred      IN pat_vacc_adm_det.id_administred%TYPE DEFAULT NULL,
        i_administred_desc IN VARCHAR2,
        
        --Next dose schedule
        i_dt_predicted IN VARCHAR2,
        
        i_notes IN pat_vacc_adm_det.notes%TYPE,
        
        o_id_admin   OUT NUMBER,
        o_type_admin OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_details
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        o_adm     OUT pk_types.cursor_type,
        o_desc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_update
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_vacc      IN vacc.id_vacc%TYPE,
        o_vacc_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacc_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_reg        IN vacc_update_admin.id_reg%TYPE,
        i_type       IN vacc_update_admin.flg_type%TYPE,
        i_dt_admin   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_rep_take_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vacc      IN vacc.id_vacc%TYPE,
        i_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_desc         OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_vacc_presc_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_vacc_descontinue_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN patient.id_patient%TYPE,
        i_id_vacc IN vacc.id_vacc%TYPE,
        i_dose    IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION set_discontinue_dose
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_vacc            IN pat_vacc_adm.id_vacc%TYPE,
        i_id_reason_sus   IN pat_vacc_adm_det.id_reason_sus%TYPE,
        i_suspended_notes IN pat_vacc_adm_det.suspended_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vacc       IN vacc.id_vacc%TYPE,
        i_status     IN pat_vacc.flg_status%TYPE,
        i_id_reason  IN NUMBER,
        i_notes      IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_resume_dose
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_vacc       IN pat_vacc_adm.id_vacc%TYPE,
        i_drug       IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_advers_react
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN NUMBER,
        i_type_vacc IN VARCHAR2,
        o_id_value  OUT NUMBER,
        o_notes     OUT VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_advers_react
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_reg     IN drug_prescription.id_drug_prescription%TYPE,
        i_value      IN vacc_advers_react.id_vacc_adver_reac%TYPE,
        i_notes      IN vacc_advers_react.notes_advers_react%TYPE,
        i_type_vacc  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --TUBERCULIN

    FUNCTION set_tuberculin_test_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_test_id             IN NUMBER,
        i_dt_adm              IN VARCHAR2,
        i_lote_adm            IN VARCHAR2,
        i_dt_valid            IN VARCHAR2,
        i_app_place           IN VARCHAR2,
        i_prof_write          professional.id_professional%TYPE,
        i_notes               IN VARCHAR2,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN drug_presc_plan.flg_type_date%TYPE,
        i_dosage_admin        IN drug_presc_plan.dosage%TYPE,
        i_dosage_unit_measure IN drug_presc_plan.dosage_unit_measure%TYPE,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancel_info
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --presc_det
        i_cancel_id IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op IN VARCHAR,
        --Out
        o_main_title  OUT VARCHAR2,
        o_notes_title OUT VARCHAR2,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cancel_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --presc_det
        i_cancel_id    IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_cancel_op    IN VARCHAR,
        i_notes_cancel IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_warnings
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_test_id IN drug_prescription.id_drug_prescription%TYPE,
        --OUT
        o_flg_show       OUT VARCHAR2,
        o_message_title  OUT VARCHAR2,
        o_message_text   OUT VARCHAR2,
        o_forward_button OUT VARCHAR2,
        o_back_button    OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_test_add
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_test_id IN NUMBER,
        --OUT
        o_main_title OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notes_advers_react_list
    (
        i_lang    IN language.id_language%TYPE,
        o_ap_spot OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reading_unit_list
    (
        i_lang      IN language.id_language%TYPE,
        o_read_unit OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_evaluation_values
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tuberculin_test_res
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_test_id       IN drug_prescription.id_drug_prescription%TYPE,
        i_dt_read       IN VARCHAR2,
        i_value         IN drug_presc_result.value%TYPE,
        i_evaluation    IN drug_presc_result.evaluation%TYPE,
        i_evaluation_id IN drug_presc_result.id_evaluation%TYPE,
        i_reactions     IN drug_presc_result.notes_advers_react%TYPE,
        i_prof_write    IN professional.id_professional%TYPE,
        i_notes         IN VARCHAR2,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_care_dash_vacc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_vacc    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_funding_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_vacc_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_origin_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_origin OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_funding_source
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_vacc_source OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adverse_reaction_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_adv_reaction OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_by_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pnv_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_dose_info_detail_new
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_vacc     IN vacc.id_vacc%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_emb      IN me_med.emb_id%TYPE,
        o_info     OUT pk_types.cursor_type,
        o_info_age OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Retornar a toma a administrar.
    *
    * @param      i_lang    Língua registada como preferência do profissional
    * @param      i_vacc    ID da vacina
    * @param      i_pat     ID do paciente
    * @param      i_emb     ID da embalagem
    *
    * @return     TRUE se a função termina com sucesso e FALSE caso contrário
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2007/12/10
    */

    FUNCTION get_vacc_last_take_detail_new
    (
        i_lang            IN language.id_language%TYPE,
        i_vacc            IN vacc.id_vacc%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_emb             IN me_med.emb_id%TYPE,
        i_prof            IN profissional,
        o_info_last_take  OUT pk_types.cursor_type,
        o_predicted_take  OUT pk_types.cursor_type,
        o_predicted_label OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_tuberculin_tests_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Results
        o_res_title OUT VARCHAR2,
        o_res_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        -- Adverses React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_label_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_id_admin          IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_type_admin        IN VARCHAR2,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacc_doc_value
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_barcode_desc IN VARCHAR2,
        o_vacc_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vaccines_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_vacc_id IN vacc.id_vacc%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_med_descr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_emb       IN me_med.emb_id%TYPE,
        i_med       IN VARCHAR2,
        o_med_descr OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_vacc_adm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_vacc                IN table_number,
        i_emb                 IN table_varchar,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_begin_str        IN VARCHAR2,
        i_presc               IN prescription.id_prescription%TYPE,
        i_flg_status          IN pat_vacc_adm.flg_status%TYPE,
        i_flg_orig            IN pat_vacc_adm.flg_orig%TYPE,
        i_desc_vaccine        IN pat_vacc_adm_det.desc_vaccine%TYPE,
        i_flg_advers_react    IN VARCHAR2,
        i_notes_advers_react  IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot    IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number          IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str   IN VARCHAR2,
        i_report_orig         IN pat_vacc_adm_det.report_orig%TYPE,
        i_notes               IN pat_vacc_adm_det.notes%TYPE,
        i_flg_time            IN table_varchar,
        i_takes               IN table_number,
        i_dosage              IN table_number,
        i_unit_measure        IN table_number,
        i_dt_presc            IN VARCHAR2,
        i_notes_presc         IN pat_vacc_adm.notes_presc%TYPE,
        i_prof_presc          IN pat_vacc_adm.prof_presc%TYPE,
        i_test                IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_predicted        IN VARCHAR2,
        i_flg_reported        IN VARCHAR2 DEFAULT NULL,
        i_vacc_manuf          IN vacc_manufacturer.id_vacc_manufacturer%TYPE DEFAULT NULL,
        code_mvx              IN vacc_manufacturer.code_mvx%TYPE DEFAULT NULL,
        i_flg_type_date       IN pat_vacc_adm.flg_type_date%TYPE,
        i_dosage_admin        IN table_number,
        i_dosage_unit_measure IN table_number,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_req             OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_id_admin            OUT NUMBER,
        o_type_admin          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vaccines_detail_free_text
    
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        i_reg     IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        --OUT
        --titles
        o_main_title         OUT VARCHAR2,
        o_this_take_title    OUT VARCHAR2,
        o_history_take_title OUT VARCHAR2,
        o_detail_info        OUT VARCHAR2,
        o_vacc_name          OUT VARCHAR2,
        --test info
        o_test_info OUT pk_types.cursor_type,
        --Cancel
        o_can_title OUT VARCHAR2,
        o_can_det   OUT pk_types.cursor_type,
        --Administration
        o_adm_title OUT VARCHAR2,
        o_adm_det   OUT pk_types.cursor_type,
        --Prescription
        o_presc_title OUT VARCHAR2,
        o_presc_det   OUT pk_types.cursor_type,
        --Advers React
        o_advers_react_title OUT VARCHAR2,
        o_advers_react_det   OUT pk_types.cursor_type,
        --ERROR
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacc_presc_det
    (
        i_lang               IN language.id_language%TYPE,
        i_vacc_adm           IN pat_vacc_adm.id_pat_vacc_adm%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_notes              IN pat_vacc_adm_det.notes%TYPE,
        i_flg_take_type      IN VARCHAR2,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_flg_advers_react   IN VARCHAR2,
        i_notes_advers_react IN pat_vacc_adm_det.notes_advers_react%TYPE,
        i_application_spot   IN pat_vacc_adm_det.application_spot%TYPE,
        i_lot_number         IN pat_vacc_adm_det.lot_number%TYPE,
        i_dt_expiration_str  IN VARCHAR2,
        i_dt_adm_str         IN VARCHAR2,
        i_vacc_manuf         IN vacc_manufacturer.id_vacc_manufacturer%TYPE,
        code_mvx             IN vacc_manufacturer.code_mvx%TYPE,
        i_flg_type_date      IN pat_vacc_adm_det.flg_type_date%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_immunization_ux;
/
