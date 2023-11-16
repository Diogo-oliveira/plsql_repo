/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_discharge IS

    TYPE t_rec_disch_notes IS RECORD(
        id_discharge_notes     discharge_notes.id_discharge_notes%TYPE,
        id_episode             discharge_notes.id_episode%TYPE,
        id_professional        discharge_notes.id_professional%TYPE,
        dt_creation            VARCHAR2(50 CHAR),
        epis_complaint         discharge_notes.epis_complaint%TYPE,
        epis_diagnosis         discharge_notes.epis_diagnosis%TYPE,
        recommended            discharge_notes.recommended%TYPE,
        discharge_instructions discharge_notes.discharge_instructions%TYPE,
        notes_release          discharge_notes.notes_release%TYPE,
        signature              VARCHAR2(4000));

    TYPE t_cur_discharge_notes IS REF CURSOR RETURN t_rec_disch_notes;
    TYPE t_coll_disch_notes IS TABLE OF t_rec_disch_notes;

    FUNCTION set_disch_edis_to_inp_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_disch_edis_to_inp_alert
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN discharge.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Check if the given visit has an ongoing social assistance
    * episode. When it does, this function returns a warning message
    * to be shown to the user.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_visit          visit identifier
    * @param o_flg_show       show warning message: Y/N
    * @param o_msg_title      warning message title
    * @param o_msg_text       warning message content
    * @param o_button         warning message buttons
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/01
    */
    PROCEDURE check_sw_episode
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_visit     IN visit.id_visit%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2
    );
    --
    FUNCTION get_patient_transportations
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_discharge_reason IN NUMBER,
        o_sql                 OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Devolve o detalhe da alta
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         
    * @version                        1.0 
    * @changed                        Emília Taborda
    * @since                          2007/06/18 
    **********************************************************************************************/
    FUNCTION get_disch_detail_disch
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_detail_admit
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_detail_expir
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_detail_transf
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_detail_lwbs
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_detail_ama
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Devolve os valores possiveis para o compo que indica se é necessário criar cirurgia na alta para internamento o para o bloco
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @o_sql                          cursor with contains result of domain
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Silvia Freitas
    * @version                        1.0  
    * @since                          2007/06/06
    **********************************************************************************************/
    FUNCTION get_flg_oris
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Devolve os valores possiveis para o campo MSE - Medical screening evaluation
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_mse_val                cursor with contains result of domain
    * @param o_error                  Error message
    *                        
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0  
    * @since                          2007/06/18
    **********************************************************************************************/
    FUNCTION get_mse_type_list
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        o_mse_val OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_pat_report_given_admit
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_pat_report_given_transfer
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_caretakers_disch
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_caretakers_lwbs
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_caretakers_ama
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Check if the discharge has an associated surgery episode.
    *
    * @param i_id_discharge       Discharge ID
    *                        
    * @return            'Y' if has an associated surgery episode, 'N' otherwise
    *
    * @author            Alexandre Santos
    * @version           1.0  
    * @since             2009/12/14
    **********************************************************************************************/
    FUNCTION get_flg_surgery(i_discharge IN discharge.id_discharge%TYPE) RETURN VARCHAR2;
    --
    FUNCTION get_follow_up_by_disch
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_follow_up_by_lwbs
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_follow_up_by_ama
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_flg_voluntary
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_flg_orgn_dntn_info
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_professionals
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /******************************************************************************
    * Used to return the names of all professionals, plus one free-text option ('Other').
    * 
    * @param i_lang            Professional prefered language
    * @param i_prof            Professional information
    * @param o_sql             List of all professionals, plus option 'Other'
    * 
    * @return                  TRUE if sucessfull, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-05-30
    *
    * NOTES: this function was build to use only on the USA market.
    *
    ******************************************************************************/
    FUNCTION get_all_professionals
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_services
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_disch_destination
    (
        i_lang              IN language.id_language%TYPE,
        i_id_dep_clin_serv  IN NUMBER,
        i_id_department     IN NUMBER,
        i_id_institution    IN NUMBER,
        i_id_discharge_dest IN NUMBER
    ) RETURN VARCHAR2;
    --
    /**
    * Checks if an episode was already discharged
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_EPISODE episode id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_FLG_TYPE Discharge: D - Medical, M - Administrative
    * @param   I_NOTES discharge notes
    * @param   O_HAS_DISCHARGE Y - episode was already discharged, N - otherwise
    * @param   O_ERROR error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @since   06-Jan-2009
    */
    FUNCTION check_discharge_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN discharge.id_episode%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN VARCHAR2,
        o_has_discharge OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_discharge
    (
        i_lang                         IN NUMBER,
        i_episode                      IN NUMBER,
        i_prof                         IN profissional,
        i_reas_dest                    IN NUMBER,
        i_disch_type                   IN VARCHAR2,
        i_flg_type                     IN VARCHAR2,
        i_notes                        IN VARCHAR2,
        i_transp                       IN NUMBER,
        i_justify                      IN VARCHAR2,
        i_prof_cat_type                IN VARCHAR2, -- 10
        i_flg_pat_condition            IN VARCHAR2,
        i_id_transport_type            IN NUMBER,
        i_id_disch_rea_transp_ent_inst IN NUMBER,
        i_flg_caretaker                IN VARCHAR2,
        i_caretaker_notes              IN VARCHAR2,
        i_flg_follow_up_by             IN VARCHAR2,
        i_follow_up_notes              IN VARCHAR2,
        i_follow_up_date               IN DATE,
        i_flg_written_notes            IN VARCHAR2,
        i_flg_voluntary                IN VARCHAR2, -- 20
        i_flg_pat_report               IN VARCHAR2,
        i_flg_transfer_form            IN VARCHAR2,
        i_id_prof_admitting            IN NUMBER,
        i_prof_admitting_desc          IN VARCHAR2,
        i_id_dep_clin_serv_admiting    IN NUMBER,
        i_dep_clin_serv_admiting_desc  IN VARCHAR2,
        i_flg_summary_report           IN VARCHAR2,
        i_flg_autopsy_consent          IN VARCHAR2, -- 26
        i_autopsy_consent_desc         IN VARCHAR2,
        i_flg_orgn_dntn_info           IN VARCHAR2,
        i_orgn_dntn_info               IN VARCHAR2,
        i_flg_examiner_notified        IN VARCHAR2, -- 30
        i_examiner_notified_info       IN VARCHAR2,
        i_flg_orgn_dntn_form_complete  IN VARCHAR2,
        i_flg_ama_form_complete        IN VARCHAR2,
        i_flg_lwbs_form_complete       IN VARCHAR2,
        i_add_notes                    IN VARCHAR2,
        o_flg_show                     OUT VARCHAR2,
        o_msg_title                    OUT VARCHAR2,
        o_msg_text                     OUT VARCHAR2,
        o_button                       OUT VARCHAR2,
        o_id_discharge                 OUT NUMBER,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_discharge_master
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN discharge.id_episode%TYPE,
        i_prof           IN profissional,
        i_reas_dest      IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type     IN discharge.flg_type%TYPE,
        i_flg_type       IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_transp         IN transp_entity.id_transp_entity%TYPE,
        i_justify        IN discharge.notes_justify %TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_transaction_id IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_id_discharge   OUT NUMBER,
        o_warning        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_discharge_detail
    (
        i_lang                         IN NUMBER,
        i_prof                         IN profissional,
        i_id_discharge                 IN NUMBER,
        i_flg_pat_condition            IN VARCHAR2,
        i_id_transport_type            IN NUMBER,
        i_id_disch_rea_transp_ent_inst IN NUMBER,
        i_flg_caretaker                IN VARCHAR2,
        i_caretaker_notes              IN VARCHAR2,
        i_flg_follow_up_by             IN VARCHAR2,
        i_follow_up_notes              IN VARCHAR2,
        i_follow_up_date_str           IN VARCHAR2,
        i_flg_written_notes            IN VARCHAR2,
        i_flg_voluntary                IN VARCHAR2,
        i_flg_pat_report               IN VARCHAR2,
        i_flg_transfer_form            IN VARCHAR2,
        i_id_prof_admitting            IN NUMBER,
        i_prof_admitting_desc          IN VARCHAR2,
        i_id_dep_clin_serv_admiting    IN NUMBER,
        i_dep_clin_serv_admiting_desc  IN VARCHAR2,
        i_flg_summary_report           IN VARCHAR2,
        i_flg_autopsy_consent          IN VARCHAR2,
        i_autopsy_consent_desc         IN VARCHAR2,
        i_flg_orgn_dntn_info           IN VARCHAR2,
        i_orgn_dntn_info               IN VARCHAR2,
        i_flg_examiner_notified        IN VARCHAR2,
        i_examiner_notified_info       IN VARCHAR2,
        i_flg_orgn_dntn_form_complete  IN VARCHAR2,
        i_flg_ama_form_complete        IN VARCHAR2,
        i_flg_lwbs_form_complete       IN VARCHAR2,
        i_notes                        IN VARCHAR2,
        i_flg_autopsy                  IN discharge_detail.flg_autopsy%TYPE DEFAULT NULL,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN discharge.id_episode%TYPE,
        i_prof          IN profissional,
        i_reas_dest     IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type    IN discharge.flg_type%TYPE,
        i_flg_type      IN VARCHAR2,
        i_notes         IN discharge.notes_med%TYPE,
        i_transp        IN transp_entity.id_transp_entity%TYPE,
        i_justify       IN discharge.notes_justify %TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_flg_surgery   IN VARCHAR2,
        i_clin_serv     IN clinical_service.id_clinical_service%TYPE,
        i_department    IN department.id_department%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_EPISODE episode id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_REAS_DEST discharge reason by destination
    * @param   I_DISCH_TYPE Idischarge type
    * @param   I_FLG_TYPE flag type
    * @param   I_NOTES discharge notes
    * @param   I_TRANSP transport id
    * @param   I_JUSTIFY discharge justify
    * @param   I_PRICE appointment price
    * @param   I_CURRENCY appointment price currency
    * @param   I_FLG_PAYMENT payment condition
    * @param   I_FLG_SURGERY  Y/N, INDICA SE É PRECISO CRIAR CIRURGIA
    * @param   I_FLG_SURGERY - indicates if discharge for internment is associated to a surgery (Y/N)
    * @param   I_CLIN_SERV - id_clinical_service of internment speciality, in case od discharge for internment
    * @param   i_flg_print_report - flg print report
    * @param   i_flg_letter - type of discharge letter: P - print discharge letter; S - send discharge letter message
    * @param   i_flg_task - list of tasks associated with the discharge letter
    
    * @param   O_FLG_SHOW does it shows buttons
    * @param   O_MSG_TITLE warning/error message title
    * @param   O_MSG_TEXT warning/error message
    * @param   O_BUTTON OUT the buttons to show in the warning/error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   24-Jan-2006
    * NOTAS: LG 2007-fev-08
    */
    FUNCTION set_discharge_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN discharge.id_episode%TYPE,
        i_prof           IN profissional,
        i_reas_dest      IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type     IN discharge.flg_type%TYPE,
        i_flg_type       IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_transp         IN transp_entity.id_transp_entity%TYPE,
        i_justify        IN discharge.notes_justify %TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_price          IN discharge.price%TYPE,
        i_currency       IN discharge.currency%TYPE,
        i_flg_payment    IN discharge.flg_payment%TYPE,
        i_flg_surgery    IN VARCHAR2,
        i_dt_surgery     IN VARCHAR2,
        i_clin_serv      IN clinical_service.id_clinical_service%TYPE,
        i_department     IN department.id_department%TYPE,
        i_transaction_id IN VARCHAR2,
        i_flg_bill_type  IN discharge.flg_bill_type%TYPE,
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report    IN discharge_detail.flg_print_report%TYPE DEFAULT NULL,
        i_flg_letter          IN discharge_rep_notes.flg_type%TYPE,
        i_flg_task            IN discharge_rep_notes.flg_task%TYPE,
        i_sysdate             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_pat_condition   IN discharge_detail.flg_pat_condition%TYPE,
        i_flg_hist            IN VARCHAR2,
        i_dt_fw_visit         IN VARCHAR2,
        i_id_dep_clin_serv_fw IN discharge_detail.id_dep_clin_serv_fw%TYPE,
        i_id_prof_fw          IN discharge_detail.id_prof_fw%TYPE,
        i_sched_notes         IN discharge_detail.sched_notes%TYPE,
        i_id_complaint_fw     IN discharge_detail.id_complaint_fw%TYPE,
        i_reason_for_visit_fw IN discharge_detail.reason_for_visit_fw%TYPE,
        i_dt_med              IN VARCHAR2 DEFAULT NULL,
        
        i_id_concept_term         IN concept_term.id_concept_term%TYPE DEFAULT NULL,
        i_id_cncpt_trm_inst_owner IN concept_term.id_inst_owner%TYPE DEFAULT NULL,
        i_id_terminology_version  IN terminology_version.id_terminology_version%TYPE DEFAULT NULL,
        i_flg_type_closure        IN discharge_detail.flg_type_closure%TYPE DEFAULT NULL,
        
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_id_shortcut      OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_discharge_detail OUT discharge_detail.id_discharge_detail%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_EPISODE episode id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_REAS_DEST discharge reason by destination
    * @param   I_DISCH_TYPE Idischarge type
    * @param   I_FLG_TYPE flag type
    * @param   I_NOTES discharge notes
    * @param   I_TRANSP transport id
    * @param   I_JUSTIFY discharge justify
    * @param   I_PRICE appointment price
    * @param   I_CURRENCY appointment price currency
    * @param   I_FLG_PAYMENT payment condition
    * @param   I_FLG_SURGERY  Y/N, INDICA SE É PRECISO CRIAR CIRURGIA
    * @param   I_FLG_SURGERY - indicates if discharge for internment is associated to a surgery (Y/N)
    * @param   I_CLIN_SERV - id_clinical_service of internment speciality, in case od discharge for internment
    * @param   i_flg_print_report - flg print report
    * @param   i_flg_letter - type of discharge letter: P - print discharge letter; S - send discharge letter message
    * @param   i_flg_task - list of tasks associated with the discharge letter
    
    * @param   O_FLG_SHOW does it shows buttons
    * @param   O_MSG_TITLE warning/error message title
    * @param   O_MSG_TEXT warning/error message
    * @param   O_BUTTON OUT the buttons to show in the warning/error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luis Gaspar
    * @version 1.0
    * @since   24-Jan-2006
    * NOTAS: LG 2007-fev-08
    */
    FUNCTION set_discharge_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN discharge.id_episode%TYPE,
        i_prof           IN profissional,
        i_reas_dest      IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type     IN discharge.flg_type%TYPE,
        i_flg_type       IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_transp         IN transp_entity.id_transp_entity%TYPE,
        i_justify        IN discharge.notes_justify %TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_price          IN discharge.price%TYPE,
        i_currency       IN discharge.currency%TYPE,
        i_flg_payment    IN discharge.flg_payment%TYPE,
        i_flg_surgery    IN VARCHAR2,
        i_dt_surgery     IN VARCHAR2,
        i_clin_serv      IN clinical_service.id_clinical_service%TYPE,
        i_department     IN department.id_department%TYPE,
        i_transaction_id IN VARCHAR2,
        i_flg_bill_type  IN discharge.flg_bill_type%TYPE,
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report IN discharge_detail.flg_print_report%TYPE DEFAULT NULL,
        i_flg_letter       IN discharge_rep_notes.flg_type%TYPE,
        i_flg_task         IN discharge_rep_notes.flg_task%TYPE,
        i_flg_hist         IN VARCHAR2,
        i_dt_med           IN VARCHAR2 DEFAULT NULL,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE DEFAULT NULL,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_id_shortcut      OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_discharge_detail OUT discharge_detail.id_discharge_detail%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_discharge_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN discharge.id_episode%TYPE,
        i_prof           IN profissional,
        i_reas_dest      IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type     IN discharge.flg_type%TYPE,
        i_flg_type       IN VARCHAR2,
        i_notes          IN discharge.notes_med%TYPE,
        i_transp         IN transp_entity.id_transp_entity%TYPE,
        i_justify        IN discharge.notes_justify %TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_price          IN discharge.price%TYPE,
        i_currency       IN discharge.currency%TYPE,
        i_flg_payment    IN discharge.flg_payment%TYPE,
        i_flg_surgery    IN VARCHAR2,
        i_dt_surgery     IN VARCHAR2,
        i_clin_serv      IN clinical_service.id_clinical_service%TYPE,
        i_department     IN department.id_department%TYPE,
        i_transaction_id IN VARCHAR2,
        i_flg_bill_type  IN discharge.flg_bill_type%TYPE,
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report  IN discharge_detail.flg_print_report%TYPE DEFAULT NULL,
        i_flg_letter        IN discharge_rep_notes.flg_type%TYPE,
        i_flg_task          IN discharge_rep_notes.flg_task%TYPE,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_pat_condition IN discharge_detail.flg_pat_condition%TYPE,
        i_flg_hist          IN VARCHAR2,
        i_flg_type_closure  IN discharge_detail.flg_type_closure%TYPE DEFAULT NULL,
        o_reports_pat       OUT reports.id_reports%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_id_episode        OUT episode.id_episode%TYPE,
        o_id_shortcut       OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_discharge         OUT discharge.id_discharge%TYPE,
        o_discharge_detail  OUT discharge_detail.id_discharge_detail%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param i_lang        language associated to the professional executing the request
    * @param i_episode     episode id
    * @param i_prof        professional, institution and software ids
    * @param i_reas_dest   discharge reason by destination
    * @param i_disch_type  discharge type
    * @param i_flg_type    flag type
    * @param i_notes       discharge notes
    * @param i_transp      transport id
    * @param i_justify     discharge justify
    * @param i_price       appointment price
    * @param i_currency    appointment price currency
    * @param i_flg_payment payment condition
    * @param o_flg_show    does it shows buttons
    * @param o_msg_title   warning/error message title
    * @param o_msg_text    warning/error message
    * @param o_button      out the buttons to show in the warning/error
    * @param o_error       Error message
    *
    * @return              TRUE if sucess, FALSE otherwise
    *
    * @author              Luis Gaspar
    * @version             1.0
    * @since               24-Jan-2006
    **********************************************************************************************/
    FUNCTION set_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN discharge.id_episode%TYPE,
        i_prof          IN profissional,
        i_reas_dest     IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type    IN discharge.flg_type%TYPE,
        i_flg_type      IN VARCHAR2,
        i_notes         IN discharge.notes_med%TYPE,
        i_transp        IN transp_entity.id_transp_entity%TYPE,
        i_justify       IN discharge.notes_justify %TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_price         IN discharge.price%TYPE,
        i_currency      IN discharge.currency%TYPE,
        i_flg_payment   IN discharge.flg_payment%TYPE,
        i_flg_surgery   IN VARCHAR2,
        i_clin_serv     IN clinical_service.id_clinical_service%TYPE,
        i_department    IN department.id_department%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    FUNCTION set_nurse_discharge
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN nurse_discharge.id_episode%TYPE,
        i_prof    IN profissional,
        i_notes   IN nurse_discharge.notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    *  End of session MFR
    *
    * @param i_lang                   language ID
    * @param i_episode                Id episode
    * @param i_prof                   Professional details
    * @param i_notes                   Notes discharge
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Rita Lopes
    * @version                        2.4.3
    * @since                          2008/06/25
    **********************************************************************************************/

    FUNCTION set_therapist_discharge
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN nurse_discharge.id_episode%TYPE,
        i_prof    IN profissional,
        i_notes   IN discharge.notes_therapist%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION cancel_nurse_discharge
    (
        i_lang               IN language.id_language%TYPE,
        i_id_nurse_discharge IN nurse_discharge.id_nurse_discharge%TYPE,
        i_prof               IN profissional,
        i_notes              IN nurse_discharge.notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN discharge.id_episode%TYPE,
        i_prof          IN profissional,
        i_category_type IN category.flg_type%TYPE,
        o_disch         OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_flg_create    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge
    (
        i_lang                 IN language.id_language%TYPE,
        i_episode              IN discharge.id_episode%TYPE,
        i_prof                 IN profissional,
        i_category_type        IN category.flg_type%TYPE,
        i_flg_type             IN VARCHAR2,
        o_disch                OUT pk_types.cursor_type,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_text             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_flg_create           OUT VARCHAR2,
        o_sync_client_registry OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_discharge_detail
    (
        i_lang  IN language.id_language%TYPE,
        i_disch IN discharge.id_discharge%TYPE,
        i_prof  IN profissional,
        o_disch OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --   
    /**********************************************************************************************
    * Check if the episode has associated inpatient or surgery episodes.
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param o_flg_show           Show popup message
    * @param o_msg_title          Message title
    * @param o_msg_text           Message text
    * @param o_button             Popup button
    * @param o_error              Error message
    *                        
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/02/03
    **********************************************************************************************/
    FUNCTION check_created_episodes
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**********************************************************************************************
    * Cancel administrative discharge. To be used by Flash.
    *
    * @param i_lang                   language ID
    * @param i_prof                   Professional Info
    * @param i_id_epis                Episode ID
    * @param i_id_discharge           Discharge ID
    * @param i_id_cancel_reason       Cancel reason ID
    * @param i_notes_cancel           Cancellation notes
    * @param o_flg_show               Show message: Y - Yes; N -  No
    * @param o_msg                    Message text
    * @param o_msg_title              Message title
    * @param o_button                 Button to show  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/08/19 
    **********************************************************************************************/
    FUNCTION cancel_admin_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis          IN episode.id_episode%TYPE,
        i_id_discharge     IN discharge.id_discharge%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN discharge.notes_cancel%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel administrative discharge
    *
    * @param i_lang                   language ID
    * @param i_prof                   Professional Info
    * @param i_id_epis                Episode ID
    * @param i_id_discharge           Discharge ID
    * @param i_id_cancel_reason       Cancel reason ID
    * @param i_notes_cancel           Cancellation notes
    * @param i_dt_cancel              Cancellation date
    * @param o_flg_show               Show message: Y - Yes; N -  No
    * @param o_msg                    Message text
    * @param o_msg_title              Message title
    * @param o_button                 Button to show  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        2.6.0.4
    * @since                          2010/08/19 
    **********************************************************************************************/
    FUNCTION cancel_admin_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis          IN episode.id_episode%TYPE,
        i_id_discharge     IN discharge.id_discharge%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN discharge.notes_cancel%TYPE,
        i_dt_cancel        IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_prof         IN profissional,
        i_notes_cancel IN discharge.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * @param i_transaction_id   Transaction id for the new scheduler
    */
    FUNCTION cancel_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_id_discharge     IN discharge.id_discharge%TYPE,
        i_prof             IN profissional,
        i_notes_cancel     IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_dt_cancel        IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Overrides the cancel discharge to avoid passing i_transaction_id that is needed 
     * in the new scheduler
     * 
    */
    FUNCTION cancel_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_id_discharge     IN discharge.id_discharge%TYPE,
        i_prof             IN profissional,
        i_notes_cancel     IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_epis_recomend
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        i_prof     IN profissional,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * @return boolean
    *
    * @author                   Joel Lopes
    * @since                    28/01/2014
    ********************************************************************************************/
    FUNCTION get_epis_recomend_rep
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        i_flg_rep  IN VARCHAR2,
        i_prof     IN profissional,
        o_temp     OUT pk_types.cursor_type,
        o_def      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_epis_recomend_det
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_recomend.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN epis_recomend.flg_type%TYPE,
        o_det      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get detail and history of epis_recomend record.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_epis_rec     record identifier
    * @param o_detail       detail
    * @param o_history      history
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/08/24
    */
    FUNCTION get_epis_recomend_hist
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_rec IN epis_recomend.id_epis_recomend%TYPE,
        o_detail   OUT pk_types.cursor_type,
        o_history  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_plan_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN table_number,
        o_plan_text OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels record from epis_recomend.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_epis_rec     record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/08/23
    */
    FUNCTION set_epis_recomend_cancel
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_epis_rec IN epis_recomend.id_epis_recomend%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels record from epis_recomend (no commit).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_epis_rec     record identifier
    * @param i_reason       cancel reason identifier
    * @param i_notes        cancel notes
    * @param o_epis_rec     created record identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/08/23
    */
    FUNCTION set_epis_recomend_cancel_int
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_rec IN epis_recomend.id_epis_recomend%TYPE,
        i_reason   IN cancel_info_det.id_cancel_reason%TYPE,
        i_notes    IN cancel_info_det.notes_cancel_long%TYPE,
        o_epis_rec OUT epis_recomend.id_epis_recomend%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_epis_recomend_int
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN epis_recomend.id_episode%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_type         IN epis_recomend.flg_type%TYPE,
        i_desc             IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_parent           IN epis_recomend.id_epis_recomend%TYPE,
        o_id_epis_recomend OUT epis_recomend.id_epis_recomend%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_epis_recomend
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN epis_recomend.id_episode%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN epis_recomend.flg_type%TYPE,
        i_desc             IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_parent           IN epis_recomend.id_epis_recomend_parent%TYPE := NULL,
        o_id_epis_recomend OUT epis_recomend.id_epis_recomend%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION check_exist_clin_disch
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN discharge.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;
    --
    FUNCTION get_discharge_type
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_nurse_discharge
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN discharge.id_episode%TYPE,
        i_prof    IN profissional,
        o_temp    OUT pk_types.cursor_type,
        o_def     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /******************************************************************************
       OBJECTIVO:   Obter detalhe de recomendações por profissional e tipo.
       PARAMETROS:  Entrada:I_LANG - Língua registada como preferência do profissional
                            I_EPISODE - ID do episódio
                     Saida: O_DET - Detalhe de recomendações
                            O_ERROR - erro
    
      CRIAÇÃO: SS 2006/10/12
      NOTAS:
    *********************************************************************************/
    FUNCTION get_nurse_discharge_det
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN epis_recomend.id_episode%TYPE,
        i_prof    IN profissional,
        o_det     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_admin_discharge
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN discharge.id_episode%TYPE,
        i_prof    IN profissional,
        o_disch   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_transp_entity_list
    (
        i_lang   IN language.id_language%TYPE,
        i_type   IN transp_entity.flg_type%TYPE,
        i_transp IN transp_entity.flg_transp%TYPE,
        i_prof   IN profissional,
        o_transp OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    PROCEDURE set_end_day_discharges;
    --
    /*************************************************************************************
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param i_lang          language associated to the professional executing the request
    * @param i_prof          professional, institution and software ids
    * @param i_id_discharge  the discharge id
    * @param i_payment       the new payment state, true if payed, false otherwise
    * @param o_error         error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Luis Gaspar
    * @version               1.0
    * @since                 30-Jan-2006
    *************************************************************************************/
    FUNCTION set_payment
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN episode.id_episode%TYPE,
        i_payment      IN VARCHAR2,
        i_price        IN discharge.price%TYPE,
        i_currency     IN discharge.currency%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_default_admin_disch_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_defaults   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Criar registo de alta (DISCHARGE -  master and detail). Alterar nos MCDTs o ID_EPISODE e actualizar o ID_PREV_EPISODE
    *
    * @param i_lang                           language id
    * @param i_episode                        episode id
    * @param i_prof                           professional, software and institution ids
    * @param i_prof_cat_type                  Categoria do profissional
    * @param i_flg_new_epis                   Tipo do novo episódio
    * @param i_reas_dest                      Relação motivo e destino da alta
    * @param i_disch_type                     Tipo de alta: F - Fim do episódio; D - Alta
    * @param i_flg_type                       Tipo: D - Alta médica; M - Alta administrativa
    * @param i_notes                          Notas da alta
    * @param i_notes_det                      Notas do detalhe da alta
    * @param i_transp                         Transporte indicado pelo médico ou administrativo
    * @param i_notes_justify                  Notas de justificação
    * @param i_flg_pat_condition              Patient conditions: (i)mproved, (u)nchanged, (s)table, (w)orse, (o)ther
    * @param i_id_transport_type              Tipo de transporte
    * @param i_id_disch_rea_t_ent_inst 
    * @param i_flg_caretaker                  Caretaker Flag: (C)aretaker, (F)amily, (P)atient, (N)one, (O)ther
    * @param i_caretaker_notes                Notes for individual responsible for additional care and instructions
    * @param i_flg_follow_up_by               Type of Professional for performs the follow-up: (P)rimary care doctor, (N)one, (O)ther
    * @param i_follow_up_notes                Notes for follow-up
    * @param i_follow_up_date                 Date/Time of Follow-up
    * @param i_flg_written_notes              Flag indicates if there is additional WRITTEN instructions
    * @param i_flg_voluntary 
    * @param i_flg_pat_report 
    * @param i_flg_transfer_form
    * @param i_id_prof_admitting 
    * @param i_prof_admitting_desc 
    * @param i_id_dep_clin_serv_admit 
    * @param i_dep_clin_serv_ad_desc 
    * @param i_flg_summary_report 
    * @param i_flg_autopsy_consent 
    * @param i_autopsy_consent_desc 
    * @param i_flg_orgn_dntn_info 
    * @param i_orgn_dntn_info 
    * @param i_flg_examiner_notified 
    * @param i_examiner_notified_info 
    * @param i_flg_orgn_dntn_f_compl 
    * @param i_flg_ama_form_complete 
    * @param i_flg_lwbs_form_complete 
    * @param i_price                          Preço da consulta
    * @param i_currency                       Moeda
    * @param i_flg_payment                    Estado do pagamento:Pagou ou não pago
    * @param i_flg_status 
    * @param i_mse_type                       MSE (Medical screening evaluation)
    * @param i_flg_surgery                    Flg surgery
    * @param i_dt_surgery_str                 surgery date
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    * @param o_flg_show 
    * @param o_msg_title 
    * @param o_msg_text 
    * @param o_button 
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Emília Taborda
    * @version                                1.0  
    * @since                                  23-02-2007
    ********************************************************************************************/
    FUNCTION set_epis_discharge_no_commit
    (
        i_lang                       IN NUMBER,
        i_episode                    IN NUMBER,
        i_prof                       IN profissional,
        i_prof_cat_type              IN category.flg_type%TYPE,
        i_flg_new_epis               IN VARCHAR2,
        i_reas_dest                  IN NUMBER,
        i_disch_type                 IN VARCHAR2,
        i_flg_type                   IN VARCHAR2,
        i_notes                      IN discharge.notes_med%TYPE,
        i_notes_det                  IN discharge_detail.notes%TYPE,
        i_transp                     IN discharge.id_transp_ent_med%TYPE,
        i_notes_justify              IN discharge.notes_justify%TYPE,
        i_flg_pat_condition          IN discharge_detail.flg_pat_condition%TYPE,
        i_id_transport_type          IN discharge_detail.id_transport_type%TYPE,
        i_id_disch_rea_t_ent_inst    IN discharge_detail.id_disch_rea_transp_ent_inst%TYPE,
        i_flg_caretaker              IN discharge_detail.flg_caretaker%TYPE,
        i_caretaker_notes            IN discharge_detail.caretaker_notes%TYPE,
        i_flg_follow_up_by           IN discharge_detail.flg_follow_up_by%TYPE,
        i_follow_up_notes            IN discharge_detail.follow_up_notes%TYPE,
        i_follow_up_date_str         IN VARCHAR2,
        i_flg_written_notes          IN discharge_detail.flg_written_notes%TYPE,
        i_flg_voluntary              IN discharge_detail.flg_voluntary%TYPE,
        i_flg_pat_report             IN discharge_detail.flg_pat_report%TYPE,
        i_flg_transfer_form          IN discharge_detail.flg_transfer_form%TYPE,
        i_id_prof_admitting          IN discharge_detail.id_prof_admitting%TYPE,
        i_prof_admitting_desc        IN discharge_detail.prof_admitting_desc%TYPE,
        i_id_dep_clin_serv_admit     IN discharge_detail.id_dep_clin_serv_admiting%TYPE,
        i_dep_clin_serv_ad_desc      IN discharge_detail.dep_clin_serv_admiting_desc%TYPE,
        i_flg_summary_report         IN discharge_detail.flg_summary_report%TYPE,
        i_flg_autopsy_consent        IN discharge_detail.flg_autopsy_consent%TYPE,
        i_autopsy_consent_desc       IN discharge_detail.autopsy_consent_desc%TYPE,
        i_flg_orgn_dntn_info         IN discharge_detail.flg_orgn_dntn_info%TYPE,
        i_orgn_dntn_info             IN discharge_detail.orgn_dntn_info%TYPE,
        i_flg_examiner_notified      IN discharge_detail.flg_examiner_notified%TYPE,
        i_examiner_notified_info     IN discharge_detail.examiner_notified_info%TYPE,
        i_flg_orgn_dntn_f_compl      IN discharge_detail.flg_orgn_dntn_form_complete%TYPE,
        i_flg_ama_form_complete      IN discharge_detail.flg_ama_form_complete%TYPE,
        i_flg_lwbs_form_complete     IN discharge_detail.flg_lwbs_form_complete%TYPE,
        i_price                      IN discharge.price%TYPE,
        i_currency                   IN discharge.currency%TYPE,
        i_flg_payment                IN discharge.flg_payment%TYPE,
        i_flg_status                 IN discharge.flg_status%TYPE,
        i_mse_type                   IN discharge_detail.mse_type%TYPE,
        i_flg_surgery                IN discharge_detail.flg_surgery%TYPE,
        i_date_surgery_str           IN VARCHAR2,
        i_flg_print_report           IN VARCHAR2,
        i_transaction_id             IN VARCHAR2,
        i_transfer_diagnosis         IN discharge_detail.id_transfer_diagnosis%TYPE,
        i_flg_inst_transfer          IN discharge_detail.flg_inst_transfer%TYPE,
        i_dt_admin                   IN VARCHAR2,
        i_flg_autopsy                IN discharge_detail.flg_autopsy%TYPE,
        i_dt_med                     IN VARCHAR2 DEFAULT NULL,
        i_death_process_registration IN discharge_detail.death_process_registration%TYPE DEFAULT NULL,
        o_flg_show                   OUT VARCHAR2,
        o_msg_title                  OUT VARCHAR2,
        o_msg_text                   OUT VARCHAR2,
        o_button                     OUT VARCHAR2,
        o_id_episode                 OUT episode.id_episode%TYPE,
        o_id_discharge               OUT discharge.id_discharge%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Validar se é possivél proceder à alta do paciente - Discharge do episódio
    *
    * @param i_lang                  language id
    * @param i_episode               episode id
    * @param i_prof                  professional, software and institution ids
    * @param i_patient               patient id   
    * @param i_reas_dest             Relação motivo e destino da alta
    * @param i_disch_type            Tipo de alta: F - Fim do episódio; D - Alta
    * @param i_flg_type              Tipo: D - Alta médica; M - Alta administrativa
    * @param o_epis_type_new_epis    Tipo do novo episódio        
    * @param o_flg_type_new_epis     Estado do novo episódio        
    * @param o_flg_new_epis          Criação de novo episódio: Y - Yes; N - No    
    * @param o_screen                Ecran a ser visualizado no caso da relação Motivo/Destino obrigar a criar um novo episódio
    * @param o_flg_show_msg          Flag: Y - existe msg para mostrar; N - ñ existe  
    * @param o_msg                   Mensagem a mostrar
    * @param o_msg_title             Título da mensagem
    * @param o_button                Botões a mostrar: R - lido
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         12-02-2007
    ********************************************************************************************/
    FUNCTION check_epis_discharge
    (
        i_lang               IN NUMBER,
        i_episode            IN NUMBER,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_reas_dest          IN NUMBER,
        i_disch_type         IN VARCHAR2,
        i_flg_type           IN VARCHAR2,
        o_epis_type_new_epis OUT episode.id_epis_type%TYPE,
        o_flg_type_new_epis  OUT episode.flg_type%TYPE,
        o_flg_new_epis       OUT VARCHAR2,
        o_screen             OUT VARCHAR2,
        o_flg_show_msg       OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Criar registo de alta (DISCHARGE -  master and detail)
    *
    * @param i_lang                           language id
    * @param i_episode                        episode id
    * @param i_prof                           professional, software and institution ids
    * @param i_prof_cat_type                  Categoria do profissional
    * @param i_reas_dest                      Relação motivo e destino da alta
    * @param i_disch_type                     Tipo de alta: F - Fim do episódio; D - Alta
    * @param i_flg_type                       Tipo: D - Alta médica; M - Alta administrativa
    * @param i_notes                          Notas da alta
    * @param i_notes_det                      Notas do detalhe da alta
    * @param i_transp                         Transporte indicado pelo médico ou administrativo
    * @param i_notes_justify                  Notas de justificação
    * @param i_flg_pat_condition              Patient conditions: (i)mproved, (u)nchanged, (s)table, (w)orse, (o)ther
    * @param i_id_transport_type              Tipo de transporte
    * @param i_id_disch_rea_t_ent_inst 
    * @param i_flg_caretaker                  Caretaker Flag: (C)aretaker, (F)amily, (P)atient, (N)one, (O)ther
    * @param i_caretaker_notes                Notes for individual responsible for additional care and instructions
    * @param i_flg_follow_up_by               Type of Professional for performs the follow-up: (P)rimary care doctor, (N)one, (O)ther
    * @param i_follow_up_notes                Notes for follow-up
    * @param i_follow_up_date                 Date/Time of Follow-up
    * @param i_flg_written_notes              Flag indicates if there is additional WRITTEN instructions
    * @param i_flg_voluntary 
    * @param i_flg_pat_report 
    * @param i_flg_transfer_form
    * @param i_id_prof_admitting 
    * @param i_prof_admitting_desc 
    * @param i_id_dep_clin_serv_admit 
    * @param i_dep_clin_serv_ad_desc 
    * @param i_flg_summary_report 
    * @param i_flg_autopsy_consent 
    * @param i_autopsy_consent_desc 
    * @param i_flg_orgn_dntn_info 
    * @param i_orgn_dntn_info 
    * @param i_flg_examiner_notified 
    * @param i_examiner_notified_info 
    * @param i_flg_orgn_dntn_f_compl 
    * @param i_flg_ama_form_complete 
    * @param i_flg_lwbs_form_complete 
    * @param i_price                          Preço da consulta
    * @param i_currency                       Moeda
    * @param i_flg_payment                    Estado do pagamento:Pagou ou não pago
    * @param i_flg_status 
    * @param i_mse_type                       MSE (Medical screening evaluation)
    * @param o_flg_show 
    * @param o_msg_title 
    * @param o_msg_text 
    * @param o_button 
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Emília Taborda
    * @version                                1.0  
    * @since                                  06-02-2007
    ********************************************************************************************/
    FUNCTION set_epis_discharge
    (
        i_lang                       IN NUMBER,
        i_episode                    IN NUMBER,
        i_prof                       IN profissional,
        i_prof_cat_type              IN category.flg_type%TYPE,
        i_flg_new_epis               IN VARCHAR2,
        i_reas_dest                  IN NUMBER,
        i_disch_type                 IN VARCHAR2,
        i_flg_type                   IN VARCHAR2,
        i_notes                      IN discharge.notes_med%TYPE,
        i_notes_det                  IN discharge_detail.notes%TYPE,
        i_transp                     IN discharge.id_transp_ent_med%TYPE,
        i_notes_justify              IN discharge.notes_justify%TYPE,
        i_flg_pat_condition          IN discharge_detail.flg_pat_condition%TYPE,
        i_id_transport_type          IN discharge_detail.id_transport_type%TYPE,
        i_id_disch_rea_t_ent_inst    IN discharge_detail.id_disch_rea_transp_ent_inst%TYPE,
        i_flg_caretaker              IN discharge_detail.flg_caretaker%TYPE,
        i_caretaker_notes            IN discharge_detail.caretaker_notes%TYPE,
        i_flg_follow_up_by           IN discharge_detail.flg_follow_up_by%TYPE,
        i_follow_up_notes            IN discharge_detail.follow_up_notes%TYPE,
        i_follow_up_date_str         IN VARCHAR2,
        i_flg_written_notes          IN discharge_detail.flg_written_notes%TYPE,
        i_flg_voluntary              IN discharge_detail.flg_voluntary%TYPE,
        i_flg_pat_report             IN discharge_detail.flg_pat_report%TYPE,
        i_flg_transfer_form          IN discharge_detail.flg_transfer_form%TYPE,
        i_id_prof_admitting          IN discharge_detail.id_prof_admitting%TYPE,
        i_prof_admitting_desc        IN discharge_detail.prof_admitting_desc%TYPE,
        i_id_dep_clin_serv_admit     IN discharge_detail.id_dep_clin_serv_admiting%TYPE,
        i_dep_clin_serv_ad_desc      IN discharge_detail.dep_clin_serv_admiting_desc%TYPE,
        i_flg_summary_report         IN discharge_detail.flg_summary_report%TYPE,
        i_flg_autopsy_consent        IN discharge_detail.flg_autopsy_consent%TYPE,
        i_autopsy_consent_desc       IN discharge_detail.autopsy_consent_desc%TYPE,
        i_flg_orgn_dntn_info         IN discharge_detail.flg_orgn_dntn_info%TYPE,
        i_orgn_dntn_info             IN discharge_detail.orgn_dntn_info%TYPE,
        i_flg_examiner_notified      IN discharge_detail.flg_examiner_notified%TYPE,
        i_examiner_notified_info     IN discharge_detail.examiner_notified_info%TYPE,
        i_flg_orgn_dntn_f_compl      IN discharge_detail.flg_orgn_dntn_form_complete%TYPE,
        i_flg_ama_form_complete      IN discharge_detail.flg_ama_form_complete%TYPE,
        i_flg_lwbs_form_complete     IN discharge_detail.flg_lwbs_form_complete%TYPE,
        i_price                      IN discharge.price%TYPE,
        i_currency                   IN discharge.currency%TYPE,
        i_flg_payment                IN discharge.flg_payment%TYPE,
        i_flg_status                 IN discharge.flg_status%TYPE,
        i_mse_type                   IN discharge_detail.mse_type%TYPE,
        i_flg_surgery                IN discharge_detail.flg_surgery%TYPE,
        i_date_surgery_str           IN VARCHAR2,
        i_flg_print_report           IN VARCHAR2,
        i_transfer_diagnosis         IN discharge_detail.id_transfer_diagnosis%TYPE,
        i_flg_inst_transfer          IN discharge_detail.flg_inst_transfer%TYPE,
        i_dt_admin                   IN VARCHAR2,
        i_flg_autopsy                IN discharge_detail.flg_autopsy%TYPE,
        i_dt_med                     IN VARCHAR2 DEFAULT NULL,
        i_death_process_registration IN discharge_detail.death_process_registration%TYPE DEFAULT NULL,
        o_flg_show                   OUT VARCHAR2,
        o_msg_title                  OUT VARCHAR2,
        o_msg_text                   OUT VARCHAR2,
        o_button                     OUT VARCHAR2,
        o_reports                    OUT reports.id_reports%TYPE, --odete monteiro 7/9/2007
        o_reports_pat                OUT reports.id_reports%TYPE,
        o_id_episode                 OUT episode.id_episode%TYPE,
        o_id_discharge               OUT discharge.id_discharge%TYPE,
        o_shortcut                   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /********************************************************************************************
    * Alterar nos MCDTs o ID_EPISODE e actualizar o ID_EPISODE_ORIGIN
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_prof_cat_type   Category professional
    * @param i_episode         episode id
    * @param i_new_episode     ID do novo episódio 
    * @param i_new_epis_type   Tipo do novo episódio
    * @param i_dep_clin_serv   Clinical service department id    
    * @param i_patient         patient id        
    * @param o_error           error message
    *
    * @return                  TRUE if sucess, FALSE otherwise
    *
    * @author                  Emília Taborda
    * @version                 1.0  
    * @since                   19-02-2007
    ********************************************************************************************/
    FUNCTION set_mcdt_episode_origin
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_new_episode   IN episode.id_episode%TYPE,
        i_new_epis_type IN epis_type.id_epis_type%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Criar registo de alta (DISCHARGE -  master and detail). Alterar nos MCDTs o ID_EPISODE e actualizar o ID_PREV_EPISODE
    *
    * @param i_lang                           language id
    * @param i_episode                        episode id
    * @param i_prof                           professional, software and institution ids
    * @param i_prof_cat_type                  Categoria do profissional
    * @param i_flg_new_epis  
    * @param i_reas_dest                      Relação motivo e destino da alta
    * @param i_disch_type                     Tipo de alta: F - Fim do episódio; D - Alta
    * @param i_flg_type                       Tipo: D - Alta médica; M - Alta administrativa
    * @param i_notes                          Notas da alta
    * @param i_notes_det                      Notas do detalhe da alta
    * @param i_transp                         Transporte indicado pelo médico ou administrativo
    * @param i_notes_justify                  Notas de justificação
    * @param i_flg_pat_condition              Patient conditions: (i)mproved, (u)nchanged, (s)table, (w)orse, (o)ther
    * @param i_id_transport_type              Tipo de transporte
    * @param i_id_disch_rea_t_ent_inst 
    * @param i_flg_caretaker                  Caretaker Flag: (C)aretaker, (F)amily, (P)atient, (N)one, (O)ther
    * @param i_caretaker_notes                Notes for individual responsible for additional care and instructions
    * @param i_flg_follow_up_by               Type of Professional for performs the follow-up: (P)rimary care doctor, (N)one, (O)ther
    * @param i_follow_up_notes                Notes for follow-up
    * @param i_follow_up_date_str             Date/Time of Follow-up
    * @param i_flg_written_notes              Flag indicates if there is additional WRITTEN instructions
    * @param i_flg_voluntary 
    * @param i_flg_pat_report 
    * @param i_flg_transfer_form
    * @param i_id_prof_admitting 
    * @param i_prof_admitting_desc 
    * @param i_id_dep_clin_serv_admit 
    * @param i_dep_clin_serv_ad_desc 
    * @param i_flg_summary_report 
    * @param i_flg_autopsy_consent 
    * @param i_autopsy_consent_desc 
    * @param i_flg_orgn_dntn_info 
    * @param i_orgn_dntn_info 
    * @param i_flg_examiner_notified 
    * @param i_examiner_notified_info 
    * @param i_flg_orgn_dntn_f_compl 
    * @param i_flg_ama_form_complete 
    * @param i_flg_lwbs_form_complete 
    * @param i_price                          Preço da consulta
    * @param i_currency                       Moeda
    * @param i_flg_payment                    Estado do pagamento:Pagou ou não pago
    * @param i_flg_status 
    * @param i_new_episode                    ID do novo episódio
    * @param i_new_epis_type                  Tipo do novo episódio
    * @param i_flg_type_new_epis              Estado (flg_type) do novo episódio
    * @param i_id_clinical_service            Clinical service id
    * @param i_dep_clin_serv                  Clinical service department id
    * @param i_patient                        patient id
    * @param i_entry_notes                    Entry notes
    * @param i_date_prev_inp_str              Data prevista de internamento
    * @param i_date_prev_disch_str            Data prevista da alta
    * @param i_id_room                        room id
    * @param i_id_bed                         bed id
    * @param i_flg_surgery                    Flg surgery
    * @param i_dt_surgery_str                 surgery date
    * @param i_mse_type                       MSE (Medical screening evaluation)
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    * @param o_flg_show 
    * @param o_msg_title 
    * @param o_msg_text 
    * @param o_button 
    * @param o_id_episode                     episode ID that was created after the discharge
    * @param o_error                          Error message
    *                        
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Emília Taborda
    * @version                                1.0  
    * @since                                  06-02-2007
    ********************************************************************************************/
    FUNCTION set_discharge_edis_to_inp
    (
        i_lang                    IN NUMBER,
        i_episode                 IN NUMBER,
        i_prof                    IN profissional,
        i_prof_cat_type           IN category.flg_type%TYPE,
        i_flg_new_epis            IN VARCHAR2,
        i_reas_dest               IN NUMBER,
        i_disch_type              IN VARCHAR2,
        i_flg_type                IN VARCHAR2,
        i_notes                   IN discharge.notes_med%TYPE,
        i_notes_det               IN discharge_detail.notes%TYPE,
        i_transp                  IN discharge.id_transp_ent_med%TYPE,
        i_notes_justify           IN discharge.notes_justify%TYPE,
        i_flg_pat_condition       IN discharge_detail.flg_pat_condition%TYPE,
        i_id_transport_type       IN discharge_detail.id_transport_type%TYPE,
        i_id_disch_rea_t_ent_inst IN discharge_detail.id_disch_rea_transp_ent_inst%TYPE,
        i_flg_caretaker           IN discharge_detail.flg_caretaker%TYPE,
        i_caretaker_notes         IN discharge_detail.caretaker_notes%TYPE,
        i_flg_follow_up_by        IN discharge_detail.flg_follow_up_by%TYPE,
        i_follow_up_notes         IN discharge_detail.follow_up_notes%TYPE,
        i_follow_up_date_str      IN VARCHAR2,
        i_flg_written_notes       IN discharge_detail.flg_written_notes%TYPE,
        i_flg_voluntary           IN discharge_detail.flg_voluntary%TYPE,
        i_flg_pat_report          IN discharge_detail.flg_pat_report%TYPE,
        i_flg_transfer_form       IN discharge_detail.flg_transfer_form%TYPE,
        i_id_prof_admitting       IN discharge_detail.id_prof_admitting%TYPE,
        i_prof_admitting_desc     IN discharge_detail.prof_admitting_desc%TYPE,
        i_id_dep_clin_serv_admit  IN discharge_detail.id_dep_clin_serv_admiting%TYPE,
        i_dep_clin_serv_ad_desc   IN discharge_detail.dep_clin_serv_admiting_desc%TYPE,
        i_flg_summary_report      IN discharge_detail.flg_summary_report%TYPE,
        i_flg_autopsy_consent     IN discharge_detail.flg_autopsy_consent%TYPE,
        i_autopsy_consent_desc    IN discharge_detail.autopsy_consent_desc%TYPE,
        i_flg_orgn_dntn_info      IN discharge_detail.flg_orgn_dntn_info%TYPE,
        i_orgn_dntn_info          IN discharge_detail.orgn_dntn_info%TYPE,
        i_flg_examiner_notified   IN discharge_detail.flg_examiner_notified%TYPE,
        i_examiner_notified_info  IN discharge_detail.examiner_notified_info%TYPE,
        i_flg_orgn_dntn_f_compl   IN discharge_detail.flg_orgn_dntn_form_complete%TYPE,
        i_flg_ama_form_complete   IN discharge_detail.flg_ama_form_complete%TYPE,
        i_flg_lwbs_form_complete  IN discharge_detail.flg_lwbs_form_complete%TYPE,
        i_price                   IN discharge.price%TYPE,
        i_currency                IN discharge.currency%TYPE,
        i_flg_payment             IN discharge.flg_payment%TYPE,
        i_flg_status              IN discharge.flg_status%TYPE,
        --
        i_new_episode         IN episode.id_episode%TYPE,
        i_new_epis_type       IN epis_type.id_epis_type%TYPE,
        i_flg_type_new_epis   IN episode.flg_type%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_entry_notes         IN VARCHAR,
        i_date_prev_inp_str   IN VARCHAR2,
        i_date_prev_disch_str IN VARCHAR2,
        --
        i_id_room IN room.id_room%TYPE,
        i_id_bed  IN bed.id_bed%TYPE,
        --
        i_flg_surgery        IN VARCHAR2,
        i_dt_surgery_str     IN VARCHAR2,
        i_mse_type           IN discharge_detail.mse_type%TYPE,
        i_flg_print_report   IN VARCHAR2, -- José Brito 21/04/2008
        i_transaction_id     IN VARCHAR2,
        i_transfer_diagnosis IN discharge_detail.id_transfer_diagnosis%TYPE,
        i_flg_inst_transfer  IN discharge_detail.flg_inst_transfer%TYPE,
        i_dt_admin           IN VARCHAR2,
        i_dt_med             IN VARCHAR2 DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_id_episode         OUT episode.id_episode%TYPE,
        o_id_discharge       OUT discharge.id_discharge%TYPE,
        o_reports            OUT reports.id_reports%TYPE, --odete monteiro 7/9/2007
        o_reports_pat        OUT reports.id_reports%TYPE, -- José Brito 21/04/2008
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Verificar, antes de realizar a alta médica, se existem:Medicamentos
    *                                                        Procedimentos
    *                                                        Análisis
    *                                                        Exames
    * para concluir.
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_episode               episode id
    * @param i_flg_mcdt              Apresenta a concatenação de determinados valores: A - Analysis;D - Drugs; I - Intervention; 
                                                                                       E - Exam
                                                                   Ex: |A|D|I|E|    
    * @param o_flg_show_msg          Flag: Y - existe msg para mostrar; N - ñ existe  
    * @param o_msg                   Mensagem a mostrar
    * @param o_msg_title             Título da mensagem
    * @param o_button                Botões a mostrar: R - lido 
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         05-02-2007
    ********************************************************************************************/
    FUNCTION check_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_mcdt     IN disch_reas_dest.flg_mcdt%TYPE,
        o_flg_show_msg OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    --
    --
    /********************************************************************************************
    * Get the most recent discharge notes, and also all patient complaints and diagnosis.
    * This method is used specifically for the USA market.
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_epis                  episode id
    * @param o_complaint             string with all patient complaints
    * @param o_diagnosis             string with all patient diagnosis
    * @param o_disch                 discharge notes
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        José Brito (Based on GET_DISCHARGE_NOTES by Emília Taborda)
    * @version                       1.0  
    * @since                         06-03-2009
    ********************************************************************************************/
    FUNCTION get_discharge_notes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_complaint OUT CLOB,
        o_diagnosis OUT VARCHAR2,
        o_disch     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar todas as notas da alta do episódio
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_epis                  episode id
    * @param o_disch                 array with info discharge
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         10-10-2006
    ********************************************************************************************/
    FUNCTION get_all_discharge_notes
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_disch OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * List the details of discharge notes
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_epis                  episode id
    * @param i_id_disch              discharge id
    * @param o_disch                 array with info discharge detail
    * @param o_follow_up             follow-up info
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         10-10-2006
    *
    * @alter                         José Brito
    * @version                       1.1
    * @since                         06-03-2009
    *
    ********************************************************************************************/
    FUNCTION get_discharge_notes_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        i_id_disch  IN discharge_notes.id_discharge_notes%TYPE,
        o_disch     OUT pk_types.cursor_type,
        o_follow_up OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * A mix of GET_ALL_DISCHARGE_NOTES with GET_DISCHARGE_NOTES_DET for CARE.
    * Adapted from those functions.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis                  episode identifier
    * @param o_notes                 detail of all discharge instructions
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         09/04/2009
    *
    ********************************************************************************************/
    FUNCTION get_all_dis_notes_care
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_notes OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Insert discharge notes, follow-up entities
    * and manages pending issues related to discharge instructions.
    *
    * @param i_lang                    Language id
    * @param i_prof                    Professional, software and institution ids
    * @param i_prof_cat_type           Professional category
    * @param i_epis                    Episode id
    * @param i_patient                 Patient id
    * @param i_id_disch                Discharge notes id
    * @param i_epis_complaint          Patient complaint
    * @param i_epis_diagnosis          Patient diagnosis
    * @param i_discharge_instructions  Discharge instructions
    * @param i_discharge_instr_list    Discharge instructions DEFAULT NULL 
    * @param i_release_from            Release from work or school
    * @param i_dt_from                 Release from this date...
    * @param i_dt_until                ...until this date
    * @param i_notes_release           Release notes
    * @param i_instructions_discussed  Instructions discussed with...
    * @param i_follow_up_with          Follow-up entities ID (can be a physician, external physician or external institution)
    * @param i_follow_up_in            Array of dates or number of days from which the patient must be followed-up
    * @param i_id_follow_up_type       Array of type of follow-up: D - Date; DY - Days; S - SOS
    * @param i_flg_follow_up_with      Follow-up with: (OC) on-call physician (PH) external physician
                                                       (CL) clinic (OF) office (O) other (free text specified in 'i_follow_up_text')
    * @param i_follow_up_text          Specified follow-up entity, with free text, if 'i_flg_follow_up_with' is 'O'
    * @param i_follow_up_notes         Specific notes for follow-up
    * @param i_issue_assignee         Selected assignee(s) in the multichoice, in the format: P<id> or G<id>
                                       Examples:
                                                P142 (Professional with ID_PROFESSIONAL = 142)
                                                G27  (Group with ID_GROUP = 27)
    * @param i_issue_title             Title for the pending issue
    * @param i_flg_printer             Flag printer: P - Printed
    * @param i_commit_data             Commit date? (Y) Yes (N) No   
    * @param i_sysdate                 record date   
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         1.0  
    * @since                           2009/03/05
    *
    ********************************************************************************************/
    FUNCTION set_discharge_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        --
        i_id_disch               IN discharge_notes.id_discharge_notes%TYPE,
        i_epis_complaint         IN CLOB,
        i_epis_diagnosis         IN discharge_notes.epis_diagnosis%TYPE,
        i_discharge_instructions IN discharge_notes.discharge_instructions%TYPE,
        i_discharge_instr_list   IN table_number DEFAULT NULL,
        i_release_from           IN discharge_notes.release_from%TYPE,
        i_dt_from                IN VARCHAR2,
        i_dt_until               IN VARCHAR2,
        i_notes_release          IN discharge_notes.notes_release%TYPE,
        i_instructions_discussed IN table_varchar,
        --
        i_follow_up_with     IN table_number,
        i_follow_up_in       IN table_varchar,
        i_id_follow_up_type  IN table_number,
        i_flg_follow_up_type IN follow_up_entity.flg_type%TYPE,
        i_follow_up_text     IN VARCHAR2,
        i_follow_up_notes    IN VARCHAR2,
        --
        i_issue_assignee IN table_varchar,
        i_issue_title    IN pending_issue.title%TYPE,
        --
        i_flg_printer IN VARCHAR,
        i_commit_data IN VARCHAR2,
        i_sysdate     IN TIMESTAMP WITH LOCAL TIME ZONE,
        --
        i_flg_csg_patient   IN VARCHAR2,
        i_dt_csg_patient    IN VARCHAR2,
        o_id_discharge_note OUT discharge_notes.id_discharge_notes%TYPE,
        o_reports_pat       OUT reports.id_reports%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Insert discharge notes, follow-up entities
    * and manages pending issues related to discharge instructions.
    *
    * @param i_lang                    language id
    * @param i_prof                    Professional, software and institution ids
    * @param i_prof_cat_type           Professional category
    * @param i_epis                    Episode id
    * @param i_patient                 Patient id
    * @param i_id_disch                Discharge notes id
    * @param i_epis_complaint          Patient complaint
    * @param i_epis_diagnosis          Patient diagnosis
    * @param i_discharge_instructions  Discharge instructions
    * @param i_discharge_instr_list    Discharge instructions DEFAULT NULL 
    * @param i_release_from            Release from work or school
    * @param i_dt_from                 Release from this date...
    * @param i_dt_until                ...until this date
    * @param i_notes_release           Release notes
    * @param i_instructions_discussed  Instructions discussed with...
    * @param i_follow_up_with          Follow-up entities ID (can be a physician, external physician or external institution)
    * @param i_follow_up_in            Array of dates or number of days from which the patient must be followed-up
    * @param i_id_follow_up_type       Array of type of follow-up: D - Date; DY - Days; S - SOS
    * @param i_flg_follow_up_with      Follow-up with: (OC) on-call physician (PH) external physician
                                                       (CL) clinic (OF) office (O) other (free text specified in 'i_follow_up_text')
    * @param i_follow_up_text          Specified follow-up entity, with free text, if 'i_flg_follow_up_with' is 'O'
    * @param i_follow_up_notes         Specific notes for follow-up
    * @param i_issue_assignee         Selected assignee(s) in the multichoice, in the format: P<id> or G<id>
                                       Examples:
                                                P142 (Professional with ID_PROFESSIONAL = 142)
                                                G27  (Group with ID_GROUP = 27)
    * @param i_issue_title             Title for the pending issue
    * @param i_flg_printer             Flag printer: P - Printed
    * @param i_commit_data             Commit date? (Y) Yes (N) No   
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         1.0  
    * @since                           2009/03/05
    *
    ********************************************************************************************/
    FUNCTION set_discharge_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        --
        i_id_disch               IN discharge_notes.id_discharge_notes%TYPE,
        i_epis_complaint         IN CLOB,
        i_epis_diagnosis         IN discharge_notes.epis_diagnosis%TYPE,
        i_discharge_instructions IN discharge_notes.discharge_instructions%TYPE,
        i_discharge_instr_list   IN table_number DEFAULT NULL,
        i_release_from           IN discharge_notes.release_from%TYPE,
        i_dt_from                IN VARCHAR2,
        i_dt_until               IN VARCHAR2,
        i_notes_release          IN discharge_notes.notes_release%TYPE,
        i_instructions_discussed IN table_varchar,
        --
        i_follow_up_with     IN table_number,
        i_follow_up_in       IN table_varchar,
        i_id_follow_up_type  IN table_number,
        i_flg_follow_up_type IN follow_up_entity.flg_type%TYPE,
        i_follow_up_text     IN VARCHAR2,
        i_follow_up_notes    IN VARCHAR2,
        --
        i_issue_assignee IN table_varchar,
        i_issue_title    IN pending_issue.title%TYPE,
        --
        i_flg_printer IN VARCHAR,
        i_commit_data IN VARCHAR2,
        --
        i_flg_csg_patient IN VARCHAR2,
        i_dt_csg_patient  IN VARCHAR2,
        
        o_id_discharge_note OUT discharge_notes.id_discharge_notes%TYPE,
        o_reports_pat       OUT reports.id_reports%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Cancelar uma nota associada à alta do episódio
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_epis                  episode id
    * @param i_id_disch              discharge id
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         10-10-2006
    ********************************************************************************************/
    FUNCTION set_cancel_disch_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis     IN episode.id_episode%TYPE,
        i_id_disch IN discharge_notes.id_discharge_notes%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar os tipos para o acompanhamento
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_follow_up_type        Lista com os tipos para o acompanhamento
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         2007/11/07
    ********************************************************************************************/
    FUNCTION get_follow_up_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_follow_up_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_follow_up_type_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;
    --
    /********************************************************************************************
    * Get follow-up type description
    *
    * @param    i_lang                      preferred language ID
    * @param    i_prof                      object (id of professional, id of institution, id of software)
    * @param    i_follow_up_type            follow-up type ID
    * @param    o_follow_up_type_desc       follow-up type description
    * @param    o_follow_up_type_unit_mea   follow-up type unit measure description
    * @param    o_error                     error message   
    *
    * @return   boolean                     false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/08/09
    ********************************************************************************************/
    FUNCTION get_follow_up_type_desc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_follow_up_type          IN follow_up_type.id_follow_up_type%TYPE,
        o_follow_up_type_desc     OUT pk_translation.t_desc_translation,
        o_follow_up_type_unit_mea OUT pk_translation.t_desc_translation,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as entidades a quem se destina a justificação
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_release_from          Listar as entidades a quem se destina a justificação
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         2007/11/07
    ********************************************************************************************/
    FUNCTION get_release_from_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_release_from OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar as entidades a quem foi comunicado as instruções
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_instr_disc            Listar as entidades a quem foi comunicado as instruções
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         2007/11/07
    ********************************************************************************************/
    FUNCTION get_instruct_discussed_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_instr_disc OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Listar os grupos e as intruções dos mesmos
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_disch_instr_grp       Listar os grupos de intruções
    * @param o_disch_instr           Listar as instruções associadas a cada grupo   
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         2007/11/08
    ********************************************************************************************/
    FUNCTION get_disch_instructions_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_disch_instr_grp OUT pk_types.cursor_type,
        o_disch_instr     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the list of professionals that follow the patient in the next intervention (without free text option)
    *
    * @param i_lang                  preferred language id for this professional
    * @param i_prof                  professional id structure
    * @param o_follow_up_with        list of professionals that follow the patient in the next intervention
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Tiago Silva
    * @since                         2010/10/28
    ********************************************************************************************/
    FUNCTION get_followup_with_wofreetext
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_follow_up_with OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_followup_with_wofreetext
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;
    --
    /********************************************************************************************
    * Listar os profissionais que acompanham o paciente numa proxima intervenção
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param o_follow_up_with        Listar os profissionais que acompanham o paciente numa proxima intervenção
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Emília Taborda
    * @version                       1.0  
    * @since                         2007/11/14
    ********************************************************************************************/
    FUNCTION get_follow_up_with_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_follow_up_with OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * List follow-up entities in the discharge instructions screen.
    *
    * @param i_lang                  language id
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_disch_notes        Discharge notes ID
    * @param o_follow_up_with        Follow-up entities list
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        José Brito
    * @version                       1.0  
    * @since                         2009/03/06
    ********************************************************************************************/
    FUNCTION get_follow_up_with_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_disch_notes IN discharge_notes.id_discharge_notes%TYPE,
        o_follow_up_with OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * List follow-up entities in the EHR Discharge Instructions History.
    *
    * @param i_lang                  language id
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_disch_notes        Discharge notes ID
    * @param i_id_episode            Episode ID
    *
    * @return                        Text with follow-up entities and follow-up dates
    *
    * @author                        José Brito
    * @version                       1.0  
    * @since                         2009/04/07
    ********************************************************************************************/
    FUNCTION get_follow_up_with_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_disch_notes IN discharge_notes.id_discharge_notes%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    --
    /********************************************************************************************
    * Get follow-up with entity description
    *
    * @param    i_lang                preferred language ID
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_opinion_prof        entity professional ID
    *
    * @return   varchar2              entity description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_follow_up_with_entity_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_entity_prof IN professional.id_professional%TYPE
    ) RETURN professional.name%TYPE;
    --                    
    FUNCTION get_discharge_options
    (
        i_lang  IN language.id_language%TYPE,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /***********************************************************************************************
    * Gets the discharge type list
    *
    * @param i_lang      the id language
    * @param i_prof      professional, software and institution ids
    * @param o_type      list of available discharge types    
    *                        
    * @return            Description of MSE_TYPE
    *
    * @author            José Silva
    * @version           1.0  
    * @since             2008/02/11
    **********************************************************************************************/
    FUNCTION get_discharge_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_type  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION set_alert_edis_to_inp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_new_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /***********************************************************************************************
    * Concatenar os diferentes valores MSE_TYPE inseridos no detalhe da alta
    *
    * @param i_lang      the id language
    * @param i_mse_type  mse - medical screening evaluation ids
    *                        
    * @return            Description of MSE_TYPE
    *
    * @author            Emilia Taborda
    * @version           1.0  
    * @since             2007/06/18
    **********************************************************************************************/
    FUNCTION get_disch_det_mse_type_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_mse_type IN VARCHAR2
    ) RETURN VARCHAR2;
    --

    /***********************************************************************************************
    * Set id_epis_report for a discharge_note record
    *
    * @param i_lang      the id language
    * @param i_prof      professional, software and institution ids
    * @param i_id_episode          id of episode    
    * @param i_id_epis_report      id of epis_report to save    
    * @param o_error     Error message
    *                        
    * @return            TRUE if sucess, FALSE otherwise
    *
    * @author            Carlos Ferreira
    * @version           1.0  
    * @since             2008/03/26
    **********************************************************************************************/
    FUNCTION set_epis_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_report IN epis_report.id_epis_report%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION discharge_to_new_institution
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_new_epis_type  IN epis_type.id_epis_type%TYPE,
        i_sysdate        IN DATE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Insert new discharge notes (medical or administrative).
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_notes              The notes
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_error              Error message
    *                        
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/02/10
    **********************************************************************************************/
    FUNCTION create_new_discharge_notes
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_notes        IN VARCHAR2,
        i_flg_type     IN VARCHAR2 DEFAULT 'A',
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all discharge notes (medical or administrative).
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param i_id_episode         Episode ID
    * @param i_id_discharge       Discharge ID
    * @param i_flg_type           (A) Administrative or (D) Medical discharge notes
    * @param o_notes              The notes
    * @param o_error              Error message
    *                        
    * @return            TRUE if sucessful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/02/10
    **********************************************************************************************/
    FUNCTION get_disch_prof_notes
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_flg_type     IN VARCHAR2,
        o_notes        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of follow-up entities to fill the multichoice displayed
    * after pressing the field "Follow-up with" in the "Discharge Instructions" screen.
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param o_list               List of entities
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/13
    **********************************************************************************************/
    FUNCTION get_follow_up_entities
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of options to fill the multichoice "Create a pending issue..." on the 
    * "Discharge Instructions" screen.
    * Cursor includes the follow-up care groups and the current professional.
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param o_assignees          List of assignees
    * @param o_error              Error message
    *                        
    * @return            TRUE if successful, FALSE otherwise
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/19
    **********************************************************************************************/
    FUNCTION get_issue_assignees
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_assignees OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Database internal function.
    * Returns the current assignee(s) of the pending issue related to discharge instructions.
    *
    * @param i_lang               language ID
    * @param i_prof               Professional info
    * @param i_id_disch_notes     Discharge Notes ID
    * @param i_id_pending_issue   Pending Issue ID
    * @param i_flg_issue_assign   Issue is assigned to: (P) professional (G) groups
    *                        
    * @return            Text with the current assignees
    *
    * @author            José Brito
    * @version           1.0  
    * @since             2009/03/19
    **********************************************************************************************/
    FUNCTION get_issue_current_assignee
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_disch_notes   IN discharge_notes.id_discharge_notes%TYPE,
        i_id_pending_issue IN pending_issue.id_pending_issue%TYPE,
        i_flg_issue_assign IN discharge_notes.flg_issue_assign%TYPE
    ) RETURN VARCHAR2;

    --
    --######################################################################

    /**********************************************************************************************
    * Returns the flg_hour_origin corresponding to the expected discharge of a given episode.
    *
    * @param i_lang                ID language
    * @param i_episode             ID of episode
    * @param i_prof                Object with user info
    *
    * @param o_error               Error message
    *
    * @return                      flg_hour_origin ('D'-date;'DH'-date and hour)
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0
    * @since                       2009/12/16
    **********************************************************************************************/
    FUNCTION get_dch_sch_flg_hour
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_anamnesis.id_episode%TYPE
    ) RETURN discharge_schedule.flg_hour_origin%TYPE;

    /**********************************************************************************************
    * Retorna a lista com as datas previstas de alta para um dado episódio
    *
    * @param i_lang                ID language
    * @param i_episode             ID of episode
    * @param i_prof                Object with user info
    *
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Alexandre Santos
    * @version                     2.5.
    * @since                       2009/03/30
    **********************************************************************************************/
    FUNCTION get_discharge_schedule_date
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_prof     IN profissional,
        o_disch_sh OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the disposition date and label.
    *
    * @param i_lang                          ID language
    * @param i_prof                          Logged professional
    * @param i_row_ei                        EPIS_INFO row_type
    * 
    * @param o_disp_date                     Disposition date
    * @param o_disp_date_tstz                Disposition date (timestamp with local time zone)
    * @param o_disp_label                    Disposition label
    * @param o_error                         Error message
    *
    * @return                                True on success, false otherwise
    *                        
    * @author                                Luís Maia
    * @version                               2.6.0.3.2
    * @since                                 2010-Ago-31
    * 
    **********************************************************************************************/
    FUNCTION get_inp_disposition_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_row_ei         IN epis_info%ROWTYPE,
        o_disp_date      OUT VARCHAR2,
        o_disp_date_tstz OUT epis_info.dt_med_tstz%TYPE,
        o_disp_label     OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Define a data de alta prevista para um dado episódio
    *
    * @param i_lang                          ID language
    * @param i_episode                       ID of episode
    * @param i_prof                          Object with user info
    * @param i_dt_discharge_schedule         New discharge schedule date
    * @param i_flg_hour_origin               flg hour origin
    * @param i_transaction_id               remote transaction identifier
    * @param i_allocation_commit             Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    *
    * @param o_id_discharge_schedule         New ID record
    * @param o_error                         Error message
    *
    * @return                                True on success, false otherwise
    *                        
    * @author                                Alexandre Santos
    * @version                               2.5.
    * @since                                 2009/03/30
    * 
    * Sofia Mendes (27-05-2009): - New funtion set_discharge_sch_dt:
    *                               (contains the same code as previously the function set_discharge_schedule_date).
    *                               It was created to avoid recursive calls because with the incorporation of the 
    *                               Admissions scheduler, when an admission schedule is created it is necessary to 
    *                               change the discharge date and when the discharge date is changed it is necessary to 
    *                               change the schedule end date.
    *                            - Remove commit on function set_discharge_schedule_date
    **********************************************************************************************/
    FUNCTION set_discharge_sch_dt_int
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN discharge_schedule.id_episode%TYPE,
        i_patient               IN discharge_schedule.id_patient%TYPE,
        i_prof                  IN profissional,
        i_dt_discharge_schedule IN VARCHAR2,
        i_flg_hour_origin       IN VARCHAR2 DEFAULT 'DH',
        i_transaction_id        IN VARCHAR2,
        i_allocation_commit     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_id_discharge_schedule OUT discharge_schedule.id_discharge_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Define a data de alta prevista para um dado episódio
    *
    * @param i_lang                          ID language
    * @param i_episode                       ID of episode
    * @param i_prof                          Object with user info
    * @param i_dt_discharge_schedule         New discharge schedule date
    *
    * @param o_id_discharge_schedule         New ID record
    * @param o_error                         Error message
    *
    * @return                                True on success, false otherwise
    *                        
    * @author                                Alexandre Santos
    * @version                               2.5.
    * @since                                 2009/03/30
    *
    * Sofia Mendes (27-05-2009): - New funtion set_discharge_sch_dt:
    *                               (contains the same code as previously the function set_discharge_schedule_date).
    *                               It was created to avoid recursive calls because with the incorporation of the 
    *                               Admissions scheduler, when an admission schedule is created it is necessary to 
    *                               change the discharge date and when the discharge date is changed it is necessary to 
    *                               change the schedule end date.
    *                            - Remove commit on function set_discharge_schedule_date
    **********************************************************************************************/
    FUNCTION set_discharge_sch_dt
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN discharge_schedule.id_episode%TYPE,
        i_patient               IN discharge_schedule.id_patient%TYPE,
        i_prof                  IN profissional,
        i_dt_discharge_schedule IN VARCHAR2,
        i_flg_hour_origin       IN VARCHAR2 DEFAULT 'DH',
        o_id_discharge_schedule OUT discharge_schedule.id_discharge_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_discharge_schedule_date
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN discharge_schedule.id_episode%TYPE,
        i_patient               IN discharge_schedule.id_patient%TYPE,
        i_prof                  IN profissional,
        i_dt_discharge_schedule IN VARCHAR2,
        i_flg_hour_origin       IN VARCHAR2 DEFAULT 'DH',
        o_id_discharge_schedule OUT discharge_schedule.id_discharge_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_NEW_MATCH_EPIS_DS                  This function make "match" of discharge schedule registries between episodes
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Luís Maia
    * @version                               2.5.2
    * @since                                 2012/03/05
    **********************************************************************************************/
    FUNCTION set_new_match_epis_ds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Used for discharge creation/edition, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_min_dt                contact end date left bound
    * @param o_max_dt                contact end date right bound
    * @param o_flg_warn              show no contact start date warning (Y/N)
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharge_amb
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_disch    IN discharge.id_discharge%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_disch    OUT pk_types.cursor_type,
        o_min_dt   OUT VARCHAR2,
        o_max_dt   OUT VARCHAR2,
        o_flg_warn OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieve discharges, in ambulatory products. Adapted from GET_DISCHARGE.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_disch                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_discharges_amb
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_disch   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels a discharge, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param i_canc_reas             cancel reason identifier
    * @param i_canc_notes            cancel notes
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION cancel_discharge_amb
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_disch      IN discharge.id_discharge%TYPE,
        i_canc_reas  IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes IN discharge.notes_cancel%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a discharge, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 discharge identifier
    * @param i_episode               episode identifier
    * @param i_dt_end                discharge date
    * @param i_disch_dest            discharge reason destiny identifier
    * @param i_notes                 discharge notes_med
    * @param o_flg_show              warm
    * @param o_msg_title             warn
    * @param o_msg_text              warn
    * @param o_button                warn
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION set_discharge_amb
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_disch      IN discharge.id_discharge%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_end     IN VARCHAR2,
        i_disch_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes      IN discharge.notes_med%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_text   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a discharge, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 discharge identifier
    * @param i_episode               episode identifier
    * @param i_dt_end                discharge date
    * @param i_disch_dest            discharge reason destiny identifier
    * @param i_notes                 discharge notes_med
    * @param i_transaction_id        Scheduler 3.0 transaction ID
    * @param o_flg_show              warm
    * @param o_msg_title             warn
    * @param o_msg_text              warn
    * @param o_button                warn
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION set_discharge_amb
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_cat       IN category.flg_type%TYPE,
        i_disch          IN discharge.id_discharge%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_end         IN VARCHAR2,
        i_disch_dest     IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes          IN discharge.notes_med%TYPE,
        i_transaction_id IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves discharge destinations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param o_dests                 cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_disch_dest_amb
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dests OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves a discharge record history of operations, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_disch                 discharge identifier
    * @param o_hist                  cursor
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         28/05/2009
    ********************************************************************************************/
    FUNCTION get_disch_hist_amb
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_disch IN discharge.id_discharge%TYPE,
        o_hist  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Similar to GET_ALL_DIS_NOTES_CARE, but only sends out printed instructions.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_epis                  episode identifier
    * @param o_notes                 detail of all discharge instructions
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Carneiro
    * @version                       1.0  
    * @since                         08/06/2009
    *
    ********************************************************************************************/
    FUNCTION get_printed_dis_notes
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_notes OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retrieves a physician discharge record notes from phy_discharge_notes table
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_patient               patient identifier
    * @param o_notes                 cursor returned
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Filipe Machado
    * @version                       1.0  
    * @since                         01/07/2009
    ********************************************************************************************/
    FUNCTION get_phy_discharge_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_notes   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a physician discharge record notes in phy_discharge_notes table
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_patient               patient identifier
    * @param i_episode               episode identifier
    * @param i_cancel_reason         cancel reason identifier
    * @param i_phy_discharge_notes   physician discharge notes
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Filipe Machado
    * @version                       1.0  
    * @since                         01/07/2009
    ********************************************************************************************/
    FUNCTION cancel_phy_discharge_notes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_phy_discharge_notes IN phy_discharge_notes.id_phy_discharge_notes%TYPE,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a physician discharge record notes
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_patient               patient identifier
    * @param i_episode               episode identifier
    * @param i_notes                 physician discharge notes
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Filipe Machado
    * @version                       1.0  
    * @since                         01/07/2009
    ********************************************************************************************/
    FUNCTION set_phy_discharge_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_notes   IN phy_discharge_notes.notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Criação de episódio no internamento
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_patient               patient id
    * @param i_episode               episode id
    * @param i_prof_cat_type         professional category
    * @param i_flg_status            discharge status
    * @param i_flg_new_epis          discharge with new episode: Y - yes, N - no
    * @param i_new_epis_type         episode type
    * @param i_id_prof_admitting     professional who admitted the patient
    * @param i_dep_clin_serv         clinical service that admits the patient
    * @param i_transaction_id        remote transaction identifier
    * @param o_can_refresh_mviews    materialized view refresh: Y - yes, N - no
    * @param o_id_episode            episode ID that was created after the discharge
    * @param o_error                 error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        José Silva
    * @version                       1.0  
    * @since                         10-09-2009
    ********************************************************************************************/
    FUNCTION set_inp_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_prof_cat_type        IN category.flg_type%TYPE,
        i_flg_status           IN discharge.flg_status%TYPE,
        i_flg_new_epis         IN VARCHAR2,
        i_new_epis_type        IN epis_type.id_epis_type%TYPE,
        i_id_prof_admitting    IN discharge_detail.id_prof_admitting%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_flg_compulsory       IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason    IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_can_refresh_mviews   OUT VARCHAR2,
        o_id_episode           OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the discharge dates: administrative discharge, medical active discharge and medical pending discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param o_discharge_adm         Administrative discharge
    * @param o_discharge_med         Medical active discharge
    * @param o_discharge_date        Medical pending discharge
    * @param o_flg_discharge_status  Discharge status flag
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_dates
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        o_discharge_adm        OUT discharge.dt_admin_tstz%TYPE,
        o_discharge_med        OUT discharge.dt_med_tstz%TYPE,
        o_discharge_pend       OUT discharge.dt_pend_tstz%TYPE,
        o_flg_discharge_status OUT epis_info.flg_dsch_status%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the discharge date 
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_patient               patient identifier
    * @param i_episode               episode identifier
    * @param o_notes                 cursor returned
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        o_discharge_date       OUT discharge.dt_med_tstz%TYPE,
        o_flg_discharge_status OUT epis_info.flg_dsch_status%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the expected discharge date.    
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier
    * @param o_discharge_date        Expected discharge date
    * @param o_flg_hour_origin       Flg_hour_origin ('D' -date; 'DH' - date and hour)
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_schedule_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        o_discharge_date  OUT discharge_schedule.dt_discharge_schedule%TYPE,
        o_flg_hour_origin OUT discharge_schedule.flg_hour_origin%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the discharge date.
    * Priority order:
    * -administrative discharge
    * -physician active discharge
    * -physician pending discharge
    * -expected discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_patient               patient identifier
    * @param i_episode               episode identifier
    * @param o_notes                 cursor returned
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_date
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_show_date_expected IN VARCHAR2 DEFAULT 'Y'
    ) RETURN discharge.dt_med_tstz%TYPE;

    /********************************************************************************************
    * Returns the discharge date. This function does not consider the expected discharge.
    * Priority order:
    * -administrative discharge
    * -physician active discharge
    * -physician pending discharge    
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier
    * @param i_show_date_expected    indentify id get the disscharde_date from schedule_discharge table or not      
    *
    * @return                        discharge date
    *
    * @author                        Sofia Mendes
    * @version                       2.6.0.3.3
    * @since                         28-Sep-2010
    ********************************************************************************************/
    FUNCTION get_disch_phy_adm_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN discharge.dt_med_tstz%TYPE;

    /**
    * Checks if "Tipo de consulta" should be shown
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_IS_AVAILABLE Y - show "tipo de consula", N - otherwise
    * @param   O_ERROR error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Pedro Teixeira
    * @since   05-01-2009
    */
    FUNCTION check_bill_type_avail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_is_available OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get bill types
    *
    * @param   I_LANG                language associated to the professional executing the request
    * @param   I_PROF                profissional
    * @param   I_EPISODE             episode ID    
    * @param   O_TYPE                cursor with bill types
    * @param   O_FILLED_DEFAULT      this field is automatically filled with the first option of the multichoice: (Y)es or (N)o
    *
    * @param   O_ERROR               error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Pedro Teixeira
    * @since   05-01-2009
    */
    FUNCTION get_discharge_bill_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_type           OUT pk_types.cursor_type,
        o_filled_default OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the disposition report label
    *
    * @param i_lang                  Language identifier
    * @param i_prof                  Logged professional structure
    * @param i_reas_dest             Discharge destination Identifier
    * @param o_label                 Report label
    * @param o_print_config          Print configuration (P- Save and Print, PL- Save and add
    *                                to the printing list).
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @updated by                    Gisela Couto
    * @version                       2.5.0.7
    * @since                         11/12/2009
    ********************************************************************************************/
    FUNCTION get_report_label
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_reas_dest    IN disch_reas_dest.id_disch_reas_dest%TYPE DEFAULT NULL,
        o_label        OUT pk_translation.t_desc_translation,
        o_print_config OUT sys_list_group_rel.flg_context%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns discharge detail
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_discharge           discharge id
    * @param o_sql                    cursor with detail of discharge
    * @param o_error                  Error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Alexandre Santos
    * @version                       2.5.0.7.1
    * @since                         27/01/2009
    ********************************************************************************************/
    FUNCTION get_disch_detail
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_discharge IN NUMBER,
        o_sql          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the FLG_STATUS from ID_DISCHARGE_STATUS or vice-versa
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_flg_status            input discharge status (A - active, P - pending)
    * @param i_disch_status          input discharge type
    * @param o_flg_status            output discharge status (A - active, P - pending)
    * @param o_disch_status          output discharge type
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        José Silva
    * @version                       2.6
    * @since                         19/02/2010
    ********************************************************************************************/
    FUNCTION get_disch_flg_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_status   IN discharge.flg_status%TYPE,
        i_disch_status IN discharge_status.id_discharge_status%TYPE,
        o_flg_status   OUT discharge.flg_status%TYPE,
        o_disch_status OUT discharge_status.id_discharge_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions available in the discharge screen
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_subject                Subject
     * @param i_disch_reas_dest        Discharge reason and destination ID
     * @param i_patient                Patient ID
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          José Silva
     * @version                         2.6
     * @since                           2010/02/22
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
     * Gets the list of available sections in the discharge notes report
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_flg_type               Type of discharge letter: P - print discharge letter; S - send discharge letter message
     * 
     * @param o_sections               List of sections
     * @param o_report                 Report ID
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          José Silva
     * @version                         2.6
     * @since                           2010/02/22
    **********************************************************************************************/
    FUNCTION get_rep_notes_sections
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN discharge_rep_notes.flg_type%TYPE,
        o_sections OUT pk_print_tool.p_rep_section_cur,
        o_report   OUT reports.id_reports%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Sets the information to be sent in the discharge notes area
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode ID
     * @param i_patient                Patient ID
     * @param i_discharge              Discharge ID
     * @param i_flg_type               type of discharge notes: P - print discharge notes; S - send digital message
     * @param i_flg_task               List of tasks to be sent in the GP Letter
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          José Silva
     * @version                         2.6
     * @since                           2010/02/22
    **********************************************************************************************/
    FUNCTION set_discharge_rep_notes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        i_flg_type  IN discharge_rep_notes.flg_type%TYPE,
        i_flg_task  IN discharge_rep_notes.flg_task%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retorna o numero da ordem do profissional
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_id                profissional para o qual pretendemos que seja retornado o numero da ordem                
    * @param o_num_order              numero da ordem do profissional pretendido
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/

    FUNCTION get_num_order
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_id   IN professional.id_professional%TYPE,
        o_num_order OUT professional.num_order%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Clears all records from discharge and related (FK's) tables for the given id_episode's
    *
    * @param i_lang                    Language id
    * @param i_table_id_episodes       table with id episodes
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           2010-09-08
    *
    ********************************************************************************************/
    FUNCTION clear_discharge_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_episodes IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if there exist nursing notes for an episode
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_episode         episode id 
    * @param o_flg_data        Y if there exist data, N when no data found
    * @param o_error           Error message
    *
    * @return                  true or false on success or error
    *
    * @author                  Ariel Machado 
    * @version                 2.5.1.2                    
    * @since                   29-10-2010
    **********************************************************************************************/
    FUNCTION get_nursing_notes_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks the following conditions:
    *  - A new discharge cannot be given if already exists an active or pending one
    *  - It's not possible to change a discharge of an inactive episode unless input var i_can_edt_inact_epis = 'Y'
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               Episode id
    * @param i_can_edt_inact_epis    Can edit inactive episodes?
    * @param o_error                 error message
    *
    * @return                        True if all validations are ok, otherwise returns false
    *
    * @author                        Alexandre Santos
    * @version                       2.5.1
    * @since                         27/12/2010
    ********************************************************************************************/
    FUNCTION check_discharge
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_can_edt_inact_epis IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the multichoice options of patient condition field
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_discharge_reason      Discharge reason id 
    * @param i_screen_name           Screen name. 
    * @param o_items                 Options list
    * @param o_error                 error message
    *
    * @return                        True if all validations are ok, otherwise returns false
    *
    * @author                        Alexandre Santos
    * @version                       2.6.0.3.4
    * @since                         18/01/2010
    ********************************************************************************************/
    FUNCTION get_patient_conditions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_discharge_reason IN discharge_reason.id_discharge_reason%TYPE,
        i_screen_name      IN disch_reas_status.screen_name%TYPE,
        o_items            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient condition description
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_discharge             Discharge id 
    * @param i_discharge_reason      Discharge reason id 
    * @param i_screen_name           Screen name. 
    * @param i_flg_pat_condition     Patient condition flag 
    *
    * @return                        Patient condition description
    *
    * @author                        Alexandre Santos
    * @version                       2.6.0.3.4
    * @since                         18/01/2010
    ********************************************************************************************/
    FUNCTION get_patient_condition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_discharge         IN discharge.id_discharge%TYPE,
        i_discharge_reason  IN discharge_reason.id_discharge_reason%TYPE,
        i_flg_pat_condition IN discharge_detail.flg_pat_condition%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    /**********************************************************************************************
    * Verifies if patient (in a specific episode) has already been discharged 
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_discharge         Discharge state: 
    *                                     Y if the discharge is set for the given episode and N otherwise
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.2
    * @since                              2010/10/20       
    ********************************************************************************************/
    FUNCTION get_epis_discharge_state
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_discharge OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the discharge reason and discharge destination descriptions for the episode
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               Episode id 
    * @param o_reason                Discharge reason
    * @param o_destination           Discharge destination
    * @param o_error                 error message
    *
    * @return                        true or false on success or error
    *
    * @author                        Nuno Alves
    * @version                       2.6.3.8.2
    * @since                         29/04/2015
    ********************************************************************************************/
    FUNCTION get_epis_disch_rea_dest_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_reason      OUT translation.desc_lang_2%TYPE,
        o_destination OUT translation.desc_lang_2%TYPE,
        o_signature   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Returns the expected discharge date.    
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier
    * @param i_discharge_date        Discharge schedule date 
    * @param i_flg_hour_origin       Flg_hour_origin ('D' -date; 'DH' - date and hour)
    *
    * @return                        Discharge schedule date formatted string
    *
    * @author                        Sofia Mendes
    * @version                       2.6.1.2
    * @since                         23-Ago-2011
    ********************************************************************************************/
    FUNCTION get_formatted_disch_sch_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_discharge_date  IN discharge_schedule.dt_discharge_schedule%TYPE DEFAULT NULL,
        i_flg_hour_origin IN discharge_schedule.flg_hour_origin%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get the discharge schedule flg_hour_origin. 
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_discharge_schedule  Discharge schedule Id    
    * 
    * Return                          Flg_hour_origin ('D' -date; 'DH' - date and hour) 
    *                                                                       
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          24-Aug-2011                                
    **************************************************************************/
    FUNCTION get_dich_sch_flg_hour_origin
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_discharge_schedule IN discharge_schedule.id_discharge_schedule%TYPE
    ) RETURN discharge_schedule.flg_hour_origin%TYPE;

    /********************************************************************************************
    * Get medication reconciliation info
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_patient              Patient ID
    * @param i_id_episode              Episode ID
    * @param o_info                    Medication reconciliation data
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           29-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_reconciliation_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /***
    * Checks if new disposition screen should be opened
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info   
    * @param i_id_DISCH_REAS_DEST     id_DISCH_REAS_DEST to check
    *
    * @param o_check_disposition_fe   'Y' or 'N' 
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2012/03/23
    */
    FUNCTION check_disposition_fe
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_disch_reas_dest   IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_check_disposition_fe OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /***
    * Checks if new disposition screen should be opened
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info   
    * @param i_id_DISCH_REAS_DEST     id_DISCH_REAS_DEST to check
    *
    * @return                          Y / N
    *
    * @author   Paulo Teixeira
    * @version  2.6.1.2
    * @since    2012/03/23
    */
    FUNCTION check_disposition_fe_aux
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE
    ) RETURN VARCHAR2;

    /*
    * Get the description of a discharge instruction to use on single pages import mechanism
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_disch_note     discharge note identifier
    * @param i_flg_short      Short descritpion or long descritpion (Y - short description)
    *
    * @return                 Discharge instrution description
    *
    * @author                 Sérgio Santos
    * @version                2.6.2
    * @since                  2012/08/22
    */
    FUNCTION get_sp_disch_instr_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_disch_notes        IN discharge_notes.id_discharge_notes%TYPE,
        i_flg_short             IN VARCHAR2 DEFAULT 'N',
        i_desc_type             IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    /**********************************************************************************************
    * Send discharge letter to GP
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_patient            Patient name
    * @param i_id_episode            Episode
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.3
    * @since                         2013/09/18 
    ***********************************************************************************************/
    FUNCTION send_discharge_letter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_report  IN reports.id_reports%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Send messages to interalert
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.3
    * @since                         2013/09/18 
    *
    * @changed                       Elisabete Bugalho
    * @version                       2.6.4.3
    * @since                         2014/12/18
    ***********************************************************************************************/
    PROCEDURE send_gp_discharge_letter;
    --######################################################################
    PROCEDURE set_oris_discharge;
    --#########################################################################################

    /**********************************************************************************************
    * Get discharge instructions for CDA section: Discharge instructions
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_discharge_notes       Cursor with all discharge notes for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2013/12/20 
    ***********************************************************************************************/
    FUNCTION get_disch_instructions_cda
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        o_discharge_instr OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*Printing list developments*/

    /********************************************************************************************
    * Gets information about print list job using print list job identifier 
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_id_print_list_job     Print list job identifier (discharge areas)
    *
    * @return                        Print list job information
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         07/10/2014
    ********************************************************************************************/
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /********************************************************************************************
    * Compares if a print list job is similar to the array of print list jobs
    *
    * @param i_lang                   Language associated to the professional executing the request
    * @param i_prof                   Professional, institution and software identification
    * @param i_print_job_context_data Print list job context
    * @param i_tbl_print_list_jobs    Array of print list job identifiers
    *
    * @return                        Array of print list jobs that are similar
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number;

    /********************************************************************************************
    * Gets discharge instruction completion options
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param o_options               Referrals completion options
    * @param o_error                 An error message, set when return=false
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION get_completion_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets default option from printing list configuration 
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_area                  Functional area (discharge - 8, discharge_instructions - 7)
    *
    * @return                        Sys_list internal name - SAVE_PRINT_LIST | SAVE_LIST
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION get_default_opt_print_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_area IN print_list_area.id_print_list_area%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Creates discharge context structure using report id and associated discharge identifier.
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_id_reports            Report identifier
    * @param i_id_discharge          Discharge identifier
    *
    * @return                        Context string created
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         07/10/2014
    ********************************************************************************************/
    FUNCTION encode_disch_print_job_context
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_reports   IN reports.id_reports%TYPE,
        i_id_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Decodes discharge context string to get report id and associated discharge identifier.
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_context               Printing list context
    * @param o_id_report             Report identifier
    * @param o_id_discharge          Discharge identifier 
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         07/10/2014
    ********************************************************************************************/
    FUNCTION decode_disch_print_job_context
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_context      IN print_list_job.context_data%TYPE,
        o_id_report    OUT reports.id_reports%TYPE,
        o_id_discharge OUT discharge.id_discharge%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Adds the print list job to the printing list
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param i_tbl_context_data      List tha contains all print list jobs context
    * @param i_tbl_print_list_areas  Printing list areas
    * @param i_tbl_print_arguments   Arguments necessary to print the jobs
    * @param o_print_list_jobs       Array of print list job identifiers added
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION set_print_list_jobs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_tbl_context_data     IN table_clob,
        i_tbl_print_list_areas IN table_number,
        i_tbl_print_arguments  IN table_varchar,
        o_print_list_jobs      OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Adds the discharge instruction record to the print list.
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param i_print_arguments       Arguments necessary to print the discharge instructions job
    * @param i_id_reports            Report identifier   
    * @param o_print_list_jobs       Array of print list job identifiers added
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets discharge print jobs in the printing list.
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param i_tbl_id_report         List that contains report identifiers 
    * @param i_id_discharge      List that contains discharge identifier 
    * @param i_tbl_print_arguments   Arguments necessary to print the discharge job
    * @param o_id_print_list_jobs    Print list job identifiers added to the printing list
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION add_print_list_jobs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_report       IN table_number,
        i_id_discharge        IN discharge.id_discharge%TYPE,
        i_tbl_print_arguments IN table_varchar,
        o_id_print_list_jobs  OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Generic function to delete more than one print jobs, by area/patient/episode
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param i_print_list_area       Discharge instructions - 7, Discharge - 8
    * @param o_id_print_list_jobs    Print list job identifiers deleted
    * @param o_error                 An error message, set when return=false
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION cancel_print_jobs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_print_list_area    IN print_list_area.id_print_list_area%TYPE,
        o_id_print_list_jobs OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Removes all discharge print jobs from printing list
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param o_id_print_list_jobs    Print list job identifiers deleted
    * @param o_error                 An error message, set when return=false
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION cancel_disch_print_jobs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_id_print_list_jobs OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Removes all discharge instruction print jobs from printing list.
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_patient               Patient identifier
    * @param i_episode               Episode identifier
    * @param o_id_print_list_jobs    Print list job identifiers deleted
    * @param o_error                 An error message, set when return=false
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Gisela Couto
    * @version                       2.6.4.2.1
    * @since                         08/10/2014
    ********************************************************************************************/
    FUNCTION cancel_disch_instr_print_jobs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        o_id_print_list_jobs OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_level_of_service_desc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_task_type            IN task_type.id_task_type%TYPE,
        i_id_concept_term         IN concept_term.id_concept_term%TYPE,
        i_id_cncpt_trm_inst_owner IN concept_term.id_inst_owner%TYPE,
        i_id_terminology_version  IN terminology_version.id_terminology_version%TYPE
        
    ) RETURN VARCHAR2;

    FUNCTION get_level_of_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_discharge_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number
    ) RETURN t_coll_disch_notes
        PIPELINED;

    FUNCTION get_list_discharge_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN table_number,
        o_disch_notes OUT t_cur_discharge_notes,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions to be displayed when a SOAP note is selected.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_recomend           Epis recomment id    
    * @param o_actions                    actions data
    * @param o_error                      error
    *
    * @return                             false if errors occur, true otherwise
    *
    * @author                             Vanessa Barsottelli
    * @version                            2.6.4
    * @since                              10-Dez-2014
    */
    FUNCTION get_actions_soap_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_recomend IN epis_recomend.id_epis_recomend%TYPE,
        i_id_task_type     IN tl_task.id_tl_task%TYPE,
        o_actions          OUT NOCOPY pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_match_episode_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dn_discussed_with
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_notes IN discharge_notes.id_discharge_notes%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_dn_discussed_with
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_discharge_notes   IN discharge_notes.id_discharge_notes%TYPE,
        o_dn_discussed      OUT table_varchar,
        o_dn_discussed_desc OUT table_varchar,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Returns the list of dicharge instructions selected in dicharge note.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_discharge_notes            Discharge note id    
    * @param o_dn_instr                   Array of discharge instruction IDs
    * @param o_dn_instr_desc              Array of discharge instruction description
    * @param o_error                      Error message
    *
    * @return                             TRUE if sucess, FALSE otherwise
    *
    * @author                             Anna Kurowska
    * @version                            2.7
    * @since                              29-Jun-2017
    */
    FUNCTION get_dn_instr_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_notes IN discharge_notes.id_discharge_notes%TYPE,
        o_dn_instr        OUT table_number,
        o_dn_instr_desc   OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the concat string with list of dicharge instructions selected in dicharge note.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_discharge_notes            Discharge note id    
    *
    * @return                             string with description
    *
    * @author                             Anna Kurowska
    * @version                            2.7
    * @since                              29-Jun-2017
    */
    FUNCTION get_dn_instr_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_notes IN discharge_notes.id_discharge_notes%TYPE
    ) RETURN VARCHAR2;
    /* *******************************************************************************************
    *  Get current state of dischrge instructions for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_disch_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /* *******************************************************************************************
    *  Get current state of dischrge  for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author     Elisabete Bugalho                
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get discharge information
    *             
    * @param i_lang       language idenfier
    * @param i_prof       profissional identifier
    * @param i_id_episode episode idenfier
    *
    * @return             Type with the discharge information
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.2.3
    * @since                          2018-01-18
    **********************************************************************************************/

    FUNCTION tf_get_episode_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_table_epis_transf;

    FUNCTION check_created_epis_on_disch
    (
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_prev_episode IN episode.id_prev_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_exists_disch_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN discharge.id_episode%TYPE,
        i_flg_type    IN VARCHAR2,
        o_exist_disch OUT VARCHAR2,
        o_type        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Used to return the names of all professionals
    * 
    * @param i_lang            Professional prefered language
    * @param i_prof            Professional information
    * @param o_prof             List of all professionals
    * 
    *
    ******************************************************************************/
    FUNCTION get_admitting_professionals
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_prof  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************
    * used to get Print discharge report auto? (Y/N)
    ************************************************************/
    FUNCTION get_disch_print_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_type             OUT pk_types.cursor_type,
        o_flg_print_report OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Used to return the names of all professionals
    * 
    * @param i_lang            Professional prefered language
    * @param i_prof            Professional information
    * @param o_prof             List of all professionals
    * 
    *
    ******************************************************************************/
    FUNCTION get_written_by_professionals
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_prof  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_admission_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_admission_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_admission_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_discharge_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_discharge_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_discharge_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_discharge_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_discharge IN discharge.id_discharge%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_patient_condition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_discharge_schedule_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    -- GLOBALS
    --#########################################################################################   
    g_owner        VARCHAR2(200);
    g_package_name VARCHAR2(200);

    g_error        VARCHAR2(2000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found_true   VARCHAR2(1);
    g_found_false  VARCHAR2(1);
    g_found        BOOLEAN;
    g_exception EXCEPTION;
    --
    g_yes           VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_documentation sys_config.value%TYPE;
    g_document_n    sys_config.value%TYPE;
    g_document_d    sys_config.value%TYPE;
    --
    g_cat_avail category.flg_available%TYPE;
    --
    g_triage     CONSTANT discharge.flg_type_disch%TYPE := 'T';
    g_doctor     CONSTANT category.flg_type%TYPE := 'D';
    g_nurse      CONSTANT category.flg_type%TYPE := 'N';
    g_adm        CONSTANT category.flg_type%TYPE := 'M';
    g_adm_cat    CONSTANT category.flg_type%TYPE := 'A';
    g_therapist  CONSTANT category.flg_type%TYPE := 'F';
    g_manchester CONSTANT category.flg_type%TYPE := 'M';
    --
    g_disch_type_doctor epis_diagnosis.flg_type%TYPE;
    g_disch_type_adm    epis_diagnosis.flg_type%TYPE;
    g_disch_type_nurse  epis_diagnosis.flg_type%TYPE;
    --
    g_disch_type_f        discharge.flg_type%TYPE;
    g_disch_flg_active    discharge.flg_status%TYPE;
    g_disch_flg_reopen    discharge.flg_status%TYPE;
    g_disch_flg_cancel    discharge.flg_status%TYPE;
    g_disch_flg_pend      discharge.flg_status%TYPE;
    g_disch_flg_available VARCHAR2(1);
    g_disch_flg_pay_n     VARCHAR2(1);
    g_disch_flg_pay_y     VARCHAR2(1);
    g_disch_type_alert    epis_info.flg_status%TYPE;
    --
    g_disch_cancel category.flg_type%TYPE;
    g_disch_active category.flg_type%TYPE;
    --
    g_disch_reas_dest_default    sys_config.value%TYPE;
    g_disch_trans_entity_default sys_config.value%TYPE;

    g_disch_print_report_auto sys_config.id_sys_config%TYPE;
    --
    g_domain_disch sys_domain.code_domain%TYPE;
    --
    g_disch_reason sys_config.value%TYPE;
    g_disch_admin  sys_config.value%TYPE;
    g_disch_social sys_config.value%TYPE;

    g_disch_reason_oris sys_config.value%TYPE;
    --
    g_epis_disch_act discharge.flg_status%TYPE;
    g_disch_act      discharge.flg_status%TYPE;
    g_disch_reopen   discharge.flg_status%TYPE;
    --
    g_disch_notes_np discharge_notes.flg_status%TYPE;
    g_disch_notes_p  discharge_notes.flg_status%TYPE;
    g_disch_notes_c  discharge_notes.flg_status%TYPE;
    g_disch_n_status sys_domain.code_domain%TYPE;
    --
    g_epis_status_active episode.flg_status%TYPE;
    g_epis_status_cons   epis_info.flg_status%TYPE;
    g_epis_status_atend  epis_info.flg_status%TYPE;
    g_epis_pend          episode.flg_status%TYPE;
    g_epis_act           episode.flg_status%TYPE;
    --
    g_visit_active   visit.flg_status%TYPE;
    g_epis_active    episode.flg_status%TYPE;
    g_visit_inactive visit.flg_status%TYPE;
    g_epis_inactive  episode.flg_status%TYPE;
    g_epis_canc      episode.flg_status%TYPE;
    --
    g_epis_flg_type_d episode.flg_type%TYPE;
    g_sr_epis_type CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_care_nurse_epis_type      episode.id_epis_type%TYPE;
    g_outp_nurse_epis_type      episode.id_epis_type%TYPE;
    g_without_patient_epis_type episode.id_epis_type%TYPE;
    g_epis_type_oris            epis_type.id_epis_type%TYPE;
    g_epis_type_nutrition       epis_type.id_epis_type%TYPE := 18;
    g_epis_type_nurse_pp        epis_type.id_epis_type%TYPE := 17;
    g_epis_type_inp             epis_type.id_epis_type%TYPE := 5;
    --
    g_epis_diag_act  epis_diagnosis.flg_status%TYPE;
    g_epis_diag_canc epis_diagnosis.flg_status%TYPE;
    g_epis_diag_decl epis_diagnosis.flg_status%TYPE;
    g_epis_diag_def  epis_diagnosis.flg_status%TYPE;
    g_epis_diag_base epis_diagnosis.flg_status%TYPE;
    --
    g_diagn_actv epis_diagnosis.flg_status%TYPE;
    g_diagn_canc epis_diagnosis.flg_status%TYPE;
    g_diagn_decl epis_diagnosis.flg_status%TYPE;
    --
    g_diagn_def   epis_diagnosis.flg_type%TYPE;
    g_diagn_base  epis_diagnosis.flg_type%TYPE;
    g_flag_diag   disch_reas_dest.flg_diag%TYPE;
    g_diagn_final VARCHAR2(1);
    --
    g_flg_hist epis_recomend.flg_temp%TYPE;
    g_flg_temp epis_recomend.flg_temp%TYPE;
    g_flg_def  epis_recomend.flg_temp%TYPE;
    --
    g_type_p epis_recomend.flg_type%TYPE;
    g_type_d epis_recomend.flg_type%TYPE;
    g_type_n epis_recomend.flg_type%TYPE;
    g_type_a epis_recomend.flg_type%TYPE;
    g_type_m epis_recomend.flg_type%TYPE;
    g_type_l epis_recomend.flg_type%TYPE;
    --
    g_anamnesis_type  epis_anamnesis.flg_type%TYPE;
    g_admin_anamnesis epis_anamnesis.flg_class%TYPE;
    --
    g_transp_depart CONSTANT transp_entity.flg_transp%TYPE := 'D';
    g_flash_mask                 VARCHAR2(0050);
    g_message_none               sys_message.code_message%TYPE;
    g_sys_config_default_flg_pay sys_config.id_sys_config%TYPE;
    g_soft_edis       CONSTANT sys_config.value%TYPE := 8;
    g_soft_ubu        CONSTANT sys_config.value%TYPE := 29;
    g_soft_manchester CONSTANT sys_config.value%TYPE := 35;
    g_soft_care       CONSTANT software.id_software%TYPE := 3;
    g_soft_outpatient CONSTANT software.id_software%TYPE := 1;
    g_soft_pp         CONSTANT software.id_software%TYPE := 12;
    --
    g_isencao       VARCHAR2(1);
    g_complaint_act epis_complaint.flg_status%TYPE;
    g_complaint     VARCHAR2(1);
    --
    g_analysis_det_req    analysis_req_det.flg_status%TYPE;
    g_analysis_det_result analysis_req_det.flg_status%TYPE;
    g_analysis_det_canc   analysis_req_det.flg_status%TYPE;
    g_analysis_det_read   analysis_req_det.flg_status%TYPE;
    g_analysis_det_pend   analysis_req_det.flg_status%TYPE;
    g_analysis_det_exec   analysis_req_det.flg_status%TYPE;
    --
    g_analisys_status_final analysis_req_det.flg_status%TYPE;
    g_analisys_status_red   analysis_req_det.flg_status%TYPE;
    --
    g_exam_det_result   exam_req_det.flg_status%TYPE;
    g_exam_det_canc     exam_req_det.flg_status%TYPE;
    g_exam_status_final exam_req_det.flg_status%TYPE;
    g_exam_status_red   exam_req_det.flg_status%TYPE;
    --
    g_interv_det_canc  interv_presc_det.flg_status%TYPE;
    g_interv_det_fin   interv_presc_det.flg_status%TYPE;
    g_interv_det_inter interv_presc_det.flg_status%TYPE;
    --
    g_disch_analysis sys_config.value%TYPE;
    g_disch_exam     sys_config.value%TYPE;
    g_disch_drug_flu sys_config.value%TYPE;
    g_disch_interv   sys_config.value%TYPE;
    --
    g_admin_category category.flg_type%TYPE;

    g_flg_available VARCHAR2(1);

    g_surgery_type_c VARCHAR2(1);
    --
    g_unknown           VARCHAR2(1);
    g_epis_info_efectiv VARCHAR2(1);
    --
    g_analysis        CONSTANT VARCHAR2(1) := 'A';
    g_drug            CONSTANT VARCHAR2(1) := 'D';
    g_intervention    CONSTANT VARCHAR2(1) := 'I';
    g_exam            CONSTANT VARCHAR2(1) := 'E';
    g_drug_continuous CONSTANT VARCHAR2(1) := 'C';
    g_discharge_mcdt sys_config.value%TYPE;

    g_social_episode_inactive CONSTANT VARCHAR2(1) := 'I';

    g_transp_disch CONSTANT transp_entity.flg_type%TYPE := 'D';
    g_transp_all   CONSTANT transp_entity.flg_type%TYPE := 'A';

    g_alert_nurse CONSTANT VARCHAR2(1) := 'N';
    g_type_add    CONSTANT VARCHAR2(1) := 'A';

    g_flg_other VARCHAR2(1);

    g_disch_type_therapist_f discharge.flg_type%TYPE;
    g_disch_type_therapist_o discharge.flg_type%TYPE;

    g_disch_type_nutritionist discharge.flg_type%TYPE := 'U';

    g_other_prof_id CONSTANT NUMBER(1) := -1;

    -- variable for insertion in diaries
    g_plan_session CONSTANT notes_config.notes_code%TYPE := 'PLA';

    g_ehr_schedule        CONSTANT episode.flg_ehr%TYPE := 'S';
    g_config_disch_triage CONSTANT sys_config.id_sys_config%TYPE := 'TRIAGE_ALLOW_DISCHARGE';
    g_cr_status_active    CONSTANT clin_record.flg_status%TYPE := 'A';

    g_schedule_nurse_w CONSTANT schedule_outp.flg_state%TYPE := 'W';

    -- follow up types
    g_follow_up_date follow_up_type.id_follow_up_type%TYPE := 1;
    g_follow_up_days follow_up_type.id_follow_up_type%TYPE := 2;
    g_follow_up_sos  follow_up_type.id_follow_up_type%TYPE := 3;

    -- physian discharge notes status
    g_phy_disch_notes_activated CONSTANT phy_discharge_notes.flg_status%TYPE := 'A';
    g_phy_disch_notes_cancelled CONSTANT phy_discharge_notes.flg_status%TYPE := 'C';

    g_disch_type_casemanager_c CONSTANT discharge.flg_type_disch%TYPE := 'C';

    g_disch_flg_status_active discharge.flg_status%TYPE := 'A';
    g_disch_flg_status_pend   discharge.flg_status%TYPE := 'P';
    g_disch_flg_status_cancel discharge.flg_status%TYPE := 'C';
    g_disch_flg_status_reopen discharge.flg_status%TYPE := 'R';

    g_disch_flg_hour_d  discharge_schedule.flg_hour_origin%TYPE := 'D';
    g_disch_flg_hour_dh discharge_schedule.flg_hour_origin%TYPE := 'DH';

    --Disposition print report config
    g_cfg_print_disp_report CONSTANT sys_config.id_sys_config%TYPE := 'PRINT_DISPOSITION_REPORT';
    g_cfg_print_disch_instr CONSTANT sys_config.id_sys_config%TYPE := 'PRINT_DISCHARGE_INSTR_REPORT';
    --
    e_check_discharge EXCEPTION;

    --
    g_cfg_force_doc_discharge CONSTANT sys_config.id_sys_config%TYPE := 'APPOINTMENT_REQUESTS_FORCE_DOC_DISCHARGE';
    g_opinion_approval_needed CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_M033';
    g_dictation_area_plan dictation_report.id_work_type%TYPE := 10;
    --
    g_disch_screen_admis_all    CONSTANT VARCHAR2(50 CHAR) := 'AdmissionAllDisposition.swf';
    g_disch_screen_ama_all      CONSTANT VARCHAR2(50 CHAR) := 'AMAAllDisposition.swf';
    g_disch_screen_disp_admit   CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2Admit.swf';
    g_disch_screen_disp_ama     CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2AMA.swf';
    g_disch_screen_disp_disch   CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2Discharge.swf';
    g_disch_screen_disp_exp     CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2Expire.swf';
    g_disch_screen_disp_lwbs    CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2LWBS.swf';
    g_disch_screen_disp_mse     CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2Mse.swf';
    g_disch_screen_disp_transf  CONSTANT VARCHAR2(50 CHAR) := 'DispositionCreateStep2Transfer.swf';
    g_disch_screen_followup_all CONSTANT VARCHAR2(50 CHAR) := 'FollowUpAllDisposition.swf';
    g_disch_screen_home_all     CONSTANT VARCHAR2(50 CHAR) := 'HomeAllDisposition.swf';
    g_disch_screen_lwbs_all     CONSTANT VARCHAR2(50 CHAR) := 'LWBSAllDisposition.swf';
    g_disch_screen_mse_all      CONSTANT VARCHAR2(50 CHAR) := 'MSEAllDisposition.swf';
    g_disch_screen_transf_all   CONSTANT VARCHAR2(50 CHAR) := 'TransferAllDisposition.swf';

    --Printing tool popup default option configuration
    -- Is the Save option the default option? Y - The option Save is shown as default in the popup , N- The printing list default option configured is shown.
    g_disch_print_tool_default_opt CONSTANT sys_config.id_sys_config%TYPE := 'DEFAULT_OPT_DISCH_INSTR_SAVE';

    --sys_list_group that contains specific discharge printing list options
    g_slg_disch_instr_options CONSTANT sys_list_group.internal_name%TYPE := 'DISCHARGE_INSTR_SAVE_OPT';
    g_slg_disch_options       CONSTANT sys_list_group.internal_name%TYPE := 'DISCHARGE_SAVE_OPT';

    --sys_list discharge options
    g_sys_list_save_add_print_list CONSTANT sys_list_group_rel.flg_context%TYPE := 'PL';
    g_sys_list_save_print          CONSTANT sys_list_group_rel.flg_context%TYPE := 'P';
    g_sys_list_save                CONSTANT sys_list_group_rel.flg_context%TYPE := 'S';

    --sys_list discharge options
    g_sys_list_int_name_pl CONSTANT sys_list.internal_name%TYPE := 'SAVE_PRINT_LIST';
    g_sys_list_int_name_p  CONSTANT sys_list.internal_name%TYPE := 'SAVE_PRINT';
    g_sys_list_inst_name_s CONSTANT sys_list.internal_name%TYPE := 'SAVE';

    g_id_report_label       CONSTANT VARCHAR2(100 CHAR) := 'ID_REPORTS:';
    g_id_transctional_label CONSTANT VARCHAR2(100 CHAR) := 'ID_TRANSACTIONAL:';
    g_separator             CONSTANT VARCHAR2(1 CHAR) := ';';

    g_trs_complaint CONSTANT VARCHAR2(50 CHAR) := 'ALERT.DISCHARGE_NOTES.EPIS_COMPLAINT.';
    g_disch_detail_fpr_s discharge_detail.flg_print_report%TYPE := 'S';
    g_disch_detail_fpr_x discharge_detail.flg_print_report%TYPE := 'X';
END;
/
