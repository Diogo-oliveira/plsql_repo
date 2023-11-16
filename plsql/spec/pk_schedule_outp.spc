/*-- Last Change Revision: $Rev: 2028959 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:58 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_outp IS

    ----- FUNCTIONS ----------------------------------------------------------------------------------------------------------

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
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
    *
    * UPDATED
    * a current_timestamp deixa de ser truncada no time. Passou a usar novo modelo da msg_stack para se conseguir
    * saber se certa mensagem vem na stack
    * @author Telmo Castro
    * @date 29-08-2008
    * @version 2.4.3
    */
    FUNCTION validate_schedule
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv   IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event       IN schedule.id_sch_event%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_dt_begin           IN VARCHAR2,
        i_id_sch_consult_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_institution     IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    -- Create Schedule for Multidisciplinary
    FUNCTION create_schedule_multidisc
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN table_number,
        i_id_dep_clin_serv_list   IN table_number,
        i_id_sch_event            IN schedule.id_sch_event%TYPE,
        i_id_prof_list            IN table_number,
        i_dt_begin                IN VARCHAR2,
        i_dt_end                  IN VARCHAR2,
        i_flg_vacancy             IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason               IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin               IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room                 IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode              IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes            IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap              IN VARCHAR2,
        i_id_consult_vac_list     IN table_number,
        i_sch_option              IN VARCHAR2,
        i_id_consult_req          IN consult_req.id_consult_req%TYPE DEFAULT NULL,
        i_id_complaint            IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_prof_leader          IN sch_resource.id_professional%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_leader IN schedule.id_dcs_requested%TYPE,
        i_id_sch_combi_detail     IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule             OUT schedule.id_schedule%TYPE,
        o_flg_proceed             OUT VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg                     OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    -- Validate Schedule for Multidisciplinary
    FUNCTION validate_schedule_multidisc
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv_list   IN table_number,
        i_id_sch_event            IN schedule.id_sch_event%TYPE,
        i_id_prof                 IN table_number,
        i_dt_begin                IN VARCHAR2,
        i_id_sch_consult_vac_list IN table_number,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed             OUT VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg                     OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedules, vacancies and patient icons for the daily view.
    * 
    * @param i_lang            Language identifier.
    * @param i_prof            Professional.
    * @param i_args            UI search args.
    * @param i_id_patient      Patient identifier.
    * @param o_vacants         Vacancies.
    * @param o_schedules       Schedules.
    * @param o_patient_icons   Patient icons.
    * @param o_error           Error message, if an error occurred.
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
    */
    FUNCTION get_hourly_detail
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_args          IN table_varchar,
        i_id_patient    IN sch_group.id_patient%TYPE,
        o_vacants       OUT pk_types.cursor_type,
        o_schedules     OUT pk_types.cursor_type,
        o_professionals OUT pk_types.cursor_type,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates outpatient schedule. Also used for private practice.  
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
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
    * @param i_flg_schedule_via   meio do pedido marcacao
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    * @return                     True if successful, false otherwise
    * 
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     28-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * adaptacao para as consultas de enfermagem. Antes a coluna schedule.flg_sch_type recebia sempre C,
    * agora esse valor e' calculado atraves do id_sch_event
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     05-06-2008 
    *
    * UPDATED
    * passa a escrever o id_schedule na requisicao quando em contexto de requisicao de consulta (i_id_consult_req not null)
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     16-07-2008
    *
    * UPDATED
    * a flg_sch_type passa a ser calculada dentro do pk_schedule.create_schedule. Vai daqui a null
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    25-08-2008  
    *
    * UPDATED
    * novo campo i_id_complaint
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    *
    * UPDATED
    * Change i_id_patient data type from numner to table_number (because of group schedules)
    * @author  Sofia Mendes
    * @date     15-06-2009
    * @version  2.5.x
    */
    FUNCTION create_schedule
    (
        i_lang                  IN LANGUAGE.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN table_number, --sch_group.id_patient%TYPE,
        i_id_dep_clin_serv      IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event          IN schedule.id_sch_event%TYPE,
        i_id_prof               IN sch_resource.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_flg_vacancy           IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes        IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator    IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred     IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason             IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin             IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room               IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref       IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode            IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes          IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type      IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via      IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap            IN VARCHAR2,
        i_id_consult_vac        IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option            IN VARCHAR2,
        i_id_consult_req        IN consult_req.id_consult_req%TYPE DEFAULT NULL,
        i_id_complaint          IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_sch_combi_detail   IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        i_flg_status            IN schedule.flg_status%TYPE DEFAULT NULL,
        i_id_institution        IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule           OUT schedule.id_schedule%TYPE,
        o_flg_proceed           OUT VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_schedule_pat
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN table_number, --sch_group.id_patient%TYPE,
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
        i_id_schedule_ref    IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_id_consult_vac     IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option         IN VARCHAR2,
        i_id_consult_req     IN consult_req.id_consult_req%TYPE DEFAULT NULL,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_institution     IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param o_sv_stop                warning to the caller telling that this reschedule violates dependencies inside a single visit
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
    */
    FUNCTION validate_reschedule
    (
        i_lang                   IN LANGUAGE.id_language%TYPE,
        i_prof                   IN profissional,
        i_old_id_schedule        IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv       IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event           IN schedule.id_sch_event%TYPE,
        i_id_prof                IN sch_resource.id_professional%TYPE,
        i_dt_begin               IN VARCHAR2,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_tab_patients           IN table_number DEFAULT table_number(),
        i_id_institution         IN institution.id_institution%TYPE DEFAULT NULL,
        o_sv_stop                OUT VARCHAR2,
        o_flg_proceed            OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_error                  OUT t_error_out
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
    * @param i_do_overlap             null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                                 issued with Y or N
    * @param i_id_consult_vac         id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option             'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_id_schedule            Identifier of the new schedule.
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
    * added parameters to cope with new create_schedule
    * @author  Telmo Castro
    * @date    01-07-2008
    * @version 2.4.3
    */
    FUNCTION create_reschedule
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_do_overlap      IN VARCHAR2,
        i_id_consult_vac  IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option      IN VARCHAR2,
        i_id_institution  IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reschedules an appointment patient that belongs to a group appointment.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Identifier of the appointment to be rescheduled.
    * @param i_id_patients            Table number with the patient ids which appointment will be cancelled
    * @param i_id_prof                Target professional.
    * @param i_dt_begin               Start date
    * @param i_dt_end                 End date
    * @param i_do_overlap             null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                                 issued with Y or N
    * @param i_id_consult_vac         id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option             'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_id_schedule            Identifier of the new schedule.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.    
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Sofia Mendes
    * @version  2.5.x
    * @since 2009/06/17    
    */
    FUNCTION create_reschedule_pat
    (
        i_lang            IN LANGUAGE.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patients     IN table_number,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_do_overlap      IN VARCHAR2,
        i_id_consult_vac  IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option      IN VARCHAR2,
        i_id_institution  IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Validates multiple reschedules.
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_schedules              List of schedules (identifiers) to reschedule.
    * @param i_id_prof                Target professional's identifier.
    * @param i_dt_begin               Start date.
    * @param i_dt_end                 End date.
    * @param i_id_dep                 Selected department's identifier.
    * @param i_id_dep_clin_serv       Selected Department-Clinical Service's identifier.
    * @param i_id_event               Selected event's identifier.    
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
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_schedules        IN table_varchar,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_dep           IN VARCHAR2 DEFAULT NULL,
        i_id_dep_clin_serv IN VARCHAR2 DEFAULT NULL,
        i_id_event         IN VARCHAR2 DEFAULT NULL,
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
    * @param i_id_prof            Target professional.
    * @param i_schedules          List of schedules.
    * @param i_start_dates        List of start dates.
    * @param i_end_dates          List of end dates.
    * @param i_do_overlap             null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                                 issued with Y or N
    * @param i_id_consult_vac         id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option             'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_error              Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/08
    *
    * UPDATED
    * added parameters to cope with new create_schedule
    * @author  Telmo Castro
    * @date    01-07-2008
    * @version 2.4.3
    */
    FUNCTION create_mult_reschedule
    (
        i_lang         LANGUAGE.id_language%TYPE,
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
    * Performs the validations for creating consult appointments.
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
        i_lang        IN LANGUAGE.id_language%TYPE,
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

    /**
    * Updates outpatient schedule. Also used for private practice.  
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
    * @param i_id_episode         Episode 
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
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
    * @author   Luís Gaspar
    * @version  2.4.3
    * @date     31-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo i_id_complaint
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008 
    */
    FUNCTION update_schedule
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_schedule        IN schedule.id_schedule%TYPE,
        i_id_patient         IN table_number, --sch_group.id_patient%TYPE,
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
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_id_consult_vac     IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option         IN VARCHAR2,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_cancel_reason   IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        i_id_institution     IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates outpatient schedule. Also used for private practice. Integration version.
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
    * @param i_id_episode         Episode
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_flg_request_type   tipo de pedido
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
    * @author   Luís Gaspar
    * @version  2.4.3
    * @date     31-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo i_id_complaint
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    */
    FUNCTION update_schedule
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_schedule        IN schedule.id_schedule%TYPE,
        i_id_patient         IN table_number, --sch_group.id_patient%TYPE,
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
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_id_consult_vac     IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option         IN VARCHAR2,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_id_cancel_reason   IN schedule.id_cancel_reason%TYPE DEFAULT NULL,
        i_id_institution     IN institution.id_institution%TYPE DEFAULT NULL,
        i_transaction_id     IN VARCHAR2,
        o_id_schedule        OUT schedule.id_schedule%TYPE,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a pacient appointment or a group of patient appointments in a group.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be updated
    * @param i_id_patients        Table number with the patients IDs wich appointment will be cancelled   
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @author   Sofia Mendes
    * @version  2.5.0.x
    * @date     16-06-2009    
    */
    FUNCTION cancel_schedule_group
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patients      IN table_number,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * inserts or updates a combination master record. Used in single visit appointments.
    * if i_id_combi is not null then its an update
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           if not null, key chosen by caller
    * @param i_combi_name          name for this combination
    * @param i_dt_before          date says that the schedules must start before this date
    * @param i_dt_after           date says that the schedules must start after this date
    * @param i_id_target_inst     location/institution where these visit will happen
    * @param i_Notes              notes for the scheduler professional
    * @param i_priority           priority level
    * @param i_id_patient         patient id
    * @param i_id_prof_req        id of professional who requested this sv
    * @param o_id_combi           new record id
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     19-06-2009
    */
    FUNCTION set_combination
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_id_combi       IN sch_combi.id_sch_combi%TYPE,
        i_combi_name     IN sch_combi.combi_name%TYPE,
        i_dt_before      IN VARCHAR2,
        i_dt_after       IN VARCHAR2,
        i_id_target_inst IN institution.id_institution%TYPE,
        i_notes          IN sch_combi.notes%TYPE,
        i_priority       IN sch_combi.priority%TYPE,
        i_id_patient     IN sch_combi.id_patient%TYPE,
        i_id_prof_req    IN sch_combi.id_prof_requests%TYPE,
        o_id_combi       OUT sch_combi.id_sch_combi%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * inserts or updates a combination detail record. Used in single visit appointments. A detail is one of the appointments
    * of a single visit.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           if not null, key chosen by caller
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     19-06-2009
    */
    FUNCTION set_combi_line
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_id_combi       IN sch_combi_detail.id_sch_combi%TYPE,
        i_id_code        IN sch_combi_detail.id_code%TYPE,
        i_id_event       IN sch_combi_detail.id_sch_event%TYPE,
        i_id_dcs         IN sch_combi_detail.id_dep_clin_serv%TYPE,
        i_id_exam        IN sch_combi_detail.id_exam%TYPE,
        i_dep_type       IN sch_combi_detail.dep_type%TYPE,
        i_id_code_parent IN sch_combi_detail.id_code_parent%TYPE,
        i_min_time_after IN sch_combi_detail.min_time_after%TYPE,
        i_max_time_after IN sch_combi_detail.max_time_after%TYPE,
        i_flg_optional   IN sch_combi_detail.flg_optional%TYPE,
        i_id_profs       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  delete a detail line of a combination. if there is a schedule attached returns error
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_sch_combi       sch_combi_detail pk part 1
    * @param i_id_code            sch_combi_Detail pk part 2
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     22-06-2009
    */
    FUNCTION delete_combi_detail
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_detail.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_detail.id_code%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * delete a professional of a detail line in a combination. if there is a schedule attached returns error
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_sch_combi       sch_combi_detail pk part 1
    * @param i_id_code            sch_combi_Detail pk part 2
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     22-06-2009
    */
    FUNCTION delete_combi_prof
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_profs.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_profs.id_code%TYPE,
        i_id_prof      IN sch_combi_profs.id_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * adds new prof to a detail line in a combination. if it exists does nothing
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_sch_combi       sch_combi_detail pk part 1
    * @param i_id_code            sch_combi_Detail pk part 2
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     22-06-2009
    */
    FUNCTION set_combi_prof
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_profs.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_profs.id_code%TYPE,
        i_id_prof      IN sch_combi_profs.id_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** sets the dependency, by means of id_code, from one detail to other
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_sch_combi       sch_combi_detail pk part 1
    * @param i_id_code            sch_combi_Detail pk part 2
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     22-06-2009
    */
    FUNCTION set_combi_dependency
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_id_sch_combi   IN sch_combi_detail.id_sch_combi%TYPE,
        i_id_code        IN sch_combi_detail.id_code%TYPE,
        i_id_code_parent IN sch_combi_detail.id_code_parent%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** retrieves the combination detail lines
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_sch_combi       sch_combi_detail pk part 1
    * @param o_lines              detail lines
    * @param o_profs              names of professionals. each one has the id code of the detail line he belongs
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     25-06-2009
    */
    FUNCTION get_combination
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_detail.id_sch_combi%TYPE,
        o_lines        OUT pk_types.cursor_type,
        o_profs        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_schedules_series
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN table_number,
        i_id_dep_clin_serv   IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event       IN schedule.id_sch_event%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_tab_dt_begin       IN table_varchar,
        i_tab_dt_end         IN table_varchar,
        i_flg_vacancy        IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_schedule_notes     IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred  IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason          IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin          IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_room            IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref    IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode         IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_reason_notes       IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type   IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via   IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_do_overlap         IN VARCHAR2,
        i_tab_id_consult_vac IN table_number,
        i_sch_option         IN VARCHAR2,
        i_id_consult_req     IN consult_req.id_consult_req%TYPE DEFAULT NULL,
        i_id_complaint       IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_repeat_frequency   IN schedule_recursion.repeat_frequency%TYPE,
        i_flg_unit           IN schedule_recursion.flg_timeunit%TYPE,
        i_weekday            IN schedule_recursion.weekdays%TYPE,
        i_week               IN schedule_recursion.week%TYPE,
        i_day_month          IN schedule_recursion.day_month%TYPE,
        i_month              IN schedule_recursion.MONTH%TYPE,
        i_begin_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        i_num_serie          IN schedule_recursion.num_freq%TYPE,
        i_flg_status         IN schedule_recursion.flg_type_rep%TYPE,
        i_id_institution     IN institution.id_institution%TYPE DEFAULT NULL,
        o_tab_id_schedule    OUT table_number,
        o_flg_proceed        OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION confirm_schedules_series
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_tab_id_sch  IN table_number,
        i_tab_vacs    IN table_number,
        i_confirm_all IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

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

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    -- global variables 
    g_error VARCHAR2(4000);

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    g_default_date_mask CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MI';

    g_schedule_outp_flg_type_first CONSTANT VARCHAR2(1) := 'P';
    g_schedule_outp_flg_type_subs  CONSTANT VARCHAR2(1) := 'S';

    /* Update schedule cancel notes */
    g_update_schedule CONSTANT VARCHAR2(8) := 'SCH_T264';

    g_sysdate_tstz TIMESTAMP WITH TIME ZONE := current_timestamp;

END pk_schedule_outp;
/
