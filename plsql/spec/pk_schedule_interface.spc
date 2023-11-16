/*-- Last Change Revision: $Rev: 2028954 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_interface IS
    -- This package provides the API to be used by InterAlert for ALERT Scheduler.
    -- @author Nuno Guerreiro
    -- @version alpha

    /* Type for CREATEs and GETs */
    TYPE schedule_outp_struct IS RECORD(
        id_schedule            NUMBER, -- Schedule identifier (only filled on GETs)
        id_instit_requests     NUMBER, -- Institution that requested the schedule (Optional for CREATE)
        id_instit_requested    NUMBER, -- Institution that is requested for the schedule.
        id_dcs_requests        NUMBER, -- Department-Clinical Service that requested the schedule (Optional for CREATE)
        id_dcs_requested       NUMBER, -- Department-Clinical Service that is requested for the schedule .
        id_prof_requests       NUMBER, -- Professional that requests the schedule (Option for CREATE).
        id_prof_requested      NUMBER, -- Professional requested to carry out the schedule.
        id_prof_schedules      NUMBER, -- Professional that created the schedule.
        id_prof_cancel         NUMBER, -- Professional that cancelled the schedule (Optional for CREATE).
        id_epis_type           NUMBER, -- Episode type.
        id_cancel_reason       NUMBER, -- Cancellation reason (Optional for CREATE).
        id_patient             NUMBER, -- Patient
        id_lang_translator     NUMBER, -- Translator language (Optional for CREATE).
        id_lang_preferred      NUMBER, -- Preferred language (Optional for CREATE).
        id_reason              NUMBER, -- Reason for the schedule (Optional for CREATE).
        id_origin              NUMBER, -- Origin (Optional for CREATE).
        id_room                NUMBER, -- Room (Optional for CREATE).
        id_schedule_ref        NUMBER, -- Previous schedule, if this schedule is a result of a reschedule (Optional for CREATE).
        dt_begin               TIMESTAMP WITH TIME ZONE, -- Schedule begin date
        dt_end                 TIMESTAMP WITH TIME ZONE, -- Schedule end date (Optional for CREATE).
        dt_cancel              TIMESTAMP WITH TIME ZONE, -- Cancellation date (Optional for CREATE).
        schedule_notes         VARCHAR2(4000), -- Free-text for notes.
        flg_first_subs         VARCHAR2(0050), -- First or subsequent flag
        flg_notification       VARCHAR2(0050), -- Notification flag
        flg_vacancy            VARCHAR2(0050), -- Vacancy flag
        flg_status             VARCHAR2(0050), -- Status flag (Optional for CREATE).
        flg_ignore_cancel      VARCHAR2(0050), -- Whether or not should existing cancelled schedules be ignored on creation. (Optional for CREATE)
        reason_notes           VARCHAR2(4000), -- Reason for the schedule in free-text (Optional for CREATE).
        ref_num                NUMBER, -- P1
        flg_schedule_via       VARCHAR2(0050), -- The way the appointment was created (telephone, etc)
        flg_sched_request_type VARCHAR2(0050), -- Who requested the appointment (patient, physician, etc
        flg_sched_type         VARCHAR2(1), -- Indirect or direct contacts
        id_sch_event           NUMBER -- event ID. Optional
        );

    /* Type for CANCEL */
    TYPE schedule_outp_cancel_struct IS RECORD(
        id_schedule    NUMBER, -- Schedule identifier.
        id_prof_cancel NUMBER, -- Professional that canceled the schedule.
        id_reason      NUMBER, -- Reason for cancellation. (Optional) 
        cancel_notes   VARCHAR2(4000), -- Free-text for cancellation notes.
        dt_cancel      TIMESTAMP WITH TIME ZONE -- Date of cancellation.
        );

    /* Type for SET_SCHEDULE_PENDING_OUTP */
    TYPE schedule_outp_setpend_struct IS RECORD(
        id_schedule   NUMBER, -- Schedule identifier.
        flg_status    VARCHAR2(0050), -- Status flag.
        pending_notes VARCHAR2(4000) -- Free-text for errors, etc.
        );

    /* Type for CREATE_ABSENCE and GET_ABSENCE */
    TYPE schedule_absence_struct IS RECORD(
        id_absence      NUMBER, -- Absence identifier (Optional, only filled on GETs)
        id_professional NUMBER, -- Professional identifier
        id_institution  NUMBER, -- Institution identifier
        dt_begin        TIMESTAMP WITH LOCAL TIME ZONE, -- Absence start date
        dt_end          TIMESTAMP WITH LOCAL TIME ZONE, -- Absence end date
        desc_absence    VARCHAR2(4000), -- Absence description,
        flg_type        VARCHAR2(0050), -- Absence type: T training, S sick, V vacations, O other
        flg_status      VARCHAR2(0050) -- Absence status: A active, I inactive
        );

    /*
    * Returns the next available schedule identifier.
    * 
    * @return next available schedule identifier
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/04
    */
    FUNCTION get_next_schedule_id RETURN schedule.id_schedule%TYPE;

    /*
    * Checks if a duplicate schedule already exists.
    * 
    * @param  i_sched_outp        Record containing data from an external system.
    * @param  o_exists            Whether or not the schedule exists.
    * @param  o_id_sched          Schedule identifier on ALERT Scheduler.
    * @param  o_error             Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/06/04
    */
    FUNCTION exists_matching_schedule
    (
        i_sched_outp IN schedule_outp_struct,
        o_exists     OUT BOOLEAN,
        o_id_sched   OUT schedule.id_schedule%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates an outpatient schedule on ALERT Scheduler.
    * 
    * @param  i_sched_outp        Record containing data from an external system.
    * @param  o_new_id_sched      Schedule identifier on ALERT Scheduler.
    * @param  o_warning           Warning message.
    * @param  o_error             Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/05/09
    */
    FUNCTION create_schedule_outp
    (
        i_sched_outp   IN schedule_outp_struct,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a record containing data for the given schedule.
    * 
    * @param  i_id_sched        Schedule identifier on ALERT Scheduler.
    * @param  o_sched_outp      Record containing data for the schedule identifier by i_id_sched.
    * @param  o_warning         Warning message.
    * @param  o_error           Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/05/09
    */
    FUNCTION get_schedule_outp
    (
        i_id_sched   IN schedule.id_schedule%TYPE,
        o_sched_outp OUT schedule_outp_struct,
        o_warning    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a schedule.
    * 
    * @param  i_sched_outp_cancel       Cancellation data.
    * @param  o_warning                 Warning message.
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/05/09
    */
    FUNCTION cancel_schedule_outp
    (
        i_sched_outp_cancel IN schedule_outp_cancel_struct,
        o_warning           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a given schedule can be transported to 
    * another system (e.g. if it is an outpatient consult).
    * To be primarily used by BEFORE INSERT OR UPDATE triggers.
    * 
    * @param  i_id_sched                Schedule identifier.
    * @param  o_transportable           Whether or not the schedule is transportable.
    * @param  o_warning                 Warning message.
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/05/09
    */
    FUNCTION is_transportable
    (
        i_id_sched      IN schedule.id_schedule%TYPE,
        o_transportable OUT BOOLEAN,
        o_warning       OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Makes an appointment (outpatient) transit to the pending state,
    * after an error while trying to transport it to an
    * external system.
    * 
    * @param  i_set_pending             Data for setting an appointment's status.
    * @param  o_warning                 Warning message.
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/05/30
    */
    FUNCTION set_schedule_pending_outp
    (
        i_set_pending IN schedule_outp_setpend_struct,
        o_warning     OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new absence period.
    *
    * @param  i_absence     Record containing the absence period's information.
    * @param  o_id_absence  Create absence period's identifier
    * @param  o_error       Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/04
    */
    FUNCTION create_absence
    (
        i_absence    IN schedule_absence_struct,
        o_id_absence OUT sch_absence.id_sch_absence%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels an absence period.
    *
    * @param  i_id_absence  Absence identifier.
    * @param  o_error       Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/04
    */
    FUNCTION cancel_absence
    (
        i_id_absence IN sch_absence.id_sch_absence%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information about a given absence
    *
    * @param  i_id_absence  Absence identifier.
    * @param  o_absence     Absence information.
    * @param  o_error       Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/04
    */
    FUNCTION get_absence
    (
        i_id_absence IN sch_absence.id_sch_absence%TYPE,
        o_absence    OUT schedule_absence_struct,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if a duplicate schedule already exists.
    *
    * @param  i_lang                 Language 
    * @param  i_prof                 Professional identification
    * @param  i_id_patient           Patient identifier
    * @param  i_id_instit_requested  Institution to which was scheduled the appointment
    * @param  i_id_dep_clin_serv     Dep_clin_serv associated to the schedule to search
    * @param  i_id_sch_event         Event of the schedule to be searched (7-exams; 13- other exams)
    * @param  i_id_prof_scheduled    Professional associated to the schedule to search
    * @param  i_sch_dt_begin         Begin date of the schedule
    * @param  i_flg_ignore_cancel    Indicates if it is to consider the cancelled appointments. The null value has the same behavior as the ‘N’ value
    * @param  o_exists               Whether or not the schedule exists.
    * @param  o_id_sched             Schedule identifier on ALERT Scheduler.
    * @param  o_error                Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Sofia Mendes
    * @version 2.5.0.7.4.1
    * @since  2010/01/27
    */
    FUNCTION check_appointment_radlab
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event        IN sch_event.id_sch_event%TYPE,
        i_id_prof_scheduled   IN professional.id_professional%TYPE,
        i_sch_dt_begin        IN schedule.dt_begin_tstz%TYPE,
        i_flg_ignore_cancel   IN VARCHAR2,
        o_exists              OUT BOOLEAN,
        o_id_sched            OUT schedule.id_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates an exam schedule on ALERT Scheduler.
    * 
    * @param  i_lang                 Language ID for translations
    * @param  i_prof                 Professional that is creating the schedule
    * @param  i_id_patient           Patient that will be associated to the schedule
    * @param  i_id_schedule          Schedule identifier.
    * @param  i_id_dep_clin_serv     Dep_clin_serv identifier.
    * @param  i_id_sch_event         Schedule event identifier.
    * @param  i_id_prof              Professional for who will be scheduled the appointment
    * @param  i_dt_begin             Schedule start date
    * @param  i_dt_end               Schedule end date
    * @param  i_id_instit_requested  Institution associated to the schedule.
    * @param  i_flg_vacancy          Type of vacancy occupied.
    * @param  i_schedule_notes       Schedule notes.
    * @param  i_id_lang_translator   Translator’s language
    * @param  i_id_lang_preferred    Patient’s preferred language
    * @param  i_id_reason            Reason for visit
    * @param  i_id_origin            Patient’s origin
    * @param  i_id_room              Room where the appointment takes place
    * @param  i_ids_exams            Table number with the exam ids that should be associated to the schedule.
    *                                This parameter can only be:
    *                                      - null if the i_ids_exam_reqs parameter is not null.
    *                                      - not null if the i_ids_exam_reqs parameter is null. 
    * @param  i_reason_notes         Appointment reason in plain text
    * @param  i_ids_exam_reqs        Table number with the exam requests ids that should be associated to the schedule.
    *                                This parameter can only be:
    *                                     - null if the i_ids_exam_reqs parameter is not null.
    *                                     - not null if the i_ids_exam_reqs parameter is null.
    * @param  i_id_schedule_ref     Previous schedule, if this schedule is a result of a reschedule (Should be null for CREATE)
    * @param  i_flg_request_type    Appointment’s request type
    * @param  i_flg_schedule_via    The way the appointment was created (telephone, etc)
    * @param  i_do_overlap          
    * @param  i_id_consult_vac      Vacancy id
    * @param  i_sch_option          Type of schedule.
    * @param  i_id_episode          Episode identifier.
    * @param  i_flg_ignore_cancel   Indicates whether or not existing cancelled schedules should be ignored on creation.
    * @param  i_ref_num             Referral number. This parameter should not be null if when creating a new schedule it is 
    *                               pretended to associate the schedule to a referral. When updating an existing schedule, 
    *                               this function does not consider this parameter value (the new schedule only stays with 
    *                               the association that exists on the cancelled schedule [if it exists])       
    * @param  o_new_id_sched      Schedule identifier on ALERT Scheduler.
    * @param  o_warning           Warning message.
    * @param  o_error             Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Sofia Mendes
    * @version 2.5.0.7.4.1
    * @since  2010/02/04    
    */
    FUNCTION create_schedule_exam
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event        IN schedule.id_sch_event%TYPE,
        i_id_prof             IN sch_resource.id_professional%TYPE,
        i_dt_begin            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end              IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes      IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason           IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin           IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room             IN schedule.id_room%TYPE DEFAULT NULL,
        i_ids_exams           IN table_number DEFAULT NULL,
        i_reason_notes        IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_ids_exam_reqs       IN table_number DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap          IN VARCHAR2,
        i_id_consult_vac      IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option          IN VARCHAR2,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_flg_ignore_cancel   IN VARCHAR2,
        i_ref_num             IN p1_external_request.id_external_request%TYPE DEFAULT NULL,
        o_new_id_sched        OUT schedule.id_schedule%TYPE,
        o_warning             OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a schedule.
    * 
    * @param  i_lang                          Language identification
    * @param  i_prof                          Professional identification
    * @param  i_id_schedule                   Schedule identifier
    * @param  i_id_sch_cancel_reason          Cancelation reason id
    * @param  i_cancel_notes                  Cancelation notes   
    * @param  o_warning                       Warning message.
    * @param  o_error                         Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Sofia Mendes
    * @version 2.5.0.7.4.1
    * @since  2010/02/05
    */
    FUNCTION cancel_schedule_exam
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_sch_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_warning              OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------------------------------------------------------

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    /* Error message */
    g_error VARCHAR2(4000);

    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    /* Urgent vacancy */
    g_vacancy_flg_urgent CONSTANT VARCHAR2(1) := 'U';
    /* Routine vacancy */
    g_vacancy_flg_routine CONSTANT VARCHAR2(1) := 'R';
    /* Unplanned vacancy */
    g_vacancy_flg_unplanned CONSTANT VARCHAR2(1) := 'V';
    /* Cancelled appointment */
    g_sch_status_cancelled CONSTANT VARCHAR2(1) := 'C';
    /* Scheduled appointment */
    g_sch_status_scheduled CONSTANT VARCHAR2(1) := 'A';
    /* First consult */
    g_first_subs_flg_first CONSTANT VARCHAR2(1) := 'F';
    /* Subsequent consult */
    g_first_subs_flg_subs CONSTANT VARCHAR2(1) := 'S';
    /* Other events */
    g_first_subs_flg_other CONSTANT VARCHAR2(1) := 'O';
    /* Referral consults */
    g_first_subs_flg_referral CONSTANT VARCHAR2(1) := 'R';
    /* Ignore existing cancelled schedules on creation. */
    g_flg_ignore_cancel_yes CONSTANT VARCHAR2(1) := g_yes;
    /* Do not ignore existing cancelled schedules on creation. */
    g_flg_ignore_cancel_no CONSTANT VARCHAR2(1) := g_no;
    /* Active absence record */
    g_absence_flg_status_active CONSTANT VARCHAR2(1) := 'A';
    /* Inactive absence record */
    g_absence_flg_status_inactive CONSTANT VARCHAR2(1) := 'I';

    /* ALERT Outpatient software id */
    g_outpatient_software CONSTANT NUMBER := 1;

    g_data_gov_e EXCEPTION;

END pk_schedule_interface;
/
