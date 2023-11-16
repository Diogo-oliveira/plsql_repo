/*-- Last Change Revision: $Rev: 2028952 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:56 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_exam IS
    -- This package provides the exam scheduling logic for ALERT Scheduler.
    -- @author Nuno Guerreiro
    -- @version alpha

    ------------------------------ PUBLIC FUNCTIONS ---------------------------

    /*
    * Checks if an exam requires the patient to perform preparation steps.
    * 
    * @param i_lang              Language identifier.
    * @param i_id_exam           Exam identifier.
    * @param o_flg_prep          'Y' or 'N'.
    * @param o_prep_desc         Translated "yes" or "no"
    * @param o_error             Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/29
    */
    FUNCTION has_preparation
    (
        i_lang      language.id_language%TYPE,
        i_id_exam   exam.id_exam%TYPE,
        o_flg_prep  OUT VARCHAR2,
        o_prep_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the exam preparation values.
    * 
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option be included.
    * @param o_preparations        List of preparation options.
    * @param o_error               Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/30
    */
    FUNCTION get_preparations
    (
        i_lang         language.id_language%TYPE,
        i_prof         profissional,
        i_flg_search   VARCHAR2,
        o_preparations OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of exams.
    *
    * @param   i_lang              Language identifier.
    * @param   i_prof              Professional.
    * @param   i_id_dep            Department identifier(s).
    * @param   i_id_dep_clin_serv  Department-Clinical Service identifier(s).
    * @param   i_flg_search        Whether or not should the 'All' option appear on the list of exams.
    * @param   o_exams             List of exams
    * @param   o_error             Error message, if an error occurred.
    *
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    FUNCTION get_exams
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_id_dep           VARCHAR2,
        i_id_dep_clin_serv VARCHAR2,
        i_flg_search       VARCHAR2,
        o_exams            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedules, vacancies and patient icons for the daily view.
    * 
    * @param i_lang            Language identifier.
    * @param i_prof            Professional.
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param o_vacants         Vacancies.
    * @param o_schedule        Schedules.
    * @param o_patient_icons   Patient icons.
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    *
    * UPDATED
    * added column flg_cancel_schedule to output cursor o_schedule
    * @author  Telmo Castro
    * @date    25-07-2008
    * @version 2.4.3    
    *
    * UPDATED
    * alert-8202. new cursor for the exams in each schedule
    * @author  Telmo Castro
    * @date    16-10-2009
    * @version 2.5.0.7
    */
    FUNCTION get_hourly_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_args          IN table_varchar,
        i_id_patient    IN sch_group.id_patient%TYPE,
        o_vacants       OUT pk_types.cursor_type,
        o_schedules     OUT pk_types.cursor_type,
        o_sch_exams     OUT pk_types.cursor_type,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
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
    * @author   Tiago Ferreira
    * @version  1.0
    * @since 2007/05/17
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
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    *
    * UPDATED
    * added i_id_new_exam and removed i_id_dep_clin_serv to validate the type of exam. DCS can be different
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    01-09-2008  
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_sch_event    IN schedule.id_sch_event%TYPE,
        i_id_prof         IN sch_resource.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        o_sv_stop         OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates exam schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
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
    * @param i_ids_exams          Exam identifiers  
    * @param i_reason_notes       Reason for appointment in free-text
    * @param i_ids_exam_reqs      list of exam requisitions
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_flg_schedule_via   via de agendamento (telefone, email, ...)
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     vacancy id. Can be null, depending on the value of i_sch_option
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visit. This id relates this schedule with the combination detail line
    * @param o_id_schedule        New schedule id 
    * @param o_id_schedule_exam   new schedule exam id
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *       
    * @return   True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     02-06-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * o parametro id_exam_req_det passou a i_id_exam_req (tabela exam_req) para uniformizar com a 
    * create_schedule_exam, create_reschedule, update_schedule
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008    
    *
    * UPDATED
    * a flg_sch_type passa a ser calculada dentro do pk_schedule.create_schedule. Vai daqui a null
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    25-08-2008
    *
    * UPDATED alert-8202. passa a receber uma lista de exames e uma lista de reqs
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv    IN schedule.id_dcs_requested%TYPE,
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
        i_id_sch_combi_detail IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        o_id_schedule         OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam    OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_proceed         OUT VARCHAR2,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reschedules an appointment.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Identifier of the appointment to be rescheduled.
    * @param i_id_prof                Target professional.
    * @param i_dt_begin               Start date
    * @param i_dt_end                 End date
    * @param o_id_schedule            Identifier of the new schedule.
    * @param o_id_schedule_exam       new schedule exam id
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.    
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/23
    *
    * UPDATED
    * incluida invocacao da pk_exam.set_exam_date para update da data na tabela exam_req
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008 
    */
    FUNCTION create_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_old_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_do_overlap       IN VARCHAR2,
        i_id_consult_vac   IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option       IN VARCHAR2,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_flg_proceed      OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Validates multiple reschedules.
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_schedule               List of schedules (identifiers) to reschedule.
    * @param i_id_prof                Target professional's identifier.
    * @param i_dt_begin               Start date.
    * @param i_dt_end                 End date.
    * @param i_id_dep                 Selected department's identifier.
    * @param i_id_dep_clin_serv       Selected Department-Clinical Service's identifier.
    * @param i_id_event               Selected event's identifier.
    * @param i_id_exam                Selected exam's identifier.
    * @param o_list_sch_hour          List of schedule identifiers + start date + end date (for schedules that can be rescheduled).
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/25
    */
    FUNCTION validate_mult_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_schedules        IN table_varchar,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_dep           IN VARCHAR2 DEFAULT NULL,
        i_id_dep_clin_serv IN VARCHAR2 DEFAULT NULL,
        i_id_event         IN VARCHAR2 DEFAULT NULL,
        i_id_exam          IN VARCHAR2 DEFAULT NULL,
        o_list_sch_hour    OUT table_varchar,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reschedules several appointments.
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_prof            Target Professional.
    * @param i_schedules          List of schedules.
    * @param i_start_dates        List of start dates.
    * @param i_end_dates          List of end dates.
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/08
    */
    FUNCTION create_mult_reschedule
    (
        i_lang         language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof      IN professional.id_professional%TYPE,
        i_schedules    IN table_varchar,
        i_start_dates  IN table_varchar,
        i_end_dates    IN table_varchar,
        i_do_overlap   IN VARCHAR2,
        i_ids_cons_vac IN table_number,
        i_sch_option   IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the identifier of the exam associated with the schedule.
    * To be used inside SQL statements.
    * 
    * @param i_id_schedule    Schedule identifier.
    * 
    * @return identifier of the exam associated with the schedule.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/20
    *
    * @ UPDATED - alert-8202 now returns all exam ids under a schedule id, csv style
    * @author  Telmo
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION get_exam_id_by_sch(i_id_schedule schedule.id_schedule%TYPE) RETURN VARCHAR2;

    /*
    * Returns the exam's description  
    * 
    * @param i_lang         Language identifier.
    * @param i_id_schedule  Schedule identifier.
    * 
    * @return Exam's description. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/20
    */
    FUNCTION get_exam_desc_by_sch
    (
        i_lang        language.id_language%TYPE,
        i_id_schedule schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /*
    * Performs the validations for creating exam appointments.
    * 
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria.
    * @param i_sch_args            Appointment criteria.    
    * @param o_dt_begin            Appointment's start date
    * @param o_dt_end              Appointment's end date
    * @param o_flg_proceed         Whether or not should the screen perform additional processing after this execution
    * @param o_flg_show            Whether or not should a semantic error message be shown to the used
    * @param o_msg                 Semantic error message to show (if invalid parameters were given or an invalid action was attempted)
    * @param o_msg_title           Semantic error title message
    * @param o_button              Buttons to show
    * @param o_flg_vacancy         Vacancy flag   
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/23
    */
    FUNCTION validate_schedule_mult
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        i_sch_args    IN table_varchar,
        o_dt_begin    OUT VARCHAR2,
        o_dt_end      OUT VARCHAR2,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_flg_vacancy OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates the exam specific data for a schedule or reschedule. 
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_schedule            Schedule identifier
    * @param i_ids_exam_reqs          requesitions ids
    * @param i_dt_begin               date needed for the 20-06-2008 revision 
    * @param i_id_episode             episode id para usar no insert_exam_task
    * @param i_ids_exams              Exams identifiers
    * @param i_id_patient             patient id
    * @param o_new_ids                new schedule_exam ids
    * @param o_error                  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * o parametro id_exam_req_det passou a i_id_exam_req (tabela exam_req) para uniformizar com a 
    * create_schedule_exam, create_reschedule, update_schedule
    * incluida invocacao da pk_exam.set_exam_date para update da data na tabela exam_req
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    20-06-2008
    *
    * UPDATED
    * passa a devolver o id da schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008
    *
    * UPDATED alert-8202. passa a receber uma lista de exames e lista de reqs
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_schedule   IN schedule.id_schedule%TYPE,
        i_ids_exam_reqs IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_id_episode    IN episode.id_episode%TYPE,
        i_ids_exams     IN table_number,
        i_id_patient    IN patient.id_patient%TYPE,
        o_new_ids       OUT table_number,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates exam schedule. Adapted from the pk_schedule_outp version of create_schedule 
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be updated
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
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
    * @param i_id_exam            exam id
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_sched_request_type  tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option         'V' = marcar numa vaga; 'A' = marcar alem-vaga;  'S' = marcar sem vaga (fora do horario normal)
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     02-06-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * acrescentado o parametro o_id_schedule_exam
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-07-2008 
    */
    FUNCTION update_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_schedule        IN schedule.id_schedule%TYPE,
        i_id_patient         IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv   IN schedule.id_dcs_requested%TYPE,
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
        i_ids_exams          IN table_number DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_id_consult_vac     IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option         IN VARCHAR2,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_id_schedule_exam   OUT schedule_exam.id_schedule_exam%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_only_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_only_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an exam appointment. Also works for Other exams. Previously the cancel_schedule from pk_schedule was used,
    * but now there is a need to call specific exam code, so this step was introduced
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Telmo Castro
    * @version 2.4.3
    * @date    09-09-2008
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg_req          OUT VARCHAR2,
        o_msg_result       OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the exam description.
    * To be used inside SQL statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_exam         Exam identifier
    *
    * @return  Translated description of the exam
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/20
    */
    FUNCTION string_exam
    (
        i_lang    IN language.id_language%TYPE,
        i_id_exam IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_sch_permissions
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        i_value         IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_category_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_in_category
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_in_group
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_group   IN exam_group.id_exam_group%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns a string containig the event nr and the event date/hour.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_schedule            Schedule recursion id
    *
    * @return                         varchar2
    *                        
    * @author                         Sofia Mendes
    * @version                        2.5.0.7.6
    * @since                          2010/01/13
    **********************************************************************************************/
    FUNCTION get_schedule_exams
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION validate_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN sch_group.id_patient%TYPE,
        i_dt_begin    IN VARCHAR2,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * private function. used to check every schedule requisition's status.
    * If at least one req is executed or in an equivalent status, it is given order to not proceed with 
    * cancelation ou update or reschedule.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_schedule            schedule id 
    * @param o_proceed                N= do not proceed  Y=ok
    * @param o_error                  error data
    * @return True if successful, false otherwise. 
    *
    * @author  Telmo
    * @version 2.5.0.7
    * @date    21-10-2009
    */
    FUNCTION get_reqs_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_proceed     OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* returns all exam/other exam appointments for TODAY, scheduled for the given profissional's intitution.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    *
    * @RETURN t_table_sch_exam_daily_apps   nested table of t_rec_sch_exam_daily_apps
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    10-12-2014
    */
    FUNCTION get_today_exam_appoints
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_day  IN schedule.dt_begin_tstz%TYPE DEFAULT NULL
    ) RETURN t_table_sch_exam_daily_apps;

    /*
    *  ALERT-303513. Details of a exam/other exams schedule 
    */
    FUNCTION get_sch_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  ALERT-303513. History of a exam/other exams schedule 
    */
    FUNCTION get_sch_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * ALERT-305894. Cancel schedules connected to a specific req
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_req                      requisition id
    * @param i_ids_exams                   (optional) exam ids. Limits the canceled schedules to those connected with these exams
    * @param i_id_cancel_reason            common cancel reason to stamp all canceled schedules
    * @param i_cancel_notes                (optional) common cancel notes
    * @param i_transaction_id              sch remote transaction id
    * @param o_error                       error info
    *
    * @RETURN true/false
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    13-01-2015
    */
    FUNCTION cancel_req_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_req           IN schedule_exam.id_exam_req%TYPE,
        i_ids_exams        IN table_number DEFAULT NULL,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------- CONSTANTS ------------------------------

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    /* Yes / No translation */
    g_yes_no CONSTANT VARCHAR2(6) := 'YES_NO';

    g_default_date_mask CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MI';

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

    idx_sch_args_dcs      CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_dcs;
    idx_sch_args_event    CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_event;
    idx_sch_args_prof     CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_prof;
    idx_sch_args_patient  CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_patient;
    idx_sch_args_exam     CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_exam;
    idx_sch_args_analysis CONSTANT NUMBER(2) := pk_schedule.idx_sch_args_analysis;

    /* message codes  */
    -- to be used in update_schedule
    g_sched_msg_no_upd CONSTANT VARCHAR2(8) := 'SCH_T788';
    -- to be used in cancel_schedule
    g_sched_msg_no_cancel CONSTANT VARCHAR2(8) := 'SCH_T789';

END pk_schedule_exam;
/
