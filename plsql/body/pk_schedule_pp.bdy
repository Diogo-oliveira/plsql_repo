/*-- Last Change Revision: $Rev: 2027690 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_pp IS

    /**
    * Returns the message to be shown when a disposition is changed and an appointment already exists.
    * Private function
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/11/15
    */
    FUNCTION get_disp_change_msg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_msg         OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DISP_CHANGE_MSG';
    
        l_tokens       table_varchar;
        l_replacements table_varchar;
        l_message      sys_message.desc_message%TYPE;
    
        l_patient     patient.name%TYPE;
        l_dt_existing schedule.dt_begin_tstz%TYPE;
        l_dep         department.id_department%TYPE;
        l_dcs         dep_clin_serv.id_dep_clin_serv%TYPE;
        l_event       schedule.id_sch_event%TYPE;
        l_prof        professional.id_professional%TYPE;
    
    BEGIN
        g_error := 'GET SCHEDULE DETAILS';
        SELECT p.name, s.dt_begin_tstz, dcs.id_department, dcs.id_dep_clin_serv, s.id_sch_event, pr.id_professional
          INTO l_patient, l_dt_existing, l_dep, l_dcs, l_event, l_prof
          FROM schedule s, sch_resource sr, sch_group sg, patient p, professional pr, dep_clin_serv dcs
         WHERE s.id_schedule = sr.id_schedule
           AND sr.id_schedule(+) = sg.id_schedule
           AND s.id_schedule = i_id_schedule
           AND p.id_patient = sg.id_patient
           AND pr.id_professional(+) = sr.id_professional
           AND dcs.id_dep_clin_serv = s.id_dcs_requested;
    
        -- Replace special chars
        l_tokens       := table_varchar('@1', '@2', '@3', '@4', '@5', '@6');
        l_replacements := table_varchar(l_patient,
                                        pk_schedule.string_date_hm(i_lang, i_prof, l_dt_existing),
                                        pk_schedule.string_department(i_lang, l_dep),
                                        pk_schedule.string_clin_serv_by_dcs(i_lang, l_dcs),
                                        pk_schedule.string_sch_event(i_lang, l_event),
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof));
        -- Get message to translate
        l_message := pk_schedule.get_message(i_lang => i_lang, i_message => g_disp_warn_msg);
        -- Replace tokens
        IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                          i_string       => l_message,
                                          i_tokens       => l_tokens,
                                          i_replacements => l_replacements,
                                          o_string       => o_msg,
                                          o_error        => o_error)
        THEN
            RETURN FALSE;
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
            RETURN FALSE;
        
    END get_disp_change_msg;

    /**
    * Gets the list of events.
    *
    * @param  i_lang                    Language identifier
    * @param  i_prof                    Professionalt
    * @param  i_id_consult_req          Consult request
    * @param  i_id_schedule             Appointment identifier
    * @param  i_flg_view                Indicates whether or not the screen is on view mode
    * @param  o_events                  Events
    * @param  o_error                   Error message
    *
    * @return True if successful, false otherwise.
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/10/16
    * 
    * UPDATED
    * eliminacao da coluna sch_event.flg_consult nas queries
    * @author  Telmo Castro
    * @date    18-04-2008
    * @version 2.4.3
    * 
    * UPDATED
    * novo tipo de permissao na sch_permission - prof1-prof2-dcs-evento
    * @author  Telmo Castro
    * @date    16-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * DBImprovements - retirar sch_event_soft 
    * @author  Telmo Castro 
    * @date     14-10-2008
    * @version  2.4.3.x
    */
    FUNCTION get_visit_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_view       IN VARCHAR2,
        o_events         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'GET_VISIT_EVENTS';
        l_default_event sch_event.id_sch_event%TYPE := NULL;
        l_events        table_number := table_number();
        l_dep_type      sch_event.dep_type%TYPE := pk_schedule_common.g_sch_dept_flg_dep_type_cons;
    BEGIN
        g_error := 'GET APPOINTMENT''S EVENT';
        -- Get the default event
        IF i_id_schedule IS NOT NULL
        THEN
            SELECT s.id_sch_event
              INTO l_default_event
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        END IF;
    
        g_error := 'GET EVENTS';
        IF i_flg_view IS NULL
           OR i_flg_view = pk_schedule.g_no
        THEN
            IF i_id_consult_req IS NOT NULL
            THEN
                SELECT decode(e.id_epis_type,
                              g_nurse_type_care,
                              pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                              g_nurse_type_outp,
                              pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                              g_nurse_type_pp,
                              pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                              pk_schedule_common.g_sch_dept_flg_dep_type_cons)
                  INTO l_dep_type
                  FROM consult_req cr, episode e
                 WHERE cr.id_consult_req = i_id_consult_req
                   AND cr.id_episode = e.id_episode;
            ELSE
                l_dep_type := pk_schedule_common.g_sch_dept_flg_dep_type_cons;
            END IF;
        
            -- Get events, keeping them in such an order that the first one will be selected, if no default is set
            SELECT se.id_sch_event
              BULK COLLECT
              INTO l_events
              FROM sch_event se
             WHERE se.flg_available = pk_schedule.g_yes
               AND se.dep_type = l_dep_type
                  -- The user has permission to schedule an appointment
               AND EXISTS (SELECT 0
                      FROM sch_permission sp
                     WHERE sp.id_institution = i_prof.institution
                       AND sp.id_professional = i_prof.id
                       AND sp.id_sch_event = se.id_sch_event
                       AND sp.flg_permission = pk_schedule.g_permission_schedule)
               AND NOT EXISTS
             (SELECT 0
                      FROM sch_event_inst sei
                     WHERE sei.id_sch_event_ref = se.id_sch_event
                       AND sei.id_institution IN (i_prof.institution, 0)
                       AND sei.active = pk_schedule.g_yes)
               AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_prof.institution, i_prof.software) =
                   pk_alert_constant.g_yes
            -- If no request is being used, order events by rank. Otherwise, keep the follow-up appointments first.
             ORDER BY decode(i_id_consult_req,
                             NULL,
                             1,
                             decode(se.flg_occurrence, pk_schedule.g_event_occurrence_subs, 1, 2)),
                      se.rank;
        ELSIF i_id_schedule IS NOT NULL
        THEN
            l_events.extend;
            l_events(1) := l_default_event;
        END IF;
    
        IF l_events IS NOT NULL
           AND l_events.count > 0
        THEN
            -- Some events were found. Use the first as the default, if no default is set yet.
            IF l_default_event IS NULL
            THEN
                l_default_event := l_events(1);
            END IF;
        
            -- Get event details
            g_error := 'OPEN o_events';
            -- Get events
            OPEN o_events FOR
                SELECT /*+ first_rows */
                 se.id_sch_event,
                 pk_translation.get_translation(i_lang, se.code_sch_event_abrv) desc_event,
                 decode(l_default_event, se.id_sch_event, pk_schedule.g_yes, pk_schedule.g_no) flg_select,
                 se.flg_target_professional
                  FROM sch_event se
                 WHERE se.id_sch_event IN (SELECT *
                                             FROM TABLE(CAST(l_events AS table_number)))
                   AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_prof.institution, i_prof.software) =
                       pk_alert_constant.g_yes
                 ORDER BY se.rank;
        ELSE
            pk_types.open_my_cursor(o_events);
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
            pk_types.open_my_cursor(o_events);
            RETURN FALSE;
        
    END get_visit_events;

    /**
    * Returns the visit types.
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment identifier
    * @param      i_flg_view         Indicates whether or not the screen is on view mode   
    * @param      o_types            Visit types
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/16
    */
    FUNCTION get_visit_types
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_view       IN VARCHAR2,
        o_types          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_VISIT_TYPES';
        l_types        table_number := table_number();
        l_default_type schedule.id_dcs_requested%TYPE := NULL;
    BEGIN
        g_error := 'GET APPOINTMENT''S VISIT TYPE';
        -- Get the default visit type
        IF i_id_schedule IS NOT NULL
        THEN
            -- .. using the appointment
            SELECT s.id_dcs_requested
              INTO l_default_type
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        ELSIF i_id_consult_req IS NOT NULL
        THEN
            -- .. using the consult request
            SELECT cr.id_dep_clin_serv
              INTO l_default_type
              FROM consult_req cr
             WHERE cr.id_consult_req = i_id_consult_req;
        END IF;
    
        g_error := 'CHECK VIEW MODE';
        IF i_flg_view IS NOT NULL
           AND i_flg_view = pk_schedule.g_yes
        THEN
            -- If view mode is enabled, then we return a single result
            l_types.extend;
            l_types(1) := l_default_type;
        ELSE
            g_error := 'GET TYPES';
            -- Get all the types that the user has access to
            SELECT pdcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_types
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.flg_status = pk_schedule.g_status_pdcs_selected
               AND pdcs.id_professional = i_prof.id
               AND pdcs.id_institution = i_prof.institution;
        END IF;
    
        g_error := 'CHECK TYPES';
        IF l_types IS NOT NULL
           AND l_types.count > 0
        THEN
            -- Some types were found. Use the first as the default, if no default is set yet.
            IF l_default_type IS NULL
            THEN
                l_default_type := l_types(1);
            END IF;
        
            g_error := 'OPEN o_types';
            -- Get visit types
            OPEN o_types FOR
                SELECT /*+ first_rows */
                 id_dep_clin_serv,
                 desc_dep_clin_serv,
                 decode(l_default_type, id_dep_clin_serv, pk_schedule.g_yes, pk_schedule.g_no) flg_select
                  FROM (SELECT column_value id_dep_clin_serv,
                               pk_schedule.string_clin_serv_by_dcs(i_lang, column_value) desc_dep_clin_serv,
                               rank
                          FROM TABLE(CAST(l_types AS table_number)) coll, dep_clin_serv dcs
                         WHERE dcs.id_dep_clin_serv = coll.column_value)
                 ORDER BY rank, desc_dep_clin_serv, id_dep_clin_serv;
        ELSE
            pk_types.open_my_cursor(o_types);
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
            pk_types.open_my_cursor(o_types);
            RETURN FALSE;
        
    END get_visit_types;

    /**
    * Returns the instructions for the next follow-up visit.
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment identifier
    * @param      i_flg_view         Indicates whether or not the screen is on view mode   
    * @param      o_instructions     Instructions
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/23
    */
    FUNCTION get_visit_instructions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_view       IN VARCHAR2,
        o_instructions   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := 'GET_VISIT_INSTRUCTIONS';
        l_instructions         table_varchar := table_varchar();
        l_default_instructions sys_domain.val%TYPE := NULL;
    BEGIN
        g_error := 'GET APPOINTMENT''S INSTRUCTIONS';
        -- Get instructions
        IF i_id_schedule IS NOT NULL
        THEN
            -- .. using the appointment
            SELECT s.flg_instructions
              INTO l_default_instructions
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        ELSIF i_id_consult_req IS NOT NULL
        THEN
            -- .. using the consult request
            SELECT cr.flg_instructions
              INTO l_default_instructions
              FROM consult_req cr
             WHERE cr.id_consult_req = i_id_consult_req;
        END IF;
    
        g_error := 'CHECK VIEW MODE';
        IF i_flg_view IS NOT NULL
           AND i_flg_view = pk_schedule.g_yes
        THEN
            -- If view mode is enabled, then we return a single result
            l_instructions.extend;
            l_instructions(1) := l_default_instructions;
        ELSE
            g_error := 'GET INSTRUCTIONS';
            -- Get all the types that the user has access to
            SELECT sd.val
              BULK COLLECT
              INTO l_instructions
              FROM sys_domain sd
             WHERE sd.id_language = i_lang
               AND sd.code_domain = g_flg_instructions_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = pk_schedule.g_yes;
        END IF;
    
        g_error := 'CHECK INSTRUCTIONS';
        IF l_instructions IS NOT NULL
           AND l_instructions.count > 0
        THEN
            -- Some instructions were found. Use the first as the default, if no default is set yet.
            IF l_default_instructions IS NULL
            THEN
                l_default_instructions := l_instructions(1);
            END IF;
        
            g_error := 'OPEN o_instructions';
            -- Get instructions
            OPEN o_instructions FOR
                SELECT sd.val VALUE,
                       sd.desc_val desc_value,
                       decode(l_default_instructions, sd.val, pk_schedule.g_yes, pk_schedule.g_no) flg_select
                  FROM sys_domain sd
                 WHERE sd.id_language = i_lang
                   AND sd.code_domain = g_flg_instructions_domain
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.flg_available = pk_schedule.g_yes
                 ORDER BY sd.desc_val;
        ELSE
            pk_types.open_my_cursor(o_instructions);
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
            pk_types.open_my_cursor(o_instructions);
            RETURN FALSE;
        
    END get_visit_instructions;

    /**
    * Returns the reasons for visit.
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment
    * @param      i_id_dep_clin_serv Type of visit
    * @param      i_id_sch_event     Event type
    * @param      i_flg_view         Indicates whether or not the screen is on view mode   
    * @param      o_reasons          Reasons for visit
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/16
    */
    FUNCTION get_visit_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_consult_req   IN consult_req.id_consult_req%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_flg_view         IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_VISIT_REASONS';
        l_reasons        table_number := table_number();
        l_default_reason schedule.id_reason%TYPE := NULL;
    BEGIN
        g_error := 'GET APPOINTMENT''S REASON FOR VISIT';
        -- Get the default reason
        IF i_id_schedule IS NOT NULL
        THEN
            -- .. using the appointment
            SELECT s.id_reason
              INTO l_default_reason
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        ELSIF i_id_consult_req IS NOT NULL
        THEN
            -- .. using the consult request
            SELECT cr.id_complaint
              INTO l_default_reason
              FROM consult_req cr
             WHERE cr.id_consult_req = i_id_consult_req;
        END IF;
    
        g_error := 'CHECK VIEW MODE';
        IF i_flg_view IS NOT NULL
           AND i_flg_view = pk_schedule.g_yes
        THEN
            -- If view mode is enabled, then we return a single result
            l_reasons.extend;
            l_reasons(1) := l_default_reason;
        ELSE
            g_error := 'GET REASONS';
            -- Get reasons
            SELECT DISTINCT c.id_complaint
              BULK COLLECT
              INTO l_reasons
              FROM doc_template_context dtc, complaint c
             WHERE dtc.id_institution IN (0, i_prof.institution)
               AND dtc.id_software IN (0, i_prof.software)
               AND dtc.id_dep_clin_serv = i_id_dep_clin_serv
               AND dtc.id_sch_event IN (0, i_id_sch_event)
               AND dtc.flg_type = pk_complaint.g_flg_type_ct
               AND dtc.id_context = c.id_complaint;
        END IF;
    
        g_error := 'CHECK REASONS';
        IF l_reasons IS NOT NULL
           AND l_reasons.count > 0
        THEN
            g_error := 'OPEN o_reasons';
            -- Get visit reasons
            OPEN o_reasons FOR
                SELECT /*+ first_rows */
                 id_reason,
                 desc_reason,
                 decode(l_default_reason, id_reason, pk_schedule.g_yes, pk_schedule.g_no) flg_select
                  FROM (SELECT c.id_complaint id_reason,
                               pk_translation.get_translation(i_lang, c.code_complaint) desc_reason
                          FROM complaint c
                         WHERE c.id_complaint IN (SELECT *
                                                    FROM TABLE(CAST(l_reasons AS table_number))))
                 ORDER BY desc_reason, id_reason;
        ELSE
            pk_types.open_my_cursor(o_reasons);
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
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
        
    END get_visit_reasons;

    /**
    * Returns the list of professionals for scheduling a visit. 
    *
    * @param      i_lang             Language identifier
    * @param      i_prof             Professional
    * @param      i_id_consult_req   Consult request
    * @param      i_id_schedule      Appointment
    * @param      i_id_dep_clin_serv Type of visit
    * @param      i_id_sch_event     Event type
    * @param      i_flg_view         Indicates whether or not the screen is on view mode   
    * @param      o_prof             List of professionals
    * @param      o_error            Error message if an error occurred
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/10/17
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
    */
    FUNCTION get_visit_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_consult_req   IN consult_req.id_consult_req%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_flg_view         IN VARCHAR2,
        o_profs            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_VISIT_PROF';
        l_default_prof professional.id_professional%TYPE;
        l_profs        table_number := table_number();
        l_target_prof  sch_event.flg_target_professional%TYPE := NULL;
    BEGIN
        g_error := 'CHECK EVENT''S TARGET';
        IF i_id_sch_event IS NOT NULL
        THEN
            -- Check if the event targets a professional
            SELECT se.flg_target_professional
              INTO l_target_prof
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event;
        END IF;
    
        g_error := 'TEST TARGET';
        IF (l_target_prof IS NOT NULL AND l_target_prof = pk_schedule.g_yes)
           OR i_id_sch_event IS NULL
        THEN
            g_error := 'GET APPOINTMENT''S PROFESSIONAL';
            -- Get the default professional
            IF i_id_schedule IS NOT NULL
            THEN
                -- .. using the appointment
                SELECT sr.id_professional
                  INTO l_default_prof
                  FROM schedule s, sch_resource sr
                 WHERE s.id_schedule = i_id_schedule
                   AND s.id_schedule = sr.id_schedule;
            ELSIF i_id_consult_req IS NOT NULL
            THEN
                -- .. using the consult request
                SELECT cr.id_prof_requested
                  INTO l_default_prof
                  FROM consult_req cr
                 WHERE cr.id_consult_req = i_id_consult_req;
            END IF;
        
            g_error := 'CHECK VIEW MODE';
            IF i_flg_view IS NOT NULL
               AND i_flg_view = pk_schedule.g_yes
            THEN
                -- If view mode is enabled, then we return a single result
                l_profs.extend;
                l_profs(1) := l_default_prof;
            ELSE
                g_error := 'GET PROFESSIONALS';
                -- Get professionals
                SELECT pdcs.id_professional
                  BULK COLLECT
                  INTO l_profs
                  FROM sch_permission sp, prof_dep_clin_serv pdcs
                 WHERE sp.id_professional = i_prof.id
                   AND sp.id_sch_event = i_id_sch_event
                   AND sp.id_prof_agenda = pdcs.id_professional
                   AND pdcs.id_dep_clin_serv = i_id_dep_clin_serv
                   AND pdcs.id_dep_clin_serv = sp.id_dep_clin_serv -- Telmo 16-05-2008
                   AND pdcs.flg_status = pk_schedule.g_status_pdcs_selected
                   AND sp.flg_permission <> pk_schedule.g_permission_none;
            END IF;
        
            g_error := 'CHECK REASONS';
            IF l_profs IS NOT NULL
               AND l_profs.count > 0
            THEN
                g_error := 'OPEN o_profs';
                -- Get professionals
                OPEN o_profs FOR
                    SELECT /*+ first_rows */
                     id_professional,
                     prof_name,
                     decode(l_default_prof, id_professional, pk_schedule.g_yes, pk_schedule.g_no) flg_select
                      FROM (SELECT p.id_professional, p.name prof_name
                              FROM professional p
                             WHERE p.id_professional IN
                                   (SELECT *
                                      FROM TABLE(CAST(l_profs AS table_number))))
                     ORDER BY prof_name, id_professional;
            ELSE
                g_error := 'CALL OPEN_MY_CURSOR';
                -- Open an empty cursor
                pk_types.open_my_cursor(o_profs);
            END IF;
        
        ELSE
            g_error := 'CALL OPEN_MY_CURSOR';
            -- Open an empty cursor
            pk_types.open_my_cursor(o_profs);
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
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        
    END get_visit_prof;

    --------------------------------------------- PUBLIC FUNCTIONS ---------------------------------------------------------

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
    * REVISED
    * new kind of scenario in sch_permission - prof1-prof2-dcs-evento.
    * @author  Telmo Castro
    * @date    16-05-2008
    * @version 2.4.3
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
    ) RETURN BOOLEAN IS
        l_func_name               VARCHAR2(32) := 'GET_VISIT_SCHED';
        g_category                category.flg_type%TYPE;
        l_epis_type_nurse         epis_type.id_epis_type%TYPE;
        l_epis_type_nutri         epis_type.id_epis_type%TYPE;
        l_therap_decision_consult translation.code_translation%TYPE;
    BEGIN
    
        g_category        := pk_prof_utils.get_category(i_lang, i_prof);
        l_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
        l_epis_type_nutri := pk_sysconfig.get_config('ID_EPIS_TYPE_NUTRITIONIST', i_prof);
    
        -- Consultas de decisao terapeutica 
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_therap_decision_consult
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        g_error := 'OPEN o_visit_sched';
        -- Get requests and appointments 
        OPEN o_visit_sched FOR
            SELECT id_consult_req,
                   id_schedule,
                   desc_dep_clin_serv,
                   id_dep_clin_serv,
                   id_professional,
                   professional_name,
                   nick_name,
                   dt_request,
                   dt_request_desc,
                   --next_visit_in,
                   dt_scheduled,
                   dt_scheduled_desc,
                   flg_status,
                   desc_status,
                   pk_patphoto.get_pat_foto(id_pat, i_prof) photo,
                   id_pat id_patient,
                   (SELECT p.name
                      FROM patient p
                     WHERE p.id_patient = id_pat
                       AND rownum = 1) patient_name,
                   pk_patient.get_pat_age(i_lang, id_pat, i_prof) pat_age,
                   (SELECT pk_patient.get_gender(i_lang, p.gender)
                      FROM patient p
                     WHERE p.id_patient = id_pat
                       AND rownum = 1) gender,
                   decode(reason_visit,
                          NULL,
                          reason_for_visit,
                          (SELECT pk_translation.get_translation(i_lang, c.code_complaint)
                             FROM complaint c
                            WHERE c.id_complaint = reason_visit
                              AND rownum = 1)) desc_reason,
                   id_prof_orig id_prof_orig,
                   desc_prof_orig desc_prof_orig,
                   id_prof_dest id_prof_dest,
                   desc_prof_dest desc_prof_dest,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   dt_proposed,
                   dt_proposed_desc,
                   status_desc status_desc,
                   epis_id_dep_clin_serv,
                   flg_epis_type,
                   consult_decision,
                   decode(flg_status, g_visit_sched_stat_cancelled, g_no, g_visit_sched_stat_scheduled, g_no, g_yes) avail_butt_ok,
                   decode(flg_status, g_visit_sched_stat_cancelled, g_no, g_visit_sched_stat_scheduled, g_no, g_yes) avail_butt_cancel
              FROM (SELECT /*+ index(cr CR_INST_REQ_FLG_ST) */
                     cr.id_consult_req,
                     NULL id_schedule,
                     pk_schedule.string_clin_serv_by_dcs(i_lang, cr.id_dep_clin_serv) desc_dep_clin_serv,
                     cr.id_dep_clin_serv,
                     p.id_professional id_professional,
                     p.name professional_name,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                     pk_date_utils.date_send_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_request,
                     pk_date_utils.date_char_hour_tsz(i_lang,
                                                      cr.dt_consult_req_tstz,
                                                      i_prof.institution,
                                                      i_prof.software) || chr(10) ||
                     pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_request_desc,
                     NULL dt_scheduled,
                     NULL dt_scheduled_desc,
                     decode(cr.flg_status,
                            pk_consult_req.g_consult_req_stat_reply,
                            g_visit_sched_stat_requested,
                            pk_consult_req.g_consult_req_stat_cancel,
                            g_visit_sched_stat_cancelled) flg_status,
                     pk_schedule.get_domain_desc(i_lang,
                                                 g_flg_status_domain,
                                                 decode(cr.flg_status,
                                                        pk_consult_req.g_consult_req_stat_reply,
                                                        g_visit_sched_stat_requested,
                                                        pk_consult_req.g_consult_req_stat_cancel,
                                                        g_visit_sched_stat_cancelled)) desc_status,
                     cr.id_patient id_pat,
                     cr.id_complaint reason_visit,
                     cr.id_prof_req id_prof_orig,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) desc_prof_orig,
                     CASE
                          WHEN id_prof_requested IS NULL THEN
                           (SELECT p2.id_professional
                              FROM professional p2, consult_req_prof crp
                             WHERE crp.id_professional = p2.id_professional
                               AND crp.id_consult_req = cr.id_consult_req
                               AND rownum = 1)
                          ELSE
                           cr.id_prof_requested
                      END id_prof_dest,
                     CASE
                          WHEN id_prof_requested IS NULL THEN
                           (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p2.id_professional)
                              FROM professional p2, consult_req_prof crp
                             WHERE crp.id_professional = p2.id_professional
                               AND crp.id_consult_req = cr.id_consult_req
                               AND rownum = 1)
                          ELSE
                           pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested)
                      END desc_prof_dest,
                     pk_date_utils.date_send_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) dt_proposed,
                     decode(cr.dt_scheduled_tstz,
                            NULL,
                            cr.next_visit_in_notes,
                            pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof)) ||
                     decode(cr.notes_admin, NULL, '', chr(10) || pk_message.get_message(i_lang, 'COMMON_M008')) dt_proposed_desc,
                     -- pk_logic_consult_req.get_consult_req_status_string(i_lang,
                     --                                                    i_prof,
                     --                                                    cr.flg_status,
                     --                                                    cr.dt_consult_req_tstz) status_desc,
                     -- 0|20080422091600|DI|X|ScheduledNewIcon status_desc,
                     pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                cr.status_str,
                                                cr.status_msg,
                                                cr.status_icon,
                                                cr.status_flg) status_desc,
                     ei.id_dep_clin_serv epis_id_dep_clin_serv,
                     decode(pk_episode.get_epis_type(i_lang, ei.id_episode),
                            l_epis_type_nurse,
                            g_epis_type_nurse,
                            l_epis_type_nutri,
                            g_epis_type_nutri,
                            decode((SELECT COUNT(1)
                                     FROM adm_request ar
                                    WHERE ar.id_nit_req = cr.id_consult_req),
                                   1,
                                   g_epis_type_nurse,
                                   decode(pk_prof_utils.get_category(i_lang,
                                                                     profissional(cr.id_prof_requested,
                                                                                  i_prof.institution,
                                                                                  i_prof.software)),
                                          g_epis_type_nutri,
                                          g_epis_type_nutri,
                                          g_epis_type_consult))) flg_epis_type,
                     cr.reason_for_visit,
                     (SELECT decode(s.id_sch_event, g_sch_event_therap_decision, l_therap_decision_consult, NULL)
                        FROM schedule s
                       WHERE s.id_schedule = ei.id_schedule) consult_decision
                      FROM consult_req cr, professional p, epis_info ei
                     WHERE (cr.id_schedule IS NULL OR EXISTS
                            (SELECT 0
                               FROM schedule s
                              WHERE s.id_schedule = cr.id_schedule
                                AND s.flg_status = pk_schedule.g_sch_canceled))
                       AND (cr.id_patient = i_id_patient OR i_id_patient IS NULL)
                       AND cr.id_episode = ei.id_episode
                       AND (cr.id_dep_clin_serv IS NULL OR EXISTS
                            (SELECT 0
                               FROM prof_dep_clin_serv pdcs
                              WHERE pdcs.id_dep_clin_serv = cr.id_dep_clin_serv
                                AND pdcs.id_professional = i_prof.id
                                AND pdcs.flg_status = pk_schedule.g_status_pdcs_selected))
                       AND cr.id_prof_requested = p.id_professional(+)
                       AND cr.id_inst_requested = i_prof.institution
                       AND cr.flg_status IN
                           (pk_consult_req.g_consult_req_stat_reply, pk_consult_req.g_consult_req_stat_cancel)
                       AND (g_category = g_flg_type_a OR EXISTS
                            (SELECT 0
                               FROM sch_permission sp
                              WHERE sp.id_institution = i_prof.institution
                                AND sp.id_dep_clin_serv = cr.id_dep_clin_serv
                                AND sp.id_professional = i_prof.id
                                AND (sp.id_prof_agenda = cr.id_prof_requested OR cr.id_prof_requested IS NULL)
                                AND (sp.flg_permission = pk_schedule.g_permission_schedule)))
                       AND ((cr.flg_status != pk_consult_req.g_consult_req_stat_cancel) OR
                           (cr.flg_status = pk_consult_req.g_consult_req_stat_cancel AND
                           trunc(cr.dt_cancel_tstz, 'DD') >= trunc(current_timestamp, 'DD')))
                    
                    UNION ALL
                    SELECT cr.id_consult_req,
                           s.id_schedule,
                           pk_schedule.string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) desc_dep_clin_serv,
                           s.id_dcs_requested id_dep_clin_serv,
                           p.id_professional id_professional,
                           p.name professional_name,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_request,
                           pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_request_desc,
                           pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_scheduled,
                           pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) ||
                           chr(10) || pk_date_utils.dt_chr_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_scheduled_desc,
                           g_visit_sched_stat_scheduled flg_status,
                           pk_schedule.get_domain_desc(i_lang, g_flg_status_domain, g_visit_sched_stat_scheduled) desc_status,
                           sg.id_patient id_pat,
                           s.id_reason reason_visit,
                           cr.id_prof_req id_prof_orig,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) desc_prof_orig,
                           ei.sch_prof_outp_id_prof id_prof_dest,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, ei.sch_prof_outp_id_prof) desc_prof_dest,
                           pk_date_utils.date_send_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) dt_proposed,
                           decode(cr.dt_scheduled_tstz,
                                  NULL,
                                  cr.next_visit_in_notes,
                                  pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof)) ||
                           decode(cr.notes_admin, NULL, '', chr(10) || pk_message.get_message(i_lang, 'COMMON_M008')) dt_proposed_desc,
                           -- pk_logic_consult_req.get_consult_req_status_string(i_lang,
                           --                                                    i_prof,
                           --                                                    cr.flg_status,
                           --                                                    cr.dt_consult_req_tstz) status_desc,
                           -- '0||I|0x829664|ScheduledCheckIcon' status_desc,
                           pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      cr.status_str,
                                                      cr.status_msg,
                                                      cr.status_icon,
                                                      cr.status_flg) status_desc,
                           ei.id_dep_clin_serv epis_id_dep_clin_serv,
                           decode(so.id_epis_type,
                                  l_epis_type_nurse,
                                  g_epis_type_nurse,
                                  l_epis_type_nutri,
                                  g_epis_type_nutri,
                                  decode((SELECT COUNT(1)
                                           FROM adm_request ar
                                          WHERE ar.id_nit_req = cr.id_consult_req),
                                         1,
                                         g_epis_type_nurse,
                                         g_epis_type_consult)) flg_epis_type,
                           cr.reason_for_visit,
                           decode(s.id_sch_event, g_sch_event_therap_decision, l_therap_decision_consult, NULL) consult_decision
                      FROM schedule      s,
                           sch_group     sg,
                           sch_resource  sr,
                           professional  p,
                           consult_req   cr,
                           schedule_outp so,
                           epis_info     ei
                     WHERE s.id_schedule = sr.id_schedule(+)
                       AND s.id_schedule = sg.id_schedule
                       AND (sg.id_patient = i_id_patient OR i_id_patient IS NULL)
                       AND s.id_instit_requested = i_prof.institution
                       AND ei.id_episode = cr.id_episode
                       AND s.id_dcs_requested IN
                           (SELECT pdcs.id_dep_clin_serv
                              FROM prof_dep_clin_serv pdcs
                             WHERE pdcs.id_dep_clin_serv = s.id_dcs_requested
                               AND pdcs.id_professional = i_prof.id
                               AND pdcs.flg_status = pk_schedule.g_status_pdcs_selected)
                       AND sr.id_professional = p.id_professional(+)
                       AND s.flg_status = pk_schedule.g_status_scheduled
                       AND s.dt_begin_tstz >= pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)
                       AND s.id_schedule = cr.id_schedule
                       AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
                       AND so.id_schedule = s.id_schedule
                       AND EXISTS (SELECT 0
                              FROM sch_permission sp
                             WHERE sp.id_institution = i_prof.institution
                               AND (sp.id_prof_agenda = sr.id_professional OR sr.id_professional IS NULL OR
                                   sp.id_professional IS NULL)
                               AND (sp.id_dep_clin_serv = s.id_dcs_requested OR sp.id_dep_clin_serv IS NULL)
                               AND (sp.flg_permission = pk_schedule.g_permission_schedule)
                               AND (sp.id_sch_event = s.id_sch_event))
                       AND trunc(s.dt_schedule_tstz, 'DD') >= trunc(current_timestamp, 'DD')
                       AND ((so.id_epis_type = pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof) AND
                           g_category = g_flg_type_n) OR g_category != g_flg_type_n))
             ORDER BY decode(flg_status,
                             g_visit_sched_stat_requested,
                             1,
                             g_visit_sched_stat_scheduled,
                             2,
                             g_visit_sched_stat_cancelled,
                             3),
                      dt_scheduled DESC,
                      dt_request DESC;
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
            pk_types.open_my_cursor(o_visit_sched);
            RETURN FALSE;
        
    END get_visit_sched;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VISIT_INIT_LOAD';
    
        -- Consult request
        CURSOR c_consult_req(i_id_consult_req consult_req.id_consult_req%TYPE) IS
            SELECT pk_date_utils.date_send_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) order_date,
                   decode(cr.dt_consult_req_tstz,
                          NULL,
                          pk_message.get_message(i_lang, g_not_available),
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           cr.dt_consult_req_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) || chr(10) ||
                          pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof)) desc_order_date,
                   cr.notes,
                   cr.notes_admin,
                   nvl(cr.next_visit_in_notes, pk_message.get_message(i_lang, g_not_available)) next_visit_in_notes,
                   pk_date_utils.date_send_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) begin_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_scheduled_tstz, i_prof.institution, i_prof.software) ||
                   chr(10) || pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) desc_begin_date
              FROM consult_req cr
             WHERE cr.id_consult_req = i_id_consult_req;
    
        -- Appointment
        CURSOR c_schedule(i_id_schedule schedule.id_schedule%TYPE) IS
            SELECT begin_date,
                   end_date,
                   duration_min,
                   desc_begin_date,
                   schedule_notes,
                   decode(duration_min,
                           NULL,
                           NULL,
                           duration_min || ' ' || CASE
                               WHEN duration_min = 1 THEN
                                pk_message.get_message(i_lang, pk_schedule.g_minute)
                               ELSE
                                pk_message.get_message(i_lang, pk_schedule.g_minutes)
                           END) duration
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) begin_date,
                           pk_date_utils.date_send_tsz(i_lang, s.dt_end_tstz, i_prof) end_date,
                           trunc(pk_date_utils.get_timestamp_diff(s.dt_end_tstz, s.dt_begin_tstz) * 1440) duration_min,
                           pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) ||
                           chr(10) || pk_date_utils.dt_chr_tsz(i_lang, s.dt_begin_tstz, i_prof) desc_begin_date,
                           s.schedule_notes
                      FROM schedule s
                     WHERE s.id_schedule = i_id_schedule);
    
        l_consult_req c_consult_req%ROWTYPE;
        l_schedule    c_schedule%ROWTYPE;
    
        -- Retrieve a consult request's data
        FUNCTION inner_get_consult_req(i_id_consult_req consult_req.id_consult_req%TYPE) RETURN c_consult_req%ROWTYPE IS
            l_record c_consult_req%ROWTYPE := NULL;
        BEGIN
            g_error := 'OPEN c_consult_req';
            OPEN c_consult_req(inner_get_consult_req.i_id_consult_req);
            g_error := 'FETCH c_consult_req';
            FETCH c_consult_req
                INTO l_record;
        
            g_error := 'TEST REQ RECORD';
            IF c_consult_req%NOTFOUND
            THEN
                -- Invalid or null consult request
                l_record.notes               := NULL;
                l_record.notes_admin         := NULL;
                l_record.next_visit_in_notes := pk_message.get_message(i_lang, g_not_available);
                l_record.desc_order_date     := l_record.next_visit_in_notes;
                l_record.order_date          := NULL;
            END IF;
        
            g_error := 'CLOSE c_consult_req';
            CLOSE c_consult_req;
        
            RETURN l_record;
        END inner_get_consult_req;
    
        -- Retrieve an appointment's data
        FUNCTION inner_get_schedule(i_id_schedule schedule.id_schedule%TYPE) RETURN c_schedule%ROWTYPE IS
            l_record c_schedule%ROWTYPE := NULL;
        BEGIN
            g_error := 'OPEN c_schedule';
            OPEN c_schedule(inner_get_schedule.i_id_schedule);
            g_error := 'FETCH c_schedule';
            FETCH c_schedule
                INTO l_record;
            g_error := 'TEST SCH RECORD';
            IF c_schedule%NOTFOUND
            THEN
                -- Invalid or null consult request
                l_record.begin_date     := NULL;
                l_record.end_date       := NULL;
                l_record.duration       := NULL;
                l_record.schedule_notes := NULL;
            END IF;
        
            g_error := 'CLOSE c_schedule';
            CLOSE c_schedule;
        
            RETURN l_record;
        END inner_get_schedule;
    
        -- Returns true if the professional is an administrative clerk
        FUNCTION inner_is_admin(i_prof profissional) RETURN BOOLEAN IS
            l_dummy NUMBER;
        BEGIN
            SELECT 1
              INTO l_dummy
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND c.flg_type = pk_schedule.g_administrative_cat;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END inner_is_admin;
    BEGIN
        g_error := 'CALL GET_VISIT_EVENTS';
        -- Get event types
        IF NOT get_visit_events(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_id_consult_req => i_id_consult_req,
                                i_id_schedule    => i_id_schedule,
                                i_flg_view       => i_flg_view,
                                o_events         => o_events,
                                o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_VISIT_TYPES';
        -- Get visit types
        IF NOT get_visit_types(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_id_consult_req => i_id_consult_req,
                               i_id_schedule    => i_id_schedule,
                               i_flg_view       => i_flg_view,
                               o_types          => o_visit_types,
                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_VISIT_INSTRUCTIONS';
        -- Get visit types
        IF NOT get_visit_instructions(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_consult_req => i_id_consult_req,
                                      i_id_schedule    => i_id_schedule,
                                      i_flg_view       => i_flg_view,
                                      o_instructions   => o_instructions,
                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET CONSULT REQUEST';
        -- Get consult request
        l_consult_req := inner_get_consult_req(i_id_consult_req);
    
        g_error := 'GET APPOINTMENT';
        -- Get appointment
        l_schedule := inner_get_schedule(i_id_schedule);
    
        g_error := 'GET REQUEST''S DATA';
        -- Get request-specific data
        o_order_date      := l_consult_req.order_date;
        o_order_date_desc := l_consult_req.desc_order_date;
        o_next_visit_in   := l_consult_req.next_visit_in_notes;
    
        g_error := 'GET APPOINTMENT''S DATA';
        -- Get appointment-specific data
        o_begin_date      := l_schedule.begin_date;
        o_begin_date_desc := l_schedule.desc_begin_date;
    
        IF o_begin_date IS NULL
        THEN
            o_begin_date      := l_consult_req.begin_date;
            o_begin_date_desc := l_consult_req.desc_begin_date;
        END IF;
    
        o_end_date     := l_schedule.end_date;
        o_duration     := l_schedule.duration;
        o_duration_min := l_schedule.duration_min;
    
        g_error := 'GET NOTES';
        -- If the appointment has notes return them, otherwise use the request's notes.
        IF l_schedule.schedule_notes IS NULL
        THEN
            -- Show administrative notes if the professional is an administrative clerk
            g_error := 'CALL INNER_IS_ADMIN';
            IF inner_is_admin(i_prof)
            THEN
                o_notes := l_consult_req.notes_admin;
            ELSE
                o_notes := l_consult_req.notes;
            END IF;
        ELSE
            o_notes := l_schedule.schedule_notes;
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
            RETURN FALSE;
        
    END get_visit_init_load;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VISIT_SUBS_LOAD';
    BEGIN
        g_error := 'CALL GET_VISIT_REASONS';
        -- Get reasons for visit
        IF NOT get_visit_reasons(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_consult_req   => i_id_consult_req,
                                 i_id_schedule      => i_id_schedule,
                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                 i_id_sch_event     => i_id_sch_event,
                                 i_flg_view         => i_flg_view,
                                 o_reasons          => o_reasons,
                                 o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_VISIT_PROF';
        -- Get professionals
        IF NOT get_visit_prof(i_lang             => i_lang,
                              i_prof             => i_prof,
                              i_id_consult_req   => i_id_consult_req,
                              i_id_schedule      => i_id_schedule,
                              i_id_dep_clin_serv => i_id_dep_clin_serv,
                              i_id_sch_event     => i_id_sch_event,
                              i_flg_view         => i_flg_view,
                              o_profs            => o_profs,
                              o_error            => o_error)
        THEN
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_reasons);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        
    END get_visit_subs_load;

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
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'SET_DISP_CONS_REQ';
        l_id_schedule     schedule.id_schedule%TYPE := NULL;
        l_id_consult_req  consult_req.id_consult_req%TYPE := NULL;
        l_consult_req_rec consult_req%ROWTYPE;
        l_exception_ext EXCEPTION;
    BEGIN
        g_error    := 'START';
        o_flg_show := pk_schedule.g_no;
    
        g_error := 'CHECK CONSULT_REQ';
        -- Try to get the consult request's and schedule's identifiers.
        BEGIN
            SELECT cr.id_consult_req, cr.id_schedule
              INTO l_id_consult_req, l_id_schedule
              FROM consult_req cr, schedule s
             WHERE cr.id_consult_req = i_id_consult_req
               AND s.id_schedule = cr.id_schedule
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_consult_req := i_id_consult_req;
        END;
    
        g_error := 'TEST SCHEDULE';
        IF l_id_schedule IS NOT NULL
        THEN
            -- If an appointment exists, the request cannot be changed.     
            o_flg_show       := pk_schedule.g_yes;
            o_button         := pk_schedule.g_check_button;
            o_id_consult_req := i_id_consult_req;
            o_msg_title      := g_disp_warn_msg_title;
        
            g_error := 'CALL GET_DISP_CHANGE_MSG';
            -- Get message
            IF NOT get_disp_change_msg(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_id_schedule => l_id_schedule,
                                       o_msg         => o_msg,
                                       o_error       => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        
        ELSIF l_id_consult_req IS NOT NULL
        THEN
            -- Create request
            g_error := 'CALL NEW_CONSULT_REQ';
            IF NOT pk_schedule_common.alter_consult_req(i_lang                => i_lang,
                                                        i_id_consult_req      => i_id_consult_req,
                                                        i_dt_consult_req_tstz => current_timestamp,
                                                        i_id_patient          => i_id_patient,
                                                        i_id_instit_requests  => i_prof.institution,
                                                        i_id_inst_requested   => i_prof.institution,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_prof_req         => i_prof.id,
                                                        i_notes_admin         => i_notes_admin,
                                                        i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                        i_id_prof_requested   => i_id_prof_requested,
                                                        i_flg_status          => pk_consult_req.g_consult_req_stat_reply,
                                                        i_next_visit_in_notes => i_next_visit_in,
                                                        i_flg_instructions    => i_flg_instructions,
                                                        i_id_complaint        => i_reason_visit,
                                                        i_dt_scheduled_tstz   => pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               i_dt_proposed,
                                                                                                               NULL),
                                                        i_flg_type_date       => i_flg_type_date,
                                                        o_consult_req_rec     => l_consult_req_rec,
                                                        o_error               => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        
            o_id_consult_req := l_consult_req_rec.id_consult_req;
        ELSE
            -- Create request
            g_error := 'CALL NEW_CONSULT_REQ';
            IF NOT pk_schedule_common.new_consult_req(i_lang                => i_lang,
                                                      i_dt_consult_req_tstz => current_timestamp,
                                                      i_id_patient          => i_id_patient,
                                                      i_id_instit_requests  => i_prof.institution,
                                                      i_id_inst_requested   => i_prof.institution,
                                                      i_id_episode          => i_id_episode,
                                                      i_id_prof_req         => i_prof.id,
                                                      i_notes_admin         => i_notes_admin,
                                                      i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                      i_id_prof_requested   => i_id_prof_requested,
                                                      i_flg_status          => pk_consult_req.g_consult_req_stat_reply,
                                                      i_next_visit_in_notes => i_next_visit_in,
                                                      i_flg_instructions    => i_flg_instructions,
                                                      i_id_complaint        => i_reason_visit,
                                                      i_dt_scheduled_tstz   => pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             i_dt_proposed,
                                                                                                             NULL),
                                                      i_flg_type_date       => i_flg_type_date,
                                                      o_consult_req_rec     => l_consult_req_rec,
                                                      o_error               => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        
            o_id_consult_req := l_consult_req_rec.id_consult_req;
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
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_disp_cons_req;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_VISIT_SCHED';
        l_count     NUMBER;
        l_dt_begin  TIMESTAMP WITH TIME ZONE;
        l_dt_end    TIMESTAMP WITH TIME ZONE;
        l_rowids    table_varchar;
        l_exception EXCEPTION;
    
        -- Creates an appointment
        FUNCTION inner_create_schedule
        (
            i_lang             IN language.id_language%TYPE,
            i_prof             IN profissional,
            i_id_patient       IN sch_group.id_patient%TYPE,
            i_id_episode       IN episode.id_episode%TYPE,
            i_id_sch_event     IN schedule.id_sch_event%TYPE,
            i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
            i_id_complaint     IN schedule.id_reason%TYPE,
            i_instructions     IN schedule.flg_instructions%TYPE,
            i_id_prof          IN sch_resource.id_professional%TYPE,
            i_dt_begin         IN TIMESTAMP WITH TIME ZONE,
            i_dt_end           IN TIMESTAMP WITH TIME ZONE,
            i_schedule_notes   IN VARCHAR2,
            i_id_schedule_ref  IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
            o_id_schedule      OUT schedule.id_schedule%TYPE,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN IS
            l_occupied sch_consult_vacancy.id_sch_consult_vacancy%TYPE; --BOOLEAN;
            l_exception EXCEPTION;
        BEGIN
            g_error := 'CALL CREATE_SCHEDULE';
            IF NOT pk_schedule_common.create_schedule(i_lang              => inner_create_schedule.i_lang,
                                                      i_id_prof_schedules => inner_create_schedule.i_prof.id,
                                                      i_id_institution    => inner_create_schedule.i_prof.institution,
                                                      i_id_software       => inner_create_schedule.i_prof.software,
                                                      i_id_patient        => inner_create_schedule.i_id_patient,
                                                      i_id_dep_clin_serv  => inner_create_schedule.i_id_dep_clin_serv,
                                                      i_id_sch_event      => inner_create_schedule.i_id_sch_event,
                                                      i_id_prof           => inner_create_schedule.i_id_prof,
                                                      i_dt_begin          => inner_create_schedule.i_dt_begin,
                                                      i_dt_end            => inner_create_schedule.i_dt_end,
                                                      i_flg_vacancy       => pk_schedule_common.g_sched_vacancy_routine,
                                                      i_flg_status        => pk_schedule.g_status_scheduled,
                                                      i_schedule_notes    => inner_create_schedule.i_schedule_notes,
                                                      i_id_complaint      => inner_create_schedule.i_id_complaint,
                                                      i_flg_instructions  => inner_create_schedule.i_instructions,
                                                      i_ignore_vacancies  => TRUE,
                                                      i_flg_sch_type      => pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                                      i_id_schedule_ref   => inner_create_schedule.i_id_schedule_ref,
                                                      o_id_schedule       => inner_create_schedule.o_id_schedule,
                                                      o_occupied          => l_occupied,
                                                      o_error             => inner_create_schedule.o_error)
            THEN
                -- Restore state
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL CREATE_SCHEDULE_OUTP';
            -- Create the outpatient-specific data.
            IF NOT pk_schedule_common.create_schedule_outp(i_lang              => inner_create_schedule.i_lang,
                                                           i_id_prof_schedules => inner_create_schedule.i_prof.id,
                                                           i_id_institution    => inner_create_schedule.i_prof.institution,
                                                           i_id_software       => inner_create_schedule.i_prof.software,
                                                           i_id_schedule       => inner_create_schedule.o_id_schedule,
                                                           i_id_patient        => inner_create_schedule.i_id_patient,
                                                           i_id_dep_clin_serv  => inner_create_schedule.i_id_dep_clin_serv,
                                                           i_id_sch_event      => inner_create_schedule.i_id_sch_event,
                                                           i_id_prof           => inner_create_schedule.i_id_prof,
                                                           i_dt_begin          => inner_create_schedule.i_dt_begin,
                                                           i_schedule_notes    => inner_create_schedule.i_schedule_notes,
                                                           i_id_episode        => inner_create_schedule.i_id_episode,
                                                           o_error             => inner_create_schedule.o_error)
            THEN
                RAISE l_exception;
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
                pk_utils.undo_changes;
                RETURN FALSE;
        END inner_create_schedule;
    
    BEGIN
        g_error := 'CHECK APPOINTMENT EXISTENCE';
        -- Check if the appointment already exists
        BEGIN
            SELECT 1
              INTO l_count
              FROM v_schedule_outp vso
             WHERE vso.id_schedule = i_id_schedule;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_begin';
        -- Convert start date
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dt_end := l_dt_begin + numtodsinterval(i_minutes, 'MINUTE');
    
        IF l_count = 1
        THEN
            -- Reschedule appointment
            g_error := 'CALL CANCEL_SCHEDULE';
            -- Cancel existing schedule
            IF NOT pk_schedule_common.cancel_schedule(i_lang             => i_lang,
                                                      i_id_professional  => i_prof.id,
                                                      i_id_software      => i_prof.software,
                                                      i_id_schedule      => i_id_schedule,
                                                      i_ignore_vacancies => TRUE,
                                                      o_error            => o_error)
            THEN
                -- Won't raise an exception on purpose
                pk_utils.undo_changes;
            END IF;
        
            g_error := 'CALL CREATE_SCHEDULE';
            -- Create a new appointment
            IF NOT inner_create_schedule(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_patient       => i_id_patient,
                                         i_id_episode       => i_id_episode,
                                         i_id_sch_event     => i_id_sch_event,
                                         i_id_dep_clin_serv => i_id_dep_clin_serv,
                                         i_id_complaint     => i_id_complaint,
                                         i_instructions     => i_instructions,
                                         i_id_prof          => i_id_prof,
                                         i_dt_begin         => l_dt_begin,
                                         i_dt_end           => l_dt_end,
                                         i_schedule_notes   => i_schedule_notes,
                                         i_id_schedule_ref  => i_id_schedule,
                                         o_id_schedule      => o_id_schedule,
                                         o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error := 'CALL CREATE_SCHEDULE';
            -- Create a new appointment
            IF NOT inner_create_schedule(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_patient       => i_id_patient,
                                         i_id_episode       => i_id_episode,
                                         i_id_sch_event     => i_id_sch_event,
                                         i_id_dep_clin_serv => i_id_dep_clin_serv,
                                         i_id_complaint     => i_id_complaint,
                                         i_instructions     => i_instructions,
                                         i_id_prof          => i_id_prof,
                                         i_dt_begin         => l_dt_begin,
                                         i_dt_end           => l_dt_end,
                                         i_schedule_notes   => i_schedule_notes,
                                         o_id_schedule      => o_id_schedule,
                                         o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'UPDATE consult_req';
        -- Update consult request
        -- <DENORM RicardoNunoAlmeida>        
        ts_consult_req.upd(id_consult_req_in => i_id_consult_req,
                           id_schedule_in    => o_id_schedule,
                           flg_status_in     => pk_consult_req.g_consult_req_stat_sched,
                           rows_out          => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        --</DENORM>
    
        --        UPDATE consult_req SET id_schedule = o_id_schedule, flg_status = pk_consult_req.g_consult_req_stat_sched WHERE id_consult_req = i_id_consult_req;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        -- Register episode-professional interaction
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => o_error)
        THEN
            RAISE l_exception;
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
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_visit_sched;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_VISIT_SCHED';
        l_exists    NUMBER;
        l_rowids    table_varchar;
        l_exception_int EXCEPTION;
        l_exception_ext EXCEPTION;
        l_error_message  VARCHAR2(4000);
        l_do_commit      BOOLEAN := FALSE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        g_error := 'CANCEL APPOINTMENT';
        IF i_id_schedule IS NOT NULL
        THEN
            g_error := 'CHECK EPISODE';
            -- Check if the appointment has an episode associated that isn't cancelled.
            BEGIN
                SELECT 1
                  INTO l_exists
                  FROM epis_info ei, episode e
                 WHERE ei.id_schedule = i_id_schedule
                   AND ei.id_episode = e.id_episode
                   AND e.flg_status != pk_alert_constant.g_cancelled;
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := 0;
            END;
        
            IF l_exists = 1
            THEN
                l_error_message := pk_message.get_message(i_lang, i_prof, 'SCH_M124');
                RAISE l_exception_int;
            END IF;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            g_error := 'CALL CANCEL_SCHEDULE';
            -- Cancel appointment
            IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_id_schedule,
                                               i_id_cancel_reason => NULL,
                                               i_cancel_notes     => NULL,
                                               io_transaction_id  => l_transaction_id,
                                               o_error            => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END IF;
    
        g_error := 'CANCEL REQUEST';
        IF i_id_consult_req IS NOT NULL
        THEN
            IF (i_cancel_request IS NOT NULL AND i_cancel_request = pk_schedule.g_yes)
            THEN
                g_error := 'UPDATE consult_req';
                --<DENORM RicardoNunoAlmeida>
                ts_consult_req.upd(id_consult_req_in => i_id_consult_req,
                                   flg_status_in     => pk_consult_req.g_consult_req_stat_req,
                                   rows_out          => l_rowids);
            
                --</DENORM>
            
                g_error := 'CALL CANCEL_CONSULT_REQ';
                -- Cancel request as well
                IF NOT pk_consult_req.cancel_consult_req(i_lang         => i_lang,
                                                         i_consult_req  => i_id_consult_req,
                                                         i_prof_cancel  => i_prof,
                                                         i_notes_cancel => NULL,
                                                         i_commit_data  => pk_alert_constant.g_no,
                                                         i_flg_discharge    => pk_alert_constant.g_yes,
                                                         o_error        => o_error)
                THEN
                    RAISE l_exception_ext;
                END IF;
            ELSE
                g_error := 'UPDATE consult_req';
                -- Update request (to requested state)
            
                --<DENORM RicardoNunoAlmeida>
                ts_consult_req.upd(id_consult_req_in => i_id_consult_req,
                                   flg_status_in     => pk_consult_req.g_consult_req_stat_reply,
                                   id_schedule_in    => NULL,
                                   id_schedule_nin   => FALSE,
                                   rows_out          => l_rowids);
            
                --</DENORM>
            END IF;
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        -- Register episode-professional interaction
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_int THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => l_error_message,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
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
            RETURN FALSE;
    END cancel_visit_sched;

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
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_VISIT_SCHED';
        l_rowids         table_varchar;
        l_transaction_id VARCHAR2(4000);
        l_ext_exception EXCEPTION;
    BEGIN
    
        -- start remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        IF NOT cancel_visit_sched(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_id_consult_req => i_id_consult_req,
                                  i_id_episode     => i_id_episode,
                                  i_id_schedule    => i_id_schedule,
                                  i_cancel_request => i_cancel_request,
                                  i_transaction_id => l_transaction_id,
                                  o_error          => o_error)
        THEN
            RAISE l_ext_exception;
        ELSE
            IF i_id_cancel_reason IS NOT NULL
               AND i_cancel_request = pk_schedule.g_yes
            THEN
                g_error := 'UPDATE CONSULT_REQ CANCEL_REASON';
                ts_consult_req.upd(id_consult_req_in   => i_id_consult_req,
                                   id_cancel_reason_in => i_id_cancel_reason,
                                   notes_cancel_in     => i_cancel_notes,
                                   rows_out            => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CONSULT_REQ',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        g_error := 'COMMIT SCHEDULER REMOTE TRANSACTION';
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            pk_utils.undo_changes;
            RETURN FALSE;
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END cancel_visit_sched;

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
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CHECK_DISP_SCHED';
        l_id_schedule    schedule.id_schedule%TYPE := NULL;
        l_id_consult_req consult_req.id_consult_req%TYPE := NULL;
        l_exception EXCEPTION;
    BEGIN
        g_error    := 'START';
        o_flg_show := pk_schedule.g_no;
    
        g_error := 'CHECK CONSULT_REQ';
        -- Try to get the consult request's and schedule's identifiers.
        BEGIN
            SELECT cr.id_consult_req, cr.id_schedule
              INTO l_id_consult_req, l_id_schedule
              FROM consult_req cr, schedule s
             WHERE cr.id_consult_req = i_id_consult_req
               AND s.id_schedule = cr.id_schedule
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_consult_req := i_id_consult_req;
        END;
    
        g_error := 'TEST SCHEDULE';
        IF l_id_schedule IS NOT NULL
        THEN
            -- If an appointment exists, the disposition cannot be changed.     
            o_flg_show  := pk_schedule.g_yes;
            o_button    := pk_schedule.g_check_button;
            o_msg_title := g_disp_warn_msg_title;
        
            g_error := 'CALL GET_DISP_CHANGE_MSG';
            -- Get message
            IF NOT get_disp_change_msg(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_id_schedule => l_id_schedule,
                                       o_msg         => o_msg,
                                       o_error       => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            o_change := 0;
        ELSE
            o_change := 1;
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
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END check_disp_sched;

    /**
    * Returns the details of a visit request.
    *
    * @param  i_lang                    Language identifier.
    * @param  i_prof                    Professional
    * @param  i_id_consult_req          Consult request
    * @param  o_cursor                  Cursor to be returned.
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Eduardo Lourenço
    * @version 2.4.3
    * @since  2008/05/10
    * @Changed : Elisabete Bugalho
    *          ALERT-1040 Return reason for next appointment (on free-text)
    * @changed : Pedro Carneiro
    *          not showing correct sch_event type.
    */
    FUNCTION get_visit_request_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := 'GET_VISIT_REQUEST_DETAILS';
        l_sep              VARCHAR2(1) := ':';
        l_id_sch_event_def sch_event.id_sch_event%TYPE := 2;
        l_event            pk_types.cursor_type;
        l_id_sch_event     sch_event.id_sch_event%TYPE;
        l_desc             pk_translation.t_desc_translation;
        l_id_sch_events    table_number := table_number();
        l_descs            table_varchar := table_varchar();
        l_flgs             table_varchar := table_varchar();
        l_prof_flgs        table_varchar := table_varchar();
    BEGIN
    
        g_error := 'CALL get_visit_events';
        -- get scheduling event types
        IF NOT get_visit_events(i_lang, i_prof, i_id_consult_req, NULL, 'N', l_event, o_error)
        THEN
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
        END IF;
    
        BEGIN
            FETCH l_event BULK COLLECT
                INTO l_id_sch_events, l_descs, l_flgs, l_prof_flgs;
        EXCEPTION
            WHEN rowtype_mismatch THEN
                -- got a dummy cursor!
                NULL;
        END;
    
        -- set default scheduling event
        FOR i IN 1 .. l_id_sch_events.count
        LOOP
            IF l_flgs(i) = 'Y'
            THEN
                l_id_sch_event := l_id_sch_events(i);
                l_desc         := l_descs(i);
                EXIT;
            END IF;
        END LOOP;
    
        -- no scheduling event? set default
        IF l_id_sch_event IS NULL
        THEN
            l_id_sch_event := l_id_sch_event_def;
            l_desc         := pk_schedule.string_sch_event(i_lang, l_id_sch_event_def);
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_cursor FOR
            SELECT cr.id_consult_req id_consult_req,
                   cr.id_prof_req id_prof_orig,
                   pk_message.get_message(i_lang, 'CONSULT_REQ_T012') || l_sep tit_prof_orig,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) desc_prof_orig,
                   pk_message.get_message(i_lang, 'CONSULT_REQ_T013') || l_sep tit_consult_req,
                   pk_date_utils.date_char_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) dt_consult_req_desc,
                   cr.id_dep_clin_serv,
                   pk_message.get_message(i_lang, 'CONSULT_REQ_T034') || l_sep tit_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                   l_id_sch_event id_event_type,
                   pk_message.get_message(i_lang, 'SCH_T003') || l_sep tit_event_type,
                   l_desc desc_event_type,
                   cr.id_prof_requested id_prof_dest,
                   pk_message.get_message(i_lang, 'SCH_T183') || l_sep tit_prof_dest,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) desc_prof_dest,
                   pk_date_utils.date_send_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) dt_proposed,
                   pk_message.get_message(i_lang, 'SCH_T204') || l_sep tit_dt_proposed,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof.institution, i_prof.software) dt_proposed_desc,
                   pk_message.get_message(i_lang, 'SCH_T186') || l_sep tit_dt_schedule,
                   pk_date_utils.date_char_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) dt_schedule_desc,
                   pk_message.get_message(i_lang, 'SCH_T024') || l_sep tit_status,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', cr.flg_status, i_lang) desc_status,
                   cr.id_complaint,
                   pk_message.get_message(i_lang, 'DISCHARGE_COMMON_T016') || l_sep tit_complaint,
                   decode(cr.id_schedule,
                          NULL,
                          decode(cr.id_complaint,
                                 NULL,
                                 reason_for_visit,
                                 pk_translation.get_translation(i_lang, c.code_complaint)),
                          decode(sch.id_reason,
                                 NULL,
                                 sch.reason_notes,
                                 pk_translation.get_translation(i_lang, c2.code_complaint))) desc_complaint,
                   pk_message.get_message(i_lang, 'SCH_T013') || l_sep tit_notes_admin,
                   cr.notes_admin,
                   cr.flg_status flg_status,
                   pk_message.get_message(i_lang, 'SCH_CANCEL_T005') tit_notes_cancel,
                   nvl(cr.notes_cancel, '--') notes_cancel,
                   pk_message.get_message(i_lang, 'SCH_CANCEL_T004') tit_cancel_reason,
                   nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cr.id_cancel_reason), '--') cancel_reason
              FROM consult_req cr
              LEFT JOIN dep_clin_serv dcs
                ON cr.id_dep_clin_serv = dcs.id_dep_clin_serv
              LEFT JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
              LEFT JOIN schedule sch
                ON cr.id_schedule = sch.id_schedule
              LEFT JOIN complaint c
                ON cr.id_complaint = c.id_complaint
              LEFT JOIN complaint c2
                ON sch.id_reason = c2.id_complaint
             WHERE cr.id_consult_req = i_id_consult_req;
    
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
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
        
    END get_visit_request_details;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_pp;
/
