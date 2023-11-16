/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_common IS
    -- This package provides functions that are common to more than one type of scheduling (exams, consults, etc)
    -- but cannot be included in the main package, as they are not to be considered for middle layer code generation.
    -- These functions are solely used by the database.
    -- @author Nuno Guerreiro
    -- @version alpha

    ------------------------------------------- PRIVATE FUNCTIONS ---------------------------------------
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
        pk_alertlog.log_error(text        => i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror,
                              object_name => g_package_name,
                              owner       => g_package_owner);
    END error_handling;

    FUNCTION get_sch_event_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sch_event IN schedule.id_sch_event%TYPE,
        i_id_inst      IN sch_event_inst_soft.id_institution%TYPE,
        i_id_software  IN software.id_software%TYPE,
        o_epis_type    OUT epis_type.id_epis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCH_EVENT_EPIS_TYPE';
    
        CURSOR c_epis_type IS
            SELECT id_epis_type
              FROM (SELECT DISTINCT ses.id_epis_type id_epis_type,
                                    row_number() over(ORDER BY ses.id_software DESC) line_number
                      FROM sch_event_soft ses
                     WHERE ses.id_software IN (pk_alert_constant.g_soft_all, i_id_software)
                       AND ses.id_sch_event = i_id_sch_event
                       AND get_sch_event_avail(i_id_sch_event, i_id_inst, ses.id_software_dest /*i_id_software*/) =
                           pk_alert_constant.g_yes)
             WHERE line_number = 1;
    
        r_epis_type c_epis_type%ROWTYPE;
    
    BEGIN
    
        OPEN c_epis_type;
    
        FETCH c_epis_type
            INTO r_epis_type;
        IF c_epis_type%FOUND
        THEN
            o_epis_type := r_epis_type.id_epis_type;
        END IF;
        CLOSE c_epis_type;
    
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
            RETURN FALSE;
        
    END get_sch_event_epis_type;

    ------------------------------------------- PUBLIC FUNCTIONS ---------------------------------------

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'ALTER_SCH_PERMISSION';
    BEGIN
        -- Update record
        g_error := 'UPDATE RECORD';
        UPDATE sch_permission
           SET id_consult_permission = nvl(i_id_consult_permission, id_consult_permission),
               id_institution        = nvl(i_id_institution, id_institution),
               id_professional       = nvl(i_id_professional, id_professional),
               id_prof_agenda        = nvl(i_id_prof_agenda, id_prof_agenda),
               id_dep_clin_serv      = nvl(i_id_dep_clin_serv, id_dep_clin_serv),
               id_sch_event          = nvl(i_id_sch_event, id_sch_event),
               flg_permission        = nvl(i_flg_permission, flg_permission)
         WHERE id_consult_permission = i_id_consult_permission
        RETURNING id_consult_permission, id_institution, id_professional, id_prof_agenda, id_dep_clin_serv, id_sch_event, flg_permission INTO o_sch_permission_rec.id_consult_permission, o_sch_permission_rec.id_institution, o_sch_permission_rec.id_professional, o_sch_permission_rec.id_prof_agenda, o_sch_permission_rec.id_dep_clin_serv, o_sch_permission_rec.id_sch_event, o_sch_permission_rec.flg_permission;
        IF SQL%ROWCOUNT = 0
        THEN
            -- No records were updated due to an invalid key
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_permission_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END alter_sch_permission;

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
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'ALTER_SCHEDULE';
        l_id_cs_requested   clinical_service.id_clinical_service%TYPE;
        l_id_department_req department.id_department%TYPE;
        l_id_dept_req       dept.id_dept%TYPE;
        l_id_episode        episode.id_episode%TYPE;
        l_rowids            table_varchar;
    BEGIN
        -- Update record
        g_error := 'UPDATE RECORD';
        UPDATE schedule
           SET id_schedule            = nvl(i_id_schedule, id_schedule),
               id_instit_requests     = nvl(i_id_instit_requests, id_instit_requests),
               id_instit_requested    = nvl(i_id_instit_requested, id_instit_requested),
               id_dcs_requests        = nvl(i_id_dcs_requests, id_dcs_requests),
               id_dcs_requested       = nvl(i_id_dcs_requested, id_dcs_requested),
               id_prof_requests       = nvl(i_id_prof_requests, id_prof_requests),
               id_prof_schedules      = nvl(i_id_prof_schedules, id_prof_schedules),
               dt_request_tstz        = nvl(i_dt_request_tstz, dt_request_tstz),
               dt_schedule_tstz       = nvl(i_dt_schedule_tstz, dt_schedule_tstz),
               flg_status             = nvl(i_flg_status, flg_status),
               dt_begin_tstz          = nvl(i_dt_begin_tstz, dt_begin_tstz),
               dt_end_tstz            = nvl(i_dt_end_tstz, dt_end_tstz),
               id_prof_cancel         = nvl(i_id_prof_cancel, id_prof_cancel),
               dt_cancel_tstz         = nvl(i_dt_cancel_tstz, dt_cancel_tstz),
               schedule_notes         = nvl(i_schedule_notes, schedule_notes),
               id_cancel_reason       = nvl(i_id_cancel_reason, id_cancel_reason),
               id_lang_translator     = nvl(i_id_lang_translator, id_lang_translator),
               id_lang_preferred      = nvl(i_id_lang_preferred, id_lang_preferred),
               id_sch_event           = nvl(i_id_sch_event, id_sch_event),
               id_reason              = nvl(i_id_reason, id_reason),
               reason_notes           = nvl(i_reason_notes, reason_notes),
               id_origin              = nvl(i_id_origin, id_origin),
               id_room                = nvl(i_id_room, id_room),
               flg_urgency            = nvl(i_flg_urgency, flg_urgency),
               schedule_cancel_notes  = nvl(i_schedule_cancel_notes, schedule_cancel_notes),
               flg_notification       = nvl(i_flg_notification, flg_notification),
               id_schedule_ref        = nvl(i_id_schedule_ref, id_schedule_ref),
               flg_vacancy            = nvl(i_flg_vacancy, flg_vacancy),
               flg_sch_type           = nvl(i_flg_sch_type, flg_sch_type),
               flg_instructions       = nvl(i_flg_instructions, flg_instructions),
               id_sch_consult_vacancy = nvl(i_id_sch_consult_vac, id_sch_consult_vacancy),
               id_episode             = nvl(i_id_episode, id_episode)
         WHERE id_schedule = i_id_schedule
        RETURNING id_schedule, id_instit_requests, id_instit_requested, id_dcs_requests, id_dcs_requested, id_prof_requests, id_prof_schedules, dt_request_tstz, dt_schedule_tstz, flg_status, dt_begin_tstz, dt_end_tstz, id_prof_cancel, dt_cancel_tstz,
        --              schedule_notes, 
        id_cancel_reason, id_lang_translator, id_lang_preferred, id_sch_event, id_reason,
        --              reason_notes, 
        id_origin, id_room, flg_urgency,
        --              schedule_cancel_notes, 
        flg_notification, id_schedule_ref, flg_vacancy, flg_sch_type, flg_instructions, id_sch_consult_vacancy, id_episode INTO o_schedule_rec.id_schedule, o_schedule_rec.id_instit_requests, o_schedule_rec.id_instit_requested, o_schedule_rec.id_dcs_requests, o_schedule_rec.id_dcs_requested, o_schedule_rec.id_prof_requests, o_schedule_rec.id_prof_schedules, o_schedule_rec.dt_request_tstz, o_schedule_rec.dt_schedule_tstz, o_schedule_rec.flg_status, o_schedule_rec.dt_begin_tstz, o_schedule_rec.dt_end_tstz, o_schedule_rec.id_prof_cancel, o_schedule_rec.dt_cancel_tstz,
        --              o_schedule_rec.schedule_notes, 
        o_schedule_rec.id_cancel_reason, o_schedule_rec.id_lang_translator, o_schedule_rec.id_lang_preferred, o_schedule_rec.id_sch_event, o_schedule_rec.id_reason,
        --              o_schedule_rec.reason_notes, 
        o_schedule_rec.id_origin, o_schedule_rec.id_room, o_schedule_rec.flg_urgency,
        --              o_schedule_rec.schedule_cancel_notes, 
        o_schedule_rec.flg_notification, o_schedule_rec.id_schedule_ref, o_schedule_rec.flg_vacancy, o_schedule_rec.flg_sch_type, o_schedule_rec.flg_instructions, o_schedule_rec.id_sch_consult_vacancy, o_schedule_rec.id_episode;
    
        IF SQL%ROWCOUNT = 0
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => g_invalid_record_key,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE EPISODE AND EPIS_INFO';
        BEGIN
            SELECT ei.id_episode
              INTO l_id_episode
              FROM epis_info ei
             WHERE ei.id_schedule = i_id_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_id_episode IS NOT NULL
        THEN
            g_error := 'GET ID_CS_REQUESTED';
            BEGIN
                SELECT dcs.id_clinical_service, dpt.id_department, dpt.id_dept
                  INTO l_id_cs_requested, l_id_department_req, l_id_dept_req
                  FROM dep_clin_serv dcs, department dpt
                 WHERE dcs.id_dep_clin_serv = i_id_dcs_requested
                   AND dcs.id_department = dpt.id_department;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'UPDATE EPISODE';
            ts_episode.upd(id_cs_requested_in         => l_id_cs_requested,
                           id_department_requested_in => l_id_department_req,
                           id_dept_requested_in       => l_id_dept_req,
                           id_episode_in              => l_id_episode,
                           rows_out                   => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => profissional(0, 0, 0),
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_rowids := table_varchar();
        
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(id_episode_in          => l_id_episode,
                             flg_sch_status_in      => i_flg_status,
                             id_dcs_requested_in    => i_id_dcs_requested,
                             id_instit_requested_in => i_id_instit_requested,
                             id_prof_schedules_in   => i_id_prof_schedules,
                             flg_urgency_in         => i_flg_urgency,
                             id_complaint_in        => i_id_complaint,
                             rows_out               => l_rowids);
        
            --Process the events associated to an update on epis_info                         
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => profissional(0, 0, 0),
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_SCH_STATUS',
                                                                          'ID_DCS_REQUESTED',
                                                                          'ID_INSTIT_REQUESTED',
                                                                          'ID_PROF_SCHEDULES',
                                                                          'FLG_URGENCY_IN',
                                                                          'ID_COMPLAINT'));
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_schedule_rec := NULL;
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
            RETURN FALSE;
        
    END alter_schedule;

    /*
    * Checks if a type of schedule requires vacancies to be consumed, when creating the schedule.
    * 
    * @param i_lang                Language identifier.
    * @param i_id_institution      Institution identifier.
    * @param i_id_software         Software identifier.
    * @param i_id_dept             department id
    * @param i_flg_sch_type        Scheduling type
    * @param o_usage               Whether or not the type of schedule requires vacancies to be consumed.
    * @param o_error               Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * ALERT-10162. passa a ser uma wrapper da pk_schedule.get_vacancy_config. Com isso unifica-se o acesso á sch_vacancy_usage porque 
    * antes estas 2 funcoes tinham comportamentos ligeiramente diferentes
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
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
    ) RETURN BOOLEAN IS
        l_flg_use         sch_vacancy_usage.flg_use%TYPE;
        l_flg_sched_w_vac sch_vacancy_usage.flg_sched_without_vac%TYPE;
        l_flg_edit_vac    sch_vacancy_usage.flg_edit_vac%TYPE;
        l_func_name       VARCHAR2(32) := 'CHECK_VACANCY_USAGE';
    BEGIN
        -- Get usage
        g_error := 'CALL PK_SCHEDULE.GET_VACANCY_CONFIG';
        IF NOT pk_schedule.get_vacancy_config(i_lang                  => i_lang,
                                              i_prof                  => profissional(-1, i_id_institution, i_id_software),
                                              i_id_dept               => i_id_dept,
                                              i_dep_type              => i_flg_sch_type,
                                              o_flg_use               => l_flg_use,
                                              o_flg_sched_without_vac => l_flg_sched_w_vac,
                                              o_flg_edit_vac          => l_flg_edit_vac,
                                              o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- converter output
        o_usage       := l_flg_use = g_yes;
        o_sched_w_vac := l_flg_sched_w_vac = g_yes;
        o_edit_vac    := l_flg_edit_vac = g_yes;
    
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
            RETURN FALSE;
        
    END check_vacancy_usage;

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
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := 'GET_CONFIG';
        l_null_value_exception EXCEPTION;
    BEGIN
        g_error := 'GET ' || nvl(i_id_sysconfig, '[null i_id_sysconfig!]') || ' FROM SYS_CONFIG WITH i_id_institution=' ||
                   nvl(to_char(i_id_institution), 'null') || ' AND i_id_software=' ||
                   nvl(to_char(i_id_software), 'null');
    
        SELECT VALUE
          INTO o_config
          FROM (SELECT sc.value
                  FROM sys_config sc
                 WHERE sc.id_sys_config = i_id_sysconfig
                   AND sc.id_institution IN (i_id_institution, 0)
                   AND sc.id_software IN (i_id_software, 0)
                 ORDER BY sc.id_institution DESC, sc.id_software DESC)
         WHERE rownum = 1;
    
        IF o_config IS NULL
        THEN
            RAISE l_null_value_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- config not found
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
            -- config found, but with null value
        WHEN l_null_value_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -20202,
                                              i_sqlerrm  => 'Null value for config ' || i_id_sysconfig,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
            -- just in case...
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_config;

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
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(32) := 'EXIST_INTERFACE';
        l_schedule_interface sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL GET_CONFIG';
        -- Get scheduling interface parameter
        IF NOT (get_config(i_lang           => i_lang,
                           i_id_sysconfig   => g_scheduling_interface,
                           i_id_institution => i_prof.institution,
                           i_id_software    => i_prof.software,
                           o_config         => l_schedule_interface,
                           o_error          => o_error))
        THEN
            o_exists := TRUE;
            RETURN FALSE;
        ELSE
            g_error := 'CHECK INTERFACE';
            -- Check if the interface exists             
            IF (l_schedule_interface = g_yes)
            THEN
                o_exists := TRUE;
            ELSE
                o_exists := FALSE;
            END IF;
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            o_exists := FALSE;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END exist_interface;

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
    * @param i_id_sch_combi_detail            used in single visit. This id relates this schedule with the combination detail line 
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCHEDULE';
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_schedule IS NOT NULL)
        THEN
            o_schedule_rec.id_schedule := i_id_schedule;
        ELSE
            SELECT seq_schedule.nextval
              INTO o_schedule_rec.id_schedule
              FROM dual;
        END IF;
        -- Create record
        g_error                               := ' CREATE RECORD ';
        o_schedule_rec.id_instit_requests     := i_id_instit_requests;
        o_schedule_rec.id_instit_requested    := i_id_instit_requested;
        o_schedule_rec.id_dcs_requests        := i_id_dcs_requests;
        o_schedule_rec.id_dcs_requested       := i_id_dcs_requested;
        o_schedule_rec.id_prof_requests       := i_id_prof_requests;
        o_schedule_rec.id_prof_schedules      := i_id_prof_schedules;
        o_schedule_rec.dt_request_tstz        := i_dt_request_tstz;
        o_schedule_rec.dt_schedule_tstz       := i_dt_schedule_tstz;
        o_schedule_rec.flg_status             := i_flg_status;
        o_schedule_rec.dt_begin_tstz          := i_dt_begin_tstz;
        o_schedule_rec.dt_end_tstz            := i_dt_end_tstz;
        o_schedule_rec.id_prof_cancel         := i_id_prof_cancel;
        o_schedule_rec.dt_cancel_tstz         := i_dt_cancel_tstz;
        o_schedule_rec.schedule_notes         := i_schedule_notes;
        o_schedule_rec.id_cancel_reason       := i_id_cancel_reason;
        o_schedule_rec.id_lang_translator     := i_id_lang_translator;
        o_schedule_rec.id_lang_preferred      := i_id_lang_preferred;
        o_schedule_rec.id_sch_event           := i_id_sch_event;
        o_schedule_rec.id_reason              := i_id_reason;
        o_schedule_rec.reason_notes           := i_reason_notes;
        o_schedule_rec.id_origin              := i_id_origin;
        o_schedule_rec.flg_vacancy            := i_flg_vacancy;
        o_schedule_rec.id_room                := i_id_room;
        o_schedule_rec.flg_urgency            := i_flg_urgency;
        o_schedule_rec.schedule_cancel_notes  := i_schedule_cancel_notes;
        o_schedule_rec.flg_notification       := i_flg_notification;
        o_schedule_rec.id_schedule_ref        := i_id_schedule_ref;
        o_schedule_rec.flg_sch_type           := i_flg_sch_type;
        o_schedule_rec.flg_instructions       := i_flg_instructions;
        o_schedule_rec.flg_request_type       := i_flg_request_type;
        o_schedule_rec.flg_schedule_via       := i_flg_schedule_via;
        o_schedule_rec.id_sch_consult_vacancy := i_id_sch_consult_vacancy;
        o_schedule_rec.id_episode             := i_id_episode;
        o_schedule_rec.id_schedule_recursion  := i_id_sch_recursion;
        o_schedule_rec.flg_present            := i_flg_present;
        o_schedule_rec.id_multidisc           := i_id_multidisc;
        o_schedule_rec.id_sch_combi_detail    := i_id_sch_combi_detail;
    
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO schedule
        VALUES o_schedule_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedule_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_schedule;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_NOTIFICATION_DEFAULT';
    BEGIN
        g_error := 'NOTIFICATION DEFAULT';
        SELECT notification_default
          INTO o_default_value
          FROM (SELECT notification_default
                  FROM sch_dcs_notification sdn
                 WHERE sdn.id_dep_clin_serv = i_id_dep_clin_serv
                    OR sdn.id_dep_clin_serv = 0
                
                 ORDER BY sdn.id_dep_clin_serv DESC)
         WHERE rownum = 1;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- Assume the pending state, if no configuration is found.
            o_default_value := g_notification_status_pending;
            RETURN TRUE;
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
            RETURN FALSE;
        
    END get_notification_default;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCH_GROUP';
        l_rows_ei   table_varchar;
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_group IS NOT NULL)
        THEN
            o_sch_group_rec.id_group := i_id_group;
        ELSE
            SELECT seq_sch_group.nextval
              INTO o_sch_group_rec.id_group
              FROM dual;
        END IF;
        -- Create record
        g_error                     := 'CREATE RECORD';
        o_sch_group_rec.id_schedule := i_id_schedule;
        o_sch_group_rec.id_patient  := i_id_patient;
    
        -- Insert record
        g_error := ' INSERT RECORD ';
        INSERT INTO sch_group
            (id_group, id_schedule, id_patient)
        VALUES
            (o_sch_group_rec.id_group, o_sch_group_rec.id_schedule, o_sch_group_rec.id_patient);
    
        RETURN TRUE;
    
        ts_epis_info.upd(sch_group_id_patient_in => -1,
                         where_in                => 'ID_SCHEDULE = ' || i_id_schedule,
                         rows_out                => l_rows_ei);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => profissional(0, 0, 0),
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('SCH_GROUP_ID_PATIENT'));
    
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_group_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_sch_group;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCH_PERMISSION';
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_consult_permission IS NOT NULL)
        THEN
            o_sch_permission_rec.id_consult_permission := i_id_consult_permission;
        ELSE
            SELECT seq_sch_permission.nextval
              INTO o_sch_permission_rec.id_consult_permission
              FROM dual;
        END IF;
        -- Create record
        g_error                               := 'CREATE RECORD';
        o_sch_permission_rec.id_institution   := i_id_institution;
        o_sch_permission_rec.id_professional  := i_id_professional;
        o_sch_permission_rec.id_prof_agenda   := i_id_prof_agenda;
        o_sch_permission_rec.id_dep_clin_serv := i_id_dep_clin_serv;
        o_sch_permission_rec.id_sch_event     := i_id_sch_event;
        o_sch_permission_rec.flg_permission   := i_flg_permission;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO sch_permission
        VALUES o_sch_permission_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_permission_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_sch_permission;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCH_RESOURCE';
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_sch_resource IS NOT NULL)
        THEN
            o_sch_resource_rec.id_sch_resource := i_id_sch_resource;
        ELSE
            SELECT seq_sch_resource.nextval
              INTO o_sch_resource_rec.id_sch_resource
              FROM dual;
        END IF;
        -- Create record
        g_error                                 := 'CREATE RECORD';
        o_sch_resource_rec.id_schedule          := i_id_schedule;
        o_sch_resource_rec.id_institution       := i_id_institution;
        o_sch_resource_rec.id_professional      := i_id_professional;
        o_sch_resource_rec.dt_sch_resource_tstz := i_dt_sch_resource_tstz;
        IF i_id_professional = nvl(i_id_prof_leader, -1)
        THEN
            o_sch_resource_rec.flg_leader := g_yes;
        ELSE
            o_sch_resource_rec.flg_leader := g_no;
        END IF;
        o_sch_resource_rec.id_sch_consult_vacancy := i_id_sch_consult_vacancy;
    
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO sch_resource
        VALUES o_sch_resource_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_resource_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_sch_resource;

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
    *
    * UPDATED alert-8202. adaptado para a possibilidade de agendamento multi-exame
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION set_vacant_occupied
    (
        i_lang        language.id_language%TYPE,
        i_id_schedule schedule.id_schedule%TYPE,
        o_occupied    OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VACANT_OCCUPIED';
    
        CURSOR c_sched IS
            SELECT s.id_instit_requested,
                   sr.id_professional,
                   s.id_sch_event,
                   s.id_dcs_requested,
                   s.dt_begin_tstz,
                   s.flg_sch_type
              FROM schedule s, sch_resource sr
             WHERE s.id_schedule = i_id_schedule
               AND s.id_schedule = sr.id_schedule(+);
    
        l_sched c_sched%ROWTYPE;
    
    BEGIN
        g_error := 'OPEN c_sched';
        -- Open cursor
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        -- Fetch
        FETCH c_sched
            INTO l_sched;
        g_error := 'CLOSE c_sched';
        -- Close cursor
        CLOSE c_sched;
        -- Occupy vacancy
        RETURN set_vacant_occupied(i_lang             => i_lang,
                                   i_id_institution   => l_sched.id_instit_requested,
                                   i_id_sch_event     => l_sched.id_sch_event,
                                   i_id_professional  => l_sched.id_professional,
                                   i_id_dep_clin_serv => l_sched.id_dcs_requested,
                                   i_dt_begin_tstz    => l_sched.dt_begin_tstz,
                                   i_flg_sch_type     => l_sched.flg_sch_type,
                                   o_occupied         => o_occupied,
                                   o_error            => o_error);
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
            RETURN FALSE;
        
    END set_vacant_occupied;

    /*
    * Tries to occupy a vacancy.
    * 
    * @param i_lang                 Language identifier.
    * @param i_id_institution       Institution identifier.
    * @param i_id_sch_event         Event identifier.
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
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    29-05-2008
    *
    * UPDATED alert-8202. adaptado para a possibilidade de agendamentos multi-exame
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
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
        o_occupied         OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VACANT_OCCUPIED';
    BEGIN
        g_error := 'UPDATE sch_consult_vacancy';
        -- Update vacancy table, depending on the type of schedule.
        UPDATE sch_consult_vacancy scv
           SET scv.used_vacancies = scv.used_vacancies + 1
         WHERE scv.id_sch_consult_vacancy =
               (SELECT MIN(scv_inner.id_sch_consult_vacancy)
                  FROM sch_consult_vacancy scv_inner
                 WHERE scv_inner.id_institution = i_id_institution
                   AND scv_inner.id_sch_event = i_id_sch_event
                   AND ((i_id_professional IS NOT NULL AND scv_inner.id_prof = i_id_professional) OR
                       scv_inner.id_prof IS NULL)
                   AND scv_inner.id_dep_clin_serv = i_id_dep_clin_serv
                   AND scv_inner.dt_begin_tstz = i_dt_begin_tstz
                   AND scv_inner.max_vacancies > scv_inner.used_vacancies
                   AND scv_inner.flg_status = pk_schedule_bo.g_status_active)
        RETURNING scv.id_sch_consult_vacancy INTO o_occupied;
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
            RETURN FALSE;
        
    END set_vacant_occupied;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VACANT_OCCUPIED_BY_ID';
    BEGIN
        g_error := 'UPDATE sch_consult_vacancy';
        UPDATE sch_consult_vacancy scv
           SET scv.used_vacancies = scv.used_vacancies + 1
         WHERE scv.id_sch_consult_vacancy = i_id_vacancy
           AND scv.max_vacancies > scv.used_vacancies
        RETURNING scv.id_sch_consult_vacancy INTO o_occupied;
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
            RETURN FALSE;
        
    END set_vacant_occupied_by_id;

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
    * @author   Sofia Mendes
    * @version  2.4.3
    * @date     16-07-2008
    */
    FUNCTION set_vac_occupied_groups
    (
        i_lang           language.id_language%TYPE,
        i_id_vacancy     sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_nr_of_patients IN NUMBER,
        o_occupied       OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VACANT_OCCUPIED_BY_PATS';
    BEGIN
        g_error := 'UPDATE sch_consult_vacancy';
        UPDATE sch_consult_vacancy scv
           SET scv.used_vacancies = scv.used_vacancies + i_nr_of_patients
         WHERE scv.id_sch_consult_vacancy = i_id_vacancy
        --AND scv.max_vacancies > scv.used_vacancies
        RETURNING scv.id_sch_consult_vacancy INTO o_occupied;
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
            RETURN FALSE;
        
    END set_vac_occupied_groups;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VACANT_OCCUPIED_BY_ID_MFR';
    BEGIN
        g_error := 'UPDATE sch_consult_vacancy';
        UPDATE sch_consult_vacancy scv
           SET scv.used_vacancies = scv.used_vacancies + 1
         WHERE scv.id_sch_consult_vacancy = i_id_vacancy
        RETURNING scv.id_sch_consult_vacancy INTO o_occupied;
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
            RETURN FALSE;
        
    END set_vacant_occupied_by_id_mfr;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_GENERIC_EVENT';
    BEGIN
        g_error := 'CHECK EVENT';
        BEGIN
            g_error := 'GET GENERIC EVENT';
            SELECT id_sch_event_ref
              INTO o_id_event
              FROM sch_event_inst sei
             WHERE sei.id_institution = i_id_institution
               AND sei.id_sch_event = i_id_event
               AND sei.active = g_yes
               AND rownum = 1
               AND get_sch_event_avail(i_id_event, i_id_institution, 0) = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                -- If no generic event is found, then the event itself is returned.
                o_id_event := i_id_event;
        END;
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
            RETURN FALSE;
        
    END get_generic_event;

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
    *
    * UPDATED
    * Removed update to p1_external_request
    * @author  Jose Antunes
    * @date    06-08-2008
    * @version 2.4.3
    * 
    * UPDATED
    * update status and cancel dates in table schedule_sr 
    * @author Telmo Castro
    * @date   27-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * ALERT-10162. updated call to check_vacancy_usage - new parameter i_id_dept
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * used_vacancies decrement fixed for MFR scheduler
    * @author  Telmo Castro
    * @date    08-01-2009
    * @version 2.4.3.x    
    *
    * UPDATED
    * alert-8202 sch_consult_vac_exam deprecated.
    * @author  Telmo Castro
    * @date    16-10-2009
    * @version 2.5.0.7    
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
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_schedule_rec   schedule%ROWTYPE;
        l_id_sch_event   sch_event.id_sch_event%TYPE;
        l_id_prof        professional.id_professional%TYPE;
        l_vacancy_usage  BOOLEAN;
        l_sched_w_vac    BOOLEAN;
        l_edit_vac       BOOLEAN;
        l_cancelled      BOOLEAN := FALSE;
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_dept        dep_clin_serv.id_department%TYPE;
        l_func_exception EXCEPTION;
    
        l_id_vacancy table_number;
    
        l_rowids table_varchar;
    
        /*        -- Returns the analysis identifier associated with an analysis schedule.
                FUNCTION inner_get_analysis_id(i_id_schedule schedule_analysis.id_schedule%TYPE)
                    RETURN schedule_analysis.id_analysis%TYPE IS
                    l_id_schedule_analysis schedule_analysis.id_analysis%TYPE := NULL;
                BEGIN
                    g_error := 'INNER_GET_ANALYSIS_ID';
                    -- Get analysis identifier
                    SELECT sa.id_analysis
                      INTO l_id_schedule_analysis
                      FROM schedule_analysis sa
                     WHERE sa.id_schedule = inner_get_analysis_id.i_id_schedule;
                    RETURN l_id_schedule_analysis;
                END inner_get_analysis_id;
        */
    
        -- Returns the schedule's associated professional's identifier.
        FUNCTION inner_get_prof_id(i_id_schedule schedule.id_schedule%TYPE) RETURN sch_resource.id_professional%TYPE IS
            l_id_prof sch_resource.id_professional%TYPE := NULL;
        BEGIN
            g_error := 'INNER_GET_PROF_ID';
            -- Get professional identifier
            BEGIN
                SELECT sr.id_professional
                  INTO l_id_prof
                  FROM sch_resource sr
                 WHERE sr.id_schedule = inner_get_prof_id.i_id_schedule
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            RETURN l_id_prof;
        END inner_get_prof_id;
    
        FUNCTION inner_get_vacancy(i_id_schedule schedule.id_schedule%TYPE) RETURN table_number IS
            l_id_vacancy table_number := table_number();
        BEGIN
            g_error := 'INNER_GET_VACANCY';
            -- Get vacancy
            BEGIN
                SELECT sr.id_sch_consult_vacancy
                  BULK COLLECT
                  INTO l_id_vacancy
                  FROM sch_resource sr
                 WHERE sr.id_schedule = inner_get_vacancy.i_id_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
            RETURN l_id_vacancy;
        END inner_get_vacancy;
    
    BEGIN
        g_error := 'CHECK IF APPOINTMENT IS ALREADY CANCELLED';
        -- Check if the appointment is already cancelled
        BEGIN
            SELECT s.id_schedule
              INTO l_id_schedule
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule
               AND s.flg_status = pk_schedule.g_sched_status_cancelled;
        
            l_cancelled := TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                l_cancelled := FALSE;
        END;
    
        IF NOT l_cancelled
        THEN
            g_error := 'ALTER SCHEDULE';
            -- Alter the schedule
            IF NOT alter_schedule(i_lang                  => i_lang,
                                  i_id_schedule           => i_id_schedule,
                                  i_flg_status            => pk_schedule.g_sched_status_cancelled,
                                  i_id_prof_cancel        => i_id_professional,
                                  i_id_cancel_reason      => i_id_cancel_reason,
                                  i_dt_cancel_tstz        => current_timestamp,
                                  i_schedule_cancel_notes => i_cancel_notes,
                                  o_schedule_rec          => l_schedule_rec,
                                  o_error                 => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- Telmo 27-08-2008. Cancelar agendamentos oris. Tem as mesmas colunas de cancelamentos que a schedule !
            /*UPDATE schedule_sr
               SET flg_status     = pk_schedule.g_sched_status_cancelled,
                   id_prof_cancel = i_id_professional,
                   dt_cancel_tstz = current_timestamp,
                   notes_cancel   = i_cancel_notes --,
            -- Sofia Mendes 24-09-2009: retirado porque os motivos de cancelamento da schedule_sr não 
            -- são os mesmos dos inseridos aquando do cancelamento de um agendamento
            --id_sr_cancel_reason = i_id_cancel_reason
             WHERE id_schedule = i_id_schedule; -- se nao encontrou e' porque nao era agendamento oris*/
        
            g_error  := 'UPDATE SCHEDULE_SR';
            l_rowids := table_varchar();
            ts_schedule_sr.upd(flg_status_in      => pk_schedule.g_sched_status_cancelled,
                               flg_status_nin     => FALSE,
                               id_prof_cancel_in  => i_id_professional,
                               id_prof_cancel_nin => FALSE,
                               notes_cancel_in    => i_cancel_notes,
                               notes_cancel_nin   => FALSE,
                               dt_cancel_tstz_in  => current_timestamp,
                               dt_cancel_tstz_nin => FALSE,
                               where_in           => 'id_schedule = ' || i_id_schedule,
                               rows_out           => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => NULL,
                                          i_table_name   => 'SCHEDULE_SR',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_CANCEL',
                                                                          'NOTES_CANCEL',
                                                                          'DT_CANCEL_TSTZ'));
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
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
            RETURN FALSE;
        
    END cancel_schedule;

    /**
    * Creates a generic schedule (exams, consults, analysis, etc).  
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
    *
    * UPDATED
    * INC BMC ID = 24032, JIRA ISSUE = ALERT-9772
    * este create_schedule e' usado pelo pk_schedule_interface por isso nao traz id da vaga.
    * e' preciso tentar fazer match com uma vaga existente para que se consiga preencher o campo schedule.id_sch_consult_vacancy.
    * O objectivo e' permitir criar alem-vagas em agendamentos vindos do sonho, para o qual ter essa coluna preenchida e' fundamental.
    * @author  Telmo Castro
    * @version 2.4.3.x
    * @date     13-11-2008
    *
    * UPDATED
    * ALERT-10162. updated call to check_vacancy_usage - new parameter i_id_dept
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
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
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(18) := 'CREATE_SCHEDULE';
        l_id_inst              department.id_institution%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_schedule_rec         schedule%ROWTYPE;
        l_sch_group_rec        sch_group%ROWTYPE;
        l_sch_resource_rec     sch_resource%ROWTYPE;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_vacancy_usage        BOOLEAN;
        l_reason_notes         schedule.reason_notes%TYPE;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_sched_w_vac          BOOLEAN;
        l_edit_vac             BOOLEAN;
        l_id_dept              dep_clin_serv.id_department%TYPE;
        l_func_exception       EXCEPTION;
    BEGIN
        l_flg_status := i_flg_status;
    
        -- Set default value (when no vacancies are used)
        o_occupied := NULL;
    
        g_error := 'LOAD INSTITUTION';
        -- Load institution 
        SELECT d.id_institution
          INTO l_id_inst
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_department = d.id_department
           AND dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        g_error := 'GET NOTIFICATION DEFAULT';
        -- Get default value for the notification flag
        IF NOT get_notification_default(i_lang             => i_lang,
                                        i_id_dep_clin_serv => i_id_dep_clin_serv,
                                        o_default_value    => l_notification_default,
                                        o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Get reason notes
        IF i_id_reason IS NOT NULL
        THEN
            g_error        := 'GET REASON NOTES';
            l_reason_notes := pk_schedule.string_reason(i_lang      => i_lang,
                                                        i_prof      => profissional(i_id_prof_schedules,
                                                                                    i_id_institution,
                                                                                    i_id_software),
                                                        i_id_reason => i_id_reason,
                                                        i_flg_rtype => NULL);
        ELSE
            -- Custom reason
            l_reason_notes := i_reason_notes;
        END IF;
    
        -- Create schedule
        g_error := 'CALL NEW_SCHEDULE';
        IF NOT new_schedule(i_lang                   => i_lang,
                            i_id_schedule            => i_id_schedule,
                            i_id_instit_requests     => i_id_institution,
                            i_id_instit_requested    => l_id_inst,
                            i_id_dcs_requested       => i_id_dep_clin_serv,
                            i_id_prof_schedules      => i_id_prof_schedules,
                            i_id_prof_requests       => i_id_prof_requests,
                            i_dt_schedule_tstz       => g_sysdate_tstz,
                            i_flg_status             => l_flg_status,
                            i_dt_begin_tstz          => i_dt_begin,
                            i_dt_end_tstz            => i_dt_end,
                            i_schedule_notes         => i_schedule_notes,
                            i_id_lang_translator     => i_id_lang_translator,
                            i_id_lang_preferred      => i_id_lang_preferred,
                            i_id_sch_event           => i_id_sch_event,
                            i_id_reason              => i_id_reason,
                            i_reason_notes           => l_reason_notes,
                            i_id_origin              => i_id_origin,
                            i_id_room                => i_id_room,
                            i_flg_urgency            => g_no,
                            i_flg_vacancy            => i_flg_vacancy,
                            i_flg_notification       => l_notification_default,
                            i_flg_sch_type           => i_flg_sch_type,
                            i_id_schedule_ref        => i_id_schedule_ref,
                            i_flg_instructions       => i_flg_instructions,
                            i_id_complaint           => i_id_complaint,
                            i_flg_request_type       => i_flg_request_type,
                            i_flg_schedule_via       => i_flg_schedule_via,
                            i_id_sch_consult_vacancy => NULL,
                            i_id_multidisc           => NULL,
                            i_id_sch_combi_detail    => NULL,
                            o_schedule_rec           => l_schedule_rec,
                            o_error                  => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        o_id_schedule := l_schedule_rec.id_schedule;
    
        -- Create schedule group
        g_error := 'CALL NEW_SCH_GROUP';
        IF NOT pk_schedule_common.new_sch_group(i_lang          => i_lang,
                                                i_id_schedule   => o_id_schedule,
                                                i_id_patient    => i_id_patient,
                                                o_sch_group_rec => l_sch_group_rec,
                                                o_error         => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Create resource allocation
        IF NOT pk_schedule_common.new_sch_resource(i_lang                 => i_lang,
                                                   i_id_schedule          => o_id_schedule,
                                                   i_id_institution       => l_id_inst,
                                                   i_id_professional      => i_id_prof,
                                                   i_dt_sch_resource_tstz => g_sysdate_tstz,
                                                   o_sch_resource_rec     => l_sch_resource_rec,
                                                   o_error                => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF NOT i_ignore_vacancies
        THEN
            -- Increment vacancy usage (for schedule types that require so). 
            -- Note: even if the schedule is still on the pending state,
            -- the vacancy is used anyway. This prevents the situation
            -- where multiple pending schedules target the same slot.
            g_error := 'CHECK_VACANCY_USAGE';
            -- obter primeiro o i_id_dept a partir do id_dcs_requested. Se nao encontrar deve ir para o WHEN OTHERS
            SELECT id_department
              INTO l_id_dept
              FROM dep_clin_serv d
             WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv, -1);
        
            IF NOT check_vacancy_usage(i_lang           => i_lang,
                                       i_id_institution => i_id_institution,
                                       i_id_software    => i_id_software,
                                       i_id_dept        => l_id_dept,
                                       i_flg_sch_type   => i_flg_sch_type,
                                       o_usage          => l_vacancy_usage,
                                       o_sched_w_vac    => l_sched_w_vac,
                                       o_edit_vac       => l_edit_vac,
                                       o_error          => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF (i_flg_vacancy <> pk_schedule_common.g_sched_vacancy_unplanned AND l_vacancy_usage)
            THEN
                g_error := 'GET_GENERIC_EVENT';
                -- Get the event that is actually associated with the vacancies.
                -- It can be a generic event (if the instution has one) or
                -- the event itself.
                IF NOT get_generic_event(i_lang           => i_lang,
                                         i_id_institution => i_id_institution,
                                         i_id_event       => i_id_sch_event,
                                         o_id_event       => l_id_sch_event,
                                         o_error          => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                g_error := 'CALL SET_VACANT_OCCUPIED';
                -- Try to occupy a vacancy
                IF NOT set_vacant_occupied(i_lang             => i_lang,
                                           i_id_institution   => l_id_inst,
                                           i_id_sch_event     => l_id_sch_event,
                                           i_id_professional  => i_id_prof,
                                           i_id_dep_clin_serv => i_id_dep_clin_serv,
                                           i_dt_begin_tstz    => i_dt_begin,
                                           i_flg_sch_type     => i_flg_sch_type,
                                           o_occupied         => o_occupied,
                                           o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                -- Telmo 13-11-2008
                -- actualizar coluna schedule.id_sch_consult_vacancy
                IF o_occupied IS NOT NULL
                   AND NOT alter_schedule(i_lang               => i_lang,
                                          i_id_schedule        => o_id_schedule,
                                          i_id_sch_consult_vac => o_occupied,
                                          o_schedule_rec       => l_schedule_rec,
                                          o_error              => o_error)
                   AND NOT alter_sch_resource(i_lang                   => i_lang,
                                              i_id_sch_resource        => l_sch_resource_rec.id_sch_resource,
                                              i_id_sch_consult_vacancy => o_occupied,
                                              o_error                  => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_schedule;

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
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(18) := 'CREATE_SCHEDULE';
        l_id_inst              department.id_institution%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_schedule_rec         schedule%ROWTYPE;
        l_sch_group_rec        sch_group%ROWTYPE;
        l_sch_resource_rec     sch_resource%ROWTYPE;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_vacancy_usage        BOOLEAN;
        l_reason_notes         schedule.reason_notes%TYPE;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_sched_w_vac          BOOLEAN;
        l_edit_vac             BOOLEAN;
        l_id_dept              dep_clin_serv.id_department%TYPE;
        l_dep_type             sch_event.dep_type%TYPE;
        l_func_exception       EXCEPTION;
    BEGIN
        l_flg_status := i_flg_status;
    
        -- Set default value (when no vacancies are used)
        o_occupied := NULL;
    
        g_error := 'LOAD INSTITUTION';
        -- Load institution 
        SELECT d.id_institution
          INTO l_id_inst
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_department = d.id_department
           AND dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        g_error := 'GET NOTIFICATION DEFAULT';
        -- Get default value for the notification flag
        IF NOT get_notification_default(i_lang             => i_lang,
                                        i_id_dep_clin_serv => i_id_dep_clin_serv,
                                        o_default_value    => l_notification_default,
                                        o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Get reason notes
        IF i_id_reason IS NOT NULL
        THEN
            g_error        := 'GET REASON NOTES';
            l_reason_notes := pk_schedule.string_reason(i_lang      => i_lang,
                                                        i_prof      => profissional(i_id_prof_schedules,
                                                                                    i_id_institution,
                                                                                    i_id_software),
                                                        i_id_reason => i_id_reason,
                                                        i_flg_rtype => NULL);
        ELSE
            -- Custom reason
            l_reason_notes := i_reason_notes;
        END IF;
    
        -- Create schedule
        g_error := 'CALL NEW_SCHEDULE';
        IF NOT new_schedule(i_lang                   => i_lang,
                            i_id_schedule            => i_id_schedule,
                            i_id_instit_requests     => i_id_institution,
                            i_id_instit_requested    => l_id_inst,
                            i_id_dcs_requested       => i_id_dep_clin_serv,
                            i_id_prof_schedules      => i_id_prof_schedules,
                            i_id_prof_requests       => i_id_prof_requests,
                            i_dt_schedule_tstz       => g_sysdate_tstz,
                            i_flg_status             => l_flg_status,
                            i_dt_begin_tstz          => i_dt_begin,
                            i_dt_end_tstz            => i_dt_end,
                            i_schedule_notes         => i_schedule_notes,
                            i_id_lang_translator     => i_id_lang_translator,
                            i_id_lang_preferred      => i_id_lang_preferred,
                            i_id_sch_event           => i_id_sch_event,
                            i_id_reason              => i_id_reason,
                            i_reason_notes           => l_reason_notes,
                            i_id_origin              => i_id_origin,
                            i_id_room                => i_id_room,
                            i_flg_urgency            => g_no,
                            i_flg_vacancy            => i_flg_vacancy,
                            i_flg_notification       => l_notification_default,
                            i_flg_sch_type           => i_flg_sch_type,
                            i_id_schedule_ref        => i_id_schedule_ref,
                            i_flg_instructions       => i_flg_instructions,
                            i_id_complaint           => i_id_complaint,
                            i_flg_request_type       => i_flg_request_type,
                            i_flg_schedule_via       => i_flg_schedule_via,
                            i_id_sch_consult_vacancy => i_id_consult_vac,
                            i_id_episode             => i_id_episode,
                            i_id_sch_recursion       => i_id_sch_recursion,
                            i_id_multidisc           => i_id_multidisc,
                            i_id_sch_combi_detail    => i_id_sch_combi_detail,
                            o_schedule_rec           => l_schedule_rec,
                            o_error                  => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        o_id_schedule := l_schedule_rec.id_schedule;
    
        FOR i IN i_id_patient.first .. i_id_patient.last
        LOOP
            IF NOT pk_schedule_common.new_sch_group(i_lang          => i_lang,
                                                    i_id_schedule   => o_id_schedule,
                                                    i_id_patient    => i_id_patient(i),
                                                    o_sch_group_rec => l_sch_group_rec,
                                                    o_error         => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END LOOP;
    
        -- Create resource allocation
        IF i_id_prof IS NOT NULL
        THEN
            IF NOT pk_schedule_common.new_sch_resource(i_lang                 => i_lang,
                                                       i_id_schedule          => o_id_schedule,
                                                       i_id_institution       => l_id_inst,
                                                       i_id_professional      => i_id_prof,
                                                       i_dt_sch_resource_tstz => g_sysdate_tstz,
                                                       o_sch_resource_rec     => l_sch_resource_rec,
                                                       o_error                => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        --call set_first_obs
        g_error := 'CALL SET_FIRST_OBS';
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => profissional(i_id_prof_schedules,
                                                                                i_id_institution,
                                                                                i_id_software),
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
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
            RETURN FALSE;
        
    END create_schedule;

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
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(30) := 'CREATE_SCHEDULE_MULTIDISC';
        l_id_inst              department.id_institution%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_schedule_rec         schedule%ROWTYPE;
        l_sch_group_rec        sch_group%ROWTYPE;
        l_sch_resource_rec     sch_resource%ROWTYPE;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_vacancy_usage        BOOLEAN;
        l_reason_notes         schedule.reason_notes%TYPE;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_sched_w_vac          BOOLEAN;
        l_edit_vac             BOOLEAN;
        l_id_dept              dep_clin_serv.id_department%TYPE;
        l_dep_type             sch_event.dep_type%TYPE;
        l_func_exception       EXCEPTION;
    BEGIN
        l_flg_status := i_flg_status;
    
        -- Set default value (when no vacancies are used)
        o_occupied := NULL;
    
        g_error := 'LOAD INSTITUTION';
        -- Load institution 
        SELECT d.id_institution
          INTO l_id_inst
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_department = d.id_department
           AND dcs.id_dep_clin_serv = i_id_dep_clin_serv_leader; -- aqui
    
        g_error := 'GET NOTIFICATION DEFAULT';
        -- Get default value for the notification flag
        IF NOT get_notification_default(i_lang             => i_lang,
                                        i_id_dep_clin_serv => i_id_dep_clin_serv_leader, -- aqui
                                        o_default_value    => l_notification_default,
                                        o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Get reason notes
        IF i_id_reason IS NOT NULL
        THEN
            g_error        := 'GET REASON NOTES';
            l_reason_notes := pk_schedule.string_reason(i_lang      => i_lang,
                                                        i_prof      => profissional(i_id_prof_schedules,
                                                                                    i_id_institution,
                                                                                    1),
                                                        i_id_reason => i_id_reason,
                                                        i_flg_rtype => NULL);
        ELSE
            -- Custom reason
            l_reason_notes := i_reason_notes;
        END IF;
    
        -- Create schedule
        g_error := 'CALL NEW_SCHEDULE';
        IF NOT new_schedule(i_lang                   => i_lang,
                            i_id_schedule            => i_id_schedule,
                            i_id_instit_requests     => i_id_institution,
                            i_id_instit_requested    => l_id_inst,
                            i_id_dcs_requested       => i_id_dep_clin_serv_leader,
                            i_id_prof_schedules      => i_id_prof_schedules,
                            i_id_prof_requests       => i_id_prof_requests,
                            i_dt_schedule_tstz       => g_sysdate_tstz,
                            i_flg_status             => l_flg_status,
                            i_dt_begin_tstz          => i_dt_begin,
                            i_dt_end_tstz            => i_dt_end,
                            i_schedule_notes         => i_schedule_notes,
                            i_id_lang_translator     => i_id_lang_translator,
                            i_id_lang_preferred      => i_id_lang_preferred,
                            i_id_sch_event           => i_id_sch_event,
                            i_id_reason              => i_id_reason,
                            i_reason_notes           => l_reason_notes,
                            i_id_origin              => i_id_origin,
                            i_id_room                => i_id_room,
                            i_flg_urgency            => g_no,
                            i_flg_vacancy            => i_flg_vacancy,
                            i_flg_notification       => l_notification_default,
                            i_flg_sch_type           => i_flg_sch_type,
                            i_id_schedule_ref        => i_id_schedule_ref,
                            i_flg_instructions       => i_flg_instructions,
                            i_id_complaint           => i_id_complaint,
                            i_flg_request_type       => i_flg_request_type,
                            i_flg_schedule_via       => i_flg_schedule_via,
                            i_id_sch_consult_vacancy => NULL,
                            i_id_episode             => i_id_episode,
                            i_id_sch_recursion       => i_id_sch_recursion,
                            i_id_multidisc           => i_id_multidisc,
                            i_id_sch_combi_detail    => i_id_sch_combi_detail,
                            o_schedule_rec           => l_schedule_rec,
                            o_error                  => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        o_id_schedule := l_schedule_rec.id_schedule;
    
        -- Create schedule group
        g_error := 'CALL NEW_SCH_GROUP';
        FOR i IN i_id_patient.first .. i_id_patient.last
        LOOP
            IF NOT pk_schedule_common.new_sch_group(i_lang          => i_lang,
                                                    i_id_schedule   => o_id_schedule,
                                                    i_id_patient    => i_id_patient(i),
                                                    o_sch_group_rec => l_sch_group_rec,
                                                    o_error         => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END LOOP;
    
        -- Create resource allocation
        IF i_id_prof_list.count > 0
        THEN
            FOR idx IN i_id_prof_list.first .. i_id_prof_list.last
            LOOP
                IF NOT pk_schedule_common.new_sch_resource(i_lang                   => i_lang,
                                                           i_id_schedule            => o_id_schedule,
                                                           i_id_institution         => l_id_inst,
                                                           i_id_professional        => i_id_prof_list(idx),
                                                           i_dt_sch_resource_tstz   => g_sysdate_tstz,
                                                           i_id_prof_leader         => i_id_prof_leader,
                                                           i_id_sch_consult_vacancy => i_id_consult_vac_list(idx),
                                                           o_sch_resource_rec       => l_sch_resource_rec,
                                                           o_error                  => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END LOOP;
        END IF;
    
        --call set_first_obs
        g_error := 'CALL SET_FIRST_OBS';
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => profissional(i_id_prof_schedules,
                                                                                i_id_institution,
                                                                                i_id_software),
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        IF NOT i_ignore_vacancies
        THEN
            -- Increment vacancy usage (for schedule types that require so). 
            -- Note: even if the schedule is still on the pending state,
            -- the vacancy is used anyway. This prevents the situation
            -- where multiple pending schedules target the same slot.
            g_error := 'CHECK_VACANCY_USAGE';
            -- obter primeiro o i_id_dept a partir do id_dcs_requested. Se nao encontrar deve ir para o WHEN OTHERS
            SELECT id_department
              INTO l_id_dept
              FROM dep_clin_serv d
             WHERE d.id_dep_clin_serv = nvl(i_id_dep_clin_serv_leader, -1);
        
            IF NOT check_vacancy_usage(i_lang           => i_lang,
                                       i_id_institution => i_id_institution,
                                       i_id_software    => i_id_software,
                                       i_id_dept        => l_id_dept,
                                       i_flg_sch_type   => i_flg_sch_type,
                                       o_usage          => l_vacancy_usage,
                                       o_sched_w_vac    => l_sched_w_vac,
                                       o_edit_vac       => l_edit_vac,
                                       o_error          => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF l_vacancy_usage
            THEN
                g_error := 'GET_GENERIC_EVENT';
                -- Get the event that is actually associated with the vacancies.
                -- It can be a generic event (if the instution has one) or
                -- the event itself.
                IF NOT get_generic_event(i_lang           => i_lang,
                                         i_id_institution => i_id_institution,
                                         i_id_event       => i_id_sch_event,
                                         o_id_event       => l_id_sch_event,
                                         o_error          => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                --ALERT-10118. Verificar se o evento pertence ao tipo MFR (PM) ou oris
                IF NOT get_dep_type(i_lang         => i_lang,
                                    i_prof         => profissional(i_id_prof_schedules, i_id_institution, i_id_software),
                                    i_id_sch_event => l_id_sch_event,
                                    o_dep_type     => l_dep_type,
                                    o_error        => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                -- Try to occupy a vacancy
                g_error := 'CALL SET_VACANT_OCCUPIED';
                IF i_id_consult_vac_list IS NOT NULL
                THEN
                    IF (l_dep_type = g_sch_dept_flg_dep_type_pm AND
                       l_flg_status <> pk_schedule.g_sched_status_temporary)
                       OR l_dep_type = g_sch_dept_flg_dep_type_sr
                    THEN
                        IF NOT set_vacant_occupied_by_id_mfr(i_lang       => i_lang,
                                                             i_id_vacancy => i_id_consult_vac_list(1),
                                                             o_occupied   => o_occupied,
                                                             o_error      => o_error)
                        THEN
                            RAISE l_func_exception;
                        END IF;
                    ELSIF l_dep_type <> g_sch_dept_flg_dep_type_pm
                    THEN
                    
                        -- Loop for all vacancies
                        FOR idx IN i_id_consult_vac_list.first .. i_id_consult_vac_list.last
                        LOOP
                            IF NOT set_vacant_occupied_by_id(i_lang       => i_lang,
                                                             i_id_vacancy => i_id_consult_vac_list(idx),
                                                             o_occupied   => o_occupied,
                                                             o_error      => o_error)
                            THEN
                                RAISE l_func_exception;
                            END IF;
                        END LOOP;
                    
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
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
            RETURN FALSE;
        
    END create_schedule_multidisc;

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
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(18) := 'GET_CONSULT_TYPE';
        l_return    VARCHAR2(1) := NULL;
    BEGIN
    
        g_error := 'Get consult_type';
        BEGIN
            SELECT nvl(flg_type, g_consult_direct)
              INTO l_return
              FROM dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = i_dep_clin_serv;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN g_consult_direct;
        END;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_return := NULL;
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_return;
    END get_consult_type;
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
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * Alterado id_software do agendamento para o id do OUTP, no caso de agendamentos do EDIS. 
    * O mesmo foi previamente feito para o caso do INP. Faz com que os agendamentos aparecam no OUTP
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    30-07-2008
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
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(32) := 'CREATE_SCHEDULE_OUTP';
        l_outp_software_conf VARCHAR2(32) := 'SOFTWARE_ID_OUTP';
        l_care_software_conf VARCHAR2(32) := 'SOFTWARE_ID_CARE';
        --l_clin_software_conf   VARCHAR2(32) := 'SOFTWARE_ID_CLINICS';
        l_inp_software_conf  VARCHAR2(32) := 'SOFTWARE_ID_INP';
        l_edis_software_conf VARCHAR2(32) := 'SOFTWARE_ID_EDIS';
        l_ref_software_conf  VARCHAR2(32) := 'SOFTWARE_ID_P1';
        l_id_software        sys_config.value%TYPE;
        l_id_software_ref    sys_config.value%TYPE;
        l_id_software_care   sys_config.value%TYPE;
        l_id_software_edis   sys_config.value%TYPE;
        l_flg_type           schedule_outp.flg_type%TYPE;
        l_epis_type          sys_config.value%TYPE;
        l_flg_sched          schedule_outp.flg_sched%TYPE;
        o_schedule_outp_rec  schedule_outp%ROWTYPE;
        o_sch_prof_outp_rec  sch_prof_outp%ROWTYPE;
        l_target_prof        sch_event.flg_target_professional%TYPE;
        l_compare            NUMBER;
        l_date_compare       VARCHAR2(1);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET INPATIENT SOFTWARE';
        -- Get the inpatient software
        IF NOT get_config(i_lang           => i_lang,
                          i_id_sysconfig   => l_inp_software_conf,
                          i_id_institution => i_id_institution,
                          i_id_software    => i_id_software,
                          o_config         => l_id_software,
                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT get_config(i_lang           => i_lang,
                          i_id_sysconfig   => l_ref_software_conf,
                          i_id_institution => i_id_institution,
                          i_id_software    => i_id_software,
                          o_config         => l_id_software_ref,
                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET EDIS SOFTWARE';
        -- Get the edis software
        IF NOT get_config(i_lang           => i_lang,
                          i_id_sysconfig   => l_edis_software_conf,
                          i_id_institution => i_id_institution,
                          i_id_software    => i_id_software,
                          o_config         => l_id_software_edis,
                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_id_software = i_id_software
           OR l_id_software_edis = i_id_software
           OR l_id_software_ref = i_id_software
        THEN
            -- The appointment is being created via Inpatient. So, the software to use is Outpatient.
            g_error := 'GET OUTPATIENT SOFTWARE';
            -- Get the outpatient software
            IF NOT get_config(i_lang           => i_lang,
                              i_id_sysconfig   => l_outp_software_conf,
                              i_id_institution => i_id_institution,
                              i_id_software    => i_id_software,
                              o_config         => l_id_software,
                              o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            -- Create the appointment using the software used by the professional.
            l_id_software := i_id_software;
        END IF;
    
        g_error := 'GET EPISODE TYPE';
        IF i_id_epis_type IS NOT NULL
        THEN
            l_epis_type := i_id_epis_type;
        ELSE
            -- Get episode type
            IF NOT get_sch_event_epis_type(i_lang,
                                           i_id_sch_event => i_id_sch_event,
                                           i_id_inst      => i_id_institution,
                                           i_id_software  => i_id_software,
                                           o_epis_type    => l_epis_type,
                                           o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_epis_type IS NULL
               AND NOT get_config(i_lang           => i_lang,
                                  i_id_sysconfig   => pk_schedule.g_sched_epis_type_config,
                                  i_id_institution => i_id_institution,
                                  i_id_software    => to_number(l_id_software),
                                  o_config         => l_epis_type,
                                  o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET CARE SOFTWARE';
        -- Get the CARE software
        IF NOT get_config(i_lang           => i_lang,
                          i_id_sysconfig   => l_care_software_conf,
                          i_id_institution => i_id_institution,
                          i_id_software    => i_id_software,
                          o_config         => l_id_software_care,
                          o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_id_software_care = i_id_software
        THEN
        
            g_error := 'COMPARE DATES';
            SELECT pk_date_utils.get_timestamp_diff(pk_date_utils.trunc_insttimezone(profissional(i_id_prof_schedules,
                                                                                                  i_id_institution,
                                                                                                  i_id_software),
                                                                                     i_dt_begin),
                                                    pk_date_utils.trunc_insttimezone(profissional(i_id_prof_schedules,
                                                                                                  i_id_institution,
                                                                                                  i_id_software),
                                                                                     g_sysdate_tstz)
                                                    
                                                    )
              INTO l_compare
              FROM dual;
            IF l_compare >= 1
            THEN
                l_date_compare := g_date_greater;
            ELSE
                l_date_compare := g_date_minor;
            END IF;
            -- Get event type and target
            g_error := 'GET EVENT TYPE AND TARGET';
            SELECT CASE
                        WHEN se.flg_is_group = pk_alert_constant.g_yes THEN
                         se.flg_schedule_outp_type
                        WHEN se.dep_type = g_sch_dept_flg_dep_type_cm THEN
                         se.flg_schedule_outp_type
                        ELSE
                         decode(i_flg_sched_type,
                                g_val_spresenca,
                                g_val_indirect,
                                decode(l_date_compare,
                                       g_date_greater,
                                       decode(se.flg_occurrence,
                                              pk_schedule.g_event_occurrence_first,
                                              g_val_fprogramada,
                                              g_val_programada),
                                       decode(se.flg_occurrence,
                                              pk_schedule.g_event_occurrence_first,
                                              g_val_fdia,
                                              g_val_dia)))
                    END flg_schedule_outp_type,
                   --se.flg_schedule_outp_type,
                   se.flg_target_professional,
                   decode(se.flg_occurrence,
                          pk_schedule.g_event_occurrence_first,
                          pk_schedule_outp.g_schedule_outp_flg_type_first,
                          pk_schedule.g_event_occurrence_subs,
                          pk_schedule_outp.g_schedule_outp_flg_type_subs,
                          '')
              INTO l_flg_sched, l_target_prof, l_flg_type
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event;
        
        ELSE
        
            g_error := 'GET EVENT TYPE AND TARGET';
            -- Get event type and target
            SELECT se.flg_schedule_outp_type,
                   se.flg_target_professional,
                   decode(se.flg_occurrence,
                          pk_schedule.g_event_occurrence_first,
                          pk_schedule_outp.g_schedule_outp_flg_type_first,
                          pk_schedule.g_event_occurrence_subs,
                          pk_schedule_outp.g_schedule_outp_flg_type_subs,
                          '')
              INTO l_flg_sched, l_target_prof, l_flg_type
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event;
        
        END IF;
    
        g_error := 'CREATE SCHEDULE OUTP';
        -- Create outpatient-specific schedule
        IF NOT new_schedule_outp(i_lang              => i_lang,
                                 i_id_schedule       => i_id_schedule,
                                 i_dt_target_tstz    => i_dt_begin,
                                 i_flg_state         => pk_schedule.g_status_scheduled,
                                 i_flg_sched         => l_flg_sched,
                                 i_id_software       => to_number(l_id_software),
                                 i_id_epis_type      => l_epis_type,
                                 i_flg_type          => l_flg_type,
                                 i_flg_sched_type    => i_flg_sched_type,
                                 o_schedule_outp_rec => o_schedule_outp_rec,
                                 o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CREATE SCHEDULE PROF OUTP';
        -- Create outpatient schedule's professional
        IF l_target_prof = pk_schedule.g_yes
        THEN
            IF NOT new_sch_prof_outp(i_id_professional   => i_id_prof,
                                     i_id_schedule_outp  => o_schedule_outp_rec.id_schedule_outp,
                                     o_sch_prof_outp_rec => o_sch_prof_outp_rec,
                                     o_error             => o_error)
            THEN
                RETURN FALSE;
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
            RETURN FALSE;
        
    END create_schedule_outp;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(15) := 'NEW_CONSULT_REQ';
        l_rowids    table_varchar;
    BEGIN
    
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_consult_req IS NOT NULL)
        THEN
            o_consult_req_rec.id_consult_req := i_id_consult_req;
        ELSE
        
            o_consult_req_rec.id_consult_req := ts_consult_req.next_key();
        END IF;
        -- Create record
        g_error                               := 'CREATE RECORD';
        o_consult_req_rec.dt_consult_req_tstz := i_dt_consult_req_tstz;
        o_consult_req_rec.consult_type        := i_consult_type;
        o_consult_req_rec.id_clinical_service := i_id_clinical_service;
        o_consult_req_rec.id_patient          := i_id_patient;
        o_consult_req_rec.id_instit_requests  := i_id_instit_requests;
        o_consult_req_rec.id_inst_requested   := i_id_inst_requested;
        o_consult_req_rec.id_episode          := i_id_episode;
        o_consult_req_rec.id_prof_req         := i_id_prof_req;
        o_consult_req_rec.id_prof_auth        := i_id_prof_auth;
        o_consult_req_rec.id_prof_appr        := i_id_prof_appr;
        o_consult_req_rec.id_prof_proc        := i_id_prof_proc;
        o_consult_req_rec.dt_scheduled_tstz   := i_dt_scheduled_tstz;
        o_consult_req_rec.notes               := i_notes;
        o_consult_req_rec.id_prof_cancel      := i_id_prof_cancel;
        o_consult_req_rec.dt_cancel_tstz      := i_dt_cancel_tstz;
        o_consult_req_rec.notes_cancel        := i_notes_cancel;
        o_consult_req_rec.id_dep_clin_serv    := i_id_dep_clin_serv;
        o_consult_req_rec.id_prof_requested   := i_id_prof_requested;
        o_consult_req_rec.flg_status          := i_flg_status;
        o_consult_req_rec.notes_admin         := i_notes_admin;
        o_consult_req_rec.id_schedule         := i_id_schedule;
        o_consult_req_rec.next_visit_in_notes := i_next_visit_in_notes;
        o_consult_req_rec.flg_instructions    := i_flg_instructions;
        o_consult_req_rec.id_complaint        := i_id_complaint;
        o_consult_req_rec.flg_type_date       := i_flg_type_date;
        -- Insert record
        g_error := 'INSERT RECORD';
    
        ts_consult_req.ins(rec_in => o_consult_req_rec, rows_out => l_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => profissional(i_id_prof_req, i_id_instit_requests, 0),
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_consult_req_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_consult_req;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32);
    BEGIN
        l_func_name := 'NEW_CONSULT_REQ_PROF';
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_consult_req_prof IS NOT NULL)
        THEN
            o_consult_req_prof_rec.id_consult_req_prof := i_id_consult_req_prof;
        ELSE
            SELECT seq_consult_req_prof.nextval
              INTO o_consult_req_prof_rec.id_consult_req_prof
              FROM dual;
        END IF;
        -- Create record
        g_error                                         := 'CREATE RECORD';
        o_consult_req_prof_rec.dt_consult_req_prof_tstz := i_dt_consult_req_prof_tstz;
        o_consult_req_prof_rec.id_consult_req           := i_id_consult_req;
        o_consult_req_prof_rec.id_professional          := i_id_professional;
        o_consult_req_prof_rec.denial_justif            := i_denial_justif;
        o_consult_req_prof_rec.flg_status               := i_flg_status;
        o_consult_req_prof_rec.dt_scheduled_tstz        := i_dt_scheduled_tstz;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO consult_req_prof
        VALUES o_consult_req_prof_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_consult_req_prof_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_consult_req_prof;

    /**
    * Creates a new record on schedule_outp.
    *
    * @param i_lang               Language identifier
    * @param i_id_schedule_outp   Identifier       
    * @param i_id_schedule        Schedule identifier
    * @param i_dt_target_tstz       Schedule date
    * @param i_flg_state          State
    * @param i_flg_sched          N - 1ª enfermagem, F - subsequente enfermagem, I - internamento, S - internamento para cirurgia, V - tratamento feridas, T - administração medicamentos, I - informações   
    D - primeira médica; M - subsequente médica; P - primeira de especialidade; Q - subsequente especialidade
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCHEDULE_OUTP';
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_schedule_outp IS NOT NULL)
        THEN
            o_schedule_outp_rec.id_schedule_outp := i_id_schedule_outp;
        ELSE
            SELECT seq_schedule_outp.nextval
              INTO o_schedule_outp_rec.id_schedule_outp
              FROM dual;
        END IF;
        -- Create record
        g_error                            := 'CREATE RECORD';
        o_schedule_outp_rec.id_schedule    := i_id_schedule;
        o_schedule_outp_rec.dt_target_tstz := i_dt_target_tstz;
        o_schedule_outp_rec.flg_state      := i_flg_state;
        o_schedule_outp_rec.flg_sched      := i_flg_sched;
        o_schedule_outp_rec.id_software    := i_id_software;
        o_schedule_outp_rec.id_epis_type   := i_id_epis_type;
        o_schedule_outp_rec.flg_type       := i_flg_type;
        o_schedule_outp_rec.flg_sched_type := i_flg_sched_type;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO schedule_outp
        VALUES o_schedule_outp_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedule_outp_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_schedule_outp;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NEW_SCH_PROF_OUTP';
        l_rows_ei   table_varchar;
    BEGIN
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_sch_prof_outp IS NOT NULL)
        THEN
            o_sch_prof_outp_rec.id_sch_prof_outp := i_id_sch_prof_outp;
        ELSE
            SELECT seq_sch_prof_outp.nextval
              INTO o_sch_prof_outp_rec.id_sch_prof_outp
              FROM dual;
        END IF;
        -- Create record
        g_error                              := 'CREATE RECORD';
        o_sch_prof_outp_rec.id_professional  := i_id_professional;
        o_sch_prof_outp_rec.id_schedule_outp := i_id_schedule_outp;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO sch_prof_outp
        VALUES o_sch_prof_outp_rec;
    
        ts_epis_info.upd(sch_prof_outp_id_prof_in => i_id_professional,
                         where_in                 => 'ID_SCHEDULE_OUTP = ' || i_id_schedule_outp,
                         rows_out                 => l_rows_ei);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => profissional(0, 0, 0),
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('SCH_PROF_OUTP_ID_PROF'));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_prof_outp_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_sch_prof_outp;

    /* finds all vacancy intersections between all profs in table sch_tmptab_vacs or sch_tmptab_full_vacs.
    * A vacancy intersection is when there is at least one vacancy for each different professional that start at same time.
    * only those vacancies are left in the GTT.
    *
    * @param i_lang       lang id
    * @param i_prof       prof id
    * @param i_profcount  prof count used for knowing how many professionals are in the multidisc app
    * @param i_fulltable  Y = lookup in sch_tmptab_full_vacs  N = lookup in sch_tmptab_vacs
    * @param o_error      error data
    *
    * @author   Telmo
    * @date     18-06-2009
    * @version  2.5.0.4
    */
    FUNCTION get_multidisc_vacancies
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_profcount IN NUMBER,
        i_fulltable IN VARCHAR2 DEFAULT 'N',
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_MULTIDISC_VACANCIES';
        l_goodvacancies table_number := table_number();
    BEGIN
    
        IF i_fulltable = g_no
        THEN
            -- pick vacancies 
            g_error := 'FETCH OVERLAPPING VACANCIES OF ALL PROFS';
            SELECT stv1.id_sch_consult_vacancy
              BULK COLLECT
              INTO l_goodvacancies
              FROM sch_consult_vacancy scv1
              JOIN sch_tmptab_vacs stv1
                ON scv1.id_sch_consult_vacancy = stv1.id_sch_consult_vacancy
             WHERE scv1.dt_begin_tstz IN (SELECT t.dt_begin_tstz
                                            FROM (SELECT scv.dt_begin_tstz, scv.id_prof
                                                    FROM sch_consult_vacancy scv
                                                    JOIN sch_tmptab_vacs stv
                                                      ON scv.id_sch_consult_vacancy = stv.id_sch_consult_vacancy
                                                   GROUP BY scv.dt_begin_tstz, scv.id_prof) t
                                           GROUP BY t.dt_begin_tstz
                                          HAVING COUNT(*) = nvl(i_profcount, 0));
        
            --delete vacancies not overlapping
            g_error := 'DELETE NON-OVERLAPPING VACANCIES';
            DELETE sch_tmptab_vacs t
             WHERE t.id_sch_consult_vacancy NOT IN (SELECT column_value
                                                      FROM TABLE(l_goodvacancies));
        ELSE
            -- pick vacancies 
            g_error := 'FETCH OVERLAPPING VACANCIES OF ALL PROFS';
            SELECT stv1.id_sch_consult_vacancy
              BULK COLLECT
              INTO l_goodvacancies
              FROM sch_consult_vacancy scv1
              JOIN sch_tmptab_full_vacs stv1
                ON scv1.id_sch_consult_vacancy = stv1.id_sch_consult_vacancy
             WHERE scv1.dt_begin_tstz IN (SELECT t.dt_begin_tstz
                                            FROM (SELECT dt_begin_tstz, id_prof
                                                    FROM sch_tmptab_full_vacs stv
                                                   GROUP BY dt_begin_tstz, id_prof) t
                                           GROUP BY t.dt_begin_tstz
                                          HAVING COUNT(*) = nvl(i_profcount, 0));
        
            --delete vacancies not overlapping
            g_error := 'DELETE NON-OVERLAPPING VACANCIES';
            DELETE sch_tmptab_full_vacs t
             WHERE t.id_sch_consult_vacancy NOT IN (SELECT column_value
                                                      FROM TABLE(l_goodvacancies));
        
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
            RETURN FALSE;
    END get_multidisc_vacancies;

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
    *
    * UPDATED
    * melhorias de performance. IN trocados por EXISTS, hint NL_SJ, limpeza do join principal, simplificação de alguns filtros
    * @author  Telmo Castro 
    * @date     25-09-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * ALERT-17213 - passei o filtro da duracao para o get_schedules
    * @author  Telmo Castro
    * @date    11-02-2009
    * @version 2.4.4
    *
    * UPDATED
    * ALERT-708 - pesquisa por vagas livres.
    * @author   Telmo Castro
    * @date     25-03-2009
    * @version  2.5
    *
    * UPDATED
    * ALERT-707 - pesquisa avancada por time deve prever agendas onde dt_end_tstz e null
    * @author   Telmo Castro
    * @date     14-04-2009
    * @version  2.5
    *
    * UPDATED
    * ALERT-31987 - output da get_vacancies passa a ser a GTT sch_tmptab_vacs em vez do table_number
    * @author  Telmo
    * @date    12-06-2009
    * @version 2.5.0.4
    *
    * UPDATED
    * ALERT-28024 - making appointments. vacancies post processing for single visits and multidisciplinary appoints.
    *
    * UPDATED 
    * ALERT-49860 - performance improvement
    * @author  Telmo, Vasco Rocha
    * @date    15-10-2009
    * @version 2.5.0.7
    *
    * UPDATED 
    * ALERT-8202 criterio de pesquisa por exames deixa de existir
    * @author  Telmo
    * @date    16-10-2009
    * @version 2.5.0.7
    */
    FUNCTION get_vacancies
    (
        i_lang  IN language.id_language%TYPE DEFAULT NULL,
        i_prof  IN profissional,
        i_args  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_VACANCIES';
        l_start_ts     TIMESTAMP WITH TIME ZONE := NULL;
        l_end_ts       TIMESTAMP WITH TIME ZONE := NULL;
        l_only_vacs    VARCHAR2(1) := g_no;
        i              INTEGER;
        l_dummy        NUMBER;
        l_id_sch_event sch_event.id_sch_event%TYPE;
    
        l_list_dep    table_number := pk_schedule.get_list_number_csv(i_args(idx_id_dep));
        l_list_dcs    table_number := pk_schedule.get_list_number_csv(i_args(idx_id_dep_clin_serv));
        l_list_event  table_number := pk_schedule.get_list_number_csv(i_args(idx_event));
        l_list_prof   table_number := pk_schedule.get_list_number_csv(i_args(idx_id_prof));
        l_list_status table_varchar := pk_schedule.get_list_string_csv(i_args(idx_status));
    
    BEGIN
        -- empty workbench
        g_error := 'TRUNCATE TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_ARGS';
    
        g_error := 'TRUNCATE VACANCIES TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_VACS';
    
        -- fill auxiliary GTTs
        g_error := 'FILL TEMPORARY TABLE';
        INSERT INTO sch_tmptab_args
            SELECT idx_id_dep, column_value
              FROM TABLE(l_list_dep);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_id_dep_clin_serv, column_value
              FROM TABLE(l_list_dcs);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_event, column_value
              FROM TABLE(l_list_event);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_id_prof, column_value
              FROM TABLE(l_list_prof);
    
        -- special var
        g_error := 'CALC L_ONLY_VACS';
        i       := l_list_status.first;
        WHILE i IS NOT NULL
              AND l_only_vacs = g_no
        LOOP
            IF l_list_status(i) = g_onlyfreevacs
            THEN
                l_only_vacs := g_yes;
            END IF;
            i := l_list_status.next(i);
        END LOOP;
    
        -- Get proper start timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_start_ts';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(idx_dt_begin),
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get proper end timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_end_ts';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(idx_dt_end),
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- big daddy
        g_error := 'INSERT INTO SCH_TMPTAB_VACS';
        INSERT INTO sch_tmptab_vacs
            SELECT /*+LEADING (sd)*/
             scv.id_sch_consult_vacancy,
             pk_date_utils.trunc_insttimezone(i_prof, scv.dt_begin_tstz),
             max_vacancies,
             used_vacancies
              FROM sch_consult_vacancy scv
              JOIN sch_event se
                ON (scv.id_sch_event = se.id_sch_event)
              JOIN sch_department sd
                ON (se.dep_type = sd.flg_dep_type)
             WHERE
            --filter by institution
             scv.id_institution = i_args(idx_id_inst)
            --filter by department
             AND EXISTS
             (SELECT /*+NL_SJ*/
               1
                FROM sch_tmptab_args
               WHERE argtype = idx_id_dep
                 AND id = sd.id_department)
            --filter by begin and end date
             AND scv.dt_begin_tstz >= l_start_ts
             AND (i_args(idx_dt_end) IS NULL OR (scv.dt_begin_tstz < l_end_ts))
            --filter by DCS. DCS cannot be null. It can be 'All' or a list of DCSs.
             AND (i_args(idx_id_dep_clin_serv) IS NULL OR EXISTS
              (SELECT /*+NL_SJ*/
                1
                 FROM sch_tmptab_args
                WHERE argtype = idx_id_dep_clin_serv
                  AND id = scv.id_dep_clin_serv))
            --Filter by events
             AND (i_args(idx_event) IS NULL OR EXISTS (SELECT /*+NL_SJ*/
                                                    1
                                                     FROM sch_tmptab_args
                                                    WHERE argtype = idx_event
                                                      AND id = scv.id_sch_event))
            --Filter by Professional. prof can be null or a list of profs
             AND (i_args(idx_id_prof) IS NULL OR EXISTS (SELECT /*+NL_SJ*/
                                                      1
                                                       FROM sch_tmptab_args
                                                      WHERE argtype = idx_id_prof
                                                        AND id = scv.id_prof))
            --Filter by exam or analysis
             AND (sd.flg_dep_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_as,
                                  pk_schedule_common.g_sch_dept_flg_dep_type_oexams))
            -- only free vacancies
             AND (l_only_vacs = g_no OR scv.max_vacancies - scv.used_vacancies > 0)
            -- only active vacancies
             AND scv.flg_status = pk_schedule_bo.g_status_active
            --filter by start and end time 
             AND (i_args(idx_time_begin) IS NULL OR
             pk_date_utils.to_char_insttimezone(i_prof, dt_begin_tstz, pk_schedule.g_default_time_mask) >=
             i_args(idx_time_begin))
             AND (i_args(idx_time_end) IS NULL OR dt_end_tstz IS NULL OR
             pk_date_utils.to_char_insttimezone(i_prof, dt_end_tstz, pk_schedule.g_default_time_mask) <=
             i_args(idx_time_end))
            -- filter in permissions
             AND EXISTS (SELECT 1
                FROM sch_permission sp
               WHERE scv.id_sch_event = sp.id_sch_event
                 AND (scv.id_prof IS NULL OR scv.id_prof = sp.id_prof_agenda)
                 AND sp.id_dep_clin_serv = scv.id_dep_clin_serv
                 AND sp.id_institution = scv.id_institution
                 AND sp.id_professional = i_prof.id
                 AND sp.flg_permission <> pk_schedule.g_permission_none);
    
        -- post processing for multidisciplinary event
        BEGIN
            SELECT 1
              INTO l_dummy
              FROM sch_tmptab_args t
             WHERE t.argtype = idx_event
               AND t.id = pk_schedule.g_event_multidisc
               AND rownum = 1;
        
            -- multidisc event found. lets check if its generic
            IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                        i_id_institution => i_prof.institution,
                                                        i_id_event       => pk_schedule.g_event_multidisc,
                                                        o_id_event       => l_id_sch_event,
                                                        o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_id_sch_event <> pk_schedule.g_event_multidisc
            THEN
                -- its generic. Afraid you have to get dirty, lad
                IF NOT get_multidisc_vacancies(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_profcount => l_list_prof.count,
                                               i_fulltable => g_no,
                                               o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
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
            RETURN FALSE;
    END get_vacancies;

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
    *
    * UPDATED
    * DBImprovements - sch_event_type demise  
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.4
    *
    * UPDATED
    * melhorias de performance. IN trocados por EXISTS, hint NL_SJ, limpeza do join principal, simplificação de alguns filtros
    * @author  Telmo Castro 
    * @date     24-10-2008
    * @version  2.4.4
    *
    * UPDATED
    * ALERT-17213 - passei o filtro da duracao para o get_schedules
    * @author  Telmo Castro
    * @date    11-02-2009
    * @version 2.4.4
    *
    * UPDATED
    * ALERT-707 - pesquisa avancada por time deve prever agendas onde dt_end_tstz e null
    * @author   Telmo Castro
    * @date     14-04-2009
    * @version  2.5
    */
    FUNCTION get_schedules
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_args       IN table_varchar,
        o_schedules  OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULES';
    
        l_list_dep         table_number := pk_schedule.get_list_number_csv(i_args(idx_id_dep));
        l_list_dcs         table_number := pk_schedule.get_list_number_csv(i_args(idx_id_dep_clin_serv));
        l_list_event       table_number := pk_schedule.get_list_number_csv(i_args(idx_event));
        l_list_prof        table_number := pk_schedule.get_list_number_csv(i_args(idx_id_prof));
        l_list_exams       table_number := pk_schedule.get_list_number_csv(i_args(idx_id_exam));
        l_list_duration    table_number := pk_schedule.get_list_number_csv(i_args(idx_duration));
        l_list_pref_langs  table_number := pk_schedule.get_list_number_csv(i_args(idx_preferred_lang));
        l_list_types       table_varchar := pk_schedule.get_list_string_csv(i_args(idx_type));
        l_list_status      table_varchar := pk_schedule.get_list_string_csv(i_args(idx_status));
        l_list_reasons     table_number := pk_schedule.get_list_number_csv(i_args(idx_id_reason));
        l_list_trans_langs table_number := pk_schedule.get_list_number_csv(i_args(idx_translation_needs));
        l_list_origin      table_number := pk_schedule.get_list_number_csv(i_args(idx_id_origin));
        l_list_room        table_number := pk_schedule.get_list_number_csv(i_args(idx_id_room));
    
        l_start_ts TIMESTAMP WITH TIME ZONE := NULL;
        l_end_ts   TIMESTAMP WITH TIME ZONE := NULL;
    
        CURSOR c_schedules
        (
            i_start_ts TIMESTAMP WITH TIME ZONE,
            i_end_ts   TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT id_schedule
              FROM (SELECT s.id_schedule, s.dt_begin_tstz dt_begin, s.dt_end_tstz dt_end
                      FROM schedule       s,
                           sch_resource   sr,
                           sch_group      sg,
                           sch_event      se,
                           sch_department sd,
                           patient        pat,
                           dep_clin_serv  dcs,
                           schedule_outp  so
                     WHERE s.id_schedule = sr.id_schedule(+)
                       AND s.id_schedule = sg.id_schedule
                       AND s.id_sch_event = se.id_sch_event
                       AND s.flg_sch_type = sd.flg_dep_type
                       AND s.id_instit_requested = i_args(idx_id_inst) --i_prof.institution
                       AND se.dep_type = sd.flg_dep_type
                       AND sd.id_department IN (SELECT DISTINCT id_department
                                                  FROM prof_dep_clin_serv pdcs
                                                 INNER JOIN dep_clin_serv dxs
                                                    ON pdcs.id_dep_clin_serv = dxs.id_dep_clin_serv
                                                 WHERE pdcs.id_professional = i_prof.id)
                       AND sg.id_patient = pat.id_patient
                       AND s.id_dcs_requested = dcs.id_dep_clin_serv
                       AND s.id_schedule = so.id_schedule(+)
                          -- Filter by department
                       AND (i_args(idx_id_dep) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_id_dep
                                AND id = sd.id_department))
                          -- Filter by type
                       AND (s.flg_sch_type = g_sch_dept_flg_dep_type_exam OR
                           s.flg_sch_type = g_sch_dept_flg_dep_type_oexams OR
                           (s.flg_sch_type = g_sch_dept_flg_dep_type_cons AND so.id_schedule_outp IS NOT NULL) OR
                           (s.flg_sch_type = g_sch_dept_flg_dep_type_nurs AND so.id_schedule_outp IS NOT NULL) OR
                           (s.flg_sch_type = g_sch_dept_flg_dep_type_nut AND so.id_schedule_outp IS NOT NULL) OR
                           (s.flg_sch_type = g_sch_dept_flg_dep_type_as AND so.id_schedule_outp IS NOT NULL))
                          -- Filter by date
                       AND s.dt_begin_tstz >= i_start_ts
                       AND (i_args(idx_dt_end) IS NULL OR s.dt_begin_tstz < i_end_ts)
                          -- Filter by DCS                             
                       AND (i_args(idx_id_dep_clin_serv) IS NULL AND s.id_instit_requested = i_args(idx_id_inst) OR
                           EXISTS (SELECT /*+NL_SJ*/
                                    1
                                     FROM sch_tmptab_args
                                    WHERE argtype = idx_id_dep_clin_serv
                                      AND id = s.id_dcs_requested))
                          -- Filter by event
                       AND (i_args(idx_event) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_event
                                AND id = s.id_sch_event))
                          -- Filter by professional
                       AND (i_args(idx_id_prof) IS NULL OR sr.id_professional IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_id_prof
                                AND id = sr.id_professional))
                          -- Filter by preferred language
                       AND (i_args(idx_preferred_lang) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_preferred_lang
                                AND id = s.id_lang_preferred))
                          -- Filter by vacancy type
                       AND (i_args(idx_type) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_vargs
                              WHERE argtype = idx_type
                                AND id = s.flg_vacancy))
                          -- Filter by status
                       AND (i_args(idx_status) IS NULL OR s.flg_status = pk_schedule.g_status_pending OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_vargs
                              WHERE argtype = idx_status
                                AND id = s.flg_status))
                          -- Filter by reason
                       AND ((i_args(idx_id_reason) IS NOT NULL AND
                           (EXISTS (SELECT /*+NL_SJ*/
                                       1
                                        FROM sch_tmptab_args
                                       WHERE argtype = idx_id_reason
                                         AND id = s.id_reason))) OR
                           (i_args(idx_id_reason) IS NULL AND
                           (i_args(idx_reason_notes) IS NULL OR
                           upper(s.reason_notes) LIKE '%' || upper(i_args(idx_reason_notes)) || '%')))
                          -- Filter by translation needs
                       AND (i_args(idx_translation_needs) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_translation_needs
                                AND id = s.id_lang_translator))
                          --Filter by duration
                       AND (i_args(idx_duration) IS NULL OR
                           (s.dt_end_tstz IS NOT NULL AND EXISTS
                            (SELECT /*+NL_SJ*/
                               1
                                FROM sch_tmptab_args
                               WHERE argtype = idx_duration
                                 AND id = trunc(pk_date_utils.get_timestamp_diff(s.dt_end_tstz, s.dt_begin_tstz),
                                                pk_schedule.g_max_decimal_prec))))
                          -- Filter by exam (including instructions)
                       AND (s.flg_sch_type NOT IN (g_sch_dept_flg_dep_type_exam, g_sch_dept_flg_dep_type_oexams) OR
                           (i_args(idx_id_exam) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                               1
                                FROM sch_tmptab_args targa
                                JOIN schedule_exam sexam
                                  ON targa.id = sexam.id_exam
                                JOIN exam ex
                                  ON sexam.id_exam = ex.id_exam
                               WHERE argtype = idx_id_exam
                                 AND sexam.id_schedule = s.id_schedule
                                 AND (i_args(idx_flg_prep) IS NULL OR 'N' = i_args(idx_flg_prep)))))
                          -- Filter by analysis
                          -- Filter by origin                           
                       AND (i_args(idx_id_origin) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_id_origin
                                AND id = s.id_origin))
                          -- Filter by room
                       AND (i_args(idx_id_room) IS NULL OR EXISTS
                            (SELECT /*+NL_SJ*/
                              1
                               FROM sch_tmptab_args
                              WHERE argtype = idx_id_room
                                AND id = s.id_room))
                          -- Filter by patient  
                       AND (i_id_patient IS NULL OR sg.id_patient = i_id_patient))
            -- Filter by time. This filter is applied on the outside query to prevent
            -- to_char_insttimezone to be called event for records that are not valid.
             WHERE (i_args(idx_time_begin) IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof, dt_begin, pk_schedule.g_default_time_mask) >=
                   i_args(idx_time_begin))
               AND (i_args(idx_time_end) IS NULL OR dt_end IS NULL OR
                   pk_date_utils.to_char_insttimezone(i_prof, dt_end, pk_schedule.g_default_time_mask) <=
                   i_args(idx_time_end));
    BEGIN
    
        -- Telmo 19-08-2008  clean up temp tables 
        g_error := 'TRUNCATE TEMPORARY TABLE';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_ARGS';
        EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_VARGS';
    
        -- fill it up 
        g_error := 'FILL TEMPORARY TABLE';
        INSERT INTO sch_tmptab_args
            SELECT idx_id_dep, column_value
              FROM TABLE(l_list_dep);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_id_dep_clin_serv, column_value
              FROM TABLE(l_list_dcs);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_event, column_value
              FROM TABLE(l_list_event);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_id_prof, column_value
              FROM TABLE(l_list_prof);
        INSERT INTO sch_tmptab_args
            SELECT DISTINCT idx_id_exam, column_value
              FROM TABLE(l_list_exams);
        INSERT INTO sch_tmptab_args
            SELECT idx_duration, column_value
              FROM TABLE(l_list_duration);
        INSERT INTO sch_tmptab_args
            SELECT idx_preferred_lang, column_value
              FROM TABLE(l_list_pref_langs);
        INSERT INTO sch_tmptab_vargs
            SELECT idx_type, column_value
              FROM TABLE(l_list_types);
        INSERT INTO sch_tmptab_vargs
            SELECT idx_status, column_value
              FROM TABLE(l_list_status);
        INSERT INTO sch_tmptab_args
            SELECT idx_id_reason, column_value
              FROM TABLE(l_list_reasons);
        INSERT INTO sch_tmptab_args
            SELECT idx_translation_needs, column_value
              FROM TABLE(l_list_trans_langs);
        INSERT INTO sch_tmptab_args
            SELECT idx_id_origin, column_value
              FROM TABLE(l_list_origin);
        INSERT INTO sch_tmptab_args
            SELECT idx_id_room, column_value
              FROM TABLE(l_list_room);
        -- end Telmo 19-08-2008
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CALL GET_STRING_TSTZ FOR l_start_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(idx_dt_begin),
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_end_ts';
        -- Get start timestamp
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_args(idx_dt_end),
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_ts,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'OPEN c_schedules';
        OPEN c_schedules(l_start_ts, l_end_ts);
        g_error := 'FETCH c_schedules';
        FETCH c_schedules BULK COLLECT
            INTO o_schedules;
        g_error := 'CLOSE c_schedules';
        CLOSE c_schedules;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedules := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_schedules;

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
    *
    * UPDATED alert-8202. adaptado para a possibilidade de agendamento multi-exame
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION get_schedules_for_vacancy
    (
        i_lang           IN language.id_language%TYPE DEFAULT NULL,
        i_prof           IN profissional,
        i_id_sch_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_args           IN table_varchar,
        o_schedules      OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_SCHEDULES_FOR_VACANCY';
        l_list_schedules table_number;
    
        CURSOR c_schedules(i_list_schedules table_number) IS
            SELECT /*+ first_rows */
             s.id_schedule
              FROM schedule s, sch_consult_vacancy scv, sch_resource sr
             WHERE scv.id_sch_consult_vacancy = i_id_sch_vacancy
               AND scv.dt_begin_tstz = s.dt_begin_tstz
               AND scv.id_institution = s.id_instit_requested
               AND scv.id_dep_clin_serv = s.id_dcs_requested
               AND scv.id_sch_event = s.id_sch_event
               AND s.id_schedule IN (SELECT *
                                       FROM TABLE(i_list_schedules))
               AND s.id_schedule = sr.id_schedule(+)
               AND ((scv.id_prof IS NULL AND sr.id_professional IS NULL) OR scv.id_prof = sr.id_professional);
    
    BEGIN
        g_error := 'CALL GET_SCHEDULES';
        -- Get schedules' identifiers that match the criteria
        IF NOT get_schedules(i_lang       => i_lang,
                             i_prof       => i_prof,
                             i_id_patient => NULL,
                             i_args       => i_args,
                             o_schedules  => l_list_schedules,
                             o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get schedules' identifiers that match the given vacancy.
        g_error := 'OPEN c_schedules';
        OPEN c_schedules(l_list_schedules);
        g_error := 'FETCH c_schedules';
        FETCH c_schedules BULK COLLECT
            INTO o_schedules;
        g_error := 'CLOSE c_schedules';
        CLOSE c_schedules;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedules := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_schedules_for_vacancy;

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
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_VAC_AND_SCH_MULT';
        l_inter_dates     table_timestamp_tz := table_timestamp_tz();
        l_union_schedules table_number := table_number();
        l_schedules       table_number := table_number();
        l_dates           table_timestamp_tz := table_timestamp_tz();
        l_list_event      table_number;
    
        -- Intersects two table_timestamp_tz lists
        FUNCTION inner_intersect_table_tz
        (
            i_table_1 table_timestamp_tz,
            i_table_2 table_timestamp_tz
        ) RETURN table_timestamp_tz IS
            l_table_str_1 table_varchar := table_varchar();
            l_table_str_2 table_varchar := table_varchar();
            l_ret         table_timestamp_tz := table_timestamp_tz();
        BEGIN
            g_error := 'INNER_INTERSECT_TABLE_TZ: CONVERT 1';
            -- Convert first table
            IF (i_table_1 IS NOT NULL AND i_table_1.count > 0)
            THEN
                FOR i IN i_table_1.first .. i_table_1.last
                LOOP
                    l_table_str_1.extend;
                    l_table_str_1(i) := pk_date_utils.date_send_tsz(i_lang, i_table_1(i), i_prof);
                END LOOP;
            END IF;
        
            g_error := 'INNER_INTERSECT_TABLE_TZ: CONVERT 2';
            -- Convert second table
            IF (i_table_2 IS NOT NULL AND i_table_2.count > 0)
            THEN
                FOR i IN i_table_2.first .. i_table_2.last
                LOOP
                    l_table_str_2.extend;
                    l_table_str_2(i) := pk_date_utils.date_send_tsz(i_lang, i_table_2(i), i_prof);
                END LOOP;
            END IF;
        
            g_error := 'MULTISET INTERSECT DISTINCT';
            -- Intersect tables
            l_table_str_1 := l_table_str_1 MULTISET INTERSECT DISTINCT l_table_str_2;
        
            g_error := 'INNER_INTERSECT_TABLE_TZ: CONVERT 1 BACK';
            -- Convert first table back
            IF (l_table_str_1 IS NOT NULL AND l_table_str_1.count > 0)
            THEN
                FOR i IN l_table_str_1.first .. l_table_str_1.last
                LOOP
                    l_ret.extend;
                    l_ret(i) := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => l_table_str_1(i),
                                                              i_timezone  => NULL);
                END LOOP;
            END IF;
        
            RETURN l_ret;
        END inner_intersect_table_tz;
    
    BEGIN
        g_error := 'ITERATE THROUGH CRITERIA';
        IF i_args IS NOT NULL
           AND i_args.count > 0
        THEN
        
            -- extract events from 1st i_args. Later we need to know if we have a multidisc situation in our hands
            l_list_event := pk_schedule.get_list_number_csv(i_args(1) (idx_event));
        
            FOR idx IN i_args.first .. i_args.last
            LOOP
                -- Stop looking for vacancies and schedules once the list of common dates is empty (after the first iteration).
                EXIT WHEN l_inter_dates.count = 0 AND idx > 1;
            
                g_error := 'CALL GET_VACANCIES';
                -- Get the list of vacancies that match the current criteria set
                IF NOT get_vacancies(i_lang => i_lang, i_prof => i_prof, i_args => i_args(idx), o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'CALL GET_SCHEDULES';
                -- Get the list of schedules that match the current criteria set
                IF pk_schedule.get_only_vacs(i_args(idx) (idx_status)) = g_yes
                THEN
                    l_schedules := table_number();
                ELSE
                    IF NOT get_schedules(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_patient => i_id_patient,
                                         i_args       => i_args(idx),
                                         o_schedules  => l_schedules,
                                         o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                g_error := 'UNITE SCHEDULES';
                -- Unite all schedules found so far.
                -- Each one is valid for at least one criteria set.
                l_union_schedules := l_union_schedules MULTISET UNION DISTINCT l_schedules;
            
                -- unite all vacancies found so far
                g_error := 'MERGE INTO sch_tmptab_full_vacs';
                MERGE INTO sch_tmptab_full_vacs g
                USING (SELECT stv.id_sch_consult_vacancy idscv,
                              stv.dt_begin_trunc         dbt,
                              stv.max_vacancies          mv,
                              stv.used_vacancies         uv,
                              scv.id_prof                idprof,
                              scv.id_sch_event           ideve,
                              scv.id_dep_clin_serv       iddcs,
                              scv.id_institution         idinst,
                              scv.dt_begin_tstz          dtbegin,
                              scv.dt_end_tstz            dtend,
                              scv.id_sch_consult_vacancy idco
                         FROM sch_tmptab_vacs stv
                         JOIN sch_consult_vacancy scv
                           ON stv.id_sch_consult_vacancy = scv.id_sch_consult_vacancy) stv2
                ON (g.id_sch_consult_vacancy = stv2.idscv)
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sch_consult_vacancy,
                         dt_begin_trunc,
                         max_vacancies,
                         used_vacancies,
                         id_prof,
                         id_sch_event,
                         dt_begin_tstz,
                         dt_end_tstz,
                         id_dep_clin_serv,
                         id_institution,
                         id_code)
                    VALUES
                        (stv2.idscv,
                         stv2.dbt,
                         stv2.mv,
                         stv2.uv,
                         stv2.idprof,
                         stv2.ideve,
                         stv2.dtbegin,
                         stv2.dtend,
                         stv2.iddcs,
                         stv2.idinst,
                         stv2.idco);
            
                -- Get the list of days for the current vacancies and/or schedules
                -- when dealing with multidisc appoints, do not clean the dt_begin_tstz time portion 
                -- so that we can intersect them right down to the minute.
                g_error := 'GET DAYS FOR VACANCIES AND SCHEDULES';
                IF nvl(pk_utils.search_table_number(l_list_event, pk_schedule.g_event_multidisc), -1) > -1
                THEN
                    SELECT pk_date_utils.trunc_insttimezone(i_prof, dt_begin_tstz, 'MI')
                      BULK COLLECT
                      INTO l_dates
                      FROM sch_tmptab_full_vacs stv
                     WHERE stv.id_prof = i_args(idx) (idx_id_prof)
                       AND stv.id_dep_clin_serv = i_args(idx) (idx_id_dep_clin_serv);
                ELSE
                    SELECT pk_date_utils.trunc_insttimezone(i_prof, dt_begin)
                      BULK COLLECT
                      INTO l_dates
                      FROM (SELECT stv.dt_begin_trunc dt_begin
                              FROM sch_tmptab_full_vacs stv
                            UNION
                            SELECT pk_date_utils.trunc_insttimezone(i_prof, s.dt_begin_tstz) dt_begin
                              FROM schedule s
                             WHERE s.id_schedule IN (SELECT *
                                                       FROM TABLE(l_schedules)));
                
                END IF;
            
                g_error := 'INTERSECT DAYS';
                IF idx = 1
                THEN
                    l_inter_dates := l_dates;
                ELSE
                    -- Intersect all the days found so far  
                    -- Multiset does not work with tables of timestamps with time zone.
                    l_inter_dates := inner_intersect_table_tz(l_inter_dates, l_dates);
                END IF;
            END LOOP;
        
            -- post processing - remove vacancies and schedules that fall out of allowed dates (l_inter_dates)
            g_error := 'CHECK DAYS COUNT';
            IF (l_inter_dates IS NOT NULL AND l_inter_dates.count > 0)
            THEN
                -- Get vacancies and schedules for the valid dates only
                g_error := 'EXCLUDE VACANCIES THAT ARE NOT WITHIN THE ALLOWED DATES';
                DELETE sch_tmptab_full_vacs
                 WHERE id_sch_consult_vacancy NOT IN
                       (SELECT id_sch_consult_vacancy
                          FROM sch_tmptab_full_vacs t,
                               (SELECT *
                                  FROM TABLE(l_inter_dates)) dates
                         WHERE t.dt_begin_tstz >= dates.column_value
                           AND t.dt_begin_tstz < pk_date_utils.add_days_to_tstz(dates.column_value, 1));
            
                g_error := 'EXCLUDE SCHEDULES THAT ARE NOT WITHIN THE ALLOWED DATES';
                SELECT /*+ first_rows */
                 s.id_schedule
                  BULK COLLECT
                  INTO o_schedules
                  FROM schedule s,
                       (SELECT *
                          FROM TABLE(l_inter_dates)) dates
                 WHERE s.id_schedule IN (SELECT *
                                           FROM TABLE(l_union_schedules))
                   AND s.dt_begin_tstz >= dates.column_value
                   AND s.dt_begin_tstz < pk_date_utils.add_days_to_tstz(dates.column_value, 1);
            
            ELSE
                -- No days were found with vacancies or schedules for all the criteria sets.
                o_schedules := table_number();
                g_error     := 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
                EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
            END IF;
        ELSE
            o_schedules := table_number();
            g_error     := 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE SCH_TMPTAB_FULL_VACS';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_schedules := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_vac_and_sch_mult;

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
    ) RETURN VARCHAR IS
        l_select    VARCHAR2(32000);
        l_func_name VARCHAR2(32) := 'STRING_TRANSLATION';
        l_string    pk_translation.t_desc_translation;
    BEGIN
        -- Build select statement
        l_select := 'SELECT pk_translation.get_translation(:1, ' || i_select || ') ';
        l_select := l_select || ' FROM ' || i_from;
        l_select := l_select || ' WHERE rownum = 1 AND ' || i_where;
        -- Execute the statement
        g_error := 'EXECUTE IMMEDIATE ' || l_select;
        EXECUTE IMMEDIATE l_select
            INTO l_string
            USING IN i_lang;
        RETURN l_string;
    EXCEPTION
        WHEN no_data_found THEN
            -- Missing translation or to restrictive WHERE clause.
            l_string := '';
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || i_select || ' FROM ' || i_from ||
                                                ' WHERE ' || i_where,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN l_string;
        WHEN OTHERS THEN
            -- Unexpected error
            l_string := '';
            error_handling(i_func_proc_name => l_func_name, i_error => g_error, i_sqlerror => SQLERRM);
            RETURN l_string;
    END string_translation;

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
    ) RETURN BOOLEAN IS
        l_select    VARCHAR2(32000);
        l_func_name VARCHAR2(32) := 'STRING_TRANSLATION';
    BEGIN
        -- Build select statement
        l_select := 'SELECT pk_translation.get_translation(:1, ' || i_select || ') ';
        l_select := l_select || ' FROM ' || i_from;
        l_select := l_select || ' WHERE rownum = 1 AND ' || i_where;
        -- Execute the statement
        g_error := 'EXECUTE IMMEDIATE ' || l_select;
        EXECUTE IMMEDIATE l_select
            INTO o_string
            USING IN i_lang;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- Missing translation or to restrictive WHERE clause.
            o_string := '';
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || i_select || ' FROM ' || i_from ||
                                                ' WHERE ' || i_where,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := '';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END string_translation;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32);
    BEGIN
        l_func_name := 'NEW_SCH_ABSENCE';
        -- If the primary key is passed as a parameter use it,
        -- else take the next value from sequence.
        g_error := 'GET SEQUENCE VALUE';
        IF (i_id_sch_absence IS NOT NULL)
        THEN
            o_sch_absence_rec.id_sch_absence := i_id_sch_absence;
        ELSE
            SELECT seq_sch_absence.nextval
              INTO o_sch_absence_rec.id_sch_absence
              FROM dual;
        END IF;
        -- Create record
        g_error                           := 'CREATE RECORD';
        o_sch_absence_rec.id_professional := i_id_professional;
        o_sch_absence_rec.id_institution  := i_id_institution;
        o_sch_absence_rec.dt_begin_tstz   := i_dt_begin_tstz;
        o_sch_absence_rec.dt_end_tstz     := i_dt_end_tstz;
        o_sch_absence_rec.desc_absence    := i_desc_absence;
        o_sch_absence_rec.flg_type        := i_flg_type;
        o_sch_absence_rec.flg_status      := i_flg_status;
        -- Insert record
        g_error := 'INSERT RECORD';
        INSERT INTO sch_absence
        VALUES o_sch_absence_rec;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_absence_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END new_sch_absence;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32);
    BEGIN
        l_func_name := 'ALTER_SCH_ABSENCE';
        -- Update record
        g_error := 'UPDATE RECORD';
        UPDATE sch_absence
           SET id_sch_absence  = nvl(i_id_sch_absence, id_sch_absence),
               id_professional = nvl(i_id_professional, id_professional),
               id_institution  = nvl(i_id_institution, id_institution),
               dt_begin_tstz   = nvl(i_dt_begin_tstz, dt_begin_tstz),
               dt_end_tstz     = nvl(i_dt_end_tstz, dt_end_tstz),
               desc_absence    = nvl(i_desc_absence, desc_absence),
               flg_type        = nvl(i_flg_type, flg_type),
               flg_status      = nvl(i_flg_status, flg_status)
         WHERE id_sch_absence = i_id_sch_absence
        RETURNING id_sch_absence, id_professional, id_institution, dt_begin_tstz, dt_end_tstz, desc_absence, flg_type, flg_status INTO o_sch_absence_rec.id_sch_absence, o_sch_absence_rec.id_professional, o_sch_absence_rec.id_institution, o_sch_absence_rec.dt_begin_tstz, o_sch_absence_rec.dt_end_tstz, o_sch_absence_rec.desc_absence, o_sch_absence_rec.flg_type, o_sch_absence_rec.flg_status;
        IF SQL%ROWCOUNT = 0
        THEN
            -- No records were updated due to an invalid key
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => g_invalid_record_key,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            o_sch_absence_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END alter_sch_absence;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32);
        l_rowids    table_varchar;
    BEGIN
        l_func_name := 'ALTER_CONSULT_REQ';
        -- Update record
        g_error := 'UPDATE RECORD';
        ts_consult_req.upd(id_consult_req_in      => i_id_consult_req,
                           dt_consult_req_tstz_in => i_dt_consult_req_tstz,
                           dt_scheduled_tstz_in   => i_dt_scheduled_tstz,
                           dt_cancel_tstz_in      => i_dt_cancel_tstz,
                           next_visit_in_notes_in => i_next_visit_in_notes,
                           flg_instructions_in    => i_flg_instructions,
                           id_complaint_in        => i_id_complaint, /* nvl(i_id_consult_req, id_consult_req), */
                           consult_type_in        => i_consult_type,
                           id_clinical_service_in => i_id_clinical_service,
                           id_patient_in          => i_id_patient,
                           id_instit_requests_in  => i_id_instit_requests,
                           id_inst_requested_in   => i_id_inst_requested,
                           id_episode_in          => i_id_episode,
                           id_prof_req_in         => i_id_prof_req,
                           id_prof_auth_in        => i_id_prof_auth,
                           id_prof_appr_in        => i_id_prof_appr,
                           id_prof_proc_in        => i_id_prof_proc,
                           notes_in               => i_notes,
                           id_prof_cancel_in      => i_id_prof_cancel,
                           notes_cancel_in        => i_notes_cancel,
                           id_dep_clin_serv_in    => i_id_dep_clin_serv,
                           id_prof_requested_in   => i_id_prof_requested,
                           flg_status_in          => i_flg_status,
                           notes_admin_in         => i_notes_admin,
                           flg_type_date_in       => i_flg_type_date,
                           rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => profissional(i_id_prof_req, i_id_instit_requests, 0),
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        SELECT id_schedule,
               dt_consult_req_tstz,
               dt_scheduled_tstz,
               dt_cancel_tstz,
               next_visit_in_notes,
               flg_instructions,
               id_complaint,
               id_consult_req,
               consult_type,
               id_clinical_service,
               id_patient,
               id_instit_requests,
               id_inst_requested,
               id_episode,
               id_prof_req,
               id_prof_auth,
               id_prof_appr,
               id_prof_proc,
               notes,
               id_prof_cancel,
               notes_cancel,
               id_dep_clin_serv,
               id_prof_requested,
               flg_status,
               notes_admin,
               flg_type_date
          INTO o_consult_req_rec.id_schedule,
               o_consult_req_rec.dt_consult_req_tstz,
               o_consult_req_rec.dt_scheduled_tstz,
               o_consult_req_rec.dt_cancel_tstz,
               o_consult_req_rec.next_visit_in_notes,
               o_consult_req_rec.flg_instructions,
               o_consult_req_rec.id_complaint,
               o_consult_req_rec.id_consult_req,
               o_consult_req_rec.consult_type,
               o_consult_req_rec.id_clinical_service,
               o_consult_req_rec.id_patient,
               o_consult_req_rec.id_instit_requests,
               o_consult_req_rec.id_inst_requested,
               o_consult_req_rec.id_episode,
               o_consult_req_rec.id_prof_req,
               o_consult_req_rec.id_prof_auth,
               o_consult_req_rec.id_prof_appr,
               o_consult_req_rec.id_prof_proc,
               o_consult_req_rec.notes,
               o_consult_req_rec.id_prof_cancel,
               o_consult_req_rec.notes_cancel,
               o_consult_req_rec.id_dep_clin_serv,
               o_consult_req_rec.id_prof_requested,
               o_consult_req_rec.flg_status,
               o_consult_req_rec.notes_admin,
               o_consult_req_rec.flg_type_date
          FROM consult_req
         WHERE ROWID IN (SELECT column_value
                           FROM TABLE(l_rowids));
    
        IF (SQL%NOTFOUND)
        THEN
            -- No records were updated due to an invalid key
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => g_invalid_record_key,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_consult_req_rec := NULL;
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END alter_consult_req;

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
    FUNCTION get_vacancy_data -- descontinuada
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VACANCY_DATA';
    BEGIN
    
        g_error := 'get vac data';
        BEGIN
            IF (i_id_sch_event = pk_schedule.g_event_group OR i_id_sch_consult_vac IS NOT NULL)
            THEN
                SELECT *
                  INTO o_vacancy
                  FROM sch_consult_vacancy
                 WHERE id_sch_consult_vacancy = i_id_sch_consult_vac;
            ELSE
                -- passou a servir tambem para casos de exames e outros exames
                SELECT *
                  INTO o_vacancy
                  FROM sch_consult_vacancy
                 WHERE id_sch_consult_vacancy =
                       (SELECT MIN(s.id_sch_consult_vacancy)
                          FROM sch_consult_vacancy s
                         WHERE s.id_institution = i_id_institution
                           AND ((i_id_professional IS NOT NULL AND s.id_prof = i_id_professional) OR s.id_prof IS NULL)
                           AND s.id_sch_event = i_id_sch_event
                           AND s.id_dep_clin_serv = i_id_dep_clin_serv
                           AND s.dt_begin_tstz = i_dt_begin_tstz
                           AND s.flg_status = pk_schedule_bo.g_status_active);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
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
            RETURN FALSE;
        
    END get_vacancy_data;

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
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'ALTER_VACANCY';
        l_usedvac       EXCEPTION;
        l_usedvacancies sch_consult_vacancy.used_vacancies%TYPE;
    BEGIN
        -- get vac data
        g_error := 'GET VACANCY DATA';
        SELECT used_vacancies
          INTO l_usedvacancies
          FROM sch_consult_vacancy
         WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        -- check 
        g_error := 'CHECK IF IT IS USED';
        IF l_usedvacancies > 0
        THEN
            RAISE l_usedvac;
        END IF;
    
        -- update
        g_error := 'UPDATE VACANCY';
        UPDATE sch_consult_vacancy
           SET id_prof          = i_id_prof,
               id_dep_clin_serv = i_id_dep_clin_serv,
               id_room          = i_id_room,
               dt_begin_tstz    = i_dt_begin_tstz,
               dt_end_tstz      = i_dt_end_tstz
         WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_usedvac THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Vacancy cannot be changed because it is already in use',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
        
    END alter_vacancy;

    /*
    * @author  Nuno Miguel Ferreira
        * @version 2.5.0.4
        * @date    08-07-2009
        */
    FUNCTION alter_sch_resource
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_sch_resource        IN sch_resource.id_sch_resource%TYPE,
        i_id_sch_consult_vacancy IN sch_resource.id_sch_consult_vacancy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'ALTER_SCH_RESOURCE';
    BEGIN
        g_error := 'UPDATE SCH_RESOURCE';
        UPDATE sch_resource
           SET id_sch_consult_vacancy = i_id_sch_consult_vacancy
         WHERE id_sch_resource = i_id_sch_resource;
    
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
            RETURN FALSE;
        
    END alter_sch_resource;

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
    ) RETURN BOOLEAN IS
        l_table_str_1 table_varchar := table_varchar();
        l_table_str_2 table_varchar := table_varchar();
        l_func_name   VARCHAR2(32) := 'GET_INTERSECT_TABLE_TZ';
    
    BEGIN
        g_error := 'GET_INTERSECT_TABLE_TZ: CONVERT 1';
        -- Convert first table
        IF (i_table_1 IS NOT NULL AND i_table_1.count > 0)
        THEN
            FOR i IN i_table_1.first .. i_table_1.last
            LOOP
                l_table_str_1.extend;
                l_table_str_1(i) := pk_date_utils.date_send_tsz(i_lang, i_table_1(i), i_prof);
            END LOOP;
        END IF;
    
        g_error := 'GET_INTERSECT_TABLE_TZ: CONVERT 2';
        -- Convert second table
        IF (i_table_2 IS NOT NULL AND i_table_2.count > 0)
        THEN
            FOR i IN i_table_2.first .. i_table_2.last
            LOOP
                l_table_str_2.extend;
                l_table_str_2(i) := pk_date_utils.date_send_tsz(i_lang, i_table_2(i), i_prof);
            END LOOP;
        END IF;
    
        g_error := 'MULTISET INTERSECT DISTINCT';
        -- Intersect tables
        l_table_str_1 := l_table_str_1 MULTISET INTERSECT DISTINCT l_table_str_2;
    
        o_table := table_timestamp_tz();
        g_error := 'GET_INTERSECT_TABLE_TZ: CONVERT 1 BACK';
        -- Convert first table back
        IF (l_table_str_1 IS NOT NULL AND l_table_str_1.count > 0)
        THEN
            FOR i IN l_table_str_1.first .. l_table_str_1.last
            LOOP
                o_table.extend;
                o_table(i) := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timestamp => l_table_str_1(i),
                                                            i_timezone  => NULL);
            END LOOP;
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
            RETURN FALSE;
        
    END get_intersect_table_tz;

    FUNCTION get_dep_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN sch_event.id_sch_event%TYPE,
        o_dep_type     OUT sch_dep_type.dep_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEP_TYPE';
    BEGIN
        g_error := 'OPEN CURSOR';
        SELECT dep_type
          INTO o_dep_type
          FROM sch_event se
         WHERE se.id_sch_event = i_id_sch_event
           AND get_sch_event_avail(i_id_sch_event, i_prof.institution, i_prof.software) = pk_alert_constant.g_yes;
    
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
            RETURN FALSE;
    END get_dep_type;

    /**********************************************************************************************
    * Function to return professional team names for a schedule list
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_LIST';
    BEGIN
        g_error := 'OPEN o_prof_list CURSOR';
        OPEN o_prof_list FOR
            SELECT sch.id_schedule,
                   scr.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, scr.id_professional) nick_prof,
                   pk_prof_utils.get_prof_speciality(i_lang, i_prof) prof_speciality,
                   CASE
                        WHEN nvl(scr.flg_leader, g_no) = g_no THEN
                         0
                        ELSE
                         1
                    END flg_leader,
                   scr.id_sch_consult_vacancy
              FROM schedule sch
             INNER JOIN sch_resource scr
                ON sch.id_schedule = scr.id_schedule
             WHERE sch.id_schedule IN (SELECT column_value
                                         FROM TABLE(i_schedules))
             ORDER BY flg_leader DESC, sch.id_schedule;
    
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
            RETURN FALSE;
    END get_prof_list;

    /*
    * returns dep_type_group for a given dep_type
    * INLINE function.
    * 
    * @param i_dep_type     scheduling type
    *
    * @return               sch_dep_type.dep_type_group
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @date     21-05-2010
    */
    FUNCTION get_dep_type_group(i_dep_type IN sch_dep_type.dep_type%TYPE) RETURN sch_dep_type.dep_type_group%TYPE IS
        l_retval sch_dep_type.dep_type_group%TYPE;
    BEGIN
        SELECT dep_type_group
          INTO l_retval
          FROM sch_dep_type
         WHERE dep_type = i_dep_type;
    
        RETURN l_retval;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_dep_type_group;

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
    ) RETURN VARCHAR2 IS
        v_res VARCHAR2(1);
    BEGIN
        SELECT pk_alert_constant.g_yes
          INTO v_res
          FROM sch_event_inst_soft seis
          JOIN sch_event se
            ON seis.id_sch_event = se.id_sch_event
         WHERE seis.id_sch_event = i_id_sch_event
           AND seis.id_institution IN (nvl(i_id_inst, 0), 0)
           AND seis.id_software IN (nvl(i_id_soft, 0), 0)
           AND seis.flg_available = pk_alert_constant.g_yes
           AND se.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
        RETURN v_res;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
    END get_sch_event_avail;

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
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := $$PLSQL_UNIT;
        l_id_sch_event    sch_event.id_sch_event%TYPE;
        l_sch_not_found   EXCEPTION;
        l_etype_not_found EXCEPTION;
    BEGIN
        BEGIN
            g_error := l_func_name || ' - get dep_type and id_sch_event';
            SELECT s.id_sch_event, nvl(s.flg_sch_type, se.dep_type)
              INTO l_id_sch_event, o_dep_type
              FROM schedule s
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_schedule = i_id_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_sch_not_found;
        END;
    
        g_error := l_func_name || ' - get id_epis_type, attempt 1. id_schedule=' || i_id_schedule;
        BEGIN
            SELECT e.id_epis_type
              INTO o_id_epis_type
              FROM epis_info ei
              JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE ei.id_schedule = i_id_schedule;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- carry on to the next attempt
        END;
    
        g_error := l_func_name || ' - get id_epis_type, attempt 2. id_schedule=' || i_id_schedule;
        BEGIN
            SELECT so.id_epis_type
              INTO o_id_epis_type
              FROM schedule_outp so
             WHERE so.id_schedule = i_id_schedule;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- carry on to the next attempt
        END;
    
        g_error := l_func_name || ' - get id_epis_type, attempt 3. id_sch_event=' || l_id_sch_event || ', id_software=' ||
                   i_prof.software;
        BEGIN
            SELECT ses.id_epis_type
              INTO o_id_epis_type
              FROM sch_event_soft ses
             WHERE ses.id_sch_event = l_id_sch_event
               AND ses.id_software = i_prof.software
               AND rownum = 1;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- carry on to the next attempt
        END;
    
        g_error := l_func_name || ' - get id_epis_type, attempt 4. id_institution=' || i_prof.institution ||
                   ', id_software=' || i_prof.software;
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => pk_schedule.g_sched_epis_type_config,
                                             i_id_institution => i_prof.institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => o_id_epis_type,
                                             o_error          => o_error)
        THEN
            RAISE l_etype_not_found;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_sch_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -20001,
                                              i_sqlerrm  => 'schedule id ' || i_id_schedule || ' not found',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN l_etype_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -20002,
                                              i_sqlerrm  => 'could not find id_epis_type for schedule id ' ||
                                                            i_id_schedule || ' after 3 attempts',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_sch_epis_type;

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
    FUNCTION get_dep_type(i_id_sch_event IN sch_event.id_sch_event%TYPE) RETURN sch_event.dep_type%TYPE IS
        l_ret sch_event.dep_type%TYPE;
    BEGIN
        SELECT dep_type
          INTO l_ret
          FROM sch_event se
         WHERE se.id_sch_event = i_id_sch_event;
    
        RETURN l_ret;
    END get_dep_type;

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
    FUNCTION get_event_data(i_id_sch_event IN sch_event.id_sch_event%TYPE) RETURN sch_event%ROWTYPE IS
        l_ret sch_event%ROWTYPE;
    BEGIN
        SELECT *
          INTO l_ret
          FROM sch_event
         WHERE id_sch_event = i_id_sch_event;
    
        RETURN l_ret;
    END get_event_data;

    /* 
    *
    */
    FUNCTION get_translation_alias
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_id_sch_event     sch_event_alias.id_sch_event%TYPE,
        i_code_translation translation.code_translation%TYPE,
        i_try_both_sources BOOLEAN DEFAULT TRUE
    ) RETURN VARCHAR2 IS
        l_func_name            VARCHAR2(32) := $$PLSQL_UNIT;
        l_code_sch_event_alias sch_event_alias.code_sch_event_alias%TYPE;
    
    BEGIN
        g_error := l_func_name || ' - get row from sch_event_alias. id_sch_event=' || i_id_sch_event ||
                   ', id_institution=' || i_prof.institution;
    
        SELECT code_sch_event_alias
          INTO l_code_sch_event_alias
          FROM (SELECT code_sch_event_alias,
                       row_number() over(PARTITION BY sea.id_sch_event ORDER BY sea.id_institution DESC) rn
                  FROM sch_event_alias sea
                 WHERE sea.id_sch_event = i_id_sch_event
                   AND decode(sea.id_institution, 0, nvl(i_prof.institution, 0), sea.id_institution) =
                       nvl(i_prof.institution, 0))
         WHERE rn = 1;
    
        RETURN pk_translation.get_translation(i_lang, l_code_sch_event_alias);
    
    EXCEPTION
        WHEN no_data_found THEN
            IF i_try_both_sources
            THEN
                RETURN pk_translation.get_translation(i_lang, i_code_translation);
            END IF;
    END get_translation_alias;

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
    ) RETURN alert_core_tech.t_rec_translation IS
        l_func_name VARCHAR2(32) := $$PLSQL_UNIT;
        l_ret       alert_core_tech.t_rec_translation;
    BEGIN
        -- first try to find a suitable record in sch_event_alias
        g_error := l_func_name || ' - get row from sch_event_alias. id_sch_event=' || i_id_sch_event ||
                   ', id_institution=' || i_prof.institution;
        SELECT alert_core_tech.t_rec_translation(t.code_translation,
                                                 NULL, --table_owner. not needed
                                                 NULL, --full_code. not needed
                                                 NULL, --table_name. not needed
                                                 NULL, --module. not needed
                                                 t.desc_lang_1,
                                                 t.desc_lang_2,
                                                 t.desc_lang_3,
                                                 t.desc_lang_4,
                                                 t.desc_lang_5,
                                                 t.desc_lang_6,
                                                 t.desc_lang_7,
                                                 t.desc_lang_8,
                                                 t.desc_lang_9,
                                                 t.desc_lang_10,
                                                 t.desc_lang_11,
                                                 t.desc_lang_12,
                                                 t.desc_lang_13,
                                                 t.desc_lang_14,
                                                 t.desc_lang_15,
                                                 t.desc_lang_16,
                                                 t.desc_lang_17,
                                                 t.desc_lang_18,
                                                 t.desc_lang_19,
                                                 t.desc_lang_20,
                                                 t.desc_lang_21,
                                                 t.desc_lang_22,
                                                 NULL) -- desc_lang_23. not used
          INTO l_ret
          FROM translation t
         WHERE t.code_translation =
               (SELECT code_sch_event_alias
                  FROM (SELECT code_sch_event_alias,
                               row_number() over(PARTITION BY sea.id_sch_event ORDER BY sea.id_institution DESC) rn
                          FROM sch_event_alias sea
                         WHERE sea.id_sch_event = i_id_sch_event
                           AND decode(sea.id_institution, 0, nvl(i_prof.institution, 0), sea.id_institution) =
                               nvl(i_prof.institution, 0))
                 WHERE rn = 1);
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            IF i_try_both_sources
            THEN
                SELECT alert_core_tech.t_rec_translation(t.code_translation,
                                                         NULL, --table_owner. not needed
                                                         NULL, --full_code. not needed
                                                         NULL, --table_name. not needed
                                                         NULL, --module. not needed
                                                         t.desc_lang_1,
                                                         t.desc_lang_2,
                                                         t.desc_lang_3,
                                                         t.desc_lang_4,
                                                         t.desc_lang_5,
                                                         t.desc_lang_6,
                                                         t.desc_lang_7,
                                                         t.desc_lang_8,
                                                         t.desc_lang_9,
                                                         t.desc_lang_10,
                                                         t.desc_lang_11,
                                                         t.desc_lang_12,
                                                         t.desc_lang_13,
                                                         t.desc_lang_14,
                                                         t.desc_lang_15,
                                                         t.desc_lang_16,
                                                         t.desc_lang_17,
                                                         t.desc_lang_18,
                                                         t.desc_lang_19,
                                                         t.desc_lang_20,
                                                         t.desc_lang_21,
                                                         t.desc_lang_22,
                                                         NULL) -- desc_lang_20. not used
                  INTO l_ret
                  FROM translation t
                 WHERE t.code_translation = i_code_translation;
            
                RETURN l_ret;
            END IF;
    END get_translation_alias_rec;

    /*
    *
    */
    FUNCTION ins_sch_event_alias
    (
        i_lang           language.id_language%TYPE,
        i_id_sch_event   sch_event_alias.id_sch_event%TYPE,
        i_id_inst        sch_event_alias.id_institution%TYPE DEFAULT 0,
        i_alias          VARCHAR2,
        i_regen_appoints BOOLEAN DEFAULT FALSE
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := $$PLSQL_UNIT;
        l_id        sch_event_alias.id_sch_event_alias%TYPE := 'SEA_' || to_char(i_id_sch_event) || '_' ||
                                                               to_char(i_id_inst);
        l_code      sch_event_alias.code_sch_event_alias%TYPE := 'SCH_EVENT_ALIAS.CODE_SCH_EVENT_ALIAS.' || l_id;
        o_error     t_error_out;
    BEGIN
        BEGIN
            SELECT code_sch_event_alias
              INTO l_code
              FROM sch_event_alias sea
             WHERE sea.id_sch_event = i_id_sch_event
               AND sea.id_institution = i_id_inst;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := l_func_name || ' - Insert into sch_event_alias. i_id_sch_event=' || i_id_sch_event ||
                           ', i_id_inst=' || i_id_inst;
                BEGIN
                    INSERT INTO sch_event_alias
                        (id_sch_event_alias, id_sch_event, id_institution, code_sch_event_alias)
                    VALUES
                        (l_id, i_id_sch_event, i_id_inst, l_code);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        NULL; -- para os casos em que sequencia e max(PK) sao diferentes 
                END;
        END;
    
        IF i_lang IS NOT NULL
           AND i_alias IS NOT NULL
        THEN
            g_error := l_func_name || ' - call insert_into_translation';
            pk_translation.insert_into_translation(i_lang => i_lang, i_code_trans => l_code, i_desc_trans => i_alias);
        
            -- send event alias to scheduler
            g_error := l_func_name || ' - call pk_schedule_tools.generate_lb_translations. code=' || l_code;
            pk_schedule_tools.generate_lb_translations(i_lang, table_varchar(l_code));
        
            -- regen appointment alias
            IF i_regen_appoints
            THEN
                g_error := l_func_name || ' - call pk_schedule_tools.generate_appt_alias. i_id_sch_event_alias=' || l_id ||
                           ', i_lang=' || i_lang;
                pk_schedule_tools.generate_appt_alias(i_id_sch_event_alias => l_id, i_upd_lb_transl => TRUE);
            END IF;
        
            -- export alias to aps and scheduler
            pk_ia_event_backoffice.sch_event_alias_new(i_id_sch_event_alias => l_id, i_id_institution => i_id_inst);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(l_func_name || ': ' || SQLERRM);
            RETURN FALSE;
    END ins_sch_event_alias;

    /*
    *
    */
    FUNCTION ins_sch_event_alias
    (
        i_id_sch_event   sch_event_alias.id_sch_event%TYPE,
        i_id_inst        sch_event_alias.id_institution%TYPE,
        i_aliases        table_varchar,
        i_regen_appoints BOOLEAN DEFAULT TRUE
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := $$PLSQL_UNIT;
        i           PLS_INTEGER;
        l_ret       BOOLEAN;
    BEGIN
        i := i_aliases.first;
        WHILE i IS NOT NULL
        LOOP
            l_ret := ins_sch_event_alias(i_lang           => i,
                                         i_id_sch_event   => i_id_sch_event,
                                         i_id_inst        => i_id_inst,
                                         i_alias          => i_aliases(i),
                                         i_regen_appoints => i_regen_appoints);
            i     := i_aliases.next(i);
        END LOOP;
        RETURN TRUE;
    END ins_sch_event_alias;

    /*
    * remove an event alias. 
    * Also removes its dependencies in appointment_alias table and translations.
    */
    FUNCTION del_sch_event_alias(i_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_codes        table_varchar;
        l_id_inst      sch_event_alias.id_institution%TYPE;
        l_id_sch_event sch_event_alias.id_sch_event%TYPE;
    BEGIN
        g_error := l_func_name || ' - GATHER appointment_alias codes. i_id_sch_event_alias=' || i_id_sch_event_alias;
        SELECT aa.code_appointment_alias
          BULK COLLECT
          INTO l_codes
          FROM appointment_alias aa
         WHERE aa.id_sch_event_alias = i_id_sch_event_alias;
    
        g_error := l_func_name || ' - get institution. i_id_sch_event_alias=' || i_id_sch_event_alias;
        SELECT sea.id_institution, sea.id_sch_event
          INTO l_id_inst, l_id_sch_event
          FROM sch_event_alias sea
         WHERE sea.id_sch_event_alias = i_id_sch_event_alias;
    
        g_error := l_func_name || ' - DELETE appointment_alias. i_id_sch_event_alias=' || i_id_sch_event_alias;
        DELETE appointment_alias aa
         WHERE aa.id_sch_event_alias = i_id_sch_event_alias;
    
        g_error := l_func_name || ' - DELETE translations';
        pk_translation.delete_code_translation(i_code => l_codes);
    
        -- delete 
        g_error := l_func_name || ' - DELETE sch_event_alias for i_id_sch_event_alias=' || i_id_sch_event_alias;
        DELETE sch_event_alias sea
         WHERE sea.id_sch_event_alias = i_id_sch_event_alias;
    
        -- notify deletion to scheduler
        g_error := l_func_name || ' - CALL pk_ia_event_backoffice.sch_event_alias_delete. i_id_sch_event=' ||
                   i_id_sch_event_alias || ', i_id_institution=' || l_id_inst;
        pk_ia_event_backoffice.sch_event_alias_delete(i_id_sch_event => l_id_sch_event, i_id_institution => l_id_inst);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END del_sch_event_alias;

    /*
    * another version, if id_sch_event_alias is unknown
    */
    FUNCTION del_sch_event_alias
    (
        i_id_sch_event sch_event_alias.id_sch_event%TYPE,
        i_id_inst      sch_event_alias.id_institution%TYPE
    ) RETURN BOOLEAN IS
        l_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE;
    BEGIN
        SELECT id_sch_event_alias
          INTO l_id_sch_event_alias
          FROM sch_event_alias sea
         WHERE sea.id_sch_event = i_id_sch_event
           AND sea.id_institution = i_id_inst;
    
        RETURN del_sch_event_alias(l_id_sch_event_alias);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            RETURN FALSE;
    END del_sch_event_alias;

    /*
    *
    */
    FUNCTION backup_schedule
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) RETURN schedule_hist%ROWTYPE IS
        l_schedule_row      schedule%ROWTYPE;
        l_schedule_row_hist schedule_hist%ROWTYPE;
    BEGIN
        g_error := 'BACKUP_SCHEDULE. id_schedule=' || i_id_sch;
    
        -- neste backup tenho de declarar todos os campos porque o dt_update deixou de ser o ultimo
        SELECT s.*
          INTO l_schedule_row
          FROM schedule s
         WHERE s.id_schedule = i_id_sch;
    
        l_schedule_row_hist.id_schedule            := l_schedule_row.id_schedule;
        l_schedule_row_hist.id_instit_requests     := l_schedule_row.id_instit_requests;
        l_schedule_row_hist.id_instit_requested    := l_schedule_row.id_instit_requested;
        l_schedule_row_hist.id_dcs_requests        := l_schedule_row.id_dcs_requests;
        l_schedule_row_hist.id_dcs_requested       := l_schedule_row.id_dcs_requested;
        l_schedule_row_hist.id_prof_requests       := l_schedule_row.id_prof_requests;
        l_schedule_row_hist.id_prof_schedules      := l_schedule_row.id_prof_schedules;
        l_schedule_row_hist.flg_urgency            := l_schedule_row.flg_urgency;
        l_schedule_row_hist.flg_status             := l_schedule_row.flg_status;
        l_schedule_row_hist.id_prof_cancel         := l_schedule_row.id_prof_cancel;
        l_schedule_row_hist.schedule_notes         := l_schedule_row.schedule_notes;
        l_schedule_row_hist.id_cancel_reason       := l_schedule_row.id_cancel_reason;
        l_schedule_row_hist.id_lang_translator     := l_schedule_row.id_lang_translator;
        l_schedule_row_hist.id_lang_preferred      := l_schedule_row.id_lang_preferred;
        l_schedule_row_hist.id_sch_event           := l_schedule_row.id_sch_event;
        l_schedule_row_hist.id_reason              := l_schedule_row.id_reason;
        l_schedule_row_hist.id_origin              := l_schedule_row.id_origin;
        l_schedule_row_hist.id_room                := l_schedule_row.id_room;
        l_schedule_row_hist.schedule_cancel_notes  := l_schedule_row.schedule_cancel_notes;
        l_schedule_row_hist.flg_notification       := l_schedule_row.flg_notification;
        l_schedule_row_hist.id_schedule_ref        := l_schedule_row.id_schedule_ref;
        l_schedule_row_hist.flg_vacancy            := l_schedule_row.flg_vacancy;
        l_schedule_row_hist.flg_sch_type           := l_schedule_row.flg_sch_type;
        l_schedule_row_hist.reason_notes           := l_schedule_row.reason_notes;
        l_schedule_row_hist.dt_begin               := l_schedule_row.dt_begin_tstz;
        l_schedule_row_hist.dt_cancel              := l_schedule_row.dt_cancel_tstz;
        l_schedule_row_hist.dt_end                 := l_schedule_row.dt_end_tstz;
        l_schedule_row_hist.dt_request             := l_schedule_row.dt_request_tstz;
        l_schedule_row_hist.dt_schedule            := l_schedule_row.dt_schedule_tstz;
        l_schedule_row_hist.flg_schedule_via       := l_schedule_row.flg_schedule_via;
        l_schedule_row_hist.flg_instructions       := l_schedule_row.flg_instructions;
        l_schedule_row_hist.id_sch_consult_vacancy := l_schedule_row.id_sch_consult_vacancy;
        l_schedule_row_hist.flg_notification_via   := l_schedule_row.flg_notification_via;
        l_schedule_row_hist.id_prof_notification   := l_schedule_row.id_prof_notification;
        l_schedule_row_hist.dt_notification        := l_schedule_row.dt_notification_tstz;
        l_schedule_row_hist.flg_request_type       := l_schedule_row.flg_request_type;
        l_schedule_row_hist.id_episode             := l_schedule_row.id_episode;
        l_schedule_row_hist.id_schedule_recursion  := l_schedule_row.id_schedule_recursion;
        l_schedule_row_hist.create_user            := l_schedule_row.create_user;
        l_schedule_row_hist.create_time            := l_schedule_row.create_time;
        l_schedule_row_hist.create_institution     := l_schedule_row.create_institution;
        l_schedule_row_hist.update_user            := l_schedule_row.update_user;
        l_schedule_row_hist.update_time            := l_schedule_row.update_time;
        l_schedule_row_hist.update_institution     := l_schedule_row.update_institution;
        l_schedule_row_hist.id_sch_combi_detail    := l_schedule_row.id_sch_combi_detail;
        l_schedule_row_hist.flg_present            := l_schedule_row.flg_present;
        l_schedule_row_hist.id_multidisc           := l_schedule_row.id_multidisc;
        l_schedule_row_hist.id_resched_reason      := l_schedule_row.id_resched_reason;
        l_schedule_row_hist.id_prof_resched        := l_schedule_row.id_prof_resched;
        l_schedule_row_hist.dt_resched_date        := l_schedule_row.dt_resched_date;
        l_schedule_row_hist.resched_notes          := l_schedule_row.resched_notes;
        l_schedule_row_hist.id_group               := l_schedule_row.id_group;
        l_schedule_row_hist.dt_update              := i_dt_update;
        l_schedule_row_hist.flg_reason_type        := l_schedule_row.flg_reason_type;
        l_schedule_row_hist.id_prof_update         := i_id_prof_u;
        l_schedule_row_hist.id_schedule_hist       := seq_schedule_hist.nextval;
        l_schedule_row_hist.dt_schedule_hist       := current_timestamp;
    
        ts_schedule_hist.ins(rec_in => l_schedule_row_hist, sequence_in => NULL, handle_error_in => FALSE);
    
        RETURN l_schedule_row_hist;
    END backup_schedule;

    /*
    *
    */
    PROCEDURE backup_schedule
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_row      schedule%ROWTYPE;
        l_schedule_row_hist schedule_hist%ROWTYPE;
    BEGIN
        g_error := 'BACKUP_SCHEDULE. id_schedule=' || i_id_sch;
    
        -- neste backup tenho de declarar todos os campos porque o dt_update deixou de ser o ultimo
        SELECT s.*
          INTO l_schedule_row
          FROM schedule s
         WHERE s.id_schedule = i_id_sch;
    
        l_schedule_row_hist.id_schedule            := l_schedule_row.id_schedule;
        l_schedule_row_hist.id_instit_requests     := l_schedule_row.id_instit_requests;
        l_schedule_row_hist.id_instit_requested    := l_schedule_row.id_instit_requested;
        l_schedule_row_hist.id_dcs_requests        := l_schedule_row.id_dcs_requests;
        l_schedule_row_hist.id_dcs_requested       := l_schedule_row.id_dcs_requested;
        l_schedule_row_hist.id_prof_requests       := l_schedule_row.id_prof_requests;
        l_schedule_row_hist.id_prof_schedules      := l_schedule_row.id_prof_schedules;
        l_schedule_row_hist.flg_urgency            := l_schedule_row.flg_urgency;
        l_schedule_row_hist.flg_status             := l_schedule_row.flg_status;
        l_schedule_row_hist.id_prof_cancel         := l_schedule_row.id_prof_cancel;
        l_schedule_row_hist.schedule_notes         := l_schedule_row.schedule_notes;
        l_schedule_row_hist.id_cancel_reason       := l_schedule_row.id_cancel_reason;
        l_schedule_row_hist.id_lang_translator     := l_schedule_row.id_lang_translator;
        l_schedule_row_hist.id_lang_preferred      := l_schedule_row.id_lang_preferred;
        l_schedule_row_hist.id_sch_event           := l_schedule_row.id_sch_event;
        l_schedule_row_hist.id_reason              := l_schedule_row.id_reason;
        l_schedule_row_hist.id_origin              := l_schedule_row.id_origin;
        l_schedule_row_hist.id_room                := l_schedule_row.id_room;
        l_schedule_row_hist.schedule_cancel_notes  := l_schedule_row.schedule_cancel_notes;
        l_schedule_row_hist.flg_notification       := l_schedule_row.flg_notification;
        l_schedule_row_hist.id_schedule_ref        := l_schedule_row.id_schedule_ref;
        l_schedule_row_hist.flg_vacancy            := l_schedule_row.flg_vacancy;
        l_schedule_row_hist.flg_sch_type           := l_schedule_row.flg_sch_type;
        l_schedule_row_hist.reason_notes           := l_schedule_row.reason_notes;
        l_schedule_row_hist.dt_begin               := l_schedule_row.dt_begin_tstz;
        l_schedule_row_hist.dt_cancel              := l_schedule_row.dt_cancel_tstz;
        l_schedule_row_hist.dt_end                 := l_schedule_row.dt_end_tstz;
        l_schedule_row_hist.dt_request             := l_schedule_row.dt_request_tstz;
        l_schedule_row_hist.dt_schedule            := l_schedule_row.dt_schedule_tstz;
        l_schedule_row_hist.flg_schedule_via       := l_schedule_row.flg_schedule_via;
        l_schedule_row_hist.flg_instructions       := l_schedule_row.flg_instructions;
        l_schedule_row_hist.id_sch_consult_vacancy := l_schedule_row.id_sch_consult_vacancy;
        l_schedule_row_hist.flg_notification_via   := l_schedule_row.flg_notification_via;
        l_schedule_row_hist.id_prof_notification   := l_schedule_row.id_prof_notification;
        l_schedule_row_hist.dt_notification        := l_schedule_row.dt_notification_tstz;
        l_schedule_row_hist.flg_request_type       := l_schedule_row.flg_request_type;
        l_schedule_row_hist.id_episode             := l_schedule_row.id_episode;
        l_schedule_row_hist.id_schedule_recursion  := l_schedule_row.id_schedule_recursion;
        l_schedule_row_hist.create_user            := l_schedule_row.create_user;
        l_schedule_row_hist.create_time            := l_schedule_row.create_time;
        l_schedule_row_hist.create_institution     := l_schedule_row.create_institution;
        l_schedule_row_hist.update_user            := l_schedule_row.update_user;
        l_schedule_row_hist.update_time            := l_schedule_row.update_time;
        l_schedule_row_hist.update_institution     := l_schedule_row.update_institution;
        l_schedule_row_hist.id_sch_combi_detail    := l_schedule_row.id_sch_combi_detail;
        l_schedule_row_hist.flg_present            := l_schedule_row.flg_present;
        l_schedule_row_hist.id_multidisc           := l_schedule_row.id_multidisc;
        l_schedule_row_hist.id_resched_reason      := l_schedule_row.id_resched_reason;
        l_schedule_row_hist.id_prof_resched        := l_schedule_row.id_prof_resched;
        l_schedule_row_hist.dt_resched_date        := l_schedule_row.dt_resched_date;
        l_schedule_row_hist.resched_notes          := l_schedule_row.resched_notes;
        l_schedule_row_hist.id_group               := l_schedule_row.id_group;
        l_schedule_row_hist.dt_update              := i_dt_update;
        l_schedule_row_hist.flg_reason_type        := l_schedule_row.flg_reason_type;
        l_schedule_row_hist.id_prof_update         := i_id_prof_u;
        l_schedule_row_hist.id_schedule_hist       := seq_schedule_hist.nextval;
        l_schedule_row_hist.dt_schedule_hist       := current_timestamp;
    
        ts_schedule_hist.ins(rec_in => l_schedule_row_hist, sequence_in => NULL, handle_error_in => FALSE);
    
    END backup_schedule;

    /*
    * 
    */
    PROCEDURE backup_sch_group
    (
        i_id_sch    sch_group.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_sch_group_rows ts_sch_group.sch_group_tc;
        l_sch_group_hist sch_group_hist%ROWTYPE;
    BEGIN
        g_error := 'BACKUP_SCH_GROUP. id_schedule=' || i_id_sch;
    
        SELECT s.*
          BULK COLLECT
          INTO l_sch_group_rows
          FROM sch_group s
         WHERE s.id_schedule = i_id_sch;
    
        FOR indx IN 1 .. l_sch_group_rows.count
        LOOP
            l_sch_group_hist.id_group           := l_sch_group_rows(indx).id_group;
            l_sch_group_hist.id_schedule        := l_sch_group_rows(indx).id_schedule;
            l_sch_group_hist.id_patient         := l_sch_group_rows(indx).id_patient;
            l_sch_group_hist.create_user        := l_sch_group_rows(indx).create_user;
            l_sch_group_hist.create_time        := l_sch_group_rows(indx).create_time;
            l_sch_group_hist.create_institution := l_sch_group_rows(indx).create_institution;
            l_sch_group_hist.update_user        := l_sch_group_rows(indx).update_user;
            l_sch_group_hist.update_time        := l_sch_group_rows(indx).update_time;
            l_sch_group_hist.update_institution := l_sch_group_rows(indx).update_institution;
            l_sch_group_hist.flg_ref_type       := l_sch_group_rows(indx).flg_ref_type;
            l_sch_group_hist.id_prof_ref        := l_sch_group_rows(indx).id_prof_ref;
            l_sch_group_hist.id_inst_ref        := l_sch_group_rows(indx).id_inst_ref;
            l_sch_group_hist.id_cancel_reason   := l_sch_group_rows(indx).id_cancel_reason;
            l_sch_group_hist.no_show_notes      := l_sch_group_rows(indx).no_show_notes;
            l_sch_group_hist.flg_contact_type   := l_sch_group_rows(indx).flg_contact_type;
            l_sch_group_hist.id_health_plan     := l_sch_group_rows(indx).id_health_plan;
            l_sch_group_hist.auth_code          := l_sch_group_rows(indx).auth_code;
            l_sch_group_hist.dt_auth_code_exp   := l_sch_group_rows(indx).dt_auth_code_exp;
            l_sch_group_hist.dt_update          := i_dt_update;
            l_sch_group_hist.pat_instructions   := l_sch_group_rows(indx).pat_instructions;
            l_sch_group_hist.id_pat_health_plan := l_sch_group_rows(indx).id_pat_health_plan;
            l_sch_group_hist.id_prof_update     := i_id_prof_u;
        
            ts_sch_group_hist.ins(rec_in => l_sch_group_hist, sequence_in => NULL, handle_error_in => FALSE);
        END LOOP;
    
    END backup_sch_group;

    /*
    * 
    */
    PROCEDURE backup_schedule_exam
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_exam_rows ts_schedule_exam_hist.schedule_exam_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCHEDULE_EXAM. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u -- quando a tabela _hist esta' igual a' principal, nao e' necessaria transformacao
          BULK COLLECT
          INTO l_schedule_exam_rows
          FROM schedule_exam s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_schedule_exam_rows.count > 0
        THEN
            -- optimizaçao
            ts_schedule_exam_hist.ins(rows_in => l_schedule_exam_rows, handle_error_in => FALSE);
        END IF;
    END backup_schedule_exam;

    /*
    * 
    */
    PROCEDURE backup_schedule_analysis
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_analysis_rows ts_schedule_analysis_hist.schedule_analysis_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCHEDULE_ANALYSIS. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u
          BULK COLLECT
          INTO l_schedule_analysis_rows
          FROM schedule_analysis s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_schedule_analysis_rows.count > 0
        THEN
            -- optimizaçao
            ts_schedule_analysis_hist.ins(rows_in => l_schedule_analysis_rows, handle_error_in => FALSE);
        END IF;
    END backup_schedule_analysis;

    /*
    *
    */
    PROCEDURE backup_schedule_bed
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_bed_rows ts_schedule_bed_hist.schedule_bed_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCHEDULE_BED. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u
          BULK COLLECT
          INTO l_schedule_bed_rows
          FROM schedule_bed s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_schedule_bed_rows.count > 0
        THEN
            -- optimizaçao
            ts_schedule_bed_hist.ins(rows_in => l_schedule_bed_rows, handle_error_in => FALSE);
        END IF;
    END backup_schedule_bed;

    /*
    * 
    */
    PROCEDURE backup_schedule_outp
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_outp_rows ts_schedule_outp_hist.schedule_outp_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCHEDULE_OUTP. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u
          BULK COLLECT
          INTO l_schedule_outp_rows
          FROM schedule_outp s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_schedule_outp_rows.count > 0
        THEN
            -- optimizaçao
            ts_schedule_outp_hist.ins(rows_in => l_schedule_outp_rows, handle_error_in => FALSE);
        END IF;
    END backup_schedule_outp;

    /*
    * 
    */
    PROCEDURE backup_sch_resource
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_sch_resource_rows ts_sch_resource_hist.sch_resource_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCH_RESOURCE. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u
          BULK COLLECT
          INTO l_sch_resource_rows
          FROM sch_resource s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_sch_resource_rows.count > 0
        THEN
            -- optimizaçao
            ts_sch_resource_hist.ins(rows_in => l_sch_resource_rows, handle_error_in => FALSE);
        END IF;
    END backup_sch_resource;

    /*
    * 
    */
    PROCEDURE backup_sch_rehab_group
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_sch_rehab_group_rows ts_sch_rehab_group_hist.sch_rehab_group_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCH_REHAB_GROUP. id_schedule=' || i_id_sch;
    
        SELECT s.id_schedule,
               s.id_rehab_group,
               s.create_user,
               s.create_time,
               s.create_institution,
               s.update_user,
               s.update_time,
               s.update_institution,
               i_dt_update,
               i_id_prof_u,
               s.id_rehab_sch_need
          BULK COLLECT
          INTO l_sch_rehab_group_rows
          FROM sch_rehab_group s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_sch_rehab_group_rows.count > 0
        THEN
            -- optimizaçao
            ts_sch_rehab_group_hist.ins(rows_in => l_sch_rehab_group_rows, handle_error_in => FALSE);
        END IF;
    END backup_sch_rehab_group;

    /*
    * 
    */
    PROCEDURE backup_schedule_sr
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_schedule_sr_rows ts_schedule_sr_hist.schedule_sr_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCHEDULE_SR. id_schedule=' || i_id_sch;
    
        SELECT s.id_schedule_sr,
               s.id_sched_sr_parent,
               s.id_schedule,
               s.id_episode,
               s.id_patient,
               s.duration,
               s.id_diagnosis,
               s.id_speciality,
               s.flg_status,
               s.flg_sched,
               s.id_dept_dest,
               s.prev_recovery_time,
               s.id_sr_cancel_reason,
               s.id_prof_cancel,
               s.notes_cancel,
               s.id_prof_reg,
               s.id_institution,
               s.adw_last_update,
               s.dt_target_tstz,
               s.dt_interv_preview_tstz,
               s.dt_cancel_tstz,
               s.create_user,
               s.create_time,
               s.create_institution,
               s.update_user,
               s.update_time,
               s.update_institution,
               s.icu,
               s.notes,
               s.id_waiting_list,
               s.adm_needed,
               s.flg_temporary,
               s.flg_dur_control,
               s.id_diag_inst_owner,
               i_dt_update,
               i_id_prof_u,
               s.need_global_anesth,
               s.need_local_anesth,
               s.icu_pos
          BULK COLLECT
          INTO l_schedule_sr_rows
          FROM schedule_sr s
         WHERE s.id_schedule = i_id_sch;
    
        IF l_schedule_sr_rows.count > 0
        THEN
            -- optimizaçao
            ts_schedule_sr_hist.ins(rows_in => l_schedule_sr_rows, handle_error_in => FALSE);
        END IF;
    END backup_schedule_sr;

    /*
    *
    */
    PROCEDURE backup_sch_prof_outp
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_sch_prof_outp_rows ts_sch_prof_outp_hist.sch_prof_outp_hist_tc;
    BEGIN
        g_error := 'BACKUP_SCH_PROF_OUTP. id_schedule=' || i_id_sch;
    
        SELECT s.*, i_dt_update, i_id_prof_u
          BULK COLLECT
          INTO l_sch_prof_outp_rows
          FROM sch_prof_outp s
          JOIN schedule_outp o
            ON s.id_schedule_outp = o.id_schedule_outp
         WHERE o.id_schedule = i_id_sch;
    
        IF l_sch_prof_outp_rows.count > 0
        THEN
            -- optimizaçao
            ts_sch_prof_outp_hist.ins(rows_in => l_sch_prof_outp_rows, handle_error_in => FALSE);
        END IF;
    END backup_sch_prof_outp;

    /* 
    *
    */
    PROCEDURE backup_all
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) IS
        l_dt_update TIMESTAMP WITH LOCAL TIME ZONE := i_dt_update;
        l_id_prof_u NUMBER := i_id_prof_u;
    BEGIN
        g_error := 'BACKUP_ALL. id_schedule=' || i_id_sch;
    
        IF l_dt_update IS NULL
           AND l_id_prof_u IS NULL
        THEN
            SELECT id_prof_schedules, dt_schedule_tstz
              INTO l_id_prof_u, l_dt_update
              FROM schedule s
             WHERE s.id_schedule = i_id_sch;
        END IF;
    
        backup_schedule(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_group(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_exam(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_analysis(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_bed(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_outp(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_resource(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_rehab_group(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_sr(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_prof_outp(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
    END backup_all;

    /* 
    *
    */
    FUNCTION backup_all
    (
        i_id_sch    schedule.id_schedule%TYPE,
        i_dt_update TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_u NUMBER
    ) RETURN schedule_hist%ROWTYPE IS
        l_ret       schedule_hist%ROWTYPE;
        l_dt_update TIMESTAMP WITH LOCAL TIME ZONE := i_dt_update;
        l_id_prof_u NUMBER := i_id_prof_u;
    BEGIN
        g_error := 'BACKUP_ALL. id_schedule=' || i_id_sch;
    
        IF l_dt_update IS NULL
           AND l_id_prof_u IS NULL
        THEN
            SELECT id_prof_schedules, dt_schedule_tstz
              INTO l_id_prof_u, l_dt_update
              FROM schedule s
             WHERE s.id_schedule = i_id_sch;
        END IF;
    
        l_ret := backup_schedule(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_group(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_exam(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_analysis(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_bed(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_outp(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_resource(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_rehab_group(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_schedule_sr(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
        backup_sch_prof_outp(i_id_sch => i_id_sch, i_dt_update => l_dt_update, i_id_prof_u => l_id_prof_u);
    
        RETURN l_ret;
    END backup_all;

    /*  
    * intentional no exception handling 
    */
    /*
        FUNCTION get_hist_curr_info 
        ( 
           i_id_sch    schedule.id_schedule%TYPE
        ) RETURN t_sch_hist_upd_info IS
          l_ret t_sch_hist_upd_info;
        BEGIN
          select nvl(s.update_time, s.dt_schedule_tstz), 
                 case pk_utils.is_number(s.update_user)
                   when 'Y' then to_number(s.update_user)
                   else s.id_prof_schedules
                 end
            into l_ret.update_date, l_ret.update_user
          from schedule s 
          where s.id_schedule = i_id_sch;
          
          return l_ret;
        END get_hist_curr_info;
    */

    /*
    * intentional no exception handling.
    * assume-se que e' sempre usado o pk_schedule_common.backup_all e por isso a schedule_hist recebe sempre 1 registo
    * mesmo quando o(s) campo(s) alterado(s) nao lhe pertencem.
    */
    FUNCTION get_hist_last_upd_info(i_id_sch schedule.id_schedule%TYPE) RETURN t_sch_hist_upd_info IS
    
        l_ret t_sch_hist_upd_info;
    BEGIN
    
        SELECT dt_update, id_prof_update
          INTO l_ret.update_date, l_ret.update_user
          FROM schedule_hist h
         WHERE h.id_schedule = i_id_sch
           AND h.dt_update = (SELECT MAX(dt_update)
                                FROM schedule_hist
                               WHERE id_schedule = i_id_sch);
        RETURN l_ret;
    END get_hist_last_upd_info;

    /*  
    * intentional no exception handling 
    */
    FUNCTION get_hist_col_last_upd_info
    (
        i_id_sch     schedule.id_schedule%TYPE,
        i_table_name VARCHAR2,
        i_col_name   VARCHAR2
    ) RETURN t_sch_hist_upd_info IS
    
        l_query VARCHAR2(2000) := q'[with fups as
                (
                  select *
                  from (
                        select nvl(cast(h.]' || i_col_name ||
                                  q'[ as varchar(4000)), 'null') valor,
                               lag(nvl(cast(h.]' || i_col_name ||
                                  q'[ as varchar(4000)), 'null'), 1, 'null') over(order by dt_update) valor_ant,
                               h.dt_update,
                               h.id_prof_update
                        from ]' || i_table_name || q'[ h
                        where h.id_schedule = :id_sch
                       )
                  where valor <> valor_ant
                  order by dt_update desc
                )
                select dt_update, id_prof_update 
                from fups
                where rownum = 1]';
    
        l_ret t_sch_hist_upd_info;
    BEGIN
        EXECUTE IMMEDIATE l_query -- dyn sql due to dynamic from table and column
            INTO l_ret.update_date, l_ret.update_user
            USING i_id_sch;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN get_hist_last_upd_info(i_id_sch);
    END get_hist_col_last_upd_info;

    /*  
    *
    */
    FUNCTION get_hist_col_updates
    (
        i_id_sch     schedule.id_schedule%TYPE,
        i_table_name VARCHAR2,
        i_col_name   VARCHAR2
    ) RETURN tt_sch_hist_upd_info IS
        l_ret   tt_sch_hist_upd_info;
        l_query VARCHAR2(2000) := q'[select dt_update, id_prof_update, valor
                  from (
                        select nvl(cast(h.]' || i_col_name ||
                                  q'[ as varchar(4000)), 'null') valor,
                               lag(nvl(cast(h.]' || i_col_name ||
                                  q'[ as varchar(4000)), 'null'), 1, 'null') over(order by dt_update) valor_ant,
                               h.dt_update,
                               h.id_prof_update
                        from ]' || i_table_name ||
                                  q'[ h
                        where h.id_schedule = :id
                       )
                  where valor <> valor_ant
                  order by dt_update desc]';
    BEGIN
        EXECUTE IMMEDIATE l_query BULK COLLECT
            INTO l_ret
            USING i_id_sch;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN tt_sch_hist_upd_info();
    END get_hist_col_updates;

    /* Add the SCHEDULING BLOCK TO THE OUTPUT.
    * Used in functions pk_schedule_exam.get_sch_detail, pk_schedule_exam.get_sch_hist, pk_schedule_lab.get_sch_detail, pk_schedule_lab.get_sch_hist
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
    ) IS
        l_str VARCHAR2(32767);
    BEGIN
        -- header: Scheduling
        pk_edis_hist.add_value(i_lang  => i_lang,
                               i_label => pk_message.get_message(i_lang => i_lang, i_code_mess => g_m_scheduling),
                               i_value => NULL,
                               i_type  => pk_edis_hist.g_type_title);
    
        -- field: patient name
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang => i_lang, i_code_mess => g_m_pat_name),
                               i_value    => i_pat_name,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: scheduling date
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang => i_lang, i_code_mess => g_m_sch_date),
                               i_value    => i_sch_date,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: scheduling test(s)
        pk_edis_hist.add_value(i_lang     => i_lang,
                               i_flg_call => pk_edis_hist.g_call_detail,
                               i_label    => pk_message.get_message(i_lang => i_lang, i_code_mess => g_m_sch_tests),
                               i_value    => i_tests,
                               i_type     => pk_edis_hist.g_type_content);
    
        -- field: signature
        l_str := pk_edis_hist.get_signature(i_lang                   => i_lang,
                                            i_id_episode             => NULL,
                                            i_prof                   => i_prof,
                                            i_date                   => i_created_date,
                                            i_id_prof_last_change    => i_created_by,
                                            i_has_historical_changes => pk_alert_constant.g_no);
    
        pk_edis_hist.add_value(i_label => NULL,
                               i_value => l_str,
                               i_type  => pk_edis_hist.g_type_signature,
                               i_code  => 'SIGNATURE');
    END add_scheduling_block;

    /*
    *
    */
    FUNCTION get_dep_type
    (
        i_lang        IN NUMBER,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_dep_type    OUT schedule.flg_sch_type%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'get dep_type';
        SELECT nvl(s.flg_sch_type, se.dep_type)
          INTO o_dep_type
          FROM schedule s
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
         WHERE s.id_schedule = i_id_schedule;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DEP_TYPE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_dep_type;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_common;
/
