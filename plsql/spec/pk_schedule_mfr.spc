/*-- Last Change Revision: $Rev: 2028957 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_mfr IS
    -- This package provides the MFR scheduling logic for ALERT Scheduler.
    -- @author Jose Antunes
    -- @version alpha

    ------------------------------ PUBLIC FUNCTIONS ---------------------------
    /*
    * Checks if mfr scheduler is available to this institution.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param o_exists             True if available, false otherwise.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     21-11-2008
    */
    /*
        FUNCTION exist_mfr_scheduler
        (
            i_lang   IN LANGUAGE.id_language%TYPE,
            i_prof   IN profissional,
            o_exists OUT BOOLEAN,
            o_error out t_error_out
        ) RETURN BOOLEAN;
    */

    /*
    * returns value of base clinical service
    *
    * @param i_prof               Professional.
    * @param o_exists             True if available, false otherwise.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     21-11-2008
    *
    * UPDATE: DEPRECATED 
    */
    FUNCTION get_base_clin_serv(i_prof IN profissional) RETURN NUMBER;

    /*
    * get list of dep_clin_servs that are under the base clinical service
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_base_dcs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get list of dep_clin_servs that are under the base clinical service AND that are connected to the professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_prof_base_dcs
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * same as get_prof_base_dcs but returns only the primary key id_dep_clin_serv
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_id_dcs             output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_base_id_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_id_dcs OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get list of dep_clin_servs that are under the base clinical service 
    * AND are connected to the professional
    * AND said professional has permission to schedule in such dep_clin_serv
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional
    * @param o_dcs                output list
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     24-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_prof_base_dcs_perm
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_schedule IN VARCHAR2,
        o_dcs          OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get list of physiatry areas that are under the base clinical service 
    * AND are connected to the professional. 
    *
    * @param i_lang                Language identifier
    * @param i_prof                Professional using the scheduler 
    * @param i_id_interv_presc_det if not null means the scheduler is being part of an intervention prescription workflow
    * @param i_deps                List of departments to restrain the output
    * @param i_flg_search          Whether or not should the 'All' option be included
    * @param o_error               Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author   Telmo
    * @version  2.4.3.x
    * @date     25-11-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_physiatry_areas
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_deps                IN VARCHAR2,
        i_flg_search          IN VARCHAR2,
        o_physareas           OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of professionals on whose schedules the logged professional has permission to read or schedule. 
    * Este get_professionals especifico da agenda mfr e' identificado pelo evento e pela inexistencia de dcs fornecidos como parametro.
    * Os dcs considerados sao todos os que pertencem ao 
    * clinical service configurado na sys_config com a chave MFR_CLIN_SERV. Esses dcs sao obtidos com a pk_schedule_mfr.get_base_dcs
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional identifier.
    * @param i_id_dep           Department identifier.
    * @param i_id_clin_serv     Department-Clinical service identifier.
    * @param i_id_event         Event identifier.
    * @param i_flg_schedule     Whether or not should the events be filtered considering the professional's permission to schedule
    * @param i_phys_areas       list of physiatry areas that will also filter the professionals
    * @param o_professionals    List of processionals.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    *
    * @author  Telmo Castro
    * @date    25-11-2008
    * @version 2.4.3.x    
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        i_phys_areas    IN VARCHAR2,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /* In here only for test purposes */
    FUNCTION get_vacancies
    (
        i_lang    IN language.id_language%TYPE DEFAULT NULL,
        i_prof    IN profissional,
        i_args    IN table_varchar,
        i_wizmode IN VARCHAR2 DEFAULT 'N',
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /* In here only for test purposes */
    FUNCTION get_schedules
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_varchar,
        i_wizmode    IN VARCHAR2 DEFAULT 'N',
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function returns the availability for each day on a given period.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                Arguments.
    * @param i_id_patient          Patient.
    * @param i_semester            Whether or not this function is being called to fill the semester calendar.
    * @param i_wizmode             wizard mode. Means that i_prof is solving conflicts in a mfr prescription. So temporary 
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date
    * @param o_days_sched          List of total schedules per date.
    * @param o_days_conflicts      List of total conflicting appointments per date.
    * @param o_days_tempor         List of flags per date indicating the existence of temporary schedules
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     02-12-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability
    (
        i_lang           IN language.id_language%TYPE DEFAULT NULL,
        i_prof           IN profissional,
        i_args           IN table_varchar,
        i_id_patient     IN patient.id_patient%TYPE,
        i_wizmode        IN VARCHAR2 DEFAULT 'N',
        i_semester       IN VARCHAR2,
        o_days_status    OUT table_varchar,
        o_days_date      OUT table_varchar,
        o_days_free      OUT table_number,
        o_days_sched     OUT table_number,
        o_days_conflicts OUT table_number,
        o_days_tempor    OUT table_varchar,
        o_patient_icons  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedules, vacancies and patient icons for the daily view. Based on the function with the same name from pk_schedule_exam
    * 
    * @param i_lang            Language identifier.
    * @param i_prof            Professional.
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param i_wizmode         wizard mode. Means that i_prof is solving conflicts in a mfr prescription. So temporary 
    * @param o_vacants         Vacancies.
    * @param o_schedule        Schedules.
    * @param o_patient_icons   Patient icons.
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo Castro
    * @date    05-12-2008
    * @version 2.4.3.x
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_hourly_detail
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_args IN table_varchar,
        --        i_id_patient    IN sch_group.id_patient%TYPE,
        i_wizmode   IN VARCHAR2 DEFAULT 'N',
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        --        o_patient_icons OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the estimated duration for a intervention in minutes.
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional.
    * @param   i_id_interv                  Intervention ID
    * @param   o_duration                   Estimated duration of the intervention in minutes
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.3.x
    * @since 2008/11/21
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_interv_time
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_interv IN intervention_times.id_intervention%TYPE,
        o_duration  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates mfr schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is doing the scheduling
    * @param i_id_patient         Patient id
    * @param i_id_dep_clin_serv   If null, it will be calculated inside based on configuration
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_schedule_notes     Notes
    * @param i_id_lang_translator Translator's language
    * @param i_id_lang_preferred  Preferred language
    * @param i_id_reason          Appointment reason
    * @param i_id_origin          Patient origin
    * @param i_id_room            Room
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_id_episode         Episode id
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_id_interv_presc_det prescription id
    * @param i_id_sch_recursion   recursion id. Its the id of the recursion plan generated previously based on user choices
    * @param i_id_phys_area       physiatry area id
    * @param i_wizmode            Y= wizard mode means that schedules created in this mode must be temporary. N= standard mode
    * @param i_id_slot            slot id or null. If not null then its normal scheduling or unplanned. If null then its a fora do horario normal.
                                  Must be a permanent slot. 
    * @param o_id_schedule        Newly generated schedule id 
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     19-12-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        i_id_sch_event        IN schedule.id_sch_event%TYPE,
        i_id_prof             IN sch_resource.id_professional%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes      IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason           IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin           IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room             IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes        IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE,
        i_id_sch_recursion    IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        i_id_phys_area        IN schedule_intervention.id_physiatry_area%TYPE,
        i_wizmode             IN VARCHAR2 DEFAULT 'N',
        i_id_slot             IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        --        i_do_overlap          IN VARCHAR2,
        --        i_sch_option          IN VARCHAR2,
        i_id_complaint IN complaint.id_complaint%TYPE DEFAULT NULL,
        o_id_schedule  OUT schedule.id_schedule%TYPE,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
     * reschedule a session, whether its permanent or temporary. 
     * this operation allows changes in the begin/end dates and target professional. 
     * If permanent, the current schedule is cancelled and a new one created. Column id_schedule_ref in the new 
     * record retains link to ancient schedule.
     * If temporary, the old schedule is deleted and a new one created. Also temporary.
     *
     * @param i_lang                   Language identifier
     * @param i_prof                   Professional who is rescheduling
     * @param i_old_id_schedule        Identifier of the appointment to be rescheduled
     * @param i_id_prof                new target professional
     * @param i_dt_begin               new start date
     * @param i_dt_end                 new end date
     * @param i_wizmode                Y= wizard mode  N= standard mode
     * @param i_id_slot                slot id of the new home for this schedule, if one was picked
     * @param o_id_schedule            Identifier of the new schedule.
     * @param o_flg_show               Set to 'Y' if there is a message to show.
     * @param o_msg                    Message body.
     * @param o_msg_title              Message title.
     * @param o_button                 Buttons to show.
     * @param o_error                  Error message if something goes wrong
     *
     * @return   TRUE if process is ok, FALSE otherwise
     *
     * @author  Telmo
     * @date     06-01-2009
     * @version 2.4.3.x
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_wizmode         IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a MFR schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be canceled
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes
    * @param o_error              Error message if something goes wrong
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.3.x
    * @since 2009/01/09
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        --  i_transaction_id   IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancel a set of MFR schedule.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_interv_presc_det          Intervention identifier
    * @param i_id_cancel_reason             Cancel reason
    * @param i_cancel_notes                 Cancel notes
    * @param o_error                        Error message if something goes wrong
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.3.x
    * @since 2008/11/28
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION cancel_schedules
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_id_cancel_reason    IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes        IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * locate vacancies (not slots) that intersect dt_begin and/or dt_end.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is doing the scheduling
    * @param i_id_sch_event       Event type
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_id_phys_area       physiatry area
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     21-12-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_suitable_vacancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN sch_consult_vacancy.id_sch_event%TYPE,
        i_dt_begin     IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_dt_end       IN sch_consult_vacancy.dt_end_tstz%TYPE,
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE,
        o_ids_vac      OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on schedule table
    *
    * @param [all schedule table fields]
    * @param id_schedule_out                 output parameter - new inserted id_schedule
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_schedule
    (
        i_lang                    IN language.id_language%TYPE,
        id_schedule_in            IN schedule.id_schedule%TYPE DEFAULT NULL,
        id_instit_requests_in     IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        id_instit_requested_in    IN schedule.id_instit_requested%TYPE DEFAULT NULL,
        id_dcs_requests_in        IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        id_dcs_requested_in       IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        id_prof_requests_in       IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        id_prof_schedules_in      IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        flg_status_in             IN schedule.flg_status%TYPE DEFAULT NULL,
        id_prof_cancel_in         IN schedule.id_prof_cancel%TYPE DEFAULT NULL,
        schedule_notes_in         IN schedule.schedule_notes%TYPE DEFAULT NULL,
        id_cancel_reason_in       IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_lang_translator_in     IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        id_lang_preferred_in      IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        id_sch_event_in           IN schedule.id_sch_event%TYPE DEFAULT NULL,
        id_reason_in              IN schedule.id_reason%TYPE DEFAULT NULL,
        id_origin_in              IN schedule.id_origin%TYPE DEFAULT NULL,
        id_room_in                IN schedule.id_room%TYPE DEFAULT NULL,
        flg_urgency_in            IN schedule.flg_urgency%TYPE DEFAULT NULL,
        schedule_cancel_notes_in  IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        flg_notification_in       IN schedule.flg_notification%TYPE DEFAULT NULL,
        id_schedule_ref_in        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        flg_vacancy_in            IN schedule.flg_vacancy%TYPE DEFAULT NULL,
        flg_sch_type_in           IN schedule.flg_sch_type%TYPE DEFAULT NULL,
        reason_notes_in           IN schedule.reason_notes%TYPE DEFAULT NULL,
        dt_begin_tstz_in          IN schedule.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_in         IN schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in            IN schedule.dt_end_tstz%TYPE DEFAULT NULL,
        dt_request_tstz_in        IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        dt_schedule_tstz_in       IN schedule.dt_schedule_tstz%TYPE DEFAULT NULL,
        id_complaint_in           IN schedule.id_reason%TYPE DEFAULT NULL,
        flg_instructions_in       IN schedule.flg_instructions%TYPE DEFAULT NULL,
        flg_schedule_via_in       IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        id_prof_notification_in   IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        dt_notification_tstz_in   IN schedule.dt_notification_tstz%TYPE DEFAULT NULL,
        flg_notification_via_in   IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in IN schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        flg_request_type_in       IN schedule.flg_request_type%TYPE DEFAULT NULL,
        id_episode_in             IN schedule.id_episode%TYPE DEFAULT NULL,
        id_schedule_recursion_in  IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        id_schedule_out           OUT schedule.id_schedule%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - update one row on schedule table by primary key
    *
    * @param id_schedule_in                  schedule ID
    * @param [all schedule table fields]     [new values for update]
    * @param [all schedule table fields]_nin boolean flag to accept null values
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_schedule
    (
        i_lang                     IN language.id_language%TYPE,
        id_schedule_in             IN schedule.id_schedule%TYPE DEFAULT NULL,
        id_instit_requests_in      IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        id_instit_requests_nin     IN BOOLEAN := TRUE,
        id_instit_requested_in     IN schedule.id_instit_requested%TYPE DEFAULT NULL,
        id_instit_requested_nin    IN BOOLEAN := TRUE,
        id_dcs_requests_in         IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        id_dcs_requests_nin        IN BOOLEAN := TRUE,
        id_dcs_requested_in        IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        id_dcs_requested_nin       IN BOOLEAN := TRUE,
        id_prof_requests_in        IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        id_prof_requests_nin       IN BOOLEAN := TRUE,
        id_prof_schedules_in       IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        id_prof_schedules_nin      IN BOOLEAN := TRUE,
        flg_status_in              IN schedule.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_prof_cancel_in          IN schedule.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin         IN BOOLEAN := TRUE,
        schedule_notes_in          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        schedule_notes_nin         IN BOOLEAN := TRUE,
        id_cancel_reason_in        IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        id_cancel_reason_nin       IN BOOLEAN := TRUE,
        id_lang_translator_in      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        id_lang_translator_nin     IN BOOLEAN := TRUE,
        id_lang_preferred_in       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        id_lang_preferred_nin      IN BOOLEAN := TRUE,
        id_sch_event_in            IN schedule.id_sch_event%TYPE DEFAULT NULL,
        id_sch_event_nin           IN BOOLEAN := TRUE,
        id_reason_in               IN schedule.id_reason%TYPE DEFAULT NULL,
        id_reason_nin              IN BOOLEAN := TRUE,
        id_origin_in               IN schedule.id_origin%TYPE DEFAULT NULL,
        id_origin_nin              IN BOOLEAN := TRUE,
        id_room_in                 IN schedule.id_room%TYPE DEFAULT NULL,
        id_room_nin                IN BOOLEAN := TRUE,
        flg_urgency_in             IN schedule.flg_urgency%TYPE DEFAULT NULL,
        flg_urgency_nin            IN BOOLEAN := TRUE,
        schedule_cancel_notes_in   IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        schedule_cancel_notes_nin  IN BOOLEAN := TRUE,
        flg_notification_in        IN schedule.flg_notification%TYPE DEFAULT NULL,
        flg_notification_nin       IN BOOLEAN := TRUE,
        id_schedule_ref_in         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        id_schedule_ref_nin        IN BOOLEAN := TRUE,
        flg_vacancy_in             IN schedule.flg_vacancy%TYPE DEFAULT NULL,
        flg_vacancy_nin            IN BOOLEAN := TRUE,
        flg_sch_type_in            IN schedule.flg_sch_type%TYPE DEFAULT NULL,
        flg_sch_type_nin           IN BOOLEAN := TRUE,
        reason_notes_in            IN schedule.reason_notes%TYPE DEFAULT NULL,
        reason_notes_nin           IN BOOLEAN := TRUE,
        dt_begin_tstz_in           IN schedule.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin          IN BOOLEAN := TRUE,
        dt_cancel_tstz_in          IN schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin         IN BOOLEAN := TRUE,
        dt_end_tstz_in             IN schedule.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin            IN BOOLEAN := TRUE,
        dt_request_tstz_in         IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        dt_request_tstz_nin        IN BOOLEAN := TRUE,
        dt_schedule_tstz_in        IN schedule.dt_schedule_tstz%TYPE DEFAULT NULL,
        dt_schedule_tstz_nin       IN BOOLEAN := TRUE,
        id_complaint_in            IN schedule.id_reason%TYPE DEFAULT NULL,
        id_complaint_nin           IN BOOLEAN := TRUE,
        flg_instructions_in        IN schedule.flg_instructions%TYPE DEFAULT NULL,
        flg_instructions_nin       IN BOOLEAN := TRUE,
        flg_schedule_via_in        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        flg_schedule_via_nin       IN BOOLEAN := TRUE,
        id_prof_notification_in    IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        id_prof_notification_nin   IN BOOLEAN := TRUE,
        dt_notification_tstz_in    IN schedule.dt_notification_tstz%TYPE DEFAULT NULL,
        dt_notification_tstz_nin   IN BOOLEAN := TRUE,
        flg_notification_via_in    IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        flg_notification_via_nin   IN BOOLEAN := TRUE,
        id_sch_consult_vacancy_in  IN schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_nin IN BOOLEAN := TRUE,
        flg_request_type_in        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        flg_request_type_nin       IN BOOLEAN := TRUE,
        id_episode_in              IN schedule.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        id_schedule_recursion_in   IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        id_schedule_recursion_nin  IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vac_mfr_slot table
    *
    * @param id_sch_consult_vac_mfr_in       sch_consult_vac_mfr ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_physiatry_area_in            physiatry_area ID
    * @param dt_begin_tstz_in                begin date
    * @param dt_end_tstz_in                  end date
    * @param id_professional_in              professional ID
    * @param flg_status_in                   flag status
    * @param id_prof_created_in              created by
    * @param dt_created_in                   creating date
    * @param id_sch_consult_vac_mfr_out      output parameter - new inserted id_sch_consult_vac_mfr_slot
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_sch_consult_vac_mfr_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_mfr_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_physiatry_area_in       IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE DEFAULT NULL,
        dt_begin_tstz_in           IN sch_consult_vac_mfr_slot.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in             IN sch_consult_vac_mfr_slot.dt_end_tstz%TYPE DEFAULT NULL,
        id_professional_in         IN sch_consult_vac_mfr_slot.id_professional%TYPE DEFAULT NULL,
        flg_status_in              IN sch_consult_vac_mfr_slot.flg_status%TYPE DEFAULT NULL,
        id_prof_created_in         IN sch_consult_vac_mfr_slot.id_prof_created%TYPE DEFAULT NULL,
        dt_created_in              IN sch_consult_vac_mfr_slot.dt_created%TYPE DEFAULT NULL,
        id_sch_consult_vac_mfr_out OUT sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - update one row on sch_consult_vac_mfr_slot table by primary key
    *
    * @param id_sch_consult_vac_mfr_in       sch_consult_vac_mfr ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_sch_consult_vacancy_nin      boolean flag to accept null values    
    * @param id_physiatry_area_in            physiatry_area ID
    * @param id_physiatry_area_nin           boolean flag to accept null values
    * @param dt_begin_tstz_in                begin date
    * @param dt_begin_tstz_nin               boolean flag to accept null values   
    * @param dt_end_tstz_in                  end date
    * @param dt_end_tstz_nin                 boolean flag to accept null values
    * @param id_professional_in              professional ID
    * @param id_professional_nin             boolean flag to accept null values
    * @param flg_status_in                   flag status
    * @param flg_status_nin                  boolean flag to accept null values
    * @param id_prof_created_in              created by
    * @param id_prof_created_nin             boolean flag to accept null values
    * @param dt_created_in                   creating date
    * @param dt_created_nin                  boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_sch_consult_vac_mfr_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_mfr_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_mfr_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_nin IN BOOLEAN := TRUE,
        id_physiatry_area_in       IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE DEFAULT NULL,
        id_physiatry_area_nin      IN BOOLEAN := TRUE,
        dt_begin_tstz_in           IN sch_consult_vac_mfr_slot.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin          IN BOOLEAN := TRUE,
        dt_end_tstz_in             IN sch_consult_vac_mfr_slot.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin            IN BOOLEAN := TRUE,
        id_professional_in         IN sch_consult_vac_mfr_slot.id_professional%TYPE DEFAULT NULL,
        id_professional_nin        IN BOOLEAN := TRUE,
        flg_status_in              IN sch_consult_vac_mfr_slot.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        id_prof_created_in         IN sch_consult_vac_mfr_slot.id_prof_created%TYPE DEFAULT NULL,
        id_prof_created_nin        IN BOOLEAN := TRUE,
        dt_created_in              IN sch_consult_vac_mfr_slot.dt_created%TYPE DEFAULT NULL,
        dt_created_nin             IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on schedule_recursion table
    *
    * @param id_schedule_recursion_in        sch_consult_vac_mfr ID
    * @param weekdays_in                     list with weekdays, separated by global constant separator
    * @param flg_regular_in                  regular / irregular cycles flag: Y-Yes / N-No
    * @param flg_timeunit_in                 time unit: S-Weekly /  M-Monthly
    * @param num_take_in                     number of takes per session                     
    * @param num_freq_in                     frequency of sessions
    * @param id_interv_presc_det_in          intervention detail ID
    * @param id_schedule_recursion_out       output parameter - new inserted id_schedule_recursion
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_schedule_recursion
    (
        i_lang                    IN language.id_language%TYPE,
        id_schedule_recursion_in  IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        weekdays_in               IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        flg_regular_in            IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        flg_timeunit_in           IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        num_take_in               IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        num_freq_in               IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        id_interv_presc_det_in    IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        id_schedule_recursion_out OUT schedule_recursion.id_schedule_recursion%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - update one row on schedule_recursion table by primary key
    *
    * @param id_schedule_recursion_in        id_schedule_recursion ID
    * @param weekdays_in                     list with weekdays, separated by global constant separator
    * @param weekdays_nin                    boolean flag to accept null values
    * @param flg_regular_in                  regular / irregular cycles flag: Y-Yes / N-No
    * @param flg_regular_nin                 boolean flag to accept null values
    * @param flg_timeunit_in                 time unit: S-Weekly /  M-Monthly
    * @param flg_timeunit_nin                boolean flag to accept null values
    * @param num_take_in                     number of takes
    * @param num_take_nin                    boolean flag to accept null values
    * @param num_freq_in                     frequency
    * @param num_freq_nin                    boolean flag to accept null values
    * @param id_interv_presc_det_in          intervention detail ID
    * @param id_interv_presc_det_nin         boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION upd_schedule_recursion
    (
        i_lang                   IN language.id_language%TYPE,
        id_schedule_recursion_in IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        weekdays_in              IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        weekdays_nin             IN BOOLEAN := TRUE,
        flg_regular_in           IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        flg_regular_nin          IN BOOLEAN := TRUE,
        flg_timeunit_in          IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        flg_timeunit_nin         IN BOOLEAN := TRUE,
        num_take_in              IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        num_take_nin             IN BOOLEAN := TRUE,
        num_freq_in              IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        num_freq_nin             IN BOOLEAN := TRUE,
        id_interv_presc_det_in   IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        id_interv_presc_det_nin  IN BOOLEAN := TRUE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on schedule_intervention table
    *
    * @param id_schedule_intervention_in     schedule_intervention ID
    * @param id_schedule_in                  schedule ID
    * @param id_interv_presc_det_in          interv_presc_det ID
    * @param id_prof_assigned_in             professional assigned ID
    * @param flg_state_in                    state
    * @param rank_in                         rank       
    * @param id_physiatry_area_in            physiatry area ID
    * @param o_error                         descripton error
    * @param id_schedule_intervention_out    output parameter - new inserted id_schedule_intervention
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    **********************************************************************************************/
    FUNCTION ins_schedule_intervention
    (
        i_lang                       IN language.id_language%TYPE,
        id_schedule_intervention_in  IN schedule_intervention.id_schedule_intervention%TYPE DEFAULT NULL,
        id_schedule_in               IN schedule_intervention.id_schedule%TYPE DEFAULT NULL,
        id_interv_presc_det_in       IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        id_prof_assigned_in          IN schedule_intervention.id_prof_assigned%TYPE DEFAULT NULL,
        flg_state_in                 IN schedule_intervention.flg_state%TYPE DEFAULT NULL,
        rank_in                      IN schedule_intervention.rank%TYPE DEFAULT NULL,
        id_physiatry_area_in         IN schedule_intervention.id_physiatry_area%TYPE DEFAULT NULL,
        flg_original_in              IN schedule_intervention.flg_original%TYPE DEFAULT NULL,
        id_schedule_intervention_out OUT schedule_intervention.id_schedule_intervention%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - udapete one row on schedule_intervention table by primary key
    *
    * @param id_schedule_intervention_in     schedule_intervention ID
    * @param id_schedule_in                  schedule ID
    * @param id_schedule_nin                 boolean flag to accept null values   
    * @param id_interv_presc_det_in          interv_presc_det ID
    * @param id_interv_presc_det_nin         boolean flag to accept null values
    * @param id_prof_assigned_in             professional assigned ID
    * @param id_prof_assigned_nin            boolean flag to accept null values
    * @param flg_state_in                    state
    * @param flg_state_nin                   boolean flag to accept null values
    * @param rank_in                         rank       
    * @param rank_nin                        boolean flag to accept null values
    * @param id_physiatry_area_in            physiatry area ID
    * @param id_physiatry_area_nin           boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    **********************************************************************************************/
    FUNCTION upd_schedule_intervention
    (
        i_lang                      IN language.id_language%TYPE,
        id_schedule_intervention_in IN schedule_intervention.id_schedule_intervention%TYPE DEFAULT NULL,
        id_schedule_in              IN schedule_intervention.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin             IN BOOLEAN := TRUE,
        id_interv_presc_det_in      IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        id_interv_presc_det_nin     IN BOOLEAN := TRUE,
        id_prof_assigned_in         IN schedule_intervention.id_prof_assigned%TYPE DEFAULT NULL,
        id_prof_assigned_nin        IN BOOLEAN := TRUE,
        flg_state_in                IN schedule_intervention.flg_state%TYPE DEFAULT NULL,
        flg_state_nin               IN BOOLEAN := TRUE,
        rank_in                     IN schedule_intervention.rank%TYPE DEFAULT NULL,
        rank_nin                    IN BOOLEAN := TRUE,
        id_physiatry_area_in        IN schedule_intervention.id_physiatry_area%TYPE DEFAULT NULL,
        id_physiatry_area_nin       IN BOOLEAN := TRUE,
        flg_original_in             IN schedule_intervention.flg_original%TYPE DEFAULT NULL,
        flg_original_nin            IN BOOLEAN := TRUE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vacancy table
    *
    * @param id_sch_consult_vacancy_in       consult_vacancy ID
    * @param dt_sch_consult_vacancy_in       consult_vacancy date - TSTZ
    * @param id_institution_in               institution ID
    * @param id_prof_in                      professional ID
    * @param dt_begin_in                     begin date
    * @param max_vacancies_in                max vacancies
    * @param used_vacancies_in               used vacancies
    * @param dt_end_in                       end date
    * @param id_dep_clin_serv_in             department/clinical service ID
    * @param id_room_in                      room ID                
    * @param id_sch_event_in                 schedule event ID
    * @param dt_begin_tstz_in                begin date - TSTZ
    * @param dt_end_tstz_in                  end date - TSTZ
    * @param dt_sch_consult_vacancy_tstz_in  consult_vacancy date - TSTZ
    * @param id_sch_consult_vacancy_out      output parameter - new inserted id_sch_consult_vacancy
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.4.3
    * @since                                 2008/11/25
    * @alteration                            JM 2009/03/10 Exception handling refactoring
    **********************************************************************************************/
    FUNCTION ins_sch_consult_vacancy
    (
        i_lang                         IN language.id_language%TYPE,
        id_sch_consult_vacancy_in      IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_institution_in              IN sch_consult_vacancy.id_institution%TYPE DEFAULT NULL,
        id_prof_in                     IN sch_consult_vacancy.id_prof%TYPE DEFAULT NULL,
        max_vacancies_in               IN sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL,
        used_vacancies_in              IN sch_consult_vacancy.used_vacancies%TYPE DEFAULT NULL,
        id_dep_clin_serv_in            IN sch_consult_vacancy.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_room_in                     IN sch_consult_vacancy.id_room%TYPE DEFAULT NULL,
        id_sch_event_in                IN sch_consult_vacancy.id_sch_event%TYPE DEFAULT NULL,
        dt_begin_tstz_in               IN sch_consult_vacancy.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_in                 IN sch_consult_vacancy.dt_end_tstz%TYPE DEFAULT NULL,
        dt_sch_consult_vacancy_tstz_in IN sch_consult_vacancy.dt_sch_consult_vacancy_tstz%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_out     OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * API - update one row on sch_consult_vacancy table by primary key
    *
    * @param id_sch_consult_vacancy_in       consult_vacancy ID
    * @param id_institution_in               institution ID
    * @param id_institution_nin              boolean flag to accept null values   
    * @param id_prof_in                      professional ID
    * @param id_prof_nin                     boolean flag to accept null values   
    * @param max_vacancies_in                max vacancies
    * @param max_vacancies_nin               boolean flag to accept null values   
    * @param used_vacancies_in               used vacancies
    * @param used_vacancies_nin              boolean flag to accept null values   
    * @param id_dep_clin_serv_in             department/clinical service ID
    * @param id_dep_clin_serv_nin            boolean flag to accept null values   
    * @param id_room_in                      room ID                
    * @param id_room_nin                     boolean flag to accept null values   
    * @param id_sch_event_in                 schedule event ID
    * @param id_sch_event_nin                boolean flag to accept null values   
    * @param dt_begin_tstz_in                begin date - TSTZ
    * @param dt_begin_tstz_nin               boolean flag to accept null values   
    * @param dt_end_tstz_in                  end date - TSTZ
    * @param dt_end_tstz_nin                 boolean flag to accept null values   
    * @param dt_sch_consult_vacancy_tstz_in  consult_vacancy date - TSTZ
    * @param dt_sch_consult_vacancy_tstz_nin boolean flag to accept null values   
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/

    FUNCTION upd_sch_consult_vacancy
    (
        i_lang                       IN language.id_language%TYPE,
        id_sch_consult_vacancy_in    IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_institution_in            IN sch_consult_vacancy.id_institution%TYPE DEFAULT NULL,
        id_institution_nin           IN BOOLEAN := TRUE,
        id_prof_in                   IN sch_consult_vacancy.id_prof%TYPE DEFAULT NULL,
        id_prof_nin                  IN BOOLEAN := TRUE,
        max_vacancies_in             IN sch_consult_vacancy.max_vacancies%TYPE DEFAULT NULL,
        max_vacancies_nin            IN BOOLEAN := TRUE,
        used_vacancies_in            IN sch_consult_vacancy.used_vacancies%TYPE DEFAULT NULL,
        used_vacancies_nin           IN BOOLEAN := TRUE,
        id_dep_clin_serv_in          IN sch_consult_vacancy.id_dep_clin_serv%TYPE DEFAULT NULL,
        id_dep_clin_serv_nin         IN BOOLEAN := TRUE,
        id_room_in                   IN sch_consult_vacancy.id_room%TYPE DEFAULT NULL,
        id_room_nin                  IN BOOLEAN := TRUE,
        id_sch_event_in              IN sch_consult_vacancy.id_sch_event%TYPE DEFAULT NULL,
        id_sch_event_nin             IN BOOLEAN := TRUE,
        dt_begin_tstz_in             IN sch_consult_vacancy.dt_begin_tstz%TYPE DEFAULT NULL,
        dt_begin_tstz_nin            IN BOOLEAN := TRUE,
        dt_end_tstz_in               IN sch_consult_vacancy.dt_end_tstz%TYPE DEFAULT NULL,
        dt_end_tstz_nin              IN BOOLEAN := TRUE,
        dt_sch_cons_vacancy_tstz_in  IN sch_consult_vacancy.dt_sch_consult_vacancy_tstz%TYPE DEFAULT NULL,
        dt_sch_cons_vacancy_tstz_nin IN BOOLEAN := TRUE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function determine and inserts on table sch_consult_vac_mfr_slot the free slots for a
    * sch_consult_vacancy ID 
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_sch_consult_vacancy        sch_consult_vacancy ID
    * @param i_id_physiatry_area             physiatry_area ID
    * @param i_id_prof_created               professional ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Temporary slot / N-No -> Permanent slot)
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/12
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION create_slots
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_physiatry_area      IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_flg_wizard             IN VARCHAR2 DEFAULT NULL,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function close ONE MFR Session by id_schedule
    * and then re-create slots with flg_wizard parameter = N-No
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_schedule                   schedule ID
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION close_mfr_session
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function close MULTIPLE MFR Sessions, using the function <close_mfr_session> for each id_schedule on table parameter
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_tab_id_schedule               schedule ID table
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION close_mfr_sessions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get time units of schedule mechanism to fill keypad
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional
    * @param   o_time_units                 Time units
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.3.x
    * @since 2008/12/03
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_time_units
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_time_units OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets weekdays by default for a given software and institution
    *
    * @param   i_lang                       Language identifier.
    * @param   i_prof                       Professional
    * @param   i_number_days                Number of days per time unit
    * @param   i_unit                       Time unit (M - month, W - week)
    * @param   i_dt_begin                   Begin date
    * @param   o_weekdays                   Weekdays
    * @param   o_error                      Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Jose Antunes
    * @version 2.4.3.x
    * @since 2008/11/27
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_weekdays_by_default
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_number_days IN sch_reprules.num_days%TYPE,
        i_unit        IN VARCHAR2,
        i_dt_begin    IN VARCHAR2,
        o_weekdays    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create and validate a set of temporary schedules
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_prof                       Professioanl identifier 
    * @param i_id_patient                    Patient identifier
    * @param i_id_phys_area                  Physiatry area identifier
    * @param i_duration                      Duration of the intervention in minutes
    * @param i_flg_restart                   Flag if is to restart
    * @param i_num_sessions                  Number of sessions to schedule
    * @param i_weekdays                      Weekdays selected 
    * @param i_id_interv_presc_det           Prescription ID
    * @param i_freq                          Frequency selected
    * @param i_num_take                      Number of takes per session
    * @param i_time_unit                     Time unit selected
    * @param i_begin_date                    Date selected in the calendar
    * @param i_next_begin_date               Begin date of subsequent appointments
    * @param i_next_duration                 Duration of subsequent appointments
    * @param i_room                          Room ID
    * @param i_flg_vacancy                   Flag with Vacancy type: U - Urgent, V - Unplanned, R - Routine
    * @param i_notes                         Appointment notes
    * @param i_flg_schedule_via              Flag schedule via: P - Presencial, F - Fax, O - Other, S - SMS, E - Email, T - Telephone, N - Normal
    * @param i_id_reason                     Reason ID
    * @param i_reason_notes                  Free-text for the appointment reason
    * @param i_id_lang_translator            Translator's language identifier
    * @param i_id_lang_preferred             Preferred language identifier
    * @param i_flg_request_type              Flag request type (U - Utente, M - Médico, E - Enfermeiro, H -  Hospital, O - Outros)
    * @param i_id_origin                     Patient origin
    * @param i_id_complaint                  Complaint ID
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.3.x
    * @since 2008/12/11
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_sugested_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof             IN sch_consult_vacancy.id_prof%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_phys_area        IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_duration            IN NUMBER,
        i_flg_restart         IN VARCHAR2,
        i_num_sessions        IN NUMBER,
        i_weekdays            IN table_number,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_freq                IN NUMBER,
        i_num_take            IN schedule_recursion.num_take%TYPE,
        i_time_unit           IN VARCHAR2,
        i_begin_date          IN VARCHAR2,
        i_next_begin_date     IN VARCHAR2,
        i_next_duration       IN NUMBER,
        i_room                IN schedule.id_room%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_notes               IN VARCHAR2,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE,
        i_id_reason           IN schedule.id_reason%TYPE,
        i_reason_notes        IN schedule.reason_notes%TYPE,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE,
        i_id_slot             IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE DEFAULT NULL,
        i_flg_request_type    IN schedule.flg_request_type%TYPE,
        i_id_origin           IN schedule.id_origin%TYPE,
        i_id_complaint        IN schedule.id_reason%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a set of schedules associated with an id_interv_presc_det
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_phys_area                  Physiatry area identifier
    * @param i_id_interv_presc_det           Prescription ID
    * @param o_weekdays                      Weekdays of each schedule created
    * @param o_dates                         Schedules dates
    * @param o_id_schedule                   Schedules IDs
    * @param o_id_profs                      Professionals assigned to each schedule
    * @param o_nick_profs                    Professionals name assigned to each schedule
    * @param o_is_perm                       Flag indicating if schedules are temporary
    * @param o_has_conflict                  Flag indicating if schedules have conflicts
    * @param o_conf_over                     Description of overlap conflict, if exists
    * @param o_conf_no_vac                   Description of no vacancy conflict, if exists
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.3.x
    * @since 2008/12/18
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_phys_area        IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_weekdays            OUT table_varchar,
        o_dates               OUT table_varchar,
        o_id_schedule         OUT table_number,
        o_id_profs            OUT table_number,
        o_nick_profs          OUT table_varchar,
        o_is_perm             OUT table_varchar,
        o_has_conflict        OUT table_varchar,
        o_conf_over           OUT table_varchar,
        o_conf_no_vac         OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER;

    /********************************************************************************************
    * This function returns a date with next week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with next week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION next_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN DATE;

    /********************************************************************************************
    * This function returns a date with previous week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with previous week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION previous_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN DATE;

    /********************************************************************************************
    * This function determines proposed schedule dates, based on i_num_freq, i_flg_timeunit and i_tab_weekdays table
    *
    * @param i_lang                          language ID
    * @param i_id_interv_presc_det           Intervention Prescription Detail ID
    * @param i_sessions                      Number of sessions to schedule
    * @param i_num_freq                      Frequency
    * @param i_flg_timeunit                  Frequency Unit (S-Weekly ; M-Monthly)
    * @param i_tab_weekdays                  Table with weekdays (1-Monday..7-Sunday)
    * @param i_sch_date_tstz                 Schedule start date
    * @param i_flg_restart                   Re-start flag: no search back i_sch_date_tstz
    * @param o_dates                         Table of calculated dates
    * @param o_flg_regular                   Output parameter: Y-Regular Cycle; N-Irregular Cycle
    * @param o_error                         error message
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/12
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION get_sched_dates
    (
        i_lang                IN language.id_language%TYPE,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_sessions            IN NUMBER,
        i_num_freq            IN NUMBER,
        i_flg_timeunit        IN VARCHAR2,
        i_tab_weekdays        IN table_number,
        i_sch_date_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_restart         IN VARCHAR2,
        o_dates               OUT table_timestamp_tz,
        o_flg_regular         OUT schedule_recursion.flg_regular%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function validate conflits before save to database
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_profs                      scheduled professional IDs
    * @param i_id_phys_area                  physician area ID
    * @param i_tab_id_schedule               schedule IDs table
    * @param i_tab_conflit                   last conflits table: 0-No conflit; 1-No Vacancy Conflict; 2-Over Slot Conflict
    * @param o_has_changes                   flag indicate changes since last calculation 
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/22
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION validate_before_save
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_profs        IN table_number,
        i_id_phys_area    IN sch_consult_vac_mfr_slot.id_physiatry_area%TYPE,
        i_tab_id_schedule IN table_number,
        i_tab_conflict    IN table_number, -- 0-No conflit; 1-No Vacancy Conflict; 2-Over Slot Conflict
        o_has_changes     OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function deletes permanently the temporary schedules by professional ID
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_interv_presc_det           Prescription ID
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2009/01/05
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION delete_temp_schedules
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Create and validate a set of temporary and dependent schedules
    *
    * @param i_lang                          Language
    * @param i_prof                          Professional identification
    * @param i_id_interv_presc_det           Prescription ID
    * @param i_id_patient                    Patient identifier
    * @param i_num_sessions                  Number of sessions to schedule
    * @param o_error                         Error message if something goes wrong
    *
    * @return True if successful, false otherwise.  
    *
    * @author   Josï¿½ Antunes
    * @version  2.4.3.x
    * @since 2009/01/08
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_dependent_sessions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_num_sessions        IN NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function gets the total of scheduled sessions for an Intervention Detail, 
    *   and the rank for schedule ID parameter 
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Scheduled / N-No -> Temporaray)
    * @param i_id_interv_presc_det           intervention prescription ID
    * @param o_count                         number of total scheduled sessions
    * @param o_rank                          session rank for i_id_schedule parameter
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2009/01/08
    * @alteration            Joao Martins 2009/01/29 Added parameter i_id_interv_presc_det
    * @alteration            JM 2009/03/10 Exception handling refactoring
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_flg_wizard          IN VARCHAR2 DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL,
        o_count               OUT NUMBER,
        o_rank                OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Overload da get_count_and_rank para se poder usar dentro de queries
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    * @param i_flg_wizard                    wizard flag (Y-Yes -> Scheduled / N-No -> Temporaray)
    * @param i_id_interv_presc_det           intervention prescription ID
    *
    * @return                                o_rank,o_count (varchar)
    *
    * @author                Telmo
    * @version               V.2.4.3.x
    * @since                 2009/01/08
    * @alteration            Joao Martins 2009/01/29 Added parameter i_id_schedule_intervention
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang                IN language.id_language%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_flg_wizard          IN VARCHAR2 DEFAULT NULL,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  general rules: see function pk_schedule.validate_schedule
    *  specific rules: skips the rule begin date cannot be inferior to current date
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     08-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *  - physiatry area must remain the same
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param i_id_phys_area           new physiatry area. must be the same
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    *
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     08-01-2008
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_sch_event    IN schedule.id_sch_event%TYPE,
        i_id_prof         IN sch_resource.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_id_phys_area    IN schedule_intervention.id_physiatry_area%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the translation needs for use on the translators' cross-view.
    * Adapted from pk_schedule.get_translators_crossview
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_args           UI Args.
    * @param i_wizmode        Y = wizard mode.  N = standard mode. Affects the output of function get_schedules.
    * @param o_schedules      Translation needs.
    * @param o_error          Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     12-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_translators_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the availability for the cross-view.
    * Adapted from pk_schedule.get_availability_crossview
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional.
    * @param i_args         UI args.
    * @param i_wizmode      Y = wizard mode. Means that i_prof is editing some prescription's schedules, therefore temporary schedules are visible
    * @param o_vacants      Vacancies.
    * @param o_schedules    Schedules.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/28
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a patient's events that are inside a time range.
    * Adapted from pk_schedule.get_proximity_events.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_id_patient     Patient identifier.
    * @param i_dt_schedule    Selected date.
    * @param i_wizmode        Y =wizard mode
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    *
    * @author  Telmo Castro
    * @date    12-01-2009
    * @version 2.4.3.x
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_proximity_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_dt_schedule IN VARCHAR2,
        i_wizmode     IN VARCHAR2,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns data for the multiple search cross-view. 
    * Adapted from pk_schedule.get_availability. 
    *
    * @param i_lang      Language identifier.
    * @param i_prof      professional calling this
    * @param i_args      table of i_args. Each i_args is a set of search criteria
    * @param i_wizmode   Y = wizard mode
    * @param o_vacants   the resulting list of vacancies
    * @param o_schedules the resulting list of schedules
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date    13-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability_cross_mult
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_table_varchar,
        i_wizmode   IN VARCHAR2,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a professional's schedules that are inside a time range.
    * Adapted from the homonymous function in pk_schedule.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_dt_schedule    Selected date
    * @param i_args           UI search arguments
    * @param i_wizmode        Y = wizard mode. needed for the get_schedules call.
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @author     Telmo
    * @version    2.4.3.x
    * @date       14-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_proximity_schedules
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_schedule IN VARCHAR2,
        i_args        IN table_varchar,
        i_wizmode     IN VARCHAR2,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve statistics for the available and scheduled appointments
    * Adapted from pk_schedule.get_schedules_statistics.
    *
    * @param      i_lang             Professional default language
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_args             Arguments used to retrieve stats
    * @param      i_wizmode          Y= wizard mode. relevant only in the code that deals with MFR stuff
    * @param      o_vacants          Vacants information
    * @param      o_schedules        Schedule information
    * @param      o_titles           Title information
    * @param      o_flg_vancay       Vacancy flags information
    * @param      o_error            Error information if exists
    *
    * @return     boolean type       "False" on error or "True" if success
    * 
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     19-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_schedules_statistics
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        i_wizmode     IN VARCHAR2,
        o_vacants     OUT pk_types.cursor_type,
        o_schedules   OUT pk_types.cursor_type,
        o_titles      OUT pk_types.cursor_type,
        o_flg_vacancy OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function returns the availability for each day on a given period.
    * For that, it considers one or more lists of search criteria.
    * Each day can be fully scheduled, half scheduled or empty.
    * Adapted from pk_schedule original.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria matrix (each element represent a search criteria set).
    * @param i_id_patient          Patient.
    * @param i_wizmode             Y = wizard mode
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date    21-01-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_availability_mult
    (
        i_lang          IN language.id_language%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_args          IN table_table_varchar,
        i_id_patient    IN patient.id_patient%TYPE,
        i_wizmode       IN VARCHAR2,
        o_days_status   OUT table_varchar,
        o_days_date     OUT table_varchar,
        o_days_free     OUT table_number,
        o_days_sched    OUT table_number,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function tells if there is another appointment of any kind (event) that fully or partially overlaps
    * the one supplied.
    * To be used in SQL
    *
    * @param id_sched   The one being searched
    * @param id_prof    Profissional's schedules to look for
    * @param dt_begin   start date of id_sched
    * @param dt_end     end date of id_sched
    * @return           g_icon_sch_temp_ol or g_icon_sch_temp
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date     26-01-2009
    */
    FUNCTION get_schedule_conflicts
    (
        id_sched schedule.id_schedule%TYPE,
        id_prof  sch_resource.id_professional%TYPE,
        dt_begin schedule.dt_begin_tstz%TYPE,
        dt_end   schedule.dt_end_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Updates mfr schedule. To be used by flash layer in response to option 'change' inside actions button.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_old_id_schedule    The schedule id to be updated
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_schedule_notes     Notes
    * @param i_id_lang_translator Translator's language
    * @param i_id_lang_preferred  Preferred language
    * @param i_id_reason          Appointment reason
    * @param i_id_origin          Patient origin
    * @param i_id_room            Room
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_id_phys_area       new physiatry area 
    * @param i_wizmode            Y=wizard mode, N=standard mode
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     19-02-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    *
    */
    FUNCTION update_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_old_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_sch_event       IN schedule.id_sch_event%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_dt_begin           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_flg_vacancy        IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes     IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred  IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason          IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin          IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room            IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_phys_area       IN schedule_intervention.id_physiatry_area%TYPE,
        i_wizmode            IN VARCHAR2 DEFAULT 'N',
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the details of the schedules that are dragged, by dragging a full day into the clipboard
    * Adapted from homonymous function in pk_schedule
    *
    * @param i_lang       language id
    * @param i_prof       professional performing this
    * @param i_args       criteria for schedule filtering
    * @param i_wizmode    Y= wizard mode   N = standard moded
    * @param o_schedules  output
    * @param o_error
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @since   20-02-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION get_schedules_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        i_wizmode   IN VARCHAR2 DEFAULT 'N',
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reschedules several appointments.
    * Adapted from same function in pk_schedule_outp.
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_prof            Target professional.
    * @param i_schedules          List of schedules to reschedule.
    * @param i_start_dates        List of new start dates
    * @param i_end_dates          List of new end dates
    * @param i_wizmode            Y=wizard mode  N=standard mode
    * @param i_ids_slot           ids das novas slots. Podem ser null
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo
    * @version  2.4.3.x
    * @date     03-03-2009
    * @alteration JM 2009/03/10 Exception handling refactoring
    */
    FUNCTION create_mult_reschedule
    (
        i_lang        language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_prof     IN professional.id_professional%TYPE,
        i_schedules   IN table_varchar,
        i_start_dates IN table_varchar,
        i_end_dates   IN table_varchar,
        i_ids_slot    IN table_number,
        i_wizmode     IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set a new schedule notification for a set of schedules 
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional
    * @param    i_id_interv_presc_det    Interventions ID
    * @param    i_flg_notif              Notification flag
    * @param    i_flg_notif_via          Notification via flag
    * @param    o_error                  Error message if something goes wrong
    *
    * @author  Jose Antunes
    * @version  2.5
    * @date     27-03-2009
    */
    FUNCTION set_schedule_notification
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_interv_presc_det IN table_number,
        i_flg_notif           IN schedule.flg_notification%TYPE,
        i_flg_notif_via       IN schedule.flg_notification_via%TYPE,
        --   i_transaction_id      IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /* for alert v2.6
    *
    * @author                Telmo
    * @version               2.6.1
    * @since                 11-05-2011
    */
    FUNCTION get_rank_and_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    ---------------------------------- CONSTANTS ------------------------------

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    /*sys_config key to assess existence of mfr scheduler*/
    g_scheduler_mfr_available CONSTANT VARCHAR2(30) := 'SCHEDULER_MFR_AVAILABLE';

    /*BASE CLINICAL SERVICE */
    g_mfr_clin_serv CONSTANT VARCHAR2(30) := 'MFR_CLIN_SERV';

    /* values for sch_consult_vac_mfr_slot.flg_status */
    g_slot_status_permanent CONSTANT VARCHAR2(1) := 'P';
    g_slot_status_temporary CONSTANT VARCHAR2(1) := 'T';

    /* new value for schedule.flg_status */
    --    g_sched_status_temporary CONSTANT VARCHAR2(1) := pk_schedule.g_sched_status_temporary;

    /* part of i_args argument in several functions */
    --    idx_id_phys_area CONSTANT NUMBER(2) := pk_schedule.idx_id_phys_area;

    /* existencia de agendamentos temporarios e com sobreposicao */
    g_temp_sched_overlap CONSTANT VARCHAR2(1) := 'S';

    g_sep_list          CONSTANT VARCHAR2(1) := ';';
    g_flg_freq_s        CONSTANT VARCHAR2(1) := 'S';
    g_flg_freq_m        CONSTANT VARCHAR2(1) := 'M';
    g_ref_date          CONSTANT DATE := to_date('20000102', 'YYYYMMDD');
    g_weekday_begin_sch CONSTANT VARCHAR2(1) := '0';
    g_weekdays          CONSTANT NUMBER := 7;

    -- Package global variables
    g_found BOOLEAN;

    -- Minimum time interval between slots (minutes). Slots with durations below this value will not be create.
    g_sch_min_slot_interval CONSTANT sys_config.id_sys_config%TYPE := 'SCH_MIN_SLOT_INTERVAL';

    /* Message for over slot */
    g_over_slot CONSTANT VARCHAR2(8) := 'SCH_T311';
    /* Message for no vacancy */
    g_no_vacancy CONSTANT VARCHAR2(8) := 'SCH_T312';
    /* Message for weekday 1 */
    g_msg_seg CONSTANT VARCHAR2(8) := 'SCH_T314';
    /* Message for weekday 2 */
    g_msg_ter CONSTANT VARCHAR2(8) := 'SCH_T315';
    /* Message for weekday 3 */
    g_msg_qua CONSTANT VARCHAR2(8) := 'SCH_T316';
    /* Message for weekday 4 */
    g_msg_qui CONSTANT VARCHAR2(8) := 'SCH_T317';
    /* Message for weekday 5 */
    g_msg_sex CONSTANT VARCHAR2(8) := 'SCH_T318';
    /* Message for weekday 6 */
    g_msg_sab CONSTANT VARCHAR2(8) := 'SCH_T319';
    /* Message for weekday 7 */
    g_msg_dom CONSTANT VARCHAR2(8) := 'SCH_T320';
    /* Message for week */
    g_msg_week CONSTANT VARCHAR2(8) := 'SCH_T305';
    /* Message for month */
    g_msg_month CONSTANT VARCHAR2(8) := 'SCH_T306';
    /* Message to be shown when a reschedule fails due to a bad procedure slot. */
    g_sched_msg_resched_bad_proc CONSTANT VARCHAR2(8) := 'SCH_T329';
    /* Flag month */
    g_flg_month CONSTANT VARCHAR2(8) := 'M';
    /* Flag of all sessions schedules */
    g_flg_status_scheduled CONSTANT VARCHAR2(1) := 'A';
    /* Flag of partial sessions schedules */
    g_flg_status_partial CONSTANT VARCHAR2(1) := 'P';

    /* Event for PROC_MFR */
    g_mfr_event CONSTANT NUMBER := 11;
    /* Event for PROC_MFR */
    g_no_conflict CONSTANT NUMBER := 0;
    /* Event for PROC_MFR */
    g_conf_over_slot CONSTANT NUMBER := 1;
    /* Event for PROC_MFR */
    g_conf_no_vacancy CONSTANT NUMBER := 2;

    -- Icones para agendamentos temporarios, na grelha do dia. 
    -- Nota: os icones para agendamentos nao temporarios estao na sys_Domain com o code_domain = SCHEDULE.FLG_SCH_STATUS
    g_icon_sch_temp    CONSTANT VARCHAR2(25) := 'SCH_PendantRoutineIcon';
    g_icon_sch_temp_ol CONSTANT VARCHAR2(25) := 'SCH_ScheduledConflictIcon';

END pk_schedule_mfr;
/
