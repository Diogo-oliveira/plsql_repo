/*-- Last Change Revision: $Rev: 2028960 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_pp IS
    -- This package provides functions that are used solely on ALERT Private Practice.
    -- @author Nuno Guerreiro
    -- @version alpha

    /**
    * Gets a list of records to show on the Visit scheduling deepnav.
    *
    * @param  i_lang                    Language identifier.
    * @param  i_prof                    Professional
    * @param  i_id_patient              Patient identifier
    * @param  o_visit_sched             Visit scheduling records
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/10/15
    * 
    * UPDATED
    * alterado campo id_prof_dest e desc_prof_dest alterados, para corrigir os casos em que eram null
    * @author  José Antunes
    * @date    26-09-2008
    * @version 2.4.3
    */
    FUNCTION get_visit_sched
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_visit_sched OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the initial data for the visit scheduling screen.
    *
    * @param      i_lang              Language identifier
    * @param      i_prof              Professional
    * @param      i_id_consult_req    Consult request
    * @param      i_id_schedule       Appointment
    * @param      i_flg_view          Indicates whether or not the screen is on view mode       
    * @param      o_events            List of event types
    * @param      o_visit_types       List of visit types
    * @param      o_order_date        Order date
    * @param      o_order_date_desc   Translated order date
    * @param      o_next_visit_in     Notes for scheduling the next visit
    * @param      o_begin_date        Appointment's begin date
    * @param      o_begin_date_desc   Appointment's translated begin date
    * @param      o_end_date          Appointment's end date
    * @param      o_duration          Appointment's translated duration
    * @param      o_duration_min      Appointment's duration (minutes)
    * @param      o_instructions      Instructions for next follow-up visit
    * @param      o_notes             Notes
    * @param      o_error             Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/17
    */
    FUNCTION get_visit_init_load
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_consult_req  IN consult_req.id_consult_req%TYPE,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        i_flg_view        IN VARCHAR2,
        o_events          OUT pk_types.cursor_type,
        o_visit_types     OUT pk_types.cursor_type,
        o_order_date      OUT VARCHAR2,
        o_order_date_desc OUT VARCHAR2,
        o_next_visit_in   OUT VARCHAR2,
        o_begin_date      OUT VARCHAR2,
        o_begin_date_desc OUT VARCHAR2,
        o_end_date        OUT VARCHAR2,
        o_duration        OUT VARCHAR2,
        o_duration_min    OUT NUMBER,
        o_instructions    OUT pk_types.cursor_type,
        o_notes           OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the variable data for the visit scheduling screen (new/edit/view).
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment
    * @param      i_id_dep_clin_serv Type of visit
    * @param      i_id_sch_event     Event type
    * @param      i_flg_view         Indicates whether or not the screen is on view mode      
    * @param      o_reasons          Reasons for visit
    * @param      o_profs            Professionals
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/17
    */
    FUNCTION get_visit_subs_load
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_consult_req   IN consult_req.id_consult_req%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_view         IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_profs            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates/Updates a consult request when a disposition is created/changed.
    *
    * @param      i_lang                           Language identifier
    * @param      i_prof                           Professional
    * @param      i_id_consult_req                 Consult request (NULL for a new request)
    * @param      i_id_patient                     Patient identifier
    * @param      i_id_dep_clin_serv               Type of visit
    * @param      i_id_episode                     Episode identifier
    * @param      i_notes_admin                    Notes for the administrative
    * @param      i_id_prof_requested              Professional for whom the appointment request will be created
    * @param      i_reason_visit                   Reason for visit
    * @param      i_flg_instructions               Instructions for the next follow-up visit
    * @param      i_next_visit_in                  "Next follow-up visit in" notes
    * @param      o_id_consult_req                 Consult request (Same or New)
    * @param      o_button                         Buttons
    * @param      o_msg                            Warning message
    * @param      o_msg_title                      Warning message title
    * @param      o_flg_show                       Whether or not should a warning message be shown.
    * @param      o_error                          Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/17
    */
    FUNCTION set_disp_cons_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_consult_req    IN consult_req.id_consult_req%TYPE,
        i_id_patient        IN consult_req.id_patient%TYPE,
        i_id_dep_clin_serv  IN consult_req.id_dep_clin_serv%TYPE,
        i_id_episode        IN consult_req.id_episode%TYPE,
        i_notes_admin       IN consult_req.notes_admin%TYPE,
        i_id_prof_requested IN consult_req.id_prof_requested%TYPE,
        i_reason_visit      IN consult_req.id_complaint%TYPE,
        i_flg_instructions  IN consult_req.flg_instructions%TYPE,
        i_next_visit_in     IN consult_req.next_visit_in_notes%TYPE,
        i_dt_proposed       IN VARCHAR2,
        i_flg_type_date     IN consult_req.flg_type_date%TYPE,
        o_id_consult_req    OUT consult_req.id_consult_req%TYPE,
        o_button            OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_flg_show          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels an appointment, a request (without appointment) or both a request and an appointment.
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment
    * @param      i_cancel_request   'Y' to cancel the consult request, 'N' otherwise.
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/18
    */
    FUNCTION cancel_visit_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_cancel_request IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * cancel_visit_sched Function overload
    *
    * @param      i_id_cancel_reason Language identifier
    * @param      i_cancel_notes     Consult request
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Pedro Teixeira
    * @version    1
    * @since      27/10/2009
    */
    FUNCTION cancel_visit_sched
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_consult_req   IN consult_req.id_consult_req%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_cancel_request   IN VARCHAR2,
        i_id_cancel_reason IN consult_req.id_cancel_reason%TYPE,
        i_cancel_notes     IN consult_req.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates/updates an appointment, on the Visit scheduling screen.
    * 
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Original appointment (NULL if no appointment exists)
    * @param      i_id_patient       Patient
    * @param      i_id_episode       Episode
    * @param      i_id_sch_event     Event type
    * @param      i_id_dep_clin_serv Type of visit
    * @param      i_id_complaint     Reason for visit
    * @param      i_instructions     Instructions for the next follow-up visit.
    * @param      i_id_prof          Professional that will carry out the appointment
    * @param      i_dt_begin         Appointment's begin date
    * @param      i_minutes          Appointment's duration (number of minutes)
    * @param      i_schedule_notes   Notes
    * @param      o_id_schedule      New/Updated appointment
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/18
    */
    FUNCTION set_visit_sched
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_consult_req   IN consult_req.id_consult_req%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_complaint     IN schedule.id_reason%TYPE,
        i_instructions     IN schedule.flg_instructions%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_minutes          IN NUMBER,
        i_schedule_notes   IN VARCHAR2,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a disposition can be changed, that is, if no active appointments exist already for that dispostion.
    *
    * @param  i_lang                    Language identifier.
    * @param  i_prof                    Professional
    * @param  i_id_consult_req          Consult request
    * @param  o_button                  Buttons
    * @param  o_msg                     Error message (business logic) to be shown when an active appointment exists
    * @param  o_msg_title               Error message title to be shown when an active appointment exists
    * @param  o_flg_show                'Y' if a business error occurred (an active appointment exists)
    * @param  o_change                  1 if the disposition can be changed, 0 otherwise
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/11/15
    */
    FUNCTION check_disp_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_button         OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_change         OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_visit_request_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';
    /* Message code for an unexpected exception. */
    g_not_available CONSTANT VARCHAR2(11) := 'N/A';
    /* Status domain */
    g_flg_status_domain CONSTANT VARCHAR2(32) := 'SCHEDULE_PP.FLG_STATUS';
    /* Instructions domain */
    g_flg_instructions_domain CONSTANT VARCHAR2(32) := 'SCHEDULE.FLG_INSTRUCTIONS';
    /* Disposition warning message */
    g_disp_warn_msg CONSTANT VARCHAR2(32) := 'SCH_T188';
    /* Disposition warning message title */
    g_disp_warn_msg_title CONSTANT VARCHAR2(32) := 'SCH_T189';
    /* Visit scheduling statuses: Scheduled */
    g_visit_sched_stat_scheduled CONSTANT VARCHAR2(1) := 'S';
    /* Visit scheduling statuses: Requested */
    g_visit_sched_stat_requested CONSTANT VARCHAR2(1) := 'R';
    /* Visit scheduling statuses: Cancelled */
    g_visit_sched_stat_cancelled CONSTANT VARCHAR2(1) := 'C';

    g_flg_type_n CONSTANT category.flg_type%TYPE := 'N';
    g_flg_type_a CONSTANT category.flg_type%TYPE := 'A';

    /* Epis_type NURSE */
    g_nurse_type_care CONSTANT NUMBER := 14;
    g_nurse_type_outp CONSTANT NUMBER := 16;
    g_nurse_type_pp   CONSTANT NUMBER := 17;

    g_epis_type_nurse   CONSTANT VARCHAR2(1) := 'N';
    g_epis_type_nutri   CONSTANT VARCHAR2(1) := 'U';
    g_epis_type_consult CONSTANT VARCHAR2(1) := 'C';

    g_sch_event_therap_decision sch_event.id_sch_event%TYPE := 20;

    -- bollean
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
END pk_schedule_pp;
/
