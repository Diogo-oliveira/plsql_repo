/*-- Last Change Revision: $Rev: 2027667 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:57 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_api_upstream AS

    -- VARS
    g_transaction_id VARCHAR2(4000);

    k_alert_hhc_approve_sched CONSTANT NUMBER := 332;
    k_alert_hhc_undo_sched    CONSTANT NUMBER := 333;

    -- **********************************************
    FUNCTION hhc_change_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_flg_status     IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_alert_event
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_sys_alert     IN NUMBER,
        i_id_sys_alert_del IN NUMBER,
        i_id_schedule      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    -- INTERNAL SUBPROGRAMS
    FUNCTION get_language_from_prof(i_prof IN profissional) RETURN NUMBER IS

    BEGIN
      RETURN TO_NUMBER(pk_sysconfig.get_config('LANGUAGE', i_prof));
      EXCEPTION
        WHEN OTHERS THEN
          RETURN 2;
    END get_language_from_prof;
    
    
    FUNCTION get_fit_error_message(i_errmsg VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN substr(i_errmsg, 1, 1500);
    END get_fit_error_message;

    /*
    * Gets id_schedule external (first id)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @version 1.0
    * @since   21-10-2009      
    */
    FUNCTION get_tbl_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN table_number,
        o_id_schedule OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_ext table_number;
    BEGIN
    
        IF i_id_schedule.exists(1)
        THEN
        
            SELECT id_schedule_ext
              BULK COLLECT
              INTO tbl_ext
              FROM (SELECT s.id_schedule,
                           y.id_schedule_ext,
                           row_number() over(PARTITION BY id_schedule ORDER BY y.id_schedule_ext) rn,
                           s.rnx
                      FROM (SELECT /*+ OPT_ESTIMATE(TABLE tt ROWS=1) */
                             rownum rnx, column_value id_schedule
                              FROM TABLE(i_id_schedule) tt) s
                      LEFT JOIN sch_api_map_ids y
                        ON s.id_schedule = y.id_schedule_pfh) xsql
             WHERE rn = 1
             ORDER BY rnx;
        
        END IF;
    
        o_id_schedule := tbl_ext;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TBL_SCHEDULE_ID_EXT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_tbl_schedule_id_ext;

    FUNCTION get_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_map_sch IS
            SELECT id_schedule_ext
              FROM sch_api_map_ids
             WHERE id_schedule_pfh = i_id_schedule
               AND rownum = 1;
    
    BEGIN
    
        g_error := 'OPEN c_map_sch';
        OPEN c_map_sch;
        FETCH c_map_sch
            INTO o_id_schedule;
        CLOSE c_map_sch;
    
        IF o_id_schedule IS NULL
        THEN
            pk_alertlog.log_warn(text        => 'get_schedule_id_ext - id_schedule_ext not found for i_id_schedule=' ||
                                                i_id_schedule,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
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
                                              i_function => 'GET_SCHEDULE_ID_EXT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_schedule_id_ext;

    /**
    * Obtem o id_content usado pela nova agenda.
    * Trata-se de um método genérico que deve ser usado com cuidado pois o id_content
    * nem sempre virá da tabela clinical service. O id_content deverá sempre ser obtido
    * sempre no contexto de quem invocou a funcao.Se for de um MFR devera ser usada por
    * exemplo a funcao get_interv_content_id.
    *
    * @param i_dep_clin_serv   Id que permite obtencao do id_content
    * @param o_content_id      Id do conteudo. Sera usado pela nova agenda.
    * @param o_error           Id do erro
    * @author Carlos Nogueira
    * @version 1.5
    * @since 02-03-2010
    *
    */
    FUNCTION get_interv_content_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_interv_presc_det IN schedule_intervention.id_interv_presc_det%TYPE,
        o_content_id          OUT clinical_service.id_content%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_CONTENT_ID';
    
    BEGIN
    
        g_error := 'GET ID_CONTENT FROM SCHEDULE_INTERVENTION,INTERV_PRESC_DET,INTERVENTION WHERE i_id_interv_presc_det = ' ||
                   i_id_interv_presc_det;
        SELECT i.id_content
          INTO o_content_id
          FROM schedule_intervention si, interv_presc_det ipd, intervention i
         WHERE si.id_interv_presc_det = ipd.id_interv_presc_det
           AND i.id_intervention = ipd.id_intervention
           AND si.id_interv_presc_det = i_id_interv_presc_det;
    
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
        
    END get_interv_content_id;

    /*
    * Gets a new transaction ID and begins it
    *
    * @return Transaction identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009
    */
    FUNCTION create_new_transaction(i_prof profissional) RETURN VARCHAR2 IS
        l_transaction_id VARCHAR2(4000);
        l_language NUMBER;
		l_application_context sys_config.id_sys_config%TYPE := 'REST_APSSCH_CONTEXT';
        l_application_port    sys_config.id_sys_config%TYPE := 'REST_APSSCH_PORT';
    
    BEGIN   
        
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_no THEN
            RETURN 'NO_SCHEDULER3_INSTALLED.THIS_IS_A_FAKE_TRANSACTION';
        END IF;
		
        l_language := get_language_from_prof(i_prof);
        g_error  := 'CALL PK_REST_API.GETTRANSACTIONID ERROR GETTING TRANSACTION ID';
        IF NOT pk_rest_api.gettransactionid(i_lang            => l_language,
                                        i_prof                => i_prof,
                                        i_application_context => l_application_context,
                                        i_application_port    => l_application_port,
                                        o_transaction         => l_transaction_id) THEN
          pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
        END IF;
                                                                
        g_error := 'CALL PK_REST_API.BEGINTRANSACTION: ' || l_transaction_id;
        IF NOT pk_rest_api.begintransaction(i_lang        => l_language,
                                            i_prof        => i_prof,
                                            i_transaction => l_transaction_id) THEN
          pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
         END IF;
    
        RETURN l_transaction_id;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
            RETURN NULL;
    END;

    /*
    * Creates an appointment in scheduler 3 and after the same appointment in pfh
    * used by PK_P1_INTERFACE and PK_REF_INTERFACE
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_event_id           Associated event id
    * @param i_professional_id    Physician id
    * @param i_id_patient         Patient id
    * @param i_id_dep_clin_serv   id dep clin serv
    * @param i_dt_begin_tstz      Appointment begin date
    * @parma i_dt_end_tstz        Appointment end date
    * @param i_flg_vacancy         Flag vacancy ( Type of vacancy occupied: 'R' routine, 'U' urgent, 'V' unplanned )
    * @param i_id_episode         Episode ids
    * @param i_flg_rqst_type      Appointment's request type (patient, physician, nurse, institution)
    * @param i_flg_sch_via        Scheduling by telephone contact
    * @param i_sch_notes          schedule notes
    * @param i_id_inst_requests   requesting instit
    * @param i_id_dcs_requests    requesting dcs
    * @param i_id_prof_requests    requesting prof
    * @param i_id_prof_schedules  scheduling prof
    * @param i_id_sch_ref         reference to this schedule
    * @param i_transaction_id     Scheduler transaction identifier
    * @param i_id_external_req    P1 identifier.
    * @param o_id_schedule         list of new PFH schedule ids
    * @param o_id_schedule_ext    new scheduler 3 id
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @since   21-12-2009
    */
    FUNCTION create_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_id          IN schedule.id_sch_event%TYPE,
        i_professional_id   IN professional.id_professional%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz     IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tstz       IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy       IN schedule.flg_vacancy%TYPE,
        i_id_episode        IN schedule.id_episode%TYPE,
        i_flg_rqst_type     IN schedule.flg_request_type%TYPE,
        i_flg_sch_via       IN schedule.flg_schedule_via%TYPE,
        i_sch_notes         IN schedule.schedule_notes%TYPE,
        i_id_inst_requests  IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_dcs_requests   IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_prof_requests  IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_sch_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_transaction_id    IN VARCHAR2,
        i_id_external_req   IN p1_external_request.id_external_request%TYPE,
        i_dt_referral       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_ids_schedule      OUT table_number,
        o_id_schedule_ext   OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_id_appointment appointment.id_appointment%TYPE;
        l_id_dep         dep_clin_serv.id_department%TYPE;
        l_id_inst        department.id_institution%TYPE;
        l_sch_type       sch_event.dep_type%TYPE;
        l_procedure      pk_schedule_api_downstream.t_procedure;
        l_procedures     pk_schedule_api_downstream.t_procedures := pk_schedule_api_downstream.t_procedures();
        l_person         pk_schedule_api_downstream.t_person;
        l_persons        pk_schedule_api_downstream.t_persons := pk_schedule_api_downstream.t_persons();
        l_resource       pk_schedule_api_downstream.t_resource;
        l_resources      pk_schedule_api_downstream.t_resources := pk_schedule_api_downstream.t_resources();
        l_procedure_req  pk_schedule_api_downstream.t_procedure_req;
        l_procedure_reqs pk_schedule_api_downstream.t_procedure_reqs := pk_schedule_api_downstream.t_procedure_reqs();
    
    BEGIN
        -- obter id_content a partir do evento e dcs
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT WITH i_event_id= ' || i_event_id ||
                   ' AND i_id_dep_clin_serv= ' || i_id_dep_clin_serv;
        IF NOT pk_schedule_api_downstream.get_id_content(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_sch_event => i_event_id,
                                                         i_id_dcs       => i_id_dep_clin_serv,
                                                         o_id_content   => l_id_appointment,
                                                         o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- obter inst e dep do dcs
        g_error := 'GET DEPARTMENT ID AND INSTITUTION ID WITH id_dep_clin_serv = ' || i_id_dep_clin_serv;
        SELECT dcs.id_department, d.id_institution
          INTO l_id_dep, l_id_inst
          FROM dep_clin_serv dcs
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        -- obter sch type
        g_error := 'GET SCH TYPE FROM EVENT WITH id_sch_event = ' || i_event_id;
        SELECT dep_type
          INTO l_sch_type
          FROM sch_event
         WHERE id_sch_event = i_event_id;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error        := 'Call pk_schedule_rest_services.createschedule';
            l_obj_response := pk_schedule_rest_services.createschedule(i_lang           => i_lang,
                                                                       i_prof           => i_prof,                             
                                                                       i_personid       => i_id_patient,
                                                                       i_depcleanservid => i_id_dep_clin_serv,
                                                                       i_contentid      => l_id_appointment,
                                                                       i_professionalid => i_professional_id,
                                                                       i_begindate      => i_dt_begin_tstz,
                                                                       i_enddate        => i_dt_end_tstz,
                                                                       i_vacancy        => i_flg_vacancy,
                                                                       --episodeid      => i_id_episode,
                                                                       i_requesttypeid => NULL, --i_flg_rqst_type, -- null e' temporario ate se resolver diferenca de datatype no MW
                                                                       i_schedulevia   => i_flg_sch_via,
                                                                       i_notes         => i_sch_notes,
                                                                       i_transaction   => i_transaction_id,
                                                                       o_schid       => o_id_schedule_ext);
        
            -- handle remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            
            END IF;
        END IF;
    
        -- assemble a procedure
        g_error                           := 'ASSEMBLE PROCEDURE';
        l_procedure.id_schedule_procedure := 1;
        l_procedure.id_content            := l_id_appointment;
        l_procedure.flg_sch_type          := l_sch_type;
        l_procedure.id_dcs_requested      := i_id_dep_clin_serv;
        l_procedures.extend;
        l_procedures(1) := l_procedure;
    
        -- assemble the procedure resources
        g_error                          := 'ASSEMBLE RESOURCES';
        l_resource.id_schedule_procedure := 1;
        l_resource.id_resource           := i_professional_id;
        l_resource.id_resource_type      := pk_schedule_api_downstream.g_res_type_prof;
        l_resource.dt_begin              := i_dt_begin_tstz;
        l_resource.dt_end                := i_dt_end_tstz;
        l_resource.flg_leader            := pk_alert_constant.g_no;
        l_resources.extend;
        l_resources(1) := l_resource;
    
        -- assemble person (the robot?)
        g_error                       := 'ASSEMBLE PERSON';
        l_person.id_schedule_person   := 1;
        l_person.id_patient           := i_id_patient;
        l_person.id_instit_requests   := nvl(i_id_inst_requests, i_prof.institution);
        l_person.id_dcs_requests      := i_id_dcs_requests;
        l_person.id_prof_requests     := i_id_prof_requests;
        l_person.id_prof_schedules    := nvl(i_id_prof_schedules, i_prof.id);
        l_person.notes                := i_sch_notes;
        l_person.id_lang_translator   := NULL;
        l_person.id_reason            := NULL;
        l_person.id_origin            := NULL;
        l_person.flg_notification     := NULL;
        l_person.dt_notification      := NULL;
        l_person.id_prof_notification := NULL;
        l_person.flg_notification_via := NULL;
        l_person.reason_notes         := NULL;
        l_person.dt_schedule          := g_sysdate_tstz;
        l_person.dt_request           := NULL;
        l_person.flg_request_type     := i_flg_rqst_type;
        l_person.flg_schedule_via     := i_flg_sch_via;
        l_persons.extend;
        l_persons(1) := l_person;
    
        -- assemble procedure request
        IF i_id_external_req IS NOT NULL
        THEN
            l_procedure_req.id_schedule_procedure := 1;
            l_procedure_req.id_schedule_person    := 1;
            l_procedure_req.id_patient            := i_id_patient;
            l_procedure_req.id_type               := pk_schedule_api_downstream.g_proc_req_type_ref;
            l_procedure_req.id                    := i_id_external_req;
            l_procedure_reqs.extend;
            l_procedure_reqs(1) := l_procedure_req;
        END IF;
    
        g_error := 'Call PK_SCHEDULE_API_DOWNSTREAM.CREATE_SCHEDULE';
        IF NOT pk_schedule_api_downstream.create_schedule(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_sch_ext          => o_id_schedule_ext,
                                                          i_flg_status          => pk_schedule.g_status_scheduled, -- em duvida. e' sempre agendado?
                                                          i_id_instit_requested => l_id_inst,
                                                          i_id_dep_requested    => l_id_dep,
                                                          i_flg_vacancy         => i_flg_vacancy,
                                                          i_procedures          => l_procedures,
                                                          i_resources           => l_resources,
                                                          i_persons             => l_persons,
                                                          i_procedure_reqs      => l_procedure_reqs,
                                                          i_id_episode          => i_id_episode,
                                                          i_id_sch_ref          => i_id_sch_ref,
                                                          i_dt_begin            => i_dt_begin_tstz,
                                                          i_dt_end              => i_dt_end_tstz,
                                                          i_dt_referral         => i_dt_referral,
                                                          o_ids_schedule        => o_ids_schedule,
                                                          o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CREATE_SCHEDULE ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_SCHEDULE',
                                              o_error    => o_error);
            --            do_rollback(i_transaction_id);    -- (telmo) em duvida
            RETURN FALSE;
    END create_schedule;

    /*
    * Creates an appointment in scheduler 3 and after the same appointment in pfh.
    * This version of create_schedule has support for appointments not found.
    * used in pk_ehr_access.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_event_id           Associated event id
    * @param i_professional_id    Physician id
    * @param i_id_patient         Patient id
    * @param i_id_dep_clin_serv   id dep clin serv
    * @param i_dt_begin_tstz      Appointment begin date
    * @parma i_dt_end_tstz        Appointment end date
    * @param i_flg_vacancy         Flag vacancy ( Type of vacancy occupied: 'R' routine, 'U' urgent, 'V' unplanned )
    * @param i_id_episode         Episode ids
    * @param i_flg_rqst_type      Appointment's request type (patient, physician, nurse, institution)
    * @param i_flg_sch_via        Scheduling by telephone contact
    * @param i_sch_notes          schedule notes
    * @param i_id_inst_requests   requesting instit
    * @param i_id_dcs_requests    requesting dcs
    * @param i_id_prof_requests    requesting prof
    * @param i_id_prof_schedules  scheduling prof
    * @param i_id_sch_ref         reference to this schedule
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_id_schedule         list of new PFH schedule ids
    * @param o_id_schedule_ext    new scheduler 3 id
    * @param o_flg_proceed        show stopper
    * @param o_flg_show           show stopper
    * @param o_msg_title          popup message title
    * @param o_msg                popup message message
    * @param o_button             popup buttons
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @since   23-04-2010
    */
    FUNCTION create_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_id          IN schedule.id_sch_event%TYPE,
        i_professional_id   IN professional.id_professional%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin_tstz     IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tstz       IN schedule.dt_end_tstz%TYPE,
        i_flg_vacancy       IN schedule.flg_vacancy%TYPE,
        i_id_episode        IN schedule.id_episode%TYPE,
        i_flg_rqst_type     IN schedule.flg_request_type%TYPE,
        i_flg_sch_via       IN schedule.flg_schedule_via%TYPE,
        i_sch_notes         IN schedule.schedule_notes%TYPE,
        i_id_inst_requests  IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_dcs_requests   IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_id_prof_requests  IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_sch_ref        IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_transaction_id    IN VARCHAR2,
        o_ids_schedule      OUT table_number,
        o_id_schedule_ext   OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_flg_proceed       OUT VARCHAR2,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg               OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_id_appointment appointment.id_appointment%TYPE;
        l_id_dep         dep_clin_serv.id_department%TYPE;
        l_id_inst        department.id_institution%TYPE;
        l_sch_type       sch_event.dep_type%TYPE;
        l_procedure      pk_schedule_api_downstream.t_procedure;
        l_procedures     pk_schedule_api_downstream.t_procedures := pk_schedule_api_downstream.t_procedures();
        l_person         pk_schedule_api_downstream.t_person;
        l_persons        pk_schedule_api_downstream.t_persons := pk_schedule_api_downstream.t_persons();
        l_resource       pk_schedule_api_downstream.t_resource;
        l_resources      pk_schedule_api_downstream.t_resources := pk_schedule_api_downstream.t_resources();
        -- l_procedure_req  pk_schedule_api_downstream.t_procedure_req;
        l_procedure_reqs pk_schedule_api_downstream.t_procedure_reqs := pk_schedule_api_downstream.t_procedure_reqs();
    
    BEGIN
        o_flg_show := pk_alert_constant.g_no;
    
        -- obter id_content a partir do evento e dcs
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_ID_CONTENT WITH i_event_id=' || to_char(i_event_id) ||
                   ', i_id_dep_clin_serv=' || to_char(i_id_dep_clin_serv);
    
        IF NOT pk_schedule_api_downstream.get_id_content(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_sch_event => i_event_id,
                                                         i_id_dcs       => i_id_dep_clin_serv,
                                                         o_id_content   => l_id_appointment,
                                                         o_flg_proceed  => o_flg_proceed,
                                                         o_flg_show     => o_flg_show,
                                                         o_msg_title    => o_msg_title,
                                                         o_msg          => o_msg,
                                                         o_button       => o_button,
                                                         o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            RETURN TRUE;
        END IF;
    
        -- obter inst e dep do dcs
        g_error := 'GET DEPARTMENT ID AND INSTITUTION ID WITH i_id_dep_clin_serv=' || to_char(i_id_dep_clin_serv);
        SELECT dcs.id_department, d.id_institution
          INTO l_id_dep, l_id_inst
          FROM dep_clin_serv dcs
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        -- obter sch type
        g_error := 'GET SCH TYPE FROM EVENT WITH i_event_id=' || to_char(i_event_id);
        SELECT dep_type
          INTO l_sch_type
          FROM sch_event
         WHERE id_sch_event = i_event_id;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error        := 'Call pk_schedule_rest_service.createschedule';
            l_obj_response := pk_schedule_rest_services.createschedule(i_lang           => i_lang,
                                                                      i_prof           => i_prof,                  
                                                                      i_personid       => i_id_patient,
                                                                      i_depcleanservid => i_id_dep_clin_serv,
                                                                      i_contentid      => l_id_appointment,
                                                                      i_professionalid => i_professional_id,
                                                                      i_begindate      => i_dt_begin_tstz,
                                                                      i_enddate        => i_dt_end_tstz,
                                                                      i_vacancy        => i_flg_vacancy,
                                                                      -- episodeid      => i_id_episode,
                                                                      i_requesttypeid => NULL, --i_flg_rqst_type, -- null e' temporario ate se resolver diferenca de datatype no MW
                                                                      i_schedulevia   => i_flg_sch_via,
                                                                      i_notes         => i_sch_notes,
                                                                      i_transaction   => i_transaction_id,
                                                                      o_schid       => o_id_schedule_ext);
        
            -- handle remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            END IF;
        END IF;
    
        -- assemble a procedure
        g_error := 'ASSEMBLE PROCEDURE';
    
        l_procedure.id_schedule_procedure := 1;
        l_procedure.id_content            := l_id_appointment;
        l_procedure.flg_sch_type          := l_sch_type;
        l_procedure.id_dcs_requested      := i_id_dep_clin_serv;
        l_procedures.extend;
        l_procedures(1) := l_procedure;
    
        -- assemble the procedure resources
        g_error                          := 'ASSEMBLE RESOURCES';
        l_resource.id_schedule_procedure := 1;
        l_resource.id_resource           := i_professional_id;
        l_resource.id_resource_type      := pk_schedule_api_downstream.g_res_type_prof;
        l_resource.dt_begin              := i_dt_begin_tstz;
        l_resource.dt_end                := i_dt_end_tstz;
        l_resource.flg_leader            := pk_alert_constant.g_no;
        l_resources.extend;
        l_resources(1) := l_resource;
    
        -- assemble person (the robot?)
        g_error                       := 'ASSEMBLE PERSON';
        l_person.id_schedule_person   := 1;
        l_person.id_patient           := i_id_patient;
        l_person.id_instit_requests   := nvl(i_id_inst_requests, i_prof.institution);
        l_person.id_dcs_requests      := i_id_dcs_requests;
        l_person.id_prof_requests     := i_id_prof_requests;
        l_person.id_prof_schedules    := nvl(i_id_prof_schedules, i_prof.id);
        l_person.notes                := i_sch_notes;
        l_person.id_lang_translator   := NULL;
        l_person.id_reason            := NULL;
        l_person.id_origin            := NULL;
        l_person.flg_notification     := NULL;
        l_person.dt_notification      := NULL;
        l_person.id_prof_notification := NULL;
        l_person.flg_notification_via := NULL;
        l_person.reason_notes         := NULL;
        l_person.dt_schedule          := g_sysdate_tstz;
        l_person.dt_request           := NULL;
        l_person.flg_request_type     := i_flg_rqst_type;
        l_person.flg_schedule_via     := i_flg_sch_via;
        l_persons.extend;
        l_persons(1) := l_person;
    
        g_error := 'Call PK_SCHEDULE_API_DOWNSTREAM.CREATE_SCHEDULE';
        IF NOT pk_schedule_api_downstream.create_schedule(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_id_sch_ext          => o_id_schedule_ext,
                                                          i_flg_status          => pk_schedule.g_status_scheduled, -- em duvida. e' sempre agendado?
                                                          i_id_instit_requested => l_id_inst,
                                                          i_id_dep_requested    => l_id_dep,
                                                          i_flg_vacancy         => i_flg_vacancy,
                                                          i_procedures          => l_procedures,
                                                          i_resources           => l_resources,
                                                          i_persons             => l_persons,
                                                          i_procedure_reqs      => l_procedure_reqs, -- e' uma consulta na hora por isso nao ha' requisicao
                                                          i_id_episode          => i_id_episode,
                                                          i_id_sch_ref          => i_id_sch_ref,
                                                          i_dt_begin            => i_dt_begin_tstz,
                                                          i_dt_end              => i_dt_end_tstz,
                                                          o_ids_schedule        => o_ids_schedule,
                                                          o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CREATE_SCHEDULE ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
        
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg       := 'PK_SCHEDULE_REST_SERVICES.CREATE_SCHEDULE ERROR';
            o_button    := pk_schedule.g_check_button;
            RETURN FALSE; -- atencao neste caso especifico ao contrario do habitual nestas popups tem de ser false
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_SCHEDULE',
                                              o_error    => o_error);
            --            do_rollback(i_transaction_id);    -- (telmo) em duvida
            RETURN FALSE;
        
    END create_schedule;

    /**
    * Schedules an intervention for a given schedule
    * Will be rethinked later. Function not in use currently.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional that requested the procedure scheduling
    * @param i_id_schedule                 Schedule identifier
    * @param i_institution_request         Institution where the request was created
    * @param i_institution_requested       Target institution where the procedure will take place
    * @param i_dcs_request_id              Dep_clin_serv associated with the request institution
    * @param i_dcs_requested_id            Dep_clin_serv associated with the target institution
    * @param i_content_id
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Carlos Nogueira
    * @version 1.0
    * @since   27-01-2009
    */

    FUNCTION create_schedule_intervention
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_schedule             IN schedule.id_schedule%TYPE,
        i_institution_request     IN institution.id_institution%TYPE,
        i_institution_requested   IN institution.id_institution%TYPE,
        i_dep_clin_serv_request   IN schedule.id_dcs_requests%TYPE,
        i_dep_clin_serv_requested IN schedule.id_dcs_requests%TYPE,
        i_reason_notes            IN schedule.reason_notes%TYPE,
        i_flg_urgency             IN schedule.flg_urgency%TYPE,
        i_flg_status              IN schedule.flg_status%TYPE,
        i_dt_begin_tstz           IN schedule.dt_begin_tstz%TYPE,
        i_dt_create_tstz          IN schedule.dt_schedule_tstz%TYPE,
        i_flg_schedule_type       IN schedule.flg_sch_type%TYPE,
        i_target_professional     IN professional.id_professional%TYPE,
        i_id_interv_presc_det     IN schedule_intervention.id_interv_presc_det%TYPE,
        i_transaction_id          IN VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CREATE_SCHEDULE_PROCEDURE';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_content_id_requested clinical_service.id_content%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT WITH i_id_schedule=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        --insere na tabela remota do scheduler
        g_error := 'CALL to pk_schedule_api_downstream.create_schedule';
        /* Agendamento de MFR irá ser refeito logo esta parte nao será testada */
    
        g_error := 'CALL to get_content_id';
        IF NOT get_interv_content_id(i_lang                => i_lang,
                                     i_id_interv_presc_det => i_id_interv_presc_det,
                                     o_content_id          => l_content_id_requested,
                                     o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL pk_schedule_rest_services.createscheduleprocedure / ID_SCHEDULE_INT = ' ||
                                  i_id_schedule || ' ID_SCHEDULE_EXT= ' || l_id_schedule_ext;
                l_obj_response := pk_schedule_rest_services.createscheduleprocedure(i_lang                   => i_lang,
                                                                                    i_prof                   => i_prof,
                                                                                    i_scheduleid             => l_id_schedule_ext,                                                                                 
                                                                                    i_institutionrequestsid  => i_institution_request,
                                                                                    i_institutionrequestedid => i_institution_requested,
                                                                                    i_dcsrequestsid          => i_dep_clin_serv_request,
                                                                                    i_dcsrequestedid         => i_dep_clin_serv_requested,
                                                                                    i_contentid              => l_content_id_requested,
                                                                                    i_professionalid         => i_target_professional, --NUMBER q id de profissional é este ??
                                                                                    --profschedulesid        => NULL, --NUMBER q id de profissional é este ??
                                                                                    i_reasonnotes  => i_reason_notes,
                                                                                    i_urgency      => i_flg_urgency,
                                                                                    i_begindate    => i_dt_begin_tstz,
                                                                                    i_creationdate => i_dt_create_tstz,
                                                                                    i_scehduletype => i_flg_schedule_type,
                                                                                    i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' l_id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CREATE_SCHEDULE_PROCEDURE ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
        
    END create_schedule_intervention;

    /*
    * Cancels an appointment.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_cancel_reason   Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param i_transaction_id     Scheduler transaction identifier
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Teste
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason  IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
        --l_sysdate_tstz TIMESTAMP WITH TIME ZONE;
        l_remote_exception EXCEPTION;
        l_id_patient sch_group.id_patient%TYPE;
    BEGIN
        -- obter id sch externo. Tem de estar fora do IF is_scheduler_installed
        g_error  := 'Call get_schedule_id_ext / id_schedule=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                -- obter o id_patient inhantes
                g_error := 'Get id_patient for id_schedule=' || i_id_schedule;
                SELECT id_patient
                  INTO l_id_patient
                  FROM sch_group s
                 WHERE s.id_schedule = i_id_schedule
                   AND rownum = 1;
            
                g_error := 'Call PK_SCHEDULE_REST_SERVICES.cancelschedule / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
            
                
                l_obj_response := pk_schedule_rest_services.cancelschedule(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_schid         => l_id_schedule_ext,
                                                                           i_idperson      => l_id_patient,
                                                                           i_cancelreason  => i_id_cancel_reason,
                                                                           i_cancelnotes   => i_cancel_notes,
                                                                           i_canceldate    => g_sysdate_tstz,
                                                                           i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        g_error := 'Call pk_schedule_api_downstream.cancel_schedule_internal';
        IF NOT pk_schedule_api_downstream.cancel_schedule_internal(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_schedule      => i_id_schedule,
                                                                   i_id_professional  => i_prof.id,
                                                                   i_id_cancel_reason => i_id_cancel_reason,
                                                                   i_cancel_notes     => i_cancel_notes,
                                                                   i_cancel_date      => g_sysdate_tstz,
                                                                   i_cancel_exam_req  => i_cancel_exam_req,
                                                                   i_updating         => pk_alert_constant.g_no,
                                                                   i_dt_referral      => i_dt_referral,
                                                                   i_referral_reason  => i_referral_reason,
                                                                   o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULE ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
            RETURN FALSE;
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_SCHEDULE',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_schedule;

    /*
    * Cancels a consult registration in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009
    */
    FUNCTION cancel_scheduler_registration
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'CANCEL_SCHEDULER_REGISTRATION';
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_obj_response    boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
    
        l_id_episode episode.id_episode%TYPE;
        l_id_ti_log  ti_log.id_ti_log%TYPE;
    BEGIN
       
    
        g_error := 'Call get_schedule_id_ext / id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error := 'GET ID_EPISODE WITH i_id_schedule=' || to_char(i_id_schedule);
                BEGIN
                    SELECT ei.id_episode
                      INTO l_id_episode
                      FROM epis_info ei
                     WHERE ei.id_schedule = i_id_schedule;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_episode := NULL;
                END;
            
                IF l_id_episode IS NOT NULL
                THEN
                    g_error := 'GET ID_TI_LOG FROM TI_LOG WITH ID_EPISODE= ' || to_char(l_id_episode) ||
                               ' AND ID_RECORD=' || to_char(i_id_schedule);
                    BEGIN
                        SELECT l.id_ti_log
                          INTO l_id_ti_log
                          FROM ti_log l
                         WHERE l.id_episode = l_id_episode
                           AND l.id_record = i_id_schedule
                           AND l.flg_type = 'SH';
                    
                        g_error := 'UPDATE TI_LOG WITH ID_EPISODE= ' || to_char(l_id_episode) || ' AND ID_RECORD=' ||
                                   to_char(i_id_schedule);
                        IF NOT t_ti_log.upd_log(i_lang       => i_lang,
                                                i_id_ti_log  => l_id_ti_log,
                                                i_id_episode => l_id_episode,
                                                i_prof       => i_prof,
                                                i_flg_status => pk_alert_constant.g_cancelled,
                                                i_id_record  => i_id_schedule,
                                                i_flg_type   => 'SH',
                                                o_error      => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_ti_log := NULL;
                    END;
                END IF;
            
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.cancelScheduleRegistration / ID_SCHEDULE_INT = ' ||
                                  i_id_schedule || ' ID_SCHEDULE_EXT= ' || l_id_schedule_ext;
                l_obj_response := pk_schedule_rest_services.cancelscheduleregistration(i_lang          => i_lang,
                                                                                     i_prof          => i_prof,               
                                                                                     i_schid         => l_id_schedule_ext,
                                                                                     i_personid      => i_id_patient,
                                                                                     i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_warn(text        => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULEREGISTRATION ERROR -> no external schedule id found for internal id ' ||
                                                i_id_schedule,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULEREGISTRATION ERROR ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END cancel_scheduler_registration;

    /*
    * Cancels a consult registration in the scheduler. New version of cancel_scheduler_registration function
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   24-05-2011
    */
    FUNCTION cancel_registration_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'CANCEL_REGISTRATION_NO_TRANS';
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_obj_response    boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
    BEGIN
    
        g_error := 'Call get_schedule_id_ext / id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
            
                g_error := 'GET_TRANSACTION';
                get_transaction(i_prof);
            
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.cancelScheduleRegistration / ID_SCHEDULE_INT = ' ||
                                  i_id_schedule || ' ID_SCHEDULE_EXT= ' || l_id_schedule_ext;
                l_obj_response := pk_schedule_rest_services.cancelscheduleregistration(i_lang          => i_lang,
                                                                                       i_prof          => i_prof,
                                                                                       i_schid         => l_id_schedule_ext,
                                                                                       i_personid      => i_id_patient,
                                                                                       i_transaction   => g_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_warn(text        => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULEREGISTRATION ERROR -> no external schedule id found for internal id ' ||
                                                i_id_schedule,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULEREGISTRATION ERROR ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END cancel_registration_no_trans;

    /**
    * Confirms a patient for a given schedule
    *
    */

    FUNCTION confirm_person
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_prof_confirm   IN profissional,
        i_confirm_date   IN schedule.dt_begin_tstz%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CONFIRM_PERSON';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT / ID_SCHEDULE=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL pk_schedule_rest_services.confirmperson / ID_SCHEDULE_INT = ' || i_id_schedule ||
                                  ' ID_SCHEDULE_EXT= ' || l_id_schedule_ext;
                l_obj_response := pk_schedule_rest_services.confirmperson(i_lang                  => i_lang,
                                                                          i_prof                  => i_prof,                        
                                                                          i_scheduleid            => l_id_schedule_ext,
                                                                          i_personid              => i_id_patient,
                                                                          i_professionalidconfirm => i_prof_confirm.id,
                                                                          i_confirmationdate      => i_confirm_date,
                                                                          i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CONFIRMPERSON ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
        
    END confirm_person;

    /*
    * Confirms a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION confirm_pending_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_id_schedule    OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CONFIRM_PENDING_SCHED';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT / ID_SCHEDULE=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.CONFIRMPENDINGSCHEDULE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                                  ' ID_SCHEDULE_EXT= ' || l_id_schedule_ext;
                l_obj_response := pk_schedule_rest_services.confirmpendingschedule(i_lang          => i_lang,
                                                                                   i_prof          => i_prof,                   
                                                                                   i_schid         => l_id_schedule_ext,
                                                                                   i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        -- FALTA FAZER O MESMO NA SCHEDULE LOCAL - FLG_STATUS = A
        g_error := 'SET SCHEDULE.FLG_STATUS TO ' || pk_schedule.g_sched_status_scheduled || ' WITH i_id_schedule=' ||
                   to_char(i_id_schedule);
        UPDATE schedule
           SET flg_status = pk_schedule.g_sched_status_scheduled
         WHERE id_schedule = i_id_schedule;
    
        o_id_schedule := l_id_schedule_ext;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CONFIRMPENDINGSCHEDULE ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END confirm_pending_sched;

    /*
    * Confirms a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION confirm_pending_sched
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_schedule_ext IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'CONFIRM_PENDING_SCHED';
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_ids_sch_pfh table_number;
    BEGIN
    
        -- get internal ids
        g_error       := 'CALL PK_SCHEDULE_API_DOWNSTREAM.GET_PFH_IDS WITH i_id_schedule_ext=' || i_id_schedule_ext;
        l_ids_sch_pfh := pk_schedule_api_downstream.get_pfh_ids(i_id_schedule_ext);
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.CONFIRMPENDINGSCHEDULE WITH ID_SCHEDULE_EXT= ' || i_id_schedule_ext;
            l_obj_response := pk_schedule_rest_services.confirmpendingschedule(i_lang          => i_lang,
                                                                               i_prof        => i_prof,                 
                                                                               i_schid         => i_id_schedule_ext,
                                                                               i_transaction   => i_transaction_id);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE id_schedule_ext= ' || i_id_schedule_ext;
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            END IF;
        END IF;
    
        -- FALTA FAZER O MESMO NA SCHEDULE LOCAL - FLG_STATUS = A
        g_error := 'SET SCHEDULE.FLG_STATUS NEW STATUS';
        UPDATE schedule
           SET flg_status = pk_schedule.g_sched_status_scheduled
         WHERE id_schedule IN (SELECT column_value
                                 FROM TABLE(l_ids_sch_pfh));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.CONFIRMPENDINGSCHEDULE ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END confirm_pending_sched;

    /*
    * Commits a remote transaction
    *
    * @param i_id_transaction     Language identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009
    */
    PROCEDURE do_commit
    (
        i_id_transaction IN VARCHAR2,
        i_prof           IN profissional DEFAULT NULL
    ) IS
      l_language NUMBER;
    BEGIN
         IF  i_id_transaction IS NOT NULL
        THEN
            g_error := '[SCHED COMMIT] CALL PK_REST_API.COMMITTRANSACTION with i_id_transaction = ' || i_id_transaction;
            l_language := get_language_from_prof(i_prof);
            IF NOT pk_rest_api.committransaction(
                                          i_lang        => l_language,
                                          i_prof        => i_prof,
                                          i_transaction => i_id_transaction) THEN
               pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
             END IF;
        END IF;
    END do_commit;

    /*
    * Commits a remote transaction
    *
    * @param i_prof
    *
    * @author  Telmo Castro
    * @version 2.6.0.5
    * @date     18-03-2011
    */
    PROCEDURE do_commit(i_prof IN profissional DEFAULT NULL) IS
      l_language NUMBER;
    BEGIN
        IF  g_transaction_id IS NOT NULL
        THEN
            g_error := '[SCHED COMMIT] CALL PK_REST_API.COMMITTRANSACTION without i_id_transaction';
            l_language := get_language_from_prof(i_prof);
            IF NOT pk_rest_api.committransaction(
										  i_lang        => l_language,
										  i_prof        => i_prof,
										  i_transaction => g_transaction_id) THEN
              g_transaction_id := NULL;
              pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
            END IF;
            g_transaction_id := NULL;
        END IF;
    END do_commit;

    /*
    * Rollback a remote transaction
    *
    * @param i_id_transaction     Language identifier
    *
    * @author  Sérgio Santos / Telmo Castro
    * @version 1.0
    * @since   25-11-2009
    */
    PROCEDURE do_rollback
    (
        i_id_transaction IN VARCHAR2,
        i_prof           IN profissional DEFAULT NULL
    ) IS
      l_language NUMBER;
    BEGIN
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
           AND i_id_transaction IS NOT NULL
        THEN
            g_error := '[SCHED ROLLBACK] CALL PK_REST_API.ROLLBACKTRANSACTION with i_id_transaction = ' || i_id_transaction;
            l_language := get_language_from_prof(i_prof);
            IF NOT pk_rest_api.rollbacktransaction(i_lang        => l_language,
												   i_prof        => i_prof,
												   i_transaction => i_id_transaction) THEN
              pk_alertlog.log_error(g_error);                                    
            END IF;
        END IF;
    END do_rollback;

    /*
    * Rollback a remote transaction
    *
    * @param i_prof
    *
    * @author  Telmo Castro
    * @version 2.6.0.5
    * @date    18-03-2011
    */
    PROCEDURE do_rollback(i_prof IN profissional DEFAULT NULL) IS
      l_language NUMBER;
    BEGIN
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
           AND g_transaction_id IS NOT NULL
        THEN
            g_error := '[SCHED ROLLBACK] CALL PK_REST_API.ROLLBACK without i_id_transaction';
            l_language := get_language_from_prof(i_prof);
            IF NOT pk_rest_api.rollbacktransaction(i_lang        => l_language,
												   i_prof        => i_prof,
												   i_transaction => g_transaction_id) THEN
               pk_alertlog.log_error(g_error);                                                                         
            END IF;
        END IF;
    END do_rollback;

    /*
    * Sets a schedule bed.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_id_patient                  Patient identifier
    * @param i_flg_notification_via        Nitification via
    * @param i_flg_notification_via        Professional notification identifier (ID)
    * @param i_dt_notification             Date of notification
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009
    */
    FUNCTION notify_person
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_flg_notification_via IN sys_domain.val%TYPE,
        i_id_professional      IN professional.id_professional%TYPE,
        i_dt_notification      IN schedule.dt_notification_tstz%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'NOTIFY_PERSON';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT WITH I_ID_SCHEDULE=' || to_char(i_id_schedule);
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.NOTIFYPERSON WITH l_id_schedule_ext= ' || l_id_schedule_ext ||
                                  ', i_id_patient= ' || i_id_patient || ', i_flg_notification_via= ' ||
                                  i_flg_notification_via || ', i_id_professional= ' || i_id_professional ||
                                  ', i_dt_notification= ' || i_dt_notification;
                l_obj_response := pk_schedule_rest_services.notifyperson(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_schid            => l_id_schedule_ext,
                                                                         i_personid         => i_id_patient,
                                                                         i_notificationvia  => i_flg_notification_via,
                                                                         i_professionalid   => i_id_professional,
                                                                         i_notificationdate => i_dt_notification,
                                                                         i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.NOTIFYPERSON ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END notify_person;

    /*
    * Reactivates a previously cancelled schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION reactivate_canceled_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'REACTIVATE_CANCELED_SCHED';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT WITH i_id_schedule=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL PK_SCHEDULE_REST_API.REACTIVATECANCELEDSCHEDULE WITH l_id_schedule_ext= ' ||
                                  l_id_schedule_ext || ' i_transaction_id= ' || i_transaction_id;
                l_obj_response := pk_schedule_rest_services.reactivatecanceledschedule(i_lang          => i_lang,
                                                                                       i_prof          => i_prof,
                                                                                       i_schid         => l_id_schedule_ext,
                                                                                       i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.REACTIVATECANCELEDSCHEDULE ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END reactivate_canceled_sched;

    /* re-schedules an intervention for a given schedule it *
    * Will be rethinked later. Function not in use currently.*/
    FUNCTION recreate_schedule_intervention
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_schedule             IN schedule.id_schedule%TYPE,
        i_old_id_schedule         IN schedule.id_schedule%TYPE,
        i_institution_request     IN institution.id_institution%TYPE,
        i_institution_requested   IN institution.id_institution%TYPE,
        i_dep_clin_serv_request   IN schedule.id_dcs_requests%TYPE,
        i_dep_clin_serv_requested IN schedule.id_dcs_requests%TYPE,
        i_reason_notes            IN schedule.reason_notes%TYPE,
        i_dt_begin_tstz           IN schedule.dt_begin_tstz%TYPE,
        i_dt_create_tstz          IN schedule.dt_schedule_tstz%TYPE,
        i_id_interv_presc_det     IN schedule_intervention.id_interv_presc_det%TYPE,
        i_transaction_id          IN VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'RECREATE_SCHEDULE_PROCEDURE';
    
        --l_content_id_requested clinical_service.id_content%TYPE;
        l_flg_urgency schedule.flg_urgency%TYPE;
        l_flg_status  schedule.flg_status%TYPE;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- recreate schedule with new values
            g_error := 'Select flg_status, flg_urgency FROM schedule WITH i_old_id_schedule=' || i_old_id_schedule;
            SELECT flg_status, flg_urgency
              INTO l_flg_status, l_flg_urgency
              FROM schedule s
             WHERE s.id_schedule = i_old_id_schedule;
        
            --insere na tabela remota do scheduler
            g_error := 'Call to pk_schedule_api_upstream.create_schedule_intervention';
            IF NOT pk_schedule_api_upstream.create_schedule_intervention(i_lang                    => i_lang,
                                                                         i_prof                    => i_prof,
                                                                         i_id_schedule             => i_id_schedule,
                                                                         i_institution_request     => i_prof.institution,
                                                                         i_institution_requested   => i_prof.institution,
                                                                         i_dep_clin_serv_request   => i_dep_clin_serv_request,
                                                                         i_dep_clin_serv_requested => i_dep_clin_serv_requested,
                                                                         i_reason_notes            => i_reason_notes,
                                                                         i_flg_urgency             => l_flg_urgency,
                                                                         i_flg_status              => l_flg_status,
                                                                         i_dt_begin_tstz           => i_dt_begin_tstz,
                                                                         i_dt_create_tstz          => i_dt_create_tstz,
                                                                         i_flg_schedule_type       => NULL,
                                                                         i_target_professional     => i_prof.id,
                                                                         i_id_interv_presc_det     => i_id_interv_presc_det,
                                                                         i_transaction_id          => i_transaction_id,
                                                                         o_error                   => o_error)
            THEN
                RAISE g_exception;
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
        
    END recreate_schedule_intervention;
    /*
    * Removes a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION remove_pending_sched
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'REMOVE_PENDING_SCHED';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        g_error  := 'CALL GET_SCHEDULE_ID_EXT WITH i_id_schedule=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.REMOVEPENDINGSCHEDULE WITH l_id_schedule_ext= ' ||
                                  l_id_schedule_ext || ', i_transaction_id= ' || i_transaction_id;
                l_obj_response := pk_schedule_rest_services.removependingschedule(i_lang          => i_lang,
                                                                                  i_prof          => i_prof,
                                                                                  i_schid         => l_id_schedule_ext,
                                                                                  i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.REMOVEPENDINGSCHEDULE ERROR' ,
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END remove_pending_sched;

    /*
    * Registers a consult in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009
    */
    FUNCTION register_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'REGISTER_SCHEDULE';
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_obj_response    boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
    
        l_id_episode episode.id_episode%TYPE;
        l_id_ti_log  ti_log.id_ti_log%TYPE;
    BEGIN
    
        g_error := 'Call get_schedule_id_ext WITH i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error := 'GET ID_EPISODE WITH i_id_schedule=' || to_char(i_id_schedule);
                BEGIN
                    SELECT ei.id_episode
                      INTO l_id_episode
                      FROM epis_info ei
                     WHERE ei.id_schedule = i_id_schedule;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_episode := NULL;
                END;
            
                IF l_id_episode IS NOT NULL
                THEN
                    g_error := 'GET ID_TI_LOG WITH ID_EPISODE=' || to_char(l_id_episode) || ' AND ID_RECORD=' ||
                               to_char(i_id_schedule);
                    BEGIN
                        SELECT l.id_ti_log
                          INTO l_id_ti_log
                          FROM ti_log l
                         WHERE l.id_episode = l_id_episode
                           AND l.id_record = i_id_schedule
                           AND l.flg_type = 'SH';
                    
                        g_error := 'UPDATE TI_LOG';
                        IF NOT t_ti_log.upd_log(i_lang       => i_lang,
                                                i_id_ti_log  => l_id_ti_log,
                                                i_id_episode => l_id_episode,
                                                i_prof       => i_prof,
                                                i_flg_status => pk_alert_constant.g_active,
                                                i_id_record  => i_id_schedule,
                                                i_flg_type   => 'SH',
                                                o_error      => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            g_error := 'INSERT INTO TI_LOG';
                            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => l_id_episode,
                                                    i_flg_status => pk_alert_constant.g_active,
                                                    i_id_record  => i_id_schedule,
                                                    i_flg_type   => 'SH',
                                                    o_error      => o_error)
                            THEN
                                RAISE l_remote_exception;
                            END IF;
                    END;
                END IF;
            
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.registerSchedule WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_transaction_id= ' || i_transaction_id || ', i_id_patient=' ||
                                  i_id_patient;
                l_obj_response := pk_schedule_rest_services.registerschedule(i_lang          => i_lang,
                                                                             i_prof          => i_prof,                                                                            
                                                                             i_schid         => l_id_schedule_ext,
                                                                             i_personid      => i_id_patient,
                                                                             i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_warn(text        => 'PK_SCHEDULE_REST_SERVICES.REGISTERSCHEDULE ERROR -> no external schedule id found for internal id ' ||
                                                i_id_schedule,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.REGISTERSCHEDULE ERROR',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END register_schedule;

    /*
    * Registers a consult in the scheduler. New version of register_schedule function
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_patient         Patient id
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   24-05-2011
    */
    FUNCTION register_schedule_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'REGISTER_SCHEDULE_NO_TRANS';
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_obj_response    boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
    BEGIN
    
        g_error := 'Call get_schedule_id_ext WITH i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error := 'GET_TRANSACTION';
                get_transaction(i_prof);
            
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.registerSchedule WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_id_patient=' || i_id_patient;
                l_obj_response := pk_schedule_rest_services.registerschedule(i_lang          => i_lang,
                                                                             i_prof          => i_prof,
                                                                             i_schid         => l_id_schedule_ext,
                                                                             i_personid      => i_id_patient,
                                                                             i_transaction   => g_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_warn(text        => 'PK_SCHEDULE_REST_SERVICES.REGISTERSCHEDULE ERROR -> no external schedule id found for internal id ' ||
                                                i_id_schedule,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.REGISTERSCHEDULE ERROR',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END register_schedule_no_trans;

    /*
    * Sets the consult state in the scheduler
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_flg_state          Flag of the consult status (SCHEDULE_OUTP.FLG_STATE sys_domain)
    * @param i_id_patient         Patient id
    * @param i_transaction_id     Transaction identifier (if already got one)
    * @param o_error              Error object
    *
    * @return TRUE if sucess, FALSE otherwise
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009
    */
    FUNCTION set_schedule_consult_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_state      IN schedule_outp.flg_state%TYPE,
        i_id_patient     IN patient.id_patient%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'SET_SCHEDULE_CONSULT_STATE';
        l_ids_patient table_number;
        i             PLS_INTEGER;
        l_remote_exception EXCEPTION;
    BEGIN
    
        --to avoid unnecessary SCH 3.0 calls
        IF i_id_schedule = -1
        THEN
            RETURN TRUE;
        END IF;
    
        --se nao for fornecido id do paciente , tenta obter
        IF i_id_patient IS NULL
        THEN
            g_error := 'No patient found for id_schedule = ' || i_id_schedule;
            SELECT sg.id_patient
              BULK COLLECT
              INTO l_ids_patient
              FROM sch_group sg
             WHERE sg.id_schedule = i_id_schedule;
        ELSE
            l_ids_patient := table_number(i_id_patient);
        END IF;
    
        IF l_ids_patient IS NOT NULL
           AND l_ids_patient.count > 0
        THEN
            i := l_ids_patient.first;
            WHILE i IS NOT NULL
            LOOP
                -- switching SCHEDULE_OUTP.FLG_STATE possibilities
                CASE i_flg_state
                    WHEN pk_schedule_api_upstream.g_flg_state_pat_waiting THEN
                    
                        -- first update locally
                        g_error := 'UPDATING SCHEDULE_OUTP SET flg_state=' ||
                                   pk_schedule_api_upstream.g_flg_state_pat_waiting || 'WHERE id_schedule=' ||
                                   i_id_schedule;
                        ts_schedule_outp.upd(flg_state_in => pk_schedule_api_upstream.g_flg_state_pat_waiting,
                                             where_in     => 'id_schedule = ' || to_char(i_id_schedule));
                    
                        -- then update remotelly
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.REGISTER_SCHEDULE WITH i_id_schedule=' ||
                                   i_id_schedule || ', l_ids_patient(i)=' || l_ids_patient(i) || ', i_transaction_id=' ||
                                   i_transaction_id;
                        IF NOT pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_id_schedule    => i_id_schedule,
                                                                          i_id_patient     => l_ids_patient(i),
                                                                          i_transaction_id => i_transaction_id,
                                                                          o_error          => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    
                    WHEN pk_schedule_api_upstream.g_flg_state_scheduled THEN
                    
                        -- first update locally
                        g_error := 'UPDATE SCHEDULE_OUTP SET flg_state=' ||
                                   pk_schedule_api_upstream.g_flg_state_scheduled || 'WHERE id_schedule=' ||
                                   i_id_schedule;
                        ts_schedule_outp.upd(flg_state_in => pk_schedule_api_upstream.g_flg_state_scheduled,
                                             where_in     => 'id_schedule = ' || to_char(i_id_schedule));
                    
                        -- then update remotelly
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULER_REGISTRATION WITH i_id_schedule=' ||
                                   i_id_schedule || ', l_ids_patient(i)=' || l_ids_patient(i) || ', i_transaction_id=' ||
                                   i_transaction_id;
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULER_REGISTRATION';
                        IF NOT pk_schedule_api_upstream.cancel_scheduler_registration(i_lang           => i_lang,
                                                                                      i_prof           => i_prof,
                                                                                      i_id_schedule    => i_id_schedule,
                                                                                      i_id_patient     => l_ids_patient(i),
                                                                                      i_transaction_id => i_transaction_id,
                                                                                      o_error          => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    WHEN pk_schedule_api_upstream.g_flg_state_noshow THEN
                        --
                        g_error := 'Do nothing';
                    ELSE
                        -- update schedule state for the non treated cases
                        g_error := 'UPDATING FLG_STATE FOR i_id_schedule = ' || i_id_schedule || ' TO ''' ||
                                   i_flg_state || '''';
                        ts_schedule_outp.upd(flg_state_in => i_flg_state,
                                             where_in     => 'id_schedule = ' || to_char(i_id_schedule) ||
                                                             ' and flg_state <> ''' || i_flg_state || '''');
                    
                END CASE;
                i := l_ids_patient.next(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_remote_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_schedule_consult_state;

    /*
    * Sets the consult state in the scheduler. New version of set_schedule_consult_state function
    * that follows alert-167145 rules
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_flg_state          Flag of the consult status (SCHEDULE_OUTP.FLG_STATE sys_domain)
    * @param i_id_patient
    * @param o_error              Error object
    *
    * @return TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.1
    * @date    24-05-2011
    */
    FUNCTION set_consult_state_no_trans
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_state   IN schedule_outp.flg_state%TYPE,
        i_id_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'SET_CONSULT_STATE_NO_TRANS';
        l_ids_patient table_number;
        i             PLS_INTEGER;
        l_remote_exception EXCEPTION;
    BEGIN
    
        --to avoid unnecessary SCH 3.0 calls
        IF i_id_schedule = -1
        THEN
            RETURN TRUE;
        END IF;
    
        --se nao for fornecido id do paciente , tenta obter
        IF i_id_patient IS NULL
        THEN
            g_error := 'No patient found for id_schedule = ' || i_id_schedule;
            SELECT sg.id_patient
              BULK COLLECT
              INTO l_ids_patient
              FROM sch_group sg
             WHERE sg.id_schedule = i_id_schedule;
        ELSE
            l_ids_patient := table_number(i_id_patient);
        END IF;
    
        IF l_ids_patient IS NOT NULL
           AND l_ids_patient.count > 0
        THEN
            i := l_ids_patient.first;
            WHILE i IS NOT NULL
            LOOP
                -- switching SCHEDULE_OUTP.FLG_STATE possibilities
                CASE i_flg_state
                    WHEN pk_schedule_api_upstream.g_flg_state_pat_waiting THEN
                    
                        -- first update locally
                        g_error := 'UPDATING SCHEDULE_OUTP SET flg_state=' ||
                                   pk_schedule_api_upstream.g_flg_state_pat_waiting || 'WHERE id_schedule=' ||
                                   i_id_schedule;
                        UPDATE schedule_outp
                           SET flg_state = pk_schedule_api_upstream.g_flg_state_pat_waiting
                         WHERE id_schedule = i_id_schedule;
                    
                        -- then update remotelly
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.REGISTER_SCHEDULE WITH i_id_schedule=' ||
                                   i_id_schedule || ', l_ids_patient(i)=' || l_ids_patient(i);
                        IF NOT pk_schedule_api_upstream.register_schedule_no_trans(i_lang        => i_lang,
                                                                                   i_prof        => i_prof,
                                                                                   i_id_schedule => i_id_schedule,
                                                                                   i_id_patient  => l_ids_patient(i),
                                                                                   o_error       => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    
                    WHEN pk_schedule_api_upstream.g_flg_state_scheduled THEN
                    
                        -- first update locally
                        g_error := 'UPDATE SCHEDULE_OUTP SET flg_state=' ||
                                   pk_schedule_api_upstream.g_flg_state_scheduled || 'WHERE id_schedule=' ||
                                   i_id_schedule;
                        UPDATE schedule_outp
                           SET flg_state = pk_schedule_api_upstream.g_flg_state_scheduled
                         WHERE id_schedule = i_id_schedule;
                    
                        -- then update remotelly
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULER_REGISTRATION WITH i_id_schedule=' ||
                                   i_id_schedule || ', l_ids_patient(i)=' || l_ids_patient(i);
                        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULER_REGISTRATION';
                        IF NOT pk_schedule_api_upstream.cancel_registration_no_trans(i_lang        => i_lang,
                                                                                     i_prof        => i_prof,
                                                                                     i_id_schedule => i_id_schedule,
                                                                                     i_id_patient  => l_ids_patient(i),
                                                                                     o_error       => o_error)
                        THEN
                            RAISE l_remote_exception;
                        END IF;
                    WHEN pk_schedule_api_upstream.g_flg_state_noshow THEN
                        --
                        g_error := 'Do nothing';
                    ELSE
                        -- update schedule state for the non treated cases
                        g_error := 'UPDATING FLG_STATE FOR i_id_schedule = ' || i_id_schedule || ' TO ''' ||
                                   i_flg_state || '''';
                        UPDATE schedule_outp so
                           SET so.flg_state = i_flg_state
                         WHERE so.id_schedule = i_id_schedule
                           AND so.flg_state <> i_flg_state;
                END CASE;
                i := l_ids_patient.next(i);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_remote_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_consult_state_no_trans;

    /*
    * Sets a schedule bed.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_bed             Bed identifier
    * @param i_dt_new_end_date    Bed schedule new end date
    * @param i_transaction_id     Scheduler transaction identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009
    */
    FUNCTION set_schedule_bed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        i_id_bed          IN bed.id_bed%TYPE,
        i_dt_new_end_date IN schedule.dt_end_tstz%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_SCHEDULE_BED';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    
        l_old_date_tstz schedule.dt_end_tstz%TYPE;
    BEGIN
    
        g_error  := 'Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => i_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error := 'GET dt_end_tstz FROM SCHEDULE WHERE i_id_schedule=' || i_id_schedule;
                SELECT s.dt_end_tstz
                  INTO l_old_date_tstz
                  FROM schedule s
                 WHERE s.id_schedule = i_id_schedule;
            
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.updateScheduleBed WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_id_bed= ' || i_id_bed || ', l_old_date_tstz=' ||
                                  l_old_date_tstz || ', i_dt_new_end_date=' || i_dt_new_end_date ||
                                  ', i_transaction_id=' || i_transaction_id;
                l_obj_response := pk_schedule_rest_services.updateschedulebed(i_lang          => i_lang,
                                                                              i_prof          => i_prof,
                                                                              i_schid         => l_id_schedule_ext,
                                                                              i_bedid         => i_id_bed,
                                                                              i_olddate       => l_old_date_tstz,
                                                                              i_newdate       => i_dt_new_end_date,
                                                                              i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.UPDATESCHEDULEBED ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END set_schedule_bed;

    /**
     * Muda o agendamento associado a um paciente para outro.
     * Apenas usado nos agendamentos do ORIS(schedule_sr),
     * em que um id_schedule associado a um episodio temporario passa a estar associado
     * a um novo id_episode definitivo.
     *
     * @param i_lang               Language identifier
     * @param i_prof               Professional data: id, institution and software
     * @param i_id_schedule        Schedule identifier
     * @param i_id_patient_add     Patient to add to the new scheduler
     * @param i_id_patient_rem     Patient to remove from scheduler
     * @param i_transaction_id     Scheduler transaction identifier
     * @param o_error               An error message, set when return=false
     *
     * @RETURN  TRUE if sucess, FALSE otherwise
     * @author  Carlos Nogueira
     * @version 1.0
     * @since   28-01-2010
    */
    FUNCTION update_schedule_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient_add IN patient.id_patient%TYPE,
        i_id_patient_rem IN patient.id_patient%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'UPDATE_SCHEDULE_PATIENT';
    
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_id_schedule     schedule_sr.id_schedule%TYPE;
    
        l_obj_response boolean;
    
        l_remote_exception EXCEPTION;
    
    BEGIN
    
        -- obtem o id_schedule a partir do id do episodio
        g_error := 'SELECT id_schedule FROM schedule_sr WHERE i_id_episode=' || i_id_episode;
        SELECT id_schedule
          INTO l_id_schedule
          FROM schedule_sr
         WHERE id_episode = i_id_episode;
    
        g_error  := 'Call get_schedule_id_ext with l_id_schedule=' || l_id_schedule;
        g_retval := get_schedule_id_ext(i_lang        => i_lang,
                                        i_id_schedule => l_id_schedule,
                                        o_id_schedule => l_id_schedule_ext,
                                        o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.updateSchedulePatient with l_id_schedule_ext= ' ||
                                  l_id_schedule_ext || ', i_transaction_id= ' || i_transaction_id ||
                                  ', i_id_patient_rem= ' || i_id_patient_rem || ', i_id_patient_add= ' ||
                                  i_id_patient_add;
                l_obj_response := pk_schedule_rest_services.updateschedulepatient(i_lang            => i_lang,
                                                                                  i_prof            => i_prof,
                                                                                  i_scheduleid      => l_id_schedule_ext,
                                                                                  i_patienttoremove => i_id_patient_rem,
                                                                                  i_patienttoadd    => i_id_patient_add,
                                                                                  i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || l_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        -- deletes the schedule associated with the temporary patient
        g_error := 'Call to pk_schedule_api_downstream.update_schedule_patient with l_id_schedule=' || l_id_schedule;
        IF NOT pk_schedule_api_downstream.update_schedule_patient(i_lang        => i_lang,
                                                                  i_id_schedule => l_id_schedule,
                                                                  o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.UPDATESCHEDULEPATIENT ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END update_schedule_patient;


    /**
     * @param i_lang               Language identifier
     * @param i_prof               Professional data: id, institution and software
     * @param i_id_schedule        Schedule identifier
     * @param i_dep_clin_serv_old   Id que permite obtencao do id_content
     * @param i_dep_clin_serv_new   Id que permite obtencao do id_content
     * @param i_transaction_id     Scheduler transaction identifier
     * @param o_error               An error message, set when return=false
     *
     * @RETURN  TRUE if sucess, FALSE otherwise
     * @author  Carlos Nogueira
     * @version 1.0
     * @since   28-01-2010
    */
    FUNCTION update_sch_proc_and_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin_tstz    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tszt      IN schedule.dt_end_tstz%TYPE,
        i_dep_clin_serv    IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_request_type IN schedule.flg_request_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'UPDATE_SCH_PROC_AND_DATES';
        l_id_schedule_ext   sch_api_map_ids.id_schedule_ext%TYPE;
        l_old_dep_clin_serv dep_clin_serv.id_clinical_service%TYPE;
        l_old_flg_req_type  schedule.flg_request_type%TYPE;
        l_old_dt_begin_tstz schedule.dt_begin_tstz%TYPE;
        l_old_dt_end_tstz   schedule.dt_end_tstz%TYPE;
        l_id_sch_event      schedule.id_sch_event%TYPE;
        l_id_content_new    VARCHAR2(200); -- nao e' strong typed porque tem mais de 1 origem
        l_obj_response      boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
    
    BEGIN
    
        g_error := 'Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- obtencao do valores actuais
        g_error := l_func_name || ' - get current schedule values with i_id_schedule=' || i_id_schedule;
        SELECT s.id_dcs_requested, s.id_sch_event, s.flg_request_type, s.dt_begin_tstz, s.dt_end_tstz
          INTO l_old_dep_clin_serv, l_id_sch_event, l_old_flg_req_type, l_old_dt_begin_tstz, l_old_dt_end_tstz
          FROM schedule s
         WHERE s.id_schedule = i_id_schedule;
    
        -- leave if nothing changed
        IF l_old_dep_clin_serv = i_dep_clin_serv
           AND l_old_flg_req_type = i_flg_request_type
           AND l_old_dt_begin_tstz = i_dt_begin_tstz
           AND l_old_dt_end_tstz = i_dt_end_tszt
        THEN
            RETURN TRUE;
        END IF;
    
        -- actualizacao das antigas tabelas do schedules
        g_error := 'Call to pk_schedule_api_downstream.update_sch_proc_and_dates with i_id_schedule=' || i_id_schedule ||
                   ', i_dt_begin_tstz= ' || i_dt_begin_tstz || ', i_dt_end_tszt= ' || i_dt_end_tszt ||
                   ', i_dep_clin_serv= ' || i_dep_clin_serv || ', i_flg_request_type=' || i_flg_request_type;
        IF NOT pk_schedule_api_downstream.update_sch_proc_and_dates(i_lang             => i_lang,
                                                                    i_id_schedule      => i_id_schedule,
                                                                    i_dt_begin_tstz    => i_dt_begin_tstz,
                                                                    i_dt_end_tszt      => i_dt_end_tszt,
                                                                    i_dep_clin_serv    => i_dep_clin_serv,
                                                                    i_flg_request_type => i_flg_request_type,
                                                                    o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- remote operations start here
        IF l_id_schedule_ext IS NOT NULL
           AND is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
        
            -- obtencao do id_content para o dep clin serv new
            g_error := l_func_name || ' - Call pk_schedule_api_downstream.get_id_content with i_id_sch_event' ||
                       l_id_sch_event || ', i_id_dcs=' || i_dep_clin_serv;
            IF NOT pk_schedule_api_downstream.get_id_content(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_id_sch_event => l_id_sch_event,
                                                             i_id_dcs       => i_dep_clin_serv,
                                                             o_id_content   => l_id_content_new,
                                                             o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error        := 'Call PK_SCHEDULE_REST_SERVICES.UPDATESCHPROCEDUREANDDATES with l_id_schedule_ext= ' ||
                              l_id_schedule_ext || ', i_transaction_id= ' || i_transaction_id || ', contentid= ' ||
                              l_id_content_new || ', depclinservid=' || i_dep_clin_serv || ', profid= ' || i_prof.id ||
                              ', begindate= ' || i_dt_begin_tstz || ', enddate= ' || i_dt_end_tszt ||
                              ', requestedtype= ' || i_flg_request_type;
            l_obj_response := pk_schedule_rest_services.updateschprocedureanddates(i_lang          => i_lang,
                                                                                   i_prof          => i_prof,                                                                                   
                                                                                   i_scheduleid    => l_id_schedule_ext,
                                                                                   i_contentid     => l_id_content_new,
                                                                                   i_depclinservid => i_dep_clin_serv,
                                                                                   i_profid        => i_prof.id,
                                                                                   i_begindate     => i_dt_begin_tstz,
                                                                                   i_enddate       => i_dt_end_tszt,
                                                                                   i_requestedtype => i_flg_request_type,
                                                                                   i_transaction   => i_transaction_id);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                       ' id_schedule_ext= ' || l_id_schedule_ext;
        
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_error(text        => g_package_name || '.' || l_func_name ||
                                                 ' ERROR -> no external schedule id found for internal id ' ||
                                                 i_id_schedule,
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
            RETURN FALSE;
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => g_package_name || '.' || l_func_name || ' ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
        
    END update_sch_proc_and_dates;

    /*
    * Gets a new transaction ID and begins it or uses the transaction provided
    *
    * @param i_transaction_id   Transaction identifier (if already got one)
    *
    * @return Transaction identifier
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since   07-12-2009
    */
    FUNCTION begin_new_transaction
    (
        i_transaction_id VARCHAR2,
        i_prof           profissional DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
        IF i_transaction_id IS NOT NULL
        THEN
            l_transaction_id := i_transaction_id;
        ELSE
            l_transaction_id := create_new_transaction(i_prof);
        END IF;
    
        RETURN l_transaction_id;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
            RETURN NULL;
    END;

    /*
    * start new remote transaction and save its ID inside the package
    *
    * @param i_prof
    *
    * @author   Telmo
    * @version  2.6.0.5
    * @date     18-03-2011
    */
    PROCEDURE get_transaction(i_prof profissional DEFAULT NULL) IS
    BEGIN
        IF g_transaction_id IS NULL
        THEN
            g_transaction_id := create_new_transaction(i_prof);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => g_error);
    END get_transaction;

    /*
    * Confirms a pending schedule and sets the schedule's exam requisitions
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009
    */
    FUNCTION set_status_and_exam_reqs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_sch_ext     IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_ids_exam       IN table_number,
        i_ids_exam_req   IN table_number,
        i_transaction_id IN VARCHAR2,
        o_id_schedule    OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'SET_STATUS_AND_EXAM_REQS';
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id);
        END IF;
    
        -- confirmar agendamento externo
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CONFIRM_PENDING_SCHED WITH i_id_sch_ext=' || i_id_sch_ext ||
                   ', l_transaction_id=' || l_transaction_id;
        IF NOT confirm_pending_sched(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_id_schedule_ext => i_id_sch_ext,
                                     i_transaction_id  => l_transaction_id,
                                     o_error           => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'CALL pk_schedule_api_downstream.set_schedule_exam_reqs WITH i_id_sch_ext= ' || i_id_sch_ext ||
                   ', i_id_patient= ' || i_id_patient;
        IF NOT pk_schedule_api_downstream.set_schedule_exam_reqs(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_id_sch_ext   => i_id_sch_ext,
                                                                 i_id_patient   => i_id_patient,
                                                                 i_ids_exam     => i_ids_exam,
                                                                 i_ids_exam_req => i_ids_exam_req,
                                                                 o_error        => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id);
            RETURN FALSE;
    END set_status_and_exam_reqs;

    /*
    * send bed new blocked period to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION block_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng_action IN bmng_action.id_bmng_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'BLOCK_BED';
    
        l_obj_response boolean;
        l_id_resource  NUMBER(24);
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN     
        
            g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.BLOCKBED WITH i_id_bed=' || i_id_bed || ', i_start_date= ' ||
                              CAST(i_start_date AS VARCHAR2) || ', i_end_date= ' || CAST(i_end_date AS VARCHAR2);
            l_obj_response := pk_schedule_rest_services.blockbed(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_bedid         => i_id_bed,
                                                                 i_begindate     => i_start_date,
                                                                 i_enddate       => i_end_date,
                                                                 i_transaction   => i_transaction_id,
                                                                 o_idresource    => l_id_resource);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE AFTER PK_SCHEDULE_REST_SERVICES.BLOCKBED CALL';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            ELSE
            
                IF i_id_bmng_action IS NOT NULL
                   AND l_id_resource IS NOT NULL
                THEN
                
                    g_error := 'INSERT INTO TS_BMNG_ACTION_SCH_MAP id_bmng_action:' || i_id_bmng_action ||
                               ' id_sch_resource:' || l_id_resource;
                
                    ts_bmng_action_sch_map.ins(id_bmng_action_in  => i_id_bmng_action,
                                               id_sch_resource_in => l_id_resource,
                                               flg_action_in      => 'B',
                                               dt_created_in      => current_timestamp,
                                               handle_error_in    => TRUE);
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.BLOCKBED ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END block_bed;

    /*
    * send bed new non blocked period to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of non blocked period
    * @param i_end_date                    end of non blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION unblock_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng_action IN bmng_action.id_bmng_action%TYPE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'UNBLOCK_BED';
    
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
        
            g_error := 'CALL PK_SCHEDULE_REST_SERVICES.UNBLOCKBED WITH i_id_bed= ' || i_id_bed || ', i_start_date= ' ||
                       CAST(i_start_date AS VARCHAR2) || ', i_end_date= ' || CAST(i_end_date AS VARCHAR2);
            pk_alertlog.log_error(g_error);
            l_obj_response := pk_schedule_rest_services.unblockbed(i_lang          => i_lang,
                                                                   i_prof          => i_prof,                                                                   
                                                                   i_bedid         => i_id_bed,
                                                                   i_resourceid    => i_id_resource,
                                                                   i_begindate     => i_start_date,
                                                                   i_enddate       => i_end_date,
                                                                   i_transaction   => i_transaction_id);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE AFTER PK_SCHEDULE_REST_SERVICES.UNBLOCKBED CALL';
            pk_alertlog.log_error(g_error);
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            ELSE
                g_error := 'DELETE ON BMNG_SCHEDULER_MAP WITH ID_RESOURCE_EXT=' || i_id_resource;
                pk_alertlog.log_error(g_error);
                IF i_id_bmng_action IS NOT NULL
                   AND i_id_resource IS NOT NULL
                THEN
                    g_error := 'DELETE ON BMNG_ACTION_SCH_MAP WITH ID_RESOURCE_EXT=' || i_id_resource;
                    pk_alertlog.log_error(g_error);
                    ts_bmng_action_sch_map.del(id_bmng_action_in  => i_id_bmng_action,
                                               id_sch_resource_in => i_id_resource,
                                               handle_error_in    => TRUE);
                END IF;
            END IF;
        END IF;
    
        -- CODIGO DO INPATIENT PARA DESBLOQUEIO DA CAMA DEVE VIR A SEGUIR
        --g_error := '';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.UNBLOCKBED ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END unblock_bed;

    /*
    * send new bed allocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_speciality                speciality of the allocation
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION allocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_speciality  IN NUMBER,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bmng        IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'ALLOCATE_BED';
    
        l_obj_response boolean;
        l_id_resource  NUMBER(24);
    
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            --l_obj_response.response_ := obj_response(NULL, NULL, NULL);
        
            g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.ALLOCATEBED WITH i_id_bed= ' || i_id_bed || ', i_start_date= ' ||
                              CAST(i_start_date AS VARCHAR2) || ', i_end_date= ' || CAST(i_end_date AS VARCHAR2) ||
                              ', i_id_patient= ' || i_id_patient || ', i_id_speciality= ' || i_id_speciality;
            l_obj_response := pk_schedule_rest_services.allocatebed(i_lang          => i_lang,
                                                                    i_prof          => i_prof,                   
                                                                    i_patientid     => i_id_patient,
                                                                    i_specialtyid   => i_id_speciality,
                                                                    i_bedid         => i_id_bed,
                                                                    i_begindate     => i_start_date,
                                                                    i_enddate       => i_end_date,
                                                                    i_transaction   => i_transaction_id,
                                                                    o_idresource    => l_id_resource);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE AFTER PK_SCHEDULE_REST_SERVICES.ALLOCATEBED CALL';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            ELSE
                g_error       := 'INSERT INTO BMNG_SCHEDULER_MAP id_resource_pfh:' || i_id_bmng || ' id_resource_ext:' ||
                                 l_id_resource;
            
                ts_bmng_scheduler_map.ins(id_resource_pfh_in => i_id_bmng,
                                          id_resource_ext_in => l_id_resource,
                                          dt_created_in      => current_timestamp,
                                          handle_error_in    => TRUE);
                --COMMIT;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.ALLOCATEBED ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END allocate_bed;

    /*
    * send updated bed allocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param i_new_end_date                new end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION update_allocated_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_new_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        i_id_bmng        IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'UPDATE_ALLOCATED_BED';
    
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
        
            g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.UPDATEALLOCATEDBED WITH i_id_bed= ' || i_id_bed ||
                              ', i_start_date= ' || CAST(i_start_date AS VARCHAR2) || ', i_end_date= ' ||
                              CAST(i_end_date AS VARCHAR2) || ', i_id_patient= ' || i_id_patient ||
                              ', i_new_end_date= ' || CAST(i_new_end_date AS VARCHAR2);
            l_obj_response := pk_schedule_rest_services.updateallocatedbed(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_patientid     => i_id_patient,
                                                                           i_bedid         => i_id_bed,
                                                                           --begindate     => i_start_date,
                                                                           i_resourceid => i_id_resource,
                                                                           i_enddate    => i_end_date,
                                                                           i_newenddate => i_new_end_date,
                                                                           i_transaction   => i_transaction_id);
        
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE AFTER PK_SCHEDULE_REST_SERVICES.UPDATEALLOCATEDBED CALL';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            ELSE
                IF i_id_resource IS NOT NULL
                   AND i_id_bmng IS NOT NULL
                THEN
                    g_error := 'DELETE ON BMNG_SCHEDULER_MAP WITH ID_RESOURCE_EXT=' || i_id_resource;
                    ts_bmng_scheduler_map.del_id_resource_ext(id_resource_ext_in => i_id_resource,
                                                              handle_error_in    => TRUE);
                
                    g_error := 'INSERT INTO BMNG_SCHEDULER_MAP id_resource_pfh:' || i_id_bmng || ' id_resource_ext:' ||
                               i_id_resource;
                    ts_bmng_scheduler_map.ins(id_resource_pfh_in => i_id_bmng,
                                              id_resource_ext_in => i_id_resource,
                                              dt_created_in      => current_timestamp,
                                              handle_error_in    => TRUE);
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.UPDATEALLOCATEDBED ERROR ',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END update_allocated_bed;

    /*
    * send bed deallocation to scheduler
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_patient                  patient to whom the bed is being allocated
    * @param i_id_bed                      bed id
    * @param i_start_date                  begining of blocked period
    * @param i_end_date                    end of blocked period
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    02-07-2010
    */
    FUNCTION deallocate_bed
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_bed         IN bed.id_bed%TYPE,
        i_start_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_resource    IN bmng_scheduler_map.id_resource_ext%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'DEALLOCATE_BED';
    
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
    BEGIN
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
           AND i_id_resource IS NOT NULL
        THEN
        
            g_error        := 'CALL PK_SCHEDULE_REST_SERVICES.DEALLOCATEBED WITH i_id_bed= ' || i_id_bed || ', i_start_date= ' ||
                              CAST(i_start_date AS VARCHAR2) || ', i_end_date= ' || CAST(i_end_date AS VARCHAR2) ||
                              ', i_id_patient= ' || i_id_patient || ' i_id_resource= ' || i_id_resource;
            l_obj_response := pk_schedule_rest_services.deallocatebed(i_lang          => i_lang,
                                                                      i_prof          => i_prof,
                                                                      i_patientid     => i_id_patient,
                                                                      i_bedid         => i_id_bed,
                                                                      i_resourceid    => i_id_resource,
                                                                      --begindate     => i_start_date,
                                                                      i_enddate => i_end_date,
                                                                      i_transaction   => i_transaction_id);
          
            -- treat remote transaction error message
            g_error := 'TREAT REMOTE TRANSACTION ERROR MESSAGE AFTER PK_SCHEDULE_REST_SERVICES.DEALLOCATEBED CALL';
            IF NOT l_obj_response
            THEN
                RAISE l_remote_exception;
            ELSE
                g_error := 'DELETE ON BMNG_SCHEDULER_MAP WITH ID_RESOURCE_EXT=' || i_id_resource;
                ts_bmng_scheduler_map.del_id_resource_ext(id_resource_ext_in => i_id_resource, handle_error_in => TRUE);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            pk_alertlog.log_fatal(text        => 'PK_SCHEDULE_REST_SERVICES.DEALLOCATEBED ERROR',
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
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
            RETURN FALSE;
    END deallocate_bed;

    /*
    * notifies scheduler 3 about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3.4
    * @date    29-10-2010
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'SET_PATIENT_NO_SHOW';
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        --l_so_row          schedule_outp%ROWTYPE;
    BEGIN
        g_error := 'Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.setSchedulePersonNoShow WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_id_patient= ' || i_id_patient || ', i_id_cancel_reason=' ||
                                  i_id_cancel_reason;
                l_obj_response := pk_schedule_rest_services.setschedulepersonnoshow(i_lang          => i_lang,
                                                                                    i_prof          => i_prof,                                                                                    
                                                                                    i_schid         => l_id_schedule_ext,
                                                                                    i_personid      => i_id_patient,
                                                                                    i_noshowid      => i_id_cancel_reason,
                                                                                    i_noshownotes   => i_notes,
                                                                                    i_transaction   => i_transaction_id);
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.SET_PATIENT_NO_SHOW WITH i_id_sch_ext= ' || l_id_schedule_ext ||
                   ', i_id_patient= ' || i_id_patient || ', i_id_cancel_reason= ' || i_id_cancel_reason;
        IF NOT pk_schedule_api_downstream.set_patient_no_show(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_sch_ext       => l_id_schedule_ext,
                                                              i_id_patient       => i_id_patient,
                                                              i_id_cancel_reason => i_id_cancel_reason,
                                                              i_notes            => i_notes,
                                                              o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEHDULE_REST_SERVICES.SETSCHEDULEPERSONNOSHOW',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
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
            pk_schedule_api_upstream.do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
            RETURN FALSE;
    END set_patient_no_show;

    /*
    * this function returns value of sys_config entry 'SCHEDULER3_INSTALLED'.
    * Uses id_institution and id_software from i_prof to fetch the correct value.
    *
    * @param i_prof               Professional data: id, institution and software
    *
    * @return                 Y/N
    *
    * @author                     Telmo
    * @version                    2.6.0.3.4
    * @since                      28-10-2010
    */
    FUNCTION is_scheduler_installed(i_prof IN profissional) RETURN sys_config.value%TYPE IS
    BEGIN
        RETURN nvl(pk_sysconfig.get_config('SCHEDULER3_INSTALLED', i_prof), 'Y');
    END is_scheduler_installed;

    /*
    * Sends the new contact type value to the scheduler.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_flg_contact_Type            new contact type value. I= patient absent; D=patient present
    * @return TRUE if sucess, FALSE otherwise
    *
    * @author                     Telmo
    * @version                    2.6.0.5.4
    * @since                      17-03-2011
    */
    FUNCTION set_flg_contact_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_transaction_id   IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_flg_contact_type IN sch_group.flg_contact_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_FLG_CONTACT_TYPE';
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        l_obj_response    boolean;
    BEGIN
        g_error := 'Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := 'Call PK_SCHEDULE_REST_SERVICES.setcontacttype WITH l_id_schedule_ext = ' || l_id_schedule_ext ||
                                  ', i_id_patient= ' || i_id_patient || ', contacttype=' || i_flg_contact_type;
                l_obj_response := pk_SCHEDULE_REST_SERVICES.setcontacttype(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_schid            => l_id_schedule_ext,                                                                          
                                                                           i_idpersonexternal => i_id_patient,
                                                                           i_contacttype      => i_flg_contact_type,
                                                                           i_transaction   => i_transaction_id);
            
                -- treat remote transaction error message
                g_error := 'CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule || ' id_schedule_ext= ' ||
                           l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        -- excepcionalmente esta funcao nao faz DMLs em dados do PFH. Pedro Carneiro pediu assim.
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_error(text        => 'PK_SCHEDULE_REST_SERVICES.SETCONTACTTYPE ERROR -> no external schedule id found for internal id ' ||
                                                 i_id_schedule,
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
            RETURN FALSE;
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.SETCONTACTTYPE ERROR ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END set_flg_contact_type;

    /*
    * Cancels an appointment. This is the new version made according to alert-167145 new rules.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param i_id_sch_cancel_reason Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.1.1
    * @since   07-06-2011
    */
    FUNCTION cancel_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULE';
    BEGIN
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error := 'CANCEL_SCHEDULE - GET_TRANSACTION';
            get_transaction(i_prof);
        END IF;
    
        g_error := 'CANCEL_SCHEDULE - CALL WORKING CANCEL_SCHEDULE';
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_id_schedule,
                               i_id_cancel_reason => i_id_sch_cancel_reason,
                               i_cancel_notes     => i_cancel_notes,
                               i_transaction_id   => g_transaction_id,
                               i_cancel_exam_req  => i_cancel_exam_req,
                               i_dt_referral      => i_dt_referral,
                               i_referral_reason  => i_referral_reason,
                               o_error            => o_error)
        THEN
            RETURN FALSE;
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
    END cancel_schedule;
    /*
    * Cancels several appointments. If one fails, everything is rollbacked.
    * Initial usage by the Trials feature.
    * This function is compliant with alert-167145 new rules.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_schedule       PFH schedule identifiers
    * @param i_id_sch_cancel_reason scheduler cancel reason id. All schedules will share the same id
    * @param i_cancel_notes       Cancel notes. All schedules will share the same notes
    * @param i_cancel_exam_req    Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.1
    * @since   07-06-2011
    */
    FUNCTION cancel_schedules
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_ids_schedule         IN table_number,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULES';
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        -- l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        -- l_ids_sch_ext     table_number := table_number();
        --l_obj_response    obj_response;
        i PLS_INTEGER;
    BEGIN
    
        -- obter ids externos. Tem de estar fora do IF is_scheduler_installed
        IF i_ids_schedule IS NOT NULL
           AND i_ids_schedule.count > 0
        THEN
        
            i := i_ids_schedule.first;
            WHILE i IS NOT NULL
            LOOP
                g_error := l_func_name || ' - CALL CANCEL_SCHEDULE with i_id_schedule = ' || i_ids_schedule(i);
                IF NOT cancel_schedule(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_schedule          => i_ids_schedule(i),
                                       i_id_sch_cancel_reason => i_id_sch_cancel_reason,
                                       i_cancel_notes         => i_cancel_notes,
                                       i_cancel_exam_req      => i_cancel_exam_req,
                                       i_dt_referral          => i_dt_referral,
                                       i_referral_reason      => i_referral_reason,
                                       o_error                => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                i := i_ids_schedule.next(i);
            END LOOP;
        ELSE
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            do_rollback(i_prof);
            RETURN FALSE;
    END cancel_schedules;

    /*
    * cancel a previous patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.3.1
    * @date    17-10-2011
    */
    FUNCTION cancel_patient_no_show
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'CANCEL_PATIENT_NO_SHOW';
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        -- l_so_row          schedule_outp%ROWTYPE;
    BEGIN
        g_error := l_func_name || ' - Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := l_func_name ||
                                  ' - Call PK_SCHEDULE_REST_SERVICES.cancelSchedulePersonNoShow WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_id_patient= ' || i_id_patient;
                l_obj_response := pk_schedule_rest_services.cancelschedulepersonnoshow(i_lang             => i_lang,
                                                                                      i_prof             => i_prof,                 
                                                                                      i_schid            => l_id_schedule_ext,
                                                                                      i_idpersonexternal => i_id_patient,
                                                                                      i_transaction   => i_transaction_id);
                -- treat remote transaction error message
                g_error := l_func_name || ' - CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        g_error := 'CALL PK_SCHEDULE_API_DOWNSTREAM.SET_PATIENT_UNDO_NO_SHOW WITH i_id_sch_ext= ' || l_id_schedule_ext ||
                   ', i_id_patient= ' || i_id_patient;
        IF NOT pk_schedule_api_downstream.set_patient_undo_no_show(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_sch_ext => l_id_schedule_ext,
                                                                   i_id_patient => i_id_patient,
                                                                   o_error      => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        /*
                -- actualiza sch_group.id_cancel_reason e no_show_notes
                g_error := l_func_name || ' - UPDATE SCH_GROUP NO-SHOW COLUMNS';
                ts_sch_group.upd(id_cancel_reason_in  => NULL,
                                 id_cancel_reason_nin => FALSE,
                                 no_show_notes_in     => NULL,
                                 no_show_notes_nin    => FALSE,
                                 where_in             => 'id_patient=' || i_id_patient || ' AND id_schedule = ' || i_id_schedule,
                                 handle_error_in      => FALSE);
        
                -- actualiza schedule_outp.flg_state
                BEGIN
                    g_error := l_func_name || ' - GET ID_SCHEDULE_OUTP FOR ID_SCHEDULE ' || i_id_schedule;
                    SELECT id_schedule_outp
                      INTO l_so_row.id_schedule_outp
                      FROM schedule_outp so
                     WHERE so.id_schedule = i_id_schedule
                       AND rownum = 1;
        
                    g_error := l_func_name || ' - UPDATE SCHEDULE_OUTP.FLG_STATE';
                    l_so_row.id_schedule := i_id_schedule;
                    l_so_row.flg_state   := 'A';
                    ts_schedule_outp.upd(rec_in => l_so_row, handle_error_in => FALSE);
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE l_local_exception;
                END;
        
                -- insere no historico
                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || i_id_schedule;
                pk_schedule_common.backup_all(i_id_sch => i_id_schedule,
                                              i_dt_update => current_timestamp,
                                              i_id_prof_u => i_prof.id);
        */
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.CANCELSCHEDULEPERSONNOSHOW ',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
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
            RETURN FALSE;
    END cancel_patient_no_show;

    /*
    * add requisition to lab appointment. This tipically happens for lab appointments without initial requisition.
    * After it is registered, its possible to add requisitions for further lab harvests within the episode, and
    * thats where this function comes in.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_transaction_id              Scheduler transaction identifier
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_req                      requisition id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.7
    * @date    22-07-2013
    */
    FUNCTION add_req_to_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_req         IN NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := $$PLSQL_UNIT;
        l_obj_response boolean;
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        l_local_exception  EXCEPTION;
        l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
    BEGIN
        g_error := l_func_name || ' - Call get_schedule_id_ext with i_id_schedule=' || i_id_schedule;
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext IS NOT NULL
            THEN
                g_error        := l_func_name || ' - Call PK_SCHEDULE_REST_SERVICES.addrequisition WITH l_id_schedule_ext = ' ||
                                  l_id_schedule_ext || ', i_id_patient= ' || i_id_patient || ', idreq=' ||
                                  nvl(to_char(i_id_req), '<NULO>') || ', i_id_schedule=' || i_id_schedule;
                l_obj_response := pk_schedule_rest_services.addrequisition(i_lang             => i_lang,
                                                                           i_prof            => i_prof,                      
                                                                           i_schid            => l_id_schedule_ext,
                                                                           i_idpersonexternal => i_id_patient,
                                                                           i_idreq            => i_id_req,
                                                                           i_transaction   => i_transaction_id);
                -- treat remote transaction error message
                g_error := l_func_name || ' - CHECK REMOTE RESPONSE / ID_SCHEDULE_INT = ' || i_id_schedule ||
                           ' id_schedule_ext= ' || l_id_schedule_ext;
                IF NOT l_obj_response
                THEN
                    RAISE l_remote_exception;
                END IF;
            END IF;
        END IF;
    
        -- insere na schedule_analysis
        g_error := l_func_name || ' - Call TS_SCHEDULE_ANALYSIS.ins';
        ts_schedule_analysis.ins(id_schedule_in     => i_id_schedule,
                                 id_analysis_req_in => i_id_req,
                                 handle_error_in    => FALSE);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alertlog.log_error(text        => 'External schedule id not found for internal id ' || i_id_schedule,
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
            RETURN FALSE;
        WHEN l_remote_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20012,
                                              i_sqlerrm  => 'PK_SCHEDULE_REST_SERVICES.ADDREQUISITION ERROR',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
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
            RETURN FALSE;
    END add_req_to_sch;

    /*
    * Cancels several appointments. If one fails, everything is rollbacked, if not
    * is commited.
    * Initial usage by RESET.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_transaction_id     Scheduler transaction identifier
    * @param i_ids_schedule       PFH schedule identifiers
    * @param i_id_sch_cancel_reason scheduler cancel reason id. All schedules will share the same id
    * @param i_cancel_notes       Cancel notes. All schedules will share the same notes
    * @param i_cancel_exam_req    Y = for exam schedules also cancels their requisition.
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason   ALERT-259898
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1.1
    * @since   07-06-2011
    */
    FUNCTION cancel_schedules
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_transaction_id       IN VARCHAR2,
        i_ids_schedule         IN table_number,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_cancel_exam_req      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_referral          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason      IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_SCHEDULES';
        l_remote_exception EXCEPTION;
        l_func_exception   EXCEPTION;
        --l_id_schedule_ext sch_api_map_ids.id_schedule_ext%TYPE;
        ---l_ids_sch_ext     table_number := table_number();
        --l_obj_response    obj_response;
        i PLS_INTEGER;
    BEGIN
    
        -- obter ids externos. Tem de estar fora do IF is_scheduler_installed
        IF i_ids_schedule IS NOT NULL
           AND i_ids_schedule.count > 0
        THEN
        
            i := i_ids_schedule.first;
            WHILE i IS NOT NULL
            LOOP
                g_error := l_func_name || ' - CALL CANCEL_SCHEDULE with i_id_schedule = ' || i_ids_schedule(i);
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_transaction_id   => i_transaction_id,
                                       i_id_schedule      => i_ids_schedule(i),
                                       i_id_cancel_reason => i_id_sch_cancel_reason,
                                       i_cancel_notes     => i_cancel_notes,
                                       i_cancel_exam_req  => i_cancel_exam_req,
                                       i_dt_referral      => i_dt_referral,
                                       i_referral_reason  => i_referral_reason,
                                       o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                i := i_ids_schedule.next(i);
            END LOOP;
        ELSE
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            RETURN FALSE;
    END cancel_schedules;

    /*
    * Cancels a exam/other exam schedule, based on a id_exam_req and id_exam.
    * alert-167145 compliant.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_exam            exam id
    * @param i_id_exam_req        exam req id
    * @param i_id_sch_cancel_reason Cancel reason identifier
    * @param i_cancel_notes       Cancel notes
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Telmo
    * @version 2.6.4.2
    * @since   07-10-2014
    */
    FUNCTION cancel_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_exam              IN schedule_exam.id_exam%TYPE,
        i_id_exam_req          IN schedule_exam.id_exam_req%TYPE,
        i_id_sch_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes         IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := $$PLSQL_UNIT;
        l_id_sch    schedule_exam.id_schedule%TYPE;
    BEGIN
        -- get id_schedule
        g_error := l_func_name || ' - GET id_schedule for id_exam=' || i_id_exam || ', id_exam_req=' || i_id_exam_req;
        SELECT id_schedule
          INTO l_id_sch
          FROM schedule_exam se
         WHERE se.id_exam = i_id_exam
           AND se.id_exam_req = i_id_exam_req
           AND rownum = 1;
    
        -- get transaction
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error := l_func_name || ' - GET_TRANSACTION';
            get_transaction(i_prof);
        END IF;
    
        g_error := l_func_name || ' - CALL WORKING CANCEL_SCHEDULE';
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => l_id_sch,
                               i_id_cancel_reason => i_id_sch_cancel_reason,
                               i_cancel_notes     => i_cancel_notes,
                               i_transaction_id   => g_transaction_id,
                               i_cancel_exam_req  => pk_alert_constant.g_no,
                               i_dt_referral      => NULL,
                               i_referral_reason  => NULL,
                               o_error            => o_error)
        THEN
            RETURN FALSE;
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
    END cancel_schedule;

    -- *****************************************************************
    -- *************************************************************
    -- Approve visits
    FUNCTION hhc_approve_sch_base
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_ids         IN table_number,
        i_transaction IN VARCHAR2,
        i_id_reason   IN NUMBER,
        i_rea_note    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        t_return boolean;
        l_error  VARCHAR2(4000);
        l_remote_exception EXCEPTION;
    
        -- ************************************************
        PROCEDURE xprocess_error
        (
            i_lang    IN NUMBER,
            i_sqlcode IN NUMBER,
            i_sqlerrm IN VARCHAR2,
            o_error   OUT t_error_out
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => i_sqlcode,
                                              i_sqlerrm  => i_sqlerrm,
                                              i_message  => '',
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'APPROVE_VISIT',
                                              o_error    => o_error);
        
        END xprocess_error;
    
    BEGIN
    
        -- t_return          := obj_createscheduleresponse(NULL, obj_response(NULL, NULL, NULL));
        --t_return.response_ := obj_response(NULL, NULL, NULL);
    
        t_return := pk_schedule_rest_services.approvehhcschedules(i_lang          => i_lang,
                                                                i_prof          =>i_prof,                   
                                                                i_schids        => i_ids,
                                                                i_reasonid      => i_id_reason,
                                                                i_reasonnotes   => i_rea_note,
                                                                i_transaction   => i_transaction);
    
        IF NOT t_return
        THEN
            RAISE l_remote_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            l_error := 'PK_SCHEDULE_REST_SERVICES.APPROVE_HHC_SCH ERROR';
            xprocess_error(i_lang => i_lang, i_sqlcode => 20013, i_sqlerrm => l_error, o_error => o_error);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            xprocess_error(i_lang => i_lang, i_sqlcode => SQLCODE, i_sqlerrm => SQLERRM, o_error => o_error);
        
            RETURN FALSE;
        
    END hhc_approve_sch_base;

    -- *************************************************************
    -- Undo Approve
    FUNCTION hhc_undo_schedule_base
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2,
        i_ids         IN table_number,
        i_id_reason   IN NUMBER,
        i_rea_note    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        t_return boolean;
        l_error  VARCHAR2(4000);
        l_remote_exception EXCEPTION;
    
        -- ************************************************
        PROCEDURE xprocess_error
        (
            i_lang    IN NUMBER,
            i_sqlcode IN NUMBER,
            i_sqlerrm IN VARCHAR2,
            o_error   OUT t_error_out
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => i_sqlcode,
                                              i_sqlerrm  => i_sqlerrm,
                                              i_message  => '',
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'hhc_undo_schedule_base',
                                              o_error    => o_error);
        
        END xprocess_error;
    
    BEGIN
    
        t_return := pk_schedule_rest_services.undoapprovedhhcschedules(i_lang          => i_lang,
                                                                       i_prof          => i_prof,
                                                                       i_schids        => i_ids,
                                                                       i_reasonid      => i_id_reason,
                                                                       i_reasonnotes   => i_rea_note,
                                                                       i_transaction   => i_transaction);
    
        IF NOT t_return
        THEN
            RAISE l_remote_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            l_error := 'hhc_undo_schedule_base ERROR -> errorMsg_:';
            xprocess_error(i_lang => i_lang, i_sqlcode => 20013, i_sqlerrm => l_error, o_error => o_error);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            xprocess_error(i_lang => i_lang, i_sqlcode => SQLCODE, i_sqlerrm => SQLERRM, o_error => o_error);
        
            RETURN FALSE;
    END hhc_undo_schedule_base;

    -- **********************************************
    FUNCTION hhc_approve_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := hhc_change_schedule(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_schedule    => i_id_schedule,
                                      i_flg_status     => pk_schedule.g_sched_status_scheduled,
                                      i_transaction_id => i_transaction_id,
                                      i_id_reason      => i_id_reason,
                                      i_rea_note       => i_rea_note,
                                      o_error          => o_error);
    
        RETURN l_bool;
    
    END hhc_approve_schedule;
        
    -- *************************************************
    FUNCTION hhc_undo_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
        
        l_bool := hhc_change_schedule(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_schedule    => i_id_schedule,
                                      i_flg_status     => pk_schedule.g_sched_status_pend_approval,
                                      i_transaction_id => i_transaction_id,
                                      i_id_reason      => i_id_reason,
                                      i_rea_note       => i_rea_note,
                                      o_error          => o_error);
    
        RETURN l_bool;
    
    END hhc_undo_schedule;

    FUNCTION create_alert_event
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_sys_alert     IN NUMBER,
        i_id_sys_alert_del IN NUMBER,
        i_id_schedule      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        r_epis episode%ROWTYPE;
        saer   sys_alert_event%ROWTYPE;
        l_bool BOOLEAN;
        k_epis_type_hhc CONSTANT NUMBER := pk_alert_constant.g_epis_type_home_health_care;
        l_error t_error_out;
    
        FUNCTION get_id_episode_by_schedule(i_id_schedule IN NUMBER) RETURN NUMBER IS
            tbl_id_episode table_number;
            l_id_episode   NUMBER;
        BEGIN
            SELECT id_episode
              BULK COLLECT
              INTO tbl_id_episode
              FROM epis_info
             WHERE id_schedule = i_id_schedule;
        
            IF tbl_id_episode.count > 0
            THEN
                l_id_episode := tbl_id_episode(1);
            END IF;
        
            RETURN l_id_episode;
        
        END get_id_episode_by_schedule;
    
        FUNCTION get_episode_row(i_id_episode IN NUMBER) RETURN episode%ROWTYPE IS
            xrow episode%ROWTYPE;
        BEGIN
            SELECT e.*
              INTO xrow
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            RETURN xrow;
        END get_episode_row;
    
    BEGIN
    
        saer.id_episode := get_id_episode_by_schedule(i_id_schedule);
    
        IF saer.id_episode IS NOT NULL
        THEN
        
            r_epis := get_episode_row(i_id_episode => saer.id_episode);
        
            IF r_epis.id_epis_type = k_epis_type_hhc
            THEN
            
                -- prepare alert data
                saer.id_sys_alert   := i_id_sys_alert;
                saer.id_software    := i_prof.software;
                saer.id_institution := i_prof.institution;
                saer.id_patient     := r_epis.id_patient;
                saer.id_record      := i_id_schedule;
                saer.dt_record      := current_timestamp;
                saer.flg_visible    := pk_alert_constant.g_yes;
                saer.id_visit       := r_epis.id_visit;
            
                l_bool := pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_sys_alert_event => saer,
                                                           o_error           => o_error);
            
                IF NOT l_bool
                THEN
                    -- if alert gives error, log it, but do not invalidate operation
                    pk_alertlog.log_error(text        => 'Alert failed ' || i_id_sys_alert || ' cause=' ||
                                                         l_error.ora_sqlerrm,
                                          object_name => g_package_name,
                                          owner       => g_package_owner);
                END IF;
            
                saer.id_sys_alert := i_id_sys_alert_del;
                l_bool            := pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_sys_alert_event => saer,
                                                                      o_error           => o_error);
                IF NOT l_bool
                THEN
                    -- if alert gives error, log it, but do not invalidate operation
                    pk_alertlog.log_error(text        => 'Removing Alert failed ' || i_id_sys_alert_del || ' cause=' ||
                                                         l_error.ora_sqlerrm,
                                          object_name => g_package_name,
                                          owner       => g_package_owner);
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END create_alert_event;

    -- **********************************************
    FUNCTION hhc_change_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN table_number,
        i_flg_status     IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        i_id_reason      IN NUMBER,
        i_rea_note       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(0050 CHAR) := 'HHC_CHANGE_SCHEDULE';
        l_id_schedule_ext  table_number := table_number();
        l_id_sys_alert     NUMBER;
        l_id_sys_alert_del NUMBER;
        l_remote_exception EXCEPTION;
        l_bool BOOLEAN;
    BEGIN
    
        g_error := 'CALL GET_SCHEDULE_ID_EXT / ID_SCHEDULE';
        l_bool  := get_tbl_schedule_id_ext(i_lang        => i_lang,
                                           i_id_schedule => i_id_schedule,
                                           o_id_schedule => l_id_schedule_ext,
                                           o_error       => o_error);
    
        IF NOT l_bool
        THEN
            RAISE g_exception;
        END IF;
    
        IF is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            -- so altera estado na agenda se encontrou id schedule externo
            IF l_id_schedule_ext.count > 0 -- 000
            THEN
            
                CASE i_flg_status
                    WHEN pk_schedule.g_sched_status_pend_approval THEN
                    
                        l_id_sys_alert     := k_alert_hhc_undo_sched;
                        l_id_sys_alert_del := k_alert_hhc_approve_sched;
                    
                        l_bool := hhc_undo_schedule_base(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_ids         => l_id_schedule_ext,
                                                         i_transaction => i_transaction_id,
                                                         i_id_reason   => i_id_reason,
                                                         i_rea_note    => i_rea_note,
                                                         o_error       => o_error);
                    
                    WHEN pk_schedule.g_sched_status_scheduled THEN
                    
                        l_id_sys_alert     := k_alert_hhc_approve_sched;
                        l_id_sys_alert_del := k_alert_hhc_undo_sched;
                    
                        l_bool := hhc_approve_sch_base(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_ids         => l_id_schedule_ext,
                                                       i_transaction => i_transaction_id,
                                                       i_id_reason   => i_id_reason,
                                                       i_rea_note    => i_rea_note,
                                                       o_error       => o_error);
                    ELSE
                        l_bool := FALSE;
                END CASE;
            
                IF NOT l_bool
                THEN
                    RAISE l_remote_exception;
                END IF;
            
            END IF; --- 000
        
        END IF;
    
        -- FALTA FAZER O MESMO NA SCHEDULE LOCAL - FLG_STATUS = A
        g_error := 'SET SCHEDULE.FLG_STATUS TO Scheduled WITH i_id_schedule';
        <<lup_thru_schedule>>
        FOR i IN 1 .. i_id_schedule.count
        LOOP
        
            pk_schedule_common.backup_all(i_id_sch    => i_id_schedule(i),
                                          i_dt_update => current_timestamp,
                                          i_id_prof_u => i_prof.id);
        
            UPDATE schedule
               SET flg_status = i_flg_status
             WHERE id_schedule = i_id_schedule(i);
        
            l_bool := create_alert_event(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_sys_alert     => l_id_sys_alert,
                                         i_id_sys_alert_del => l_id_sys_alert_del,
                                         i_id_schedule      => i_id_schedule(i),
                                         o_error            => o_error);
        
            IF NOT l_bool
            THEN
                RETURN l_bool;
            END IF;
        
        END LOOP lup_thru_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_remote_exception THEN
            do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
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
            do_rollback(i_id_transaction => i_transaction_id, i_prof => i_prof);
            RETURN FALSE;
    END hhc_change_schedule;

BEGIN
    -- Log initialization
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
    --
    IF g_transaction_id IS NOT NULL
    THEN
        pk_alertlog.log_error('erro: g_transaction_id já inicializado');
    END IF;
    g_transaction_id := NULL;
END pk_schedule_api_upstream;

/
