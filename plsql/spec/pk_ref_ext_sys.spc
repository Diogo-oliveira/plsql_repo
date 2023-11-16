/*-- Last Change Revision: $Rev: 2028908 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_ext_sys AS

    -- JB 14-10-2010 ALERT-14479
    TYPE ref_rec IS RECORD(
        id_patient            VARCHAR2(50),
        id_external_request   NUMBER(24),
        num_req               VARCHAR2(50),
        dt_p1                 VARCHAR2(200),
        dt_p1_tstz            TIMESTAMP(6) WITH LOCAL TIME ZONE,
        flg_type              VARCHAR2(3),
        type_icon             VARCHAR2(200),
        id_dep_clin_serv      NUMBER(24),
        serv_spec_desc        VARCHAR2(4000),
        desc_activity         VARCHAR2(4000),
        inst_dest             VARCHAR2(4000),
        id_inst_dest          NUMBER(24),
        inst_orig             VARCHAR2(4000),
        id_inst_orig          NUMBER(24),
        prof_triage           VARCHAR2(4000),
        flg_status            VARCHAR2(3),
        flg_status_desc       VARCHAR2(4000),
        status_icon           VARCHAR2(200),
        dt_execution          VARCHAR2(200), -- data de agendamento
        dt_execution_tstz     TIMESTAMP(6) WITH LOCAL TIME ZONE, -- data de agendamento
        id_schedule           NUMBER(24),
        dt_requested_tstz     TIMESTAMP(6) WITH LOCAL TIME ZONE,
        prof_requested_name   VARCHAR2(4000),
        id_content            VARCHAR2(200),
        desc_ref_type         VARCHAR2(4000),
        desc_ref_status       VARCHAR2(4000),
        dt_schedule_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE,
        id_department         NUMBER(24),
        desc_department       VARCHAR2(4000),
        id_clinical_service   NUMBER(24),
        desc_clinical_service VARCHAR2(4000),
        id_procedure          NUMBER(24),
        desc_procedure        VARCHAR2(4000),
        id_prof_requested     NUMBER(24),
        id_prof_sch           NUMBER(24));

    -- ALERT-14479
    TYPE ref_cur IS REF CURSOR RETURN ref_rec;

    TYPE ref_detail_rec IS RECORD(
        id_patient            VARCHAR2(50),
        id_external_request   NUMBER(24),
        num_req               VARCHAR2(50),
        flg_type              VARCHAR2(3),
        desc_referral_type    VARCHAR2(800),
        flg_status            VARCHAR2(3),
        desc_referral_status  VARCHAR2(800),
        priority              VARCHAR2(800),
        decision_urg_level    VARCHAR2(800),
        dt_request            TIMESTAMP(6) WITH LOCAL TIME ZONE,
        id_prof_requested     NUMBER(24),
        prof_requested_name   VARCHAR2(4000),
        id_inst_orig          NUMBER(24),
        inst_orig_name        VARCHAR2(4000),
        id_inst_dest          NUMBER(24),
        inst_dest_name        VARCHAR2(4000),
        id_procedure          NUMBER(24),
        procedure_name        VARCHAR2(4000),
        id_dep_clin_serv      NUMBER(24),
        id_department         NUMBER(24),
        desc_department       VARCHAR2(4000),
        id_clinical_service   NUMBER(24),
        desc_clinical_service VARCHAR2(4000),
        id_content            VARCHAR2(200),
        dt_sch_tstz           TIMESTAMP(6) WITH LOCAL TIME ZONE,
        id_prof_sch           NUMBER(24),
        prof_sch_name         VARCHAR2(4000),
        id_schedule           NUMBER(24),
        prof_spec_request     VARCHAR2(4000));

    TYPE ref_detail_cur IS REF CURSOR RETURN ref_detail_rec;

    -- ALERT-308110
    TYPE t_rec_ref_info IS RECORD(
        id_external_request p1_external_request.id_external_request%TYPE,
        id_patient          p1_external_request.id_patient%TYPE,
        dt_requested        p1_external_request.dt_requested%TYPE,
        desc_ref_type       pk_translation.t_desc_translation,
        desc_items          pk_translation.t_desc_translation,
        desc_inst_dest      pk_translation.t_desc_translation,
        reason              p1_detail.text%TYPE,
        signature           VARCHAR2(4000));

    TYPE t_cur_ref_info IS REF CURSOR RETURN t_rec_ref_info;
    TYPE t_coll_ref_info IS TABLE OF t_rec_ref_info;

    /**
    * Updates referral status
    * Note: This function must not called for features that have several schedules associated to the same referral id
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software    
    * @param   i_ext_req  Referral id              
    * @param   i_status   (S)chedule, (E)fectivation, (M)ailed, appointment (C)anceled  and (F)ailed appointment  
    * @param   i_notes    Notes    
    * @param   i_schedule Schedule identifier   
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION update_referral_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_status         IN p1_external_request.flg_status%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes request status after schedule cancelation 
    *
    * @param   i_lang     Language associated to the professional executing the request
    * @param   i_prof     Id professional, institution and software    
    * @param   i_ext_req  Referral id
    * @param   i_notes    Cancelation notes
    * @param   O_ERROR    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   23-06-2009
    */
    FUNCTION cancel_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_ext_req        IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral completion options.
    * This function is used when creating one or multiple requests.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_epis          Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type    
    * @param   i_spec          Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   o_options       Referrals completion options
    * @param   o_error         An error message, set when return=false
    *
    * @value   i_flg_type      {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    */

    FUNCTION get_completion_options_new
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        i_codification IN table_number,
        i_inst_dest    IN table_number,
        i_flg_type     IN p1_external_request.flg_type%TYPE,
        i_spec         IN ref_completion_cfg.id_mcdt%TYPE,
        o_options      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral completion options (used internally)
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_epis          Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type    
    * @param   i_spec          Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   i_reports_excep         List of id_reports that will not be considered (exception)
    * @param   i_ref_compl_excep       List of referral completion options identifiers that will not be considered (exception)
    *
    * @value   i_flg_type      {*} 'C' Consultation 
    *                          {*} 'A' Lab tests 
    *                          {*} 'I' Imaging exams
    *                          {*} 'E' Other exams
    *                          {*} 'P' Procedure
    *                          {*} 'F' Rehab
    *
    * @RETURN  t_coll_ref_completion   List of completion options available
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-08-2009
    */
    FUNCTION get_compl_options_tf
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_codification    IN table_number,
        i_inst_dest       IN table_number,
        i_flg_type        IN p1_external_request.flg_type%TYPE,
        i_spec            IN ref_completion_cfg.id_mcdt%TYPE,
        i_reports_excep   IN table_number DEFAULT table_number(),
        i_ref_compl_excep IN table_number DEFAULT table_number()
    ) RETURN t_coll_ref_completion;

    /**
    * Checks if the given option is available for concluding the request.
    *
    * @param   i_lang          Language associated to the professional executing the request
    * @param   i_prof          Id professional, institution and software    
    * @param   i_patient       Patient identifier   
    * @param   i_episode       Episode identifier
    * @param   i_codification  Codification identifiers   
    * @param   i_inst_dest     Referrals destination institutions
    * @param   i_flg_type      Referral type: {*} 'C' Consultation {*} 'A' Analysis {*} 'I' Image {*} 'E' Exam {*} 'P' Procedure {*} 'F' MFR    
    * @param   i_option        Completion option identifier to be validated
    * @param   o_flg_available Option availability {*} 'Y' - available  {*} 'N' - otherwise
    * @param   O_ERROR         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   25-09-2009
    *
    * @changed by Ricardo Patrocínio
    * @changed in: 2009-11-06
    * @change reason: [ALERT-54754]
    */
    FUNCTION check_completion_option
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_codification  IN table_number,
        i_inst_dest     IN table_number,
        i_flg_type      IN p1_external_request.flg_type%TYPE,
        i_option        IN ref_completion.id_ref_completion%TYPE,
        i_spec          IN p1_speciality.id_speciality%TYPE,
        o_flg_available OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 1.0
    * @since   29-08-2007
    */
    FUNCTION get_pat_ref_to_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_type     IN table_varchar,
        i_schedule IN schedule.id_schedule%TYPE,
        o_p1       OUT ref_cur,
        o_message  OUT VARCHAR2,
        o_title    OUT VARCHAR2,
        o_buttons  OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-04-2011
    */
    FUNCTION get_pat_ref_to_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_type           IN table_varchar,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_inst_dest_list IN table_number,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_schedule    IN schedule.dt_schedule_tstz%TYPE,
        o_p1             OUT ref_cur,
        o_message        OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_buttons        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of patient referrals available for scheduling
    * Used by scheduler.
    * Based on PK_P1_EXT_SYS.get_pat_p1_to_schedule
    *
    * @param   i_lang                Language
    * @param   i_prof                Professional, institution, software
    * @param   i_patient             Patient identifier
    * @param   i_type                If null returns all requests, otherwise return for the selected type
    * @param   i_schedule            Current schedule identifier
    * @param   o_p1                  Returned referral list   
    * @param   o_message             Message to return
    * @param   o_title               Message type
    * @param   o_button              Button message
    * @param   o_error               An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-04-2011 
    */

    FUNCTION get_pat_ref_gp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_type           IN table_varchar,
        i_inst_dest_list IN table_number,
        o_ref_list       OUT ref_cur,
        o_message        OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_buttons        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Associates a referral to a schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels association between referral and schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_date     Operation date
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION cancel_ref_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_schedule       IN schedule.id_schedule%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_id_reason_code IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notifies the patient about the referral schedule. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_schedule Schedule identifier
    * @param   i_notes    Notes       
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_notify
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_ref   IN p1_external_request.id_external_request%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_notes    IN p1_detail.text%TYPE,
        i_date     IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Starts the registration process. Changes referral status accordingly.
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_notes    Notes       
    * @param   i_episode  Episode identifier (used by scheduler when scheduling ORIS/INP referral)
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_ref_efectiv
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_notes  IN p1_detail.text%TYPE,
        i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Notifies about a scheduled patient no-show
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier               
    * @param   i_notes    Notes       
    * @param   i_reason   Id_cancel_reason 
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   21-09-2011
    */
    FUNCTION set_ref_no_show
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_notes          IN p1_detail.text%TYPE,
        i_reason         IN NUMBER,
        i_date           IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Notifies about a cancel patient no-show
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software    
    * @param   i_id_ref   Referral identifier                       
    * @param   i_date     Operation date    
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   26-09-2011
    */

    FUNCTION set_ref_cancel_noshow
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_ref IN p1_external_request.id_external_request%TYPE,
        i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral identifier associated to given schedule identifier
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_schedule            Schedule Identifier 
    * @param   o_id_external_request    Referral Identifier
    * @param   o_error                  An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   29-04-2011
    */
    FUNCTION get_referral_id
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the sys_config option that determines if the destination column is to be shown or not
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional identifier, institution and software  
    * @param   o_show_opt 'Y' or 'N' depending if the destination column is to be shown or not. 
    * @param   o_error    An error message, set when return=false
    *
    * @return  TRUE if sucess, FALSE otherwise
    * @author  João Almeida 
    * @version 1.0
    * @since   22-02-2010
    */
    FUNCTION get_screen_dest_option
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_show_opt OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get Referral short detail (Patienet Portal)
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   i_id_external_request 
    * @param   O_sql referral detail
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-11-2010 */

    FUNCTION get_ref_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN table_number,
        o_detail              OUT ref_detail_cur,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_available_actions
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_active OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral detail
    *
    * @param   i_lang              Language associated to the professional executing the request
    * @param   i_prof              Professional, institution and software ids
    * @param   i_id_ext_req        Referral identifier
    * @param   i_status_detail     Detail status returned    
    * @param   o_detail            Referral general data
    * @param   o_text              Referral information detail
    * @param   o_problem           Patient problems
    * @param   o_diagnosis         Patient diagnosis
    * @param   o_mcdt              MCDTs information
    * @param   o_needs             Additional needs for scheduling
    * @param   o_info              Additional needs for the appointment
    * @param   o_notes_status      Referral historical data
    * @param   o_notes_status_det  Referral historical data detail
    * @param   o_answer            Referral answer information
    * @param   o_title_status      Deprecated   
    * @param   o_can_cancel        'Y' if the request can be canceled, 'N' otherwise
    * @param   o_ref_orig_data     Referral orig data   
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_status_detail     {*} 'A' Active {*} 'C' Canceled {*} 'O' Outdated {*} null all details
    * @value   o_can_cancel        {*} 'Y' if the request can be canceled {*} 'N' otherwise
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */

    FUNCTION get_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ext_req       IN p1_external_request.id_external_request%TYPE,
        i_status_detail    IN p1_detail.flg_status%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_title_status     OUT VARCHAR2,
        o_can_cancel       OUT VARCHAR2,
        o_ref_orig_data    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_p1_exr_flg_ald
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_ref       IN p1_external_request.id_external_request%TYPE,
        o_mcdt_list OUT pk_types.cursor_type,
        o_message   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Indicates for each MCDT, whether it is a chronic disease or not (FLG_ALD)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ref            Referral identifier    
    * @param   i_mcdt_ald       Chronic disease information for each MCDT (FLG_ALD) [id_mcdt|id_sample_type|flg_ald]
    * @param   o_p1_exr_temp    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-09-2012
    */
    FUNCTION set_p1_exr_flg_ald
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ref         IN p1_external_request.id_external_request%TYPE,
        i_mcdt_ald    IN table_table_varchar,
        o_p1_exr_temp OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update information about the duplicata report generated to this referral identifier
    * Used by reports
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral_tab    Array of referral identifiers
    * @param   i_id_epis_report_tab Array of epis_reports identifiers
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-03-2014
    */
    FUNCTION set_ref_report_duplicata
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_referral_tab    IN table_number,
        i_id_epis_report_tab IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update information about the original report generated to this referral identifier
    * Used by reports
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral_tab    Array of referral identifiers
    * @param   i_id_epis_report_tab Array of epis_reports identifiers
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   18-03-2014
    */
    FUNCTION set_ref_report_reprint
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_referral_tab    IN table_number,
        i_id_epis_report_tab IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get epis_report related to this referral, for the report type specified
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_referral        Referral identifier
    * @param   i_flg_rep_type       Report types flag
    *
    * @value   i_flg_rep_type       {*} D- duplicata
    *                               {*} R- reprint
    *
    * @return  number               Epis_report identifier
    *
    * @author  ana.monteiro
    * @since   18-03-2014
    */
    FUNCTION get_ref_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_referral  IN ref_report.id_external_request%TYPE,
        i_flg_rep_type IN ref_report.flg_type%TYPE
    ) RETURN epis_report.id_epis_report%TYPE;

    /**
    * Gets information about print list job related to the referral
    * Used by print list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_print_list_job  Print list job identifier, related to the referral
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   30-09-2014
    */
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    /**
    * Compares if a print list job context data is similar to the array of print list jobs
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_print_job_context_data       Print list job context data
    * @param   i_print_list_jobs              Array of print list job identifiers
    *
    * @return  table_number                   Arry of print list jobs that are similar
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number;

    /**
    * Gets the reports available to print the referrals
    * Used by reports, in print button
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_id_tasks                     Array of referral identifiers
    *
    * @return  t_coll_print_report            Array with all the reports available for printing
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-10-2014
    */
    FUNCTION tf_get_print_reports
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_tasks IN table_varchar
    ) RETURN t_coll_print_report;

    /**
    * Gets the reports and referral information available to print the referrals
    * Used by reports, in print button
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_id_tasks                     Array of referral identifiers
    * @param   i_id_report                    Report identifier
    *
    * @return  t_rec_print_report             Report and referral information available for printing
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   09-10-2014
    */
    FUNCTION tf_get_print_report
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_tasks  IN table_varchar,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN t_rec_print_report;

    /**
    * Adds the referral to the print list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_id_refs             List of referral identifiers to  be added to the print list
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    List of print list job identifiers
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_refs         IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets referral completion options.
    * Pop-up reformulation after development print list functionality
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_epis               Episode identifier
    * @param   i_codification       Codification identifiers   
    * @param   i_inst_dest          Referrals destination institutions
    * @param   i_flg_type           Referral type    
    * @param   i_spec               Referral speciality (in case of consultation referral type) or id_mcdt (in case of mcdt referral type: Id_Analysis, Exam.id_exam or Intervention.id_intervention)
    * @param   o_options            Referrals completion options
    * @param   o_print_options      Reports available to print the referral
    * @param   o_flg_show_popup     Flag that indicates if the pop-up is shown or not. If not, default option is assumed
    * @param   o_error              An error message, set when return=false
    *
    * @value   i_flg_type           {*} 'C' Consultation 
    *                               {*} 'A' Lab tests 
    *                               {*} 'I' Imaging exams
    *                               {*} 'E' Other exams
    *                               {*} 'P' Procedure
    *                               {*} 'F' Rehab
    *
    * @value   o_flg_show_popup     {*} 'Y' the pop-up is shown 
    *                               {*} 'N' otherwise
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   06-10-2014
    */
    FUNCTION get_completion_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_codification   IN table_number,
        i_inst_dest      IN table_number,
        i_flg_type       IN p1_external_request.flg_type%TYPE,
        i_spec           IN ref_completion_cfg.id_mcdt%TYPE,
        o_options        OUT pk_types.cursor_type,
        o_print_options  OUT pk_types.cursor_type,
        o_flg_show_popup OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns reports information available for the referral area
    * Used in print button by flash, in order to distinguish reports of referral area and general reports
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   o_cur_reports        Cursor with referral reports information:     
    *                               - id_reports: referral report identifiers
    *                               - column_name: column name from cursor PK_P1_EXT_SYS.get_pat_p1.o_detail, that has the value that flash must read, in order to enable/disable option in report button
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   16-10-2014
    */
    FUNCTION get_available_reports
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_cur_reports OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel all print items from the printing list (referral area)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_id_patient         Patient identifier
    * @param   i_id_episode         Episode identifier
    * @param   i_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   23-10-2014
    */
    FUNCTION set_print_jobs_cancel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN p1_external_request.id_patient%TYPE,
        i_id_episode IN p1_external_request.id_episode%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel all print items from the printing list (referral area)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_id_patient         Patient identifier
    * @param   i_id_episode         Episode identifier
    * @param   i_id_ref             Referral identifier
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   23-10-2014
    */
    FUNCTION set_print_jobs_complete
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN p1_external_request.id_patient%TYPE,
        i_id_episode IN p1_external_request.id_episode%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get new print arguments to the reports that need to be regenerated
    * Used by reports (pk_print_tool) when sending report to the printer (after selecting print button)    
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   io_print_arguments          Json string to be printed
    * @param   o_flg_regenerate_report     Flag indicating if the report needs to be regenerated or not
    * @param   o_error                     Error information
    *
    * @value   o_flg_regenerate_report     {*} Y- report needs to be regenerated {*} N- otherwise
    *
    * @RETURN  boolean                     TRUE if sucess, FALSE otherwise
    *
    * @author  ana.monteiro
    * @since   27-10-2014
    */
    FUNCTION get_print_args_to_regen_report
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        io_print_arguments      IN OUT print_list_job.print_arguments%TYPE,
        o_flg_regenerate_report OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Return number to be used in printed referrals.   
    *
    * @param      i_lang         professional language
    * @param      i_prof         professional, institution and software ids
    * @param      i_ext_req      referral id
    * @param      o_number       referral number
    * @param      O_ERROR        erro
    *
    * @return     boolean
    * @author     Joao Sa
    * @version    0.1
    * @since      2008/07/17
    * @modified    
    */
    FUNCTION get_referral_number
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_dt_req            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_ref_completion IN ref_completion.id_ref_completion%TYPE,
        o_number            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets **active** referrals information related to this episode
    *
    * @param   i_lang                   Language associated to the professional executing the request
    * @param   i_prof                   Professional, institution and software ids
    * @param   i_id_episode             Episode identifier
    * @param   o_coll_ref_info          Referral information
    * @param   o_error                  An error message, set when return=false    
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Ana Monteiro
    * @since   30-04-2015
    */
    FUNCTION get_referrals_by_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN p1_external_request.id_episode%TYPE,
        o_coll_ref_info OUT t_coll_ref_info,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION send_ref_to_bdnp
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_ref   IN p1_external_request.id_external_request%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ref_ext_sys;
/
