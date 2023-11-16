/*-- Last Change Revision: $Rev: 2028949 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:55 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_api_upstream AS

    /*
    * Gets a new transaction ID and begins it
    *
    * @return Transaction identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009      
    */
    FUNCTION begin_new_transaction
    (
        i_transaction_id VARCHAR2,
        i_prof           profissional DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * start new remote transaction and save its ID inside the package
    *
    * @param i_prof 
    *
    * @author   Telmo
    * @version  2.6.0.5
    * @date     18-03-2011
    */
    PROCEDURE get_transaction(i_prof profissional DEFAULT NULL);

    /*
    * Cancels an appointment.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_cancel_reason   Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param i_dt_referral         data operacao referral 
    * @param  i_referral_reason   ALERT-259898
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Teste
    * @version 1.0
    * @since   21-10-2009      
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral      IN timestamp with local time zone DEFAULT NULL,
        i_referral_reason  IN p1_reason_code.id_reason_code%TYPE default null,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a consult registration in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id 
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION cancel_scheduler_registration
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels a consult registration in the scheduler. New version of cancel_scheduler_registration function 
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id 
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   24-05-2011
    */
    FUNCTION cancel_registration_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Confirms a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION confirm_pending_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_id_schedule    OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Confirms a patient for a given schedule
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_id_patient                  Patient identifier
    * @param i_prof_confirm                Professional that confirmed the schedule
    * @param i_confirm_date                Date of schedule confirmation  
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Nogueira
    * @version 1.0
    * @since   27-01-2009      
    */
    FUNCTION confirm_person
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_prof_confirm   IN profissional,
        i_confirm_date   IN schedule.dt_begin_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an appointment in scheduler 3 and after that the same appointment in pfh.
    * used by PK_P1_INTERFACE and PK_REF_INTERFACE
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_event_id           Associated event id
    * @param i_professional_id    Physician id
    * @param i_id_patient         Patient id
    * @param i_id_dep_clin_serv   id dep clin serv 
    * @param i_dt_begin_tstz      Appointment begin date 
    * @parma i_dt_end_tstz        Appointment end date
    * @param i_flg_vacancy         Flag vacancy ( Type of vacancy occupied: 'R' routine, 'U' urgent, 'V' unplanned )
    * @param i_id_episode         Episode ids
    * @param i_flg_rqst_type      Appointment's request type (patient, physician, nurse, institution)  
    * @param i_flg_sch_via        Scheduling by telephone contact
    * @param i_sch_notes          schedule notes
    * @param i_id_inst_requests   requesting instit
    * @param i_id_dcs_requests    requesting dcs
    * @param i_id_prof_requests    requesting prof
    * @param i_id_prof_schedules  scheduling prof
    * @param i_id_sch_ref         reference to this schedule
    * @param i_transaction_id     Scheduler transaction identifier
    * @param i_id_external_req    P1 identifier
    * @param i_dt_referral         data operacao referral
    * @param o_id_schedule         list of new PFH schedule ids
    * @param o_id_schedule_ext    new scheduler 3 id
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @since   21-12-2009      
    */
    FUNCTION create_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_id          IN schedule.id_sch_event%TYPE,
        i_professional_id   IN professional.id_professional%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz     IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tstz       IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy       IN schedule.flg_vacancy%TYPE,
        i_id_episode        IN schedule.id_episode%TYPE,
        i_flg_rqst_type     IN schedule.flg_request_type%TYPE,
        i_flg_sch_via       IN schedule.flg_schedule_via%TYPE,
        i_sch_notes         IN schedule.schedule_notes%TYPE,
        i_id_inst_requests  IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_dcs_requests   IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_prof_requests  IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_sch_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_transaction_id    IN VARCHAR2,
        i_id_external_req   IN p1_external_request.id_external_request%TYPE,
        i_dt_referral       IN timestamp with local time zone DEFAULT NULL,
        o_ids_schedule      OUT table_number,
        o_id_schedule_ext   OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates an appointment in scheduler 3 and after the same appointment in pfh.
    * This version of create_schedule has support for appointments not found.
    * used in pk_ehr_access.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_event_id           Associated event id
    * @param i_professional_id    Physician id
    * @param i_id_patient         Patient id
    * @param i_id_dep_clin_serv   id dep clin serv 
    * @param i_dt_begin_tstz      Appointment begin date 
    * @parma i_dt_end_tstz        Appointment end date
    * @param i_flg_vacancy         Flag vacancy ( Type of vacancy occupied: 'R' routine, 'U' urgent, 'V' unplanned )
    * @param i_id_episode         Episode ids
    * @param i_flg_rqst_type      Appointment's request type (patient, physician, nurse, institution)  
    * @param i_flg_sch_via        Scheduling by telephone contact
    * @param i_sch_notes          schedule notes
    * @param i_id_inst_requests   requesting instit
    * @param i_id_dcs_requests    requesting dcs
    * @param i_id_prof_requests    requesting prof
    * @param i_id_prof_schedules  scheduling prof
    * @param i_id_sch_ref         reference to this schedule
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_id_schedule         list of new PFH schedule ids
    * @param o_id_schedule_ext    new scheduler 3 id
    * @param o_flg_proceed        show stopper
    * @param o_flg_show           show stopper
    * @param o_msg_title          popup message title
    * @param o_msg                popup message message
    * @param o_button             popup buttons
    * @param o_error              error data
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @since   23-04-2010      
    */
    FUNCTION create_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_id          IN schedule.id_sch_event%TYPE,
        i_professional_id   IN professional.id_professional%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz     IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tstz       IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy       IN schedule.flg_vacancy%TYPE,
        i_id_episode        IN schedule.id_episode%TYPE,
        i_flg_rqst_type     IN schedule.flg_request_type%TYPE,
        i_flg_sch_via       IN schedule.flg_schedule_via%TYPE,
        i_sch_notes         IN schedule.schedule_notes%TYPE,
        i_id_inst_requests  IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_dcs_requests   IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_prof_requests  IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_sch_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_transaction_id    IN VARCHAR2,
        o_ids_schedule      OUT table_number,
        o_id_schedule_ext   OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_flg_proceed       OUT VARCHAR2,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Schedules a intervention for a given schedule
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional that requested the procedure scheduling
    * @param i_id_schedule                 Schedule identifier
    * @param i_institution_request         Institution where the request was created
    * @param i_institution_requested       Target institution where the procedure will take place
    * @param i_dcs_request_id              Dep_clin_serv associated with the request institution
    * @param i_dcs_requested_id            Dep_clin_serv associated with the target institution
    * @param i_content_id                    
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Nogueira
    * @version 1.0
    * @since   27-01-2009      
    */

    FUNCTION create_schedule_intervention
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_schedule             IN schedule.id_schedule%TYPE,
        i_institution_request     IN institution.id_institution%TYPE,
        i_institution_requested   IN institution.id_institution%TYPE,
        i_dep_clin_serv_request   IN schedule.id_dcs_requests%TYPE,
        i_dep_clin_serv_requested IN schedule.id_dcs_requests%TYPE,
        i_reason_notes            IN schedule.reason_notes%TYPE,
        i_flg_urgency             IN schedule.flg_urgency%TYPE,
        i_flg_status              IN schedule.flg_status%TYPE,
        i_dt_begin_tstz           IN schedule.dt_begin_tstz%TYPE,
        i_dt_create_tstz          IN schedule.dt_schedule_tstz%TYPE,
        i_flg_schedule_type       IN schedule.flg_sch_type%TYPE,
        i_target_professional     IN professional.id_professional%TYPE,
        i_id_interv_presc_det     IN schedule_intervention.id_interv_presc_det%TYPE,
        i_transaction_id          IN VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Commits a remote transaction
    *
    * @param i_id_transaction     Language identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009      
    */
    PROCEDURE do_commit
    (
        i_id_transaction IN VARCHAR2,
        i_prof           IN profissional DEFAULT NULL
    );

    /*
    * Commits a remote transaction
    *
    * @param i_prof
    *
    * @author  Telmo Castro
    * @version 2.6.0.5
    * @date     18-03-2011
    */
    PROCEDURE do_commit(i_prof IN profissional DEFAULT NULL);

    /*
    * Rollback a remote transaction
    *
    * @param i_id_transaction     Language identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009      
    */
    PROCEDURE do_rollback
    (
        i_id_transaction IN VARCHAR2,
        i_prof           IN profissional DEFAULT NULL
    );

    /*
    * Rollback a remote transaction
    *
    * @param i_prof
    *
    * @author  Telmo Castro
    * @version 2.6.0.5
    * @date    18-03-2011
    */
    PROCEDURE do_rollback(i_prof IN profissional DEFAULT NULL);

    /*
    * Sets a schedule bed.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_id_patient                  Patient identifier
    * @param i_flg_notification_via        Nitification via
    * @param i_flg_notification_via        Professional notification identifier (ID)
    * @param i_dt_notification             Date of notification
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION notify_person
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_flg_notification_via IN sys_domain.val%TYPE,
        i_id_professional      IN professional.id_professional%TYPE,
        i_dt_notification      IN schedule.dt_notification_tstz%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivates a previously cancelled schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION reactivate_canceled_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Re-Schedules an intervention for a given schedule
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional that requested the procedure scheduling
    * @param i_id_schedule                 Schedule identifier
    * @param i_old_id_schedule            Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *   
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Nogueira
    * @version 1.0
    * @since   04-02-2010      
    */

    FUNCTION recreate_schedule_intervention
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_schedule             IN schedule.id_schedule%TYPE,
        i_old_id_schedule         IN schedule.id_schedule%TYPE,
        i_institution_request     IN institution.id_institution%TYPE,
        i_institution_requested   IN institution.id_institution%TYPE,
        i_dep_clin_serv_request   IN schedule.id_dcs_requests%TYPE,
        i_dep_clin_serv_requested IN schedule.id_dcs_requests%TYPE,
        i_reason_notes            IN schedule.reason_notes%TYPE,
        i_dt_begin_tstz           IN schedule.dt_begin_tstz%TYPE,
        i_dt_create_tstz          IN schedule.dt_schedule_tstz%TYPE,
        i_id_interv_presc_det     IN schedule_intervention.id_interv_presc_det%TYPE,
        i_transaction_id          IN VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Removes a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION remove_pending_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Registers a consult in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id 
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION register_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Registers a consult in the scheduler. New version of register_schedule function 
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id 
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   24-05-2011
    */
    FUNCTION register_schedule_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the consult state in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_flg_state          Flag of the consult status (SCHEDULE_OUTP.FLG_STATE sys_domain)
    * @param i_id_patient         
    * @param i_transaction_id     Transaction identifier (if already got one)
    * @param o_error              Error object
    *
    * @return TRUE if sucess, FALSE otherwise
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION set_schedule_consult_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_state      IN schedule_outp.flg_state%TYPE,
        i_id_patient     IN patient.id_patient%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets the consult state in the scheduler. New version of set_schedule_consult_state function 
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_flg_state          Flag of the consult status (SCHEDULE_OUTP.FLG_STATE sys_domain)
    * @param i_id_patient         
    * @param o_error              Error object
    *
    * @return TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.1
    * @date    24-05-2011
    */
    FUNCTION set_consult_state_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_state   IN schedule_outp.flg_state%TYPE,
        i_id_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Sets a schedule bed.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_bed             Bed identifier
    * @param i_dt_new_end_date    Bed schedule new end date
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION set_schedule_bed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        i_id_bed          IN bed.id_bed%TYPE,
        i_dt_new_end_date IN schedule.dt_end_tstz%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Muda o agendamento associado a um paciente para outro. 
     * Apenas usado nos agendamentos do ORIS(schedule_sr), 
     * em que um id_schedule associado a um episodio temporario passa a estar associado 
     * a um novo id_episode definitivo.. 
     *   
     *
     * 
     * @param i_lang               Language identifier
     * @param i_prof               Professional data: id, institution and software
     * @param i_id_episode         Episode associated to the schedule
     * @param i_id_patient_add     Patient to add to the new scheduler    
     * @param i_id_patient_rem     Patient to remove from scheduler
     * @param i_transaction_id     Scheduler transaction identifier
     * @param o_error               An error message, set when return=false
     *
     * @RETURN  TRUE if sucess, FALSE otherwise
     * @author  Carlos Nogueira
     * @version 1.0
     * @since   28-01-2010  
    */
    FUNCTION update_schedule_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient_add IN patient.id_patient%TYPE,
        i_id_patient_rem IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * @param i_lang               Language identifier
     * @param i_prof               Professional data: id, institution and software
     * @param i_id_schedule        Schedule identifier
     * @param i_dep_clin_serv_old   Id que permite obtencao do id_content
     * @param i_dep_clin_serv_new   Id que permite obtencao do id_content
     * @param i_dt_begin_tstz       Data de inicio a actualizar
     * @param i_dt_end_tstz         Data de fim a actualizar
     * @param i_flg_request         
     * @param i_transaction_id     Scheduler transaction identifier
     * @param o_error               An error message, set when return=false
     *
     * @RETURN  TRUE if sucess, FALSE otherwise
     * @author  Carlos Nogueira
     * @version 1.0
     * @since   28-01-2010  
    */
    FUNCTION update_sch_proc_and_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin_tstz    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tszt      IN schedule.dt_end_tstz%TYPE,
        i_dep_clin_serv    IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_request_type IN schedule.flg_request_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Confirms a pending schedule and sets the schedule's exam requisitions
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION set_status_and_exam_reqs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_sch_ext     IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_ids_exam       IN table_number,
        i_ids_exam_req   IN table_number,
        i_transaction_id IN VARCHAR2,
        o_id_schedule    OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * send bed new blocked period to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION block_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng_action        IN bmng_action.id_bmng_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * send bed new non blocked period to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION unblock_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng_action IN bmng_action.id_bmng_action%TYPE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * send new bed allocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_speciality                speciality of the allocation
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION allocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_speciality  IN NUMBER,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng        IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * send updated bed allocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param i_new_end_date                new end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION update_allocated_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_new_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        i_id_bmng        IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * send bed deallocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION deallocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * notifies scheduler 3 about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3.4
    * @date    29-10-2010
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * this function returns value of sys_config entry 'SCHEDULER3_INSTALLED'.
    * Uses id_institution and id_software from i_prof to fetch the correct value.
    *
    * @param i_prof               Professional data: id, institution and software
    *
    * @return                 Y/N
    *
    * @author                     Telmo
    * @version                    2.6.0.3.4
    * @since                      28-10-2010
    */
    FUNCTION is_scheduler_installed(i_prof IN profissional) RETURN sys_config.value%TYPE;

    /*
    * Sends the new contact type value to the scheduler.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_flg_contact_Type            new contact type value. I= patient absent; D=patient present
    * @return TRUE if sucess, FALSE otherwise               
    *
    * @author                     Telmo
    * @version                    2.6.0.5.4
    * @since                      17-03-2011
    */
    FUNCTION set_flg_contact_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_flg_contact_type IN sch_group.flg_contact_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an appointment. This is the new version made according to alert-167145 new rules.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_sch_cancel_reason Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   07-06-2011
    */
    FUNCTION cancel_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN timestamp with local time zone DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE default null,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels several appointments. If one fails, everything is rolled back.
    * Initial usage by the Trials feature.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_schedule       PFH schedule identifiers
    * @param i_id_cancel_reason   Cancel reason id. All schedules will share the same id
    * @param i_cancel_notes       Cancel notes. All schedules will share the same notes
    * @param i_cancel_exam_req    Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    * 
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.1
    * @since   07-06-2011
    */
    FUNCTION cancel_schedules
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_ids_schedule         IN table_number,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN timestamp with local time zone DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE default null,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;


    /*
    * cancel a previous patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.3.1
    * @date    17-10-2011
    */
    FUNCTION cancel_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    
    
    /*
    * Add requisition to lab appointment. This tipically happens for lab appointments without initial requisition.
    * After it is registered, its possible to add requisitions for further lab harvests within the episode, and
    * thats where this function comes in.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_req                      requisition id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.7
    * @date    22-07-2013
    */
    FUNCTION add_req_to_sch
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_req           IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    
    /*
    * Cancels several appointments. If one fails, everything is rolled back, if not
    * is commited.
    * Initial usage by RESET.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_transaction_id     Scheduler transaction identifier
    * @param i_ids_schedule       PFH schedule identifiers
    * @param i_id_cancel_reason   Cancel reason id. All schedules will share the same id
    * @param i_cancel_notes       Cancel notes. All schedules will share the same notes
    * @param i_cancel_exam_req    Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    * 
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Gustavo
    * @version 2.6.3.8.3
    * @since   30-10-2013
    */
    FUNCTION cancel_schedules
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_transaction_id       IN VARCHAR2,
        i_ids_schedule         IN table_number,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;


    /*
    * Cancels a exam/other exam schedule, based on a id_exam_req and id_exam. 
    * alert-167145 compliant.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_exam            exam id
    * @param i_id_exam_req        exam req id
    * @param i_id_sch_cancel_reason Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.4.2
    * @since   07-10-2014
    */
    FUNCTION cancel_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_exam              IN schedule_exam.id_exam%type,
        i_id_exam_req          IN schedule_exam.id_exam_req%type,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    
    
    ----------- PUBLIC VARS, CONSTANTS ---------------
    g_error         VARCHAR2(4000);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
    g_exception EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    g_null CONSTANT VARCHAR2(1) := NULL;
    --Scheduled
    g_flg_state_scheduled CONSTANT VARCHAR2(1) := 'A';
    --Patient waiting
    g_flg_state_pat_waiting CONSTANT VARCHAR2(1) := 'E';
    --Appointment
    g_flg_state_appointment CONSTANT VARCHAR2(1) := 'T';
    --Waiting area
    g_flg_state_waiting_area CONSTANT VARCHAR2(1) := 'C';
    --Waiting for nursing encounter
    g_flg_state_wait_nurse_encount CONSTANT VARCHAR2(1) := 'W';
    --Nursing encounter / appointment
    g_flg_state_nurse_encounter CONSTANT VARCHAR2(1) := 'N';
    --End of encounter with nurse
    g_flg_state_end_nurse_encount CONSTANT VARCHAR2(1) := 'P';
    --Waiting for encounter with techniciang_flg_state_scheduled
    g_flg_state_wait_tech_encount CONSTANT VARCHAR2(1) := 'G';
    --Encounter with technician
    g_flg_state_tech_encounter CONSTANT VARCHAR2(1) := 'K';
    --End of encounter with technician
    g_flg_state_end_tech_encounter CONSTANT VARCHAR2(1) := 'F';
    --Physician discharge
    g_flg_state_phys_discharge CONSTANT VARCHAR2(1) := 'D';
    --Nutrition discharge
    g_flg_state_nurse_discharge CONSTANT VARCHAR2(1) := 'U';
    --Administrative discharge
    g_flg_state_adm_discharge CONSTANT VARCHAR2(1) := 'M';
    --Requested
    g_flg_state_requested CONSTANT VARCHAR2(1) := 'R';
    --Patient No show
    g_flg_state_noshow CONSTANT VARCHAR2(1) := 'B';

    --
    -- *************************************************************
    FUNCTION hhc_undo_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- **********************************************
    FUNCTION hhc_approve_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_schedule_api_upstream;
/
