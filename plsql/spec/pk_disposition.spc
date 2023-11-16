/*-- Last Change Revision: $Rev: 2028611 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_disposition IS

    -- ***********************************************************************************************
    -- GLOBALS
    -- ***********************************************************************************************
    g_adm     CONSTANT category.flg_type%TYPE := 'M';
    g_doctor  CONSTANT category.flg_type%TYPE := 'D';
    g_nurse   CONSTANT category.flg_type%TYPE := 'N';
    g_adm_cat CONSTANT category.flg_type%TYPE := 'A';

    g_anamnesis_type  CONSTANT VARCHAR2(0050) := 'C';
    g_admin_anamnesis CONSTANT VARCHAR2(0050) := 'A';

    g_disch_act           CONSTANT VARCHAR2(0050) := 'A';
    g_disch_reopen        CONSTANT VARCHAR2(0050) := 'R';
    g_disch_type_alert    CONSTANT VARCHAR2(0050) := 'A';
    g_disch_type_nurse    CONSTANT VARCHAR2(0050) := 'N';
    g_disch_flg_active    CONSTANT VARCHAR2(0050) := 'A';
    g_disch_flg_reopen    CONSTANT VARCHAR2(0050) := 'R';
    g_disch_flg_cancel    CONSTANT VARCHAR2(0050) := 'C';
    g_disch_flg_pend      CONSTANT VARCHAR2(0050) := 'P';
    g_disch_flg_available CONSTANT VARCHAR2(0050) := 'Y';
    g_disch_flg_pay_n     CONSTANT VARCHAR2(0050) := 'N';
    g_disch_flg_pay_y     CONSTANT VARCHAR2(0050) := 'Y';

    g_epis_diag_act  CONSTANT VARCHAR2(0050) := 'A';
    g_epis_diag_canc CONSTANT VARCHAR2(0050) := 'C';
    g_epis_diag_decl CONSTANT VARCHAR2(0050) := 'R';
    g_epis_diag_def  CONSTANT VARCHAR2(0050) := 'D'; -- Diagnóstico definitivo
    g_epis_diag_base CONSTANT VARCHAR2(0050) := 'B';
    g_epis_act       CONSTANT VARCHAR2(0050) := 'A';

    g_episode_end CONSTANT VARCHAR2(0050) := 'F';

    g_disch_reas_dest_inactive CONSTANT VARCHAR2(0050) := 'I';
    g_available                CONSTANT VARCHAR2(0050) := 'Y';

    g_outdated CONSTANT VARCHAR2(0050) := 'O';
    g_yes      CONSTANT VARCHAR2(0050) := 'Y';
    g_no       CONSTANT VARCHAR2(0050) := 'N';
    g_active   CONSTANT VARCHAR2(0050) := 'A';
    g_inactive CONSTANT VARCHAR2(0050) := 'I';
    g_pendente CONSTANT VARCHAR2(0050) := 'P';
    g_cancel   CONSTANT VARCHAR2(0050) := 'C';

    g_selected CONSTANT VARCHAR2(0050) := 'S';

    g_disp_adms  CONSTANT VARCHAR2(0050) := 'A'; --'Altas para Serviços internos'
    g_disp_home  CONSTANT VARCHAR2(0050) := 'H'; -- 'Altas para Domicilio'
    g_disp_foll  CONSTANT VARCHAR2(0050) := 'F'; -- 'Altas para Follow-up'
    g_disp_tran  CONSTANT VARCHAR2(0050) := 'T'; --'Altas para outra instituição'
    g_disp_expi  CONSTANT VARCHAR2(0050) := 'X'; --'Altas para Morte'
    g_disp_ama   CONSTANT VARCHAR2(0050) := 'M'; --'Altas contre parecer médico'
    g_disp_mse   CONSTANT VARCHAR2(0050) := 'S'; --'Altas MSE'
    g_disp_lwbs  CONSTANT VARCHAR2(0050) := 'L'; --'Altas LWBS'
    g_disp_other CONSTANT VARCHAR2(0050) := 'O'; -- 'Altas Other - Free text ' 

    g_flg_type_consult CONSTANT VARCHAR2(0050) := 'C';

    g_sch_event_id_followup CONSTANT sch_event.id_sch_event%TYPE := 2;
    g_flg_type_date_day     CONSTANT consult_req.flg_type_date%TYPE := 'D';

    g_date_mask CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';

    g_discharge_diag_mandatory VARCHAR2(0050);
    g_disch_admin              VARCHAR2(0050);
    g_soft_edis                VARCHAR2(0050);
    g_disch_reason             VARCHAR2(0050);
    g_disch_reason_oris        VARCHAR2(0050);
    g_disch_social             VARCHAR2(0050);
    g_discharge_mcdt           VARCHAR2(0050);

    g_soft_ubu     VARCHAR2(0050);
    g_package_name VARCHAR2(4000);

    g_error VARCHAR2(4000);

    g_sysdate DATE;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_flg_print_report_domain CONSTANT VARCHAR2(0050) := 'DISCHARGE_DETAIL_HIST.FLG_PRINT_REPORT';
    g_disch_flg_status_domain CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE.FLG_STATUS';

    /* Complaint sample text type */
    g_complaint_sample_text_type CONSTANT VARCHAR2(6) := 'QUEIXA';
    g_all                        CONSTANT NUMBER(2) := -10;
    g_reason_origin_sample_text  CONSTANT VARCHAR2(1) := 'S';

    g_exception EXCEPTION;

    g_cfg_force_doc_discharge  CONSTANT sys_config.id_sys_config%TYPE := 'APPOINTMENT_REQUESTS_FORCE_DOC_DISCHARGE';
    g_opinion_approval_needed  CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_M033';
    g_force_diag_abort_deliv_a CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_M045';
    g_force_diag_abort_deliv_d CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_M046';

    g_trs_death_event CONSTANT VARCHAR2(50 CHAR) := 'DISCHARGE_DETAIL_HIST.CODE_DEATH_EVENT.';

    g_newborn_condition_u discharge_newborn.flg_condition%TYPE := 'U';


    /**********************************************************************************************
    * Gets the patient admitting to room (Inpatient discharge)
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room_admit             admitting room ID
    * @param i_admit_to_room          admitting room (free text)
    *
    * @return                         admitting room (formatted text)
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2010/10/08
    **********************************************************************************************/
    FUNCTION get_room_admit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_room_admit    IN discharge_detail_hist.id_room_admit%TYPE,
        i_admit_to_room IN discharge_detail_hist.admit_to_room%TYPE
    ) RETURN VARCHAR2;

    -- UX
    FUNCTION cancel_disposition_ux
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- INTER-ALERT
    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_dt_cancel         IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- Logic
    /***************************************************************************************************
    * AUXILLIARY method. Checks if discharge can be cancelled from the medical discharge list screen.
    *
    * @param   i_lang              Language ID
    * @param   i_prof              Professional info
    * @param   i_id_prof_med       Medical discharge professional
    * @param   i_id_prof_adm       Administrative discharge professional
    * @param   i_flg_status        Discharge status
    * @param   i_cancel_allowed    Value of 'CANCEL_ADMINISTRATIVE_DISCHARGE'
    * @param   i_cancel_allowed_pp Value of 'PRIV_CANCEL_DISPOSITION'
    * @param   i_end_epis_on_disch Value of 'END_EPISODE_ON_DISCHARGE'
    *
    * @RETURN  1 if can be cancelled, 0 otherwise
    *
    * @author  José Brito
    * @version 2.6.0.3
    * @since   24/09/2010
    *
    ***************************************************************************************************/
    FUNCTION can_cancel_us_discharge
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_med       IN discharge_hist.id_prof_med%TYPE,
        i_id_prof_adm       IN discharge_hist.id_prof_admin%TYPE,
        i_flg_status        IN discharge_hist.flg_status%TYPE,
        i_cancel_allowed    IN sys_config.value%TYPE,
        i_cancel_allowed_pp IN sys_config.value%TYPE,
        i_end_epis_on_disch IN sys_config.value%TYPE
    ) RETURN VARCHAR2;

    FUNCTION cancel_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        i_dt_cancel         IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************
    * Gets the discharge type description
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    * @param   i_disch                    discharge status ID
    * @param   i_flg_status               discharge status (flag value)
    * @param   o_desc                     description of the discharge type
    * @param   o_error                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 1.0
    * @since   19/02/2010
    *
    ***************************************************************************************************/
    FUNCTION get_disch_status_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_disch      IN discharge_status.id_discharge_status%TYPE,
        i_flg_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_other_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that gets data from table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_id_discharge_hist   id de registo de alta se exisitir
     * @param O_sql           id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/15
    ********************************************************************************************/
    FUNCTION get_followup_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_FLG_SHOW Show pop-up with error or warning message (Y/N)
    * @param   O_MSG_TITLE Message title
    * @param   O_MSG_TEXT Error or warning text
    * @param   O_BUTTON Button to display on the pop-up
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION get_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        o_info                 OUT pk_types.cursor_type,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_text             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_newborn_reg          OUT pk_types.cursor_type,
        o_newborn              OUT pk_types.cursor_type,
        o_sync_client_registry OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get summary to the reports
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO result cursor
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Alexandre Santos
    * @version 1.0
    * @since   29-01-2010
    *
    */
    FUNCTION get_summary_to_reports
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_newborn    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_type_of_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional professional.id_professional%TYPE,
        o_sql             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************
    * Gets the list of discharge types
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    * @param   i_id_disch_reas_dest       disch_reas_dest ID
    * @param   o_type                     discharge types
    * @param   o_error                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 1.0
    * @since   17/05/2009
    *
    * @author  José Silva
    * @version 2.0
    * @since   25/01/2010
    *
    ***************************************************************************************************/
    FUNCTION get_discharge_options
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_type               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_reopen_disposition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_reopen_disposition
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN discharge_hist.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_end_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_end_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_category OUT category.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lwbs_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mse_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ama_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_expired_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_transfer_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * set records outdated
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   i_id_discharge    id de alta
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   22-Oct-2007
    */
    FUNCTION set_outdated
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN discharge.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the discharge destination label.
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_disch_reas_dest      Discharge destination record ID
    *                        
    * @return  Discharge destination label
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          09-FEB-2011
    **********************************************************************************************/
    FUNCTION get_disch_dest_label
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE
    ) RETURN VARCHAR2;

    /*
    * get professional category
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_PROF_CATEGORY CATEGORIA DO PROFISSIONAL
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_profile_template
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_id_profile_template OUT profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get list of destination for type of discharge
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF                        - professional, institution and software ids
    * @param   I_ID_DISCH_REASON             - ID motivo de alta
    * @param   O_DISCH_DEST_LIST             - array de destinos de alta
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   2007-10-17
    */
    FUNCTION get_discharge_dest_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_disch_reason IN discharge_reason.id_discharge_reason%TYPE,
        o_disch_dest_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * set Homedisposition
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   i_id_episode               id of episode
    * @param   i_id_disch_reas_dest       id of discharge/destination
    * @param   i_id_discharge_hist        id of Dischage_hist  record
    * @param   i_flg_pat_condition        flg of patient condition
    * @param   i_med_reconciliation       content of medication reconciliation
    * @param   i_flg_prescription         prescription given to Y/N
    * @param   i_care_discussed           care and instructions discussed with people indicated
    * @param   i_instructions_understood  
    * @param   i_follow_up_by             follow_up by
    * @param   i_dt_follow_up             date for follow_up
    * @param   i_notes                    additional notes
    * @param   i_report_given_to          person who gets the report on transfer dispositions
    * @param   i_flg_print_report         flg print report
    * @param   i_flg_letter               type of discharge letter: P - print discharge letter; S - send discharge letter message
    * @param   i_flg_task                 list of tasks associated with the discharge letter
    * @param   i_transaction_id           Scheduler 3.0 transaction ID
    * @param   o_flg_show                 flag to show warning screen Y/N
    * @param   o_msg_title                title of warning screen
    * @param   o_msg_text                 text of warning screen
    * @param   o_button                   buttons for warning screen
    * @param   o_id_episode               episode ID that was created after the discharge
    * @param   o_id_discharge             discharge ID
    * @param   O_ERROR                    warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */

    FUNCTION set_main_disposition
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_discharge_status     IN discharge_status.id_discharge_status%TYPE,
        i_disposition_flg_type IN discharge_flash_files.flg_type%TYPE,
        i_id_disch_reas_dest   IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist    IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition    IN discharge_detail_hist.flg_pat_condition%TYPE, --8
        
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE DEFAULT NULL,
        i_flg_prescription_given       IN discharge_detail_hist.flg_prescription_given%TYPE DEFAULT NULL,
        i_flg_written_notes            IN discharge_detail_hist.flg_written_notes%TYPE DEFAULT NULL,
        i_dt_med                       IN VARCHAR2 DEFAULT NULL,
        i_flg_instructions_discussed   IN discharge_detail_hist.flg_instructions_discussed%TYPE DEFAULT NULL, -- 14
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE DEFAULT NULL,
        i_instructions_understood      IN discharge_detail_hist.instructions_understood%TYPE DEFAULT NULL,
        i_vs_taken                     IN discharge_detail_hist.vs_taken%TYPE DEFAULT NULL, -- 13
        i_intake_output_done           IN discharge_detail_hist.intake_output_done%TYPE DEFAULT NULL,
        i_flg_patient_transport        IN discharge_detail_hist.flg_patient_transport%TYPE DEFAULT NULL,
        i_flg_pat_escorted_by          IN discharge_detail_hist.flg_pat_escorted_by%TYPE DEFAULT NULL,
        i_desc_pat_escorted_by         IN discharge_detail_hist.desc_pat_escorted_by%TYPE DEFAULT NULL,
        i_notes                        IN discharge_hist.notes_med%TYPE DEFAULT NULL, -- 18
        --
        i_id_prof_admitting   IN discharge_detail_hist.id_prof_admitting%TYPE DEFAULT NULL,
        i_admission_orders    IN discharge_detail_hist.admission_orders%TYPE DEFAULT NULL,
        i_admit_to_room       IN discharge_detail_hist.admit_to_room%TYPE DEFAULT NULL,
        i_room_admit          IN discharge_detail_hist.id_room_admit%TYPE DEFAULT NULL,
        i_flg_check_valuables IN discharge_detail_hist.flg_check_valuables%TYPE DEFAULT NULL, -- 22
        --
        i_reason_of_transfer      IN discharge_detail_hist.reason_of_transfer%TYPE DEFAULT NULL,
        i_flg_transfer_transport  IN discharge_detail_hist.flg_transfer_transport%TYPE DEFAULT NULL,
        i_dt_transfer_transport   IN VARCHAR2 DEFAULT NULL,
        i_desc_transfer_transport IN discharge_detail_hist.desc_transfer_transport%TYPE DEFAULT NULL,
        i_risk_of_transfer        IN discharge_detail_hist.risk_of_transfer%TYPE DEFAULT NULL,
        i_benefits_of_transfer    IN discharge_detail_hist.benefits_of_transfer%TYPE DEFAULT NULL,
        i_prof_admitting_desc     IN discharge_detail_hist.prof_admitting_desc%TYPE DEFAULT NULL, --27
        i_dt_prof_admiting        IN VARCHAR2 DEFAULT NULL,
        i_en_route_orders         IN discharge_detail_hist.en_route_orders%TYPE DEFAULT NULL,
        i_flg_patient_consent     IN discharge_detail_hist.flg_patient_consent%TYPE DEFAULT NULL,
        i_acceptance_facility     IN discharge_detail_hist.acceptance_facility%TYPE DEFAULT NULL,
        i_admitting_room          IN discharge_detail_hist.admitting_room%TYPE DEFAULT NULL,
        i_room_assigned_by        IN discharge_detail_hist.room_assigned_by%TYPE DEFAULT NULL,
        i_items_sent_with_patient IN discharge_detail_hist.items_sent_with_patient%TYPE DEFAULT NULL, -- 34
        --
        i_dt_death                   IN VARCHAR2 DEFAULT NULL,
        i_prf_declared_death         IN discharge_detail_hist.prf_declared_death%TYPE DEFAULT NULL,
        i_autopsy_consent_desc       IN discharge_detail_hist.autopsy_consent_desc%TYPE DEFAULT NULL, -- 37
        i_flg_orgn_donation_agency   IN discharge_detail_hist.flg_orgn_donation_agency%TYPE DEFAULT NULL,
        i_flg_report_of_death        IN discharge_detail_hist.flg_report_of_death%TYPE DEFAULT NULL,
        i_flg_coroner_contacted      IN discharge_detail_hist.flg_coroner_contacted%TYPE DEFAULT NULL,
        i_coroner_name               IN discharge_detail_hist.coroner_name%TYPE DEFAULT NULL,
        i_flg_funeral_home_contacted IN discharge_detail_hist.flg_funeral_home_contacted%TYPE DEFAULT NULL,
        i_funeral_home_name          IN discharge_detail_hist.funeral_home_name%TYPE DEFAULT NULL, --43
        i_dt_body_removed            IN VARCHAR2 DEFAULT NULL,
        --
        i_risk_of_leaving     IN discharge_detail_hist.risk_of_leaving%TYPE DEFAULT NULL, -- 45
        i_flg_risk_of_leaving IN discharge_detail_hist.flg_risk_of_leaving%TYPE DEFAULT NULL,
        i_dt_ama              IN VARCHAR2 DEFAULT NULL,
        i_flg_signed_ama_form IN discharge_detail_hist.flg_signed_ama_form%TYPE DEFAULT NULL,
        i_signed_ama_form     IN discharge_detail_hist.desc_signed_ama_form%TYPE DEFAULT NULL, --49
        --
        i_mse_type IN discharge_detail_hist.mse_type%TYPE DEFAULT NULL,
        --
        i_reason_for_leaving IN discharge_detail_hist.reason_for_leaving%TYPE DEFAULT NULL, --51
        
        i_pat_instructions_provided    IN discharge_detail_hist.pat_instructions_provided%TYPE DEFAULT NULL,
        i_flg_prescription_given_to    IN discharge_detail_hist.flg_prescription_given_to%TYPE DEFAULT NULL,
        i_desc_prescription_given_to   IN discharge_detail_hist.desc_prescription_given_to%TYPE DEFAULT NULL,
        i_id_prof_assigned_to          IN discharge_detail_hist.id_prof_assigned_to%TYPE DEFAULT NULL,
        i_next_visit_scheduled         IN discharge_detail_hist.next_visit_scheduled%TYPE DEFAULT NULL,
        i_flg_instructions_next_visit  IN discharge_detail_hist.flg_instructions_next_visit%TYPE DEFAULT NULL,
        i_desc_instructions_next_visit IN discharge_detail_hist.desc_instructions_next_visit%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_visit       IN discharge_detail_hist.id_dep_clin_serv_visit%TYPE DEFAULT NULL,
        i_id_complaint                 IN discharge_detail_hist.id_complaint%TYPE DEFAULT NULL,
        i_notes_registrar              IN discharge_detail_hist.notes%TYPE DEFAULT NULL,
        i_id_cpt_code                  IN discharge.id_cpt_code%TYPE DEFAULT NULL,
        i_dt_proposed                  IN VARCHAR2 DEFAULT NULL,
        i_id_schedule                  IN schedule.id_schedule%TYPE DEFAULT NULL,
        --
        i_report_given_to         IN discharge_detail_hist.report_given_to%TYPE DEFAULT NULL,
        i_reason_of_transfer_desc IN discharge_detail_hist.reason_of_transfer_desc%TYPE DEFAULT NULL,
        --        i_commit_at_end                IN VARCHAR2 DEFAULT 'Y',
        i_transaction_id IN VARCHAR2,
        --
        -- AS 14-12-2009 (ALERT-62112)
        i_flg_print_report IN discharge_detail_hist.flg_print_report%TYPE DEFAULT NULL,
        --
        i_flg_letter IN discharge_rep_notes.flg_type%TYPE DEFAULT NULL,
        i_flg_task   IN discharge_rep_notes.flg_task%TYPE DEFAULT NULL,
        --
        i_id_dep_clin_serv_admit     IN discharge_detail.id_dep_clin_serv_admiting%TYPE DEFAULT NULL,
        i_flg_surgery                IN VARCHAR2 DEFAULT NULL,
        i_dt_surgery_str             IN VARCHAR2 DEFAULT NULL,
        i_death_characterization     IN discharge_detail_hist.id_death_characterization%TYPE DEFAULT NULL,
        i_death_process_registration IN discharge_detail.death_process_registration%TYPE DEFAULT NULL,
        --
        i_id_inst_transfer     IN discharge_detail_hist.id_inst_transfer%TYPE DEFAULT NULL,
        i_id_admitting_doctor  IN discharge_detail_hist.id_admitting_doctor%TYPE DEFAULT NULL,
        i_order_type           IN co_sign.id_order_type%TYPE DEFAULT NULL,
        i_prof_order           IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_dt_order             IN VARCHAR2 DEFAULT NULL,
        i_id_written_by        IN discharge_detail_hist.id_written_by%TYPE DEFAULT NULL,
        i_flg_compulsory       IN VARCHAR2 DEFAULT 'N',
        i_id_compulsory_reason IN NUMBER DEFAULT NULL,
        i_compulsory_reason    IN VARCHAR2 DEFAULT NULL,
        i_oper_treatment_detail IN CLOB DEFAULT NULL,
        i_status_before_death   IN CLOB DEFAULT NULL,
        --
        o_shortcut     OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_reports      OUT reports.id_reports%TYPE,
        o_reports_pat  OUT reports.id_reports%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_id_episode   OUT episode.id_episode%TYPE,
        o_id_discharge OUT discharge.id_discharge%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that gets data from table DISCHARGE_hist...
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param O_sql           id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/15
    ********************************************************************************************/
    FUNCTION get_home_disposition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        o_sql               OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that updates data into table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION upd_disposition_dsc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dsc          IN discharge%ROWTYPE,
        i_do_commit    IN VARCHAR2,
        o_id_discharge OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that updates data into table DISCHARGE_detail
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION upd_disposition_dsd
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dsd                 IN discharge_detail%ROWTYPE,
        i_do_commit           IN VARCHAR2,
        o_id_discharge_detail OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc           structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge     id_discharge generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_dsc          IN discharge%ROWTYPE,
        i_do_commit    IN VARCHAR2,
        o_id_discharge OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE_detail
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsd           structure with info to be saved  into discharge_detail
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_detail   id_discharge_detail generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsd
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dsd                 IN discharge_detail%ROWTYPE,
        i_do_commit           IN VARCHAR2,
        o_id_discharge_detail OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE_hist
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_dsc_h         structure with info to be saved  into discharge
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_hist   id_discharge_hist generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsc_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_dsc_h             IN discharge_hist%ROWTYPE,
        i_do_commit         IN VARCHAR2,
        o_id_discharge_hist OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that inserts data into table DISCHARGE_detail_hist
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param I_DSD_H         structure with info to be saved  into discharge_detail_hist
     * @param i_do_commit     flag to know if commit is to be made
     * @param O_discharge_detail_hist   id_discharge_detail_hist generated by function
     * @param o_ERROR         error genereated by function
     *
     * @value i_do_commit     (*) 'Y' Yes (N) 'N' No
     *
     * @return                True if completed successfully, False if completed with errors
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/12
    ********************************************************************************************/
    FUNCTION set_disposition_dsd_h
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_dsd_h                 IN discharge_detail_hist%ROWTYPE,
        i_do_commit             IN VARCHAR2,
        o_discharge_detail_hist OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Disposition validation
     *
     * @param   I_LANG               language associated to the professional executing the request
     * @param   I_PROF               professional, institution and software ids
     * @param   I_EPISODE            episode id
     * @param   i_id_disch_reas_dest tipo e destino de alta
     * @param   i_id_discharge_hist  id do registo de historico de alta
     * @param   o_epis_type_new_epis id do tipo de episodio a criar se aplicavel
     * @param   o_flg_type_new_epis  flag do tipo de episdio
     * @param   o_flg_new_epis       indica se destino implica criação de episodio
     * @param   o_screen             indica ecra a carregar para o flash
     * @param   o_flg_show_msg       indica se é necessario mensagem de aviso
     * @param   o_msg                conteudo da mensagem
     * @param   o_msg_title          titulo da mensagem
     * @param   o_button             botoes da mensagem
     * @param   O_ERROR warning/error message
     *
     *
     * @return                True if completed successfully, False if completed with errors
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/10
    ********************************************************************************************/
    FUNCTION check_epis_disposition
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_episode                  IN episode.id_episode%TYPE,
        i_id_disch_reas_dest          IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist           IN discharge_hist.id_discharge_hist%TYPE,
        o_epis_type_new_epis          OUT episode.id_epis_type%TYPE,
        o_flg_type_new_epis           OUT episode.flg_type%TYPE,
        o_disch_letter_list_exception OUT VARCHAR2,
        o_flg_new_epis                OUT VARCHAR2,
        o_screen                      OUT VARCHAR2,
        o_flg_show_msg                OUT VARCHAR2,
        o_msg                         OUT VARCHAR2,
        o_msg_title                   OUT VARCHAR2,
        o_button                      OUT VARCHAR2,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;



    /**********************************************************************************************
    * Gets all the rooms available in the inpatient department
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department          Destination department ID
    * @param o_room                   Room list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0 
    * @since                          08-10-2010
    **********************************************************************************************/
    FUNCTION get_admit_room_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_room          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get physician summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    *
    */
    FUNCTION get_physician_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get nurse summary
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_EPISODE episode id
    * @param   O_INFO cursor com resultado
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_nurse_summary
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get professional category
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   O_PROF_CATEGORY CATEGORIA DO PROFISSIONAL
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   10-Oct-2007
    */
    FUNCTION get_prof_category
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_prof_category OUT category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_followup_default_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_cur        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_schedule_and_disposition
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        -- schedule
        i_id_patient             IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv       IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event           IN schedule.id_sch_event%TYPE,
        i_id_prof                IN sch_resource.id_professional%TYPE,
        i_dt_begin               IN VARCHAR2,
        i_dt_end                 IN VARCHAR2,
        i_flg_vacancy            IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes         IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator     IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred      IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason              IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin              IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room                IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_sch_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes           IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_sched_request_type IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via       IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap             IN VARCHAR2,
        i_id_consult_vac         IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option             IN VARCHAR2,
        -- disposition
        i_id_episode                   IN episode.id_episode%TYPE,
        i_flg_status                   IN discharge_hist.flg_status%TYPE,
        i_disposition_flg_type         IN discharge_flash_files.flg_type%TYPE,
        i_id_disch_reas_dest           IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_id_discharge_hist            IN discharge_hist.id_discharge_hist%TYPE,
        i_flg_pat_condition            IN discharge_detail_hist.flg_pat_condition%TYPE,
        i_flg_med_reconcile            IN discharge_detail_hist.flg_med_reconcile%TYPE,
        i_instructions_discussed_notes IN discharge_detail_hist.instructions_discussed_notes%TYPE,
        i_notes                        IN discharge_hist.notes_med%TYPE,
        i_pat_instructions_provided    IN discharge_detail_hist.pat_instructions_provided%TYPE,
        i_flg_prescription_given_to    IN discharge_detail_hist.flg_prescription_given_to%TYPE,
        i_desc_prescription_given_to   IN discharge_detail_hist.desc_prescription_given_to%TYPE,
        i_id_prof_assigned_to          IN discharge_detail_hist.id_prof_assigned_to%TYPE,
        i_next_visit_scheduled         IN discharge_detail_hist.next_visit_scheduled%TYPE,
        i_flg_instructions_next_visit  IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_desc_instructions_next_visit IN discharge_detail_hist.flg_instructions_next_visit%TYPE,
        i_id_dep_clin_serv_visit       IN discharge_detail_hist.id_dep_clin_serv_visit%TYPE,
        i_id_complaint                 IN discharge_detail_hist.id_complaint%TYPE,
        i_notes_registrar              IN discharge_detail_hist.notes%TYPE,
        i_id_cpt_code                  IN discharge.id_cpt_code%TYPE DEFAULT NULL,
        i_order_type                   IN co_sign.id_order_type%TYPE DEFAULT NULL,
        i_prof_order                   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_dt_order                     IN VARCHAR2 DEFAULT NULL,
        o_flg_show                     OUT VARCHAR2,
        o_flg_proceed                  OUT VARCHAR2,
        o_msg_title                    OUT VARCHAR2,
        o_msg_text                     OUT VARCHAR2,
        o_button                       OUT VARCHAR2,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retorna os motivo da consulta 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_id_dep_clin_serv    ID 
    * @param i_patient             ID of patient
    * @param i_episode             ID of episode
    *
    * @param o_type                Type of returned information ( S - Sample of of area QUEIXA, 
    *                              C - Data form table COMPLAINT
    * @param o_sql                 Cursor with the reason for visit
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/23
    **********************************************************************************************/
    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_type             OUT VARCHAR2,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Return the configured flash file id for the given parameters
    *
    * @param i_institution         Institution
    * @param i_discharge_reason    Discharge reason ID
    * @param i_profile_template    Profile template ID 
    *
    * @return                      Discharge flash file ID
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.2
    * @since                       2012/09/24
    **********************************************************************************************/
    FUNCTION get_disch_flash_file
    (
        i_institution      IN institution.id_institution%TYPE,
        i_discharge_reason IN discharge_reason.id_discharge_reason%TYPE,
        i_profile_template IN discharge_hist.id_profile_template%TYPE
    ) RETURN discharge_flash_files.id_discharge_flash_files%TYPE;

    /**********************************************************************************************
    * Gets discharge status (ALERT-280978)
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_episode             ID of episode
    *
    * @param o_discharge_status    Discharge status
    *                              1 - ROUTINE DISCHARGE HOME
    *                              2 - LEFT AGAINST MEDICAL ADVICE
    *                              3 - TRANSFERRED TO OTHER HOSPITAL
    *                              4 - DIED WITHIN 48 HOURS
    *                              5 - DIED AFTER 48 HOURS
    *                              6 - OTHER
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       2014/05/06
    **********************************************************************************************/
    FUNCTION get_discharge_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_discharge_status OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns death event characterization data
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @param o_death_evet          Content cursor
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Sergio Dias
    * @version                     2.6.3.15
    * @since                       Apr-3-2014
    **********************************************************************************************/
    FUNCTION get_death_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_death_event OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns discharge shortcut
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    *
    * @return                      Discharge shortcut
    *                        
    * @author                      Alexandre Santos
    * @version                     2.6.4
    * @since                       Dec-15-2014
    **********************************************************************************************/
    FUNCTION get_discharge_shortcut
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN sys_shortcut.id_sys_shortcut%TYPE;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    * @param i_episode             ID of episode
    * @param i_pat_pregnancy       ID of pat_pregnancy
    * @param i_flg_condition       Flag of newborn condition
    *
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION set_newborn_discharge
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_discharge     IN discharge.id_discharge%TYPE,
        i_episode       IN table_number,
        i_pat_pregnancy IN table_number,
        i_flg_condition IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                ID language
    * @param i_prof                ID of professional
    * @param i_discharge           ID of discharge
    *
    * @param o_
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Vanessa Barsottelli
    * @version                     2.7.0
    * @since                       10-11-2016
    **********************************************************************************************/
    FUNCTION cancel_newborn_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;


    FUNCTION get_summary
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_flg_type             IN VARCHAR2,
        o_info                 OUT pk_types.cursor_type,
        o_flg_show             OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_text             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_newborn_reg          OUT pk_types.cursor_type,
        o_newborn              OUT pk_types.cursor_type,
        o_flg_create           OUT VARCHAR2,
        o_sync_client_registry OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_flg_type IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Function that returns list of discharges depending of profile and institution
     *
     * @param i_lang          id language  to use
     * @param i_prof          id, institution, software to use in function
     * @param i_prof_cat      professional category
     * @param o_list          result of discharge_reason
     * @param o_ERROR         error genereated by function
     *
     * @return                True if completed successfully, False if completed with errors
     *
     *
     * @author                Carlos Ferreira
     * @version               2.4.1
     * @since                 2007/10/10
    ********************************************************************************************/
    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_discharge_reason_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_episode  IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_dsc_reason_selected
    (
        i_episode        IN NUMBER,
        i_id_hhc_episode IN NUMBER,
        i_flg_hhc_disch  IN VARCHAR2
    ) RETURN VARCHAR2;
    
    FUNCTION set_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_id_discharge      IN discharge.id_discharge%TYPE,
        i_id_discharge_hist IN discharge_hist.id_discharge_hist%TYPE,
        i_prof              IN profissional,
        i_notes_cancel      IN discharge.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_disposition;
/
