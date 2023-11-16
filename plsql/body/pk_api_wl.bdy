/*-- Last Change Revision: $Rev: 2004050 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2021-12-23 12:04:10 +0000 (qui, 23 dez 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_wl IS

    /********************************************************************************************
    * Executes the required steps to allow that an external system can trigger "call" commands in WL's screens.
    * The only mandatory argument is the id of the machine - should the ticket not be provided, the function searches for the next ticket to call.
    *
    * 
    *
    * @param i_lang                 The language ID.
    * @param i_prof                 The professional that called the function. If NULL, it defaults to (0,0,0)
    * @param i_machine              The machine that called the function.
    * @param i_flg_prioritary       Defines if the application should mind prioritary queues or not.
    * @param io_ticket              (OPTIONAL) Specifies the ticket to be called by WL, and returns the ticket called by WL.
    * @param o_error                Errors.
    ********************************************************************************************/
    FUNCTION intf_get_next_call
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_machine        IN wl_machine.id_wl_machine%TYPE,
        i_flg_prioritary IN NUMBER,
        io_ticket        IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_prioritary NUMBER;
        l_message_audio  VARCHAR2(4000);
        l_sound_file     VARCHAR2(4000);
        l_mac            table_varchar;
        l_msg            table_number;
        l_id_queues      table_number;
        l_wl_mach        table_number;
    BEGIN
    
        IF i_flg_prioritary IS NULL
        THEN
            l_flg_prioritary := 1;
        END IF;
    
        IF i_prof IS NOT NULL
        THEN
            g_prof := i_prof;
        END IF;
    
        IF i_lang IS NOT NULL
        THEN
            g_lang := i_lang;
        END IF;
    
        -- If io_ticket is not null, it means the purpose is to repeat a call for a known ticket, which is provided by system calling this function.
        --Therefore, the next ticket to be called is the same which was provided, and there is no need to go through this IF statement.
        IF io_ticket IS NULL
        THEN
            --We don't know which ticket is supposed to be called, yet.
            --First we need to identify the queues the machine that issued the call is alocated to;
            IF ((g_prof.id = 0) OR (g_prof IS NULL))
            THEN
                g_error := 'GET QUEUE';
                --There is no professional set, therefore we fetch all non-clinical queues on the same group of the machine.
                SELECT wq.id_wl_queue
                  BULK COLLECT
                  INTO l_id_queues
                  FROM wl_machine wm
                 INNER JOIN wl_queue wq
                    ON nvl(wm.id_wl_queue_group, 0) = nvl(wq.id_wl_queue_group, 0)
                 WHERE wq.flg_type_queue = g_flg_type_queue_registar
                   AND wm.id_wl_machine = i_machine;
            
            ELSE
                --The professional must be allocated to some queues in order to accept.
                g_error := 'GET ALL QUEUES';
                SELECT wmpq.id_wl_queue
                  BULK COLLECT
                  INTO l_id_queues
                  FROM wl_mach_prof_queue wmpq
                 WHERE wmpq.id_wl_machine = i_machine
                   AND wmpq.id_professional = g_prof.id;
            END IF;
        
            -- Queues are identified, we are ready to get the next ticket.
            -- One question: do we care only with the non-prioritary queues or not?
            -- Answer: i_flg_prioritary - if true the call will follow the normal rules; if false the call will not consider tickets from prioritary queues.
            g_error := 'GET TICKET';
            g_ret   := pk_wladm.get_next_call_queue(i_lang            => i_lang,
                                                    i_id_queues       => l_id_queues,
                                                    i_flg_prior_too   => l_flg_prioritary,
                                                    o_id_waiting_line => io_ticket,
                                                    o_error           => o_error);
        
        END IF;
    
        -- io_ticket should always have a value set by now, but can't hurt to check that, neverthless.
        -- if it does not, then it just means that
        IF io_ticket IS NOT NULL
        THEN
            g_error := 'GET ID MACHINE';
            SELECT wmq.id_wl_mach_dest
              BULK COLLECT
              INTO l_wl_mach
              FROM wl_waiting_line wl
             INNER JOIN wl_queue wq
                ON wq.id_wl_queue = wl.id_wl_queue
               AND wq.id_wl_queue_group = (SELECT wm.id_wl_queue_group
                                             FROM wl_machine wm
                                            WHERE wm.id_wl_machine = i_machine)
            
             INNER JOIN wl_msg_queue wmq
                ON wl.id_wl_queue = wmq.id_wl_id_queue
             WHERE wl.id_wl_waiting_line = io_ticket;
        
            g_error := 'GENERATE CALL';
            FOR i IN l_wl_mach.first .. l_wl_mach.last
            LOOP
            
                g_ret := pk_wlservices.set_item_call_queue(i_lang          => i_lang,
                                                           i_id_wl         => io_ticket,
                                                           i_id_mach_ped   => l_wl_mach(i),
                                                           i_prof          => g_prof,
                                                           i_id_mach_dest  => i_machine,
                                                           i_id_episode    => null,
                                                           i_id_room       => null,
                                                           o_message_audio => l_message_audio,
                                                           o_sound_file    => l_sound_file,
                                                           o_msg           => l_msg,
                                                           o_mac           => l_mac,
                                                           o_error         => o_error);
            END LOOP;
        
            IF g_ret
            THEN
                g_error := 'UPDATE CALL TIMES';
                g_ret   := pk_wlcore.set_item_call_queue_sound_gen(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_sound_file => l_sound_file,
                                                                   o_error      => o_error);
            END IF;
        
        END IF;
        RETURN g_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_GET_NEXT_CALL',
                                              o_error);
        
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Function to return the ALERT ID of the provided machine name.
    *
    * @param i_machine_name               The name machine requiring identification.
    * @param o_machine                    The machine ID.
    * @param o_error                      Errors.
    ********************************************************************************************/
    FUNCTION intf_get_machine
    (
        i_machine_name IN wl_machine.machine_name%TYPE,
        o_machine_id   OUT wl_machine.id_wl_machine%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'START';
        SELECT id_wl_machine
          INTO o_machine_id
          FROM wl_machine
         WHERE machine_name = i_machine_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(1,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'INTF_GET_MACHINE',
                                                     o_error);
        
    END intf_get_machine;

    /********************************************************************************************
    * Function to allocate professionals to queues. If no queues are provided, the professional is assumed to be
    * an ancillary and is allocated to all non-medical queues.
    *
    * @param i_prof                  The ALERT professional.
    * @param i_machine               The machine the professional is logged on.
    * @param i_queues                The queues to allocate the professional to.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_prof_queues
    (
        i_prof    IN profissional,
        i_machine IN wl_machine.id_wl_machine%TYPE,
        i_queues  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_queues table_number := table_number();
    BEGIN
        IF i_queues IS NULL
        THEN
            g_error := 'COLLECT QUEUES';
            SELECT wq.id_wl_queue
              BULK COLLECT
              INTO l_queues
              FROM wl_queue wq
             WHERE wq.flg_type_queue = g_flg_type_queue_registar;
        ELSE
            l_queues := i_queues;
        END IF;
        g_error := 'ALLOCATE QUEUES';
        g_ret   := pk_wlsession.set_queues(i_lang      => 11,
                                           i_prof      => i_prof,
                                           i_id_mach   => i_machine,
                                           i_id_queues => l_queues,
                                           o_error     => o_error);
        RETURN g_ret;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_PROF_QUEUES',
                                              o_error);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Function to return the available queues for a machine.
    *
    * @param i_machine               The machine.
    * @param o_queues                Array containing the IDs of the available queues.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_get_prof_queues
    (
        i_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues  OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'START';
        SELECT wq.id_wl_queue
          BULK COLLECT
          INTO o_queues
          FROM wl_machine wm
         INNER JOIN room r
            ON wm.id_room = r.id_room
         INNER JOIN wl_queue wq
            ON wq.id_department = r.id_department
           AND wq.id_wl_queue_group = wm.id_wl_queue_group
         WHERE wq.flg_type_queue IN (g_flg_type_queue_registar, g_flg_type_queue_nur_cons)
           AND wm.id_wl_machine = i_machine;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(1,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'INTF_GET_PROF_QUEUES',
                                                     o_error);
        
    END intf_get_prof_queues;

    /********************************************************************************************
    * Function to return information related to the available queues for a machine.
    *
    * @param i_lang                  The ID of the language in which the queue information should be displayed
    * @param i_machine               The machine.
    * @param o_queues                Array containing the IDs of the available queues.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_get_prof_queues_info
    
    (
        i_lang    IN language.id_language%TYPE,
        i_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'START';
        OPEN o_queues FOR
            SELECT wq.id_wl_queue,
                   pk_translation.get_translation(i_lang, wq.code_name_queue) inter_name_queue,
                   pk_translation.get_translation(i_lang, wq.code_msg) code_msg
              FROM wl_machine wm
             INNER JOIN room r
                ON wm.id_room = r.id_room
             INNER JOIN wl_queue wq
                ON wq.id_department = r.id_department
               AND wq.id_wl_queue_group = wm.id_wl_queue_group
             WHERE wq.flg_type_queue IN (g_flg_type_queue_registar, g_flg_type_queue_nur_cons)
               AND wm.id_wl_machine = i_machine;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_GET_PROF_QUEUES_INFO',
                                              o_error);
        
    END intf_get_prof_queues_info;

    /********************************************************************************************
    * INTERNAL
    * A very simple function that creates an association between a ticket and an episode.
    * Extra information is also updated on the ticket.
    * Note that this mode of execution does not allow for the WL workflow to continue its natural course.
    *
    *
    * @param i_prof                 The professional.
    * @param i_ticket               The ticket to associate.
    * @param i_epis                 The episode to associate.
    * @param i_dt_consult           Date of the consult
    * @param i_id_clin_serv         Clinical Service of the consult
    * @param i_room                 Room where the consult will take place
    * @param o_error                Errors
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis_simple
    (
        i_prof         IN profissional,
        i_ticket       IN NUMBER,
        i_epis         IN NUMBER,
        i_dt_consult   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_clin_serv IN NUMBER,
        i_room         IN NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'START';
        UPDATE wl_waiting_line wwl
           SET wwl.id_episode          = i_epis,
               wwl.id_patient         =
               (SELECT v.id_patient
                  FROM episode e
                 INNER JOIN visit v
                    ON e.id_visit = v.id_visit
                 WHERE e.id_episode = i_epis),
               wwl.flg_wl_status       = 'A', --Admitted
               wwl.dt_end_tstz         = current_timestamp,
               wwl.id_professional     = i_prof.id,
               wwl.dt_consult_tstz     = i_dt_consult, --Note: This info should not be stored here; for possible later data migration.
               wwl.id_clinical_service = i_id_clin_serv, --Note: This info should not be stored here; for possible later data migration.
               wwl.id_room             = i_room --Note: This info should not be stored here; for possible later data migration.
         WHERE wwl.id_wl_waiting_line = i_ticket
           AND wwl.id_episode IS NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_TICKET_EPIS_SIMPLE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Triggers an admission just as the WL applet would do it.
    *
    * @param i_lang                  The language ID.
    * @param i_prof                  The ALERT professional.
    * @param i_epis                  The episode to associate.
    * @param i_id_prof_next          The ID of the next ALERT professional.
    * @param i_clin_serv             The ID of the clinical service the patient intends to visit.
    * @param dt_consult              Date of the consult.
    * @param i_id_mach               The ID of the machine of the ALERT professional that will receive the patient.
    * @param i_room                  The ID of the room where the consult will take place.
    * @param io_ticket               The ticket to associate. OUT: the ticket ID of the following line.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis_workflow
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_prof_next IN professional.id_professional%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_dt_consult   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_mach      IN wl_machine.id_wl_machine%TYPE,
        i_room         IN room.id_room%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        io_ticket      IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat   patient%ROWTYPE;
        l_pats  table_number := table_number();
        l_rooms table_number := table_number();
    BEGIN
        g_error := 'START';
        --Get the patient data
        SELECT p.*
          INTO l_pat
          FROM patient p
         INNER JOIN visit v
            ON v.id_patient = p.id_patient
         INNER JOIN episode e
            ON e.id_visit = v.id_visit
         WHERE e.id_episode = i_epis;
    
        g_error := 'INSERT PATIENT';
        INSERT INTO wl_patient_sonho
            (patient_id,
             patient_name,
             patient_dt_birth,
             patient_gender,
             num_proc,
             clin_prof_id,
             clin_prof_name,
             dt_consult_tstz,
             consult_id,
             consult_name,
             prof_id,
             machine_name,
             id_institution,
             id_episode)
        VALUES
            (l_pat.id_patient,
             l_pat.name,
             l_pat.dt_birth,
             l_pat.gender,
             NULL, --Numero de processo, não é utilizado.
             i_id_prof_next,
             '', -- Nome do proximo profissional, não importa.
             i_dt_consult,
             i_clin_serv,
             '', --Nome da consulta.
             i_prof.id,
             NULL, --Nome da máquina, também não importa
             i_prof.institution,
             i_epis);
    
        l_pats  := table_number(l_pat.id_patient);
        l_rooms := table_number(i_room);
        g_error := 'APPLY ADMISSION';
        g_ret   := pk_wlcore.set_end_line(i_lang    => i_lang,
                                          i_id_prof => i_prof,
                                          i_id_mach => i_id_mach,
                                          i_id_wait => io_ticket,
                                          i_id_pat  => l_pats,
                                          i_id_room => l_rooms,
                                          o_error   => o_error);
    
        RETURN g_ret;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_TICKET_EPIS_WORKFLOW',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * This function receives the two mandatory arguments (ticket id and episode id) and based on that
    * settles itself for a course of action, that can go from following the regular workflow to simply
    * updating the ticket with the id of the episode.
    *
    * @param i_lang                  The language ID.
    * @param i_prof                  The ALERT professional.
    * @param i_epis                  The episode to associate.
    * @param i_id_prof_next          The ID of the next ALERT professional.
    * @param i_clin_serv             The ID of the clinical service the patient intends to visit.
    * @param dt_consult              Date of the consult.
    * @param i_id_mach               The ID of the machine of the ALERT professional that will receive the patient.
    * @param i_room                  The ID of the room where the consult will take place.
    * @param io_ticket               The ticket to associate. OUT: the ticket ID of the following line.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_id_prof_next IN professional.id_professional%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_dt_consult   IN wl_waiting_line.dt_consult_tstz%TYPE,
        i_id_mach      IN wl_machine.id_wl_machine%TYPE,
        i_room         IN room.id_room%TYPE,
        io_ticket      IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_clin_serv clinical_service.id_clinical_service%TYPE;
        l_room      room.id_room%TYPE;
        l_prof_next professional.id_professional%TYPE;
    BEGIN
        g_ret   := NULL;
        g_error := 'START';
    
        IF i_prof IS NOT NULL
        THEN
            g_prof := i_prof;
        END IF;
    
        IF i_lang IS NOT NULL
        THEN
            g_lang := i_lang;
        END IF;
    
        -- Critical info not provided? No need to continue.
        IF (io_ticket IS NULL)
           OR (i_epis IS NULL)
        THEN
            RETURN FALSE;
        END IF;
    
        -- The basic case, when there is no relevant info other than simply the original ticket and the episode id that is aquired later on.
        -- For instance, the system always has the info regarding the machine being called; nevertheless if its ID is passed on as NULL
        -- that'll be a clear sign that it's not supposed to run its best course.
        IF ((g_prof.id = 0) OR (i_id_prof_next IS NULL) OR (i_id_mach IS NULL))
        THEN
            g_error := 'BASIC CASE';
            g_ret   := intf_set_ticket_epis_simple(i_prof         => g_prof,
                                                   i_ticket       => io_ticket,
                                                   i_epis         => i_epis,
                                                   i_dt_consult   => i_dt_consult,
                                                   i_id_clin_serv => i_clin_serv,
                                                   i_room         => i_room,
                                                   o_error        => o_error);
        
            RETURN g_ret;
        ELSE
        
            IF i_id_prof_next IS NULL
            THEN
                g_error := 'CANNOT FIND PROFESSIONAL';
                g_ret   := intf_set_ticket_epis_simple(i_prof         => g_prof,
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            ELSE
                l_prof_next := i_id_prof_next;
            END IF;
        
            IF (i_room IS NULL)
            THEN
                g_error := 'CANNOT FIND ROOM';
                g_ret   := intf_set_ticket_epis_simple(i_prof => g_prof,
                                                       
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            
            ELSE
                l_room := i_room;
            END IF;
        
            IF (i_clin_serv IS NULL)
            THEN
                -- Unable to find clinical service; therefore going for the simple course (l_clin_serv will be null).
                g_error := 'CANNOT FIND CLIN_SERV';
                g_ret   := intf_set_ticket_epis_simple(i_prof => g_prof,
                                                       
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            ELSE
                l_clin_serv := i_clin_serv;
            END IF;
        
            --Perfect case, when all important fields are provided
            IF (g_ret IS NULL)
               AND (l_clin_serv IS NOT NULL)
               AND (l_room IS NOT NULL)
               AND (l_prof_next IS NOT NULL)
            THEN
                g_error := 'ENTERING ADMISSION';
                g_ret   := intf_set_ticket_epis_workflow(g_lang,
                                                         g_prof,
                                                         l_prof_next,
                                                         l_clin_serv,
                                                         i_dt_consult,
                                                         i_id_mach,
                                                         l_room,
                                                         i_epis,
                                                         io_ticket,
                                                         o_error);
            END IF;
        END IF;
        RETURN g_ret;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_TICKET_EPIS',
                                              o_error);
        
            RETURN FALSE;
    END intf_set_ticket_epis;

    /********************************************************************************************
    * This function receives the two mandatory arguments (ticket id and episode id) and based on that
    * settles itself for a course of action, that can go from following the regular workflow to simply
    * updating the ticket with the id of the episode.
    * If you pass id_ticket NULL, this function will automatically create one ticket
    *
    * @param i_lang                  The language ID.
    * @param i_prof                  The ALERT professional.
    * @param i_epis                  The episode to associate.
    * @param i_id_prof_next          The ID of the next ALERT professional.
    * @param i_clin_serv             The ID of the clinical service the patient intends to visit.
    * @param dt_consult              Date of the consult.
    * @param i_id_mach               The ID of the machine of the ALERT professional that will receive the patient.
    * @param i_room                  The ID of the room where the consult will take place.
    * @param i_id_wl_queue           ID of the Queue that the ticket 
    * @param io_ticket               The ticket to associate. OUT: the ticket ID of the following line.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_id_prof_next IN professional.id_professional%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_dt_consult   IN wl_waiting_line.dt_consult_tstz%TYPE,
        i_id_mach      IN wl_machine.id_wl_machine%TYPE,
        i_room         IN room.id_room%TYPE,
        i_id_wl_queue  IN wl_queue.id_wl_queue%TYPE,
        io_ticket      IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_clin_serv clinical_service.id_clinical_service%TYPE;
        l_room      room.id_room%TYPE;
        l_prof_next professional.id_professional%TYPE;
        --
        next_number         wl_queue.num_queue%TYPE;
        char_queue          wl_queue.char_queue%TYPE;
        l_code_message_dept department.code_department%TYPE;
        l_id_inst           department.id_institution%TYPE;
        l_code_message_inst institution.code_institution%TYPE;
        l_rows              table_varchar;
        --
        l_ticket_number VARCHAR2(1000 CHAR);
        l_msg_dept      VARCHAR2(1000 CHAR);
        l_msg_inst      VARCHAR2(1000 CHAR);
    BEGIN
        g_ret   := NULL;
        g_error := 'START';
    
        IF i_prof IS NOT NULL
        THEN
            g_prof := i_prof;
        END IF;
    
        IF i_lang IS NOT NULL
        THEN
            g_lang := i_lang;
        END IF;
    
        IF io_ticket IS NULL
        THEN
            g_error := 'GET MACHINE, INSTITUTION AND DEPARTMENT INFO';
            pk_alertlog.log_debug(g_error, g_package_name);
            SELECT d.code_department,
                   d.id_institution,
                   pk_translation.get_translation(i_lang, wm.cod_desc_machine_visual),
                   i.code_institution,
                   i.abbreviation
              INTO l_code_message_dept, l_id_inst, l_msg_dept, l_code_message_inst, l_msg_inst
              FROM wl_machine wm
             INNER JOIN room r
                ON wm.id_room = r.id_room
             INNER JOIN department d
                ON r.id_department = d.id_department
             INNER JOIN institution i
                ON d.id_institution = i.id_institution
             WHERE wm.id_wl_machine = i_id_mach;
        
            g_error := 'UPDATE RECORD WITH NEW NUMBER';
            pk_alertlog.log_debug(g_error, g_package_name);
            UPDATE wl_queue
               SET num_queue =
                   (num_queue + 1)
             WHERE id_wl_queue = i_id_wl_queue
            RETURNING(num_queue + 1), char_queue INTO next_number, l_ticket_number;
        
            g_error := 'INSERT RECORD TO BE CALLED';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            io_ticket := ts_wl_waiting_line.next_key;
        
            ts_wl_waiting_line.ins(id_wl_waiting_line_in => io_ticket,
                                   char_queue_in         => l_ticket_number,
                                   number_queue_in       => next_number,
                                   id_wl_queue_in        => i_id_wl_queue,
                                   flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_e,
                                   dt_begin_tstz_in      => current_timestamp,
                                   rows_out              => l_rows);
            l_ticket_number := l_ticket_number || next_number;
        
            g_error := 'PROCESS INSERT WITH WL_WAITING_LINE ' || l_ticket_number;
            pk_alertlog.log_debug(g_error, g_package_name);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'WL_WAITING_LINE', l_rows, o_error);
        
        END IF;
    
        -- Critical info not provided? No need to continue.
        IF (io_ticket IS NULL)
           OR (i_epis IS NULL)
        THEN
            RETURN FALSE;
        END IF;
    
        -- The basic case, when there is no relevant info other than simply the original ticket and the episode id that is aquired later on.
        -- For instance, the system always has the info regarding the machine being called; nevertheless if its ID is passed on as NULL
        -- that'll be a clear sign that it's not supposed to run its best course.
        IF ((g_prof.id = 0) OR (i_id_prof_next IS NULL) OR (i_id_mach IS NULL))
        THEN
            g_error := 'BASIC CASE';
            g_ret   := intf_set_ticket_epis_simple(i_prof         => g_prof,
                                                   i_ticket       => io_ticket,
                                                   i_epis         => i_epis,
                                                   i_dt_consult   => i_dt_consult,
                                                   i_id_clin_serv => i_clin_serv,
                                                   i_room         => i_room,
                                                   o_error        => o_error);
        
            RETURN g_ret;
        ELSE
        
            IF i_id_prof_next IS NULL
            THEN
                g_error := 'CANNOT FIND PROFESSIONAL';
                g_ret   := intf_set_ticket_epis_simple(i_prof         => g_prof,
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            ELSE
                l_prof_next := i_id_prof_next;
            END IF;
        
            IF (i_room IS NULL)
            THEN
                g_error := 'CANNOT FIND ROOM';
                g_ret   := intf_set_ticket_epis_simple(i_prof => g_prof,
                                                       
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            
            ELSE
                l_room := i_room;
            END IF;
        
            IF (i_clin_serv IS NULL)
            THEN
                -- Unable to find clinical service; therefore going for the simple course (l_clin_serv will be null).
                g_error := 'CANNOT FIND CLIN_SERV';
                g_ret   := intf_set_ticket_epis_simple(i_prof => g_prof,
                                                       
                                                       i_ticket       => io_ticket,
                                                       i_epis         => i_epis,
                                                       i_dt_consult   => i_dt_consult,
                                                       i_id_clin_serv => i_clin_serv,
                                                       i_room         => i_room,
                                                       o_error        => o_error);
                RETURN g_ret;
            ELSE
                l_clin_serv := i_clin_serv;
            END IF;
        
            --Perfect case, when all important fields are provided
            IF (g_ret IS NULL)
               AND (l_clin_serv IS NOT NULL)
               AND (l_room IS NOT NULL)
               AND (l_prof_next IS NOT NULL)
            THEN
                g_error := 'ENTERING ADMISSION';
                g_ret   := intf_set_ticket_epis_workflow(g_lang,
                                                         g_prof,
                                                         l_prof_next,
                                                         l_clin_serv,
                                                         i_dt_consult,
                                                         i_id_mach,
                                                         l_room,
                                                         i_epis,
                                                         io_ticket,
                                                         o_error);
            END IF;
        END IF;
        RETURN g_ret;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_SET_TICKET_EPIS',
                                              o_error);
        
            RETURN FALSE;
    END intf_set_ticket_epis;

BEGIN
    g_prof := profissional(0, 0, 0);
    g_lang := 1;

    g_flg_type_queue_doctor   := 'D';
    g_flg_type_queue_nurse    := 'N';
    g_flg_type_queue_registar := 'A';
    g_flg_type_queue_nur_cons := 'C';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_wl;
/
