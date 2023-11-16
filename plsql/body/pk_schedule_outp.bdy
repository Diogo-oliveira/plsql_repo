/*-- Last Change Revision: $Rev: 2027688 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:00 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_outp IS

    --------------------------- PRIVATE FUNCTIONS & PROCEDURES ---------------------------------

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(text=>i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, object_name => g_package_name, owner => g_package_owner);
    END error_handling;

    /*
    * Creates the outpatient specific data for a schedule or reschedule. 
    * 
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_id_patient             Patient identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional identifier.
    * @param i_dt_begin               Start date.
    * @param i_schedule_notes         Schedule notes.
    * @param i_id_episode             Episode identifier.
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
    * @since 2008/02/26
    * @Notes Alterar a chamada à funcao pk_schedule_common.create_schedule_outp
    *        Para já, como a agenda nao vai contemplar a hipotese de escolher directo ou indirecto vou acrescentar o param a NULL
    *
    * UPDATED
    * acrescentado parametro i_flg_sched_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date  30-04-2008
    *
    * UPDATED
    * i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    */
    FUNCTION create_schedule_outp
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN schedule.dt_begin_tstz%TYPE,
        i_schedule_notes   IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_episode       IN consult_req.id_episode%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := 'CREATE_SCHEDULE_OUTP';
        o_consult_req_rec      consult_req%ROWTYPE;
        o_consult_req_prof_rec consult_req_prof%ROWTYPE;
        l_schedule_interface   BOOLEAN;
        l_flg_sched_type       schedule_outp.flg_sched_type%TYPE := NULL;
        l_func_exception EXCEPTION;
        l_id_institution institution.id_institution%TYPE := i_id_institution;
    BEGIN
        g_error := 'CALL EXIST_INTERFACE';
    
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        -- Check if there is an interface with an external system
        IF NOT pk_schedule_common.exist_interface(i_lang   => i_lang,
                                                  i_prof   => i_prof,
                                                  o_exists => l_schedule_interface,
                                                  o_error  => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL CREATE_SCHEDULE_OUTP';
        -- Create the outpatient-specific data.
        IF NOT pk_schedule_common.create_schedule_outp(i_lang              => i_lang,
                                                       i_id_prof_schedules => i_prof.id,
                                                       i_id_institution    => l_id_institution, --i_prof.institution,
                                                       i_id_software       => i_prof.software,
                                                       i_id_schedule       => i_id_schedule,
                                                       i_id_patient        => i_id_patient,
                                                       i_id_dep_clin_serv  => i_id_dep_clin_serv,
                                                       i_id_sch_event      => i_id_sch_event,
                                                       i_id_prof           => i_id_prof,
                                                       i_dt_begin          => i_dt_begin,
                                                       i_schedule_notes    => i_schedule_notes,
                                                       i_id_episode        => i_id_episode,
                                                       i_flg_sched_type    => l_flg_sched_type,
                                                       o_error             => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Create data in consult request if there are no interfaces and ALERT is not the primary application for schedules
        IF NOT l_schedule_interface
        THEN
            g_error := 'CALL NEW_CONSULT_REQ';
            IF NOT pk_schedule_common.new_consult_req(i_lang                => i_lang,
                                                      i_dt_consult_req_tstz => current_timestamp,
                                                      i_id_patient          => i_id_patient,
                                                      i_id_instit_requests  => i_prof.institution,
                                                      i_id_inst_requested   => l_id_institution, --i_prof.institution,
                                                      i_id_episode          => i_id_episode,
                                                      i_id_prof_req         => i_prof.id,
                                                      i_dt_scheduled_tstz   => i_dt_begin,
                                                      i_notes_admin         => i_schedule_notes,
                                                      i_id_prof_cancel      => NULL,
                                                      i_dt_cancel_tstz      => NULL,
                                                      i_notes_cancel        => NULL,
                                                      i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                      i_id_prof_requested   => i_id_prof,
                                                      i_id_schedule         => i_id_schedule,
                                                      i_flg_status          => pk_consult_req.g_consult_req_stat_reply,
                                                      o_consult_req_rec     => o_consult_req_rec,
                                                      o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            g_error := 'CALL NEW_CONSULT_REQ_PROF';
            IF NOT pk_schedule_common.new_consult_req_prof(i_lang                     => i_lang,
                                                           i_dt_consult_req_prof_tstz => current_timestamp,
                                                           i_id_consult_req           => o_consult_req_rec.id_consult_req,
                                                           i_id_professional          => i_prof.id,
                                                           i_denial_justif            => NULL,
                                                           i_flg_status               => pk_schedule.g_status_scheduled,
                                                           i_dt_scheduled_tstz        => i_dt_begin,
                                                           o_consult_req_prof_rec     => o_consult_req_prof_rec,
                                                           o_error                    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_schedule_outp;

    --------------------------------- PUBLIC FUNCTIONS ----------------------------------------

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
    *
    * UPDATED
    * group appointments: validate if the maximun nr of pacients in the group was reached
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(18) := 'VALIDATE_SCHEDULE';
    
        l_id_inst        department.id_institution%TYPE;
        l_epis_type      sys_config.VALUE%TYPE;
        l_flg_occurrence sch_event.flg_occurrence%TYPE;
        l_flg_type       schedule_outp.flg_type%TYPE;
    
        l_nr_free_vacs NUMBER;
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
        g_error       := 'CALL VALIDATE_SCHEDULE';
    
        -- Perform general validations.
        IF NOT pk_schedule.validate_schedule(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => i_id_patient,
                                             i_id_dep_clin_serv => i_id_dep_clin_serv,
                                             i_id_sch_event     => i_id_sch_event,
                                             i_id_prof          => i_id_prof,
                                             i_dt_begin         => i_dt_begin,
                                             i_id_institution   => i_id_institution,
                                             o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- RULE : Episode validations  ----------------------------------------------------------------------    
        g_error := 'RULE : Episode validations';
    
        -- Load variables 
        SELECT d.id_institution
          INTO l_id_inst
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_department = d.id_department
           AND dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        g_error := 'GET EVENT OCCURRENCE';
        -- Get event occurence
        SELECT se.flg_occurrence
          INTO l_flg_occurrence
          FROM sch_event se
         WHERE se.id_sch_event = i_id_sch_event;
    
        g_error := 'CALL GET_CONFIG';
        -- Get episode type
        IF NOT pk_schedule.get_config(i_lang         => i_lang,
                                      i_id_sysconfig => pk_schedule.g_config_epis_type,
                                      i_prof         => i_prof,
                                      o_config       => l_epis_type,
                                      o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_EPISODE.GET_FIRST_SUBSEQUENT';
        -- Check if it is a first or subsequent appointment
        IF NOT pk_episode.get_first_subsequent(i_lang         => i_lang,
                                               i_id_pat       => i_id_patient,
                                               i_id_clin_serv => pk_schedule.get_id_clin_serv(i_id_dcs => i_id_dep_clin_serv),
                                               i_institution  => l_id_inst,
                                               i_epis_type    => l_epis_type,
                                               o_flg          => l_flg_type,
                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CHECK CONSULT TYPE';
        -- Test the type of consult against the patient.
        IF (l_flg_type = g_schedule_outp_flg_type_first AND l_flg_occurrence = pk_schedule.g_event_occurrence_subs)
        THEN
            o_msg := pk_message.get_message(i_lang, pk_schedule.g_epis_rule_subsequent);
            pk_schedule.message_push(o_msg, 1);
        ELSIF (l_flg_type = g_schedule_outp_flg_type_subs AND l_flg_occurrence = pk_schedule.g_event_occurrence_first)
        THEN
            o_msg := pk_message.get_message(i_lang, pk_schedule.g_epis_rule_first);
            pk_schedule.message_push(o_msg, 2);
        END IF;
    
        -- validate if the group isn't full
        IF (i_id_sch_event = pk_schedule.g_event_group)
        THEN
            SELECT scv.max_vacancies - scv.used_vacancies
              INTO l_nr_free_vacs
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy = i_id_sch_consult_vac;
        
            IF (l_nr_free_vacs < 1)
            THEN
                o_msg := pk_message.get_message(i_lang, 'SCH_T744');
                pk_schedule.message_push(o_msg, 1);
                o_flg_proceed := g_yes;
            END IF;
        END IF;
    
        ------- CREATE RETURN MESSAGE ------------------------------------------------------------------------
        g_error := 'Processing return message';
    
        IF pk_schedule.g_msg_stack.COUNT > 1
        THEN
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            pk_schedule.message_flush(o_msg);
            o_flg_show := g_yes;
            IF (i_id_sch_event <> pk_schedule.g_event_group)
            THEN
                o_flg_proceed := g_yes;
                o_button      := pk_schedule.g_cancel_button_code ||
                                 pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                                 pk_schedule.g_ok_button_code ||
                                 pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            ELSE
                o_button := pk_schedule.g_cancel_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                            pk_schedule.g_ok_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_schedule;

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
    * @author   Nuno Miguel Ferreira
    * @version  2.5.0.4
    * @since 2009/07/01
    *   
    * UPDATED: new parameter: i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @since 2009/07/30
    *
    * UPDATED ALERT-54316 - checking all rules against all professionals results in duplicate messages.
    * Now only the foist professional and dcs is considered
    * @author   Telmo
    * @version  2.5.0.7
    * @since    05-11-2009    
    */
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'VALIDATE_SCHEDULE_MULTIDISC';
    BEGIN
    
        g_error := 'CALL VALIDATE_SCHEDULE FOR PREMIER PROFESSIONAL';
        IF i_id_prof IS NOT NULL
           AND i_id_prof.EXISTS(1)
           AND i_id_dep_clin_serv_list IS NOT NULL
           AND i_id_dep_clin_serv_list.EXISTS(1)
        THEN
            IF NOT validate_schedule(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_id_patient         => i_id_patient,
                                     i_id_dep_clin_serv   => i_id_dep_clin_serv_list(1),
                                     i_id_sch_event       => i_id_sch_event,
                                     i_id_prof            => i_id_prof(1),
                                     i_dt_begin           => i_dt_begin,
                                     i_id_sch_consult_vac => NULL,
                                     i_id_institution     => i_id_institution,
                                     o_flg_proceed        => o_flg_proceed,
                                     o_flg_show           => o_flg_show,
                                     o_msg                => o_msg,
                                     o_msg_title          => o_msg_title,
                                     o_button             => o_button,
                                     o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF o_flg_proceed = g_no
            THEN
                RETURN TRUE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_schedule_multidisc;

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
    * @param i_id_combi_detail    used in single visits to relate to the combination detail line that originated this schedule
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
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * Change i_id_patient data type from number to table_number (because of group schedules)
    * @author  Sofia Mendes
    * @date     15-06-2009
    * @version  2.5.x
    *
    * UPDATED
    * New parameter: i_id_institution: to allow to schedule to a institution different from i_prof.institution
    * @author  Sofia Mendes
    * @date     29-07-2009
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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_id_schedule schedule.id_schedule%TYPE;
        l_timestamp   TIMESTAMP WITH TIME ZONE;
        l_retval      BOOLEAN;
        l_rowids      table_varchar;
        l_func_exception EXCEPTION;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'CALL CREATE_SCHEDULE';
        -- Create the schedule
        l_retval := pk_schedule.create_schedule(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_patient            => i_id_patient,
                                                i_id_dep_clin_serv      => i_id_dep_clin_serv,
                                                i_id_sch_event          => i_id_sch_event,
                                                i_id_prof               => i_id_prof,
                                                i_dt_begin              => i_dt_begin,
                                                i_dt_end                => i_dt_end,
                                                i_flg_vacancy           => i_flg_vacancy,
                                                i_schedule_notes        => i_schedule_notes,
                                                i_id_lang_translator    => i_id_lang_translator,
                                                i_id_lang_preferred     => i_id_lang_preferred,
                                                i_id_reason             => i_id_reason,
                                                i_id_origin             => i_id_origin,
                                                i_id_room               => i_id_room,
                                                i_flg_sch_type          => NULL,
                                                i_reason_notes          => i_reason_notes,
                                                i_flg_request_type      => i_flg_request_type,
                                                i_flg_schedule_via      => i_flg_schedule_via,
                                                i_do_overlap            => i_do_overlap,
                                                i_id_consult_vac        => i_id_consult_vac,
                                                i_sch_option            => i_sch_option,
                                                i_id_schedule_ref       => i_id_schedule_ref,
                                                i_id_episode            => i_id_episode,
                                                i_id_complaint          => i_id_complaint,
                                                o_id_schedule           => l_id_schedule,
                                                i_id_sch_combi_detail   => i_id_sch_combi_detail,
                                                i_id_schedule_recursion => i_id_schedule_recursion,
                                                i_flg_status            => i_flg_status,
                                                i_id_institution        => i_id_institution,
                                                o_flg_proceed           => o_flg_proceed,
                                                o_flg_show              => o_flg_show,
                                                o_msg                   => o_msg,
                                                o_msg_title             => o_msg_title,
                                                o_button                => o_button,
                                                o_error                 => o_error);
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_timestamp,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CREATE SCHEDULE OUTP';
        -- Create outpatient-specific data.
        IF NOT create_schedule_outp(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_schedule      => l_id_schedule,
                                    i_id_patient       => i_id_patient(1),
                                    i_id_dep_clin_serv => i_id_dep_clin_serv,
                                    i_id_sch_event     => i_id_sch_event,
                                    i_id_prof          => i_id_prof,
                                    i_dt_begin         => l_timestamp,
                                    i_schedule_notes   => i_schedule_notes,
                                    i_id_episode       => i_id_episode,
                                    i_id_institution   => i_id_institution,
                                    o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF i_id_consult_req IS NOT NULL
        THEN
            --<DENORM RicardoNunoAlmeida>
            ts_consult_req.upd(id_consult_req_in => i_id_consult_req,
                               flg_status_in     => 'S',
                               id_schedule_in    => l_id_schedule,
                               rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CONSULT_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            --</DENORM>
        
        END IF;
    
        o_id_schedule := l_id_schedule;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_schedule;

    /*
    * Creates outpatient schedule. Also used for private practice.  
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service for each professional
    * @param i_id_sch_event       Event type   
    * @param i_id_prof_list       Professionals list schedule target
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
    * @param i_id_combi_detail    used in single visits to relate to the combination detail line that originated this schedule
    * @param o_id_schedule        New schedule
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set if a message is displayed or not      
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @author   Nuno Miguel Ferreira
    * @version  2.5.0.4
    * @date     01-07-2009
    *
    * UPDATED: new parameter : i_id_institution
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     30-07-2009
    */
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
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30) := 'CREATE_SCHEDULE_MULTIDISC';
        l_id_schedule  schedule.id_schedule%TYPE;
        l_timestamp    TIMESTAMP WITH TIME ZONE;
        l_retval       BOOLEAN;
        l_rowids       table_varchar;
        l_id_multidisc schedule.id_multidisc%TYPE;
        l_func_exception EXCEPTION;
    
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert date to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_timestamp,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get nextval from <seq_sch_group_multidisc> sequence
        g_error := 'GET MULTIDISC SEQUENCE ID - for grouping schedules';
        SELECT seq_sch_group_multidisc.NEXTVAL
          INTO l_id_multidisc
          FROM dual;
    
        -- Single SCHEDULE register with multiple SCH_RESOURCE registers            
        l_retval := pk_schedule.create_schedule_multidisc(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_id_patient              => i_id_patient,
                                                          i_id_dep_clin_serv_list   => i_id_dep_clin_serv_list,
                                                          i_id_sch_event            => i_id_sch_event,
                                                          i_id_prof_list            => i_id_prof_list,
                                                          i_dt_begin                => i_dt_begin,
                                                          i_dt_end                  => i_dt_end,
                                                          i_flg_vacancy             => i_flg_vacancy,
                                                          i_schedule_notes          => i_schedule_notes,
                                                          i_id_lang_translator      => i_id_lang_translator,
                                                          i_id_lang_preferred       => i_id_lang_preferred,
                                                          i_id_reason               => i_id_reason,
                                                          i_id_origin               => i_id_origin,
                                                          i_id_room                 => i_id_room,
                                                          i_flg_sch_type            => NULL,
                                                          i_reason_notes            => i_reason_notes,
                                                          i_flg_request_type        => i_flg_request_type,
                                                          i_flg_schedule_via        => i_flg_schedule_via,
                                                          i_do_overlap              => i_do_overlap,
                                                          i_id_consult_vac_list     => i_id_consult_vac_list,
                                                          i_sch_option              => i_sch_option,
                                                          i_id_schedule_ref         => i_id_schedule_ref,
                                                          i_id_episode              => i_id_episode,
                                                          i_id_complaint            => i_id_complaint,
                                                          i_id_prof_leader          => i_id_prof_leader,
                                                          i_id_dep_clin_serv_leader => i_id_dep_clin_serv_leader,
                                                          i_id_multidisc            => l_id_multidisc,
                                                          o_id_schedule             => l_id_schedule,
                                                          i_id_sch_combi_detail     => i_id_sch_combi_detail,
                                                          i_id_institution          => i_id_institution,
                                                          o_flg_proceed             => o_flg_proceed,
                                                          o_flg_show                => o_flg_show,
                                                          o_msg                     => o_msg,
                                                          o_msg_title               => o_msg_title,
                                                          o_button                  => o_button,
                                                          o_error                   => o_error);
    
        IF l_retval
           AND o_flg_show = g_yes
        THEN
            RETURN TRUE;
        ELSIF NOT l_retval
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF i_id_consult_req IS NOT NULL
        THEN
            ts_consult_req.upd(id_consult_req_in => i_id_consult_req,
                               flg_status_in     => 'S',
                               id_schedule_in    => l_id_schedule,
                               rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CONSULT_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'CREATE SCHEDULE OUTP';
        -- Create outpatient-specific data.
        IF NOT create_schedule_outp(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_schedule      => l_id_schedule,
                                    i_id_patient       => i_id_patient(1),
                                    i_id_dep_clin_serv => i_id_dep_clin_serv_leader,
                                    i_id_sch_event     => i_id_sch_event,
                                    i_id_prof          => i_id_prof_leader,
                                    i_dt_begin         => l_timestamp,
                                    i_schedule_notes   => i_schedule_notes,
                                    i_id_episode       => i_id_episode,
                                    i_id_institution   => i_id_institution,
                                    o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        o_id_schedule := l_id_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_schedule_multidisc;

    /*
    * Creates outpatient group schedule. Schedules one patient in a group  
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
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @author   Sofia Mendes
    * @version  2.5.4
    * @date     16-06-2009
    */
    /*
    * Creates outpatient group schedule. Schedules one patient in a group
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
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @author   Sofia Mendes
    * @version  2.5.4
    * @date     16-06-2009
    */
    FUNCTION create_schedule_pat
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN table_number,
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CREATE_SCHEDULE_PAT';
    
        l_tab_patients table_number;
        l_id_schedule  schedule.id_schedule%TYPE;
    
        l_nr_patients NUMBER;
        --l_id_institution institution.id_institution%TYPE := i_id_institution;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        /* IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;*/
    
        -- select patients
        g_error := 'SELECT PATIENTS';
        SELECT sg.id_patient BULK COLLECT
          INTO l_tab_patients
          FROM schedule s
          JOIN sch_consult_vacancy scv ON s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
          LEFT JOIN sch_group sg ON s.id_schedule = sg.id_schedule
          LEFT JOIN sch_event se ON s.id_sch_event = se.id_sch_event
         WHERE se.flg_is_group = pk_alert_constant.g_yes
           AND s.flg_status != pk_schedule.g_status_canceled
           AND s.flg_sch_type = pk_schedule.g_sched_status_cancelled
           AND s.id_sch_consult_vacancy = i_id_consult_vac;
    
        IF (l_tab_patients.COUNT = 0)
        THEN
            g_error := 'CALL CREATE_SCHEDULE';
            IF NOT create_schedule(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_id_patient         => i_id_patient,
                                   i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                   i_id_sch_event       => i_id_sch_event,
                                   i_id_prof            => i_id_prof,
                                   i_dt_begin           => i_dt_begin,
                                   i_dt_end             => i_dt_end,
                                   i_flg_vacancy        => i_flg_vacancy,
                                   i_schedule_notes     => i_schedule_notes,
                                   i_id_lang_translator => i_id_lang_translator,
                                   i_id_lang_preferred  => i_id_lang_preferred,
                                   i_id_reason          => i_id_reason,
                                   i_id_origin          => i_id_origin,
                                   i_id_room            => i_id_room,
                                   i_id_schedule_ref    => i_id_schedule_ref,
                                   i_id_episode         => i_id_episode,
                                   i_reason_notes       => i_reason_notes,
                                   i_flg_request_type   => i_flg_request_type,
                                   i_flg_schedule_via   => i_flg_schedule_via,
                                   i_do_overlap         => i_do_overlap,
                                   i_id_consult_vac     => i_id_consult_vac,
                                   i_sch_option         => i_sch_option,
                                   i_id_consult_req     => i_id_consult_req,
                                   i_id_complaint       => i_id_complaint,
                                   i_id_institution     => i_id_institution,
                                   o_id_schedule        => o_id_schedule,
                                   o_flg_proceed        => o_flg_proceed,
                                   o_flg_show           => o_flg_show,
                                   o_msg                => o_msg,
                                   o_msg_title          => o_msg_title,
                                   o_button             => o_button,
                                   o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            l_nr_patients := i_id_patient.COUNT;
        
        ELSE
            l_tab_patients := l_tab_patients MULTISET UNION DISTINCT i_id_patient;
        
            g_error := 'GET ID_SCHEDULE FOR VANCANCY';
            SELECT s.id_schedule
              INTO l_id_schedule
              FROM schedule s
             WHERE s.id_sch_consult_vacancy = i_id_consult_vac
               AND s.flg_status = pk_schedule.g_status_scheduled;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
        
            g_error := 'CALL UPDATE_SCHEDULE';
            IF NOT update_schedule(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_id_schedule        => l_id_schedule,
                                   i_id_patient         => l_tab_patients,
                                   i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                   i_id_sch_event       => i_id_sch_event,
                                   i_id_prof            => i_id_prof,
                                   i_dt_begin           => i_dt_begin,
                                   i_dt_end             => i_dt_end,
                                   i_flg_vacancy        => i_flg_vacancy,
                                   i_schedule_notes     => i_schedule_notes,
                                   i_id_lang_translator => i_id_lang_translator,
                                   i_id_lang_preferred  => i_id_lang_preferred,
                                   i_id_reason          => i_id_reason,
                                   i_id_origin          => i_id_origin,
                                   i_id_room            => i_id_room,
                                   i_id_episode         => i_id_episode,
                                   i_reason_notes       => i_reason_notes,
                                   i_flg_request_type   => i_flg_request_type,
                                   i_flg_schedule_via   => i_flg_schedule_via,
                                   i_do_overlap         => i_do_overlap,
                                   i_id_consult_vac     => i_id_consult_vac,
                                   i_sch_option         => i_sch_option,
                                   i_id_complaint       => i_id_complaint,
                                   i_id_institution     => i_id_institution,
                                   i_transaction_id     => l_transaction_id,
                                   o_id_schedule        => o_id_schedule,
                                   o_flg_proceed        => o_flg_proceed,
                                   o_flg_show           => o_flg_show,
                                   o_msg                => o_msg,
                                   o_msg_title          => o_msg_title,
                                   o_button             => o_button,
                                   o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            l_nr_patients := l_tab_patients.COUNT;
        
        END IF;
    
        g_error := 'UPDATE USED_VACANCIES';
        UPDATE sch_consult_vacancy scv
           SET scv.used_vacancies = l_nr_patients
         WHERE scv.id_sch_consult_vacancy = i_id_consult_vac;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END create_schedule_pat;

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
    *
    * UPDATED: Group appointments validations   
    * @author   Sofia Mendes
    * @version  2.5.4
    * @since 2009/06/01
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
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_nr_free_vacs NUMBER;
        l_msg          VARCHAR2(4000);
        l_res          BOOLEAN;
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
    
        IF (i_id_sch_event = pk_schedule.g_event_group)
        THEN
        
            SELECT scv.max_vacancies - scv.used_vacancies
              INTO l_nr_free_vacs
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy = i_id_sch_consult_vacancy;
        
            IF (l_nr_free_vacs < i_tab_patients.COUNT)
            THEN
                o_msg         := pk_message.get_message(i_lang, 'SCH_T744') || chr(13) || chr(13);
                o_flg_proceed := g_yes;
                o_flg_show    := g_yes;
            
                o_button := pk_schedule.g_cancel_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                            pk_schedule.g_ok_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            
            END IF;
        END IF;
    
        IF (o_flg_proceed = g_yes)
        THEN
        
            l_res := pk_schedule.validate_reschedule(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_old_id_schedule  => i_old_id_schedule,
                                                     i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                     i_id_sch_event     => i_id_sch_event,
                                                     i_id_prof          => i_id_prof,
                                                     i_dt_begin         => i_dt_begin,
                                                     i_tab_patients     => i_tab_patients,
                                                     i_id_institution   => i_id_institution,
                                                     o_sv_stop          => o_sv_stop,
                                                     o_flg_proceed      => o_flg_proceed,
                                                     o_flg_show         => o_flg_show,
                                                     o_msg              => l_msg,
                                                     o_msg_title        => o_msg_title,
                                                     o_button           => o_button,
                                                     o_error            => o_error);
        
            IF (l_res = TRUE)
            THEN
                o_msg := o_msg || l_msg;
            END IF;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_reschedule;

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
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
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
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_HOURLY_DETAIL';
        l_list_schedules table_number;
        l_func_exception EXCEPTION;
    
        -- Inner function to retrieve the vacancies.
        FUNCTION inner_get_vacancies RETURN pk_types.cursor_type IS
            l_vacants pk_types.cursor_type;
        BEGIN
            g_error := 'OPEN l_vacants FOR';
            -- Open l_vacants
            OPEN l_vacants FOR
                SELECT /*+ first_rows */
                 id_sch_consult_vacancy,
                 pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                 pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                 id_sch_event,
                 id_prof id_prof,
                 (SELECT dcs.id_department
                    FROM dep_clin_serv dcs
                   WHERE dcs.id_dep_clin_serv = id_dcs) id_dep,
                 id_dcs id_dep_clin_serv,
                 max_vacancies,
                 used_vacancies,
                 max_vacancies - used_vacancies num_vacancies,
                 decode(flg_img,
                        ' ',
                        NULL,
                        lpad(rank, 6, 0) ||
                        pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img)) img_sched,
                 pk_schedule.string_dep_clin_serv(i_lang, id_dcs) desc_dcs,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof) nick_prof,
                 pk_schedule_common.get_translation_alias(i_lang, i_prof, id_sch_event, code_sch_event) desc_event,
                 pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                 pk_schedule.string_department(i_lang,
                                               (SELECT dcs.id_department
                                                  FROM dep_clin_serv dcs
                                                 WHERE dcs.id_dep_clin_serv = id_dcs)) desc_department,
                 pk_schedule.has_permission(i_lang, i_prof, id_dcs, id_sch_event, id_prof, i_args(idx_id_inst)) has_permission,
                 pk_schedule.is_vacancy_available(id_sch_consult_vacancy) flg_available
                  FROM (SELECT scv.id_sch_consult_vacancy,
                               scv.dt_begin_tstz,
                               scv.dt_end_tstz,
                               scv.id_sch_event,
                               scv.id_prof,
                               scv.id_dep_clin_serv id_dcs,
                               scv.max_vacancies,
                               scv.used_vacancies,
                               se.flg_img,
                               se.rank,
                               se.code_sch_event
                          FROM sch_tmptab_vacs stv
                          JOIN sch_consult_vacancy scv ON stv.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
                          JOIN sch_event se ON se.id_sch_event = scv.id_sch_event)
                 ORDER BY dt_begin_tstz, id_prof, id_dcs;
            RETURN l_vacants;
        END inner_get_vacancies;
    
        -- Inner function to get schedules
        FUNCTION inner_get_schedules(i_list_schedules table_number) RETURN pk_types.cursor_type IS
            l_schedules pk_types.cursor_type;
            l_cv        sys_config.VALUE%TYPE;
        BEGIN
            -- Telmo 25-07-2008
            g_error := 'GET CONFIG VALUE FOR FLG_CANCEL_SCHEDULE';
            IF NOT pk_sysconfig.get_config(pk_schedule_common.g_flg_cancel_schedule, i_prof, l_cv)
            THEN
                RAISE l_func_exception;
            END IF;
        
            g_error := 'OPEN l_schedules FOR';
            -- Open cursor
            OPEN l_schedules FOR
                SELECT /*+ first_rows */
                 id_schedule,
                 pk_date_utils.date_send_tsz(i_lang, dt_begin, i_prof) dt_begin,
                 pk_date_utils.date_send_tsz(i_lang, dt_end, i_prof) dt_end,
                 id_patient,
                 pk_patient.get_gender(i_lang, gender) AS gender,
                 pk_patient.get_pat_age(i_lang, id_patient, i_prof) age,
                 decode(pk_patphoto.check_blob(id_patient), g_no, '', pk_patphoto.get_pat_foto(id_patient, i_prof)) photo,
                 name,
                 pk_schedule.get_num_clin_record(id_patient, i_args(idx_id_inst)) num_clin_record,
                 lpad(rank, 6, 0) || pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img) img_sched,
                 id_sch_event,
                 pk_schedule.is_series_appointment(id_schedule) AS flg_series,
                 pk_schedule.get_repeatition_pat(id_schedule) AS flg_repeatition_pat,
                 pk_schedule.calc_icon(i_lang,
                                       id_schedule,
                                       id_instit_requested,
                                       id_dcs_requested,
                                       id_sch_event,
                                       dt_begin,
                                       dt_end,
                                       (SELECT id_professional
                                          FROM sch_resource sr
                                         WHERE sr.id_schedule = id_schedule
                                           AND rownum = 1),
                                       NULL,
                                       (CASE flg_status
                                           WHEN pk_schedule.g_sched_status_temporary THEN
                                            g_yes
                                           ELSE
                                            g_no
                                       END),
                                       flg_status,
                                       flg_vacancy,
                                       id_sch_consult_vacancy) img_schedule,
                 pk_schedule.g_icon_prefix ||
                 pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) img_notification,
                 flg_notification,
                 flg_status,
                 id_sch_consult_vacancy,
                 (SELECT dcs.id_department
                    FROM dep_clin_serv dcs
                   WHERE dcs.id_dep_clin_serv = id_dcs_requested) id_dep,
                 id_dcs_requested id_dep_clin_serv,
                 pk_schedule.string_language(i_lang, id_lang_translator) desc_lang_translator,
                 pk_schedule.string_duration(i_lang, dt_begin, dt_end) desc_duration,
                 pk_schedule.string_clin_serv_by_dcs(i_lang, id_dcs_requested) dcs_description,
                 pk_schedule.string_sch_event(i_lang, id_sch_event) event_description,
                 pk_schedule.string_sch_type(i_lang, flg_sch_type) desc_sch_type,
                 pk_schedule.string_department(i_lang,
                                               (SELECT dcs.id_department
                                                  FROM dep_clin_serv dcs
                                                 WHERE dcs.id_dep_clin_serv = id_dcs_requested)) desc_department,
                 pk_schedule.has_permission_by_schedule(i_lang,
                                                        i_prof,
                                                        id_dcs_requested,
                                                        id_sch_event,
                                                        id_schedule,
                                                        i_args(idx_id_inst)) has_permission,
                 pk_schedule.is_conflicting(id_schedule) flg_conflict,
                 l_cv flg_cancel_schedule,
                 (CASE
                      WHEN idscd IS NULL THEN
                       NULL
                      ELSE
                       (SELECT d.id_sch_combi
                          FROM sch_combi_detail d
                         WHERE d.id_sch_combi_detail = idscd)
                  END) id_combi,
                 pk_schedule.get_count_and_rank(i_lang, id_schedule) AS count_and_rank
                  FROM (SELECT vso.id_schedule,
                               vso.dt_begin,
                               vso.dt_end,
                               sg.id_patient,
                               pat.gender,
                               pat.name,
                               se.rank,
                               se.flg_img,
                               vso.id_sch_event,
                               vso.flg_status,
                               vso.flg_vacancy,
                               vso.flg_notification,
                               vso.id_dcs_requested,
                               vso.id_lang_translator,
                               vso.id_sch_consult_vacancy,
                               vso.id_sch_combi_detail idscd,
                               vso.id_instit_requested,
                               vso.flg_sch_type
                          FROM v_schedule_outp vso, sch_group sg, sch_event se, patient pat, dep_clin_serv dcs
                         WHERE se.id_sch_event = vso.id_sch_event
                           AND sg.id_schedule(+) = vso.id_schedule
                           AND pat.id_patient(+) = sg.id_patient
                           AND dcs.id_dep_clin_serv = vso.id_dcs_requested
                           AND vso.id_schedule IN (SELECT *
                                                     FROM TABLE(i_list_schedules)))
                
                 ORDER BY dt_begin, id_dcs_requested, flg_status, flg_vacancy;
        
            RETURN l_schedules;
        END inner_get_schedules;
    
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_VACANCIES';
        -- Get vacancies' identifiers using the selected criteria.
        IF NOT
            pk_schedule_common.get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => i_args, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL INNER_GET_VACANCIES';
        -- Get vacancies
        o_vacants := inner_get_vacancies();
    
        IF pk_schedule.get_only_vacs(i_args(idx_status)) = g_yes
        THEN
            pk_types.open_my_cursor(o_schedules);
        ELSE
            g_error := 'CALL GET_SCHEDULES';
            -- Get schedules' identifiers using the selected criteria.
            IF NOT pk_schedule_common.get_schedules(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_patient => NULL,
                                                    i_args       => i_args,
                                                    o_schedules  => l_list_schedules,
                                                    o_error      => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL INNER_GET_SHEDULES';
            -- Get schedules
            o_schedules := inner_get_schedules(i_list_schedules => l_list_schedules);
        END IF;
    
        g_error := 'CALL PK_SCHEDULE_COMMON.GET_PROF_LIST';
        IF NOT pk_schedule_common.get_prof_list(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_schedules => l_list_schedules,
                                                o_prof_list => o_professionals,
                                                o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_PATIENT_ICONS';
        pk_date_utils.set_dst_time_check_on;
        -- Get patient icons
        RETURN pk_schedule.get_patient_icons(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_args          => i_args,
                                             i_id_patient    => i_id_patient,
                                             o_patient_icons => o_patient_icons,
                                             o_error         => o_error);
    EXCEPTION
        WHEN l_func_exception THEN
            pk_date_utils.set_dst_time_check_off;
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_date_utils.set_dst_time_check_off;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_vacants);
            pk_types.open_my_cursor(o_schedules);
            pk_types.open_my_cursor(o_patient_icons);
            RETURN FALSE;
        
    END get_hourly_detail;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_RESCHEDULE_PAT';
    
        l_tab_patients_old      table_number := table_number();
        l_tab_patients_dest     table_number := table_number();
        l_tab_sch               table_number := table_number();
        l_schedule_cancel_notes schedule.schedule_notes%TYPE;
        l_func_exception EXCEPTION;
    
        l_nr_patients NUMBER;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   s.id_room,
                   s.id_dcs_requested,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   s.id_sch_event,
                   s.flg_vacancy,
                   s.schedule_notes,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_episode,
                   s.reason_notes,
                   s.flg_request_type,
                   s.flg_schedule_via,
--                   s.id_complaint,
                   s.id_sch_consult_vacancy,
                   sr.id_professional
              FROM schedule s
              LEFT JOIN sch_resource sr ON s.id_schedule = sr.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule;
    
        l_sched_rec_old c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'GET PATIENTS FROM OLD SCHEDULE';
        SELECT sg.id_patient BULK COLLECT
          INTO l_tab_patients_old
          FROM schedule s
          LEFT JOIN sch_group sg ON s.id_schedule = sg.id_schedule
         WHERE s.id_schedule = i_old_id_schedule;
    
        g_error         := 'GET OLD SCHEDULE DATA';
        l_sched_rec_old := inner_get_old_schedule(i_old_id_schedule);
    
        IF (l_tab_patients_old.COUNT != i_id_patients.COUNT)
        THEN
        
            l_tab_patients_old := l_tab_patients_old MULTISET except DISTINCT i_id_patients;
        
            --update first app
            g_error := 'UPDATE OLD SCHEDULE';
            IF NOT update_schedule(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_id_schedule        => i_old_id_schedule,
                                   i_id_patient         => l_tab_patients_old,
                                   i_id_dep_clin_serv   => l_sched_rec_old.id_dcs_requested,
                                   i_id_sch_event       => l_sched_rec_old.id_sch_event,
                                   i_id_prof            => l_sched_rec_old.id_professional,
                                   i_dt_begin           => pk_date_utils.date_send_tsz(i_lang,
                                                                                       l_sched_rec_old.dt_begin_tstz,
                                                                                       i_prof),
                                   i_dt_end             => pk_date_utils.date_send_tsz(i_lang,
                                                                                       l_sched_rec_old.dt_end_tstz,
                                                                                       i_prof),
                                   i_flg_vacancy        => l_sched_rec_old.flg_vacancy,
                                   i_schedule_notes     => l_sched_rec_old.schedule_notes,
                                   i_id_lang_translator => l_sched_rec_old.id_lang_translator,
                                   i_id_lang_preferred  => l_sched_rec_old.id_lang_preferred,
                                   i_id_reason          => l_sched_rec_old.id_reason,
                                   i_id_origin          => l_sched_rec_old.id_origin,
                                   i_id_room            => l_sched_rec_old.id_room,
                                   i_id_episode         => l_sched_rec_old.id_episode,
                                   i_reason_notes       => l_sched_rec_old.reason_notes,
                                   i_flg_request_type   => l_sched_rec_old.flg_request_type,
                                   i_flg_schedule_via   => l_sched_rec_old.flg_schedule_via,
                                   i_do_overlap         => i_do_overlap,
                                   i_id_consult_vac     => l_sched_rec_old.id_sch_consult_vacancy,
                                   i_sch_option         => i_sch_option,
                                   i_id_complaint       => null,
                                   i_id_institution     => i_id_institution,
                                   i_transaction_id     => l_transaction_id,
                                   o_id_schedule        => o_id_schedule,
                                   o_flg_proceed        => o_flg_proceed,
                                   o_flg_show           => o_flg_show,
                                   o_msg                => o_msg,
                                   o_msg_title          => o_msg_title,
                                   o_button             => o_button,
                                   o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL GET_STRING_TSTZ FOR current_timestamp';
        
            IF NOT pk_schedule.get_cancel_notes_msg(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_dt_begin              => i_dt_begin,
                                                    o_schedule_cancel_notes => l_schedule_cancel_notes,
                                                    o_error                 => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            -- cancel all appointment
            g_error := 'CALL PK_SCHEDULE.UPDATE_SCHEDULE';
            IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_old_id_schedule,
                                               i_id_cancel_reason => NULL,
                                               i_cancel_notes     => l_schedule_cancel_notes,
                                               io_transaction_id  => l_transaction_id,
                                               o_error            => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'UPDATE USED_VACANCIES';
            UPDATE sch_consult_vacancy scv
               SET scv.used_vacancies = 0
             WHERE scv.id_sch_consult_vacancy = l_sched_rec_old.id_sch_consult_vacancy;
        
        END IF;
    
        g_error := 'GET PATIENTS FROM DESTINY SCHEDULE';
        SELECT sg.id_patient, s.id_schedule BULK COLLECT
          INTO l_tab_patients_dest, l_tab_sch
          FROM schedule s
          LEFT JOIN sch_group sg ON s.id_schedule = sg.id_schedule
          JOIN sch_consult_vacancy scv ON s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
         WHERE scv.id_sch_consult_vacancy = i_id_consult_vac
           AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
    
        g_error         := 'GET DEST SCHEDULE DATA';
        l_sched_rec_old := inner_get_old_schedule(i_old_id_schedule);
    
        IF (l_tab_patients_dest.COUNT > 0)
        THEN
            --update
            l_tab_patients_dest := l_tab_patients_dest MULTISET UNION i_id_patients;
        
            g_error := 'UPDATE OLD SCHEDULE';
            IF NOT update_schedule(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_id_schedule        => l_tab_sch(1),
                                   i_id_patient         => l_tab_patients_dest,
                                   i_id_dep_clin_serv   => l_sched_rec_old.id_dcs_requested,
                                   i_id_sch_event       => l_sched_rec_old.id_sch_event,
                                   i_id_prof            => l_sched_rec_old.id_professional,
                                   i_dt_begin           => i_dt_begin,
                                   i_dt_end             => i_dt_end,
                                   i_flg_vacancy        => l_sched_rec_old.flg_vacancy,
                                   i_schedule_notes     => l_sched_rec_old.schedule_notes,
                                   i_id_lang_translator => l_sched_rec_old.id_lang_translator,
                                   i_id_lang_preferred  => l_sched_rec_old.id_lang_preferred,
                                   i_id_reason          => l_sched_rec_old.id_reason,
                                   i_id_origin          => l_sched_rec_old.id_origin,
                                   i_id_room            => l_sched_rec_old.id_room,
                                   i_id_episode         => l_sched_rec_old.id_episode,
                                   i_reason_notes       => l_sched_rec_old.reason_notes,
                                   i_flg_request_type   => l_sched_rec_old.flg_request_type,
                                   i_flg_schedule_via   => l_sched_rec_old.flg_schedule_via,
                                   i_do_overlap         => i_do_overlap,
                                   i_id_consult_vac     => i_id_consult_vac,
                                   i_sch_option         => i_sch_option,
                                   i_id_complaint       => null,
                                   i_id_institution     => i_id_institution,
                                   i_transaction_id     => l_transaction_id,
                                   o_id_schedule        => o_id_schedule,
                                   o_flg_proceed        => o_flg_proceed,
                                   o_flg_show           => o_flg_show,
                                   o_msg                => o_msg,
                                   o_msg_title          => o_msg_title,
                                   o_button             => o_button,
                                   o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        ELSE
            -- create sch
            g_error := 'CALL PK_SCHEDULE_OUTP.CREATE_SCHEDULE';
            IF NOT
                pk_schedule_outp.create_schedule(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_patient         => i_id_patients,
                                                 i_id_dep_clin_serv   => l_sched_rec_old.id_dcs_requested,
                                                 i_id_sch_event       => l_sched_rec_old.id_sch_event,
                                                 i_id_prof            => l_sched_rec_old.id_professional,
                                                 i_dt_begin           => i_dt_begin,
                                                 i_dt_end             => i_dt_end,
                                                 i_flg_vacancy        => l_sched_rec_old.flg_vacancy,
                                                 i_schedule_notes     => l_sched_rec_old.schedule_notes,
                                                 i_id_lang_translator => l_sched_rec_old.id_lang_translator,
                                                 i_id_lang_preferred  => l_sched_rec_old.id_lang_preferred,
                                                 i_id_reason          => l_sched_rec_old.id_reason,
                                                 i_id_origin          => l_sched_rec_old.id_origin,
                                                 i_id_room            => l_sched_rec_old.id_room,
                                                 i_id_episode         => l_sched_rec_old.id_episode,
                                                 i_reason_notes       => l_sched_rec_old.reason_notes,
                                                 i_flg_request_type   => l_sched_rec_old.flg_request_type,
                                                 i_flg_schedule_via   => l_sched_rec_old.flg_schedule_via,
                                                 i_do_overlap         => i_do_overlap,
                                                 i_id_consult_vac     => i_id_consult_vac,
                                                 i_sch_option         => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                                 i_id_schedule_ref    => i_old_id_schedule,
                                                 i_id_complaint       => null,
                                                 i_id_institution     => i_id_institution,
                                                 o_id_schedule        => o_id_schedule,
                                                 o_flg_proceed        => o_flg_proceed,
                                                 o_flg_show           => o_flg_show,
                                                 o_msg                => o_msg,
                                                 o_msg_title          => o_msg_title,
                                                 o_button             => o_button,
                                                 o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            l_nr_patients := i_id_patients.COUNT;
            g_error       := 'UPDATE USED_VACANCIES';
            UPDATE sch_consult_vacancy scv
               SET scv.used_vacancies = l_nr_patients
             WHERE scv.id_sch_consult_vacancy = i_id_consult_vac;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_reschedule_pat;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_ret       BOOLEAN;
        l_dt_begin  TIMESTAMP WITH TIME ZONE;
        l_func_exception EXCEPTION;
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT vso.id_schedule,
                   sg.id_patient,
                   vso.id_dcs_requested,
                   vso.id_sch_event,
                   spo.id_professional,
                   vso.dt_begin_tstz,
                   vso.schedule_notes
              FROM v_schedule_outp vso, sch_prof_outp spo, sch_group sg
             WHERE vso.id_schedule = c_sched.i_old_id_schedule
               AND sg.id_schedule = vso.id_schedule
               AND vso.id_schedule_outp = spo.id_schedule_outp(+);
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    BEGIN
        o_flg_proceed := g_no;
        o_flg_show    := g_no;
    
        g_error := 'CREATE RESCHEDULE';
        -- Call the generic reschedule function.
        IF NOT pk_schedule.create_reschedule(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_old_id_schedule => i_old_id_schedule,
                                             i_id_prof         => i_id_prof,
                                             i_dt_begin        => i_dt_begin,
                                             i_dt_end          => i_dt_end,
                                             i_do_overlap      => i_do_overlap,
                                             i_id_consult_vac  => i_id_consult_vac,
                                             i_sch_option      => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                             i_id_institution  => i_id_institution,
                                             o_id_schedule     => o_id_schedule,
                                             o_flg_show        => o_flg_show,
                                             o_flg_proceed     => o_flg_proceed,
                                             o_msg             => o_msg,
                                             o_msg_title       => o_msg_title,
                                             o_button          => o_button,
                                             o_error           => o_error)
        
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'GET TIMESTAMP';
        -- Convert string to timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'GET OLD SCHEDULE';
        -- Get old schedule
        l_sched_rec := inner_get_old_schedule(i_old_id_schedule);
    
        g_error := 'CREATE SCHEDULE OUTP';
        -- Create outpatient-specific data.
        IF NOT create_schedule_outp(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_id_schedule      => o_id_schedule,
                                    i_id_patient       => l_sched_rec.id_patient,
                                    i_id_dep_clin_serv => l_sched_rec.id_dcs_requested,
                                    i_id_sch_event     => l_sched_rec.id_sch_event,
                                    i_id_prof          => l_sched_rec.id_professional,
                                    i_dt_begin         => l_dt_begin,
                                    i_schedule_notes   => l_sched_rec.schedule_notes,
                                    i_id_episode       => NULL,
                                    i_id_institution   => i_id_institution,
                                    o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_reschedule;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'VALIDATE_MULT_RESCHEDULE';
    BEGIN
        RETURN pk_schedule.validate_mult_reschedule(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_schedules        => i_schedules,
                                                    i_id_prof          => i_id_prof,
                                                    i_dt_begin         => i_dt_begin,
                                                    i_dt_end           => i_dt_end,
                                                    i_id_dep           => i_id_dep,
                                                    i_id_dep_clin_serv => i_id_dep_clin_serv,
                                                    i_id_event         => i_id_event,
                                                    o_list_sch_hour    => o_list_sch_hour,
                                                    o_flg_proceed      => o_flg_proceed,
                                                    o_flg_show         => o_flg_show,
                                                    o_msg              => o_msg,
                                                    o_msg_title        => o_msg_title,
                                                    o_button           => o_button,
                                                    o_error            => o_error);
    END validate_mult_reschedule;

    /*
    * Reschedules several appointments.
    * 
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_prof            Target professional.
    * @param i_schedules          List of schedules.
    * @param i_start_dates        List of start dates.
    * @param i_end_dates          List of end dates.
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be 
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CREATE_MULT_RESCHEDULE';
        l_id_schedule schedule.id_schedule%TYPE;
        l_flg_show    VARCHAR2(1);
        l_flg_proceed VARCHAR2(1);
        l_msg         VARCHAR2(32000);
        l_msg_title   VARCHAR2(32000);
        l_button      VARCHAR2(200);
        l_func_exception EXCEPTION;
    BEGIN
        -- Iterate on schedules
        g_error := 'ITERATE ON SCHEDULES';
        FOR idx IN i_schedules.FIRST .. i_schedules.LAST
        LOOP
            -- Reschedule each appointment
            IF NOT create_reschedule(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_old_id_schedule => i_schedules(idx),
                                     i_id_prof         => i_id_prof,
                                     i_dt_begin        => i_start_dates(idx),
                                     i_dt_end          => i_end_dates(idx),
                                     i_do_overlap      => i_do_overlap,
                                     i_sch_option      => i_sch_option,
                                     i_id_consult_vac  => i_ids_cons_vac(idx),
                                     o_id_schedule     => l_id_schedule,
                                     o_flg_show        => l_flg_show,
                                     o_flg_proceed     => l_flg_proceed,
                                     o_msg             => l_msg,
                                     o_msg_title       => l_msg_title,
                                     o_button          => l_button,
                                     o_error           => o_error)
            THEN
                -- Reset state
                RAISE l_func_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_mult_reschedule;

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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'VALIDATE_SCHEDULE_MULT';
        l_msg         VARCHAR2(4000) := NULL;
        l_msg_title   VARCHAR2(4000) := NULL;
        l_button      VARCHAR2(4000) := NULL;
        l_flg_show    VARCHAR2(1) := NULL;
        l_flg_proceed VARCHAR2(1) := NULL;
    BEGIN
        g_error := 'CALL VALIDATE_SCHEDULE_MULT';
        -- Perform validations that are specific to the multi-search creation and get a valid vacancy if possible
        IF NOT pk_schedule.validate_schedule_mult(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_args         => i_args,
                                                  i_sch_args     => i_sch_args,
                                                  i_flg_sch_type => pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                                  o_dt_begin     => o_dt_begin,
                                                  o_dt_end       => o_dt_end,
                                                  o_flg_proceed  => o_flg_proceed,
                                                  o_flg_show     => o_flg_show,
                                                  o_msg          => o_msg,
                                                  o_msg_title    => o_msg_title,
                                                  o_button       => o_button,
                                                  o_flg_vacancy  => o_flg_vacancy,
                                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF (o_flg_proceed = g_yes)
        THEN
            -- It is possible to create an appointment, that is, a vacancy exists and all search
            -- parameters are valid.
        
            -- Perform additional validations (semantics)
            g_error := 'CALL VALIDATE_SCHEDULE';
            IF NOT validate_schedule(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_id_patient       => i_sch_args(idx_sch_args_patient),
                                     i_id_dep_clin_serv => i_sch_args(idx_sch_args_dcs),
                                     i_id_sch_event     => i_sch_args(idx_sch_args_event),
                                     i_id_prof          => i_sch_args(idx_sch_args_prof),
                                     i_dt_begin         => o_dt_begin,
                                     o_flg_proceed      => l_flg_proceed,
                                     o_flg_show         => l_flg_show,
                                     o_msg              => l_msg,
                                     o_msg_title        => l_msg_title,
                                     o_button           => l_button,
                                     o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_flg_show = g_yes
               AND l_flg_proceed = g_yes
            THEN
                -- Combine both messages (some warning needs to be shown)
                g_error := 'COMBINE BOTH MESSAGES';
                -- Join messages
                o_msg_title := pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            
                o_msg    := '<b>' || pk_schedule.get_message(i_lang, pk_schedule.g_sched_mult_problems) || '</b>' ||
                            chr(13) || l_msg || chr(13) || chr(13) || '<b>' ||
                            pk_schedule.get_message(i_lang, pk_schedule.g_sched_mult_confirmation) || '</b>' || chr(13) ||
                            o_msg;
                o_button := pk_schedule.g_cancel_button_code ||
                            pk_schedule.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                            pk_schedule.g_ok_button_code ||
                            pk_schedule.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            
            ELSIF l_flg_proceed = g_yes
            THEN
                -- Use the multi-search message only as the validate_schedule call did not generate a warning
                NULL;
            ELSIF l_flg_show = g_yes
            THEN
                -- Use the last message only as it is a critical error.
                o_flg_proceed := l_flg_proceed;
                o_flg_show    := l_flg_show;
                o_msg         := l_msg;
                o_button      := l_button;
                o_msg_title   := l_msg_title;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_schedule_mult;

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
    *
    * UPDATED
    * update of id_schedule_recursion field
    * @author  Sofia Mendes
    * @version 2.5.0.5
    * @date    04-09-2009 
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
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
        l_func_exception EXCEPTION;
        l_nr_patients  NUMBER;
        l_pat_referral p1_external_request.id_external_request%TYPE := NULL;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule, s.id_schedule_recursion, s.flg_status, s.id_episode
              FROM schedule s
             WHERE s.id_schedule = c_sched.i_old_id_schedule;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
        -- Get old schedule
        g_error     := 'GET OLD SCHEDULE';
        l_sched_rec := inner_get_old_schedule(i_id_schedule);
    
        g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_schedule;
        IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_id_schedule         => i_id_schedule,
                                                   o_id_external_request => l_pat_referral,
                                                   o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- get cancel notes message
        l_schedule_cancel_notes := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => g_update_schedule);
        -- cancel schedule
        g_error := 'CALL CANCEL SCHEDULE';
        IF NOT pk_schedule.cancel_schedule_old(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_id_schedule,
                                               i_id_cancel_reason => i_id_cancel_reason,
                                               i_cancel_notes     => l_schedule_cancel_notes,
                                               o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- create a new schedule
        g_error := 'CALL PK_SCHEDULE_OUTP.CREATE_SCHEDULE';
        IF NOT
            pk_schedule_outp.create_schedule(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_patient            => i_id_patient,
                                             i_id_dep_clin_serv      => i_id_dep_clin_serv,
                                             i_id_sch_event          => i_id_sch_event,
                                             i_id_prof               => i_id_prof,
                                             i_dt_begin              => i_dt_begin,
                                             i_dt_end                => i_dt_end,
                                             i_flg_vacancy           => i_flg_vacancy,
                                             i_schedule_notes        => i_schedule_notes,
                                             i_id_lang_translator    => i_id_lang_translator,
                                             i_id_lang_preferred     => i_id_lang_preferred,
                                             i_id_reason             => i_id_reason,
                                             i_id_origin             => i_id_origin,
                                             i_id_room               => i_id_room,
                                             i_id_episode            => i_id_episode,
                                             i_reason_notes          => i_reason_notes,
                                             i_flg_request_type      => i_flg_request_type,
                                             i_flg_schedule_via      => i_flg_schedule_via,
                                             i_do_overlap            => i_do_overlap,
                                             i_id_consult_vac        => i_id_consult_vac,
                                             i_sch_option            => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                             i_id_schedule_ref       => i_id_schedule,
                                             i_id_complaint          => i_id_complaint,
                                             i_id_institution        => i_id_institution,
                                             i_id_schedule_recursion => l_sched_rec.id_schedule_recursion,
                                             i_flg_status            => l_sched_rec.flg_status,
                                             o_id_schedule           => o_id_schedule,
                                             o_flg_proceed           => o_flg_proceed,
                                             o_flg_show              => o_flg_show,
                                             o_msg                   => o_msg,
                                             o_msg_title             => o_msg_title,
                                             o_button                => o_button,
                                             o_error                 => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF (o_flg_show = g_yes)
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        IF (i_id_sch_event = pk_schedule.g_event_group)
        THEN
            l_nr_patients := i_id_patient.COUNT;
        
            g_error := 'UPDATE USED_VACANCIES';
            UPDATE sch_consult_vacancy scv
               SET scv.used_vacancies = l_nr_patients
             WHERE scv.id_sch_consult_vacancy = i_id_consult_vac;
        END IF;
    
        --update referral status   
        IF (l_pat_referral IS NOT NULL)
        THEN
            g_error := 'CALL TO pk_ref_service.set_ref_schedule with id_schedule=' || i_id_schedule ||
                       ' and id_referral=' || l_pat_referral;
            IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_ref   => l_pat_referral,
                                                   i_schedule => o_id_schedule,
                                                   i_notes    => NULL,
                                                   i_episode  => l_sched_rec.id_episode,
                                                   o_error    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        COMMIT;
        
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END update_schedule;

    /**
    * Updates outpatient schedule. Also used for private practice. Integration version
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
    *
    * UPDATED
    * update of id_schedule_recursion field
    * @author  Sofia Mendes
    * @version 2.5.0.5
    * @date    04-09-2009
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
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
        l_func_exception EXCEPTION;
        l_nr_patients NUMBER;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule, s.id_schedule_recursion, s.flg_status
              FROM schedule s
             WHERE s.id_schedule = c_sched.i_old_id_schedule;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
    
        -- Get old schedule
        g_error     := 'GET OLD SCHEDULE';
        l_sched_rec := inner_get_old_schedule(i_id_schedule);
    
        -- get cancel notes message
        l_schedule_cancel_notes := pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => g_update_schedule);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- cancel schedule
        g_error := 'CALL CANCEL SCHEDULE';
        IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_schedule      => i_id_schedule,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_cancel_notes     => l_schedule_cancel_notes,
                                           io_transaction_id  => l_transaction_id,
                                           o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- create a new schedule
        g_error := 'CALL PK_SCHEDULE_OUTP.CREATE_SCHEDULE';
        IF NOT
            pk_schedule_outp.create_schedule(i_lang                  => i_lang,
                                             i_prof                  => i_prof,
                                             i_id_patient            => i_id_patient,
                                             i_id_dep_clin_serv      => i_id_dep_clin_serv,
                                             i_id_sch_event          => i_id_sch_event,
                                             i_id_prof               => i_id_prof,
                                             i_dt_begin              => i_dt_begin,
                                             i_dt_end                => i_dt_end,
                                             i_flg_vacancy           => i_flg_vacancy,
                                             i_schedule_notes        => i_schedule_notes,
                                             i_id_lang_translator    => i_id_lang_translator,
                                             i_id_lang_preferred     => i_id_lang_preferred,
                                             i_id_reason             => i_id_reason,
                                             i_id_origin             => i_id_origin,
                                             i_id_room               => i_id_room,
                                             i_id_episode            => i_id_episode,
                                             i_reason_notes          => i_reason_notes,
                                             i_flg_request_type      => i_flg_request_type,
                                             i_flg_schedule_via      => i_flg_schedule_via,
                                             i_do_overlap            => i_do_overlap,
                                             i_id_consult_vac        => i_id_consult_vac,
                                             i_sch_option            => nvl(i_sch_option, pk_schedule.g_sch_option_update),
                                             i_id_schedule_ref       => i_id_schedule,
                                             i_id_complaint          => i_id_complaint,
                                             i_id_institution        => i_id_institution,
                                             i_id_schedule_recursion => l_sched_rec.id_schedule_recursion,
                                             i_flg_status            => l_sched_rec.flg_status,
                                             o_id_schedule           => o_id_schedule,
                                             o_flg_proceed           => o_flg_proceed,
                                             o_flg_show              => o_flg_show,
                                             o_msg                   => o_msg,
                                             o_msg_title             => o_msg_title,
                                             o_button                => o_button,
                                             o_error                 => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF (i_id_sch_event = pk_schedule.g_event_group)
        THEN
            l_nr_patients := i_id_patient.COUNT;
        
            g_error := 'UPDATE USED_VACANCIES';
            UPDATE sch_consult_vacancy scv
               SET scv.used_vacancies = l_nr_patients
             WHERE scv.id_sch_consult_vacancy = i_id_consult_vac;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_schedule;

    /**
    * Cancels a pacient appointment or a group of patient appointments in a group.
    * Cancels the schedule if all the pacients are cancelled or removes the given pacients from the schedule if only
    * some of the pacients are cancelled.
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
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(32) := 'CANCEL_SCHEDULE_GROUP';
        l_tab_patients       table_number;
        l_nr_patients        NUMBER;
        l_id_consult_vacancy schedule.id_sch_consult_vacancy%TYPE;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   s.id_room,
                   s.id_dcs_requested,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   s.id_sch_event,
                   s.flg_vacancy,
                   s.schedule_notes,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_episode,
                   s.reason_notes,
                   s.flg_request_type,
                   s.flg_schedule_via,
                   s.id_sch_consult_vacancy,
                   sr.id_professional
              FROM schedule s
              LEFT JOIN sch_resource sr ON s.id_schedule = sr.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        -- select patients
        g_error := 'SELECT PATIENTS';
        SELECT sg.id_patient BULK COLLECT
          INTO l_tab_patients
          FROM schedule s
          JOIN sch_consult_vacancy scv ON s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
          LEFT JOIN sch_group sg ON s.id_schedule = sg.id_schedule
          LEFT JOIN sch_event se ON s.Id_Sch_Event = se.id_sch_event
         WHERE se.flg_is_group = pk_alert_constant.g_yes
           AND s.flg_status != pk_schedule.g_status_canceled
              --AND s.flg_sch_type = 'C'
           AND s.id_schedule = i_id_schedule;
    
        l_tab_patients := l_tab_patients MULTISET except DISTINCT i_id_patients;
    
        IF l_tab_patients.COUNT > 0
        THEN
            -- Get old schedule
            g_error     := 'GET OLD SCHEDULE';
            l_sched_rec := inner_get_old_schedule(i_id_schedule);
        
            g_error := 'CALL UPDATE_SCHEDULE';
            IF NOT update_schedule(i_lang               => i_lang,
                                   i_prof               => i_prof,
                                   i_id_schedule        => i_id_schedule,
                                   i_id_patient         => l_tab_patients,
                                   i_id_dep_clin_serv   => l_sched_rec.id_dcs_requested,
                                   i_id_sch_event       => l_sched_rec.id_sch_event,
                                   i_id_prof            => l_sched_rec.id_professional,
                                   i_dt_begin           => pk_date_utils.date_send_tsz(i_lang,
                                                                                       l_sched_rec.dt_begin_tstz,
                                                                                       i_prof),
                                   i_dt_end             => pk_date_utils.date_send_tsz(i_lang,
                                                                                       l_sched_rec.dt_end_tstz,
                                                                                       i_prof),
                                   i_flg_vacancy        => l_sched_rec.flg_vacancy,
                                   i_schedule_notes     => l_sched_rec.schedule_notes,
                                   i_id_lang_translator => l_sched_rec.id_lang_translator,
                                   i_id_lang_preferred  => l_sched_rec.id_lang_preferred,
                                   i_id_reason          => l_sched_rec.id_reason,
                                   i_id_origin          => l_sched_rec.id_origin,
                                   i_id_room            => l_sched_rec.id_room,
                                   i_id_episode         => l_sched_rec.id_episode,
                                   i_reason_notes       => l_sched_rec.reason_notes,
                                   i_flg_request_type   => l_sched_rec.flg_request_type,
                                   i_flg_schedule_via   => l_sched_rec.flg_schedule_via,
                                   i_do_overlap         => g_no,
                                   i_id_consult_vac     => l_sched_rec.id_sch_consult_vacancy,
                                   i_sch_option         => pk_schedule.g_with_vacant, --'V'
                                   i_id_complaint       => null,
                                   i_id_cancel_reason   => i_id_cancel_reason,
                                   i_transaction_id     => l_transaction_id,
                                   o_id_schedule        => o_id_schedule,
                                   o_flg_proceed        => o_flg_proceed,
                                   o_flg_show           => o_flg_show,
                                   o_msg                => o_msg,
                                   o_msg_title          => o_msg_title,
                                   o_button             => o_button,
                                   o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
                /* ELSE
                IF (o_flg_proceed = g_no)
                THEN
                    ROLLBACK;
                END IF;*/
            END IF;
        ELSE
            g_error := 'CALL PK_SCHEDULE.UPDATE_SCHEDULE';
            IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_id_schedule,
                                               i_id_cancel_reason => i_id_cancel_reason,
                                               io_transaction_id  => l_transaction_id,
                                               o_error            => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            SELECT s.id_sch_consult_vacancy
              INTO l_id_consult_vacancy
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule
               AND rownum = 1;
        
            g_error := 'UPDATE USED_VACANCIES';
            UPDATE sch_consult_vacancy scv
               SET scv.used_vacancies = 0
             WHERE scv.id_sch_consult_vacancy = l_id_consult_vacancy;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END cancel_schedule_group;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_COMBINATION';
        l_dt_before sch_combi.dt_sch_before%TYPE;
        l_dt_after  sch_combi.dt_sch_after%TYPE;
    BEGIN
        -- Convert before date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_before';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_before,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_before,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert after date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_after';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_after,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_after,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --set pk
        SELECT nvl(i_id_combi, seq_sch_combi.NEXTVAL)
          INTO o_id_combi
          FROM dual;
    
        --insert
        g_error := 'MERGE COMBINATION';
        MERGE INTO sch_combi c
        USING (SELECT i_id_combi iic
                 FROM dual) d
        ON (c.id_sch_combi = d.iic)
        WHEN NOT MATCHED THEN
            INSERT
                (id_sch_combi,
                 combi_name,
                 dt_sch_before,
                 dt_sch_after,
                 id_inst_target,
                 priority,
                 notes,
                 id_patient,
                 id_prof_requests,
                 dt_request_date)
            VALUES
                (o_id_combi,
                 i_combi_name,
                 l_dt_before,
                 l_dt_after,
                 i_id_target_inst,
                 i_priority,
                 i_notes,
                 i_id_patient,
                 i_id_prof_req,
                 g_sysdate_tstz)
        WHEN MATCHED THEN
            UPDATE
               SET c.combi_name       = i_combi_name,
                   c.dt_sch_before    = l_dt_before,
                   c.dt_sch_after     = l_dt_after,
                   c.id_inst_target   = i_id_target_inst,
                   c.priority         = i_priority,
                   c.notes            = i_notes,
                   c.id_patient       = i_id_patient,
                   c.id_prof_requests = i_id_prof_req;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_combination;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_COMBI_LINE';
    BEGIN
    
        --insert
        g_error := 'MERGE COMBINATION DETAIL LINE';
        MERGE INTO sch_combi_detail c
        USING (SELECT i_id_combi iic, i_id_code iicod
                 FROM dual) d
        ON (c.id_sch_combi = d.iic AND c.id_code = d.iicod)
        WHEN NOT MATCHED THEN
            INSERT
                (id_sch_combi,
                 id_code,
                 id_sch_combi_detail,
                 id_sch_event,
                 id_dep_clin_serv,
                 id_exam,
                 dep_type,
                 id_code_parent,
                 min_time_after,
                 max_time_after,
                 flg_optional)
            VALUES
                (i_id_combi,
                 i_id_code,
                 seq_sch_combi_detail.NEXTVAL,
                 i_id_event,
                 i_id_dcs,
                 i_id_exam,
                 i_dep_type,
                 i_id_code_parent,
                 i_min_time_after,
                 i_max_time_after,
                 i_flg_optional)
        WHEN MATCHED THEN
            UPDATE
               SET id_sch_event     = i_id_event,
                   id_dep_clin_serv = i_id_dcs,
                   id_exam          = i_id_exam,
                   dep_type         = i_dep_type,
                   id_code_parent   = i_id_code_parent,
                   min_time_after   = i_min_time_after,
                   max_time_after   = i_max_time_after,
                   flg_optional     = i_flg_optional;
    
        -- insert profs
        g_error := 'MERGE PROFS';
        IF i_id_profs IS NOT NULL
           AND i_id_profs.COUNT > 0
        THEN
            MERGE INTO sch_combi_profs c
            USING (SELECT i_id_combi iic, i_id_code iicod, column_value iip
                     FROM TABLE(i_id_profs)) d
            ON (c.id_sch_combi = d.iic AND c.id_code = d.iicod AND c.id_prof = d.iip)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_sch_combi, id_code, id_prof)
                VALUES
                    (d.iic, d.iicod, d.iip);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_combi_line;

    /*
    *  delete a detail line of a combination. if there a schedule attached returns error
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
    *
    */
    FUNCTION delete_combi_detail
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_detail.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_detail.id_code%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'DELETE_COMBI_DETAIL';
    BEGIN
        -- first delete profs for this detail
        g_error := 'DELETE DETAIL PROFS';
        DELETE sch_combi_profs s
         WHERE s.id_sch_combi = i_id_sch_combi
           AND s.id_code = i_id_code;
    
        -- delete detail. Pode falhar se existir na schedule um registo com a mesma id_sch_combi_detail
        g_error := 'DELETE DETAIL';
        DELETE sch_combi_detail d
         WHERE d.id_sch_combi = i_id_sch_combi
           AND d.id_code = i_id_code;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END delete_combi_detail;

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
    *
    */
    FUNCTION delete_combi_prof
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_profs.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_profs.id_code%TYPE,
        i_id_prof      IN sch_combi_profs.id_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'DELETE_COMBI_PROF';
    BEGIN
        g_error := 'DELETE DETAIL PROF';
        DELETE sch_combi_profs s
         WHERE s.id_sch_combi = i_id_sch_combi
           AND s.id_code = i_id_code
           AND s.id_prof = i_id_prof;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END delete_combi_prof;

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
    *
    */
    FUNCTION set_combi_prof
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_combi IN sch_combi_profs.id_sch_combi%TYPE,
        i_id_code      IN sch_combi_profs.id_code%TYPE,
        i_id_prof      IN sch_combi_profs.id_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_COMBI_PROF';
    BEGIN
        g_error := 'MERGE INTO SCH_COMBI_PROFS';
        MERGE INTO sch_combi_profs c
        USING (SELECT i_id_sch_combi iic, i_id_code iicod, i_id_prof iip
                 FROM dual) d
        ON (c.id_sch_combi = d.iic AND c.id_code = d.iicod AND c.id_prof = d.iip)
        WHEN NOT MATCHED THEN
            INSERT
                (id_sch_combi, id_code, id_prof)
            VALUES
                (d.iic, d.iicod, d.iip);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_combi_prof;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_COMBI_DEPENDENCY';
    BEGIN
    
        g_error := 'UPDATE ID_CODE_PARENT';
        UPDATE sch_combi_detail
           SET id_code_parent = i_id_code_parent
         WHERE id_sch_combi = i_id_sch_combi
           AND id_code = i_id_code;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_combi_dependency;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_COMBINATION';
    BEGIN
    
        g_error := 'open cursor o_lines';
        OPEN o_lines FOR
            SELECT d.*,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, d.id_dep_clin_serv) desc_dcs,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, e.id_sch_event, e.code_sch_event) desc_event,
                   pk_schedule_exam.string_exam(i_lang, d.id_exam) desc_exam,
                   pk_translation.get_translation(i_lang, code_dep_type) desc_sch_type,
                   d.dep_type
              FROM sch_combi_detail d
              JOIN sch_event e ON d.id_sch_event = e.id_sch_event
              LEFT JOIN sch_dep_type sdt ON d.dep_type = sdt.dep_type
             WHERE d.id_sch_combi = i_id_sch_combi
             ORDER BY d.id_code;
    
        g_error := 'open cursor o_profs';
        OPEN o_profs FOR
            SELECT p.id_code, p.id_prof, pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_prof) nick_prof
              FROM sch_combi_profs p
             WHERE p.id_sch_combi = i_id_sch_combi
             ORDER BY p.id_code;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_lines);
            pk_types.open_my_cursor(o_profs);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_combination;

    /********************************************************************************************
    * Creates a list of schedules.
    *
    * @param i_lang           language ID
    * @param i_prof           Professional identification
    * @param i_tab_id_sch     Table number with the schedule ids    
    * @param o_error                         error message
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/25    
    ********************************************************************************************/
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
        
        i_flg_status      IN schedule_recursion.flg_type_rep%TYPE,
        i_id_institution  IN institution.id_institution%TYPE DEFAULT NULL,
        o_tab_id_schedule OUT table_number,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name               VARCHAR2(32) := 'CREATE_SCHEDULES_SERIES';
        l_id_sch_series_recursion schedule.id_schedule_recursion%TYPE;
        l_sch_option              VARCHAR2(2);
        l_dt_begin_rep            TIMESTAMP WITH TIME ZONE;
        l_dt_end_rep              TIMESTAMP WITH TIME ZONE := NULL;
    BEGIN
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_begin_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_begin_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin_rep,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert current date to timestamp
        IF i_end_date IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ FOR i_end_date';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_end_rep,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL INS_SCH_SERIES_RECURSION';
        IF NOT pk_schedule.ins_schedule_recursion(i_lang                  => i_lang,
                                                  i_id_schedule_recursion => NULL,
                                                  i_flg_regular           => g_yes,
                                                  i_flg_timeunit          => i_flg_unit,
                                                  i_num_take              => NULL,
                                                  i_num_freq              => i_num_serie,
                                                  i_id_interv_presc_det   => NULL,
                                                  i_repeat_frequency      => i_repeat_frequency,
                                                  i_weekdays              => i_weekday,
                                                  i_week                  => i_week,
                                                  i_day_month             => i_day_month,
                                                  i_month                 => i_month,
                                                  i_begin_date            => l_dt_begin_rep,
                                                  i_end_date              => l_dt_end_rep,
                                                  i_flg_type_rep          => i_flg_status,
                                                  i_flg_type              => pk_schedule.g_sch_recursion_series,
                                                  o_id_schedule_recursion => l_id_sch_series_recursion,
                                                  o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_tab_id_schedule := table_number();
        o_tab_id_schedule.EXTEND(i_tab_dt_begin.COUNT);
        -- Iteration by dates
        FOR idx IN i_tab_dt_begin.FIRST .. i_tab_dt_begin.LAST
        LOOP
            IF (i_tab_id_consult_vac(idx) IS NULL OR
               NOT i_tab_id_consult_vac.EXISTS(idx) AND TRIM(i_tab_id_consult_vac(idx)) IS NULL)
            THEN
                l_sch_option := pk_schedule.g_sch_option_novacancy;
            ELSE
                l_sch_option := i_sch_option;
            END IF;
        
            g_error := 'CALL CREATE_SCHEDURE - Iteration ' || idx;
            IF NOT create_schedule(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_id_patient            => i_id_patient,
                                   i_id_dep_clin_serv      => i_id_dep_clin_serv,
                                   i_id_sch_event          => i_id_sch_event,
                                   i_id_prof               => i_id_prof,
                                   i_dt_begin              => i_tab_dt_begin(idx),
                                   i_dt_end                => i_tab_dt_end(idx),
                                   i_flg_vacancy           => i_flg_vacancy,
                                   i_schedule_notes        => i_schedule_notes,
                                   i_id_lang_translator    => i_id_lang_translator,
                                   i_id_lang_preferred     => i_id_lang_preferred,
                                   i_id_reason             => i_id_reason,
                                   i_id_origin             => i_id_origin,
                                   i_id_room               => i_id_room,
                                   i_id_schedule_ref       => i_id_schedule_ref,
                                   i_id_episode            => i_id_episode,
                                   i_reason_notes          => i_reason_notes,
                                   i_flg_request_type      => i_flg_request_type,
                                   i_flg_schedule_via      => i_flg_schedule_via,
                                   i_do_overlap            => i_do_overlap,
                                   i_id_consult_vac        => i_tab_id_consult_vac(idx),
                                   i_sch_option            => l_sch_option,
                                   i_id_consult_req        => i_id_consult_req,
                                   i_id_complaint          => i_id_complaint,
                                   i_id_schedule_recursion => l_id_sch_series_recursion,
                                   i_flg_status            => pk_schedule.g_sched_status_temporary,
                                   i_id_institution        => i_id_institution,
                                   o_id_schedule           => o_tab_id_schedule(idx),
                                   o_flg_proceed           => o_flg_proceed,
                                   o_flg_show              => o_flg_show,
                                   o_msg                   => o_msg,
                                   o_msg_title             => o_msg_title,
                                   o_button                => o_button,
                                   o_error                 => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedules_series;

    /********************************************************************************************
    * Confirms a list of schedules.
    *
    * @param i_lang           language ID
    * @param i_prof           Professional identification
    * @param i_tab_id_sch     Table number with the schedule ids    
    * @param i_tab_vacs       Vacancy ids  
    * @param i_confirm_all    'Y' - Confirms all the schedules in i_tab_id_Sch; 
    *                         'N' confirms the schedules associated to the vacancies in i_tab_vacs
    * @param o_error                         error message
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/25    
    ********************************************************************************************/
    FUNCTION confirm_schedules_series
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_tab_id_sch  IN table_number,
        i_tab_vacs    IN table_number,
        i_confirm_all IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'CONFIRM_SCHEDULES_SERIES';
        l_tab_id_sch table_number := table_number();
    
        FUNCTION inner_is_null(i_table_vacs table_number) RETURN BOOLEAN IS
        BEGIN
            FOR idx IN i_table_vacs.FIRST .. i_table_vacs.LAST
            LOOP
                IF (i_table_vacs(idx) IS NOT NULL)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        
            RETURN TRUE;
        END inner_is_null;
    
    BEGIN
        IF (i_confirm_all = pk_alert_constant.g_yes)
        THEN
            l_tab_id_sch.EXTEND(i_tab_id_sch.COUNT);
            l_tab_id_sch := i_tab_id_sch;
        ELSE
            IF (i_tab_vacs IS NOT NULL AND inner_is_null(i_tab_vacs) = FALSE)
            THEN
                SELECT s.id_schedule BULK COLLECT
                  INTO l_tab_id_sch
                  FROM schedule s
                 WHERE s.id_schedule IN (SELECT column_value
                                           FROM TABLE(i_tab_id_sch))
                   AND s.id_sch_consult_vacancy IN (SELECT column_value
                                                      FROM TABLE(i_tab_vacs));
            ELSE
                l_tab_id_sch.EXTEND(i_tab_id_sch.COUNT);
                l_tab_id_sch := i_tab_id_sch;
            END IF;
        END IF;
    
        g_error := 'UPDATE I_TAB_ID_SCH';
        FOR idx IN l_tab_id_sch.FIRST .. l_tab_id_sch.LAST
        LOOP
            IF NOT pk_schedule.confirm_schedule(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_schedule => l_tab_id_sch(idx),
                                                o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END confirm_schedules_series;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name,
                         owner       => g_package_owner);
END pk_schedule_outp;
/
