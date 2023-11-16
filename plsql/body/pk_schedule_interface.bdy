/*-- Last Change Revision: $Rev: 2027678 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_interface IS
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
        pk_alertlog.log_error(text        => i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror,
                              object_name => g_package_name,
                              owner       => g_package_owner);
    END error_handling;

    /*
    * Gets the professional's default language
    * 
    * @param i_id_professional       Professional identifier.
    * @param i_id_institution        Institution identifier.
    * @param o_lang_id               Language identifier.
    * @param o_error                 Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/06
    *
    * UPDATE alert-50388 passa a receber o id_software em vez de usar constante g_outpatient_software
    * @author Telmo
    * @version 2.5.0.6.3
    * @date    20-10-2009
    */
    FUNCTION get_prof_default_language
    (
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_software     IN prof_preferences.id_software%TYPE,
        o_lang_id         OUT language.id_language%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PROF_DEFAULT_LANGUAGE';
    BEGIN
        g_error := 'GET LANGUAGE';
        -- Get the professional's language.
        SELECT id_language
          INTO o_lang_id
          FROM (SELECT pp.id_language
                  FROM prof_preferences pp
                 WHERE pp.id_professional = i_id_professional
                   AND pp.id_institution = i_id_institution
                   AND (pp.id_software IS NULL OR pp.id_software = i_id_software)
                 ORDER BY decode(pp.id_software, i_id_software, i_id_software, NULL, i_id_software * 2))
         WHERE rownum = 1;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_lang_id := NULL;
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_default_language;

    /*
    * Returns the next available schedule identifier.
    * 
    * @return next available schedule identifier
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/04
    */
    FUNCTION get_next_schedule_id RETURN schedule.id_schedule%TYPE IS
        l_ret_id schedule.id_schedule%TYPE;
    BEGIN
        SELECT seq_schedule.nextval
          INTO l_ret_id
          FROM dual;
        RETURN l_ret_id;
    END get_next_schedule_id;

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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'EXISTS_MATCHING_SCHEDULE';
        l_id_schedule schedule.id_schedule%TYPE := NULL;
    BEGIN
        BEGIN
            g_error := 'SELECT ID';
            SELECT id_schedule
              INTO l_id_schedule
              FROM (SELECT vso.id_schedule id_schedule
                      FROM v_schedule_outp vso, sch_resource sr, sch_group sg, sch_event se
                     WHERE vso.id_instit_requested = i_sched_outp.id_instit_requested
                       AND vso.id_dcs_requested = i_sched_outp.id_dcs_requested
                       AND vso.id_schedule = sr.id_schedule(+)
                       AND vso.id_schedule = sg.id_schedule
                       AND vso.id_sch_event = se.id_sch_event
                       AND nvl(sr.id_professional, pk_schedule.g_unknown_id) =
                           nvl(i_sched_outp.id_prof_requested, pk_schedule.g_unknown_id)
                       AND sg.id_patient = i_sched_outp.id_patient
                       AND vso.dt_begin_tstz = i_sched_outp.dt_begin
                       AND se.flg_occurrence = i_sched_outp.flg_first_subs
                       AND ((sr.id_professional IS NULL AND se.flg_target_professional = g_no) OR
                           (sr.id_professional IS NOT NULL AND se.flg_target_professional = g_yes))
                       AND (vso.flg_status <> g_sch_status_cancelled OR nvl(i_sched_outp.flg_ignore_cancel, g_no) = g_no)
                     ORDER BY decode(vso.flg_status, g_sch_status_scheduled, 2, g_sch_status_cancelled, 1, 0) ASC)
             WHERE rownum = 1;
            o_exists := TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                o_exists := FALSE;
        END;
    
        o_id_sched := l_id_schedule;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_id_sched := NULL;
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END exists_matching_schedule;

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
    * @author Rita Lopes
    * @version 1.0
    * @since 2008/02/26
    * @Notes Acrescentar uma flag na chamada à funcao pk_schedule_common. com a info de encontro directo ou indirecto   
    *
    * UPDATED
    * a flg_request_type passou da tabela schedule_outp para a schedule. A invocacao da create_schedule e da 
    * foram ajustadas
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    06-06-2008
    *
    *  UPDATED
    * Desnormalização , substituição de insert p1_external_request 
    * Adição de uma excepção
    * @author  Joana Barroso
    * @version 2.4.3d
    * @date    30-09-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * ALERT-17830. adaptacao para consultas de enfermagem. Para tal foi acrescentado novo campo na schedule_outp_struct, o id_sch_event.
    * Quando o i_sched_outp.id_sch_event = NULL vai sempre buscar um evento ao conjunto de eventos da Consulta externa.
    * Quando o i_sched_outp.id_sch_event <> NULL usa esse.
    * @author  Telmo Castro
    * @date    18-02-2009
    * @version 2.4.3.x
    *
    * UPDATED
    * ALERT-25834. O valor para o parametro i_flg_sch_type do create_schedule deve ser passar a ser calculado atraves da sch_event
    * @author  Telmo Castro
    * @date    29-04-2009
    * @version 2.4.3.23 e 2.5
    */
    FUNCTION create_schedule_outp
    (
        i_sched_outp   IN schedule_outp_struct,
        o_new_id_sched OUT schedule.id_schedule%TYPE,
        o_warning      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'CREATE_SCHEDULE_OUTP';
        l_id_schedule         schedule.id_schedule%TYPE := NULL;
        l_occupied            sch_consult_vacancy.id_sch_consult_vacancy%TYPE; --BOOLEAN;
        l_id_sch_event        sch_event.id_sch_event%TYPE;
        l_exists              BOOLEAN;
        l_schedule_rec        schedule%ROWTYPE;
        l_outpatient_software epis_type_soft_inst.id_software%TYPE;
        l_flg_ignore_cancel   VARCHAR2(0050);
        l_rowids              table_varchar;
        l_lang                language.id_language%TYPE;
        l_dep_type            sch_event.dep_type%TYPE;
    
        CURSOR c_sched(i_id_schedule schedule.id_schedule%TYPE) IS
            SELECT *
              FROM schedule s
             WHERE s.id_schedule = c_sched.i_id_schedule;
    
        -- Returns the event identifier.
        -- Telmo 18-02. esta funcao so' devolve evento de entre os de consulta externa. Por isso quando i_sched_outp.id_sch_event = NULL
        -- ela e' invocada e devolve sempre um evento de C.E..
        -- Optei por deixa-la intocada 
        FUNCTION inner_get_event RETURN sch_event.id_sch_event%TYPE IS
            l_id_sch_event sch_event.id_sch_event%TYPE;
        BEGIN
            g_error := 'GET_EVENT';
            SELECT se.id_sch_event
              INTO l_id_sch_event
              FROM sch_event se
             WHERE se.flg_occurrence = i_sched_outp.flg_first_subs
               AND se.flg_target_professional = decode(i_sched_outp.id_prof_requested, NULL, g_no, g_yes)
               AND se.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
               AND rownum = 1;
            RETURN l_id_sch_event;
        END inner_get_event;
    
        -- Gets the schedule's information
        FUNCTION inner_get_schedule(i_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_sched_ret_rec c_sched%ROWTYPE := NULL;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(i_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_sched_ret_rec;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
            RETURN l_sched_ret_rec;
        END inner_get_schedule;
    
        -- get dep_type from id_sch_event
        FUNCTION inner_get_dep_type(i_id_sch_event sch_event.id_sch_event%TYPE) RETURN sch_event.dep_type%TYPE IS
            l_dep_type sch_event.dep_type%TYPE;
        BEGIN
            g_error := 'GET DEP TYPE';
            SELECT se.dep_type
              INTO l_dep_type
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event;
            RETURN l_dep_type;
        END inner_get_dep_type;
    
    BEGIN
        g_error := 'GET MATCHING SCHEDULE';
        -- Try to get a matching schedule
        IF NOT exists_matching_schedule(i_sched_outp => i_sched_outp,
                                        o_id_sched   => l_id_schedule,
                                        o_exists     => l_exists,
                                        o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- If the schedule exists, get its status and schedule date.
        IF l_exists
        THEN
            l_schedule_rec := inner_get_schedule(l_id_schedule);
        END IF;
    
        -- By defauly we do not ignore existing cancelled schedules that were created on the same day.
        l_flg_ignore_cancel := nvl(i_sched_outp.flg_ignore_cancel, g_flg_ignore_cancel_no);
    
        -- If a matching schedule does not exist OR
        -- if a cancellation was found but not on the same day 
        -- a new schedule is created. 
        -- (This is a work-around as the interfaces cannot achieve request-response serialization).
        IF NOT l_exists
           OR
           (l_schedule_rec.flg_status = pk_schedule.g_sched_status_cancelled AND
           (trunc(l_schedule_rec.dt_schedule_tstz) <> trunc(SYSDATE) OR l_flg_ignore_cancel = g_flg_ignore_cancel_yes))
        THEN
            -- Get event
            IF i_sched_outp.id_sch_event IS NULL
            THEN
                l_id_sch_event := inner_get_event();
            ELSE
                l_id_sch_event := i_sched_outp.id_sch_event;
            END IF;
        
            l_id_schedule := i_sched_outp.id_schedule;
        
            g_error := 'GET SOFTWARE FROM EPIS TYPE';
            -- Get outpatient software.
            l_outpatient_software := nvl(pk_episode.get_soft_by_epis_type(i_sched_outp.id_epis_type,
                                                                          nvl(i_sched_outp.id_instit_requests, 0)),
                                         g_outpatient_software);
        
            -- Telmo 29-04 get flg_sch_type from id_sch_event
            l_dep_type := inner_get_dep_type(l_id_sch_event);
        
            g_error := 'CALL CREATE_SCHEDULE';
            -- Create schedule data.
            IF NOT pk_schedule_common.create_schedule(i_lang              => NULL,
                                                      i_id_schedule       => l_id_schedule,
                                                      i_id_prof_schedules => i_sched_outp.id_prof_schedules,
                                                      i_id_institution    => i_sched_outp.id_instit_requests,
                                                      i_id_software       => l_outpatient_software, --g_outpatient_software,
                                                      i_id_patient        => i_sched_outp.id_patient,
                                                      i_id_dep_clin_serv  => i_sched_outp.id_dcs_requested,
                                                      i_id_sch_event      => l_id_sch_event,
                                                      i_id_prof           => i_sched_outp.id_prof_requested,
                                                      i_dt_begin          => i_sched_outp.dt_begin,
                                                      i_dt_end            => i_sched_outp.dt_end,
                                                      i_flg_vacancy       => nvl(i_sched_outp.flg_vacancy,
                                                                                 pk_schedule_common.g_sched_vacancy_routine),
                                                      i_flg_status        => pk_schedule.g_status_scheduled,
                                                      i_schedule_notes    => i_sched_outp.schedule_notes,
                                                      i_id_prof_requests  => i_sched_outp.id_prof_requests,
                                                      i_id_reason         => i_sched_outp.id_reason,
                                                      i_id_origin         => i_sched_outp.id_origin,
                                                      i_id_schedule_ref   => i_sched_outp.id_schedule_ref,
                                                      i_id_room           => i_sched_outp.id_room,
                                                      i_reason_notes      => i_sched_outp.reason_notes,
                                                      i_flg_sch_type      => l_dep_type, --pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                                      i_flg_request_type  => i_sched_outp.flg_sched_request_type,
                                                      i_flg_schedule_via  => i_sched_outp.flg_schedule_via,
                                                      o_id_schedule       => l_id_schedule,
                                                      o_occupied          => l_occupied,
                                                      o_error             => o_error)
            THEN
                -- Error while creating the schedule
                pk_alert_exceptions.process_error(i_lang     => NULL,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error creating schedule.',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            o_new_id_sched := l_id_schedule;
        
            g_error := 'CALL CREATE_SCHEDULE_OUTP';
            -- Create outpatient-specific data. 
            IF NOT pk_schedule_common.create_schedule_outp(i_lang              => NULL,
                                                           i_id_prof_schedules => i_sched_outp.id_prof_schedules,
                                                           i_id_institution    => i_sched_outp.id_instit_requested,
                                                           i_id_software       => l_outpatient_software,
                                                           i_id_schedule       => l_id_schedule,
                                                           i_id_patient        => i_sched_outp.id_patient,
                                                           i_id_dep_clin_serv  => i_sched_outp.id_dcs_requested,
                                                           i_id_sch_event      => l_id_sch_event,
                                                           i_id_prof           => i_sched_outp.id_prof_requested,
                                                           i_dt_begin          => i_sched_outp.dt_begin,
                                                           i_schedule_notes    => i_sched_outp.schedule_notes,
                                                           i_id_episode        => NULL,
                                                           i_id_epis_type      => i_sched_outp.id_epis_type,
                                                           -- Telmo 06-06-2008
                                                           --i_flg_sched_request_type => i_sched_outp.flg_sched_request_type,
                                                           i_flg_sched_type => i_sched_outp.flg_sched_type,
                                                           o_error          => o_error)
            THEN
                -- Error while creating the outpatient part of the schedule
                pk_alert_exceptions.process_error(i_lang     => NULL,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error creating schedule (outpatient data).',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            -- Set associated referral        
            -- CHANGED BY: Joana Barroso
            -- CHANGED DATE: 2008-SEP-18
            -- CHANGED REASON: Desnormalização
            g_error := 'SET REFERRAL';
            l_lang  := 2;
        
            ts_p1_external_request.upd(id_external_request_in => i_sched_outp.ref_num,
                                       id_schedule_in         => l_id_schedule,
                                       rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => l_lang,
                                          i_prof       => profissional(0, 0, 0),
                                          i_table_name => 'P1_EXTERNAL_REQUEST',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- UPDATE p1_external_request SET id_schedule = l_id_schedule WHERE id_external_request = i_sched_outp.ref_num;
            -- CHANGE END    
        
        ELSE
            IF l_schedule_rec.flg_status = pk_schedule.g_sched_status_scheduled
            THEN
                -- Duplicate schedule found. Issue a warning.
                o_new_id_sched := l_id_schedule;
                o_warning      := 'Duplicate schedule found. [ id_schedule: ' || l_id_schedule || ' ]';
            ELSIF l_schedule_rec.flg_status = pk_schedule.g_sched_status_pending
            THEN
                -- Pending schedule found, update it.
                IF NOT pk_schedule_common.alter_schedule(i_lang             => NULL,
                                                         i_id_schedule      => l_id_schedule,
                                                         i_flg_status       => pk_schedule.g_sched_status_scheduled,
                                                         i_dt_schedule_tstz => current_timestamp,
                                                         o_schedule_rec     => l_schedule_rec,
                                                         o_error            => o_error)
                THEN
                    -- Error while updating the schedule's status
                    pk_alert_exceptions.process_error(i_lang     => NULL,
                                                      i_sqlcode  => SQLCODE,
                                                      i_sqlerrm  => 'Error updating schedule to scheduled.',
                                                      i_message  => g_error,
                                                      i_owner    => g_package_owner,
                                                      i_package  => g_package_name,
                                                      i_function => l_func_name,
                                                      o_error    => o_error);
                    RETURN FALSE;
                END IF;
            
                -- Clear the schedule request from the consult requests.
                --<DENORM RicardoNunoAlmeida>
                ts_consult_req.upd(flg_status_in => pk_consult_req.g_consult_req_stat_sched,
                                   where_in      => 'id_schedule =' || l_id_schedule,
                                   rows_out      => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => 1,
                                              i_prof       => profissional(0, 0, 0),
                                              i_table_name => 'CONSULT_REQ',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                --</DENORM>
            
                o_new_id_sched := l_id_schedule;
            ELSIF l_schedule_rec.flg_status = pk_schedule.g_sched_status_cancelled
            THEN
                -- Cancelled schedule on the same day.
                -- The interfaces cannot guarantee request-response serialization, so we
                -- ignore schedule creation if a matching cancelled schedule already exists
                -- and was created on the same day.
                -- Example:
                -- 1. The user creates a schedule on 
                -- 2. The schedule is sent via interface.
                -- 3. The user cancels the schedule.
                -- 4. The duplicate creation is received via interface (external systems should not duplicate requests, but they do).
                -- 5. The schedule was already cancelled, so the duplicate creation is ignored.
                --
                -- NOTE: This is not the perfect solution, but the only feasible option without
                -- having the guarantee that no external system sends a request to Alert that already
                -- was sent by Alert to the external system.
                o_new_id_sched := l_id_schedule;
                o_warning      := 'A cancelled schedule was found, on the same day. [ id_schedule: ' || l_id_schedule || ' ]';
            ELSE
                -- Unexpected situation. Ignore 
                o_new_id_sched := l_id_schedule;
                o_warning      := 'Unexpected status for schedule. [ id_schedule: ' || l_id_schedule || ', ' ||
                                  l_schedule_rec.flg_status || ' ]';
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN g_data_gov_e THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
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
    * @since  2007/05/30
    *
    * UPDATED
    * a flg_request_type (antes era flg_sched_request_type) passou da tabela schedule_outp para a schedule. 
    *
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    06-06-2008
    *
    * UPDATED
    * ALERT-17830. adaptacao para consultas de enfermagem. Para tal foi acrescentado novo campo na schedule_outp_struct, o id_sch_event.
    * @author  Telmo Castro
    * @date    18-02-2009
    * @version 2.4.3.x
    *
    * UPDATED
    * ALERT-39001. Cancelamento de agendamentos MFR nao passam para sonho porque estes nao tem registo na schedule_outp. 
    * Acrescentei cursor e codigo para esses casos.
    * @author  Telmo
    * @date     19-08-2009
    * @version 2.4.3.27
    */
    FUNCTION get_schedule_outp
    (
        i_id_sched   IN schedule.id_schedule%TYPE,
        o_sched_outp OUT schedule_outp_struct,
        o_warning    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCHEDULE_OUTP';
    
        -- Get the appointment's data for non-mfr appoints
        CURSOR c_sched IS
            SELECT vso.id_schedule,
                   vso.id_schedule_ref,
                   vso.id_instit_requests,
                   vso.id_instit_requested,
                   vso.id_dcs_requests,
                   vso.id_dcs_requested,
                   vso.id_prof_requests,
                   vso.id_prof_schedules,
                   vso.id_prof_cancel,
                   sr.id_professional      id_prof_requested,
                   vso.id_epis_type,
                   vso.id_cancel_reason,
                   sg.id_patient,
                   vso.id_lang_translator,
                   vso.id_lang_preferred,
                   vso.id_reason,
                   vso.id_origin,
                   vso.id_room,
                   vso.dt_begin,
                   vso.dt_end,
                   vso.dt_cancel,
                   vso.schedule_notes,
                   vso.flg_notification,
                   vso.flg_vacancy,
                   se.flg_occurrence,
                   vso.flg_status,
                   s.reason_notes,
                   exr.id_external_request ref_num,
                   s.flg_schedule_via,
                   vso.flg_request_type,
                   se.id_sch_event
              FROM v_schedule_outp     vso,
                   sch_group           sg,
                   sch_resource        sr,
                   sch_event           se,
                   schedule            s,
                   p1_external_request exr,
                   schedule_outp       so
             WHERE vso.id_schedule = i_id_sched
               AND exr.id_schedule(+) = vso.id_schedule
               AND so.id_schedule = i_id_sched
               AND s.id_schedule = i_id_sched
               AND vso.id_schedule = sg.id_schedule(+)
               AND vso.id_schedule = sr.id_schedule(+)
               AND vso.id_sch_event = se.id_sch_event;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- get appoint data for mfr 
        CURSOR c_sched_mfr IS
            SELECT s.id_schedule,
                   s.id_schedule_ref,
                   s.id_instit_requests,
                   s.id_instit_requested,
                   s.id_dcs_requests,
                   s.id_dcs_requested,
                   s.id_prof_requests,
                   s.id_prof_schedules,
                   s.id_prof_cancel,
                   sr.id_professional id_prof_requested,
                   (SELECT id_epis_type
                      FROM sch_event_soft ses
                     WHERE id_sch_event = se.id_sch_event
                       AND rownum = 1) id_epis_type,
                   s.id_cancel_reason,
                   sg.id_patient,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_room,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   s.dt_cancel_tstz,
                   s.schedule_notes,
                   s.flg_notification,
                   s.flg_vacancy,
                   se.flg_occurrence,
                   s.flg_status,
                   s.reason_notes,
                   exr.id_external_request ref_num,
                   s.flg_schedule_via,
                   s.flg_request_type,
                   se.id_sch_event
              FROM schedule s
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
              LEFT JOIN p1_external_request exr
                ON s.id_schedule = exr.id_schedule
             WHERE s.id_schedule = i_id_sched
               AND rownum = 1;
    
        l_sched_rec_mfr c_sched%ROWTYPE;
    BEGIN
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
        IF c_sched%NOTFOUND
        THEN
            -- No appointment was found. try with mfr cursor
            g_error := 'OPEN c_sched_mfr';
            OPEN c_sched_mfr;
            g_error := 'FETCH c_sched_mfr';
            FETCH c_sched_mfr
                INTO l_sched_rec_mfr;
            IF c_sched_mfr%NOTFOUND
            THEN
                o_sched_outp := NULL;
                pk_alert_exceptions.process_error(i_lang     => 1,
                                                  i_sqlcode  => -1,
                                                  i_sqlerrm  => 'NO DATA FOUND',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            ELSE
                -- Set output record's values
                o_sched_outp.id_schedule            := i_id_sched;
                o_sched_outp.id_instit_requests     := l_sched_rec_mfr.id_instit_requests;
                o_sched_outp.id_instit_requested    := l_sched_rec_mfr.id_instit_requested;
                o_sched_outp.id_dcs_requests        := l_sched_rec_mfr.id_dcs_requests;
                o_sched_outp.id_dcs_requested       := l_sched_rec_mfr.id_dcs_requested;
                o_sched_outp.id_prof_requests       := l_sched_rec_mfr.id_prof_requests;
                o_sched_outp.id_prof_requested      := l_sched_rec_mfr.id_prof_requested;
                o_sched_outp.id_prof_schedules      := l_sched_rec_mfr.id_prof_schedules;
                o_sched_outp.id_prof_cancel         := l_sched_rec_mfr.id_prof_cancel;
                o_sched_outp.id_epis_type           := l_sched_rec_mfr.id_epis_type;
                o_sched_outp.id_cancel_reason       := l_sched_rec_mfr.id_cancel_reason;
                o_sched_outp.id_patient             := l_sched_rec_mfr.id_patient;
                o_sched_outp.id_lang_translator     := l_sched_rec_mfr.id_lang_translator;
                o_sched_outp.id_lang_preferred      := l_sched_rec_mfr.id_lang_preferred;
                o_sched_outp.id_reason              := l_sched_rec_mfr.id_reason;
                o_sched_outp.id_origin              := l_sched_rec_mfr.id_origin;
                o_sched_outp.id_room                := l_sched_rec_mfr.id_room;
                o_sched_outp.id_schedule_ref        := l_sched_rec_mfr.id_schedule_ref;
                o_sched_outp.dt_begin               := l_sched_rec_mfr.dt_begin;
                o_sched_outp.dt_end                 := l_sched_rec_mfr.dt_end;
                o_sched_outp.dt_cancel              := l_sched_rec_mfr.dt_cancel;
                o_sched_outp.schedule_notes         := l_sched_rec_mfr.schedule_notes;
                o_sched_outp.flg_notification       := l_sched_rec_mfr.flg_notification;
                o_sched_outp.flg_vacancy            := l_sched_rec_mfr.flg_vacancy;
                o_sched_outp.flg_first_subs         := l_sched_rec_mfr.flg_occurrence;
                o_sched_outp.flg_status             := l_sched_rec_mfr.flg_status;
                o_sched_outp.reason_notes           := l_sched_rec_mfr.reason_notes;
                o_sched_outp.ref_num                := l_sched_rec_mfr.ref_num;
                o_sched_outp.flg_schedule_via       := l_sched_rec_mfr.flg_schedule_via;
                o_sched_outp.flg_sched_request_type := l_sched_rec_mfr.flg_request_type;
                o_sched_outp.id_sch_event           := l_sched_rec_mfr.id_sch_event;
            END IF;
        ELSE
            -- Set output record's values
            o_sched_outp.id_schedule            := i_id_sched;
            o_sched_outp.id_instit_requests     := l_sched_rec.id_instit_requests;
            o_sched_outp.id_instit_requested    := l_sched_rec.id_instit_requested;
            o_sched_outp.id_dcs_requests        := l_sched_rec.id_dcs_requests;
            o_sched_outp.id_dcs_requested       := l_sched_rec.id_dcs_requested;
            o_sched_outp.id_prof_requests       := l_sched_rec.id_prof_requests;
            o_sched_outp.id_prof_requested      := l_sched_rec.id_prof_requested;
            o_sched_outp.id_prof_schedules      := l_sched_rec.id_prof_schedules;
            o_sched_outp.id_prof_cancel         := l_sched_rec.id_prof_cancel;
            o_sched_outp.id_epis_type           := l_sched_rec.id_epis_type;
            o_sched_outp.id_cancel_reason       := l_sched_rec.id_cancel_reason;
            o_sched_outp.id_patient             := l_sched_rec.id_patient;
            o_sched_outp.id_lang_translator     := l_sched_rec.id_lang_translator;
            o_sched_outp.id_lang_preferred      := l_sched_rec.id_lang_preferred;
            o_sched_outp.id_reason              := l_sched_rec.id_reason;
            o_sched_outp.id_origin              := l_sched_rec.id_origin;
            o_sched_outp.id_room                := l_sched_rec.id_room;
            o_sched_outp.id_schedule_ref        := l_sched_rec.id_schedule_ref;
            o_sched_outp.dt_begin               := l_sched_rec.dt_begin;
            o_sched_outp.dt_end                 := l_sched_rec.dt_end;
            o_sched_outp.dt_cancel              := l_sched_rec.dt_cancel;
            o_sched_outp.schedule_notes         := l_sched_rec.schedule_notes;
            o_sched_outp.flg_notification       := l_sched_rec.flg_notification;
            o_sched_outp.flg_vacancy            := l_sched_rec.flg_vacancy;
            o_sched_outp.flg_first_subs         := l_sched_rec.flg_occurrence;
            o_sched_outp.flg_status             := l_sched_rec.flg_status;
            o_sched_outp.reason_notes           := l_sched_rec.reason_notes;
            o_sched_outp.ref_num                := l_sched_rec.ref_num;
            o_sched_outp.flg_schedule_via       := l_sched_rec.flg_schedule_via;
            o_sched_outp.flg_sched_request_type := l_sched_rec.flg_request_type;
            o_sched_outp.id_sch_event           := l_sched_rec.id_sch_event;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_schedule_outp;

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
    *
    * UPDATED - o update da consult_req estava a receber o l_id_schedule sempre a null
    * @author Telmo Castro
    * @date   28-02-2008
    */
    FUNCTION cancel_schedule_outp
    (
        i_sched_outp_cancel IN schedule_outp_cancel_struct,
        o_warning           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE_OUTP';
        l_rowids    table_varchar;
    
        -- Cursor for getting the schedule that is going to be cancelled.
        CURSOR c_sched IS
            SELECT vso.*
              FROM v_schedule_outp vso
             WHERE vso.id_schedule = i_sched_outp_cancel.id_schedule;
    
        l_sched_rec    c_sched%ROWTYPE;
        l_schedule_rec schedule%ROWTYPE;
        --        l_id_schedule  schedule.id_schedule%TYPE;
    BEGIN
        -- Get schedule to cancel.
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
    
        IF c_sched%NOTFOUND
        THEN
            -- Invalid schedule identifier
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'No data found',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            -- Schedule found.
            IF l_sched_rec.flg_status = pk_schedule.g_sched_status_cancelled
            THEN
                -- Duplicate cancellation found. Issue a warning.
                o_warning := 'Duplicate cancellation found. [ id_schedule: ' || l_sched_rec.id_schedule /*estava l_id_schedule*/
                             || ' ]';
            ELSIF l_sched_rec.flg_status = pk_schedule.g_sched_status_pending
            THEN
                -- Pending schedule found. It was a result of a failed cancellation.
                g_error := 'CALL ALTER_SCHEDULE';
                IF NOT pk_schedule_common.alter_schedule(i_lang           => NULL,
                                                         i_id_schedule    => i_sched_outp_cancel.id_schedule,
                                                         i_flg_status     => pk_schedule.g_sched_status_cancelled,
                                                         i_dt_cancel_tstz => i_sched_outp_cancel.dt_cancel,
                                                         o_schedule_rec   => l_schedule_rec,
                                                         o_error          => o_error)
                THEN
                    pk_alert_exceptions.process_error(i_lang     => NULL,
                                                      i_sqlcode  => SQLCODE,
                                                      i_sqlerrm  => 'Error alter the pending schedule to cancelled. [ id_schedule: ' ||
                                                                    l_sched_rec.id_schedule || ' ]',
                                                      i_message  => g_error,
                                                      i_owner    => g_package_owner,
                                                      i_package  => g_package_name,
                                                      i_function => l_func_name,
                                                      o_error    => o_error);
                    RETURN FALSE;
                END IF;
            
                -- Clear the schedule request from the consult requests.
                --<DENORM RicardoNunoAlmeida>
                ts_consult_req.upd(flg_status_in => pk_consult_req.g_consult_req_stat_cancel,
                                   where_in      => 'id_schedule =' || l_sched_rec.id_schedule,
                                   rows_out      => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => 1,
                                              i_prof       => profissional(0, 0, 0),
                                              i_table_name => 'CONSULT_REQ',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                --</DENORM>
            
            ELSE
                -- Cancel the existing schedule 
                g_error := 'CALL CANCEL_SCHEDULE';
                IF NOT pk_schedule_common.cancel_schedule(i_lang             => NULL,
                                                          i_id_professional  => i_sched_outp_cancel.id_prof_cancel,
                                                          i_id_software      => g_outpatient_software,
                                                          i_id_schedule      => l_sched_rec.id_schedule,
                                                          i_cancel_notes     => i_sched_outp_cancel.cancel_notes,
                                                          i_id_cancel_reason => i_sched_outp_cancel.id_reason,
                                                          o_error            => o_error)
                THEN
                    pk_alert_exceptions.process_error(i_lang     => NULL,
                                                      i_sqlcode  => SQLCODE,
                                                      i_sqlerrm  => 'Error cancelling the schedule. [ id_schedule: ' ||
                                                                    l_sched_rec.id_schedule || ' ]',
                                                      i_message  => g_error,
                                                      i_owner    => g_package_owner,
                                                      i_package  => g_package_name,
                                                      i_function => l_func_name,
                                                      o_error    => o_error);
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_schedule_outp;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'IS_TRANSPORTABLE';
    
        -- Get the appointment's data
        CURSOR c_sched IS
            SELECT vso.flg_sch_type
              FROM v_schedule_outp vso
             WHERE vso.id_schedule = i_id_sched;
    
        l_sched_rec c_sched%ROWTYPE;
    BEGIN
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
        IF c_sched%NOTFOUND
        THEN
            -- No appointment was found.
            o_transportable := FALSE;
        ELSE
            -- Only outpatient appointments are transportable.
            o_transportable := l_sched_rec.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END is_transportable;

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
    *
    * UPDATE alert-50388 passa a receber o id_software em vez de usar constante g_outpatient_software
    * @author Telmo
    * @version 2.5.0.6.3
    * @date    20-10-2009
    */
    FUNCTION set_schedule_pending_outp
    (
        i_set_pending IN schedule_outp_setpend_struct,
        o_warning     OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_SCHEDULE_PENDING_OUTP';
    
        -- Get the appointment's data
        CURSOR c_sched IS
            SELECT vso.*, sg.id_patient
              FROM v_schedule_outp vso, sch_group sg
             WHERE vso.id_schedule = i_set_pending.id_schedule
               AND vso.id_schedule = sg.id_schedule;
    
        l_sched_rec            c_sched%ROWTYPE := NULL;
        l_dummy                schedule%ROWTYPE;
        l_consult_req_rec      consult_req%ROWTYPE;
        l_consult_req_prof_rec consult_req_prof%ROWTYPE;
    
        l_lang        language.id_language%TYPE;
        l_message     sys_message.desc_message%TYPE;
        l_message_key sys_message.code_message%TYPE;
    BEGIN
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
        IF l_sched_rec.id_schedule IS NULL
        THEN
            -- No appointment was found.
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'No data found',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            pk_alertlog.log_warn(text        => l_func_name || ': Set schedule status to pending. [ id_schedule: ' ||
                                                l_sched_rec.id_schedule || ' ] [ notes: ' ||
                                                i_set_pending.pending_notes || ' ]',
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            -- Appointment found. Change its status to pending and create a consult request.
        
            -- Get default language.
            IF NOT get_prof_default_language(i_id_professional => nvl(l_sched_rec.id_prof_schedules,
                                                                      l_sched_rec.id_prof_requests),
                                             i_id_institution  => l_sched_rec.id_instit_requested,
                                             i_id_software     => nvl(l_sched_rec.id_software, g_outpatient_software),
                                             o_lang_id         => l_lang,
                                             o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- Get message key depending on the previous status.
            IF i_set_pending.flg_status = pk_schedule.g_sched_status_cancelled
            THEN
                l_message_key := pk_schedule.g_interface_cancel_error_msg;
            ELSIF i_set_pending.flg_status = pk_schedule.g_sched_status_scheduled
            THEN
                l_message_key := pk_schedule.g_interface_sch_error_msg;
            END IF;
        
            -- Get message
            l_message := pk_schedule.get_message(l_lang, l_message_key);
        
            g_error := 'CALL ALTER_SCHEDULE';
            -- Set schedule status
            IF NOT pk_schedule_common.alter_schedule(i_lang         => NULL,
                                                     i_id_schedule  => l_sched_rec.id_schedule,
                                                     i_flg_status   => pk_schedule.g_sched_status_pending,
                                                     o_schedule_rec => l_dummy,
                                                     o_error        => o_error)
            THEN
                pk_alert_exceptions.process_error(i_lang     => NULL,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error altering the schedule. [ id_schedule: ' ||
                                                                l_sched_rec.id_schedule || ' ]',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            -- Create consult request 
            g_error := 'CALL NEW_CONSULT_REQ';
            IF NOT pk_schedule_common.new_consult_req(i_lang                => NULL,
                                                      i_dt_consult_req_tstz => current_timestamp,
                                                      i_id_patient          => l_sched_rec.id_patient,
                                                      i_id_instit_requests  => l_sched_rec.id_instit_requests,
                                                      i_id_inst_requested   => l_sched_rec.id_instit_requested,
                                                      i_id_episode          => NULL,
                                                      i_id_prof_req         => nvl(l_sched_rec.id_prof_requests,
                                                                                   l_sched_rec.id_prof_schedules),
                                                      i_dt_scheduled_tstz   => l_sched_rec.dt_begin,
                                                      i_notes_admin         => l_message || chr(10) ||
                                                                               l_sched_rec.schedule_notes,
                                                      i_id_prof_cancel      => l_sched_rec.id_prof_cancel,
                                                      i_dt_cancel_tstz      => l_sched_rec.dt_cancel,
                                                      i_notes_cancel        => l_sched_rec.schedule_cancel_notes,
                                                      i_id_dep_clin_serv    => l_sched_rec.id_dcs_requested,
                                                      i_id_prof_requested   => nvl(l_sched_rec.id_prof_requests,
                                                                                   l_sched_rec.id_prof_schedules),
                                                      i_id_schedule         => l_sched_rec.id_schedule,
                                                      i_flg_status          => pk_consult_req.g_consult_req_stat_reply,
                                                      o_consult_req_rec     => l_consult_req_rec,
                                                      o_error               => o_error)
            THEN
                pk_alert_exceptions.process_error(i_lang     => NULL,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error creating consult_req record. [ id_schedule: ' ||
                                                                l_sched_rec.id_schedule || ' ]',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL NEW_CONSULT_REQ_PROF';
            IF NOT pk_schedule_common.new_consult_req_prof(i_dt_consult_req_prof_tstz => current_timestamp,
                                                           i_id_consult_req           => l_consult_req_rec.id_consult_req,
                                                           i_id_professional          => nvl(l_sched_rec.id_prof_requests,
                                                                                             l_sched_rec.id_prof_schedules),
                                                           i_denial_justif            => NULL,
                                                           i_flg_status               => pk_schedule.g_status_scheduled,
                                                           i_dt_scheduled_tstz        => l_sched_rec.dt_begin,
                                                           o_consult_req_prof_rec     => l_consult_req_prof_rec,
                                                           o_error                    => o_error)
            THEN
                pk_alert_exceptions.process_error(i_lang     => NULL,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Error creating consult_req_prof record. [ id_schedule: ' ||
                                                                l_sched_rec.id_schedule || ' ]',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_schedule_pending_outp;

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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CREATE_ABSENCE';
        l_absence_rec sch_absence%ROWTYPE;
    BEGIN
        g_error := 'CALL NEW_ABSENCE';
        -- Create absence record
        IF NOT pk_schedule_common.new_sch_absence(i_id_sch_absence  => i_absence.id_absence,
                                                  i_id_professional => i_absence.id_professional,
                                                  i_id_institution  => i_absence.id_institution,
                                                  i_dt_begin_tstz   => i_absence.dt_begin,
                                                  i_dt_end_tstz     => i_absence.dt_end,
                                                  i_desc_absence    => i_absence.desc_absence,
                                                  i_flg_type        => i_absence.flg_type,
                                                  i_flg_status      => i_absence.flg_status,
                                                  o_sch_absence_rec => l_absence_rec,
                                                  o_error           => o_error)
        THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error creating sch_absence record. ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        o_id_absence := l_absence_rec.id_sch_absence;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END create_absence;

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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CANCEL_ABSENCE';
        l_absence_rec sch_absence%ROWTYPE;
    BEGIN
        g_error := 'CALL ALTER_ABSENCE';
        -- Create absence record
        IF NOT pk_schedule_common.alter_sch_absence(i_id_sch_absence  => i_id_absence,
                                                    i_flg_status      => g_absence_flg_status_inactive,
                                                    o_sch_absence_rec => l_absence_rec,
                                                    o_error           => o_error)
        THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error cancelling sch_absence record. ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_absence;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_ABSENCE';
    BEGIN
        g_error := 'GET ABSENCE';
        -- Get absence information
        SELECT sa.id_professional,
               sa.id_institution,
               sa.dt_begin_tstz,
               sa.dt_end_tstz,
               sa.desc_absence,
               sa.flg_type,
               sa.flg_status
          INTO o_absence.id_professional,
               o_absence.id_institution,
               o_absence.dt_begin,
               o_absence.dt_end,
               o_absence.desc_absence,
               o_absence.flg_type,
               o_absence.flg_status
          FROM sch_absence sa
         WHERE sa.id_sch_absence = i_id_absence;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_absence;

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
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'CREATE_SCHEDULE_EXAM';
        l_id_schedule       schedule.id_schedule%TYPE := NULL;
        l_exists            BOOLEAN;
        l_schedule_rec      schedule%ROWTYPE;
        l_flg_ignore_cancel VARCHAR2(0050);
    
        l_flg_proceed VARCHAR2(4000);
        l_flg_show    VARCHAR2(4000);
        l_msg         VARCHAR2(4000);
        l_msg_title   VARCHAR2(4000);
        l_button      VARCHAR2(4000);
    
        l_sch_start_date VARCHAR2(4000);
        l_sch_end_date   VARCHAR2(4000);
    
        l_id_schedule_exam schedule_exam.id_schedule_exam%TYPE;
    
        l_internal_error EXCEPTION;
    
        CURSOR c_sched(i_id_schedule schedule.id_schedule%TYPE) IS
            SELECT *
              FROM schedule s
             WHERE s.id_schedule = c_sched.i_id_schedule;
    
        -- Gets the schedule's information
        FUNCTION inner_get_schedule(i_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_sched_ret_rec c_sched%ROWTYPE := NULL;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(i_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_sched_ret_rec;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
            RETURN l_sched_ret_rec;
        END inner_get_schedule;
    
    BEGIN
        -- By defauly we do not ignore existing cancelled schedules that were created on the same day.
        l_flg_ignore_cancel := nvl(i_flg_ignore_cancel, g_flg_ignore_cancel_no);
    
        g_error := 'CALL CHECK_APPOINTMENT_RADLAB';
        IF (i_id_schedule IS NULL)
        THEN
            -- Try to get a matching schedule
            IF NOT check_appointment_radlab(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_patient          => i_id_patient,
                                            i_id_instit_requested => i_id_instit_requested,
                                            i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                            i_id_sch_event        => i_id_sch_event,
                                            i_id_prof_scheduled   => i_id_prof,
                                            i_sch_dt_begin        => i_dt_begin,
                                            i_flg_ignore_cancel   => g_no,
                                            o_exists              => l_exists,
                                            o_id_sched            => l_id_schedule,
                                            o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- If the schedule exists, get its status and schedule date.
            IF l_exists
            THEN
                l_schedule_rec := inner_get_schedule(l_id_schedule);
            END IF;
        
            -- If a matching schedule does not exist OR
            -- if a cancellation was found but not on the same day 
            -- a new schedule is created. 
            -- (This is a work-around as the interfaces cannot achieve request-response serialization).
            IF NOT l_exists
               OR (l_schedule_rec.flg_status = pk_schedule.g_sched_status_cancelled AND
               (trunc(l_schedule_rec.dt_schedule_tstz) <> trunc(SYSDATE) OR
               l_flg_ignore_cancel = g_flg_ignore_cancel_yes))
            THEN
                g_error          := 'CALL PK_DATE_UTILS.DATE_SEND_TSZ';
                l_sch_start_date := pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
                l_sch_end_date   := pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof);
            
                g_error := 'CALL PK_SCHEDULE_EXAM.CREATE_SCHEDULE';
                IF NOT pk_schedule_exam.create_schedule(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_patient          => i_id_patient,
                                                        i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                        i_id_sch_event        => i_id_sch_event,
                                                        i_id_prof             => i_id_prof,
                                                        i_dt_begin            => l_sch_start_date,
                                                        i_dt_end              => l_sch_end_date,
                                                        i_flg_vacancy         => i_flg_vacancy,
                                                        i_schedule_notes      => i_schedule_notes,
                                                        i_id_lang_translator  => i_id_lang_translator,
                                                        i_id_lang_preferred   => i_id_lang_preferred,
                                                        i_id_reason           => i_id_reason,
                                                        i_id_origin           => i_id_origin,
                                                        i_id_room             => i_id_room,
                                                        i_ids_exams           => i_ids_exams,
                                                        i_reason_notes        => i_reason_notes,
                                                        i_ids_exam_reqs       => i_ids_exam_reqs,
                                                        i_id_schedule_ref     => i_id_schedule_ref,
                                                        i_flg_request_type    => i_flg_request_type,
                                                        i_flg_schedule_via    => i_flg_schedule_via,
                                                        i_do_overlap          => i_do_overlap,
                                                        i_id_consult_vac      => i_id_consult_vac,
                                                        i_sch_option          => i_sch_option,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_sch_combi_detail => NULL,
                                                        o_id_schedule         => o_new_id_sched,
                                                        o_id_schedule_exam    => l_id_schedule_exam,
                                                        o_flg_proceed         => l_flg_proceed,
                                                        o_flg_show            => l_flg_show,
                                                        o_msg                 => l_msg,
                                                        o_msg_title           => l_msg_title,
                                                        o_button              => l_button,
                                                        o_error               => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            
                IF (l_msg IS NOT NULL)
                THEN
                    o_warning := l_msg;
                END IF;
            
                --associate referral 
                IF (i_ref_num IS NOT NULL)
                THEN
                    g_error := 'CALL TO pk_ref_service.set_ref_schedule with id_schedule=' || i_id_schedule ||
                               ' and id_referral=' || i_ref_num;
                    IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_id_ref   => i_ref_num,
                                                           i_schedule => o_new_id_sched,
                                                           i_notes    => NULL,
                                                           i_episode  => NULL,
                                                           o_error    => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                
                END IF;
            
            ELSE
                IF l_schedule_rec.flg_status = pk_schedule.g_sched_status_scheduled
                THEN
                    -- Duplicate schedule found. Issue a warning.
                    o_new_id_sched := l_id_schedule;
                    o_warning      := 'Duplicate schedule found. [ id_schedule: ' || l_id_schedule || ' ]';
                ELSIF l_schedule_rec.flg_status = pk_schedule.g_sched_status_pending
                THEN
                    -- Pending schedule found, update it.
                    IF NOT pk_schedule_common.alter_schedule(i_lang             => NULL,
                                                             i_id_schedule      => l_id_schedule,
                                                             i_flg_status       => pk_schedule.g_sched_status_scheduled,
                                                             i_dt_schedule_tstz => current_timestamp,
                                                             o_schedule_rec     => l_schedule_rec,
                                                             o_error            => o_error)
                    THEN
                        -- Error while updating the schedule's status
                        pk_alert_exceptions.process_error(i_lang     => NULL,
                                                          i_sqlcode  => SQLCODE,
                                                          i_sqlerrm  => 'Error updating schedule to scheduled.',
                                                          i_message  => g_error,
                                                          i_owner    => g_package_owner,
                                                          i_package  => g_package_name,
                                                          i_function => l_func_name,
                                                          o_error    => o_error);
                        RETURN FALSE;
                    END IF;
                
                    --update requisition status for all requisitions associated to this schedule                    
                    FOR rec IN (SELECT se.id_exam_req
                                  FROM schedule_exam se
                                 WHERE se.id_schedule = i_id_schedule
                                   AND se.id_exam_req IS NOT NULL)
                    LOOP
                        -- settar data do agendamento na req.
                        g_error := 'SET EXAM DATE';
                        IF NOT pk_exams_api_db.set_exam_date(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_exam_req        => rec.id_exam_req,
                                                             i_dt_begin        => i_dt_begin,
                                                             i_notes_scheduler => NULL,
                                                             o_error           => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    
                        -- settar status da requisicao
                        g_error := 'SET EXAM TASK';
                        IF NOT pk_exams_external_api_db.set_exam_status(i_lang     => i_lang,
                                                                        i_prof     => i_prof,
                                                                        i_exam_req => rec.id_exam_req,
                                                                        i_status   => 'A',
                                                                        o_error    => o_error)
                        THEN
                            RAISE l_internal_error;
                        END IF;
                    END LOOP;
                
                    o_new_id_sched := l_id_schedule;
                ELSIF l_schedule_rec.flg_status = pk_schedule.g_sched_status_cancelled
                THEN
                    -- Cancelled schedule on the same day.
                    -- The interfaces cannot guarantee request-response serialization, so we
                    -- ignore schedule creation if a matching cancelled schedule already exists
                    -- and was created on the same day.
                    -- Example:
                    -- 1. The user creates a schedule on 
                    -- 2. The schedule is sent via interface.
                    -- 3. The user cancels the schedule.
                    -- 4. The duplicate creation is received via interface (external systems should not duplicate requests, but they do).
                    -- 5. The schedule was already cancelled, so the duplicate creation is ignored.
                    --
                    -- NOTE: This is not the perfect solution, but the only feasible option without
                    -- having the guarantee that no external system sends a request to Alert that already
                    -- was sent by Alert to the external system.
                    o_new_id_sched := l_id_schedule;
                    o_warning      := 'A cancelled schedule was found, on the same day. [ id_schedule: ' ||
                                      l_id_schedule || ' ]';
                ELSE
                    -- Unexpected situation. Ignore 
                    o_new_id_sched := l_id_schedule;
                    o_warning      := 'Unexpected status for schedule. [ id_schedule: ' || l_id_schedule || ', ' ||
                                      l_schedule_rec.flg_status || ' ]';
                END IF;
            END IF;
        ELSE
            g_error          := 'CALL PK_DATE_UTILS.DATE_SEND_TSZ';
            l_sch_start_date := pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
            l_sch_end_date   := pk_date_utils.date_send_tsz(i_lang, i_dt_end, i_prof);
        
            g_error := 'CALL PK_SCHEDULE_EXAM.UPDATE_SCHEDULE';
            IF NOT pk_schedule_exam.update_schedule(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_id_schedule        => i_id_schedule,
                                                    i_id_patient         => i_id_patient,
                                                    i_id_dep_clin_serv   => i_id_dep_clin_serv,
                                                    i_id_sch_event       => i_id_sch_event,
                                                    i_id_prof            => i_id_prof,
                                                    i_dt_begin           => l_sch_start_date,
                                                    i_dt_end             => l_sch_end_date,
                                                    i_flg_vacancy        => i_flg_vacancy,
                                                    i_schedule_notes     => i_schedule_notes,
                                                    i_id_lang_translator => i_id_lang_translator,
                                                    i_id_lang_preferred  => i_id_lang_preferred,
                                                    i_id_reason          => i_id_reason,
                                                    i_id_origin          => i_id_origin,
                                                    i_id_room            => i_id_room,
                                                    i_ids_exams          => i_ids_exams,
                                                    i_id_episode         => i_id_episode,
                                                    i_reason_notes       => i_reason_notes,
                                                    i_flg_request_type   => i_flg_request_type,
                                                    i_flg_schedule_via   => i_flg_schedule_via,
                                                    i_do_overlap         => i_do_overlap,
                                                    i_id_consult_vac     => i_id_consult_vac,
                                                    i_sch_option         => i_sch_option,
                                                    o_id_schedule        => o_new_id_sched,
                                                    o_id_schedule_exam   => l_id_schedule_exam,
                                                    o_flg_proceed        => l_flg_proceed,
                                                    o_flg_show           => l_flg_show,
                                                    o_msg                => l_msg,
                                                    o_msg_title          => l_msg_title,
                                                    o_button             => l_button,
                                                    o_error              => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN g_data_gov_e THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END create_schedule_exam;

    /*
    * Checks if a duplicated schedule already exists.
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
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CHECK_APPOINTMENT_RADLAB';
        l_id_schedule schedule.id_schedule%TYPE := NULL;
    BEGIN
        BEGIN
            g_error := 'SELECT ID SCHEDULE';
            SELECT id_schedule
              INTO l_id_schedule
              FROM (SELECT vse.id_schedule id_schedule
                      FROM v_schedule_exam vse, sch_resource sr, sch_group sg, sch_event se
                     WHERE vse.id_instit_requested = i_id_instit_requested
                       AND vse.id_dcs_requested = i_id_dep_clin_serv
                       AND vse.id_schedule = sr.id_schedule(+)
                       AND vse.id_schedule = sg.id_schedule
                       AND vse.id_sch_event = se.id_sch_event
                       AND nvl(sr.id_professional, pk_schedule.g_unknown_id) =
                           nvl(i_id_prof_scheduled, pk_schedule.g_unknown_id)
                       AND sg.id_patient = i_id_patient
                       AND vse.dt_begin_tstz = i_sch_dt_begin
                       AND vse.id_sch_event = i_id_sch_event
                       AND ((sr.id_professional IS NULL AND se.flg_target_professional = g_no) OR
                           (sr.id_professional IS NOT NULL AND se.flg_target_professional = g_yes))
                       AND (vse.flg_status <> g_sch_status_cancelled OR nvl(i_flg_ignore_cancel, g_no) = g_no)
                     ORDER BY decode(vse.flg_status, g_sch_status_scheduled, 2, g_sch_status_cancelled, 1, 0) ASC)
             WHERE rownum = 1;
            o_exists := TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                o_exists := FALSE;
        END;
    
        o_id_sched := l_id_schedule;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_id_sched := NULL;
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_appointment_radlab;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE_EXAM';
    
        l_flg_show   VARCHAR2(4000);
        l_msg_req    VARCHAR2(4000);
        l_msg_result VARCHAR2(4000);
        l_msg_title  VARCHAR2(4000);
        l_button     VARCHAR2(4000);
    
        -- Cursor for getting the schedule that is going to be cancelled.
        CURSOR c_sched IS
            SELECT vse.*
              FROM v_schedule_exam vse
             WHERE vse.id_schedule = i_id_schedule;
    
        l_sched_rec c_sched%ROWTYPE;
    BEGIN
        -- Get schedule to cancel.
        g_error := 'OPEN c_sched';
        OPEN c_sched;
        g_error := 'FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
    
        IF c_sched%NOTFOUND
        THEN
            -- Invalid schedule identifier
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'No data found',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        ELSE
            -- Schedule found.
            IF l_sched_rec.flg_status = pk_schedule.g_sched_status_cancelled
            THEN
                -- Duplicate cancellation found. Issue a warning.
                o_warning := 'Duplicate cancellation found. [ id_schedule: ' || i_id_schedule || ' ]';
            
            ELSE
                -- Cancel the existing schedule                 
                g_error := 'CALL CANCEL_SCHEDULE';
                IF NOT pk_schedule_exam.cancel_only_schedule(i_lang             => NULL,
                                                             i_prof             => i_prof,
                                                             i_id_schedule      => i_id_schedule,
                                                             i_id_cancel_reason => i_id_sch_cancel_reason,
                                                             i_cancel_notes     => i_cancel_notes,
                                                             o_flg_show         => l_flg_show,
                                                             o_msg_req          => l_msg_req,
                                                             o_msg_result       => l_msg_result,
                                                             o_msg_title        => l_msg_title,
                                                             o_button           => l_button,
                                                             o_error            => o_error)
                
                THEN
                    pk_alert_exceptions.process_error(i_lang     => NULL,
                                                      i_sqlcode  => SQLCODE,
                                                      i_sqlerrm  => 'Error cancelling the schedule. [ id_schedule: ' ||
                                                                    l_sched_rec.id_schedule || ' ]',
                                                      i_message  => g_error,
                                                      i_owner    => g_package_owner,
                                                      i_package  => g_package_name,
                                                      i_function => l_func_name,
                                                      o_error    => o_error);
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END cancel_schedule_exam;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_interface;
/
