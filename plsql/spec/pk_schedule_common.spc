/*-- Last Change Revision: $Rev: 2028951 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_common IS
    -- This package provides functions that are common to more than one type of scheduling (exams, consults, etc)
    -- but cannot be included in the main package, as they are not to be considered for middle layer code generation.
    -- These functions are solely used by the database.
    -- @author Nuno Guerreiro
    -- @version alpha

    TYPE t_sch_hist_upd_info IS RECORD(
        update_date schedule_hist.dt_update%TYPE,
        update_user schedule_hist.id_prof_update%TYPE,
        valor       VARCHAR2(32767));

    TYPE tt_sch_hist_upd_info IS TABLE OF t_sch_hist_upd_info;

    ------------------------------------------- PUBLIC FUNCTIONS ------------------------------------------

    /**
    * Alters a record on sch_permission.
    *
    * @param i_lang                            Language identifier
    * @param i_id_consult_permission           Permission identifier.
    * @param i_id_institution                  Institution identifier.
    * @param i_id_professional                 Professional identifier.
    * @param i_id_prof_agenda                  Target professional identifier
    * @param i_id_dep_clin_serv                Department's clinical service.
    * @param i_id_sch_event                    Type of event.
    * @param i_flg_permission                  'R' - Read, 'S' Schedule
    * @param o_sch_permission_rec              The record that represents the update on sch_permission
    * @param o_error                           Error message (if an error occurred).
    * 
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/04/24
    */
    FUNCTION alter_sch_permission
    (
        i_lang                  language.id_language%TYPE,
        i_id_consult_permission sch_permission.id_consult_permission%TYPE,
        i_id_institution        sch_permission.id_institution%TYPE DEFAULT NULL,
        i_id_professional       sch_permission.id_professional%TYPE DEFAULT NULL,
        i_id_prof_agenda        sch_permission.id_prof_agenda%TYPE DEFAULT NULL,
        i_id_dep_clin_serv      sch_permission.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_sch_event          sch_permission.id_sch_event%TYPE DEFAULT NULL,
        i_flg_permission        sch_permission.flg_permission%TYPE DEFAULT NULL,
        o_sch_permission_rec    OUT sch_permission%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Alters a record on schedule.
    *
    * @param i_lang                          Language identifier.
    * @param i_id_schedule                   Schedule identifier.
    * @param i_id_instit_requests            Institution that requests the schedule.
    * @param i_id_instit_requested           Institution requested for the schedule.
    * @param i_id_dcs_requests               Department's Clinical Service (id) that requests the schedule.
    * @param i_id_dcs_requested              Department's Clinical (id) requested for the schedule.
    * @param i_id_prof_requests              Professional (id) that requests the schedule.
    * @param i_id_prof_schedules             Professional (id) assigned to the schedule.
    * @param i_notes                         Notes.
    * @param i_dt_request_tstz                 Request's date.
    * @param i_dt_schedule_tstz                Schedule's creation or cancelation date.
    * @param i_flg_status                    Schedule's status. 'A' - Agendado.
    * @param i_dt_begin_tstz                   Begin date.
    * @param i_dt_end_tstz                     End date. 
    * @param i_id_prof_cancel                Professional (id) that canceled the schedule (if so).
    * @param i_dt_cancel_tstz                  Cancelation date (if the schedule is canceled.
    * @param i_schedule_notes                Schedule notes.
    * @param i_id_cancel_reason              Cancelation reason.
    * @param i_id_lang_translator            Translator's Language identifier.
    * @param i_id_lang_preferred             Preferred Languag identifier.
    * @param i_id_sch_event                  Type of event.
    * @param i_id_reason                     Reason.
    * @param i_id_origin                     Origin.
    * @param i_id_room                       Room.
    * @param i_flg_vacancy                   Vacancy flag.
    * @param i_flg_urgency                   N No Y yes
    * @param i_schedule_cancel_notes         Cancelation notes.
    * @param i_flg_sch_type                  Type of schedule (exams, consults, etc).
    * @param i_flg_notification              Set if a notification was already sent to the patient. Possible values : 'N'otified or 'P'ending notification
    * @param i_id_schedule_ref               Schedule reference identification. It can be used to store a cancel schedule id used in the reschedule functionality.
    * @param i_id_complaint                  Complaint identifier
    * @param i_flg_instructions              Instructions for the next follow-up visit
    * @param i_id_sch_consult_vac            id da vaga 
    * @param i_id_episode                     id episodio
    * @param o_schedule_rec                  The record that represents the update on schedule.
    * @param o_error                         Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/04/24
    */
    FUNCTION alter_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_schedule           IN schedule.id_schedule%TYPE,
        i_id_instit_requests    IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_instit_requested   IN schedule.id_instit_requested%TYPE DEFAULT NULL,
        i_id_dcs_requests       IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_dcs_requested      IN schedule.id_dcs_requested%TYPE DEFAULT NULL,
        i_id_prof_requests      IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules     IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_dt_request_tstz       IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        i_dt_schedule_tstz      IN schedule.dt_schedule_tstz%TYPE DEFAULT NULL,
        i_flg_status            IN schedule.flg_status%TYPE DEFAULT NULL,
        i_dt_begin_tstz         IN schedule.dt_begin_tstz%TYPE DEFAULT NULL,
        i_dt_end_tstz           IN schedule.dt_end_tstz%TYPE DEFAULT NULL,
        i_id_prof_cancel        IN schedule.id_prof_cancel%TYPE DEFAULT NULL,
        i_dt_cancel_tstz        IN schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        i_schedule_notes        IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_cancel_reason      IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        i_id_lang_translator    IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred     IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_sch_event          IN schedule.id_sch_event%TYPE DEFAULT NULL,
        i_id_reason             IN schedule.id_reason%TYPE DEFAULT NULL,
        i_reason_notes          IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_id_origin             IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room               IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_vacancy           IN schedule.flg_vacancy%TYPE DEFAULT NULL,
        i_flg_urgency           IN schedule.flg_urgency%TYPE DEFAULT NULL,
        i_schedule_cancel_notes IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_flg_notification      IN schedule.flg_notification%TYPE DEFAULT NULL,
        i_flg_sch_type          IN schedule.flg_sch_type%TYPE DEFAULT NULL,
        i_id_schedule_ref       IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_complaint          IN NUMBER DEFAULT NULL,
        i_flg_instructions      IN schedule.flg_instructions%TYPE DEFAULT NULL,
        i_id_sch_consult_vac    IN schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_episode            IN schedule.id_episode%TYPE DEFAULT NULL,
        o_schedule_rec          OUT schedule%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if a type of schedule requires vacancies to be consumed, when creating the schedule.
    * 
    * @param i_lang                Language identifier.
    * @param i_id_institution      Institution identifier.
    * @param i_id_software         Software identifier.
    * @param i_id_dept             department id
    * @param i_flg_sch_type        Type of schedule.
    * @param o_usage               Whether or not the type of schedule requires vacancies to be consumed.
    * @param o_sched_w_vac         whether or not its allowed to schedule without vacancy
    * @param o_edit_vac            whether or not its allowed to change a vacancy assigned to a appointment
    * @param o_error               Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    */
    FUNCTION check_vacancy_usage
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_dept        IN sch_department.id_department%TYPE,
        i_flg_sch_type   IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        o_usage          OUT BOOLEAN,
        o_sched_w_vac    OUT BOOLEAN,
        o_edit_vac       OUT BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function is used to get configuration parameters.
    * It logs a warning if the configuration does not exist.
    *
    * @param i_lang            Language (just used for error messages).
    * @param i_id_sysconfig    Parameter identifier.
    * @param i_id_institution  Institution identifier.
    * @param i_id_software     Software identifier
    * @param o_config          Parameter value.
    * @param o_error           Error message (if an error occurred).
    *
    * @return   True if successful, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/02
    */
    FUNCTION get_config
    (
        i_lang           IN language.id_language%TYPE,
        i_id_sysconfig   IN sys_config.id_sys_config%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_config         OUT sys_config.value%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if there is an interface with an external system.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param o_exists             True if the interface exists, false otherwise.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    * 
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/17
    */
    FUNCTION exist_interface
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_exists OUT BOOLEAN,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on schedule.
    * @param i_lang                          Language identifier.
    * @param i_id_schedule                   Schedule identifier.
    * @param i_id_instit_requests            Institution that requests the schedule.
    * @param i_id_instit_requested           Institution requested for the schedule.
    * @param i_id_dcs_requests               Department' s clinical service(id) that requests THE schedule. 
    * @param i_id_dcs_requested              Department's clinical service (id) requested for the schedule.
    * @param i_id_prof_requests              Professional (id) that requests the schedule.
    * @param i_id_prof_schedules             Professional (id) assigned to the schedule.
    * @param i_dt_request_tstz                 Request's date. 
    * @param i_dt_schedule_tstz                Schedule's creation or cancelation date.
    * @param i_flg_status                    Schedule' s status. 'A' - agendado. 
    * @param i_dt_begin_tstz                   Begin date. 
    * @param i_dt_end_tstz                     End date. 
    * @param i_id_prof_cancel                Professional(id) that canceled the schedule(IF so) . 
    * @param i_dt_cancel_tstz                  Cancelation date (if the schedule is canceled). 
    * @param i_schedule_notes                Schedule notes. 
    * @param i_id_cancel_reason              Cancelation reason. 
    * @param i_id_lang_translator            Translator's Language identifier.
    * @param i_id_lang_preferred             Preferred Language identifier.
    * @param i_id_sch_event                  Type of event.
    * @param i_id_reason                     Reason.
    * @param i_id_origin                     Origin.
    * @param i_flg_vacancy                   Vacancy flag.
    * @param i_id_room                       Room.
    * @param i_flg_urgency                   N No Y yes       
    * @param i_schedule_cancel_notes         Cancelation notes.
    * @param i_flg_notification              Set if a notification was already sent to the patient. Possible values : ' N'otified or ' p 'ending notification
    * @param i_flg_sch_type                  Type of schedule (exams, consults, etc).
    * @param i_id_schedule_ref               Schedule reference identification. It can be used to store a cancel schedule id used in the reschedule functionality.
    * @param i_id_complaint                  Complaint identifier
    * @param i_flg_instructions              Instructions for the next follow-up visit
    * @param i_id_sch_consult_vacancy         vacancy id. Can be null
    * @param i_id_episode                    episode id
    * @param i_id_sch_recursion               used for MFR 
    * @param o_schedule_rec                  The record that is inserted into schedule.
    * @param o_error                         Error message (if an error occurred).
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @since 2007/04/24
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo id_episode
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    13-06-2008
    */
    FUNCTION new_schedule
    (
        i_lang                   language.id_language%TYPE,
        i_id_schedule            schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_instit_requests     schedule.id_instit_requests%TYPE,
        i_id_instit_requested    schedule.id_instit_requested%TYPE,
        i_id_dcs_requests        schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_dcs_requested       schedule.id_dcs_requested%TYPE,
        i_id_prof_requests       schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules      schedule.id_prof_schedules%TYPE,
        i_dt_request_tstz        schedule.dt_request_tstz%TYPE DEFAULT NULL,
        i_dt_schedule_tstz       schedule.dt_schedule_tstz%TYPE,
        i_flg_status             schedule.flg_status%TYPE,
        i_dt_begin_tstz          schedule.dt_begin_tstz%TYPE,
        i_dt_end_tstz            schedule.dt_end_tstz%TYPE DEFAULT NULL,
        i_id_prof_cancel         schedule.id_prof_cancel%TYPE DEFAULT NULL,
        i_dt_cancel_tstz         schedule.dt_cancel_tstz%TYPE DEFAULT NULL,
        i_schedule_notes         schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_cancel_reason       schedule.id_cancel_reason%TYPE DEFAULT NULL,
        i_id_lang_translator     schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred      schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_sch_event           schedule.id_sch_event%TYPE DEFAULT NULL,
        i_id_reason              schedule.id_reason%TYPE DEFAULT NULL,
        i_reason_notes           schedule.reason_notes%TYPE DEFAULT NULL,
        i_id_origin              schedule.id_origin%TYPE DEFAULT NULL,
        i_flg_vacancy            schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_id_room                schedule.id_room%TYPE DEFAULT NULL,
        i_flg_urgency            schedule.flg_urgency%TYPE,
        i_schedule_cancel_notes  schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_flg_notification       schedule.flg_notification%TYPE,
        i_id_schedule_ref        schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_flg_sch_type           schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_complaint           NUMBER DEFAULT NULL,
        i_flg_instructions       schedule.flg_instructions%TYPE DEFAULT NULL,
        i_flg_request_type       schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via       schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_sch_consult_vacancy schedule.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_episode             consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_sch_recursion       schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        i_flg_present            IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_multidisc           IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail    IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        o_schedule_rec           OUT schedule%ROWTYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the default notification value for the given department-clinical service.
    * 
    * @param i_lang                 Language identifier.
    * @param i_id_dep_clin_serv     Department-Clinical service identifier.
    * @param o_default_value        Default value.
    * @param o_error                Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/28
    */
    FUNCTION get_notification_default
    (
        i_lang             language.id_language%TYPE,
        i_id_dep_clin_serv sch_dcs_notification.id_dep_clin_serv%TYPE,
        o_default_value    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on sch_group.
    *
    * @param i_lang               Language identifier
    * @param i_id_group           (PK) Primary Key
    * @param i_id_schedule        (FK) Schedule
    * @param i_id_patient         (FK) Patient
    * @param o_sch_group_rec      The record that is inserted into sch_group
    * @param o_error              Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/04/24
    */
    FUNCTION new_sch_group
    (
        i_lang          language.id_language%TYPE,
        i_id_group      sch_group.id_group%TYPE DEFAULT NULL,
        i_id_schedule   sch_group.id_schedule%TYPE,
        i_id_patient    sch_group.id_patient%TYPE,
        o_sch_group_rec OUT sch_group%ROWTYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on sch_permission.
    *
    * @param i_lang                            Language identifier.
    * @param i_id_consult_permission           Permission identifier.
    * @param i_id_institution                  Institution identifier.
    * @param i_id_professional                 Professional identifier.
    * @param i_id_prof_agenda                  Target professional identifier
    * @param i_id_dep_clin_serv                Department' s clinical service. 
    * @param i_id_sch_event                    Type of event. 
    * @param i_flg_permission                  'R' - READ, 'S' schedule, 'N' none
    * @param o_sch_permission_rec              The record that is inserted into sch_permission.
    * @param o_error                           Error message(if an error occurred). 
    * 
    * @return True if successful, false otherwise. 
    * 
    * @author Nuno Guerreiro
    * @version alpha 
    * @since 2007/04/24 
    */
    FUNCTION new_sch_permission
    (
        i_lang                  language.id_language%TYPE,
        i_id_consult_permission sch_permission.id_consult_permission%TYPE DEFAULT NULL,
        i_id_institution        sch_permission.id_institution%TYPE,
        i_id_professional       sch_permission.id_professional%TYPE,
        i_id_prof_agenda        sch_permission.id_prof_agenda%TYPE DEFAULT NULL,
        i_id_dep_clin_serv      sch_permission.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_sch_event          sch_permission.id_sch_event%TYPE,
        i_flg_permission        sch_permission.flg_permission%TYPE,
        o_sch_permission_rec    OUT sch_permission%ROWTYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on sch_resource.
    *
    * @param i_lang               Language identifier.
    * @param i_id_sch_resource    Schedule's resource identifier.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_institution     Institution identfier.
    * @param i_id_professional    Professional identifier.
    * @param i_dt_sch_resource_tstz Create date.
    * @param o_sch_resource_rec   The record that is inserted into sch_resource
    * @param o_error              Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/04/24
    */
    FUNCTION new_sch_resource
    (
        i_lang                   language.id_language%TYPE,
        i_id_sch_resource        sch_resource.id_sch_resource%TYPE DEFAULT NULL,
        i_id_schedule            sch_resource.id_schedule%TYPE,
        i_id_institution         sch_resource.id_institution%TYPE DEFAULT 2,
        i_id_professional        sch_resource.id_professional%TYPE DEFAULT NULL,
        i_dt_sch_resource_tstz   sch_resource.dt_sch_resource_tstz%TYPE DEFAULT current_timestamp,
        i_id_prof_leader         sch_resource.id_professional%TYPE DEFAULT NULL,
        i_id_sch_consult_vacancy sch_resource.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_sch_resource_rec       OUT sch_resource%ROWTYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Tries to occupy a vacancy.
    * 
    * @param i_lang               Language identifier.
    * @param i_id_schedule        Schedule identifier.
    * @param o_occupied           Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/31
    *
    * UPDATED 
    * o_occupied changed to number, which is the vacancy id
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     29-05-2008
    */
    FUNCTION set_vacant_occupied
    (
        i_lang        language.id_language%TYPE,
        i_id_schedule schedule.id_schedule%TYPE,
        o_occupied    OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE, --BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Tries to occupy a vacancy through the vacancy attributes
    * 
    * @param i_lang   Language identifier.
    * @param i_id_institution Institution identifier.
    * @param i_id_sch_event   Event identifier.
    * @param i_id_professional      Professional identifier.
    * @param i_id_dep_clin_serv     Department-Clinical Service.
    * @param i_dt_begin_tstz          Start date.
    * @param i_flg_sch_type         Type of schedule.
    * @param o_occupied             Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/31
    *
    * UPDATED 
    * o_occupied changed to number, which is the vacancy id
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     29-05-2008
    */
    FUNCTION set_vacant_occupied
    (
        i_lang             language.id_language%TYPE,
        i_id_institution   sch_consult_vacancy.id_institution%TYPE,
        i_id_sch_event     sch_consult_vacancy.id_sch_event%TYPE,
        i_id_professional  sch_consult_vacancy.id_prof%TYPE,
        i_id_dep_clin_serv sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz    sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_flg_sch_type     schedule.flg_sch_type%TYPE,
        o_occupied         OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE, --BOOLEAN,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Tries to occupy a vacancy through the id
    * 
    * @param i_lang           Language identifier.
    * @param i_id_vacancy     vacancy id
    * @param o_occupied       Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error          Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     13-06-2008
    */
    FUNCTION set_vacant_occupied_by_id
    (
        i_lang       language.id_language%TYPE,
        i_id_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_occupied   OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Tries to occupy a vacancy through the id - MFR version. max vacancies is ignored
    * 
    * @param i_lang           Language identifier.
    * @param i_id_vacancy     vacancy id
    * @param o_occupied       Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error          Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     21-12-2008
    */
    FUNCTION set_vacant_occupied_by_id_mfr
    (
        i_lang       language.id_language%TYPE,
        i_id_vacancy sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_occupied   OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the generic event associated with a given event on the professional's institution.
    * If no generic event is found, the event itself is returned.
    * 
    * @param i_lang            Language identifier.
    * @param i_id_institution  Institution identifier.
    * @param i_id_event        Event identifier.
    * @param o_id_event        Generic event (or self) identifier.
    * @param o_error           Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/21
    */
    FUNCTION get_generic_event
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_event       IN sch_event.id_sch_event%TYPE,
        o_id_event       OUT sch_event.id_sch_event%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an appointment.
    * 
    * @param i_lang                       Language identifier.
    * @param i_id_professional            Professional (identifier) who cancels the appointment.
    * @param i_id_software                Software identifier.
    * @param i_id_schedule                Schedule identifier.
    * @param i_id_cancel_reason           Cancel reason identifier.
    * @param i_cancel_notes               Cancel notes.
    * @param i_ignore_vacancies           Whether or not should vacancies be ignored
    * @param o_error                      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_software      IN software.id_software%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes     IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_ignore_vacancies IN BOOLEAN DEFAULT FALSE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a generic schedule (exams, consults).  
    * All other create functions should use this for core functionality.
    * Nota: mantido porque esta a ser ainda usado pelo pk_schedule_interface
    *
    * @param i_lang               Language
    * @param i_id_schedule        Schedule identifier (optional).
    * @param i_prof_schedules     Professional that created the schedule
    * @param i_id_institution     Institution identifier.
    * @param i_id_software        Software identifier.
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_flg_status         Status
    * @param i_schedule_notes     Notes.
    * @param i_id_prof_requests   Professional that requested the schedule
    * @param i_id_lang_translator Translator's language identifier.
    * @param i_id_lang_preferred  Preferred language identifier.
    * @param i_id_reason          Reason.
    * @param i_id_origin          Origin.
    * @param i_id_schedule_ref    Appointment that this appointment replaces (on reschedules).
    * @param i_id_room            Room.  
    * @param i_flg_sch_type       Type of schedule ('C' consult, 'E' exam, etc)
    * @param i_id_exam            Exam identifier (for exam appointments)
    * @param i_id_analysis        Analysis identifier (for analysis appointments)
    * @param i_reason_notes       Free-text for the appointment reason
    * @param i_id_complaint       Complaint identifier
    * @param i_flg_instructions   Instructions for the next follow-up visit
    * @param i_ignore_vacancies   Whether or not should vacancies be ignored while creating the schedule.
    * @param o_id_schedule        Identifier of the new schedule.
    * @param o_occupied           Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error              Error message if something goes wrong
    *
    * @return   True if successful, false otherwise.
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since 2007/05/21
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    */
    FUNCTION create_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_id_schedule        IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_prof_schedules  IN professional.id_professional%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_software        IN software.id_software%TYPE,
        i_id_patient         IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv   IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event       IN schedule.id_sch_event%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_dt_begin           IN schedule.dt_begin_tstz%TYPE,
        i_dt_end             IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy        IN schedule.flg_vacancy%TYPE,
        i_flg_status         IN schedule.flg_status%TYPE,
        i_schedule_notes     IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_prof_requests   IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_lang_translator IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred  IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason          IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin          IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref    IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room            IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type       IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_exam            IN exam.id_exam%TYPE DEFAULT NULL,
        i_id_analysis        IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_id_complaint       IN NUMBER DEFAULT NULL,
        i_flg_instructions   IN schedule.flg_instructions%TYPE DEFAULT NULL,
        i_ignore_vacancies   IN BOOLEAN DEFAULT FALSE,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_occupied           OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * OVERLOAD
    * Creates a generic schedule (exams, consults, analysis, etc).  
    * All other create functions should use this for core functionality.
    * This version is for version 2.4.3. Later the old version can be deleted 
    *
    * @param i_lang               Language
    * @param i_id_schedule        Schedule identifier (optional).
    * @param i_prof_schedules     Professional that created the schedule
    * @param i_id_institution     Institution identifier.
    * @param i_id_software        Software identifier.
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_flg_status         Status
    * @param i_schedule_notes     Notes.
    * @param i_id_prof_requests   Professional that requested the schedule
    * @param i_id_lang_translator Translator's language identifier.
    * @param i_id_lang_preferred  Preferred language identifier.
    * @param i_id_reason          Reason.
    * @param i_id_origin          Origin.
    * @param i_id_schedule_ref    Appointment that this appointment replaces (on reschedules).
    * @param i_id_room            Room.  
    * @param i_flg_sch_type       Type of schedule ('C' consult, 'E' exam, etc)
    * @param i_id_exam            Exam identifier (for exam appointments)
    * @param i_id_analysis        Analysis identifier (for analysis appointments)
    * @param i_reason_notes       Free-text for the appointment reason
    * @param i_id_complaint       Complaint identifier
    * @param i_flg_instructions   Instructions for the next follow-up visit
    * @param i_ignore_vacancies   Whether or not should vacancies be ignored while creating the schedule.
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visits. This id relates this schedule with the combination detail line
    * @param o_id_schedule        Identifier of the new schedule.
    * @param o_occupied           Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     26-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo id_episode
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    13-06-2008
    *
    * UPDATED
    * ALERT-10162. updated call to check_vacancy_usage - new parameter i_id_dept
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * ALERT-10118. alteracoes introduzidas aqui devido ao pk_schedule_mfr.create_schedule:
    * novo parametro i_id_sch_recursion e nova funcao para incrementar o used_vacancies. A que existia comparava com o maxvacancies
    * @author  Telmo Castro
    * @date    21-12-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * checklist compliance. invocar a funcao set_first_obs
    * @author  Telmo Castro
    * @date    08-02-2009
    * @version 2.4.3.x
    *
    * UPDATED alert-8202. deixa de receber o id_exam
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_prof_schedules   IN professional.id_professional%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_patient          IN table_number,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event        IN schedule.id_sch_event%TYPE,
        i_id_prof             IN sch_resource.id_professional%TYPE,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_flg_status          IN schedule.flg_status%TYPE,
        i_schedule_notes      IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_prof_requests    IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_lang_translator  IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred   IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason           IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin           IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room             IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type        IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_analysis         IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes        IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_id_complaint        IN NUMBER DEFAULT NULL,
        i_flg_instructions    IN schedule.flg_instructions%TYPE DEFAULT NULL,
        i_ignore_vacancies    IN BOOLEAN DEFAULT FALSE,
        i_flg_request_type    IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via    IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_consult_vac      IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_sch_recursion    IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        i_id_multidisc        IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        o_id_schedule         OUT schedule.id_schedule%TYPE,
        o_occupied            OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a generic schedule for multidisciplinary appointments  
    *
    * @param i_lang               Language
    * @param i_id_schedule        Schedule identifier (optional).
    * @param i_prof_schedules     Professional that created the schedule
    * @param i_id_institution     Institution identifier.
    * @param i_id_software        Software identifier.
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type   
    * @param i_id_prof            Schedule professionals list
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag
    * @param i_flg_status         Status
    * @param i_schedule_notes     Notes.
    * @param i_id_prof_requests   Professional that requested the schedule
    * @param i_id_lang_translator Translator's language identifier.
    * @param i_id_lang_preferred  Preferred language identifier.
    * @param i_id_reason          Reason.
    * @param i_id_origin          Origin.
    * @param i_id_schedule_ref    Appointment that this appointment replaces (on reschedules).
    * @param i_id_room            Room.  
    * @param i_flg_sch_type       Type of schedule ('C' consult, 'E' exam, etc)
    * @param i_id_exam            Exam identifier (for exam appointments)
    * @param i_id_analysis        Analysis identifier (for analysis appointments)
    * @param i_reason_notes       Free-text for the appointment reason
    * @param i_id_complaint       Complaint identifier
    * @param i_flg_instructions   Instructions for the next follow-up visit
    * @param i_ignore_vacancies   Whether or not should vacancies be ignored while creating the schedule.
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visits. This id relates this schedule with the combination detail line
    * @param o_id_schedule        Identifier of the new schedule.
    * @param o_occupied           Whether or not the vacancy was occupied. If occupied, this param carries the vacancy id
    * @param o_error              Error message if something goes wrong
    *
    * @author   Nuno Miguel Ferreira
    * @version  2.5.0.4
    * @date     01-07-2009
    */
    FUNCTION create_schedule_multidisc
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_schedule             IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_prof_schedules       IN professional.id_professional%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_patient              IN table_number,
        i_id_dep_clin_serv_list   IN table_number,
        i_id_sch_event            IN schedule.id_sch_event%TYPE,
        i_id_prof_list            IN table_number,
        i_dt_begin                IN schedule.dt_begin_tstz%TYPE,
        i_dt_end                  IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy             IN schedule.flg_vacancy%TYPE,
        i_flg_status              IN schedule.flg_status%TYPE,
        i_schedule_notes          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_prof_requests        IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_lang_translator      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason               IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin               IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room                 IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type            IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_exam                 IN exam.id_exam%TYPE DEFAULT NULL,
        i_id_analysis             IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes            IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_id_complaint            IN NUMBER DEFAULT NULL,
        i_id_prof_leader          IN sch_resource.id_professional%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_leader IN schedule.id_dcs_requested%TYPE,
        i_flg_instructions        IN schedule.flg_instructions%TYPE DEFAULT NULL,
        i_ignore_vacancies        IN BOOLEAN DEFAULT FALSE,
        i_flg_request_type        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_consult_vac_list     IN table_number,
        i_id_episode              IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_sch_recursion        IN schedule.id_schedule_recursion%TYPE DEFAULT NULL,
        i_id_multidisc            IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail     IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        o_id_schedule             OUT schedule.id_schedule%TYPE,
        o_occupied                OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on consult_req.
    *
    * @param i_lang                    Language identifier
    * @param i_id_consult_req          Primary key
    * @param i_dt_consult_req_tstz     Request date
    * @param i_consult_type            Exam / Consult request type. 
    * @param i_id_clinical_service     Clinical service.
    * @param i_id_patient              Patient
    * @param i_id_instit_requests      Institution that requests the appointment
    * @param i_id_inst_requested       Institution on which the appointment will take place
    * @param i_id_episode              Episode on which this request is to be created
    * @param i_id_prof_req             Professional that creates the request
    * @param i_id_prof_auth 
    * @param i_id_prof_appr 
    * @param i_id_prof_proc 
    * @param i_id_schedule             Schedule
    * @param i_dt_scheduled_tstz         Appointment date
    * @param i_notes                   Request notes
    * @param i_id_prof_cancel          Professional that cancelled the request
    * @param i_dt_cancel_tstz            Date on which the request was cancelled 
    * @param i_notes_cancel            Cancel notes
    * @param i_id_dep_clin_serv        Department-clinical service
    * @param i_id_prof_requested       Requested professional
    * @param i_flg_status              Status
    * @param i_next_visit_in_notes     "Next visit in" notes
    * @param i_notes_admin             Administrative notes
    * @param i_flg_instructions        Instructions flag
    * @param i_id_complaint            Complaint (reason for visit)
    * @param o_consult_req_rec         The record that is inserted into consult_req
    * @param o_error                   Error message (if an error occurred).
    * @return True if successful, false otherwise.
    *
    * @author Tiago Ferreira
    * @version alpha
    * @since 2007/05/17
    */
    FUNCTION new_consult_req
    (
        i_lang                language.id_language%TYPE DEFAULT NULL,
        i_id_consult_req      consult_req.id_consult_req%TYPE DEFAULT NULL,
        i_dt_consult_req_tstz consult_req.dt_consult_req_tstz%TYPE,
        i_consult_type        consult_req.consult_type%TYPE DEFAULT NULL,
        i_id_clinical_service consult_req.id_clinical_service%TYPE DEFAULT NULL,
        i_id_patient          consult_req.id_patient%TYPE,
        i_id_instit_requests  consult_req.id_instit_requests%TYPE,
        i_id_inst_requested   consult_req.id_inst_requested%TYPE DEFAULT NULL,
        i_id_episode          consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_prof_req         consult_req.id_prof_req%TYPE,
        i_id_prof_auth        consult_req.id_prof_auth%TYPE DEFAULT NULL,
        i_id_prof_appr        consult_req.id_prof_appr%TYPE DEFAULT NULL,
        i_id_prof_proc        consult_req.id_prof_proc%TYPE DEFAULT NULL,
        i_dt_scheduled_tstz   consult_req.dt_scheduled_tstz%TYPE DEFAULT NULL,
        i_notes               consult_req.notes%TYPE DEFAULT NULL,
        i_id_prof_cancel      consult_req.id_prof_cancel%TYPE DEFAULT NULL,
        i_dt_cancel_tstz      consult_req.dt_cancel_tstz%TYPE DEFAULT NULL,
        i_notes_cancel        consult_req.notes_cancel%TYPE DEFAULT NULL,
        i_id_dep_clin_serv    consult_req.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_prof_requested   consult_req.id_prof_requested%TYPE DEFAULT NULL,
        i_id_schedule         consult_req.id_schedule%TYPE DEFAULT NULL,
        i_flg_status          consult_req.flg_status%TYPE,
        i_notes_admin         consult_req.notes_admin%TYPE DEFAULT NULL,
        i_next_visit_in_notes consult_req.next_visit_in_notes%TYPE DEFAULT NULL,
        i_flg_instructions    consult_req.flg_instructions%TYPE DEFAULT NULL,
        i_id_complaint        consult_req.id_complaint%TYPE DEFAULT NULL,
        i_flg_type_date       consult_req.flg_type_date%TYPE DEFAULT NULL,
        o_consult_req_rec     OUT consult_req%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on consult_req_prof.
    *
    * @param i_lang                                Language identifier
    * @param i_id_consult_req_prof                 Identifier
    * @param i_dt_consult_req_prof_tstz              Record date
    * @param i_id_consult_req                      Request identifier
    * @param i_id_professional                     Professional
    * @param i_denial_justif                       Request denial justification
    * @param i_flg_status                          Status
    * @param i_dt_scheduled_tstz                     Date that is used for the appointment
    * @param o_consult_req_prof_rec                The record that is inserted into consult_req_prof
    * @param o_error                               Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Tiago Ferreira
    * @version alpha
    * @since 2007/05/17
    */
    FUNCTION new_consult_req_prof
    (
        i_lang                     language.id_language%TYPE DEFAULT NULL,
        i_id_consult_req_prof      consult_req_prof.id_consult_req_prof%TYPE DEFAULT NULL,
        i_dt_consult_req_prof_tstz consult_req_prof.dt_consult_req_prof_tstz%TYPE,
        i_id_consult_req           consult_req_prof.id_consult_req%TYPE,
        i_id_professional          consult_req_prof.id_professional%TYPE,
        i_denial_justif            consult_req_prof.denial_justif%TYPE DEFAULT NULL,
        i_flg_status               consult_req_prof.flg_status%TYPE,
        i_dt_scheduled_tstz        consult_req_prof.dt_scheduled_tstz%TYPE DEFAULT NULL,
        o_consult_req_prof_rec     OUT consult_req_prof%ROWTYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on schedule_outp.
    *
    * @param i_lang               Language identifier
    * @param i_id_schedule_outp   Identifier       
    * @param i_id_schedule        Schedule identifier
    * @param i_dt_target_tstz       Schedule date
    * @param i_flg_state          State
    * @param i_flg_sched          N - 1? enfermagem, F - subsequente enfermagem, I - internamento, S - internamento para cirurgia, V - tratamento feridas, T - administra??o medicamentos, I - informa??es   
    D - primeira m?dica; M - subsequente m?dica; P - primeira de especialidade; Q - subsequente especialidade
    * @param i_id_software        Software
    * @param i_id_epis_type       Episode type
    * @param i_flg_type           P - first, S - follow-up
    * @param i_flg_vacancy        Vacancy usage type: routine, unplanned, urgent
    * @param o_schedule_outp_rec  The record that is inserted into schedule_outp
    * @param o_error              Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    *@author  Rita Lopes
    * @version 1.1
    * @Notes: Acrescentar também os novos icones para distinguir encontros directos e indirectos, esta informacao fica
    *         gravada no campo flg_sched_type da tab schedule_outp
    * @since 2008/02/26
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    */
    FUNCTION new_schedule_outp
    (
        i_lang              language.id_language%TYPE DEFAULT NULL,
        i_id_schedule_outp  schedule_outp.id_schedule_outp%TYPE DEFAULT NULL,
        i_id_schedule       schedule_outp.id_schedule%TYPE,
        i_dt_target_tstz    schedule_outp.dt_target_tstz%TYPE DEFAULT NULL,
        i_flg_state         schedule_outp.flg_state%TYPE,
        i_flg_sched         schedule_outp.flg_sched%TYPE DEFAULT NULL,
        i_id_software       schedule_outp.id_software%TYPE,
        i_id_epis_type      schedule_outp.id_epis_type%TYPE,
        i_flg_type          schedule_outp.flg_type%TYPE DEFAULT NULL,
        i_flg_sched_type    schedule_outp.flg_sched_type%TYPE DEFAULT NULL,
        o_schedule_outp_rec OUT schedule_outp%ROWTYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on sch_prof_outp.
    *
    * @param i_lang Language identifier
    * @param i_id_sch_prof_outp 
    * @param i_id_professional 
    * @param i_id_schedule_outp 
    * @param o_sch_prof_outp_rec The record that is inserted into sch_prof_outp
    * @param o_error Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    */
    FUNCTION new_sch_prof_outp
    (
        i_lang              language.id_language%TYPE DEFAULT NULL,
        i_id_sch_prof_outp  sch_prof_outp.id_sch_prof_outp%TYPE DEFAULT NULL,
        i_id_professional   sch_prof_outp.id_professional%TYPE,
        i_id_schedule_outp  sch_prof_outp.id_schedule_outp%TYPE,
        o_sch_prof_outp_rec OUT sch_prof_outp%ROWTYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get de consult type: Direct or indirect 
    * 
    * @param i_lang                   Language identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service.
    * @param o_consult_type           Return I indirect consult, d direct consult
    * @param o_error                  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Rita Lopes
    * @version alpha
    * @since 2007/12/28
    * 
    */
    FUNCTION get_consult_type
    (
        i_lang          IN language.id_language%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;
    /*
    * Creates the outpatient specific data for a schedule or reschedule. 
    * It is shared by the both the outpatient and interface modules. 
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof_schedules         Professional (identifier) that created the schedule.
    * @param i_id_institution         Institution identifier.
    * @param i_id_software            Software identifier.
    * @param i_id_schedule            Schedule identifier.
    * @param i_id_patient             Patient identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional identifier.
    * @param i_dt_begin               Start date.
    * @param i_schedule_notes         Schedule notes.
    * @param i_id_episode             Episode identifier.
    * @param i_id_epis_type           Episode type.
    * @param i_flg_sched_type         Tipo de encontro: directo(NULL ou restantes valores) ou indirecto (S)
    * @param o_error                  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    * 
    * @author Rita Lopes
    * @version 1.0
    * @Notes: Novos icons para representar as consultas só no OUTP e CARE
    * @       Distinguir entre: Consulta programada ou do dia
    * @since  2007/12/19 
    *@author  Rita Lopes
    * @version 1.1
    * @Notes: Acrescentar também os novos icones para distinguir encontros directos e indirectos
    * @since 2008/02/26
    */
    FUNCTION create_schedule_outp
    (
        i_lang              IN language.id_language%TYPE,
        i_id_prof_schedules IN professional.id_professional%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN software.id_software%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_patient        IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv  IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event      IN schedule.id_sch_event%TYPE,
        i_id_prof           IN sch_resource.id_professional%TYPE,
        i_dt_begin          IN schedule.dt_begin_tstz%TYPE,
        i_schedule_notes    IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_episode        IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_epis_type      IN schedule_outp.id_epis_type%TYPE DEFAULT NULL,
        i_flg_sched_type    IN schedule_outp.flg_sched_type%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of vacancies that satisfy a given list of criteria.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional.
    * @param i_args       UI arguments that define the criteria.
    * @param o_vacancies  List of vacancy identifiers
    * @param o_error      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/04
    *
    * UPDATED
    * added check of sch_permission.flg_permission 
    * @author  Telmo Castro
    * @date    15-05-2008
    * @version 2.4.3
    * 
    * UPDATED
    * novo tipo de permissao na sch_permission - prof1-prof2-dcs-evento
    * @author  Telmo Castro
    * @date    16-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * added support for other exams 
    * @author  Telmo Castro 
    * @date     17-07-2008
    * @version  2.4.3   
    *
    * UPDATED
    * performance improvements - collections prefetched unto temporary table. Hints removed and whatnot
    * @author  Telmo Castro 
    * @date     19-08-2008
    * @version  2.4.3 
    *
    * UPDATED
    * corrigido o filtro por exames e o filtro por analises. Agora so' devolve vagas para os ids de exames ou analises passados
    * @author  Telmo Castro 
    * @date     30-08-2008
    * @version  2.4.3   
    */
    FUNCTION get_vacancies
    (
        i_lang  IN language.id_language%TYPE DEFAULT NULL,
        i_prof  IN profissional,
        i_args  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of schedules that satisfy a given list of criteria.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional.
    * @param i_id_patient Patient identifier.
    * @param i_args       UI arguments that define the criteria.
    * @param o_schedules  List of schedule identifiers
    * @param o_error      Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/05
    *
    * REVISED
    * where clause re-done since demise of sch_permission_dept. Now, the sched. types of a prof. are derived 
    * from prof_dep_clin_serv and dep_clin_serv
    * @author  Telmo Castro 
    * @date     22-04-2008
    * @version  2.4.3
    *
    * UPDATED
    * added support for other exams 
    * @author  Telmo Castro 
    * @date     17-08-2008
    * @version  2.4.3
    *
    * UPDATED
    * performance improvements - collections prefetched unto temporary table. Hints removed and whatnot
    * @author  Telmo Castro 
    * @date     19-08-2008
    * @version  2.4.3
    */
    FUNCTION get_schedules
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_varchar,
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedules' identifiers that match the vacancy's parameters.
    * 
    * @param i_lang                Language identifier.
    * @param i_prof                Professional identifier.
    * @param i_id_sch_vacancy      Vacancy identifier.
    * @param i_args                UI arguments.
    * @param o_schedules           Schedule identifiers
    * @param o_error               Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/08
    */
    FUNCTION get_schedules_for_vacancy
    (
        i_lang           IN language.id_language%TYPE DEFAULT NULL,
        i_prof           IN profissional,
        i_id_sch_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_args           IN table_varchar,
        o_schedules      OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of vacancies and schedules that match each one of the criteria sets,
    * and that refer to days that match all the criteria sets.
    * 
    * @param i_lang          Language identifier.
    * @param i_prof          Professional
    * @param i_id_patient    Patient (or NULL for all patients)
    * @param i_args          UI search criteria matrix
    * @param o_vacancies     List of vacancies
    * @param o_schedules     List of schedules
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/20
    *
    * UPDATED 
    * ALERT-28024 - former o_vacancies output is now in sch_tmptab_full_vacs
    * @author   Telmo
    * @date     18-06-2009
    * @version  2.5.0.4
    */
    FUNCTION get_vac_and_sch_mult
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_table_varchar,
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function is used to get translated description strings.
    *
    * @param i_lang         Language
    * @param i_select       What you want to select (e.g. '''DEPARTMENT.CODE_DEPARTMENT.1''' or 
    *  dept.code_department)
    * @param i_from         From where you want to select a description (e.g. NULL (for dual) or
    *   'department dept')
    * @param i_where        Where clause to select the record (e.g. NULL (for no clause) or
    *   'dept = 1')
    *
    * @return   Translated description
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION string_translation
    (
        i_lang   IN language.id_language%TYPE,
        i_select IN VARCHAR2,
        i_from   IN VARCHAR2 DEFAULT 'DUAL',
        i_where  IN VARCHAR2 DEFAULT '1=1'
    ) RETURN VARCHAR;

    /**
    * This function is used to get translated description strings.
    * It is used internally by most of the other string_* functions.
    *
    * @param i_lang         Language
    * @param i_select       What you want to select (e.g. '''DEPARTMENT.CODE_DEPARTMENT.1''' or 
    *  dept.code_department)
    * @param i_from         From where you want to select a description (e.g. NULL (for dual) or
    *   'department dept')
    * @param i_where        Where clause to select the record (e.g. NULL (for no clause) or
    *   'dept = 1')
    * @param o_string       First translated string found (if at least one exists).          
    * @param o_error        Error description if it exists
    *
    * @return   True if successful executed, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION string_translation
    (
        i_lang   IN language.id_language%TYPE,
        i_select IN VARCHAR2,
        i_from   IN VARCHAR2 DEFAULT 'DUAL',
        i_where  IN VARCHAR2 DEFAULT '1=1',
        o_string OUT pk_translation.t_desc_translation,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a new record on sch_absence.
    *
    * @param i_lang               Language identifier
    * @param i_id_sch_absence     Absence identifier
    * @param i_id_professional    Professional identifier
    * @param i_id_institution     Institution identifier
    * @param i_dt_begin_tstz      Absence start date
    * @param i_dt_end_tstz        Absence end date
    * @param i_desc_absence       Absence description
    * @param i_flg_type           Absence type: T training, S sick, V vacations, O other
    * @param i_flg_status         Absence status: A active, I inactive
    * @param o_sch_absence_rec    The record that is inserted into sch_absence
    * @param o_error              Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/09/04
    */
    FUNCTION new_sch_absence
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_id_sch_absence  IN sch_absence.id_sch_absence%TYPE DEFAULT NULL,
        i_id_professional IN sch_absence.id_professional%TYPE,
        i_id_institution  IN sch_absence.id_institution%TYPE,
        i_dt_begin_tstz   IN sch_absence.dt_begin_tstz%TYPE,
        i_dt_end_tstz     IN sch_absence.dt_end_tstz%TYPE,
        i_desc_absence    IN sch_absence.desc_absence%TYPE DEFAULT NULL,
        i_flg_type        IN sch_absence.flg_type%TYPE,
        i_flg_status      IN sch_absence.flg_status%TYPE,
        o_sch_absence_rec OUT sch_absence%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Alters a record on sch_absence.
    *
    * @param i_lang               Language identifier
    * @param i_id_sch_absence     Absence identifier
    * @param i_id_professional    Professional identifier
    * @param i_id_institution     Institution identifier
    * @param i_dt_begin_tstz      Absence start date
    * @param i_dt_end_tstz        Absence end date
    * @param i_desc_absence       Absence description
    * @param i_flg_type           Absence type: T training, S sick, V vacations, O other
    * @param i_flg_status         Absence status: A active, I inactive
    * @param o_sch_absence_rec    The record that represents the update on sch_absence
    * @param o_error              Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/09/04
    */
    FUNCTION alter_sch_absence
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_id_sch_absence  IN sch_absence.id_sch_absence%TYPE,
        i_id_professional IN sch_absence.id_professional%TYPE DEFAULT NULL,
        i_id_institution  IN sch_absence.id_institution%TYPE DEFAULT NULL,
        i_dt_begin_tstz   IN sch_absence.dt_begin_tstz%TYPE DEFAULT NULL,
        i_dt_end_tstz     IN sch_absence.dt_end_tstz%TYPE DEFAULT NULL,
        i_desc_absence    IN sch_absence.desc_absence%TYPE DEFAULT NULL,
        i_flg_type        IN sch_absence.flg_type%TYPE DEFAULT NULL,
        i_flg_status      IN sch_absence.flg_status%TYPE DEFAULT NULL,
        o_sch_absence_rec OUT sch_absence%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Alters a record on consult_req.
    *
    * @param i_lang Language identifier
    * @param i_id_schedule Schedule identifier
    * @param i_dt_consult_req_tstz 
    * @param i_dt_scheduled_tstz 
    * @param i_dt_cancel_tstz 
    * @param i_next_visit_in_notes Notes for indicating when will the next visit happen
    * @param i_flg_instructions Instructions for the next visit
    * @param i_id_complaint Complaint identifier
    * @param i_id_consult_req 
    * @param i_dt_consult_req Data da requisição
    * @param i_consult_type Tipo de exame / consulta requisitada. Se requisição é externa, preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço pretendido está registado na BD da instituição requisitante) ou CONSULT_TYPE (campo de texto livre).Se requisição é interna, selecciona-se não só o tipo de serviço, mas tb o departamento (DEP_CLIN_SERV).
    * @param i_id_clinical_service Tipo de exame / consulta requisitada. Se requisição é externa, preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço pretendido está registado na BD da instituição requisitante) ou CONSULT_TYPE (campo de texto livre).Se requisição é interna, selecciona-se não só o tipo de serviço, mas tb o departamento (DEP_CLIN_SERV).
    * @param i_id_patient 
    * @param i_id_instit_requests 
    * @param i_id_inst_requested 
    * @param i_id_episode Episódio em q foi requisitada a consulta
    * @param i_id_prof_req 
    * @param i_id_prof_auth 
    * @param i_id_prof_appr 
    * @param i_id_prof_proc 
    * @param i_dt_scheduled Data / hora requisitada
    * @param i_notes Notas ao médico requisitado
    * @param i_id_prof_cancel 
    * @param i_dt_cancel 
    * @param i_notes_cancel Notas de cancelamento
    * @param i_id_dep_clin_serv Tipo de exame / consulta requisitada. Se requisição é externa, preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço pretendido está registado na BD da instituição requisitante) ou CONSULT_TYPE (campo de texto livre).Se requisição é interna, selecciona-se não só o tipo de serviço, mas tb o departamento (DEP_CLIN_SERV).
    * @param i_id_prof_requested Profissional requisitado, se é uma requisição interna.
    * @param i_flg_status Estado: R - requisitado, F - pedido lido, P - respondido, A - resposta lida, C - cancelado, T - autorizado, V - aprovado, S - processado
    * @param i_notes_admin Notas ao administrativo
    * @param o_consult_req_rec The record that represents the update on consult_req
    * @param o_error Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/10/17
    */
    FUNCTION alter_consult_req
    (
        i_lang                language.id_language%TYPE,
        i_id_consult_req      consult_req.id_consult_req%TYPE,
        i_id_schedule         consult_req.id_schedule%TYPE DEFAULT NULL,
        i_dt_consult_req_tstz consult_req.dt_consult_req_tstz%TYPE DEFAULT NULL,
        i_dt_scheduled_tstz   consult_req.dt_scheduled_tstz%TYPE DEFAULT NULL,
        i_dt_cancel_tstz      consult_req.dt_cancel_tstz%TYPE DEFAULT NULL,
        i_next_visit_in_notes consult_req.next_visit_in_notes%TYPE DEFAULT NULL,
        i_flg_instructions    consult_req.flg_instructions%TYPE DEFAULT NULL,
        i_id_complaint        consult_req.id_complaint%TYPE DEFAULT NULL,
        i_consult_type        consult_req.consult_type%TYPE DEFAULT NULL,
        i_id_clinical_service consult_req.id_clinical_service%TYPE DEFAULT NULL,
        i_id_patient          consult_req.id_patient%TYPE DEFAULT NULL,
        i_id_instit_requests  consult_req.id_instit_requests%TYPE DEFAULT NULL,
        i_id_inst_requested   consult_req.id_inst_requested%TYPE DEFAULT NULL,
        i_id_episode          consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_prof_req         consult_req.id_prof_req%TYPE DEFAULT NULL,
        i_id_prof_auth        consult_req.id_prof_auth%TYPE DEFAULT NULL,
        i_id_prof_appr        consult_req.id_prof_appr%TYPE DEFAULT NULL,
        i_id_prof_proc        consult_req.id_prof_proc%TYPE DEFAULT NULL,
        i_notes               consult_req.notes%TYPE DEFAULT NULL,
        i_id_prof_cancel      consult_req.id_prof_cancel%TYPE DEFAULT NULL,
        i_notes_cancel        consult_req.notes_cancel%TYPE DEFAULT NULL,
        i_id_dep_clin_serv    consult_req.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_prof_requested   consult_req.id_prof_requested%TYPE DEFAULT NULL,
        i_flg_status          consult_req.flg_status%TYPE DEFAULT NULL,
        i_notes_admin         consult_req.notes_admin%TYPE DEFAULT NULL,
        i_flg_type_date       consult_req.flg_type_date%TYPE DEFAULT NULL,
        o_consult_req_rec     OUT consult_req%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * devolve um rowtype de uma vaga.
    * Procura pelos atributos principais de uma vaga.
    * Devolve o_vacancy nulo se nao encontrou vaga.
    *
    * @param i_lang               Language
    * @param i_id_institution     institution id
    * @param i_id_sch_event       event id
    * @param i_id_professional    professional id
    * @param i_id_dep_clin_serv   speciality id
    * @param i_dt_begin_tstz      vacancy start date
    * @param i_flg_sch_type       scheduling type
    * @param o_vacancy            output rowtype 
    * @param o_error              error message if an error occurred
    *
    * @return  boolean type       "False" on error or "True" if success
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-05-2008
    *
    * UPDATED alert-8202. deixa de receber o id_exam
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION get_vacancy_data
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN sch_consult_vacancy.id_institution%TYPE,
        i_id_sch_event       IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_professional    IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dep_clin_serv   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz      IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_flg_sch_type       IN schedule.flg_sch_type%TYPE,
        i_id_sch_consult_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_vacancy            OUT sch_consult_vacancy%ROWTYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Alters a vacancy. Updatable columns are: id_prof, id_dep_clin_serv, id_room, dt_begin_tstz, dt_end_tstz.
    * This was created as part of the implementation of the 'edit vacancy' option inside the create_schedule. 
    * Such option can arise when the user changes one or more parameters that turn the previous chosen vacancy inadequate.
    * When that happens, there are 2 ways of action. If sch_vacancy configuration says we can edit the vacancy, then that is
    * the preferred action. Otherwise, the schedule is created without a vacancy association.
    * Only unused vacancies can be changed.
    *
    * @param i_lang                          Language identifier.
    * @param i_id_sch_consult_vacancy        vacancy identifier.
    * @param i_id_prof                        new professional for this vacancy
    * @param i_id_dep_clin_serv               new dcs
    * @param i_id_room                        new room
    * @param i_dt_begin_tstz                  new start date
    * @param i_dt_end_tstz                    new end date
    * @param o_error                         Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date    12-12-2008
    */
    FUNCTION alter_vacancy
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_prof                IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dep_clin_serv       IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room                IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin_tstz          IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        i_dt_end_tstz            IN sch_consult_vacancy.dt_end_tstz%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION alter_sch_resource
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_sch_resource        IN sch_resource.id_sch_resource%TYPE,
        i_id_sch_consult_vacancy IN sch_resource.id_sch_consult_vacancy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Intersects two table_timestamp_tz lists. Estava inicialmente dentro da get_vac_and_sch_mult.
    * coloquei como funcao publica para se poder usar no pk_schedule_mfr.
    *
    * @param i_lang                          Language identifier.
    * @param i_prof                           prof data
    * @param i_table_1                        primeira lista de valores
    * @param i_table_2                        segunda lista de valores
    * @param o_table                          lista resultante
    * @param o_error                         Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date    13-01-2009
    */
    FUNCTION get_intersect_table_tz
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_table_1 IN table_timestamp_tz,
        i_table_2 IN table_timestamp_tz,
        o_table   OUT table_timestamp_tz,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get the scheduling type concerning the given event.
    *
    * @param i_lang                          Language identifier
    * @param i_prof                          prof data
    * @param i_id_sch_event                  event
    * @param o_table                         output
    * @param o_error                         Error data (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.5
    * @date    09-04-2009
    */
    FUNCTION get_dep_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN sch_event.id_sch_event%TYPE,
        o_dep_type     OUT sch_dep_type.dep_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * * Function to return professional team names for a schedule list
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_schedules                 Schedule IDs table
    * @param o_prof_list                 Output cursor with professional information
    * @param o_error                     Error object   
    *
    * @return                            Boolean - Success / fail
    *
    * @author                            Nuno Miguel Ferreira
    * @version                           2.5.0.4
    * @since                             2009/06/19
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_schedules IN table_number,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * tornada publica para ser usada pelo codigo integracionista
    */
    FUNCTION get_sch_event_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sch_event IN schedule.id_sch_event%TYPE,
        i_id_inst      IN sch_event_inst_soft.id_institution%TYPE,
        i_id_software  IN software.id_software%TYPE,
        o_epis_type    OUT epis_type.id_epis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
        returns dep_type_group for a given dep_type
        INLINE function.
    */
    FUNCTION get_dep_type_group(i_dep_type IN sch_dep_type.dep_type%TYPE) RETURN sch_dep_type.dep_type_group%TYPE;

    /* function to find if a given sch event is available (parameterized) in a institution and sofware.
    * Returns true if available and false if not.
    * INLINE FUNCTION
    * 
    * @param i_id_sch_event              sch event to be evaluated
    * @param i_id_inst                   target institution 
    * @param i_id_soft                   target software
    *
    * @return                            Y=is available; N=not available
    *
    * @author                            Telmo
    * @version                           2.6.0.3
    * @since                             06-09-2010
    */
    FUNCTION get_sch_event_avail
    (
        i_id_sch_event sch_event_inst_soft.id_sch_event%TYPE,
        i_id_inst      sch_event_inst_soft.id_institution%TYPE,
        i_id_soft      sch_event_inst_soft.id_software%TYPE
    ) RETURN VARCHAR2;

    /* given an schedule id returns its id_epis_type.
    * Bonus: also returns the schedule event dep_type.
    * 
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_id_schedule               schedule id
    * @param o_id_epis_type              intended output value
    * @param o_dep_type                  bonus output value
    * @param o_error                     Error output data
    *
    * @return                            Boolean - Success / fail
    *
    * @author                            Telmo
    * @version                           2.6.1
    * @date                              14-06-2013                             
    */
    FUNCTION get_sch_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        o_id_epis_type OUT epis_type.id_epis_type%TYPE,
        o_dep_type     OUT schedule.flg_sch_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * no-frills event dep_type getter
    *
    * @param i_id_sch_event                  event id
    *
    * @return sch_event.dep_type
    *
    * @author  Telmo
    * @version 2.6.3
    * @date    16-04-2014
    */
    FUNCTION get_dep_type(i_id_sch_event IN sch_event.id_sch_event%TYPE) RETURN sch_event.dep_type%TYPE;

    /* simple rowtype sch_event getter
    *
    * @param i_id_sch_event                  event id
    *
    * @return sch_event%rowtype
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    12-06-2014
    */
    FUNCTION get_event_data(i_id_sch_event IN sch_event.id_sch_event%TYPE) RETURN sch_event%ROWTYPE;

    /*
    * sch event translation getter. If i_try_both_sources = True, tries to get the event name from sch_event_alias, otherwise resorts to 
    * the universal translation. If false it tries to return the alias.
    * This must be used throughout the code whenever there is a event translation 
    * being fetched.
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    01-09-2014
    */
    FUNCTION get_translation_alias
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_id_sch_event     sch_event_alias.id_sch_event%TYPE,
        i_code_translation translation.code_translation%TYPE,
        i_try_both_sources BOOLEAN DEFAULT TRUE
    ) RETURN VARCHAR2;

    /*
    * Same as above, but this one returns the full record (all languages)
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    05-09-2014
    */
    FUNCTION get_translation_alias_rec
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_id_sch_event     sch_event_alias.id_sch_event%TYPE,
        i_code_translation translation.code_translation%TYPE,
        i_try_both_sources BOOLEAN DEFAULT TRUE
    ) RETURN alert_core_tech.t_rec_translation;

    /*
    * 
    */
    --    FUNCTION get_sch_event_alias

    /*
    * insert into sch_event_alias. i_alias is the event 'new' name, for language i_lang.
    * It allows to insert alias in several languages for the same event id. Just call this function for
    * every language. Or use this function's twin brother below
    *
    * @param i_lang               id_language for i_alias
    * @param i_id_sch_event       sch_event.id_sch_event value
    * @param i_id_inst            this alias is valid for this institution only, or 0 for all
    * @param i_alias              new event name
    * @param i_regen_appoints     Y = regenerate appointments based on this event. Caution: this option increases execution time
    *                             Should only be TRUE in the last call of each event 
    *    
    * @author  Telmo
    * @version 2.6.4
    * @date    02-09-2014
    */
    FUNCTION ins_sch_event_alias
    (
        i_lang           language.id_language%TYPE,
        i_id_sch_event   sch_event_alias.id_sch_event%TYPE,
        i_id_inst        sch_event_alias.id_institution%TYPE DEFAULT 0,
        i_alias          VARCHAR2,
        i_regen_appoints BOOLEAN DEFAULT FALSE
    ) RETURN BOOLEAN;

    /*
    * insert into sch_event_alias, this time for several or all languages at once.
    * parameter i_aliases is a nested table in which every index corresponds to the language id.
    * So for example index #1 is portuguese, #3 is spanish, etc.
    *
    * @param i_id_sch_event       sch_event.id_sch_event value
    * @param i_id_inst            this alias is valid for this institution only, or 0 for all
    * @param i_aliases            new event names. Each index in the nested table represents a language id. So 1 = PT, 2 = EN, 3 = ES, etc.
    * @param i_regen_appoints     true= regenerate appointments based on this event. Caution: this option increases execution time.
    *                             Should only be TRUE in the last call of each event 
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    02-09-2014
    */
    FUNCTION ins_sch_event_alias
    (
        i_id_sch_event   sch_event_alias.id_sch_event%TYPE,
        i_id_inst        sch_event_alias.id_institution%TYPE,
        i_aliases        table_varchar,
        i_regen_appoints BOOLEAN DEFAULT TRUE
    ) RETURN BOOLEAN;

    /*
    * remove an event alias. 
    * Also removes its dependencies in appointment_alias table and translations.
    */
    FUNCTION del_sch_event_alias(i_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE) RETURN BOOLEAN;

    /*
    * another version, if id_sch_event_alias is unknown
    */
    FUNCTION del_sch_event_alias
    (
        i_id_sch_event sch_event_alias.id_sch_event%TYPE,
        i_id_inst      sch_event_alias.id_institution%TYPE
    ) RETURN BOOLEAN;

    /* backup schedule table. Returns latest schedule snapshot.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*FUNCTION backup_schedule
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) RETURN schedule_hist%ROWTYPE;*/

    /*backup schedule table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /*backup sch_group table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_sch_group
    (
        i_id_sch    sch_group.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_exam table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule_exam
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_analysis table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule_analysis
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_bed table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule_bed
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_outp table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule_outp
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_resource table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_sch_resource
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup sch_rehab_group table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_sch_rehab_group
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup schedule_sr table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_schedule_sr
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup sch_prof_outp table.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    /*PROCEDURE backup_sch_prof_outp
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );*/

    /* backup all tables.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    PROCEDURE backup_all
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    );

    /* backup all tables. returns schedule table latest snapshot.
    * 
    * @param i_id_sch         schedule id to be backed up
    * @param i_dt_update      timestamp common to all backed up tables
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    FUNCTION backup_all
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) RETURN schedule_hist%ROWTYPE;

    /*  ALERT-303513. returns the schedule's professional id and date of creation
    *
    */
    /*FUNCTION get_hist_curr_info 
    ( 
       i_id_sch    schedule.id_schedule%TYPE
    ) RETURN t_sch_hist_upd_info;*/

    /*  ALERT-303513. returns the professional id and date of most recent update on a schedule.
    *
    */
    FUNCTION get_hist_last_upd_info(i_id_sch schedule.id_schedule%TYPE) RETURN t_sch_hist_upd_info;

    /*  ALERT-303513. returns the professional id and date of the last update on the specified column.
    *
    */
    FUNCTION get_hist_col_last_upd_info
    (
        i_id_sch     schedule.id_schedule%TYPE,
        i_table_name VARCHAR2,
        i_col_name   VARCHAR2
    ) RETURN t_sch_hist_upd_info;

    /*  ALERT-303513. returns the ordered list of all modifications on i_table_name.i_col_name
    *
    */
    FUNCTION get_hist_col_updates
    (
        i_id_sch     schedule.id_schedule%TYPE,
        i_table_name VARCHAR2,
        i_col_name   VARCHAR2
    ) RETURN tt_sch_hist_upd_info;

    /* ALERT-303513. Add the SCHEDULING BLOCK TO THE OUTPUT.
    * Used in functions pk_schedule_exam.get_sch_detail, pk_schedule_exam.get_sch_hist, pk_schedule_lab.get_sch_detail, pk_schedule_lab.get_sch_hist
    * 
    * @param i_lang                language to build the output
    * @param i_prof                professional id
    * @param i_pat_name            patient name
    * @param i_sch_date            schedule begin date
    * @param i_tests               scheduled tests names
    * @param i_created_date        schedule creation date
    * @param i_created_by          schedule creator
    
    * @author  Telmo
    * @version 2.6.4.3
    * @date    22-12-2014
    */
    PROCEDURE add_scheduling_block
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pat_name     IN VARCHAR2,
        i_sch_date     IN VARCHAR2,
        i_tests        IN VARCHAR2,
        i_created_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_created_by   IN NUMBER
    );

    /*
    * no-frills event dep_type getter, this time based on supplying the id_schedule
    *
    * @param i_lang                       language id
    * @param i_id_schedule                schedule id
    * @param o_dep_type                   dep type
    * @param o_error                      error data
    *
    * @return booolean
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    31-12-2014
    */
    FUNCTION get_dep_type
    (
        i_lang        IN NUMBER,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_dep_type    OUT schedule.flg_sch_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -------------------------------------------- GLOBALS -------------------------------------------

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE := current_timestamp;

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    /* Log messages for invalid record key */
    g_invalid_record_key CONSTANT VARCHAR2(30) := 'Invalid record key';

    /* Log message for missing config values. */
    g_missing_config CONSTANT VARCHAR2(30) := 'Missing sys_config value for: ';

    /* Scheduling interface configuration */
    g_scheduling_interface CONSTANT VARCHAR2(24) := 'SCH_SCHEDULING_INTERFACE';

    /* Notification status: pending */
    g_notification_status_pending VARCHAR2(1) := 'P';
    /* Notification status: notified */
    g_notification_status_notified VARCHAR2(1) := 'N';

    /* All departments, ignoring the type of schedule */
    g_sch_dept_flg_dep_type_all CONSTANT VARCHAR2(1) := 'T';
    /* Consult department type */
    g_sch_dept_flg_dep_type_cons CONSTANT VARCHAR2(1) := 'C';
    /* Exam department type */
    g_sch_dept_flg_dep_type_exam CONSTANT VARCHAR2(1) := 'E';
    /* Analysis department type */
    g_sch_dept_flg_dep_type_anls CONSTANT VARCHAR2(1) := 'A';
    /* Surgery room department type */
    g_sch_dept_flg_dep_type_sr CONSTANT VARCHAR2(1) := 'S';
    /* Proc. MFR department type */
    g_sch_dept_flg_dep_type_pm CONSTANT VARCHAR2(2) := 'PM';
    /* Nursery type */
    g_sch_dept_flg_dep_type_nurs CONSTANT VARCHAR2(1) := 'N';
    /* Other Exames */
    g_sch_dept_flg_dep_type_oexams CONSTANT VARCHAR2(1) := 'X';
    /* nutrition department type */
    g_sch_dept_flg_dep_type_nut CONSTANT VARCHAR2(1) := 'U';
    /* Inpatient */
    g_sch_dept_flg_dep_type_inp CONSTANT VARCHAR2(2) := 'IN';
    /* social worker */
    g_sch_dept_flg_dep_type_as CONSTANT VARCHAR2(2) := 'AS';
    /* rehab appointments*/
    g_sch_dept_flg_dep_type_cr CONSTANT VARCHAR2(2) := 'CR';
    /* Multidisc appointments*/
    g_sch_dept_flg_dep_type_cm CONSTANT VARCHAR2(2) := 'CM';
    /* Home Health Care appointments*/
    g_sch_dept_flg_dep_type_hc CONSTANT VARCHAR2(2) := 'HC';

    /* Schedule vacancies: routine */
    g_sched_vacancy_routine CONSTANT VARCHAR2(1) := 'R';
    /* Schedule vacancies: unplanned */
    g_sched_vacancy_unplanned CONSTANT VARCHAR2(1) := 'V';
    /* Schedule vacancies: urgent */
    g_sched_vacancy_urgent CONSTANT VARCHAR2(1) := 'U';

    /* Usadas na create_schedule_outp */
    g_val_programada  sys_domain.val%TYPE := 'A';
    g_val_fprogramada sys_domain.val%TYPE := 'B';
    g_val_dia         sys_domain.val%TYPE := 'H';
    g_val_fdia        sys_domain.val%TYPE := 'J';
    g_val_indirect    sys_domain.val%TYPE := 'L';
    g_val_spresenca   sys_domain.val%TYPE := 'S';
    -- Valor do resultado da funcao pk_date_utils.compare_dates
    -- G se a primeira data passada e superior a 2ª
    g_date_greater     VARCHAR2(1) := 'G';
    g_date_minor       VARCHAR2(1) := 'M';
    g_consult_direct   VARCHAR2(1) := 'D';
    g_consult_indirect VARCHAR2(1) := 'I';

    /* keyword for free vacancies only request */
    g_onlyfreevacs    VARCHAR2(2) := 'FV';
    g_onlyfreevacsmsg VARCHAR2(8) := 'SCH_T343';

    /* Error message */
    g_error VARCHAR2(4000);

    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';

    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    /* Package name */
    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    /* sys_config entry name for flg_cancel_schedule */
    g_flg_cancel_schedule CONSTANT VARCHAR2(24) := 'FLG_CANCEL_SCHEDULE';

    /* Indexes for call arguments (i_args) */
    idx_dt_begin          CONSTANT NUMBER(2) := pk_schedule.idx_dt_begin;
    idx_dt_end            CONSTANT NUMBER(2) := pk_schedule.idx_dt_end;
    idx_id_inst           CONSTANT NUMBER(2) := pk_schedule.idx_id_inst;
    idx_id_dep            CONSTANT NUMBER(2) := pk_schedule.idx_id_dep;
    idx_id_dep_clin_serv  CONSTANT NUMBER(2) := pk_schedule.idx_id_dep_clin_serv;
    idx_event             CONSTANT NUMBER(2) := pk_schedule.idx_event;
    idx_id_prof           CONSTANT NUMBER(2) := pk_schedule.idx_id_prof;
    idx_id_reason         CONSTANT NUMBER(2) := pk_schedule.idx_id_reason;
    idx_id_room           CONSTANT NUMBER(2) := pk_schedule.idx_id_room;
    idx_id_notes          CONSTANT NUMBER(2) := pk_schedule.idx_id_notes;
    idx_duration          CONSTANT NUMBER(2) := pk_schedule.idx_duration;
    idx_preferred_lang    CONSTANT NUMBER(2) := pk_schedule.idx_preferred_lang;
    idx_type              CONSTANT NUMBER(2) := pk_schedule.idx_type;
    idx_status            CONSTANT NUMBER(2) := pk_schedule.idx_status;
    idx_translation_needs CONSTANT NUMBER(2) := pk_schedule.idx_translation_needs;
    idx_interval_begin    CONSTANT NUMBER(2) := pk_schedule.idx_interval_begin;
    idx_interval_end      CONSTANT NUMBER(2) := pk_schedule.idx_interval_end;
    idx_id_origin         CONSTANT NUMBER(2) := pk_schedule.idx_id_origin;
    idx_time_begin        CONSTANT NUMBER(2) := pk_schedule.idx_time_begin;
    idx_time_end          CONSTANT NUMBER(2) := pk_schedule.idx_time_end;
    idx_view              CONSTANT NUMBER(2) := pk_schedule.idx_view;
    idx_reason_notes      CONSTANT NUMBER(2) := pk_schedule.idx_reason_notes;
    idx_id_exam           CONSTANT NUMBER(2) := pk_schedule.idx_id_exam;
    idx_id_analysis       CONSTANT NUMBER(2) := pk_schedule.idx_id_analysis;
    idx_flg_prep          CONSTANT NUMBER(2) := pk_schedule.idx_flg_prep;

    g_m_encounter  CONSTANT VARCHAR2(10) := 'SCH_T890';
    g_m_scheduled  CONSTANT VARCHAR2(10) := 'SCH_T481';
    g_m_no_show    CONSTANT VARCHAR2(10) := 'SCH_T891';
    g_m_scheduling CONSTANT VARCHAR2(10) := 'SCH_T706';
    g_m_pat_name   CONSTANT VARCHAR2(30) := 'CODING_LABEL_PATIENT_NAME';
    g_m_sch_date   CONSTANT VARCHAR2(10) := 'SCH_T892';
    g_m_sch_tests  CONSTANT VARCHAR2(10) := 'SCH_T893';
    g_m_not_perf   CONSTANT VARCHAR2(10) := 'SCH_T894';
    g_m_reason     CONSTANT VARCHAR2(10) := 'SCH_T074';
    g_m_notes      CONSTANT VARCHAR2(10) := 'SCH_T382';
    g_m_notes_doc  CONSTANT VARCHAR2(10) := 'SCH_T895';
    g_m_status_n   CONSTANT VARCHAR2(10) := 'SCH_T896';
    g_m_status     CONSTANT VARCHAR2(10) := 'SCH_T897';
    g_m_undo_n_s   CONSTANT VARCHAR2(10) := 'SCH_T898';

END pk_schedule_common;
/
