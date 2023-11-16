/*-- Last Change Revision: $Rev: 2054642 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-20 15:40:36 +0000 (sex, 20 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_visit IS

    FUNCTION interf_info
    (
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_instit_requests IN institution.id_institution%TYPE,
        i_clin_serv          IN clinical_service.id_clinical_service%TYPE,
        i_id_prof            IN sch_resource.id_professional%TYPE,
        i_id_prof_schedules  IN sch_resource.id_professional%TYPE,
        i_epis_type          IN episode.id_epis_type%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_dt_schedule_begin  IN schedule.dt_begin_tstz%TYPE,
        i_dt_mcdt_begin      IN analysis_req.dt_begin_tstz%TYPE,
        i_id_analysis        IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_id_exam            IN exam.id_exam%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Criar um agendamento de um exame e/ou anlise para os casos em que o agendamento ocorreu
           antes da implementao do ALERT, mas a efectivao depois.
           PARAMETROS:
          Entrada: i_id_institution         - Institution requested to carry out the schedule
                   i_id_instit_requests     - Institution that requestes the schedule
                   i_clin_serv              - Clinical Service ID
                   i_id_prof                - Professional requested to carry out the schedule
                   i_id_prof_schedules      - Professional that created the schedule
                   i_epis_type              - Type of episode
                   i_id_pat                 - Patient ID
                   i_dt_schedule_begin      - Schedule begin date
                   i_dt_mcdt_begin          - MCDT begin date (exam or analysis)
                   i_id_analysis            - Analysis ID
                   i_id_exam                - Exam ID
          Sada:   O_ERROR                  - Error
        
          CRIAO: Patrcia Neto 2007/07/23
          NOTAS:
        *********************************************************************************/
        l_dep       department.id_department%TYPE; -- Department ID for Schedule
        l_epis_type episode.id_epis_type%TYPE; -- Type of episode
        --apagar
        l_epis_type_con episode.id_epis_type%TYPE; -- Type of episode
        l_epis_type_lab episode.id_epis_type%TYPE; -- Type of episode
        l_epis_type_rad episode.id_epis_type%TYPE; -- Type of episode
        --
        l_new_id_sched       schedule.id_schedule%TYPE; -- OUTPUT from 'created_schedule_oupt' to other functions in Interf_info
        l_episode            episode.id_episode%TYPE; -- Episode ID
        l_warning            VARCHAR2(2000); -- Warnig from 'create_schedule_outp'
        l_prof               profissional; -- Array professional
        interf_input         pk_schedule_interface.schedule_outp_struct; -- Type record, inputs to 'create_schedule_outp'
        l_dep_clin_serv      dep_clin_serv.id_dep_clin_serv%TYPE; -- Dep_Clin_serv ID
        l_lang               NUMBER := 1; -- Defaul language used
        l_analysis           table_number; -- Array analysis ID
        l_flg_type           table_varchar; -- Array analysis type ('E' ou 'G')
        l_flg_show_analysis  VARCHAR2(1); -- Y, existe msg para mostrar; N,  existe
        l_msg_title_analysis VARCHAR2(4000); -- Ttulo da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
        l_button_analysis    VARCHAR2(4000); -- Botes a mostrar: N - no, R - lido, C - confirmado
        l_analysis_req       table_number;
        l_analysis_req_det   table_number;
        l_analysis_req_par   table_number; -- ID do detalhe de requisio criado
        l_exam               table_number; -- Array de IDs de exame
        l_flg_show_exam      VARCHAR2(1); -- Y - existe msg para mostrar; N -  existe
        l_msg_req_exam       VARCHAR2(4000); -- mensagem com exames q foram requisitados recentemente
        l_msg_title_exam     VARCHAR2(4000); -- Ttulo da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
        l_button_exam        VARCHAR2(4000); -- Botes a mostrar: N - no, R - lido, C - confirmado. Tb pode mostrar combinaes destes, qd  p/ mostrar + do q 1 boto
        l_exam_req_array     table_number; -- ID do detalhe de requisio criado
        l_exam_req_det_array table_number;
        --
        -- Declarao do interf_input:
        l_id_schedule NUMBER := NULL; -- Schedule identifier (only filled on GETs)
        -- l_id_instit_requests NUMBER := NULL; -- Institution that requested the schedule (Optional for create_schedule_outp)
        l_id_dcs_requests    NUMBER := NULL; -- Department-Clinical Service that requested the schedule (Optional for create_schedule_outp)
        l_id_prof_requests   NUMBER := NULL; -- Professional that requests the schedule (Option for create_schedule_outp).
        l_id_prof_cancel     NUMBER := NULL; -- Professional that cancelled the schedule (Optional for create_schedule_outp).
        l_id_cancel_reason   NUMBER := NULL; -- Cancellation reason (Optional for create_schedule_outp).
        l_id_lang_translator NUMBER := NULL; -- Translator language (Optional for create_schedule_outp).
        l_id_lang_preferred  NUMBER := NULL; -- Preferred language (Optional for create_schedule_outp).
        l_id_reason          NUMBER := NULL; -- Reason for the schedule (Optional for create_schedule_outp).
        l_id_origin          NUMBER := NULL; -- Origin (Optional for create_schedule_outp).
        l_id_room            NUMBER := NULL; -- Room (Optional for create_schedule_outp).
        l_id_schedule_ref    NUMBER := NULL; -- Previous schedule, if this schedule is a result of a reschedule (Optional for create_schedule_outp).
        l_dt_end             TIMESTAMP WITH LOCAL TIME ZONE := NULL; -- Schedule end date (Optional for create_schedule_outp).
        l_dt_cancel          TIMESTAMP WITH LOCAL TIME ZONE := NULL; -- Cancellation date (Optional for create_schedule_outp).
        l_schedule_notes     VARCHAR2(4000) := NULL; -- Free-text for notes.
        l_flg_first_subs     VARCHAR2(0050) := 'B'; -- First or subsequent flag ('B', both, generic event)
        l_flg_notification   VARCHAR2(0050) := NULL; -- Notification flag
        l_flg_vacancy        VARCHAR2(0050) := NULL; -- Vacancy flag (WHEN NULL flg_vacancy = 'R')
        l_flg_status         VARCHAR2(0050) := NULL; -- Status flag (Optional for create_schedule_outp)
        l_flg_ignore_cancel  VARCHAR2(0050) := NULL; -- Whether or not should existing cancelled schedules be ignored on creation. (Optional for create_schedule_outp)
        l_reason_notes       VARCHAR2(4000) := NULL; -- Reason for the schedule in free-text (Optional for create_schedule_outp)
    
        -- GET ID_DEP_CLIN_SERV
        CURSOR c_dcs IS
            SELECT id_dep_clin_serv
              FROM dep_clin_serv
             WHERE id_department = l_dep
               AND id_clinical_service = i_clin_serv;
    
    BEGIN
    
        l_analysis           := table_number(i_id_analysis);
        l_flg_type           := table_varchar('E');
        l_analysis_req       := table_number();
        l_analysis_req_det   := table_number();
        l_analysis_req_par   := table_number();
        l_exam               := table_number(i_id_exam);
        l_exam_req_array     := table_number();
        l_exam_req_det_array := table_number();
        l_prof               := profissional(i_id_prof, i_id_institution, 0);
        l_epis_type_con      := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_CONSULT', i_prof => l_prof);
        l_epis_type_lab      := 12;
        l_epis_type_rad      := 13;
    
        --apagar
        IF i_epis_type = l_epis_type_con
        THEN
            l_epis_type := l_epis_type_con;
            l_dep       := pk_sysconfig.get_config(i_code_cf => 'ID_DEPARTMENT_CONSULT', i_prof => l_prof);
        ELSIF i_epis_type = l_epis_type_lab
        THEN
            l_epis_type := l_epis_type_lab;
            l_dep       := pk_sysconfig.get_config(i_code_cf => 'ID_DEPARTMENT_PATHOLOGY', i_prof => l_prof); -- i_clin_serv => 11
        ELSE
            l_epis_type := l_epis_type_rad;
            l_dep       := pk_sysconfig.get_config(i_code_cf => 'ID_DEPARTMENT_RADIOLOGY', i_prof => l_prof); -- i_clin_serv => 11
        END IF;
        --
    
        IF i_epis_type = l_epis_type
        THEN
            -- Agendamentos de exames associados a episdios de consulta
            -- l_dep := pk_sysconfig.get_config(i_code_cf => 'ID_DEPARTMENT_CONSULT', i_prof => l_prof);
        
            OPEN c_dcs;
            FETCH c_dcs
                INTO l_dep_clin_serv;
            CLOSE c_dcs;
        
            -- Inicilializao da varivel interf_input
            interf_input.id_schedule         := l_id_schedule; -- Schedule identifier (only filled on GETs)
            interf_input.id_instit_requests  := i_id_instit_requests; -- Institution that requested the schedule (Optional for CREATE)
            interf_input.id_instit_requested := i_id_institution; -- Institution that is requested for the schedule
            interf_input.id_dcs_requests     := l_id_dcs_requests; -- Department-Clinical Service that requested the schedule (Optional for CREATE)
            interf_input.id_dcs_requested    := l_dep_clin_serv; -- Department-Clinical Service that is requested for the schedule
            interf_input.id_prof_requests    := l_id_prof_requests; -- Professional that requests the schedule (Option for CREATE)
            interf_input.id_prof_requested   := i_id_prof; -- Professional requested to carry out the schedule
            interf_input.id_prof_schedules   := i_id_prof_schedules; -- Professional that created the schedule
            interf_input.id_prof_cancel      := l_id_prof_cancel; -- Professional that cancelled the schedule (Optional for CREATE)
            interf_input.id_epis_type        := l_epis_type; -- Episode type
            interf_input.id_cancel_reason    := l_id_cancel_reason; -- Cancellation reason (Optional for CREATE)
            interf_input.id_patient          := i_id_pat; -- Patient
            interf_input.id_lang_translator  := l_id_lang_translator; -- Translator language (Optional for CREATE)
            interf_input.id_lang_preferred   := l_id_lang_preferred; -- Preferred language (Optional for CREATE)
            interf_input.id_reason           := l_id_reason; -- Reason for the schedule (Optional for CREATE)
            interf_input.id_origin           := l_id_origin; -- Origin (Optional for CREATE)
            interf_input.id_room             := l_id_room; -- Room (Optional for CREATE)
            interf_input.id_schedule_ref     := l_id_schedule_ref; -- Previous schedule, if this schedule is a result of a reschedule (Optional for CREATE)
            interf_input.dt_begin            := i_dt_schedule_begin; -- Schedule begin date
            interf_input.dt_end              := l_dt_end; -- Schedule end date (Optional for CREATE)
            interf_input.dt_cancel           := l_dt_cancel; -- Cancellation date (Optional for CREATE)
            interf_input.schedule_notes      := l_schedule_notes; -- Free-text for notes.
            interf_input.flg_first_subs      := l_flg_first_subs; -- First or subsequent flag
            interf_input.flg_notification    := l_flg_notification; -- Notification flag
            interf_input.flg_vacancy         := l_flg_vacancy; -- Vacancy flag
            interf_input.flg_status          := l_flg_status; -- Status flag (Optional for CREATE)
            interf_input.flg_ignore_cancel   := l_flg_ignore_cancel; -- Whether or not should existing cancelled schedules be ignored on creation. (Optional for CREATE)
            interf_input.reason_notes        := l_reason_notes; -- Reason for the schedule in free-text (Optional for CREATE)
        
            -- Agendamento de consulta
            g_error := 'CALL CREATE SCHEDULE OUTP';
            IF NOT pk_schedule_interface.create_schedule_outp(i_sched_outp   => interf_input,
                                                              o_new_id_sched => l_new_id_sched,
                                                              o_warning      => l_warning,
                                                              o_error        => o_error)
            
            THEN
                --o_error := l_error;
                pk_utils.undo_changes;
                dbms_output.put_line('erro no create_schedule_outp');
                RETURN FALSE;
            END IF;
        
            dbms_output.put_line('o_new_id_sched = ' || l_new_id_sched);
        
            -- Episdio de consulta
            g_error := 'CALL CREATE VISIT';
            IF NOT pk_visit.create_visit(i_lang            => l_lang,
                                         i_id_pat          => i_id_pat,
                                         i_id_institution  => i_id_institution,
                                         i_id_sched        => l_new_id_sched,
                                         i_id_professional => l_prof,
                                         i_id_episode      => NULL,
                                         i_external_cause  => NULL,
                                         i_health_plan     => NULL,
                                         i_epis_type       => l_epis_type,
                                         i_dep_clin_serv   => l_dep_clin_serv,
                                         i_origin          => l_id_origin,
                                         i_flg_ehr         => 'N',
                                         o_episode         => l_episode,
                                         o_error           => o_error)
            THEN
                --o_error := t_error_out;
                pk_utils.undo_changes;
                dbms_output.put_line(' erro no create visit');
                RETURN FALSE;
            END IF;
        
            -- Requisio de MCDTs
            IF nvl(i_id_analysis, 0) != 0
            THEN
                g_error := 'CALL CREATE ANALYSIS REQUEST';
                IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => l_lang,
                                                                 i_prof                    => l_prof,
                                                                 i_patient                 => i_id_pat,
                                                                 i_episode                 => l_episode,
                                                                 i_analysis_req            => NULL,
                                                                 i_analysis_req_det        => table_number(NULL),
                                                                 i_analysis_req_det_parent => table_number(NULL),
                                                                 i_harvest                 => NULL,
                                                                 i_analysis                => l_analysis,
                                                                 i_analysis_group          => table_table_varchar(table_varchar(NULL)),
                                                                 i_flg_type                => table_varchar('A'),
                                                                 i_dt_req                  => table_varchar(NULL),
                                                                 i_flg_time                => table_varchar('B'),
                                                                 i_dt_begin                => table_varchar(pk_date_utils.date_send_tsz(l_lang,
                                                                                                                                        i_dt_mcdt_begin,
                                                                                                                                        l_prof)),
                                                                 i_dt_begin_limit          => table_varchar(NULL),
                                                                 i_episode_destination     => table_number(NULL),
                                                                 i_order_recurrence        => table_number(NULL),
                                                                 i_priority                => table_varchar('N'),
                                                                 i_flg_prn                 => table_varchar('N'),
                                                                 i_notes_prn               => table_varchar(NULL),
                                                                 i_specimen                => table_number(NULL),
                                                                 i_body_location           => table_table_number(table_number(NULL)),
                                                                 i_laterality              => table_table_varchar(table_varchar(NULL)),
                                                                 i_collection_room         => table_number(NULL),
                                                                 i_notes                   => table_varchar(NULL),
                                                                 i_notes_scheduler         => table_varchar(NULL),
                                                                 i_notes_technician        => table_varchar(NULL),
                                                                 i_notes_patient           => table_varchar(NULL),
                                                                 i_diagnosis_notes         => table_varchar(NULL),
                                                                 i_diagnosis               => NULL,
                                                                 i_exec_institution        => table_number(NULL),
                                                                 i_clinical_purpose        => table_number(NULL),
                                                                 i_clinical_purpose_notes  => table_varchar(NULL),
                                                                 i_flg_col_inst            => table_varchar('Y'),
                                                                 i_flg_fasting             => table_varchar('N'),
                                                                 i_lab_req                 => table_number(NULL),
                                                                 i_prof_cc                 => table_table_varchar(table_varchar(NULL)),
                                                                 i_prof_bcc                => table_table_varchar(table_varchar(NULL)),
                                                                 i_codification            => table_number(NULL),
                                                                 i_health_plan             => table_number(NULL),
                                                                 i_exemption               => table_number(NULL),
                                                                 i_prof_order              => table_number(l_prof.id),
                                                                 i_dt_order                => table_varchar(pk_date_utils.date_send_tsz(l_lang,
                                                                                                                                        i_dt_mcdt_begin,
                                                                                                                                        l_prof)),
                                                                 i_order_type              => table_number(NULL),
                                                                 i_clinical_question       => table_table_number(table_number(NULL)),
                                                                 i_response                => table_table_varchar(table_varchar(NULL)),
                                                                 i_clinical_question_notes => table_table_varchar(table_varchar(NULL)),
                                                                 i_clinical_decision_rule  => table_number(NULL),
                                                                 i_flg_origin_req          => 'D',
                                                                 i_task_dependency         => table_number(NULL),
                                                                 i_flg_task_depending      => table_varchar('N'),
                                                                 i_episode_followup_app    => table_number(NULL),
                                                                 i_schedule_followup_app   => table_number(NULL),
                                                                 i_event_followup_app      => table_number(NULL),
                                                                 i_test                    => 'N',
                                                                 o_flg_show                => l_flg_show_analysis,
                                                                 o_msg_title               => l_msg_title_analysis,
                                                                 o_msg_req                 => l_flg_show_analysis,
                                                                 o_button                  => l_button_analysis,
                                                                 o_analysis_req_array      => l_analysis_req,
                                                                 o_analysis_req_det_array  => l_analysis_req_det,
                                                                 o_analysis_req_par_array  => l_analysis_req_par,
                                                                 o_error                   => o_error)
                THEN
                    pk_utils.undo_changes;
                    dbms_output.put_line('erro nas analises');
                    RETURN FALSE;
                END IF;
            
            ELSIF nvl(i_id_exam, 0) != 0
            THEN
                g_error := 'CALL CREATE EXAM REQUEST';
                IF NOT pk_exams_api_db.create_exam_order(i_lang                    => l_lang,
                                                         i_prof                    => l_prof,
                                                         i_patient                 => i_id_pat,
                                                         i_episode                 => l_episode,
                                                         i_exam_req                => NULL,
                                                         i_exam_req_det            => table_number(NULL),
                                                         i_exam                    => l_exam,
                                                         i_flg_type                => l_flg_type,
                                                         i_dt_req                  => table_varchar(NULL),
                                                         i_flg_time                => table_varchar('B'),
                                                         i_dt_begin                => table_varchar(pk_date_utils.date_send_tsz(l_lang,
                                                                                                                                i_dt_mcdt_begin,
                                                                                                                                l_prof)),
                                                         i_dt_begin_limit          => table_varchar(NULL),
                                                         i_episode_destination     => table_number(NULL),
                                                         i_order_recurrence        => table_number(NULL),
                                                         i_priority                => table_varchar('N'),
                                                         i_flg_prn                 => table_varchar(NULL),
                                                         i_notes_prn               => table_varchar(NULL),
                                                         i_flg_fasting             => table_varchar(NULL),
                                                         i_notes                   => table_varchar(NULL),
                                                         i_notes_scheduler         => table_varchar(NULL),
                                                         i_notes_technician        => table_varchar(NULL),
                                                         i_notes_patient           => table_varchar(NULL),
                                                         i_diagnosis_notes         => table_varchar(NULL),
                                                         i_diagnosis               => NULL,
                                                         i_exec_room               => table_number(NULL),
                                                         i_exec_institution        => table_number(NULL),
                                                         i_clinical_purpose        => table_number(NULL),
                                                         i_codification            => table_number(NULL),
                                                         i_health_plan             => table_number(NULL),
                                                         i_prof_order              => table_number(l_prof.id),
                                                         i_dt_order                => table_varchar(pk_date_utils.date_send_tsz(l_lang,
                                                                                                                                i_dt_mcdt_begin,
                                                                                                                                l_prof)),
                                                         i_order_type              => table_number(NULL),
                                                         i_clinical_question       => table_table_number(table_number(NULL)),
                                                         i_response                => table_table_varchar(table_varchar(NULL)),
                                                         i_clinical_question_notes => table_table_varchar(table_varchar(NULL)),
                                                         i_clinical_decision_rule  => table_number(NULL),
                                                         i_flg_origin_req          => 'D',
                                                         i_task_dependency         => table_number(NULL),
                                                         i_flg_task_depending      => table_varchar('N'),
                                                         i_episode_followup_app    => table_number(NULL),
                                                         i_schedule_followup_app   => table_number(NULL),
                                                         i_event_followup_app      => table_number(NULL),
                                                         i_test                    => 'N',
                                                         o_flg_show                => l_flg_show_exam,
                                                         o_msg_title               => l_msg_title_exam,
                                                         o_msg_req                 => l_msg_req_exam,
                                                         o_button                  => l_button_exam,
                                                         o_exam_req_array          => l_exam_req_array,
                                                         o_exam_req_det_array      => l_exam_req_det_array,
                                                         o_error                   => o_error)
                
                THEN
                    -- o_error := l_error;
                    pk_utils.undo_changes;
                    dbms_output.put_line('erro nos exames');
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'INTERF_INFO',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END interf_info;

    PROCEDURE lock_schedule_record(i_id_sched IN epis_info.id_schedule%TYPE) IS
        l_id_schedule epis_info.id_schedule%TYPE;
    BEGIN
        SELECT s.id_schedule
          INTO l_id_schedule
          FROM schedule s
         WHERE s.id_schedule = i_id_sched
           FOR UPDATE;
    END;

    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_ext_value            IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception_ext EXCEPTION;
    BEGIN
        IF NOT call_create_visit(i_lang                 => i_lang,
                                 i_id_pat               => i_id_pat,
                                 i_id_institution       => i_id_institution,
                                 i_id_sched             => i_id_sched,
                                 i_id_professional      => i_id_professional,
                                 i_id_episode           => i_id_episode,
                                 i_external_cause       => i_external_cause,
                                 i_health_plan          => i_health_plan,
                                 i_epis_type            => i_epis_type,
                                 i_dep_clin_serv        => i_dep_clin_serv,
                                 i_origin               => i_origin,
                                 i_flg_ehr              => i_flg_ehr,
                                 i_dt_begin             => i_dt_begin,
                                 i_flg_appointment_type => i_flg_appointment_type,
                                 i_transaction_id       => i_transaction_id,
                                 i_ext_value            => i_ext_value,
                                 i_id_prof_in_charge    => NULL,
                                 i_flg_unknown          => i_flg_unknown,
                                 o_episode              => o_episode,
                                 o_error                => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_ext THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END call_create_visit;

    /******************************************************************************
       OBJECTIVO: Criar registo de visita. Se j existe visita e/ou episdio activos,so fechados!!
       PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                 I_ID_PAT - Utente
                 I_ID_INSTITUTION - Instituio
                 I_ID_SCHED - agendamento q origina a visita
                 I_ID_PROFESSIONAL - profissional responsvel
                 I_ID_EPISODE - ID do episdio, quando esse ID j vem do Interface (Sonho)
                 I_EXTERNAL_CAUSE - causa de admisso (SAP)
                 I_HEALTH_PLAN - plano de sade activado para o episdio
                 I_EPIS_TYPE - Tipo de episdio
                 I_DEP_CLIN_SERV - ID do servio clnico do departamento
                 I_ORIGIN - ID da origem do episdio
            Saida:   O_ERROR - erro
    
      CRIAO: CRS 2005/02/25
      ALTERAO: ET 2007/05/29
           CMF 2008-02-11 Comentado cdigo que fazia update  visita/episode anteriores
      NOTAS:
    *********************************************************************************/
    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_ext_value            IN epis_ext_sys.value%TYPE DEFAULT NULL,
        i_id_prof_in_charge    IN professional.id_professional%TYPE,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_visit           visit.id_visit%TYPE;
        l_id_episode         episode.id_episode%TYPE;
        l_epis_type          epis_type.id_epis_type%TYPE;
        l_other_id_episode   episode.id_episode%TYPE;
        l_other_id_epis_type episode.id_epis_type%TYPE;
    
        l_update_inp_prev_episode BOOLEAN := FALSE;
        l_inp_id_episode          episode.id_episode%TYPE;
        l_new_id_episode          episode.id_episode%TYPE;
        l_id_clinical_service     clinical_service.id_clinical_service%TYPE;
    
        l_rowids table_varchar;
    
        --
        l_id_visit_ref visit.id_visit%TYPE;
        l_id_ref_map   ref_map.id_ref_map%TYPE;
        l_ref_error    t_error_out;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
        CURSOR c_visit IS
            SELECT e.id_visit, ei.id_episode
              FROM epis_info ei, episode e
             WHERE ei.id_episode = e.id_episode
               AND id_schedule = i_id_sched;
    
        l_flg_show                VARCHAR2(1 CHAR);
        l_msg_title               sys_message.desc_message%TYPE;
        l_msg_body                sys_message.desc_message%TYPE;
        l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
        l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
        l_exception_ext EXCEPTION;
        l_id_software software.id_software%TYPE;
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_sched IS NOT NULL
           AND i_id_sched != -1
        THEN
            lock_schedule_record(i_id_sched);
        END IF;
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_id_visit, l_id_episode;
        g_found := c_visit%NOTFOUND;
        CLOSE c_visit;
    
        -- ambulatory products do not specify the episode type...
        IF i_epis_type IS NULL
        THEN
            -- instead, get it by schedule
            l_epis_type := get_epis_type(i_schedule => i_id_sched);
        ELSE
            -- otherwise, use input parameter
            l_epis_type := i_epis_type;
        END IF;
    
        g_error := 'l_epis_type = ' || l_epis_type;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => 'CALL_CREATE_VISIT');
    
        IF l_id_visit IS NULL
        THEN
            IF i_ext_value IS NOT NULL
            THEN
                -- Search for another episode with the same external value.
                BEGIN
                    g_error := 'GET EPISODE COUNT';
                    SELECT ees.id_episode
                      INTO l_other_id_episode
                      FROM epis_ext_sys ees
                      JOIN episode e
                        ON e.id_episode = ees.id_episode
                     WHERE ees.value = i_ext_value
                       AND ees.id_institution = i_id_institution
                       AND ees.id_episode <> nvl(i_id_episode, 0)
                       AND e.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_other_id_episode := NULL;
                END;
            
                -- If found, use the same visit ID to the new episode.
                IF l_other_id_episode IS NOT NULL
                THEN
                    g_error := 'GET VISIT ID';
                    SELECT e.id_visit, e.id_epis_type
                      INTO l_id_visit, l_other_id_epis_type
                      FROM episode e
                     WHERE e.id_episode = l_other_id_episode;
                END IF;
            
                IF l_other_id_epis_type = pk_alert_constant.g_epis_type_inpatient
                   AND l_epis_type = pk_alert_constant.g_epis_type_emergency
                THEN
                    -- If an INPATIENT episode was already created, and the current episode is an EDIS episode,
                    -- then the ID_PREV_EPISODE/ID_PREV_EPIS_TYPE data in the INPATIENT episode must match
                    -- the current episode.
                    l_update_inp_prev_episode := TRUE;
                    l_inp_id_episode          := l_other_id_episode;
                END IF;
            END IF;
        
            IF l_id_visit IS NULL
            THEN
                g_error    := 'GET SEQ_VISIT.NEXTVAL';
                l_id_visit := seq_visit.nextval;
            
                g_error := 'INSERT INTO VISIT';
                INSERT INTO visit
                    (id_visit,
                     dt_begin_tstz,
                     flg_status,
                     id_patient,
                     id_institution,
                     id_external_cause,
                     id_origin,
                     dt_creation)
                VALUES
                    (l_id_visit,
                     nvl(i_dt_begin, g_sysdate_tstz),
                     g_visit_active,
                     i_id_pat,
                     i_id_professional.institution,
                     i_external_cause,
                     i_origin,
                     g_sysdate_tstz); -- dt_creation should always be current_timestamp and it can be different from dt_begin
            END IF;
        
            g_error := 'CALL TO CREATE_EPISODE1';
            IF NOT create_episode(i_lang                 => i_lang,
                                  i_id_visit             => l_id_visit,
                                  i_id_professional      => i_id_professional,
                                  i_id_sched             => i_id_sched,
                                  i_id_episode           => i_id_episode,
                                  i_health_plan          => i_health_plan,
                                  i_epis_type            => l_epis_type,
                                  i_dep_clin_serv        => i_dep_clin_serv,
                                  i_sysdate              => nvl(i_dt_begin, SYSDATE),
                                  i_sysdate_tstz         => nvl(i_dt_begin, g_sysdate_tstz),
                                  i_flg_ehr              => i_flg_ehr,
                                  i_flg_appointment_type => i_flg_appointment_type,
                                  i_flg_unknown          => i_flg_unknown,
                                  i_transaction_id       => l_transaction_id,
                                  o_episode              => l_new_id_episode,
                                  o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSE
            g_error := 'CALL TO CREATE_EPISODE2';
            IF NOT create_episode(i_lang                 => i_lang,
                                  i_id_visit             => l_id_visit,
                                  i_id_professional      => i_id_professional,
                                  i_id_sched             => i_id_sched,
                                  i_id_episode           => l_id_episode,
                                  i_health_plan          => i_health_plan,
                                  i_epis_type            => l_epis_type,
                                  i_dep_clin_serv        => i_dep_clin_serv,
                                  i_sysdate              => nvl(i_dt_begin, SYSDATE),
                                  i_sysdate_tstz         => nvl(i_dt_begin, g_sysdate_tstz),
                                  i_flg_ehr              => i_flg_ehr,
                                  i_flg_appointment_type => i_flg_appointment_type,
                                  i_transaction_id       => l_transaction_id,
                                  o_episode              => l_new_id_episode,
                                  o_error                => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- ALERT-258957 - Mario Mineiro - Now this code happens when efectivate the pacient in: PK_VISIT.CREATE_VISIT
            -- Getting the clin service
            g_error := 'GET DEPARTMENT ID';
            IF i_dep_clin_serv IS NOT NULL
            THEN
                SELECT dcs.id_clinical_service
                  INTO l_id_clinical_service
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = i_dep_clin_serv;
            END IF;
            -- Nao deve correr este codigo se for um episodio do tipo de tratamento
            IF i_epis_type != g_epis_type_session
            THEN
                --Verificar se existem requisies e prescries de exames, etc no episdio anterior para este episdio.
                IF NOT create_exam_req_presc(i_lang            => i_lang,
                                             i_id_episode      => l_new_id_episode,
                                             i_id_patient      => i_id_pat,
                                             i_id_clin_service => l_id_clinical_service, -- clinical service
                                             i_prof            => i_id_professional,
                                             o_error           => o_error)
                THEN
                    -- o_error := l_error;
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
            -- Never update prev. episode when following this workflow.
            l_update_inp_prev_episode := FALSE;
        END IF;
    
        IF l_update_inp_prev_episode
           AND l_new_id_episode IS NOT NULL
        THEN
            -- Update previous episode of INP episode after creating EDIS episode.
            g_error := 'UPDATE INP PREV EPISODE';
            pk_alertlog.log_debug(g_error);
            ts_episode.upd(id_episode_in         => l_inp_id_episode,
                           id_prev_episode_in    => l_new_id_episode,
                           id_prev_episode_nin   => FALSE,
                           id_prev_epis_type_in  => l_epis_type,
                           id_prev_epis_type_nin => FALSE,
                           rows_out              => l_rowids);
        
            g_error := 'PROCESS UPDATE - EPISODE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_id_professional,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids,
                                          i_list_columns => table_varchar('ID_PREV_EPISODE', 'ID_PREV_EPIS_TYPE'),
                                          o_error        => o_error);
        END IF;
    
        --
        --[OA -  05/NOV/2009]
        --ALERT-27343 - Call referral function for Outpatient episodes
        IF l_epis_type = pk_alert_constant.g_epis_type_outpatient
           AND i_flg_ehr = pk_alert_constant.g_flg_ehr_n -- when registering the patient
        THEN
            IF NOT pk_api_ref_circle.set_ref_map_from_episode(i_lang     => i_lang,
                                                              i_prof     => i_id_professional,
                                                              i_schedule => i_id_sched,
                                                              i_episode  => l_id_episode,
                                                              o_visit    => l_id_visit_ref,
                                                              o_ref_map  => l_id_ref_map,
                                                              o_error    => l_ref_error)
            THEN
                -- o_error := l_error;
                --log the error and continue...
                pk_alertlog.log_error(l_ref_error.ora_sqlcode || ' - ' || l_ref_error.ora_sqlerrm);
            END IF;
        END IF;
    
        IF i_flg_ehr = pk_alert_constant.g_flg_ehr_n
        THEN
            pk_ia_event_common.episode_register(i_id_institution => i_id_professional.institution,
                                                i_id_episode     => l_new_id_episode);
        END IF;
    
        IF i_id_prof_in_charge IS NOT NULL
        THEN
            BEGIN
                SELECT ei.id_software
                  INTO l_id_software
                  FROM epis_info ei
                 WHERE ei.id_episode = l_new_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_software := i_id_professional.software;
            END;
        
            IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                          i_prof                    => i_id_professional,
                                                          i_id_episode              => l_new_id_episode,
                                                          i_id_prof_resp            => i_id_prof_in_charge,
                                                          i_id_speciality           => pk_prof_utils.get_prof_speciality_id(i_lang => i_lang,
                                                                                                                            i_prof => profissional(i_id_prof_in_charge,
                                                                                                                                                   i_id_professional.institution,
                                                                                                                                                   l_id_software)),
                                                          i_notes                   => NULL,
                                                          i_flg_epis_respons        => pk_alert_constant.g_no,
                                                          o_flg_show                => l_flg_show,
                                                          o_msg_title               => l_msg_title,
                                                          o_msg_body                => l_msg_body,
                                                          o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                          o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                          o_error                   => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END IF;
    
        IF NOT pk_ea_logic_procedures.set_grid_task_procedures_across(i_lang    => i_lang,
                                                                      i_prof    => i_id_professional,
                                                                      i_patient => i_id_pat,
                                                                      o_error   => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        o_episode := l_new_id_episode;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CALL_CREATE_VISIT',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            RETURN FALSE;
    END;

    /** Flash wrapper do not use otherwise */
    FUNCTION call_create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE DEFAULT current_timestamp,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_retval         BOOLEAN;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_id_professional);
    
        l_retval := call_create_visit(i_lang                 => i_lang,
                                      i_id_pat               => i_id_pat,
                                      i_id_institution       => i_id_institution,
                                      i_id_sched             => i_id_sched,
                                      i_id_professional      => i_id_professional,
                                      i_id_episode           => i_id_episode,
                                      i_external_cause       => i_external_cause,
                                      i_health_plan          => i_health_plan,
                                      i_epis_type            => i_epis_type,
                                      i_dep_clin_serv        => i_dep_clin_serv,
                                      i_origin               => i_origin,
                                      i_flg_ehr              => i_flg_ehr,
                                      i_dt_begin             => i_dt_begin,
                                      i_flg_appointment_type => i_flg_appointment_type,
                                      i_transaction_id       => l_transaction_id,
                                      o_episode              => o_episode,
                                      o_error                => o_error);
    
        IF NOT l_retval
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            -- sendo invocada pelo flash nao devia haver aqui um commit?
        ELSE
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
            -- sendo invocada pelo flash nao devia haver aqui um rollback?
        END IF;
    
        RETURN l_retval;
    
    END call_create_visit;

    FUNCTION create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        g_error := 'PK_VISIT.CALL_CREATE_VISIT';
        IF NOT call_create_visit(i_lang                 => i_lang,
                                 i_id_pat               => i_id_pat,
                                 i_id_institution       => i_id_institution,
                                 i_id_sched             => i_id_sched,
                                 i_id_professional      => i_id_professional,
                                 i_id_episode           => i_id_episode,
                                 i_external_cause       => i_external_cause,
                                 i_health_plan          => i_health_plan,
                                 i_epis_type            => i_epis_type,
                                 i_dep_clin_serv        => i_dep_clin_serv,
                                 i_origin               => i_origin,
                                 i_flg_ehr              => i_flg_ehr,
                                 i_dt_begin             => nvl(i_dt_begin, current_timestamp),
                                 i_flg_appointment_type => i_flg_appointment_type,
                                 i_transaction_id       => l_transaction_id,
                                 o_episode              => o_episode,
                                 o_error                => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        COMMIT;
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_id_professional);
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_visit;

    FUNCTION create_visit_no_commit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        g_error := 'PK_VISIT.CALL_CREATE_VISIT';
        IF NOT call_create_visit(i_lang                 => i_lang,
                                 i_id_pat               => i_id_pat,
                                 i_id_institution       => i_id_institution,
                                 i_id_sched             => i_id_sched,
                                 i_id_professional      => i_id_professional,
                                 i_id_episode           => i_id_episode,
                                 i_external_cause       => i_external_cause,
                                 i_health_plan          => i_health_plan,
                                 i_epis_type            => i_epis_type,
                                 i_dep_clin_serv        => i_dep_clin_serv,
                                 i_origin               => i_origin,
                                 i_flg_ehr              => i_flg_ehr,
                                 i_dt_begin             => nvl(i_dt_begin, current_timestamp),
                                 i_flg_appointment_type => i_flg_appointment_type,
                                 i_transaction_id       => l_transaction_id,
                                 o_episode              => o_episode,
                                 o_error                => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_id_professional);
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_ext THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_visit_no_commit;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_visit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_pat               IN patient.id_patient%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_professional      IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_external_cause       IN visit.id_external_cause%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin               IN visit.id_origin%TYPE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.create_visit(i_lang                 => i_lang,
                                     i_id_pat               => i_id_pat,
                                     i_id_institution       => i_id_institution,
                                     i_id_sched             => i_id_sched,
                                     i_id_professional      => i_id_professional,
                                     i_id_episode           => i_id_episode,
                                     i_external_cause       => i_external_cause,
                                     i_health_plan          => i_health_plan,
                                     i_epis_type            => i_epis_type,
                                     i_dep_clin_serv        => i_dep_clin_serv,
                                     i_origin               => i_origin,
                                     i_flg_ehr              => i_flg_ehr,
                                     i_dt_begin             => i_dt_begin,
                                     i_flg_appointment_type => i_flg_appointment_type,
                                     i_transaction_id       => NULL,
                                     o_episode              => o_episode,
                                     o_error                => o_error);
    
    END create_visit;

    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin        IN episode.dt_begin_tstz%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        g_error := 'PK_VISIT.CREATE_VISIT';
        IF NOT create_visit(i_lang                 => i_lang,
                            i_id_pat               => i_id_pat,
                            i_id_institution       => i_id_institution,
                            i_id_sched             => i_id_sched,
                            i_id_professional      => i_id_professional,
                            i_id_episode           => i_id_episode,
                            i_external_cause       => i_external_cause,
                            i_health_plan          => i_health_plan,
                            i_epis_type            => i_epis_type,
                            i_dep_clin_serv        => i_dep_clin_serv,
                            i_origin               => i_origin,
                            i_flg_ehr              => i_flg_ehr,
                            i_dt_begin             => current_timestamp,
                            i_flg_appointment_type => NULL,
                            i_transaction_id       => l_transaction_id,
                            o_episode              => o_episode,
                            o_error                => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        COMMIT;
        pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_id_professional);
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_visit;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_dt_begin        IN episode.dt_begin_tstz%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.create_visit(i_lang            => i_lang,
                                     i_id_pat          => i_id_pat,
                                     i_id_institution  => i_id_institution,
                                     i_id_sched        => i_id_sched,
                                     i_id_professional => i_id_professional,
                                     i_id_episode      => i_id_episode,
                                     i_external_cause  => i_external_cause,
                                     i_health_plan     => i_health_plan,
                                     i_epis_type       => i_epis_type,
                                     i_dep_clin_serv   => i_dep_clin_serv,
                                     i_origin          => i_origin,
                                     i_flg_ehr         => i_flg_ehr,
                                     i_dt_begin        => i_dt_begin,
                                     i_transaction_id  => NULL,
                                     o_episode         => o_episode,
                                     o_error           => o_error);
    
    END create_visit;

    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception_int EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        g_error := 'PK_VISIT.CREATE_VISIT';
        IF NOT create_visit(i_lang            => i_lang,
                            i_id_pat          => i_id_pat,
                            i_id_institution  => i_id_institution,
                            i_id_sched        => i_id_sched,
                            i_id_professional => i_id_professional,
                            i_id_episode      => i_id_episode,
                            i_external_cause  => i_external_cause,
                            i_health_plan     => i_health_plan,
                            i_epis_type       => i_epis_type,
                            i_dep_clin_serv   => i_dep_clin_serv,
                            i_origin          => i_origin,
                            i_flg_ehr         => i_flg_ehr,
                            i_dt_begin        => current_timestamp,
                            i_transaction_id  => l_transaction_id,
                            o_episode         => o_episode,
                            o_error           => o_error)
        THEN
            RAISE l_exception_int;
        END IF;
    
        COMMIT;
        pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_id_professional);
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN l_exception_int THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_visit;

    FUNCTION create_visit
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_external_cause  IN visit.id_external_cause%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_origin          IN visit.id_origin%TYPE,
        i_flg_ehr         IN episode.flg_ehr%TYPE DEFAULT 'N',
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.create_visit(i_lang            => i_lang,
                                     i_id_pat          => i_id_pat,
                                     i_id_institution  => i_id_institution,
                                     i_id_sched        => i_id_sched,
                                     i_id_professional => i_id_professional,
                                     i_id_episode      => i_id_episode,
                                     i_external_cause  => i_external_cause,
                                     i_health_plan     => i_health_plan,
                                     i_epis_type       => i_epis_type,
                                     i_dep_clin_serv   => i_dep_clin_serv,
                                     i_origin          => i_origin,
                                     i_flg_ehr         => i_flg_ehr,
                                     i_transaction_id  => NULL,
                                     o_episode         => o_episode,
                                     o_error           => o_error);
    
    END create_visit;

    /******************************************************************************
       OBJECTIVO:   Criar registo de episdio de consulta, associado a agendamento.
           Se existem episdios activos p/ esta visita, so fechados!!
       PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
           I_ID_VISIT - ID da visita. Pode  vir preenchido
           I_ID_PROFESSIONAL - profissional responsvel
           I_ID_SCHED - agendamento q origina a visita
                             I_ID_EPISODE - ID do episdio, quando esse ID j vem do Interface (Sonho)
                             I_HEALTH_PLAN - plano de sade activado para o episdio
         I_EPIS_TYPE - Tipo de episdio
         I_DEP_CLIN_SERV - Servio clinico do departamento
           Saida:   O_ERROR - erro
    
      CRIAO: CRS 2005/02/25
               Lus Gaspar, 2007-09-03: set the default episode touch option templates
      NOTAS:
    *********************************************************************************/
    FUNCTION create_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_professional IN profissional,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_seq_epis          NUMBER;
        l_seq_epis_inst     NUMBER;
        l_pat               visit.id_patient%TYPE;
        l_desc              VARCHAR2(4000);
        l_id_prof           sch_prof_outp.id_professional%TYPE;
        l_room              epis_type_room.id_room%TYPE;
        l_visit_status      visit.flg_status%TYPE;
        l_id_visit          visit.id_visit%TYPE;
        l_id_cs             clinical_service.id_clinical_service%TYPE;
        l_instit            visit.id_institution%TYPE;
        l_pat_hplan         pat_health_plan.id_pat_health_plan%TYPE;
        l_instit_type       institution.flg_type%TYPE;
        l_barcode           VARCHAR2(200);
        l_rank              NUMBER;
        l_epis_doc_template table_number;
        l_consult_subs      VARCHAR2(1);
        l_id_dep_clin_serv  schedule.id_dcs_requested%TYPE;
        l_id_department     department.id_department%TYPE;
        l_id_dept           dept.id_dept%TYPE;
        l_rowids            table_varchar := table_varchar();
        e_process_event EXCEPTION;
    
        l_id_dcs_requested  schedule.id_dcs_requested%TYPE;
        l_id_cs_requested   episode.id_cs_requested%TYPE;
        l_id_department_req department.id_department%TYPE;
        l_id_dept_req       dept.id_dept%TYPE;
    
        l_instit_requested  schedule.id_instit_requested%TYPE;
        l_id_prof_schedules schedule.id_prof_schedules%TYPE;
        l_flg_status_sched  schedule.flg_status%TYPE;
    
        l_id_schedule_outp schedule_outp.id_schedule_outp%TYPE;
        CURSOR c_sched IS
            SELECT p.id_professional,
                   dcs.id_clinical_service,
                   dpt.id_department,
                   dpt.id_dept,
                   decode(sp.flg_type, g_flg_type_s, g_consultsubs_y, g_consultsubs_n) consult_subs,
                   s.id_dcs_requested l_id_dep_clin_serv,
                   s.id_instit_requested,
                   s.id_prof_schedules,
                   s.flg_status,
                   sp.id_schedule_outp -- new tco 14/05/2009
              FROM schedule s, schedule_outp sp, sch_prof_outp p, dep_clin_serv dcs, department dpt
             WHERE s.id_schedule = i_id_sched
               AND s.flg_status != g_sched_cancel
                  --  AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporarios (SCH 3.0)
               AND sp.id_schedule = s.id_schedule
               AND p.id_schedule_outp(+) = sp.id_schedule_outp
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND dcs.id_department = dpt.id_department;
    
        CURSOR c_visit IS
            SELECT v.id_patient, v.flg_status, v.id_institution, i.flg_type
              FROM visit v, institution i
             WHERE id_visit = l_id_visit
               AND i.id_institution = v.id_institution;
    
        -- CRS 2007/02/24
        CURSOR c_epis_type
        (
            l_epis_type     epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION ALL
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv -- ET 2007/02/28
             ORDER BY rank DESC;
    
        CURSOR c_pat_hplan IS
            SELECT id_pat_health_plan
              FROM pat_health_plan
             WHERE id_patient = l_pat
               AND id_health_plan = i_health_plan
               AND flg_status = pk_alert_constant.g_active
               AND id_institution = i_id_professional.institution;
    
        CURSOR c_ehr IS
            SELECT flg_ehr
              FROM episode
             WHERE id_episode = i_id_episode;
    
        l_exam          table_number := table_number();
        l_exam_type     table_varchar := table_varchar();
        l_exam_time     table_varchar := table_varchar();
        l_exam_dt       table_varchar := table_varchar();
        l_exam_priority table_varchar := table_varchar();
    
        l_exam_t_number   table_number := table_number();
        l_exam_t_varchar  table_varchar := table_varchar();
        l_exam_tt_number  table_table_number := table_table_number();
        l_exam_tt_varchar table_table_varchar := table_table_varchar();
    
        l_flg_show VARCHAR2(100);
    
        l_msg_req            VARCHAR2(4000);
        l_msg_title          VARCHAR2(4000);
        l_button             VARCHAR2(100);
        l_exam_req_array     table_number;
        l_exam_req_det_array table_number;
    
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_id_software         software.id_software%TYPE;
    
        l_no_triage_color triage_color.id_triage_color%TYPE;
        l_error_in        t_error_in := t_error_in();
    
        l_episode_origin     episode.id_episode%TYPE;
        l_id_external_system epis_ext_sys.id_epis_ext_sys%TYPE;
        l_value              epis_ext_sys.value%TYPE;
        l_cod_epis_type_ext  epis_ext_sys.cod_epis_type_ext%TYPE;
        l_flg_ehr            episode.flg_ehr%TYPE;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_other_exception EXCEPTION;
        -- chronic medication
    
        chronic_medication_active VARCHAR2(1 CHAR) := pk_sysconfig.get_config('SHOW_PRESCRIPTION_CHRONIC',
                                                                              i_id_professional);
    
        -- chronic medication
        FUNCTION get_hhc_dcs
        (
            i_id_schedule  IN NUMBER,
            i_id_epis_type IN NUMBER,
            i_id_dcs       IN NUMBER
        ) RETURN NUMBER IS
            tbl_id   table_number;
            l_id_dcs NUMBER;
        BEGIN
        
            l_id_dcs := i_id_dcs;
            IF i_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
            
                SELECT id_dcs_requested
                  BULK COLLECT
                  INTO tbl_id
                  FROM schedule x
                 WHERE x.id_schedule = i_id_schedule;
            
                IF tbl_id.count > 0
                THEN
                    l_id_dcs := tbl_id(1);
                END IF;
            
            END IF;
        
            RETURN l_id_dcs;
        
        END get_hhc_dcs;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_id_visit := nvl(i_id_visit, 0);
        g_error    := 'GET CURSOR C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_pat, l_visit_status, l_instit, l_instit_type;
        CLOSE c_visit;
        IF l_visit_status = g_visit_inactive
           AND i_epis_type != pk_alert_constant.g_epis_type_rehab_session
        THEN
            -- o_error := pk_message.get_message(i_lang, 'VISIT_M003');
            l_error_in.set_action(pk_message.get_message(i_lang, 'VISIT_M003'), 'U');
            g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN FALSE;
        END IF;
    
        -- Profissional para quem  agendada a consulta que origina a visita
        g_error := 'GET CURSOR C_SCHED';
        OPEN c_sched;
        FETCH c_sched
            INTO l_id_prof,
                 l_id_cs_requested,
                 l_id_department_req,
                 l_id_dept_req,
                 l_consult_subs,
                 l_id_dcs_requested,
                 l_instit_requested,
                 l_id_prof_schedules,
                 l_flg_status_sched,
                 l_id_schedule_outp;
        CLOSE c_sched;
    
        -- Tipo de episodios (Normal/Sched)
        g_error := 'GET CURSOR c_ehr';
        OPEN c_ehr;
        FETCH c_ehr
            INTO l_flg_ehr;
        CLOSE c_ehr;
    
        -- Ariel Machado, April 04, 2008: If a clinical service of a department is sent in the function it's used,
        -- if it's null the value defined in the schedule is used
        IF i_dep_clin_serv IS NOT NULL
        THEN
            l_id_dep_clin_serv := i_dep_clin_serv;
        ELSE
            l_id_dep_clin_serv := l_id_dcs_requested;
        END IF;
    
        g_error := 'GET DEPARTMENT ID';
        IF l_id_dep_clin_serv IS NOT NULL
        THEN
            SELECT dcs.id_clinical_service, d.id_department, d.id_dept
              INTO l_id_cs, l_id_department, l_id_dept
              FROM dep_clin_serv dcs, department d
             WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv
               AND dcs.id_department = d.id_department;
        END IF;
    
        IF i_id_episode IS NULL
        THEN
            g_error    := 'GET CURSOR C_EPIS_SEQ';
            l_seq_epis := ts_episode.next_key;
        ELSE
            g_error    := 'GET CURSOR C_EPIS_SEQ';
            l_seq_epis := i_id_episode;
        END IF;
        --
        -- Gerar Barcode ET(2007/01/18)
        ------- GERAO DE CDIGO DE BARRAS
        g_error := 'CALL TO PK_BARCODE.GENERATE_BARCODE';
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => i_id_professional.institution,
                                           i_software     => i_id_professional.software,
                                           o_barcode      => l_barcode,
                                           o_error        => o_error)
        THEN
            --o_error := l_error;
            RETURN FALSE;
        END IF;
        --
        o_episode := l_seq_epis;
        --
        g_error := 'INSERT INTO EPISODE';
        ts_episode.ins(id_episode_in              => l_seq_epis,
                       id_visit_in                => i_id_visit,
                       id_patient_in              => l_pat,
                       id_clinical_service_in     => nvl(l_id_cs, -1),
                       id_department_in           => nvl(l_id_department, -1),
                       id_dept_in                 => nvl(l_id_dept, -1),
                       dt_begin_tstz_in           => g_sysdate_tstz,
                       id_epis_type_in            => i_epis_type,
                       flg_type_in                => pk_episode.g_flg_def,
                       flg_status_in              => g_epis_active,
                       barcode_in                 => l_barcode,
                       dt_creation_in             => g_sysdate_tstz,
                       id_institution_in          => l_instit,
                       id_cs_requested_in         => nvl(l_id_cs_requested, -1),
                       id_department_requested_in => nvl(l_id_department_req, -1),
                       id_dept_requested_in       => nvl(l_id_dept_req, -1),
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_id_professional,
                                                      i_patient     => l_pat,
                                                      i_new_episode => l_seq_epis,
                                                      o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        -- END ALERT-41412
    
        l_rowids := table_varchar();
    
        g_error := 'GET SEQ_EPIS_INSTITUTION.NEXTVAL';
        SELECT seq_epis_institution.nextval
          INTO l_seq_epis_inst
          FROM dual;
    
        g_error := 'INSERT INTO EPIS_INSTITUTION';
        INSERT INTO epis_institution
            (id_epis_institution, id_institution, id_episode)
        VALUES
            (l_seq_epis_inst, i_id_professional.institution, l_seq_epis);
    
        IF i_id_sched IS NOT NULL
        THEN
            -- Obter texto c/ info + actualizada do doente
            g_error := 'CALL TO PK_EPISODE.GET_EPIS_HEADER_INFO';
            IF NOT pk_episode.get_epis_header_info(i_lang        => i_lang,
                                                   i_id_pat      => l_pat,
                                                   i_id_schedule => i_id_sched,
                                                   i_institution => l_instit,
                                                   i_prof        => i_id_professional,
                                                   o_desc_info   => l_desc,
                                                   o_error       => o_error)
            THEN
                --o_error := l_error;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        /* ALERT-258957 - Mario Mineiro - Now this code happens when efectivate the pacient in: PK_VISIT.CREATE_VISIT
            -- Nao deve correr este codigo se for um episodio do tipo de tratamento
            IF i_epis_type != g_epis_type_session
            THEN
                --Verificar se existem requisies e prescries de exames, etc no episdio anterior para este episdio.
                IF NOT create_exam_req_presc(i_lang            => i_lang,
                                             i_id_episode      => l_seq_epis,
                                             i_id_patient      => l_pat,
                                             i_id_clin_service => l_id_cs_requested,
                                             i_prof            => i_id_professional,
                                             o_error           => o_error)
                THEN
                    -- o_error := l_error;
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        */
        -- get sala default
        g_error := 'GET CURSOR C_EPIS_TYPE';
        OPEN c_epis_type(i_epis_type, l_id_dep_clin_serv);
        FETCH c_epis_type
            INTO l_room, l_rank;
        CLOSE c_epis_type;
        --IF i_id_sched is null
        l_id_software := pk_episode.get_soft_by_epis_type(i_epis_type, i_id_professional.institution);
    
        -- Jos Brito 04/11/2008 Preencher EPIS_INFO.ID_TRIAGE_COLOR com a cr genrica do
        -- tipo de triagem usado na instituio actual
        g_error := 'GET NO TRIAGE COLOR';
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_id_professional, o_episode)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
        
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_VISIT',
                                                  'CREATE_EPISODE',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
        END;
    
        g_error            := 'INSERT INTO EPIS_INFO';
        l_id_dep_clin_serv := get_hhc_dcs(i_id_schedule  => i_id_sched,
                                          i_id_epis_type => i_epis_type,
                                          i_id_dcs       => l_id_dep_clin_serv);
        /* <DENORM Fbio> */
        ts_epis_info.ins(id_episode_in               => l_seq_epis,
                         id_schedule_in              => CASE
                                                            WHEN i_id_sched IS NULL THEN
                                                             -1
                                                            ELSE
                                                             i_id_sched
                                                        END,
                         id_room_in                  => l_room,
                         id_professional_in          => l_id_prof,
                         flg_unknown_in              => 'N',
                         desc_info_in                => l_desc,
                         flg_status_in               => g_epis_info_efectiv,
                         id_dep_clin_serv_in         => l_id_dep_clin_serv,
                         id_first_dep_clin_serv_in   => l_id_dep_clin_serv,
                         id_patient_in               => l_pat,
                         id_dcs_requested_in         => l_id_dcs_requested,
                         id_software_in              => l_id_software,
                         dt_last_interaction_tstz_in => g_sysdate_tstz,
                         triage_acuity_in            => pk_alert_constant.g_color_gray,
                         triage_color_text_in        => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in       => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in          => l_no_triage_color,
                         id_instit_requested_in      => l_instit_requested,
                         id_prof_schedules_in        => l_id_prof_schedules,
                         flg_sch_status_in           => l_flg_status_sched,
                         id_schedule_outp_in         => l_id_schedule_outp,
                         rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'INSERT DOC TRIAGE ALERT';
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               i_id_professional,
                                               l_seq_epis,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_nurse,
                                               pk_edis_triage.g_type_add,
                                               o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'INSERT EPIS WAITING ALERT';
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               i_id_professional,
                                               l_seq_epis,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_waiting,
                                               pk_edis_triage.g_type_add,
                                               o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
    
        IF i_epis_type IN (pk_alert_constant.g_epis_type_rad, pk_alert_constant.g_epis_type_exam)
        THEN
        
            -- Relacionar um episodio de RAD/EXM com o episodio que lhe deu origem
            g_error := 'I_EPIS_TYPE RAD OR EXM 1';
            BEGIN
                SELECT er.id_episode_origin
                  INTO l_episode_origin
                  FROM exam_req er, schedule_exam se
                 WHERE er.id_exam_req = se.id_exam_req
                   AND se.id_schedule = i_id_sched;
            
                BEGIN
                    SELECT ees.id_external_sys, ees.value, ees.cod_epis_type_ext
                      INTO l_id_external_system, l_value, l_cod_epis_type_ext
                      FROM epis_ext_sys ees
                     WHERE ees.id_episode = l_episode_origin;
                
                    IF l_id_external_system IS NOT NULL
                    THEN
                        INSERT INTO epis_ext_sys
                            (id_epis_ext_sys,
                             id_external_sys,
                             id_episode,
                             VALUE,
                             id_institution,
                             id_epis_type,
                             cod_epis_type_ext)
                        VALUES
                            (seq_epis_ext_sys.nextval,
                             l_id_external_system,
                             l_seq_epis,
                             l_value,
                             i_id_professional.institution,
                             i_epis_type,
                             l_cod_epis_type_ext);
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_external_system := NULL;
                        l_value              := NULL;
                        l_cod_epis_type_ext  := NULL;
                END;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_episode_origin := NULL;
            END;
        END IF;
    
        IF i_epis_type = g_epis_type_session
        THEN
            g_error := 'UPDATE SCHEDULE_INTERVENTION';
            UPDATE schedule_intervention
               SET flg_state = g_sched_efectiv
             WHERE id_schedule = i_id_sched;
        
            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                       i_prof           => i_id_professional,
                                                                       i_id_schedule    => i_id_sched,
                                                                       i_flg_state      => g_sched_efectiv,
                                                                       i_id_patient     => l_pat,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error)
            THEN
                RAISE l_other_exception;
            END IF;
        
        ELSE
            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                       i_prof           => i_id_professional,
                                                                       i_id_schedule    => i_id_sched,
                                                                       i_flg_state      => g_sched_efectiv,
                                                                       i_id_patient     => l_pat,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error)
            THEN
                RAISE l_other_exception;
            END IF;
        
            -- JS, 2008-08-06: Actualizar estado de P1 associado para efectivado.
            BEGIN
                g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_sched;
                IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                           i_prof                => i_id_professional,
                                                           i_id_schedule         => i_id_sched,
                                                           o_id_external_request => l_id_external_request,
                                                           o_error               => o_error)
                THEN
                    NULL;
                END IF;
            
                IF l_id_external_request IS NOT NULL
                   AND l_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled
                THEN
                
                    -- ACM, 2010-01-11: ALERT-63305
                    g_error := 'CALL pk_ref_ext_sys.set_ref_efectiv / ID_REF=' || l_id_external_request;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_ref_ext_sys.set_ref_efectiv(i_lang   => i_lang,
                                                          i_prof   => i_id_professional,
                                                          i_id_ref => l_id_external_request,
                                                          i_notes  => NULL,
                                                          --i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                          o_error => o_error)
                    THEN
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- Se nao existe P1, nao tem que actualizar o estado
            END;
        END IF;
    
        SELECT id_exam, flg_type, exam_time, exam_dt, exam_priority, exam_t_number, exam_t_varchar
          BULK COLLECT
          INTO l_exam, l_exam_type, l_exam_time, l_exam_dt, l_exam_priority, l_exam_t_number, l_exam_t_varchar
          FROM (SELECT esd.id_exam,
                       'E' flg_type,
                       pk_exam_constant.g_flg_time_e exam_time,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_id_professional) exam_dt,
                       pk_exam_constant.g_exam_normal exam_priority,
                       NULL exam_t_number,
                       NULL exam_t_varchar
                  FROM exam_schedule_dcs esd
                 WHERE esd.id_dep_clin_serv = l_id_dep_clin_serv
                   AND esd.id_exam IS NOT NULL
                UNION ALL
                SELECT esd.id_exam_group id_exam,
                       'G' flg_type,
                       pk_exam_constant.g_flg_time_e exam_time,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_id_professional) exam_dt,
                       pk_exam_constant.g_exam_normal exam_priority,
                       NULL exam_t_number,
                       NULL exam_t_varchar
                  FROM exam_schedule_dcs esd
                 WHERE esd.id_dep_clin_serv = l_id_dep_clin_serv
                   AND esd.id_exam_group IS NOT NULL);
    
        l_exam_tt_number.extend(l_exam.count);
        l_exam_tt_varchar.extend(l_exam.count);
    
        FOR i IN 1 .. l_exam.count
        LOOP
            l_exam_tt_number(i) := table_number(NULL);
            l_exam_tt_varchar(i) := table_varchar('');
        END LOOP;
    
        IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_id_professional,
                                                 i_patient                 => l_pat,
                                                 i_episode                 => o_episode,
                                                 i_exam_req                => NULL,
                                                 i_exam_req_det            => l_exam_t_number,
                                                 i_exam                    => l_exam,
                                                 i_flg_type                => l_exam_type,
                                                 i_dt_req                  => l_exam_t_varchar,
                                                 i_flg_time                => l_exam_time,
                                                 i_dt_begin                => l_exam_dt,
                                                 i_dt_begin_limit          => l_exam_t_varchar,
                                                 i_episode_destination     => l_exam_t_number,
                                                 i_order_recurrence        => l_exam_t_number,
                                                 i_priority                => l_exam_priority,
                                                 i_flg_prn                 => l_exam_t_varchar,
                                                 i_notes_prn               => l_exam_t_varchar,
                                                 i_flg_fasting             => l_exam_t_varchar,
                                                 i_notes                   => l_exam_t_varchar,
                                                 i_notes_scheduler         => l_exam_t_varchar,
                                                 i_notes_technician        => l_exam_t_varchar,
                                                 i_notes_patient           => l_exam_t_varchar,
                                                 i_diagnosis_notes         => l_exam_t_varchar,
                                                 i_diagnosis               => NULL,
                                                 i_exec_room               => l_exam_t_number,
                                                 i_exec_institution        => l_exam_t_number,
                                                 i_clinical_purpose        => l_exam_t_number,
                                                 i_codification            => l_exam_t_number,
                                                 i_health_plan             => l_exam_t_number,
                                                 i_prof_order              => l_exam_t_number,
                                                 i_dt_order                => l_exam_t_varchar,
                                                 i_order_type              => l_exam_t_number,
                                                 i_clinical_question       => l_exam_tt_number,
                                                 i_response                => l_exam_tt_varchar,
                                                 i_clinical_question_notes => l_exam_tt_varchar,
                                                 i_clinical_decision_rule  => l_exam_t_number,
                                                 i_task_dependency         => l_exam_t_number,
                                                 i_flg_task_depending      => l_exam_t_varchar,
                                                 i_episode_followup_app    => l_exam_t_number,
                                                 i_schedule_followup_app   => l_exam_t_number,
                                                 i_event_followup_app      => l_exam_t_number,
                                                 i_test                    => pk_exam_constant.g_no,
                                                 o_flg_show                => l_flg_show,
                                                 o_msg_req                 => l_msg_req,
                                                 o_msg_title               => l_msg_title,
                                                 o_button                  => l_button,
                                                 o_exam_req_array          => l_exam_req_array,
                                                 o_exam_req_det_array      => l_exam_req_det_array,
                                                 o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Os episodios do tipo de sessoes de tratamento nao tem estas areas, logo nao deve ser feito esta parte do codigo
        IF i_epis_type NOT IN (g_epis_type_session,
                               pk_alert_constant.g_epis_type_rad,
                               pk_alert_constant.g_epis_type_exam,
                               pk_alert_constant.g_epis_type_lab)
        THEN
            -- Lus Gaspar, 2007-09-03
            -- set the default episode touch option templates
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => i_id_professional,
                                                                  i_episode            => l_seq_epis,
                                                                  i_flg_type           => g_flg_type_appointment_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
        END IF;
    
        --ALERT-70086, ASantos 27-01-2009
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => i_id_professional,
                                                     i_episode            => l_seq_epis,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => o_error)
        THEN
        
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - ID_EPISODE: ' || l_seq_epis || '; LOG_ID: ' || o_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => 'PK_VISIT', sub_object_name => 'CREATE_EPISODE');
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
        
            RETURN FALSE;
        END IF;
    
        -- chronic medication
    
        -- IF (chronic_medication_active = 'Y')
        -- THEN
        --     g_error := 'set_prev_chronic_med_active';
        --     IF NOT pk_prescription.set_prev_chronic_med_active(i_lang    => i_lang,
        --                                                        i_episode => l_seq_epis,
        --                                                        i_patient => l_pat,
        --                                                        i_prof    => i_id_professional,
        --                                                        i_commit  => 'Y',
        --                                                        o_error   => o_error)
        --     THEN
        --         pk_utils.undo_changes;
        --         pk_alertlog.log_error(g_error);
        --         RETURN FALSE;
        --     END IF;
        -- END IF;
    
        -- chronic medication
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_other_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
            -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            RETURN FALSE;
    END create_episode;

    /** Wrapper to avoid decompile. Do not use !! */
    FUNCTION create_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_visit        IN visit.id_visit%TYPE,
        i_id_professional IN profissional,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_health_plan     IN health_plan.id_health_plan%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_episode         OUT episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN
    
     IS
    
    BEGIN
    
        RETURN pk_visit.create_episode(i_lang            => i_lang,
                                       i_id_visit        => i_id_visit,
                                       i_id_professional => i_id_professional,
                                       i_id_sched        => i_id_sched,
                                       i_id_episode      => i_id_episode,
                                       i_health_plan     => i_health_plan,
                                       i_epis_type       => i_epis_type,
                                       i_dep_clin_serv   => i_dep_clin_serv,
                                       i_transaction_id  => NULL,
                                       o_episode         => o_episode,
                                       o_error           => o_error);
    
    END create_episode;

    /******************************************************************************
       OBJECTIVO:   Criar registo de episdio de consulta, associado a agendamento.
           Se existem episdios activos p/ esta visita, so fechados!!
       PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
           I_ID_VISIT - ID da visita. Pode  vir preenchido
           I_ID_PROFESSIONAL - profissional responsvel
           I_ID_SCHED - agendamento q origina a visita
                             I_ID_EPISODE - ID do episdio, quando esse ID j vem do Interface (Sonho)
                             I_HEALTH_PLAN - plano de sade activado para o episdio
         I_EPIS_TYPE - Tipo de episdio
         I_DEP_CLIN_SERV - Servio clinico do departamento
           Saida:   O_ERROR - erro
    
      CRIAO: CRS 2005/02/25
               Lus Gaspar, 2007-09-03: set the default episode touch option templates
      NOTAS:
    *********************************************************************************/
    FUNCTION create_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sysdate              IN DATE,
        i_sysdate_tstz         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        i_flg_unknown          IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        i_transaction_id       IN VARCHAR2,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_seq_epis          NUMBER;
        l_seq_epis_inst     NUMBER;
        l_pat               visit.id_patient%TYPE;
        l_desc              VARCHAR2(4000);
        l_id_prof           sch_prof_outp.id_professional%TYPE;
        l_id_prof_resp      professional.id_professional%TYPE;
        l_id_nurse_resp     professional.id_professional%TYPE;
        l_room              epis_type_room.id_room%TYPE;
        l_visit_status      visit.flg_status%TYPE;
        l_id_visit          visit.id_visit%TYPE;
        l_id_cs             clinical_service.id_clinical_service%TYPE;
        l_instit            visit.id_institution%TYPE;
        l_pat_hplan         pat_health_plan.id_pat_health_plan%TYPE;
        l_instit_type       institution.flg_type%TYPE;
        l_wl_id             wl_waiting_line.id_wl_waiting_line%TYPE;
        l_barcode           VARCHAR2(200);
        l_rank              NUMBER;
        l_epis_doc_template table_number;
        l_consult_subs      VARCHAR2(1);
        l_id_dep_clin_serv  schedule.id_dcs_requested%TYPE;
        l_id_prof_team      prof_team.id_prof_team%TYPE;
        l_id_usf            prof_team.id_institution%TYPE;
        l_dt_begin_tstz     TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_sch_dt_begin_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_epsiode_origin     episode.id_episode%TYPE;
        l_id_external_system epis_ext_sys.id_epis_ext_sys%TYPE;
        l_value              epis_ext_sys.value%TYPE;
        l_cod_epis_type_ext  epis_ext_sys.cod_epis_type_ext%TYPE;
    
        l_id_department department.id_department%TYPE;
        l_id_dept       dept.id_dept%TYPE;
        l_rowids        table_varchar;
        e_process_event EXCEPTION;
        l_id_software software.id_software%TYPE;
    
        l_id_dcs_requested  schedule.id_dcs_requested%TYPE;
        l_id_cs_requested   episode.id_cs_requested%TYPE;
        l_id_department_req department.id_department%TYPE;
        l_id_dept_req       dept.id_dept%TYPE;
    
        l_dt_first_obs       epis_info.dt_first_obs_tstz%TYPE;
        l_dt_first_nurse_obs epis_info.dt_first_nurse_obs_tstz%TYPE;
    
        l_instit_requested  schedule.id_instit_requested%TYPE;
        l_id_prof_schedules schedule.id_prof_schedules%TYPE;
        l_flg_status_sched  schedule.flg_status%TYPE;
        l_id_schedule_outp  schedule_outp.id_schedule_outp%TYPE;
        CURSOR c_sched IS
            SELECT p.id_professional,
                   dcs.id_clinical_service,
                   dpt.id_department,
                   dpt.id_dept,
                   decode(sp.flg_type, g_flg_type_s, g_consultsubs_y, g_consultsubs_n) consult_subs,
                   s.id_dcs_requested l_id_dep_clin_serv,
                   s.dt_begin_tstz,
                   sp.flg_type,
                   s.id_instit_requested,
                   s.id_prof_schedules,
                   s.flg_status,
                   sp.id_schedule_outp -- new tco 14/05/2009
              FROM schedule s, schedule_outp sp, sch_prof_outp p, dep_clin_serv dcs, department dpt
             WHERE s.id_schedule = i_id_sched
               AND s.flg_status != g_sched_cancel
                  --  AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporarios (SCH 3.0)
               AND sp.id_schedule(+) = s.id_schedule
               AND p.id_schedule_outp(+) = sp.id_schedule_outp
               AND dcs.id_dep_clin_serv = s.id_dcs_requested
               AND dcs.id_department = dpt.id_department;
    
        CURSOR c_visit IS
            SELECT v.id_patient, v.flg_status, v.id_institution, i.flg_type
              FROM visit v, institution i
             WHERE id_visit = l_id_visit
               AND i.id_institution = v.id_institution;
    
        -- CRS 2007/02/24
        CURSOR c_epis_type
        (
            l_epis_type     epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION ALL
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv -- ET 2007/02/28
             ORDER BY rank DESC;
    
        CURSOR c_pat_hplan IS
            SELECT id_pat_health_plan
              FROM pat_health_plan
             WHERE id_patient = l_pat
               AND id_health_plan = i_health_plan
               AND id_institution = i_id_professional.institution
               and flg_status = pk_alert_constant.g_active;
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_episode = l_seq_epis
               AND e.flg_ehr = g_flg_ehr_s;
    
        CURSOR c_first_episode IS
            SELECT MIN(e.dt_begin_tstz)
              FROM episode e
             WHERE e.id_visit = i_id_visit
               AND e.flg_status != 'C';
    
        CURSOR c_ehr IS
            SELECT flg_ehr
              FROM episode
             WHERE id_episode = i_id_episode;
    
        l_flg_ehr episode.flg_ehr%TYPE;
    
        l_exam          table_number := table_number();
        l_exam_type     table_varchar := table_varchar();
        l_exam_time     table_varchar := table_varchar();
        l_exam_dt       table_varchar := table_varchar();
        l_exam_priority table_varchar := table_varchar();
    
        l_exam_t_number   table_number := table_number();
        l_exam_t_varchar  table_varchar := table_varchar();
        l_exam_tt_number  table_table_number := table_table_number();
        l_exam_tt_varchar table_table_varchar := table_table_varchar();
    
        l_sched_flg_type schedule_outp.flg_type%TYPE;
    
        l_flg_show VARCHAR2(100);
    
        l_msg_req            VARCHAR2(4000);
        l_msg_title          VARCHAR2(4000);
        l_button             VARCHAR2(100);
        l_exam_req_array     table_number;
        l_exam_req_det_array table_number;
    
        l_id_external_request p1_external_request.id_external_request%TYPE;
        g_category            category.flg_type%TYPE;
    
        l_no_triage_color triage_color.id_triage_color%TYPE;
        l_error_in        t_error_in := t_error_in();
    
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_num          NUMBER;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
        l_other_exception EXCEPTION;
        -- chronic medication
        l_bool            BOOLEAN;
        l_id_epis_hhc_req NUMBER;
    
        chronic_medication_active VARCHAR2(1 CHAR) := pk_sysconfig.get_config('SHOW_PRESCRIPTION_CHRONIC',
                                                                              i_id_professional);
    
        l_ext_value          epis_ext_sys.value%TYPE;
        l_external_sys_exist sys_config.value%TYPE := pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                                              i_id_professional);
        l_id_ext_sys         sys_config.value%TYPE := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_id_professional);
        l_exists_ext         VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_id_prev_episode    NUMBER;
    
        FUNCTION get_hhc_dcs
        (
            i_id_schedule  IN NUMBER,
            i_id_epis_type IN NUMBER,
            i_id_dcs       IN NUMBER
        ) RETURN NUMBER IS
            tbl_id   table_number;
            l_id_dcs NUMBER;
            l_count  NUMBER;
        BEGIN
        
            l_id_dcs := i_id_dcs;
            --pk_alertlog.log_debug('ID00 - get_hhc_dcs i_epis_type:' || i_id_epis_type, 'PK_VISIT', NULL);
            IF i_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
            
                SELECT id_dcs_requested
                  BULK COLLECT
                  INTO tbl_id
                  FROM schedule x
                 WHERE x.id_schedule = i_id_schedule;
            
                l_count := tbl_id.count;
                --pk_alertlog.log_error('ID01 - get_hhc_dcs l_count:' || l_count, 'PK_VISIT', NULL);
                IF l_count > 0
                THEN
                    l_id_dcs := tbl_id(1);
                    --pk_alertlog.log_error('ID02 - get_hhc_dcs l_id_dcs:' || l_id_dcs, 'PK_VISIT', NULL);
                END IF;
            
            END IF;
        
            RETURN l_id_dcs;
        
        END get_hhc_dcs;
    
    BEGIN
    
        l_sysdate_tstz := nvl(g_sysdate_tstz, current_timestamp);
    
        g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
    
        IF i_epis_type = pk_alert_constant.g_epis_type_interv
        THEN
            l_id_software := i_id_professional.software;
        ELSE
            l_id_software := pk_episode.get_soft_by_epis_type(i_epis_type, i_id_professional.institution);
        END IF;
    
        l_id_visit := nvl(i_id_visit, 0);
        g_error    := 'GET CURSOR C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_pat, l_visit_status, l_instit, l_instit_type;
        CLOSE c_visit;
        IF l_visit_status = g_visit_inactive
           AND i_epis_type != pk_alert_constant.g_epis_type_rehab_session
        THEN
            l_msg_req := pk_message.get_message(i_lang, 'VISIT_M003');
            l_error_in.set_action(l_msg_req, 'U');
            l_error_in.set_errors(i_sqlcode => 'VISIT_M003', i_sqlerrm => l_msg_req, i_user_err => '');
            g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            RETURN FALSE;
        END IF;
    
        -- Profissional para quem  agendada a consulta que origina a visita
        g_error := 'GET CURSOR C_SCHED';
        OPEN c_sched;
        FETCH c_sched
            INTO l_id_prof,
                 l_id_cs_requested,
                 l_id_department_req,
                 l_id_dept_req,
                 l_consult_subs,
                 l_id_dcs_requested,
                 l_sch_dt_begin_tstz,
                 l_sched_flg_type,
                 l_instit_requested,
                 l_id_prof_schedules,
                 l_flg_status_sched,
                 l_id_schedule_outp;
        CLOSE c_sched;
    
        -- Tipo de episodios (Normal/Sched)
        g_error := 'GET CURSOR c_ehr';
        OPEN c_ehr;
        FETCH c_ehr
            INTO l_flg_ehr;
        CLOSE c_ehr;
    
        --For the EHR event, if the schedule doenst exists then the professional is the the professional that created the EHR event
        IF l_id_prof IS NULL
           AND i_flg_ehr = g_flg_ehr_e
        THEN
            l_id_prof := i_id_professional.id;
        END IF;
        --Same for cs
        --dbms_output.put_line('i_dep_clin_serv -> ' || i_dep_clin_serv);
        IF i_dep_clin_serv IS NOT NULL
        THEN
            l_id_dep_clin_serv := i_dep_clin_serv;
        
        ELSE
            l_id_dep_clin_serv := l_id_dcs_requested;
        END IF;
        g_error := 'GET EHR CLINICAL_SERVICE';
        IF l_id_dep_clin_serv IS NOT NULL
        THEN
            SELECT dcs.id_clinical_service, d.id_department, d.id_dept
              INTO l_id_cs, l_id_department, l_id_dept
              FROM dep_clin_serv dcs, department d
             WHERE dcs.id_dep_clin_serv = l_id_dep_clin_serv
               AND dcs.id_department = d.id_department;
        END IF;
    
        IF i_id_episode IS NULL
        THEN
            g_error    := 'GET CURSOR C_EPIS_SEQ';
            l_seq_epis := ts_episode.next_key;
        ELSE
            g_error    := 'GET CURSOR C_EPIS_SEQ';
            l_seq_epis := i_id_episode;
        END IF;
    
        -- Ariel Machado, April 04, 2008: If a clinical service of a department is sent in the function it's used,
        -- if it's null the value defined in the schedule is used
        --
        -- Gerar Barcode ET(2007/01/18)
        ------- GERAO DE CDIGO DE BARRAS
        g_error := 'CALL TO PK_BARCODE.GENERATE_BARCODE';
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => i_id_professional.institution,
                                           i_software     => i_id_professional.software,
                                           o_barcode      => l_barcode,
                                           o_error        => o_error)
        THEN
            -- o_error := l_error;
            RETURN FALSE;
        END IF;
    
        --
        o_episode := l_seq_epis;
        --
    
        -- Verifies if the id_episode already existsin the EPISODE table.
    
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_seq_epis;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
    
        IF g_found
        THEN
            --actualizar o tempo de efectivao devido a passar de flg_ehr 'S' para 'N'
            g_error := 'UPDATE EPISODE';
            ts_episode.upd(flg_ehr_in => nvl(i_flg_ehr, g_flg_ehr_n), flg_type_in => pk_episode.g_flg_def, flg_type_nin => FALSE, dt_begin_tstz_in => g_sysdate_tstz, dt_begin_tstz_nin => FALSE, dt_cancel_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_cancel_tstz_nin => FALSE, id_prof_cancel_in => CAST(NULL AS NUMBER), id_prof_cancel_nin => FALSE, id_episode_in => l_seq_epis, rows_out => l_rowids);
        
            OPEN c_first_episode;
            FETCH c_first_episode
                INTO l_dt_begin_tstz;
            IF c_first_episode%FOUND
            THEN
            
                UPDATE visit e
                   SET e.dt_begin_tstz = l_dt_begin_tstz,
                       -- Jos Brito 11/11/2008 ALERT-9260
                       e.dt_end_tstz = NULL
                 WHERE e.id_visit = i_id_visit;
            
            END IF;
            CLOSE c_first_episode;
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_id_professional,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_EHR',
                                                                          'DT_BEGIN_TSTZ',
                                                                          'DT_CANCEL_TSTZ',
                                                                          'ID_PROF_CANCEL'));
        
            l_rowids := table_varchar();
        
            -- Jos Brito 12/11/2008 ALERT-8239 INVARIANTE 29
            -- Se houver episdio actualiza as datas da primeira observao na EPIS_INFO, para no haver incoerncia
            -- com a data de incio do episdio.
        
            -- Com esta query apenas se pretende verificar se as datas de observao esto preenchidas.
            -- Se estiverem, o valor usado no UPDATE  'g_sysdate_tstz'. Caso contrrio,  NULL.
            SELECT decode(l_flg_ehr,
                          pk_ehr_access.g_flg_ehr_scheduled,
                          NULL,
                          decode(ei.dt_first_obs_tstz, NULL, NULL, g_sysdate_tstz)),
                   decode(l_flg_ehr,
                          pk_ehr_access.g_flg_ehr_scheduled,
                          NULL,
                          decode(ei.dt_first_nurse_obs_tstz, NULL, NULL, g_sysdate_tstz))
              INTO l_dt_first_obs, l_dt_first_nurse_obs
              FROM epis_info ei
             WHERE ei.id_episode = l_seq_epis;
        
            l_id_dep_clin_serv := get_hhc_dcs(i_id_schedule  => i_id_sched,
                                              i_id_epis_type => i_epis_type,
                                              i_id_dcs       => l_id_dep_clin_serv);
        
            ts_epis_info.upd(id_episode_in               => l_seq_epis,
                             dt_first_obs_tstz_in        => l_dt_first_obs,
                             dt_first_obs_tstz_nin       => FALSE,
                             flg_unknown_in              => nvl(i_flg_unknown, pk_alert_constant.g_no),
                             flg_unknown_nin             => FALSE,
                             id_dep_clin_serv_in         => l_id_dep_clin_serv,
                             id_first_dep_clin_serv_in   => l_id_dep_clin_serv,
                             id_dep_clin_serv_nin        => FALSE,
                             id_first_dep_clin_serv_nin  => FALSE,
                             dt_first_nurse_obs_tstz_in  => l_dt_first_nurse_obs,
                             dt_first_nurse_obs_tstz_nin => FALSE,
                             rows_out                    => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_id_professional,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_rowids := table_varchar();
            --
        
            --if in the begining the episode was of type flg_ehr = 'S' (scheduled) then
            -- we will force the correct state to "waiting" in the scheduler in order to avoid
            --external errors.
            IF l_flg_ehr = pk_ehr_access.g_flg_ehr_scheduled
            THEN
                UPDATE schedule_outp so
                   SET so.flg_state = 'E'
                 WHERE so.id_schedule IN (SELECT ei.id_schedule
                                            FROM epis_info ei
                                           WHERE ei.id_episode = l_seq_epis);
            END IF;
        
        ELSE
        
            l_rowids := table_varchar();
        
            IF i_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
            
                l_id_prev_episode := pk_hhc_core.get_active_hhc_episode(i_patient => l_pat);
                l_id_epis_hhc_req := pk_hhc_core.get_active_hhc_request(i_patient => l_pat);
            
                -- Only in progress when approved
                IF l_flg_status_sched = pk_schedule.g_sched_status_scheduled
                THEN
                
                    l_bool := pk_hhc_core.set_status_in_progress(i_lang            => i_lang,
                                                                 i_prof            => i_id_professional,
                                                                 i_id_epis_hhc_req => l_id_epis_hhc_req,
                                                                 o_error           => o_error);
                    IF NOT l_bool
                    THEN
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                
                END IF;
            
            END IF;
        
            g_error := 'INSERT INTO EPISODE';
            ts_episode.ins(id_episode_in              => l_seq_epis,
                           id_visit_in                => i_id_visit,
                           id_patient_in              => l_pat,
                           id_clinical_service_in     => nvl(l_id_cs, -1),
                           id_department_in           => nvl(l_id_department, -1),
                           id_dept_in                 => nvl(l_id_dept, -1),
                           dt_begin_tstz_in           => g_sysdate_tstz,
                           id_epis_type_in            => i_epis_type,
                           flg_type_in                => CASE
                                                             WHEN i_flg_unknown = pk_alert_constant.g_yes THEN
                                                              pk_episode.g_flg_temp
                                                             ELSE
                                                              pk_episode.g_flg_def
                                                         END,
                           flg_status_in              => g_epis_active,
                           barcode_in                 => l_barcode,
                           flg_ehr_in                 => i_flg_ehr,
                           dt_creation_in             => l_sysdate_tstz, -- dt_creation should always be current_timestamp and it can be different from dt_begin
                           id_institution_in          => l_instit,
                           id_cs_requested_in         => nvl(l_id_cs_requested, -1),
                           id_department_requested_in => nvl(l_id_department_req, -1),
                           id_dept_requested_in       => nvl(l_id_dept_req, -1),
                           flg_appointment_type_in    => i_flg_appointment_type,
                           id_prev_episode_in         => l_id_prev_episode,
                           handle_error_in            => FALSE,
                           rows_out                   => l_rowids);
        
            g_error := 'PROCESS INSERT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_id_professional,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- ALERT-41412: AS (03-06-2011)
            g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
            pk_alertlog.log_debug(text => g_error);
            IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                          i_prof        => i_id_professional,
                                                          i_patient     => l_pat,
                                                          i_new_episode => l_seq_epis,
                                                          o_error       => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
            -- END ALERT-41412
        
            l_rowids := table_varchar();
        
            IF (l_external_sys_exist = pk_alert_constant.g_no)
            THEN
                IF i_epis_type != pk_alert_constant.g_epis_type_lab
                THEN
                    INSERT INTO epis_ext_sys
                        (id_epis_ext_sys,
                         id_external_sys,
                         id_episode,
                         VALUE,
                         id_institution,
                         id_epis_type,
                         cod_epis_type_ext)
                    VALUES
                        (seq_epis_ext_sys.nextval,
                         pk_alert_constant.g_external_sys_built_in,
                         l_seq_epis,
                         pk_area_key_nextval.get_next_account_number(i_id_professional.institution),
                         i_id_professional.institution,
                         nvl(i_epis_type, pk_sysconfig.get_config('EPIS_TYPE', i_id_professional)),
                         decode(l_id_software, 8, 'URG', 29, 'URG', 11, 'INT', 1, 'CON', 3, 'CON', 12, 'CON', 'XXX'));
                END IF;
            END IF;
        END IF;
    
        IF l_external_sys_exist = g_yes
        THEN
            BEGIN
                SELECT ees.value
                  INTO l_ext_value
                  FROM epis_ext_sys ees
                  JOIN episode e
                    ON e.id_episode = ees.id_episode
                 WHERE ees.id_institution = i_id_professional.institution
                   AND ees.id_episode = l_seq_epis
                   AND e.id_epis_type = i_epis_type
                   AND ees.id_external_sys = l_id_ext_sys;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ext_value  := NULL;
                    l_exists_ext := pk_alert_constant.g_no;
            END;
        
            IF l_id_ext_sys = pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_id_professional)
               AND l_ext_value IS NULL
               AND i_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled
               AND
               i_epis_type NOT IN (pk_alert_constant.g_epis_type_inpatient, pk_alert_constant.g_epis_type_emergency)
            
            THEN
                pk_alertlog.log_error('i_epis_type:' || i_epis_type || ' INSERIR E GERAR amb_adm_from_alert_adt_new');
                IF l_exists_ext = pk_alert_constant.g_no
                   AND i_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled
                THEN
                
                    INSERT INTO epis_ext_sys
                        (id_epis_ext_sys,
                         id_external_sys,
                         id_episode,
                         VALUE,
                         id_institution,
                         id_epis_type,
                         cod_epis_type_ext)
                    VALUES
                        (seq_epis_ext_sys.nextval,
                         l_id_ext_sys,
                         l_seq_epis,
                         NULL,
                         i_id_professional.institution,
                         nvl(i_epis_type, pk_sysconfig.get_config('EPIS_TYPE', i_id_professional)),
                         decode(l_id_software, 8, 'URG', 29, 'URG', 11, 'INT', 1, 'CON', 3, 'CON', 12, 'CON', 'XXX'));
                END IF;
                pk_ia_event_common.amb_adm_from_alert_adt_new(i_id_institution  => i_id_professional.institution,
                                                              i_id_professional => i_id_professional.id,
                                                              i_id_episode      => l_seq_epis);
            END IF;
        
        END IF;
    
        IF NOT g_found
        THEN
            g_error := 'GET SEQ_EPIS_INSTITUTION.NEXTVAL';
            SELECT seq_epis_institution.nextval
              INTO l_seq_epis_inst
              FROM dual;
        
            g_error := 'INSERT INTO EPIS_INSTITUTION';
            INSERT INTO epis_institution
                (id_epis_institution, id_institution, id_episode)
            VALUES
                (l_seq_epis_inst, i_id_professional.institution, l_seq_epis);
        END IF;
        IF i_id_sched IS NOT NULL
        THEN
            -- Obter texto c/ info + actualizada do doente
            g_error := 'CALL TO PK_EPISODE.GET_EPIS_HEADER_INFO';
            IF NOT pk_episode.get_epis_header_info(i_lang        => i_lang,
                                                   i_id_pat      => l_pat,
                                                   i_id_schedule => i_id_sched,
                                                   i_institution => l_instit,
                                                   i_prof        => i_id_professional,
                                                   o_desc_info   => l_desc,
                                                   o_error       => o_error)
            THEN
                --o_error := l_error;
                RETURN FALSE;
            END IF;
        END IF;
    
        -- get sala default
        g_error := 'GET CURSOR C_EPIS_TYPE';
        OPEN c_epis_type(i_epis_type, l_id_dep_clin_serv);
        FETCH c_epis_type
            INTO l_room, l_rank;
        CLOSE c_epis_type;
    
        IF NOT g_found
        THEN
        
            IF NOT pk_visit.get_usf_prof_team(i_lang      => i_lang,
                                              i_prof      => i_id_professional,
                                              o_usf       => l_id_usf,
                                              o_prof_team => l_id_prof_team,
                                              o_error     => o_error)
            THEN
                --o_error := l_error;
                RETURN FALSE;
            END IF;
        
            g_error := 'GET CURSOR C_EPIS_INFO_SEQ';
        
            g_category := pk_prof_utils.get_category(i_lang,
                                                     profissional(l_id_prof,
                                                                  i_id_professional.institution,
                                                                  i_id_professional.software));
        
            --l_id_software := pk_episode.get_soft_by_epis_type(i_epis_type, i_id_professional.institution);
        
            -- Jos Brito 04/11/2008 Preencher EPIS_INFO.ID_TRIAGE_COLOR com a cr genrica do
            -- tipo de triagem usado na instituio actual
            g_error := 'GET NO TRIAGE COLOR';
            BEGIN
                SELECT tco.id_triage_color
                  INTO l_no_triage_color
                  FROM triage_color tco, triage_type tt
                 WHERE tco.id_triage_type = tt.id_triage_type
                   AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_id_professional, o_episode)
                   AND tco.flg_type = 'S'
                   AND rownum < 2;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      'ALERT',
                                                      'PK_VISIT',
                                                      'CREATE_EPISODE',
                                                      o_error);
                    RETURN FALSE;
            END;
        
            -- INP and EDIS episodes can't have responsible professionals without hand off requests
            IF l_id_software IN (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_inpatient)
               AND i_flg_ehr != g_flg_ehr_e
            THEN
                l_id_prof_resp := NULL;
            ELSIF g_category NOT IN (g_flg_type_n, g_cat_type_reg)
            THEN
                l_id_prof_resp := l_id_prof;
            END IF;
        
            -- INP and EDIS episodes can't have responsible professionals without hand off requests
            IF l_id_software IN (pk_alert_constant.g_soft_edis, pk_alert_constant.g_soft_inpatient)
               AND i_flg_ehr != g_flg_ehr_e
            THEN
                l_id_nurse_resp := NULL;
            ELSIF g_category = g_flg_type_n
            THEN
                l_id_nurse_resp := l_id_prof;
            END IF;
        
            l_id_dep_clin_serv := get_hhc_dcs(i_id_schedule  => i_id_sched,
                                              i_id_epis_type => i_epis_type,
                                              i_id_dcs       => l_id_dep_clin_serv);
        
            g_error := 'INSERT INTO EPIS_INFO';
            /* <DENORM Fbio> */
            ts_epis_info.ins(id_episode_in  => l_seq_epis,
                             id_schedule_in => CASE
                                                   WHEN i_id_sched IS NULL THEN
                                                    -1
                                                   ELSE
                                                    i_id_sched
                                               END,
                             id_room_in     => l_room,
                             -- Jos Brito 21/11/2008 ALERT-10341 Se fr um administrativo a criar o evento, no deve assumir a responsabilidade do paciente
                             id_professional_in          => l_id_prof_resp,
                             flg_unknown_in              => nvl(i_flg_unknown, pk_alert_constant.g_no),
                             desc_info_in                => l_desc,
                             flg_status_in               => g_epis_info_efectiv,
                             id_dep_clin_serv_in         => l_id_dep_clin_serv,
                             id_first_dep_clin_serv_in   => l_id_dep_clin_serv,
                             id_institution_usf_in       => l_id_usf,
                             id_prof_team_in             => l_id_prof_team,
                             id_first_nurse_resp_in      => l_id_nurse_resp,
                             id_patient_in               => l_pat,
                             id_software_in              => l_id_software,
                             id_dcs_requested_in         => l_id_dcs_requested,
                             dt_last_interaction_tstz_in => g_sysdate_tstz,
                             triage_acuity_in            => pk_alert_constant.g_color_gray,
                             triage_color_text_in        => pk_alert_constant.g_color_white,
                             triage_rank_acuity_in       => pk_alert_constant.g_rank_acuity,
                             id_triage_color_in          => l_no_triage_color,
                             id_instit_requested_in      => l_instit_requested,
                             id_prof_schedules_in        => l_id_prof_schedules,
                             flg_sch_status_in           => l_flg_status_sched,
                             id_schedule_outp_in         => l_id_schedule_outp,
                             sch_prof_outp_id_prof_in    => CASE
                                                                WHEN i_id_sched IS NULL THEN
                                                                 NULL
                                                                ELSE
                                                                 l_id_prof
                                                            END,
                             rows_out                    => l_rowids);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_id_professional,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'INSERT DOC TRIAGE ALERT';
            IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                                   i_id_professional,
                                                   l_seq_epis,
                                                   g_sysdate_tstz,
                                                   pk_edis_triage.g_alert_nurse,
                                                   pk_edis_triage.g_type_add,
                                                   o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'INSERT EPIS WAITING ALERT';
            IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                                   i_id_professional,
                                                   l_seq_epis,
                                                   g_sysdate_tstz,
                                                   pk_edis_triage.g_alert_waiting,
                                                   pk_edis_triage.g_type_add,
                                                   o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_epis_type = g_epis_type_session
        THEN
            g_error := 'UPDATE SCHEDULE_INTERVENTION';
            UPDATE schedule_intervention
               SET flg_state = g_sched_efectiv
             WHERE id_schedule = i_id_sched;
        
            -- Relacionar um episodio de MFR com o episodio que lhe deu origem
            /*SELECT ip.id_episode
              INTO l_epsiode_origin
              FROM schedule_intervention si, interv_presc_det ipd, interv_prescription ip
             WHERE si.id_schedule = i_id_sched
               AND si.id_interv_presc_det = ipd.id_interv_presc_det
            AND ipd.id_interv_prescription = ip.id_interv_prescription;*/
        
            BEGIN
                SELECT ees.id_external_sys, ees.value, ees.cod_epis_type_ext
                  INTO l_id_external_system, l_value, l_cod_epis_type_ext
                  FROM epis_ext_sys ees
                 WHERE ees.id_episode = l_epsiode_origin
                   AND ees.id_institution = i_id_professional.institution
                   AND ees.id_epis_type = i_epis_type;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_external_system := NULL;
                    l_value              := NULL;
                    l_cod_epis_type_ext  := NULL;
            END;
        
            l_id_external_system := NULL;
        
            IF l_id_external_system IS NOT NULL
            THEN
                INSERT INTO epis_ext_sys
                    (id_epis_ext_sys,
                     id_external_sys,
                     id_episode,
                     VALUE,
                     id_institution,
                     id_epis_type,
                     cod_epis_type_ext)
                VALUES
                    (seq_epis_ext_sys.nextval,
                     l_id_external_system,
                     l_seq_epis,
                     l_value,
                     i_id_professional.institution,
                     g_epis_type_session,
                     l_cod_epis_type_ext);
            END IF;
        
            -- efectivar no scheduler 3
            IF i_id_sched IS NOT NULL
               AND i_flg_ehr <> 'S'
            THEN
                -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
                g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_id_professional);
            
                g_error := 'UPDATE SCHEDULE_OUTP';
                --                if 
                IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                           i_prof           => i_id_professional,
                                                                           i_id_schedule    => i_id_sched,
                                                                           i_flg_state      => g_sched_efectiv,
                                                                           i_id_patient     => l_pat,
                                                                           i_transaction_id => l_transaction_id,
                                                                           o_error          => o_error)
                THEN
                    RAISE l_other_exception;
                END IF;
            END IF;
        
        ELSE
            -- JS, 2008-08-06: Actualizar estado de P1 associado para efectivado.
            BEGIN
            
                -- ACM, 2010-01-07: ALERT-63305
                /*
                g_error := 'CHECK IF SCHEDULE IS MATCHED WITH P1';
                SELECT per.id_external_request
                  INTO l_id_external_request
                  FROM p1_external_request per, schedule s
                 WHERE per.id_schedule = i_id_sched
                   AND s.id_schedule = per.id_schedule
                   AND s.flg_status != g_sched_cancel
                   AND per.flg_status IN (g_referral_status_scheduled, g_referral_status_mailed);
                
                   */
                g_error := 'CALL TO pk_ref_module.get_ref_sch_to_cancel with id_schedule=' || i_id_sched;
                IF NOT pk_ref_module.get_ref_sch_to_cancel(i_lang                => i_lang,
                                                           i_prof                => i_id_professional,
                                                           i_id_schedule         => i_id_sched,
                                                           o_id_external_request => l_id_external_request,
                                                           o_error               => o_error)
                THEN
                    NULL;
                END IF;
            
                IF l_id_external_request IS NOT NULL
                   AND l_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled
                THEN
                
                    -- ACM, 2010-01-11: ALERT-63305
                    g_error := 'CALL pk_ref_ext_sys.set_ref_efectiv / ID_REF=' || l_id_external_request;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_ref_ext_sys.set_ref_efectiv(i_lang   => i_lang,
                                                          i_prof   => i_id_professional,
                                                          i_id_ref => l_id_external_request,
                                                          i_notes  => NULL,
                                                          --i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                          o_error => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- Se nao existe P1, nao tem que actualizar o estado
            END;
        
        END IF;
    
        SELECT id_exam, flg_type, exam_time, exam_dt, exam_priority, exam_t_number, exam_t_varchar
          BULK COLLECT
          INTO l_exam, l_exam_type, l_exam_time, l_exam_dt, l_exam_priority, l_exam_t_number, l_exam_t_varchar
          FROM (SELECT esd.id_exam,
                       'E' flg_type,
                       pk_exam_constant.g_flg_time_e exam_time,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_id_professional) exam_dt,
                       pk_exam_constant.g_exam_normal exam_priority,
                       NULL exam_t_number,
                       NULL exam_t_varchar
                  FROM exam_schedule_dcs esd
                 WHERE esd.id_dep_clin_serv = l_id_dep_clin_serv
                   AND esd.id_exam IS NOT NULL
                UNION ALL
                SELECT esd.id_exam_group id_exam,
                       'G' flg_type,
                       pk_exam_constant.g_flg_time_e exam_time,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_id_professional) exam_dt,
                       pk_exam_constant.g_exam_normal exam_priority,
                       NULL exam_t_number,
                       NULL exam_t_varchar
                  FROM exam_schedule_dcs esd
                 WHERE esd.id_dep_clin_serv = l_id_dep_clin_serv
                   AND esd.id_exam_group IS NOT NULL);
    
        l_exam_tt_number.extend(l_exam.count);
        l_exam_tt_varchar.extend(l_exam.count);
    
        FOR i IN 1 .. l_exam.count
        LOOP
            l_exam_tt_number(i) := table_number(NULL);
            l_exam_tt_varchar(i) := table_varchar('');
        END LOOP;
    
        IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_id_professional,
                                                 i_patient                 => l_pat,
                                                 i_episode                 => o_episode,
                                                 i_exam_req                => NULL,
                                                 i_exam_req_det            => l_exam_t_number,
                                                 i_exam                    => l_exam,
                                                 i_flg_type                => l_exam_type,
                                                 i_dt_req                  => l_exam_t_varchar,
                                                 i_flg_time                => l_exam_time,
                                                 i_dt_begin                => l_exam_dt,
                                                 i_dt_begin_limit          => l_exam_t_varchar,
                                                 i_episode_destination     => l_exam_t_number,
                                                 i_order_recurrence        => l_exam_t_number,
                                                 i_priority                => l_exam_priority,
                                                 i_flg_prn                 => l_exam_t_varchar,
                                                 i_notes_prn               => l_exam_t_varchar,
                                                 i_flg_fasting             => l_exam_t_varchar,
                                                 i_notes                   => l_exam_t_varchar,
                                                 i_notes_scheduler         => l_exam_t_varchar,
                                                 i_notes_technician        => l_exam_t_varchar,
                                                 i_notes_patient           => l_exam_t_varchar,
                                                 i_diagnosis_notes         => l_exam_t_varchar,
                                                 i_diagnosis               => NULL,
                                                 i_exec_room               => l_exam_t_number,
                                                 i_exec_institution        => l_exam_t_number,
                                                 i_clinical_purpose        => l_exam_t_number,
                                                 i_codification            => l_exam_t_number,
                                                 i_health_plan             => l_exam_t_number,
                                                 i_prof_order              => l_exam_t_number,
                                                 i_dt_order                => l_exam_t_varchar,
                                                 i_order_type              => l_exam_t_number,
                                                 i_clinical_question       => l_exam_tt_number,
                                                 i_response                => l_exam_tt_varchar,
                                                 i_clinical_question_notes => l_exam_tt_varchar,
                                                 i_clinical_decision_rule  => l_exam_t_number,
                                                 i_task_dependency         => l_exam_t_number,
                                                 i_flg_task_depending      => l_exam_t_varchar,
                                                 i_episode_followup_app    => l_exam_t_number,
                                                 i_schedule_followup_app   => l_exam_t_number,
                                                 i_event_followup_app      => l_exam_t_number,
                                                 i_test                    => pk_exam_constant.g_no,
                                                 o_flg_show                => l_flg_show,
                                                 o_msg_req                 => l_msg_req,
                                                 o_msg_title               => l_msg_title,
                                                 o_button                  => l_button,
                                                 o_exam_req_array          => l_exam_req_array,
                                                 o_exam_req_det_array      => l_exam_req_det_array,
                                                 o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_id_sched IS NOT NULL
        THEN
            IF l_exam.count = 0
            THEN
                -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
                g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id);
            
                g_error := 'UPDATE SCHEDULE_OUTP';
                IF i_flg_ehr <> 'S'
                THEN
                    IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                               i_prof           => i_id_professional,
                                                                               i_id_schedule    => i_id_sched,
                                                                               i_flg_state      => g_sched_efectiv,
                                                                               i_id_patient     => l_pat,
                                                                               i_transaction_id => l_transaction_id,
                                                                               o_error          => o_error)
                    THEN
                        RAISE l_other_exception;
                    END IF;
                END IF;
            ELSE
                g_error := 'UPDATE SCHEDULE_OUTP';
                UPDATE schedule_outp
                   SET flg_state = pk_exam_constant.g_waiting_technician
                 WHERE id_schedule = i_id_sched;
            END IF;
        END IF;
    
        -- Os episodios do tipo de sessoes de tratamento nao tem estas areas, logo nao deve ser feito esta parte do codigo
        IF i_epis_type != g_epis_type_session
        THEN
        
            -- Lus Gaspar, 2007-09-03
            -- set the default episode touch option templates
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => i_id_professional,
                                                                  i_episode            => l_seq_epis,
                                                                  i_flg_type           => g_flg_type_appointment_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- RicardoNunoAlmeida
        -- 04-02-2009
        -- Esta funcao tambem e utilizada num contexto da efectivacao de pacientes com agendamentos.
        -- Nesses casos, quando o WR esta disponivel para essa aplicacao e necessario tambem realizar a admissao
        -- do WR (associar a ultima senha invocada ao episodio.
        g_error := 'VERIFY WAITING ROOM';
        /*
        IF (i_epis_type IN (pk_alert_constant.g_epis_type_outpatient,
                            pk_alert_constant.g_epis_type_private_practice,
                            pk_alert_constant.g_epis_type_primary_care,
                            g_epis_type_nurse,
                            g_epis_type_nurse_outp,
                            g_epis_type_nurse_pp))
           AND (pk_sysconfig.get_config(i_code_cf   => g_wr_available,
                                        i_prof_inst => nvl(l_instit, i_id_professional.institution),
                                        i_prof_soft => nvl(l_id_software, i_id_professional.software)) = g_yes)
        THEN
            g_error := 'CALL SET_CALL_ADMISSION';
            IF NOT pk_wlcore.set_pat_admission(i_lang      => i_lang,
                                               i_prof      => i_id_professional,
                                               i_c_prof    => l_id_prof,
                                               i_pat       => l_pat,
                                               i_clin_serv => l_id_cs_requested,
                                               i_inst      => l_instit,
                                               i_epis      => o_episode,
                                               i_dt_cons   => l_sch_dt_begin_tstz,
                                               o_id_wl     => l_wl_id,
                                               o_error     => o_error)
            
            THEN
            
                -- Tudo bem. Efectivacao ainda e valida, mas nao tem uma admissao no WR.
                NULL;
            
            END IF;
        
        END IF;
        */
            g_error := 'BEFORE ID_HEALTH_PLAN USAGE: ID_HEALTH_PLAN = ' || i_health_plan;
        IF i_health_plan IS NOT NULL
        THEN
        
            g_error := 'OPEN C_PAT_HPLAN';
            OPEN c_pat_hplan;
            FETCH c_pat_hplan
                INTO l_pat_hplan;
            g_found := c_pat_hplan%FOUND;
            CLOSE c_pat_hplan;
        
            IF g_found
            THEN
                SELECT COUNT(1)
                  INTO l_num
                  FROM epis_health_plan ehp
                 WHERE ehp.id_pat_health_plan = l_pat_hplan
                   AND ehp.id_episode = o_episode;
            
                IF l_num = 0
                THEN
                    g_error := 'INSERT INTO EPIS_HEALTH_PLAN';
                    INSERT INTO epis_health_plan
                        (id_epis_health_plan, id_episode, id_pat_health_plan, flg_primary)
                    VALUES
                        (seq_epis_health_plan.nextval, o_episode, l_pat_hplan,pk_alert_constant.g_yes);
                END IF;
            END IF;
        END IF;

        --ALERT-70086, ASantos 27-01-2009
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => i_id_professional,
                                                     i_episode            => o_episode,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => o_error)
        THEN
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - ID_EPISODE: ' || o_episode || '; LOG_ID: ' || o_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => 'PK_VISIT', sub_object_name => 'CREATE_EPISODE');
            pk_utils.undo_changes;
            IF l_transaction_id IS NOT NULL
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            END IF;
        
            RETURN FALSE;
        END IF;
    
        -- chronic medication
    
        -- IF (chronic_medication_active = 'Y')
        -- THEN
        --     g_error := 'set_prev_chronic_med_active';
        --     IF NOT pk_prescription.set_prev_chronic_med_active(i_lang    => i_lang,
        --                                                        i_episode => l_seq_epis,
        --                                                        i_patient => l_pat,
        --                                                        i_prof    => i_id_professional,
        --                                                        i_commit  => 'Y',
        --                                                        o_error   => o_error)
        --     THEN
        --         pk_utils.undo_changes;
        --         pk_alertlog.log_error(g_error);
        --         RETURN FALSE;
        --     END IF;
        -- END IF;
        -- chronic medication
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_id_professional);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_other_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_id_professional);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_episode;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_episode
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_id_sched             IN epis_info.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_health_plan          IN health_plan.id_health_plan%TYPE,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_dep_clin_serv        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sysdate              IN DATE,
        i_sysdate_tstz         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_ehr              IN episode.flg_ehr%TYPE DEFAULT 'N',
        i_flg_appointment_type IN episode.flg_appointment_type%TYPE,
        o_episode              OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.create_episode(i_lang                 => i_lang,
                                       i_id_visit             => i_id_visit,
                                       i_id_professional      => i_id_professional,
                                       i_id_sched             => i_id_sched,
                                       i_id_episode           => i_id_episode,
                                       i_health_plan          => i_health_plan,
                                       i_epis_type            => i_epis_type,
                                       i_dep_clin_serv        => i_dep_clin_serv,
                                       i_sysdate              => i_sysdate,
                                       i_sysdate_tstz         => i_sysdate_tstz,
                                       i_flg_ehr              => i_flg_ehr,
                                       i_flg_appointment_type => i_flg_appointment_type,
                                       i_transaction_id       => NULL,
                                       o_episode              => o_episode,
                                       o_error                => o_error);
    
    END create_episode;

    FUNCTION set_visit_end
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /**********************************************************************************************
        * Registar fim de visita
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_prof_cat_type          professional category
        * @param i_id_visit               Visit
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *
        * @author                         CRS
        * @version                        2.4.2
        * @since                          2008/01/25
        * @changes                        RS -- Add prof and prof_cat
        **********************************************************************************************/
    BEGIN
        g_error := 'CALL PK_VISIT.SET_VISIT_END';
        RETURN pk_visit.set_visit_end(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_prof_cat_type => NULL,
                                      i_id_visit      => i_id_visit,
                                      i_sysdate       => SYSDATE,
                                      i_sysdate_tstz  => current_timestamp,
                                      o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_VISIT_END 1',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION set_visit_end
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_id_visit      IN visit.id_visit%TYPE,
        i_sysdate       IN DATE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /**********************************************************************************************
        * Registar fim de visita
        *
        * @param i_lang                   the id language
        * @param i_prof                   professional, software and institution ids
        * @param i_prof_cat_type          professional category
        * @param i_id_visit               Visit
        * @param o_error                  Error message
        *
        * @return                         TRUE if sucess, FALSE otherwise
        *
        * @author                         CRS
        * @version                        2.4.2
        * @since                          2008/01/25
        * @changes                        RS -- Add prof and prof_cat
        **********************************************************************************************/
    
        CURSOR c_epis IS
            SELECT e.id_episode, v.id_institution
              FROM episode e, visit v
             WHERE e.id_visit = i_id_visit
               AND e.flg_status = g_epis_active
               AND v.id_visit = e.id_visit;
    
        l_epis       episode.id_episode%TYPE;
        l_inst       institution.id_institution%TYPE;
        l_num_epis_a PLS_INTEGER;
    
        l_rows table_varchar;
    BEGIN
    
        g_sysdate_tstz := nvl(i_sysdate_tstz, current_timestamp);
    
        g_error := 'UPDATE EPISODE';
        /* <DENORM Fbio> */
        ts_episode.upd(dt_end_tstz_in  => g_sysdate_tstz,
                       dt_end_tstz_nin => FALSE,
                       flg_status_in   => g_epis_inactive,
                       where_in        => 'id_visit = ' || i_id_visit || ' AND flg_status IN (''' || g_epis_active ||
                                          ''', ''' || g_epis_pend || ''')',
                       rows_out        => l_rows);
    
        BEGIN
            --Inactivate episode in ADT
            UPDATE episode_adt eadt
               SET eadt.flag_status = g_epis_inactive
             WHERE eadt.id_episode IN (SELECT id_episode
                                         FROM episode
                                        WHERE id_visit = i_id_visit
                                          AND flg_status IN (g_epis_active, g_epis_pend));
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
                --If there is no episode in ADT no exception is raised because some episodes
            --do not have integration with ADT like temporary episodes
            --raise c_no_adt_exception;
        END;
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
    
        --verifica se no existe mais nenhum episdio activo antes de fechar a visita
        SELECT COUNT(*)
          INTO l_num_epis_a
          FROM episode
         WHERE id_visit = i_id_visit
           AND flg_status IN (g_epis_active, g_epis_pend);
    
        --Se j no h episdios activos, fecha a visita
        IF nvl(l_num_epis_a, 0) = 0
        THEN
        
            g_error := 'UPDATE VISIT';
            l_rows  := table_varchar();
            ts_visit.upd(flg_status_in   => g_visit_inactive,
                         flg_status_nin  => FALSE,
                         dt_end_tstz_in  => g_sysdate_tstz,
                         dt_end_tstz_nin => FALSE,
                         where_in        => 'id_visit = ' || i_id_visit || ' AND flg_status = ''' || g_visit_active ||
                                            ''' ',
                         rows_out        => l_rows);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        
            --g_error := 'UPDATE VISIT';
            --UPDATE visit
            --   SET dt_end_tstz = g_sysdate_tstz, flg_status = g_visit_inactive
            -- WHERE id_visit = i_id_visit
            --   AND flg_status = g_visit_active;
        END IF;
    
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis, l_inst;
        CLOSE c_epis;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => l_epis,
                             i_pat                 => NULL,
                             i_prof                => i_prof,
                             i_prof_cat_type       => NULL,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_VISIT',
                                                     'SET_VISIT_END 2',
                                                     o_error);
    END;

    FUNCTION set_episode_end
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar fim de episdio
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/02/25
          NOTAS:
        *********************************************************************************/
        CURSOR c_discharge IS
            SELECT 'X'
              FROM discharge
             WHERE id_episode = i_id_episode;
        l_char VARCHAR2(1);
    
        l_rows table_varchar;
    
        g_exception_int EXCEPTION;
        l_error_message VARCHAR2(4000);
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_discharge;
        FETCH c_discharge
            INTO l_char;
        g_found := c_discharge%NOTFOUND;
        CLOSE c_discharge;
        IF g_found
        THEN
            l_error_message := pk_message.get_message(i_lang, 'COMMON_M016');
            RAISE g_exception_int;
        END IF;
    
        g_error := 'UPDATE EPISODE';
        /* <DENORM Fbio> */
        ts_episode.upd(dt_end_tstz_in  => g_sysdate_tstz,
                       dt_end_tstz_nin => FALSE,
                       flg_status_in   => g_epis_inactive,
                       where_in        => 'id_episode = ' || i_id_episode || ' AND flg_status = ''' || g_epis_active || '''',
                       rows_out        => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
    
        COMMIT;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => NULL,
                             i_prof_cat_type       => NULL,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_int THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   'COMMON_M016',
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_VISIT',
                                   'SET_EPISODE_END',
                                   'COMMON_M016',
                                   'U');
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes quando aplicavel-> so faz ROLLBACK
                pk_utils.undo_changes;
                -- return failure of function_dummy
                RETURN l_ret;
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'SET_EPISODE_END 2');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION get_epis_info
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        o_flg_type            OUT episode.id_epis_type%TYPE,
        o_flg_status          OUT episode.flg_status%TYPE,
        o_id_room             OUT epis_info.id_room%TYPE,
        o_desc_room           OUT VARCHAR2,
        o_dt_entrance_room    OUT VARCHAR2,
        o_dt_last_interaction OUT VARCHAR2,
        o_dt_movement         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter info variada relativa ao epis. actual
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               Saida:   O_FLG_TYPE - ID do tipo de epis. (Urg, consulta, ...)
               O_FLG_STATUS - estado do epis. (activo / inactivo)
               O_ID_ROOM - ID da sala (localizao do doente)
               O_DESC_ROOM - localizao do doente
               O_DT_ENTRANCE_ROOM - data de fim do transporte p/ a
                      a sala O_ID_ROOM
               O_DT_LAST_INTERACTION - data de ltima interaco c/ o doente
               O_DT_MOVEMENT - data de incio do transporte p/ a
                      a sala O_ID_ROOM
               O_ERROR - erro
        
          CRIAO: CRS 2005/03/01
          NOTAS:
        *********************************************************************************/
        CURSOR c_epis IS
            SELECT e.id_epis_type,
                   e.flg_status,
                   ei.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   pk_date_utils.date_char_tsz(i_lang, ei.dt_entrance_room_tstz, i_prof.institution, i_prof.software) dt_entrance_room,
                   pk_date_utils.date_char_tsz(i_lang, ei.dt_last_interaction_tstz, i_prof.institution, i_prof.software) dt_last_interaction,
                   pk_date_utils.date_char_tsz(i_lang, ei.dt_movement_tstz, i_prof.institution, i_prof.software) dt_movement
              FROM episode e, epis_info ei, room r
             WHERE e.id_episode = i_id_episode
               AND ei.id_episode = e.id_episode
                  -- Lus Gaspar 2007-Out-29 adicionei o left join pq h episdios sem sala
               AND r.id_room(+) = ei.id_room;
        l_error_message VARCHAR2(4000);
    
    BEGIN
        g_error := 'OPEN C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO o_flg_type,
                 o_flg_status,
                 o_id_room,
                 o_desc_room,
                 o_dt_entrance_room,
                 o_dt_last_interaction,
                 o_dt_movement;
        g_found := c_epis%NOTFOUND;
        CLOSE c_epis;
        IF g_found
        THEN
            l_error_message := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_VISIT.GET_EPIS_INFO / ' ||
                              
                               g_error || ' / no data found';
        
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_VISIT',
                                                     'GET_EPIS_INFO',
                                                     o_error);
        
    END;

    FUNCTION update_epis_info
    (
        i_lang         IN language.id_language%TYPE,
        i_id_episode   IN epis_info.id_episode%TYPE,
        i_id_room      IN epis_info.id_room%TYPE,
        i_bed          IN epis_info.id_bed%TYPE,
        i_norton       IN epis_info.norton%TYPE,
        i_professional IN epis_info.id_professional%TYPE,
        i_flg_hydric   IN epis_info.flg_hydric%TYPE,
        i_flg_wound    IN epis_info.flg_wound%TYPE,
        i_companion    IN epis_info.companion%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        i_desc_info    IN epis_info.desc_info%TYPE,
        i_prof         IN profissional,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar info do doente
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               ....
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/03/08
          NOTAS: Se s se pretende alterar algumas colunas, os restantes par. entrada
             so NULL.
           O ID_PROFESSIONAL s  preenchido se a coluna estava a NULL
        *********************************************************************************/
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO UPDATE_EPIS_INFO_NO_OBS';
        IF NOT update_epis_info_no_obs(i_lang         => i_lang,
                                       i_id_episode   => i_id_episode,
                                       i_id_room      => i_id_room,
                                       i_bed          => i_bed,
                                       i_norton       => i_norton,
                                       i_professional => i_professional,
                                       i_flg_hydric   => i_flg_hydric,
                                       i_flg_wound    => i_flg_wound,
                                       i_companion    => i_companion,
                                       i_flg_unknown  => i_flg_unknown,
                                       i_desc_info    => i_desc_info,
                                       i_prof         => i_prof,
                                       o_error        => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_prof,
                             i_prof_cat_type       => NULL,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPDATE_EPIS_INFO');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END;

    FUNCTION update_epis_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_episode           IN epis_info.id_episode%TYPE,
        i_id_prof              IN profissional,
        i_dt_entrance_room     IN VARCHAR2,
        i_dt_last_interaction  IN VARCHAR2,
        i_dt_movement          IN VARCHAR2,
        i_dt_harvest           IN VARCHAR2,
        i_dt_next_drug         IN VARCHAR2,
        i_dt_first_obs         IN VARCHAR2,
        i_dt_next_intervention IN VARCHAR2,
        i_dt_next_vital_sign   IN VARCHAR2,
        i_dt_next_position     IN VARCHAR2,
        i_dt_harvest_mov       IN VARCHAR2,
        i_dt_first_nurse_obs   IN VARCHAR2,
        i_prof_cat_type        IN category.flg_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar info do doente
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               ...
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                      como  retornada em PK_LOGIN.GET_PROF_PREF
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/03/08
          NOTAS: Se s se pretende alterar algumas colunas, os restantes par. entrada so NULL
        *********************************************************************************/
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_id_prof,
                             i_prof_cat_type       => i_prof_cat_type,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO UPDATE_EPIS_INFO_NO_OBS';
        IF NOT update_epis_info_no_obs(i_lang                 => i_lang,
                                       i_id_episode           => i_id_episode,
                                       i_id_prof              => i_id_prof,
                                       i_dt_entrance_room     => i_dt_entrance_room,
                                       i_dt_last_interaction  => i_dt_last_interaction,
                                       i_dt_movement          => i_dt_movement,
                                       i_dt_harvest           => i_dt_harvest,
                                       i_dt_next_drug         => i_dt_next_drug,
                                       i_dt_first_obs         => i_dt_first_obs,
                                       i_dt_next_intervention => i_dt_next_intervention,
                                       i_dt_next_vital_sign   => i_dt_next_vital_sign,
                                       i_dt_next_position     => i_dt_next_position,
                                       i_dt_harvest_mov       => i_dt_harvest_mov,
                                       i_dt_first_nurse_obs   => i_dt_first_nurse_obs,
                                       i_prof_cat_type        => i_prof_cat_type,
                                       o_error                => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_id_prof,
                             i_prof_cat_type       => i_prof_cat_type,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPDATE_EPIS_INFO');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION update_epis_info_no_obs
    (
        i_lang         IN language.id_language%TYPE,
        i_id_episode   IN epis_info.id_episode%TYPE,
        i_id_room      IN epis_info.id_room%TYPE,
        i_bed          IN epis_info.id_bed%TYPE,
        i_norton       IN epis_info.norton%TYPE,
        i_professional IN epis_info.id_professional%TYPE,
        i_flg_hydric   IN epis_info.flg_hydric%TYPE,
        i_flg_wound    IN epis_info.flg_wound%TYPE,
        i_companion    IN epis_info.companion%TYPE,
        i_flg_unknown  IN epis_info.flg_unknown%TYPE,
        i_desc_info    IN epis_info.desc_info%TYPE,
        i_prof         IN profissional,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ei table_varchar;
    BEGIN
        g_error := 'UPDATE';
        ts_epis_info.upd(id_episode_in       => i_id_episode,
                         id_room_in          => i_id_room,
                         id_bed_in           => i_bed,
                         id_professional_in  => i_professional,
                         flg_hydric_in       => i_flg_hydric,
                         flg_wound_in        => i_flg_wound,
                         companion_in        => i_companion,
                         flg_unknown_in      => i_flg_unknown,
                         desc_info_in        => i_desc_info,
                         id_room_nin         => TRUE,
                         id_bed_nin          => TRUE,
                         id_professional_nin => TRUE,
                         flg_hydric_nin      => TRUE,
                         flg_wound_nin       => TRUE,
                         companion_nin       => TRUE,
                         flg_unknown_nin     => TRUE,
                         desc_info_nin       => TRUE,
                         rows_out            => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_ROOM',
                                                                      'ID_BED',
                                                                      'ID_PROFESSIONAL',
                                                                      'FLG_HYDRIC',
                                                                      'FLG_WOUND',
                                                                      'COMPANION',
                                                                      'FLG_UNKNOWN',
                                                                      'DESC_INFO',
                                                                      'ID_ROOM'));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPDATE_EPIS_INFO_NO_OBS');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
    END;

    FUNCTION update_epis_info_no_obs
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_episode           IN epis_info.id_episode%TYPE,
        i_id_prof              IN profissional,
        i_dt_entrance_room     IN VARCHAR2,
        i_dt_last_interaction  IN VARCHAR2,
        i_dt_movement          IN VARCHAR2,
        i_dt_harvest           IN VARCHAR2,
        i_dt_next_drug         IN VARCHAR2,
        i_dt_first_obs         IN VARCHAR2,
        i_dt_next_intervention IN VARCHAR2,
        i_dt_next_vital_sign   IN VARCHAR2,
        i_dt_next_position     IN VARCHAR2,
        i_dt_harvest_mov       IN VARCHAR2,
        i_dt_first_nurse_obs   IN VARCHAR2,
        i_prof_cat_type        IN category.flg_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ei table_varchar;
    BEGIN
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in                 => i_id_episode,
                         dt_entrance_room_tstz_in      => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_entrance_room,
                                                                                        NULL),
                         dt_movement_tstz_in           => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_movement,
                                                                                        NULL),
                         dt_harvest_tstz_in            => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_harvest,
                                                                                        NULL),
                         dt_next_drug_tstz_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_next_drug,
                                                                                        NULL),
                         dt_next_intervention_tstz_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_next_intervention,
                                                                                        NULL),
                         dt_next_vital_sign_tstz_in    => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_next_vital_sign,
                                                                                        NULL),
                         dt_next_position_tstz_in      => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_next_vital_sign,
                                                                                        NULL),
                         dt_harvest_mov_tstz_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                        i_id_prof,
                                                                                        i_dt_harvest_mov,
                                                                                        NULL),
                         dt_entrance_room_tstz_nin     => TRUE,
                         dt_movement_tstz_nin          => TRUE,
                         dt_harvest_tstz_nin           => TRUE,
                         dt_next_drug_tstz_nin         => TRUE,
                         dt_next_intervention_tstz_nin => TRUE,
                         dt_next_vital_sign_tstz_nin   => TRUE,
                         dt_next_position_tstz_nin     => TRUE,
                         dt_harvest_mov_tstz_nin       => TRUE,
                         rows_out                      => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_ENTRANCE_ROOM_TSTZ',
                                                                      'DT_MOVEMENT_TSTZ',
                                                                      'DT_HARVEST_TSTZ',
                                                                      'DT_NEXT_DRUG_TSTZ',
                                                                      'DT_NEXT_INTERVENTION_TSTZ',
                                                                      'DT_NEXT_VITAL_SIGN_TSTZ',
                                                                      'DT_NEXT_POSITION_TSTZ',
                                                                      'DT_HARVEST_MOV_TSTZ'));
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPDATE_EPIS_INFO_NO_OBS');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
    END;

    FUNCTION upd_epis_info_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_episode             IN epis_info.id_episode%TYPE,
        i_id_prof                IN profissional,
        i_dt_first_analysis_exec IN VARCHAR2,
        i_dt_first_analysis_req  IN VARCHAR2,
        i_prof_cat_type          IN category.flg_type%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar datas relativas a anlises
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               I_ID_PROF - prof do registo
               I_DT_FIRST_ANALYSIS_EXEC - data de execuo da 1 anlise
                        do episdio
               I_DT_FIRST_ANALYSIS_REQ - data de requisio da 1 anlise
                        do episdio
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                      como  retornada em PK_LOGIN.GET_PROF_PREF
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/04/26
          NOTAS:
        *********************************************************************************/
        l_rows_ei                    table_varchar;
        l_dt_first_analysis_exe_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_first_analysis_req_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT ei.dt_first_analysis_exe_tstz, dt_first_analysis_req_tstz
          INTO l_dt_first_analysis_exe_tstz, l_dt_first_analysis_req_tstz
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        g_error := 'UPDATE';
        ts_epis_info.upd(id_episode_in                  => i_id_episode,
                         dt_first_analysis_exe_tstz_in  => CASE
                                                               WHEN l_dt_first_analysis_exe_tstz IS NULL THEN
                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_id_prof,
                                                                                              i_dt_first_analysis_exec,
                                                                                              NULL)
                                                               ELSE
                                                                l_dt_first_analysis_exe_tstz
                                                           END,
                         dt_first_analysis_exe_tstz_nin => FALSE,
                         dt_first_analysis_req_tstz_in  => CASE
                                                               WHEN l_dt_first_analysis_req_tstz IS NULL THEN
                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_id_prof,
                                                                                              i_dt_first_analysis_req,
                                                                                              NULL)
                                                               ELSE
                                                                l_dt_first_analysis_req_tstz
                                                           END,
                         dt_first_analysis_req_tstz_nin => FALSE,
                         rows_out                       => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_ANALYSIS_EXE_TSTZ',
                                                                      'DT_FIRST_ANALYSIS_REQ_TSTZ'));
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_id_prof,
                             i_prof_cat_type       => i_prof_cat_type,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPD_EPIS_INFO_ANALYSIS');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION upd_epis_info_exam
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_id_prof             IN profissional,
        i_dt_first_image_exec IN VARCHAR2,
        i_dt_first_image_req  IN VARCHAR2,
        i_prof_cat_type       IN category.flg_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar datas relativas a exames
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               I_ID_PROF - prof do registo
               I_DT_FIRST_IMAGE_EXEC - data de execuo do 1 exame
                        do episdio
               I_DT_FIRST_IMAGE_REQ - data de requisio do 1 exame
                        do episdio
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                      como  retornada em PK_LOGIN.GET_PROF_PREF
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/04/26
          NOTAS:
        *********************************************************************************/
        l_rows_ei                 table_varchar;
        l_dt_first_image_exe_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_first_image_req_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT ei.dt_first_image_exec_tstz, ei.dt_first_image_req_tstz
          INTO l_dt_first_image_exe_tstz, l_dt_first_image_req_tstz
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        g_error := 'UPDATE';
        ts_epis_info.upd(id_episode_in                => i_id_episode,
                         dt_first_image_exec_tstz_in  => CASE
                                                             WHEN l_dt_first_image_exe_tstz IS NULL THEN
                                                              pk_date_utils.get_string_tstz(i_lang,
                                                                                            i_id_prof,
                                                                                            i_dt_first_image_exec,
                                                                                            NULL)
                                                             ELSE
                                                              l_dt_first_image_exe_tstz
                                                         END,
                         dt_first_image_exec_tstz_nin => FALSE,
                         dt_first_image_req_tstz_in   => CASE
                                                             WHEN l_dt_first_image_req_tstz IS NULL THEN
                                                              pk_date_utils.get_string_tstz(i_lang,
                                                                                            i_id_prof,
                                                                                            i_dt_first_image_req,
                                                                                            NULL)
                                                             ELSE
                                                              l_dt_first_image_req_tstz
                                                         END,
                         dt_first_image_req_tstz_nin  => FALSE,
                         rows_out                     => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_IMAGE_EXEC_TSTZ',
                                                                      'DT_FIRST_IMAGE_REQ_TSTZ'));
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_id_prof,
                             i_prof_cat_type       => i_prof_cat_type,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPD_EPIS_INFO_EXAM');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    /********************************************************************************************
    * UPD_EPIS_INFO_DRUG
    *
    * @param i_lang                language id
    * @param i_id_episode          episode identifier
    * @param i_prof                professional id
    * @param i_dt_first_drug_prsc  data de 1 prescricao do episodio
    * @param i_dt_first_drug_take  data de 1 toma de medicamento do episodio
    * @param i_prof_cat_type       professional type of category (PK_LOGIN.GET_PROF_PREF)
    * @param i_commit              This function should make commit
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      CRS
    * @version                     2.4.0
    * @since                       2005/04/26
    **********************************************************************************************/
    FUNCTION upd_epis_info_drug
    (
        i_lang               IN language.id_language%TYPE,
        i_id_episode         IN epis_info.id_episode%TYPE,
        i_id_prof            IN profissional,
        i_dt_first_drug_prsc IN VARCHAR2,
        i_dt_first_drug_take IN VARCHAR2,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_commit             IN VARCHAR2 DEFAULT 'N',
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_ei                 table_varchar;
        l_dt_first_drug_prsc_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_first_drug_take_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT ei.dt_first_drug_prsc_tstz, ei.dt_first_drug_take_tstz
          INTO l_dt_first_drug_prsc_tstz, l_dt_first_drug_take_tstz
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        g_error := 'UPDATE';
        ts_epis_info.upd(id_episode_in               => i_id_episode,
                         dt_first_drug_prsc_tstz_in  => CASE
                                                            WHEN l_dt_first_drug_prsc_tstz IS NULL THEN
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           i_id_prof,
                                                                                           i_dt_first_drug_prsc,
                                                                                           NULL)
                                                            ELSE
                                                             l_dt_first_drug_prsc_tstz
                                                        END,
                         dt_first_drug_prsc_tstz_nin => FALSE,
                         dt_first_drug_take_tstz_in  => CASE
                                                            WHEN l_dt_first_drug_take_tstz IS NULL THEN
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           i_id_prof,
                                                                                           i_dt_first_drug_take,
                                                                                           NULL)
                                                            ELSE
                                                             l_dt_first_drug_take_tstz
                                                        END,
                         dt_first_drug_take_tstz_nin => FALSE,
                         rows_out                    => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_DRUG_PRSC_TSTZ',
                                                                      'DT_FIRST_DRUG_TAKE_TSTZ'));
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_id_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            IF i_commit IS NULL
               OR i_commit = pk_alert_constant.g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
            RETURN FALSE;
        END IF;
    
        IF i_commit IS NULL
           OR i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPD_EPIS_INFO_DRUG');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                IF i_commit IS NULL
                   OR i_commit = pk_alert_constant.g_yes
                THEN
                    pk_utils.undo_changes;
                END IF;
                RETURN FALSE;
            END;
    END upd_epis_info_drug;

    FUNCTION upd_epis_info_interv
    (
        i_lang                       IN language.id_language%TYPE,
        i_id_episode                 IN epis_info.id_episode%TYPE,
        i_id_prof                    IN profissional,
        i_dt_first_intervention_prsc IN VARCHAR2,
        i_dt_first_intervention_take IN VARCHAR2,
        i_prof_cat_type              IN category.flg_type%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar datas relativas a intervenes
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id da episdio
               I_ID_PROF - prof do registo
               I_DT_FIRST_INTERVENTION_PRSC - data de prescrio da 1
                           interveno do episdio
               I_DT_FIRST_INTERVENTION_TAKE - data de 1 execuo do plano
                           de intervenes do episdio
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                      como  retornada em PK_LOGIN.GET_PROF_PREF
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/04/26
          NOTAS:
        *********************************************************************************/
        l_rows_ei                    table_varchar;
        l_dt_first_intervention_prsc TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_first_intervention_take TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT ei.dt_first_interv_prsc_tstz, ei.dt_first_interv_take_tstz
          INTO l_dt_first_intervention_prsc, l_dt_first_intervention_take
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        g_error := 'UPDATE';
        ts_epis_info.upd(id_episode_in                 => i_id_episode,
                         dt_first_interv_prsc_tstz_in  => CASE
                                                              WHEN l_dt_first_intervention_prsc IS NULL THEN
                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                             i_id_prof,
                                                                                             i_dt_first_intervention_prsc,
                                                                                             NULL)
                                                              ELSE
                                                               l_dt_first_intervention_prsc
                                                          END,
                         dt_first_interv_prsc_tstz_nin => FALSE,
                         dt_first_interv_take_tstz_in  => CASE
                                                              WHEN l_dt_first_intervention_take IS NULL THEN
                                                               pk_date_utils.get_string_tstz(i_lang,
                                                                                             i_id_prof,
                                                                                             i_dt_first_intervention_take,
                                                                                             NULL)
                                                              ELSE
                                                               l_dt_first_intervention_take
                                                          END,
                         dt_first_interv_take_tstz_nin => FALSE,
                         rows_out                      => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_FIRST_INTERV_PRSC_TSTZ',
                                                                      'DT_FIRST_INTERV_TAKE_TSTZ'));
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_id_prof,
                             i_prof_cat_type       => i_prof_cat_type,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'UPD_EPIS_INFO_INTERV');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_FIRST_OBS';
    BEGIN
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => i_dt_last_interaction,
                                      i_dt_first_obs        => i_dt_first_obs,
                                      i_flg_triage_call     => pk_alert_constant.g_no,
                                      o_error               => o_error);
    END set_first_obs;

    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        i_flg_triage_call     IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar datas de 1 observao mdica / enfermagem
               e ltima interaco e mdico responsvel pelo epis., caso  exista
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id do episdio
               I_PAT - ID do doente
               I_PROF - profissional q regista
               I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                      como  retornada em PK_LOGIN.GET_PROF_PREF
               I_DT - data de 1 observao / ltima interaco c/ o doente
               Saida:   O_MSG - msg a mostrar ao utilizador, para assumir responsabilidade
               O_ERROR - erro
        
          CRIAO: CRS 2005/04/08
          NOTAS:
        *********************************************************************************/
        CURSOR c_first_obs(l_id_episode episode.id_episode%TYPE) IS
            SELECT ei.dt_first_obs_tstz,
                   ei.dt_first_nurse_obs_tstz,
                   ei.id_first_nurse_resp,
                   ei.id_professional,
                   ei.id_schedule,
                   ei.flg_status,
                   epis.id_epis_type,
                   epis.flg_ehr,
                   epis.flg_status flg_status_epis,
                   ei.id_prof_first_obs,
                   ei.dt_init,
                   epis.id_patient
              FROM epis_info ei, episode epis
             WHERE ei.id_episode = l_id_episode
               AND epis.id_episode = l_id_episode;
        -- Jose Brito 28/01/2009 ALERT-15511
        -- Status of the episode will be checked later on!!
        --AND epis.flg_status NOT IN (g_epis_inactive, g_epis_cancel);
    
        -- 13-03-2008 descomentei porque nao pode actualizar qdo episodio inactivo ou cancelado
        --23-10-2007-SF retirei esta condio porque quando se
        --estava a efectuar  notas ps-alta estava a fazer update  dt_first_obs
        r_first_obs c_first_obs%ROWTYPE;
    
        CURSOR c_room IS
            SELECT id_room
              FROM prof_room
             WHERE id_professional = i_prof.id
               AND flg_pref = g_room_pref
               AND id_room IN (SELECT r.id_room
                                 FROM department dep, room r, software_dept sd
                                WHERE dep.id_institution = i_prof.institution
                                  AND dep.id_department = r.id_department
                                  AND sd.id_software = i_prof.software
                                  AND sd.id_dept = dep.id_dept);
    
        l_id_visit      visit.id_visit%TYPE;
        l_id_episode    episode.id_episode%TYPE;
        l_prof_cat_type category.flg_type%TYPE;
        l_continue      BOOLEAN := FALSE;
        l_room          epis_info.id_room%TYPE;
        l_rows_ei       table_varchar;
        l_epis_info     epis_info%ROWTYPE;
        l_flg_nurse_pre dep_clin_serv.flg_nurse_pre%TYPE;
        --l_dt_first_obs_tstz epis_info.dt_first_obs_tstz%TYPE;
        --l_dt_first_inst_obs_tstz epis_info.dt_first_inst_obs_tstz%TYPE;
        --l_id_prof_first_sch epis_info.id_prof_first_sch%TYPE;
        --l_dt_first_sch epis_info.dt_first_sch%TYPE;
        --l_dt_first_nurse_obs_tstz epis_info.dt_first_nurse_obs_tstz%TYPE;
        --l_id_prof_first_nurse_obs epis_info.id_prof_first_nurse_obs%TYPE;
        --l-_id_prof_first_nurse_sch epis_info.id_prof_first_nurse_sch%TYPE;
        --l_dt_first_nurse_sch epis_info.dt_first_nurse_sch%TYPE;
        --l_dt_last_interaction_tstz epis_info.dt_last_interaction_tstz%TYPE;
        l_ann_arriv_status  announced_arrival.flg_status%TYPE;
        l_fin_transfer_epis transfer_institution.id_episode%TYPE;
    
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_id_profile_template   profile_template.id_profile_template%TYPE;
        l_handoff_no_permission sys_config.value%TYPE;
        l_tab_handoff_no_perm   table_number;
        l_wf_type               VARCHAR2(1 CHAR);
        l_from_state            VARCHAR2(1 CHAR);
        l_to_state              VARCHAR2(1 CHAR);
    
        FUNCTION set_rehab_wf
        (
            i_wf_type    IN VARCHAR2,
            i_from_state IN VARCHAR2,
            i_to_state   IN VARCHAR2
        ) RETURN BOOLEAN AS
            l_func_name        VARCHAR2(32) := $$PLSQL_UNIT;
            l_id_episode_aux   episode.id_episode%TYPE;
            l_dep_type         sch_event.dep_type%TYPE;
            l_rehab_schedule   rehab_schedule.id_rehab_schedule%TYPE;
            l_rehab_sch_need   rehab_schedule.id_rehab_sch_need%TYPE;
            l_id_epis_origin   rehab_epis_encounter.id_episode_origin%TYPE;
            l_id_epis_rehab    rehab_epis_encounter.id_rehab_epis_encounter%TYPE;
            l_rehab_flg_status rehab_epis_encounter.flg_status%TYPE;
        BEGIN
        
            IF i_wf_type = pk_rehab.g_workflow_type_s
            THEN
                -- get ingredients. no_data_Found sao apanhados pelo when others principal
                SELECT rs.id_rehab_schedule, rs.id_rehab_sch_need
                  INTO l_rehab_schedule, l_rehab_sch_need
                  FROM rehab_schedule rs
                 WHERE rs.id_schedule = r_first_obs.id_schedule;
            END IF;
        
            --get id_episode_origin. no_data_Found sao apanhados pelo when others principal
            BEGIN
                SELECT ree.id_episode_origin, ree.id_rehab_epis_encounter, ree.flg_status
                  INTO l_id_epis_origin, l_id_epis_rehab, l_rehab_flg_status
                  FROM rehab_epis_encounter ree
                  JOIN epis_info ei
                    ON ei.id_episode = ree.id_episode_rehab
                 WHERE ei.id_schedule = r_first_obs.id_schedule
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT rsn.id_episode_origin
                      INTO l_id_epis_origin
                      FROM rehab_sch_need rsn
                      JOIN rehab_schedule rs
                        ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
                     WHERE rs.id_schedule = r_first_obs.id_schedule;
            END;
        
            IF l_id_epis_origin IS NULL
            THEN
                l_id_epis_origin := i_id_episode;
                --      l_id_epis_rehab := i_id_episode;
            END IF;
            IF l_rehab_flg_status <> i_to_state
            THEN
                IF NOT pk_rehab.set_rehab_wf_change_nocommit(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_patient        => r_first_obs.id_patient,
                                                             i_workflow_type     => i_wf_type,
                                                             i_from_state        => i_from_state,
                                                             i_to_state          => i_to_state,
                                                             i_id_rehab_grid     => l_id_epis_rehab,
                                                             i_id_rehab_presc    => l_rehab_sch_need,
                                                             i_id_epis_origin    => l_id_epis_origin,
                                                             i_id_rehab_schedule => l_rehab_schedule,
                                                             i_id_schedule       => r_first_obs.id_schedule,
                                                             i_id_cancel_reason  => NULL,
                                                             i_cancel_notes      => NULL,
                                                             i_transaction_id    => NULL,
                                                             o_id_episode        => l_id_episode_aux,
                                                             o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            RETURN TRUE;
        END set_rehab_wf;
    
    BEGIN
        l_id_episode := i_id_episode;
    
        g_error := 'GET PROF CATEGORY:';
        IF i_prof_cat_type IS NULL
        THEN
            l_prof_cat_type := pk_tools.get_prof_cat(i_prof);
        ELSE
            l_prof_cat_type := i_prof_cat_type;
        END IF;
    
        g_error            := 'GET PROF CATEGORY:';
        l_ann_arriv_status := pk_announced_arrival.get_ann_arrival_status(l_id_episode);
    
        IF l_ann_arriv_status = pk_announced_arrival.g_aa_arrival_status_a
           OR l_ann_arriv_status IS NULL
        THEN
            g_error := 'VALIDATE';
            IF l_id_episode IS NULL
            THEN
                -- Se o registo foi feito a partir do proc. clnico electrnico (PK_PATIENT)
                -- Verificar se existe visita / episdio activos
                g_error := 'CALL TO PK_VISIT.GET_ACTIVE_VIS_EPIS';
                IF NOT pk_visit.get_active_vis_epis(i_lang           => i_lang,
                                                    i_id_pat         => i_pat,
                                                    i_id_institution => i_prof.institution,
                                                    i_prof           => i_prof,
                                                    o_id_visit       => l_id_visit,
                                                    o_id_episode     => l_id_episode,
                                                    o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            --
        
            IF l_id_episode IS NOT NULL
            THEN
            
                g_error := 'SELECT epis_info with ID_EPISODE = ' || l_id_episode;
                SELECT ei.*
                  INTO l_epis_info
                  FROM epis_info ei
                 WHERE ei.id_episode = l_id_episode;
            
                -- Mesmo q  venha preenchido no par., encontrou-se ID do epis activo
                g_error := 'GET CURSOR C_FIRST_OBS';
                OPEN c_first_obs(l_id_episode);
                FETCH c_first_obs
                    INTO r_first_obs;
                CLOSE c_first_obs;
                IF ((r_first_obs.dt_first_obs_tstz IS NULL AND
                   check_first_obs_category(i_lang, i_prof, l_prof_cat_type) = pk_alert_constant.g_yes) OR
                   ((r_first_obs.dt_first_nurse_obs_tstz IS NULL OR r_first_obs.id_first_nurse_resp IS NULL) AND
                   l_prof_cat_type = g_cat_type_nurse))
                  -- Jose Brito 28/01/2009 ALERT-15511
                  -- Avoid update of inactive/cancelled episodes.
                   AND r_first_obs.flg_status_epis NOT IN (g_epis_inactive, g_epis_cancel)
                THEN
                    l_continue := TRUE;
                END IF;
            
                IF l_continue
                THEN
                    -- CRS 2006/12/22 Bloco seguinte comentado at anlise mais aprofundada da necessidade / vantagem da verificao da existncia de Alert WR
                
                    g_error := 'GET CURSOR C_ROOM';
                    OPEN c_room;
                    FETCH c_room
                        INTO l_room;
                    CLOSE c_room;
                
                    -- Actualizao da data correspondente  categoria do profissional
                    IF check_first_obs_category(i_lang, i_prof, l_prof_cat_type) = pk_alert_constant.g_yes
                    THEN
                    
                        g_error := 'DELETE NURSE TRIAGE ALERT';
                        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                                               i_prof,
                                                               l_id_episode,
                                                               NULL,
                                                               pk_edis_triage.g_alert_doc,
                                                               pk_edis_triage.g_type_rem,
                                                               o_error)
                        THEN
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    
                        -- Mdico
                    
                        g_error := 'UPDATE(1)';
                    
                        ts_epis_info.upd(id_episode_in              => l_id_episode,
                                         dt_first_obs_tstz_in       => CASE r_first_obs.flg_ehr
                                                                           WHEN g_flg_ehr_s THEN
                                                                            NULL
                                                                           ELSE
                                                                            nvl(l_epis_info.dt_first_obs_tstz,
                                                                                i_dt_first_obs)
                                                                       END,
                                         dt_first_obs_tstz_nin      => FALSE,
                                         dt_first_inst_obs_tstz_in  => CASE r_first_obs.flg_ehr
                                                                           WHEN g_flg_ehr_s THEN
                                                                            NULL
                                                                           ELSE
                                                                            nvl(l_epis_info.dt_first_inst_obs_tstz,
                                                                                i_dt_first_obs)
                                                                       END,
                                         dt_first_inst_obs_tstz_nin => FALSE,
                                         id_prof_first_sch_in       => nvl(l_epis_info.id_prof_first_sch,
                                                                           CASE r_first_obs.flg_ehr
                                                                               WHEN g_flg_ehr_s THEN
                                                                                i_prof.id
                                                                               ELSE
                                                                                NULL
                                                                           END),
                                         id_prof_first_sch_nin      => FALSE,
                                         id_prof_first_obs_in       => nvl(l_epis_info.id_prof_first_obs,
                                                                           CASE r_first_obs.flg_ehr
                                                                               WHEN g_flg_ehr_s THEN
                                                                                NULL
                                                                               ELSE
                                                                                i_prof.id
                                                                           END),
                                         id_prof_first_obs_nin      => FALSE,
                                         dt_first_sch_in            => nvl(l_epis_info.dt_first_sch,
                                                                           CASE r_first_obs.flg_ehr
                                                                               WHEN g_flg_ehr_s THEN
                                                                                i_dt_first_obs
                                                                               ELSE
                                                                                NULL
                                                                           END),
                                         dt_first_sch_nin           => FALSE,
                                         rows_out                   => l_rows_ei);
                    
                        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_table_name   => 'EPIS_INFO',
                                                      i_rowids       => l_rows_ei,
                                                      o_error        => o_error,
                                                      i_list_columns => table_varchar('DT_FIRST_OBS_TSTZ',
                                                                                      'DT_FIRST_INST_OBS_TSTZ',
                                                                                      'ID_PROF_FIRST_SCH',
                                                                                      'DT_FIRST_SCH',
                                                                                      'ID_PROF_FIRST_OBS'));
                    
                        l_rows_ei := table_varchar();
                    
                        -- update the schedule_outp state (for ambulatory products)
                        -- whenever a schedule exists
                        IF r_first_obs.id_epis_type IN
                           (g_epis_type_outp,
                            g_epis_type_pp,
                            g_epis_type_care,
                            g_epis_type_nutri,
                            pk_alert_constant.g_epis_type_social,
                            pk_alert_constant.g_epis_type_psychologist,
                            pk_alert_constant.g_epis_type_resp_therapist,
                            pk_alert_constant.g_epis_type_home_health_care)
                           AND r_first_obs.id_schedule > 0
                        THEN
                        
                            IF r_first_obs.id_epis_type = g_epis_type_nutri
                            THEN
                                g_error := 'UPDATE(2)';
                                UPDATE schedule_outp
                                   SET flg_state = decode(flg_state,
                                                          g_sched_nurse_prev,
                                                          g_sched_nurse_prev,
                                                          g_sched_nurse,
                                                          g_sched_nurse,
                                                          g_sched_nutri_disch,
                                                          g_sched_nutri_disch,
                                                          g_sched_doctor)
                                 WHERE id_schedule = r_first_obs.id_schedule;
                            
                            ELSE
                                IF r_first_obs.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                                THEN
                                
                                    l_flg_nurse_pre := pk_alert_constant.g_no;
                                ELSE
                                    IF r_first_obs.id_schedule > 0
                                    THEN
                                        g_error := 'GET FLG_NURSE_PRE 1';
                                        SELECT dcs.flg_nurse_pre
                                          INTO l_flg_nurse_pre
                                          FROM dep_clin_serv dcs, schedule s
                                         WHERE s.id_schedule = r_first_obs.id_schedule
                                           AND s.id_dcs_requested = dcs.id_dep_clin_serv
                                           AND dcs.flg_available = g_flg_available;
                                    ELSIF l_epis_info.id_dcs_requested IS NOT NULL
                                    THEN
                                        g_error := 'GET FLG_NURSE_PRE 2';
                                        SELECT dcs.flg_nurse_pre
                                          INTO l_flg_nurse_pre
                                          FROM dep_clin_serv dcs
                                         WHERE dcs.id_dep_clin_serv = l_epis_info.id_dcs_requested
                                           AND dcs.flg_available = g_flg_available;
                                    END IF;
                                END IF;
                                IF r_first_obs.flg_ehr = g_flg_ehr_n
                                THEN
                                    UPDATE schedule_outp
                                       SET flg_state = decode(flg_state,
                                                              g_sched_nurse_prev,
                                                              g_sched_nurse_prev,
                                                              g_sched_nurse,
                                                              g_sched_nurse,
                                                              g_sched_efectiv,
                                                              decode(l_flg_nurse_pre,
                                                                     g_flg_nurse_pre_y,
                                                                     g_sched_efectiv,
                                                                     g_sched_doctor),
                                                              g_sched_doctor_disch,
                                                              g_sched_doctor_disch,
                                                              g_sched_doctor)
                                     WHERE id_schedule = r_first_obs.id_schedule;
                                END IF;
                            END IF;
                        ELSIF r_first_obs.id_epis_type IN
                              (pk_alert_constant.g_epis_type_rehab_session,
                               pk_alert_constant.g_epis_type_rehab_appointment)
                              AND r_first_obs.dt_first_obs_tstz IS NULL
                              AND r_first_obs.id_schedule > 0
                              AND r_first_obs.flg_ehr <> g_flg_ehr_s
                        THEN
                            -- REHAB
                            IF r_first_obs.id_epis_type = pk_alert_constant.g_epis_type_rehab_session
                            THEN
                                l_wf_type := pk_rehab.g_workflow_type_s;
                            ELSE
                                l_wf_type := pk_rehab.g_workflow_type_a;
                            END IF;
                            l_from_state := pk_rehab.g_rehab_epis_enc_status_b;
                            l_to_state   := pk_rehab.g_rehab_epis_enc_status_s;
                            IF NOT set_rehab_wf(i_wf_type    => l_wf_type,
                                                i_from_state => l_from_state,
                                                i_to_state   => l_to_state)
                            THEN
                                pk_utils.undo_changes;
                                RETURN FALSE;
                            END IF;
                        END IF;
                    
                        IF r_first_obs.flg_status NOT IN
                           (g_epis_info_doctor, g_epis_info_last_nurse, g_epis_info_clin_disch, g_epis_info_adm_disch)
                        THEN
                            -- Se o estado j correspondia a consulta ou ps-consulta,  altera
                            -- No caso de ser um episdio de URGNCIA no altera a sala -- ET(2007/01/09)
                            IF r_first_obs.id_epis_type NOT IN
                               (g_epis_type,
                                g_epis_type_inp,
                                g_epis_type_session,
                                pk_alert_constant.g_epis_type_nurse_care,
                                pk_alert_constant.g_epis_type_nurse_outp,
                                pk_alert_constant.g_epis_type_nurse_pp)
                            THEN
                                ts_epis_info.upd(id_episode_in => l_id_episode,
                                                 flg_status_in => g_epis_info_doctor,
                                                 id_room_in    => l_room,
                                                 id_room_nin   => TRUE,
                                                 rows_out      => l_rows_ei);
                            
                                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_table_name   => 'EPIS_INFO',
                                                              i_rowids       => l_rows_ei,
                                                              o_error        => o_error,
                                                              i_list_columns => table_varchar('FLG_STATUS', 'ID_ROOM'));
                            
                                l_rows_ei := table_varchar();
                            
                                IF r_first_obs.id_epis_type NOT IN
                                   (g_epis_type_outp,
                                    g_epis_type_pp,
                                    g_epis_type_care,
                                    g_epis_type_nutri,
                                    pk_alert_constant.g_epis_type_social)
                                THEN
                                    IF r_first_obs.flg_ehr = g_flg_ehr_n
                                    THEN
                                        g_error := 'UPDATE(2)';
                                        UPDATE schedule_outp
                                           SET flg_state = g_sched_doctor
                                         WHERE id_schedule = r_first_obs.id_schedule;
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    
                    ELSIF l_prof_cat_type = g_cat_type_nurse
                    THEN
                        -- Enfermeiro
                    
                        g_error := 'UPDATE(3)';
                        ts_epis_info.upd(id_episode_in               => l_id_episode,
                                         dt_first_nurse_obs_tstz_in  => nvl(l_epis_info.dt_first_nurse_obs_tstz,
                                                                            i_dt_first_obs),
                                         dt_first_nurse_obs_tstz_nin => FALSE,
                                         id_prof_first_nurse_obs_in  => nvl(l_epis_info.id_prof_first_nurse_obs,
                                                                            i_prof.id),
                                         id_prof_first_nurse_obs_nin => FALSE,
                                         dt_first_inst_obs_tstz_in   => nvl(l_epis_info.dt_first_inst_obs_tstz,
                                                                            i_dt_first_obs),
                                         dt_first_inst_obs_tstz_nin  => FALSE,
                                         id_prof_first_nurse_sch_in  => nvl(l_epis_info.id_prof_first_nurse_sch,
                                                                            CASE r_first_obs.flg_ehr
                                                                                WHEN g_flg_ehr_s THEN
                                                                                 i_prof.id
                                                                                ELSE
                                                                                 NULL
                                                                            END),
                                         id_prof_first_nurse_sch_nin => FALSE,
                                         dt_first_nurse_sch_in       => nvl(l_epis_info.dt_first_nurse_sch,
                                                                            CASE r_first_obs.flg_ehr
                                                                                WHEN g_flg_ehr_s THEN
                                                                                 i_dt_first_obs
                                                                                ELSE
                                                                                 NULL
                                                                            END),
                                         dt_first_nurse_sch_nin      => FALSE,
                                         rows_out                    => l_rows_ei);
                    
                        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_table_name   => 'EPIS_INFO',
                                                      i_rowids       => l_rows_ei,
                                                      o_error        => o_error,
                                                      i_list_columns => table_varchar('DT_FIRST_NURSE_OBS_TSTZ',
                                                                                      'ID_PROF_FIRST_NURSE_OBS',
                                                                                      'DT_FIRST_INST_OBS_TSTZ',
                                                                                      'ID_PROF_FIRST_NURSE_SCH',
                                                                                      'DT_FIRST_NURSE_SCH'));
                    
                        l_rows_ei := table_varchar();
                    
                        /*                    IF r_first_obs.flg_status NOT IN (g_epis_info_doctor, g_epis_info_last_nurse, g_epis_info_clin_disch,
                        g_epis_info_adm_disch, g_epis_info_first_nurse)*/
                        IF r_first_obs.flg_status NOT IN (g_epis_info_last_nurse,
                                                          g_epis_info_clin_disch,
                                                          g_epis_info_adm_disch,
                                                          g_epis_info_first_nurse)
                        
                        THEN
                            -- Se o estado j correspondia a enfermagem inicial, consulta ou ps-consulta,  altera
                        
                            -- No caso de ser um episdio de URGNCIA no altera a sala -- ET(2007/01/09)
                            --IF r_first_obs.id_epis_type <> g_epis_type
                            -- Jos Brito 24/07/2008 Episdios temporrios criados pelo enfermeiro no UBU, eram automaticamente
                            -- colocados sob a responsabilidade do desse profissional.
                            IF r_first_obs.id_epis_type NOT IN (g_epis_type_edis, g_epis_type_ubu, g_epis_type_inp)
                            THEN
                                g_error               := 'GET PROF PROFILE_TEMPLATE';
                                l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
                            
                                g_error                 := 'GET HANDOFF NO PERMISSION PROFILES';
                                l_handoff_no_permission := TRIM('|' FROM pk_sysconfig.get_config('PROFILE_TEMPLATE_HANDOFF_PERMISSION',
                                                                                        i_prof.institution,
                                                                                        i_prof.software));
                                l_tab_handoff_no_perm   := pk_utils.str_split_n(i_list  => l_handoff_no_permission,
                                                                                i_delim => '|');
                            
                                IF pk_utils.search_table_number(i_table  => l_tab_handoff_no_perm,
                                                                i_search => l_id_profile_template) = -1
                                THEN
                                    g_error := 'UPDATE(4)';
                                
                                    ts_epis_info.upd(id_episode_in          => l_id_episode,
                                                     id_first_nurse_resp_in => i_prof.id,
                                                     flg_status_in          => g_epis_info_doctor,
                                                     rows_out               => l_rows_ei);
                                
                                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_table_name   => 'EPIS_INFO',
                                                                  i_rowids       => l_rows_ei,
                                                                  o_error        => o_error,
                                                                  i_list_columns => table_varchar('ID_FIRST_NURSE_RESP',
                                                                                                  'FLG_STATUS'));
                                
                                    l_rows_ei := table_varchar();
                                END IF;
                            
                                IF r_first_obs.flg_ehr = g_flg_ehr_n
                                   AND r_first_obs.id_epis_type <> pk_alert_constant.g_epis_type_home_health_care
                                THEN
                                    g_error := 'UPDATE(5)';
                                    UPDATE schedule_outp
                                       SET flg_state = g_sched_nurse
                                     WHERE id_schedule = r_first_obs.id_schedule;
                                ELSIF r_first_obs.flg_ehr = g_flg_ehr_n
                                      AND r_first_obs.id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                                THEN
                                    UPDATE schedule_outp
                                       SET flg_state = g_sched_doctor
                                     WHERE id_schedule = r_first_obs.id_schedule;
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                ELSIF r_first_obs.dt_first_obs_tstz IS NOT NULL
                      AND l_prof_cat_type = g_cat_type_doc
                THEN
                    IF r_first_obs.flg_ehr = g_flg_ehr_n
                    THEN
                        IF r_first_obs.id_epis_type NOT IN
                           (pk_alert_constant.g_epis_type_nurse_care,
                            pk_alert_constant.g_epis_type_nurse_outp,
                            pk_alert_constant.g_epis_type_nurse_pp)
                        THEN
                            g_error := 'UPDATE SCHEDULE_OUTP';
                            UPDATE schedule_outp
                               SET flg_state = decode(flg_state, g_sched_nurse_end, g_sched_doctor, flg_state)
                             WHERE id_schedule = r_first_obs.id_schedule;
                        END IF;
                    
                        -- Check status of institution transfer
                        BEGIN
                            g_error := 'CHECK TRANSFER INST';
                            SELECT t.id_episode
                              INTO l_fin_transfer_epis
                              FROM (SELECT ti.id_episode,
                                           row_number() over(PARTITION BY id_episode ORDER BY dt_end_tstz DESC) row_number
                                      FROM transfer_institution ti
                                     WHERE ti.id_institution_dest = i_prof.institution
                                       AND ti.flg_status = pk_transfer_institution.g_transfer_inst_fin) t
                             WHERE t.id_episode = l_id_episode
                               AND row_number = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_fin_transfer_epis := NULL;
                        END;
                    
                        -- Clear first observation alert in transferred patients (with a finalized transfer)
                        IF l_fin_transfer_epis IS NOT NULL
                        THEN
                            g_error := 'DELETE NURSE TRIAGE ALERT';
                            IF NOT pk_edis_triage.set_alert_triage(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_episode       => l_id_episode,
                                                                   i_dt_req_det       => NULL,
                                                                   i_alert_type       => pk_alert_constant.g_cat_type_doc,
                                                                   i_type             => pk_edis_triage.g_type_rem,
                                                                   i_is_transfer_inst => pk_alert_constant.g_yes,
                                                                   o_error            => o_error)
                            THEN
                                pk_utils.undo_changes;
                                RETURN FALSE;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
            g_error := 'UPDATE(6)';
        
            l_rows_ei := table_varchar();
            ts_epis_info.upd(id_episode_in               => l_id_episode,
                             dt_last_interaction_tstz_in => l_current_timestamp,
                             dt_first_inst_obs_tstz_in   => nvl(l_epis_info.dt_first_inst_obs_tstz,
                                                                CASE l_prof_cat_type
                                                                    WHEN g_cat_type_doc THEN
                                                                     i_dt_first_obs
                                                                    WHEN g_cat_type_nurse THEN
                                                                     i_dt_first_obs
                                                                    WHEN g_cat_type_triage THEN
                                                                     i_dt_first_obs
                                                                    ELSE
                                                                     l_epis_info.dt_first_inst_obs_tstz
                                                                END),
                             rows_out                    => l_rows_ei);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rows_ei,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('dt_last_interaction_tstz',
                                                                          'dt_first_inst_obs_tstz')); -- LMAIA 03-11-2008 (Actualizadas as colunas de acordo com o UPDATE anterior)
        
        END IF;
    
        l_rows_ei := table_varchar();
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episdio
        IF (nvl(i_id_episode, 0) != 0 OR nvl(l_id_episode, 0) != 0)
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => nvl(i_id_episode, l_id_episode),
                                              i_patient  => i_pat,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            g_error := 'UPDATE EPIS_PROF_SPEC';
            IF NOT pk_visit.set_epis_prof_dcs(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_episode => nvl(i_id_episode, l_id_episode),
                                              o_error   => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        --Trigger the begin apointment event to interfaces
        IF ((r_first_obs.dt_first_obs_tstz IS NULL AND
           l_prof_cat_type IN
           (g_cat_type_doc, g_cat_type_nutri, g_cat_type_fisio, pk_alert_constant.g_cat_type_social)) OR
           (r_first_obs.dt_first_nurse_obs_tstz IS NULL AND l_prof_cat_type = g_cat_type_nurse))
           AND r_first_obs.flg_status_epis NOT IN (g_epis_inactive, g_epis_cancel)
           AND r_first_obs.flg_ehr = g_flg_ehr_n
           AND i_id_episode IS NOT NULL
           AND r_first_obs.dt_init IS NULL
        THEN
            g_error := 'CALL pk_ia_event_common.episode_appointment_start || i_id_institution = ' || i_prof.institution ||
                       ', i_id_episode = ' || i_id_episode;
            pk_ia_event_common.episode_appointment_start(i_id_institution => i_prof.institution,
                                                         i_id_episode     => i_id_episode);
        END IF;
    
        g_error := 'CALL PK_PATIENT_TRACKING.SET_CARE_STAGE_IN_TREAT';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_patient_tracking.set_care_stage_in_treat(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_episode         => i_id_episode,
                                                           i_flg_triage_call => i_flg_triage_call,
                                                           o_error           => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        --    COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'SET_FIRST_OBS 1');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION get_active_vis_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat         IN patient.id_patient%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof           IN profissional,
        o_id_visit       OUT visit.id_visit%TYPE,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Verificar se existe visita e episdio activos para o doente.
                      Mesmo q exista + do q 1 visita ou epis. activos, s retorna o + recente.
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                                 I_ID_PAT - Utente
                                 I_ID_INSTITUTION - Instituio
        
                          Saida: O_ID_VISIT - ID da visita activa, se existir
                                 O_ID_EPISODE - ID do episdio activo, se existir
                                 O_ERROR - erro
        
          CRIAO: CRS 2005/03/23
          NOTAS:
        *********************************************************************************/
        l_id_visit visit.id_visit%TYPE;
        --
        CURSOR c_visit IS -- ID da visita activa + recente do doente
            SELECT id_visit
              FROM visit
             WHERE id_patient = i_id_pat
               AND flg_status = g_visit_active
               AND id_institution = i_prof.institution
             ORDER BY dt_begin_tstz DESC;
    
        CURSOR c_epis_visit IS -- ID do episdio activo + recente da visita
            SELECT id_episode
              FROM episode e
             WHERE e.id_visit = l_id_visit
               AND e.flg_status = g_epis_active
             ORDER BY dt_begin_tstz DESC;
    
    BEGIN
    
        g_error := 'GET CURSOR C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_id_visit;
        g_found := c_visit%FOUND;
        CLOSE c_visit;
        IF g_found
        THEN
            o_id_visit := l_id_visit;
        
            g_error := 'GET CURSOR C_EPIS_VISIT';
            OPEN c_epis_visit;
            FETCH c_epis_visit
                INTO o_id_episode;
            CLOSE c_epis_visit;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_VISIT',
                                                     'GET_ACTIVE_VIS_EPIS',
                                                     o_error);
        
    END;

    FUNCTION get_visit
    (
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN visit.id_visit%TYPE IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
        g_error := 'SELECT';
        SELECT e.id_visit
          INTO l_visit
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        RETURN l_visit;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_visit;

    FUNCTION set_prof_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar prof responsvel
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                  I_ID_EPISODE - Id do episdio
               I_PROF - profissional q regista
               Saida:   O_ERROR - erro
        
          CRIAO: CRS 2005/04/11
          NOTAS:
        *********************************************************************************/
    
        l_rows table_varchar;
        l_exception_ext EXCEPTION;
        l_category_type category.flg_type%TYPE;
    
    BEGIN
        BEGIN
            SELECT c.flg_type
              INTO l_category_type
              FROM prof_cat pc
              JOIN category c
                ON c.id_category = pc.id_category
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        EXCEPTION
            WHEN OTHERS THEN
                l_category_type := NULL;
        END;
        g_sysdate_tstz := current_timestamp;
        g_error        := 'UPDATE';
        /* <DENORM Fbio> */
    
        IF l_category_type = g_cat_type_nurse
        THEN
            ts_epis_info.upd(id_episode_in           => i_id_episode,
                             id_first_nurse_resp_in  => i_prof.id,
                             id_first_nurse_resp_nin => FALSE,
                             rows_out                => l_rows);
        ELSE
            ts_epis_info.upd(id_episode_in       => i_id_episode,
                             id_professional_in  => i_prof.id,
                             id_professional_nin => FALSE,
                             rows_out            => l_rows);
        END IF;
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rows, o_error);
    
        g_error := 'CALL pk_alerts.set_alert_professional';
        IF NOT pk_alerts.set_alert_professional(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => pk_opinion.g_alert_needs_approval,
                                                i_episode      => i_id_episode,
                                                i_professional => i_prof.id,
                                                o_error        => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT set_first_obs(i_lang                => i_lang,
                             i_id_episode          => i_id_episode,
                             i_pat                 => NULL,
                             i_prof                => i_prof,
                             i_prof_cat_type       => NULL,
                             i_dt_last_interaction => g_sysdate_tstz,
                             i_dt_first_obs        => g_sysdate_tstz,
                             o_error               => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_PROF_RESP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * CREATE_EXAM_REQ_PRESC        Verifica se h requisies ou prescries de episdios anteriores para fazer neste episdio.
    *                              Se existir, copia os registos para o novo episdio com o novo status.
    *
    * @param i_lang                language id
    * @param i_prof                professional id
    * @param i_id_episode          episode identifier
    * @param i_id_patient          patient identifier
    * @param i_id_clin_service     dep_clin_serv identifier
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Rui Batista
    * @version                     2.4.0
    * @since                       2005/05/02
    **********************************************************************************************/
    FUNCTION create_exam_req_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_id_episode      IN epis_info.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_clin_service IN episode.id_clinical_service%TYPE,
        i_prof            IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_icnp_interv(pin_id_episode IN episode.id_episode%TYPE) IS
            SELECT a.dt_icnp_epis_interv_tstz,
                   a.id_patient,
                   a.id_episode,
                   a.id_composition,
                   a.id_icnp_epis_interv,
                   a.flg_status,
                   a.id_prof,
                   a.dt_begin_tstz,
                   a.dt_end_tstz,
                   a.flg_type,
                   a.notes,
                   ap.dt_plan_tstz,
                   ap.flg_status              flg_status_plan,
                   ad.id_icnp_epis_diag,
                   ap.notes                   notes_plan,
                   ap.id_epis_documentation,
                   a.id_order_recurr_plan,
                   a.flg_prn,
                   a.prn_notes,
                   a.flg_time
              FROM icnp_epis_intervention a, icnp_interv_plan ap, icnp_epis_diag_interv ad
             WHERE a.id_episode = pin_id_episode
               AND a.id_episode_destination IS NULL
               AND a.flg_time = g_flg_time_n
               AND a.flg_status IN (g_flg_status_a, g_flg_status_i)
               AND ap.id_icnp_epis_interv(+) = a.id_icnp_epis_interv
               AND ad.id_icnp_epis_interv(+) = a.id_icnp_epis_interv;
    
        CURSOR c_analysis_req(pin_id_episode IN episode.id_episode%TYPE) IS
            SELECT a.id_analysis_req, a.flg_status
              FROM analysis_req a
             WHERE ((a.id_episode_destination = pin_id_episode AND a.id_episode IS NULL) OR
                   (a.id_episode_origin = pin_id_episode))
               AND a.flg_status != pk_alert_constant.g_flg_status_c
               AND EXISTS (SELECT 1
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = a.id_analysis_req
                       AND ard.flg_time_harvest = g_flg_time_n
                       AND ard.flg_status != pk_alert_constant.g_flg_status_c);
    
        CURSOR c_analysis_req_det(pin_id_analysis_req IN analysis_req.id_analysis_req%TYPE) IS
            SELECT ad.id_analysis_req_det, h.id_harvest, ad.flg_status
              FROM analysis_req_det ad, analysis_harvest ah, harvest h
             WHERE ad.id_analysis_req = pin_id_analysis_req
               AND ad.flg_time_harvest = g_flg_time_n
               AND ad.id_analysis_req_det = ah.id_analysis_req_det
               AND ah.id_harvest = h.id_harvest;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_exam_req(pin_id_episode IN episode.id_episode%TYPE) IS --PROCURA EXAMES REQUISITADOS PARA O EPISDIO SEGUINTE
            SELECT a.id_exam_req, a.flg_status
              FROM exam_req a
             WHERE ((a.id_episode_destination = pin_id_episode AND a.id_episode IS NULL) OR
                   (a.id_episode_origin = pin_id_episode))
               AND a.flg_time = g_flg_time_n
               AND a.flg_status != pk_alert_constant.g_flg_status_c;
    
        CURSOR c_exam_req_det(pin_id_exam_req IN exam_req.id_exam_req%TYPE) IS
            SELECT ad.id_exam_req_det, ad.flg_status
              FROM exam_req_det ad
             WHERE ad.id_exam_req = pin_id_exam_req;
    
        CURSOR c_interv_prescription(pin_id_episode IN episode.id_episode%TYPE) IS --PROCURA INTERVENES PRESCRITAS PARA O EPISDIO SEGUINTE
            SELECT a.id_interv_prescription, ad.id_interv_presc_det, ad.flg_status
              FROM interv_prescription a, interv_presc_det ad, interv_presc_plan ap
             WHERE ((a.id_episode_destination = pin_id_episode AND a.id_episode IS NULL) OR
                   (a.id_episode_origin = pin_id_episode))
               AND a.flg_time = g_flg_time_n
               AND a.flg_status != pk_alert_constant.g_flg_status_c
               AND a.id_interv_prescription = ad.id_interv_prescription;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_monit(pin_id_episode IN episode.id_episode%TYPE) IS --PROCURA LEITURAS AGENDADAS PARA O EPISDIO SEGUINTE
            SELECT a.id_monitorization mon_id_monitorization,
                   a.dt_monitorization_tstz,
                   i_id_episode,
                   a.id_professional,
                   a.notes,
                   a.dt_begin_tstz,
                   g_flg_time_e,
                   a.dt_end_tstz,
                   a.interval,
                   a.flg_status,
                   a.id_episode,
                   a.id_monitorization,
                   a.id_patient
              FROM monitorization a
             WHERE a.id_episode = pin_id_episode
               AND a.id_episode_destination IS NULL
               AND a.flg_time = g_flg_time_n
               AND a.flg_status IN (g_flg_status_d, g_flg_status_r)
             ORDER BY 1;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_monit_vs(pin_id_monitorization IN monitorization.id_monitorization%TYPE) IS --PROCURA LEITURAS AGENDADAS PARA O EPISDIO SEGUINTE
            SELECT ad.id_monitorization_vs,
                   ad.id_monitorization,
                   ad.dt_monitorization_vs_tstz,
                   ad.id_vital_sign,
                   ad.notes                     notes_det,
                   ad.flg_status                flg_status_det,
                   ad.id_prof_order,
                   ad.id_order_type,
                   ad.dt_order
              FROM monitorization_vs ad
             WHERE ad.id_monitorization = pin_id_monitorization
             ORDER BY 1;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_monit_vsp(pin_id_monitorization_vs IN monitorization_vs.id_monitorization_vs%TYPE) IS --PROCURA LEITURAS AGENDADAS PARA O EPISDIO SEGUINTE
            SELECT mvp.dt_plan_tstz, mvp.flg_status stat
              FROM monitorization_vs_plan mvp
             WHERE mvp.id_monitorization_vs = pin_id_monitorization_vs
             ORDER BY 1;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_cli_rec_req(pin_id_episode IN episode.id_episode%TYPE) IS --PROCURA PROCESSOS CLNICOS REQUISITADOS PARA O EPISDIO SEGUINTE
            SELECT a.dt_cli_rec_req_tstz,
                   a.id_prof_req,
                   a.flg_status,
                   a.notes,
                   a.dt_begin_tstz,
                   a.id_schedule,
                   a.id_episode,
                   a.id_cli_rec_req,
                   a.flg_time
              FROM cli_rec_req a
             WHERE a.id_episode = pin_id_episode
               AND a.id_episode_destination IS NULL
               AND a.flg_time = g_flg_time_n
               AND a.flg_status IN (g_flg_status_d, g_flg_status_r);
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_cli_rec_req_det(pin_id_cli_rec_req IN cli_rec_req.id_cli_rec_req%TYPE) IS --PROCURA PROCESSOS CLNICOS REQUISITADOS PARA O EPISDIO SEGUINTE
            SELECT ad.flg_status flg_status_det, ad.id_clin_record, ad.id_cli_rec_req_det, ad.id_cli_rec_req, ad.notes
              FROM cli_rec_req_det ad
             WHERE ad.id_cli_rec_req = pin_id_cli_rec_req;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_vacc(pin_id_episode IN episode.id_episode%TYPE) IS -- Vacinas requisitadas para o episdio seguinte
            SELECT pva.id_pat_vacc_adm        id_pat_vacc_adm,
                   pva.dt_pat_vacc_adm        dt_pat_vacc_adm,
                   pva.id_prof_writes         id_prof_writes,
                   pva.id_vacc                id_vacc,
                   pva.id_patient             id_patient,
                   pva.id_episode             id_episode,
                   pva.flg_status             flg_status,
                   pva.takes                  takes,
                   pva.dosage                 dosage,
                   pva.flg_orig               flg_orig,
                   pva.dt_presc               dt_presc,
                   pva.notes_presc            notes_presc,
                   pva.prof_presc             prof_presc,
                   pva.dt_cancel              dt_cancel,
                   pva.id_prof_cancel         id_prof_cancel,
                   pva.notes_cancel           notes_cancel,
                   pva.flg_time               flg_time,
                   pva.id_episode_origin      id_episode_origin,
                   pva.id_episode_destination id_episode_destination
              FROM pat_vacc_adm pva, pat_vacc_adm_det pvad
             WHERE pva.id_episode = pin_id_episode
               AND pva.id_episode_destination IS NULL
               AND pva.flg_status IN (g_flg_status_d, g_flg_status_r)
               AND pva.id_pat_vacc_adm = pvad.id_pat_vacc_adm
               AND pva.flg_time = g_flg_time_n;
    
        -- thiago.brito
        -- 11-JUN-2008
        CURSOR c_vacc_det
        (
            pin_id_episode      IN episode.id_episode%TYPE,
            pin_id_pat_vacc_adm IN pat_vacc_adm.id_pat_vacc_adm%TYPE
        ) IS -- Vacinas requisitadas para o episdio seguinte
            SELECT pvad.dt_take                dt_taked,
                   pvad.id_drug_presc_plan     id_drug_presc_pland,
                   pvad.id_episode             id_episoded,
                   pvad.flg_status             flg_statusd,
                   pvad.desc_vaccine           desc_vaccined,
                   pvad.lot_number             lot_numberd,
                   pvad.dt_expiration          dt_expirationd,
                   pvad.flg_advers_react       flg_advers_reactd,
                   pvad.notes_advers_react     notes_advers_reactd,
                   pvad.application_spot       application_spotd,
                   pvad.report_orig            report_origd,
                   pvad.notes                  notesd,
                   pvad.emb_id                 emb_idd,
                   pvad.id_unit_measure        id_unit_measured,
                   pvad.id_prof_writes         id_prof_writesd,
                   pvad.dt_reg                 dt_regd,
                   pvad.dt_cancel              dt_cancel,
                   pvad.id_prof_cancel         id_prof_cance,
                   pvad.notes_cancel           notes_cancel,
                   pvad.id_pat_medication_list id_pat_medication_list,
                   pvad.dt_next_take           dt_next_take
              FROM pat_vacc_adm_det pvad
             WHERE pvad.id_episode = pin_id_episode
               AND pvad.id_pat_vacc_adm = pin_id_pat_vacc_adm;
    
        v_exam_req          exam_req%ROWTYPE;
        v_id_episode        episode.id_episode%TYPE;
        v_found             BOOLEAN;
        v_vacc              pat_vacc_adm%ROWTYPE;
        l_next_req          exam_req.id_exam_req%TYPE;
        l_next_mvs          NUMBER;
        l_next_mvsp         NUMBER;
        l_clin_serv         episode.id_clinical_service%TYPE;
        l_exam_next_req_det exam_req_det.id_exam_req_det%TYPE;
        l_prev_monit        monitorization.id_monitorization%TYPE := 0;
    
        l_start_date              order_recurr_plan.start_date%TYPE;
        l_order_recurr_plan       order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_desc       VARCHAR2(1000 CHAR);
        l_order_recurr_option     order_recurr_plan.id_order_recurr_option%TYPE;
        l_occurrences             order_recurr_plan.occurrences%TYPE;
        l_duration                order_recurr_plan.duration%TYPE;
        l_unit_meas_duration      order_recurr_plan.id_unit_meas_duration%TYPE;
        l_duration_desc           VARCHAR2(1000 CHAR);
        l_end_date                order_recurr_plan.end_date%TYPE;
        l_flg_end_by_editable     VARCHAR2(1 CHAR);
        l_order_recurr_option_id  order_recurr_plan.id_order_recurr_option%TYPE;
        l_order_recurr_final_id   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_recurr_definit_ids_coll table_number;
        l_order_plan_exec         t_tbl_order_recurr_plan;
        l_exec_rowids_coll        table_varchar;
        l_rowsid_plan             table_varchar := table_varchar();
        l_rowsid_m                table_varchar := table_varchar();
    
        l_iei            icnp_epis_intervention%ROWTYPE;
        l_iei_rowids     table_varchar := table_varchar();
        l_iei_rowids_ins table_varchar := table_varchar();
        l_iei_rowids_upd table_varchar := table_varchar();
    
        l_iip        icnp_interv_plan%ROWTYPE;
        l_iip_rowids table_varchar := table_varchar();
    
        l_visit       NUMBER;
        l_code_interv intervention.code_intervention%TYPE;
        l_next_plan   interv_presc_plan.id_interv_presc_plan%TYPE;
    
        l_rowids_1    table_varchar := table_varchar();
        l_rowids_2    table_varchar := table_varchar();
        l_rowids_3    table_varchar := table_varchar();
        l_rowids_nard table_varchar := table_varchar();
    
        l_rowids_aux table_varchar := table_varchar();
        l_rowids_mvs table_varchar := table_varchar();
    
        l_id_nurse_tea_topic table_number := table_number();
        l_title_topic        table_varchar := table_varchar();
        l_desc_diagnosis     table_varchar := table_varchar();
        l_id_epis_type       epis_type.id_epis_type%TYPE;
        l_id_software        software.id_software%TYPE;
        l_prof               profissional;
    
        l_tab_out table_varchar := table_varchar();
        l_sug     ts_icnp_suggest_interv.icnp_suggest_interv_tc;
        l_rowsid  table_varchar := table_varchar();
    
        e_process_event EXCEPTION;
        g_exception_ext EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error        := 'GET VISIT';
        l_visit        := pk_visit.get_visit(i_id_episode, o_error);
        l_id_epis_type := pk_episode.get_epis_type(i_lang, i_id_episode);
        l_id_software  := pk_episode.get_soft_by_epis_type(l_id_epis_type, i_prof.institution);
        l_prof         := profissional(i_prof.id, i_prof.institution, l_id_software);
    
        IF o_error IS NOT NULL
        THEN
            RETURN FALSE;
        END IF;
    
        FOR v_analysis_req IN c_analysis_req(i_id_episode)
        LOOP
            g_error := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(id_episode_in    => i_id_episode,
                                id_visit_in      => l_visit,
                                dt_begin_tstz_in => g_sysdate_tstz,
                                where_in         => 'id_analysis_req = ' || v_analysis_req.id_analysis_req ||
                                                    ' AND flg_status != ''' || pk_alert_constant.g_flg_status_c || '''' ||
                                                    ' AND id_episode_destination = ' || i_id_episode,
                                rows_out         => l_rowids_1);
        
            FOR v_analysis_req_det IN c_analysis_req_det(v_analysis_req.id_analysis_req)
            LOOP
                g_error := 'UPDATE ANALYSIS_REQ_DET';
                ts_analysis_req_det.upd(id_analysis_req_det_in => v_analysis_req_det.id_analysis_req_det,
                                        dt_target_tstz_in      => g_sysdate_tstz,
                                        rows_out               => l_rowids_2);
            
                g_error := 'UPDATE HARVEST';
                ts_harvest.upd(id_harvest_in       => v_analysis_req_det.id_harvest,
                               dt_begin_harvest_in => g_sysdate_tstz,
                               rows_out            => l_rowids_3);
            
                g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_STATUS';
                IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                               i_prof             => l_prof,
                                                               i_analysis_req_det => table_number(v_analysis_req_det.id_analysis_req_det),
                                                               i_status           => CASE v_analysis_req.flg_status
                                                                                         WHEN
                                                                                          pk_lab_tests_constant.g_analysis_draft THEN
                                                                                          pk_lab_tests_constant.g_analysis_draft
                                                                                         ELSE
                                                                                          pk_lab_tests_constant.g_analysis_req
                                                                                     END,
                                                               o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'ANALYSIS_REQ',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rowids_2,
                                      o_error      => o_error);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'HARVEST',
                                      i_rowids     => l_rowids_3,
                                      o_error      => o_error);
    
        l_rowids_1 := NULL;
        l_rowids_2 := NULL;
    
        FOR v_exam_req IN c_exam_req(i_id_episode)
        LOOP
            ts_exam_req.upd(id_episode_in    => i_id_episode,
                            dt_begin_tstz_in => g_sysdate_tstz,
                            where_in         => 'id_exam_req = ' || v_exam_req.id_exam_req || ' AND flg_status != ''' ||
                                                pk_alert_constant.g_flg_status_c || '''' ||
                                                ' AND id_episode_destination = ' || i_id_episode,
                            rows_out         => l_rowids_1);
        
            FOR v_exam_req_det IN c_exam_req_det(v_exam_req.id_exam_req)
            LOOP
                ts_exam_req_det.upd(id_exam_req_det_in => v_exam_req_det.id_exam_req_det,
                                    dt_target_tstz_in  => g_sysdate_tstz,
                                    rows_out           => l_rowids_2);
            
                g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_STATUS';
                IF NOT pk_exams_api_db.set_exam_status(i_lang            => i_lang,
                                                       i_prof            => l_prof,
                                                       i_exam_req_det    => table_number(v_exam_req_det.id_exam_req_det),
                                                       i_status          => CASE v_exam_req.flg_status
                                                                                WHEN pk_exam_constant.g_exam_draft THEN
                                                                                 pk_exam_constant.g_exam_draft
                                                                                ELSE
                                                                                 pk_exam_constant.g_exam_req
                                                                            END,
                                                       i_notes           => NULL,
                                                       i_notes_scheduler => NULL,
                                                       o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'EXAM_REQ',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rowids_2,
                                      o_error      => o_error);
    
        --VERIFICA MARCAO DE INTERVENES
    
        l_rowids_1 := NULL;
        l_rowids_2 := NULL;
        l_rowids_3 := NULL;
    
        g_error := 'GET C_INTERV';
        FOR v_interv_prescription IN c_interv_prescription(i_id_episode)
        LOOP
            g_error := 'UPDATE INTERV_PRESCRIPTION 1';
            ts_interv_prescription.upd(id_episode_in    => i_id_episode,
                                       dt_begin_tstz_in => g_sysdate_tstz,
                                       flg_status_in    => CASE v_interv_prescription.flg_status
                                                               WHEN pk_procedures_constant.g_interv_draft THEN
                                                                pk_procedures_constant.g_interv_draft
                                                               ELSE
                                                                pk_procedures_constant.g_interv_req
                                                           END,
                                       where_in         => 'id_interv_prescription = ' ||
                                                           v_interv_prescription.id_interv_prescription ||
                                                           ' AND flg_status != ''' || pk_alert_constant.g_flg_status_c || '''' ||
                                                           ' AND id_episode_destination = ' || i_id_episode,
                                       rows_out         => l_rowids_1);
        
            g_error := 'UPDATE INTERV_PRESC_DET';
            ts_interv_presc_det.upd(flg_status_in => CASE v_interv_prescription.flg_status
                                                         WHEN pk_procedures_constant.g_interv_draft THEN
                                                          pk_procedures_constant.g_interv_draft
                                                         ELSE
                                                          pk_procedures_constant.g_interv_req
                                                     END,
                                    where_in      => 'id_interv_prescription = ' ||
                                                     v_interv_prescription.id_interv_prescription,
                                    rows_out      => l_rowids_2);
        
            g_error := 'UPDATE INTERV_PRESC_PLAN';
            ts_interv_presc_plan.upd(dt_plan_tstz_in => g_sysdate_tstz,
                                     flg_status_in   => pk_procedures_constant.g_interv_plan_req,
                                     where_in        => 'id_interv_presc_det = ' ||
                                                        v_interv_prescription.id_interv_presc_det,
                                     rows_out        => l_rowsid_plan);
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'INTERV_PRESCRIPTION',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rowids_2,
                                      o_error      => o_error);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'INTERV_PRESC_PLAN',
                                      i_rowids     => l_rowids_3,
                                      o_error      => o_error);
    
        --VERIFICA QUAL O LTIMO ID DE EPISDIO PARA ESTE PACIENTE/ESPECIALIDADE
        BEGIN
            g_error := 'GET LAST EPISODE ID';
            SELECT t.id_episode
              INTO v_id_episode
              FROM (SELECT e.*,
                           row_number() over(PARTITION BY e.id_clinical_service ORDER BY s.dt_begin_tstz DESC NULLS LAST) rn
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      JOIN schedule s
                        ON s.id_schedule = ei.id_schedule
                     WHERE e.id_patient = i_id_patient
                       AND e.id_episode != i_id_episode
                       AND s.dt_begin_tstz < current_timestamp
                       AND e.id_clinical_service = (SELECT e1.id_clinical_service
                                                      FROM episode e1
                                                     WHERE e1.id_episode = i_id_episode)) t
             WHERE t.rn = 1;
        
            --VERIFICA REQUISIES DE ANLISES
            l_rowids_1 := NULL;
        
            g_error := 'GET C_ANALYSIS';
            FOR v_analysis_req IN c_analysis_req(v_id_episode)
            LOOP
                g_error := 'UPDATE ANALYSIS_REQ';
                ts_analysis_req.upd(id_episode_in    => i_id_episode,
                                    id_visit_in      => l_visit,
                                    dt_begin_tstz_in => g_sysdate_tstz,
                                    where_in         => 'id_analysis_req = ' || v_analysis_req.id_analysis_req ||
                                                        ' AND flg_status != ''' || pk_alert_constant.g_flg_status_c || '''' ||
                                                        ' AND (id_episode_origin = ' || v_id_episode || ' OR ' ||
                                                        ' (id_episode_destination = ' || v_id_episode ||
                                                        ' AND id_episode IS NULL))',
                                    rows_out         => l_rowids_1);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'ANALYSIS_REQ',
                                              i_rowids     => l_rowids_1,
                                              o_error      => o_error);
            
                l_rowids_1 := NULL;
                l_rowids_2 := NULL;
                l_rowids_3 := NULL;
            
                FOR v_analysis_req_det IN c_analysis_req_det(v_analysis_req.id_analysis_req)
                LOOP
                    g_error := 'UPDATE ANALYSIS_REQ_DET';
                    ts_analysis_req_det.upd(id_episode_destination_in => i_id_episode,
                                            dt_target_tstz_in         => g_sysdate_tstz,
                                            where_in                  => 'id_analysis_req_det = ' ||
                                                                         v_analysis_req_det.id_analysis_req_det ||
                                                                         ' AND flg_status != ''' ||
                                                                         pk_alert_constant.g_flg_status_c || '''' ||
                                                                         ' AND (id_episode_origin = ' || v_id_episode ||
                                                                         ' OR ' || 'id_episode_destination = ' ||
                                                                         v_id_episode || ')',
                                            rows_out                  => l_rowids_2);
                
                    g_error := 'UPDATE HARVEST';
                    ts_harvest.upd(id_harvest_in       => v_analysis_req_det.id_harvest,
                                   dt_begin_harvest_in => g_sysdate_tstz,
                                   rows_out            => l_rowids_3);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => l_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rowids_3,
                                                  o_error      => o_error);
                
                    g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_STATUS';
                    IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                                   i_prof             => l_prof,
                                                                   i_analysis_req_det => table_number(v_analysis_req_det.id_analysis_req_det),
                                                                   i_status           => CASE v_analysis_req_det.flg_status
                                                                                             WHEN
                                                                                              pk_lab_tests_constant.g_analysis_draft THEN
                                                                                              pk_lab_tests_constant.g_analysis_draft
                                                                                             ELSE
                                                                                              pk_lab_tests_constant.g_analysis_req
                                                                                         END,
                                                                   o_error            => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
            
                g_error := 'UPDATE ANALYSIS_REQ';
                ts_analysis_req.upd(id_episode_destination_in  => i_id_episode,
                                    id_episode_destination_nin => FALSE,
                                    where_in                   => 'id_analysis_req = ' || v_analysis_req.id_analysis_req ||
                                                                  ' AND flg_status != ''' ||
                                                                  pk_alert_constant.g_flg_status_c || '''',
                                    rows_out                   => l_rowids_1);
            END LOOP;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'ANALYSIS_REQ_DET',
                                          i_rowids     => l_rowids_2,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'ANALYSIS_REQ',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
        
            l_rowids_1 := NULL;
            l_rowids_2 := NULL;
        
            --VERIFICA REQUISIES DE EXAMES
            g_error := 'GET C_EXAM';
            FOR v_exam_req IN c_exam_req(v_id_episode)
            LOOP
            
                ts_exam_req.upd(id_episode_in    => i_id_episode,
                                dt_begin_tstz_in => g_sysdate_tstz,
                                where_in         => 'id_exam_req = ' || v_exam_req.id_exam_req ||
                                                    ' AND flg_status != ''' || pk_alert_constant.g_flg_status_c || '''' ||
                                                    ' AND id_episode_origin = ' || v_id_episode,
                                rows_out         => l_rowids_1);
            
                g_error := 'UPDATE EXAM_REQ';
                ts_exam_req.upd(id_episode_destination_in => i_id_episode,
                                where_in                  => 'id_exam_req = ' || v_exam_req.id_exam_req ||
                                                             ' AND flg_status != ''' || pk_alert_constant.g_flg_status_c || '''',
                                
                                rows_out => l_rowids_1);
            
                FOR v_exam_req_det IN c_exam_req_det(v_exam_req.id_exam_req)
                LOOP
                    ts_exam_req_det.upd(id_exam_req_det_in => v_exam_req_det.id_exam_req_det,
                                        dt_target_tstz_in  => g_sysdate_tstz,
                                        rows_out           => l_rowids_2);
                
                    g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_STATUS';
                    IF NOT pk_exams_api_db.set_exam_status(i_lang            => i_lang,
                                                           i_prof            => l_prof,
                                                           i_exam_req_det    => table_number(v_exam_req_det.id_exam_req_det),
                                                           i_status          => CASE v_exam_req_det.flg_status
                                                                                    WHEN pk_exam_constant.g_exam_draft THEN
                                                                                     pk_exam_constant.g_exam_draft
                                                                                    ELSE
                                                                                     pk_exam_constant.g_exam_req
                                                                                END,
                                                           i_notes           => NULL,
                                                           i_notes_scheduler => NULL,
                                                           o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
            END LOOP;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'EXAM_REQ',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'EXAM_REQ_DET',
                                          i_rowids     => l_rowids_2,
                                          o_error      => o_error);
        
            --VERIFICA MARCAO DE INTERVENES
        
            l_rowids_1 := NULL;
            l_rowids_2 := NULL;
            l_rowids_3 := NULL;
        
            g_error := 'GET C_INTERV';
            FOR v_interv_prescription IN c_interv_prescription(v_id_episode)
            LOOP
                ts_interv_prescription.upd(id_episode_in    => i_id_episode,
                                           dt_begin_tstz_in => g_sysdate_tstz,
                                           where_in         => 'id_interv_prescription = ' ||
                                                               v_interv_prescription.id_interv_prescription ||
                                                               ' AND flg_status != ''' ||
                                                               pk_alert_constant.g_flg_status_c || '''' ||
                                                               ' AND id_episode_origin = ' || v_id_episode,
                                           rows_out         => l_rowids_1);
            
                g_error := 'UPDATE INTERV_PRESCRIPTION';
                ts_interv_prescription.upd(id_episode_destination_in => i_id_episode,
                                           where_in                  => 'id_interv_prescription = ' ||
                                                                        v_interv_prescription.id_interv_prescription ||
                                                                        ' AND flg_status != ''' ||
                                                                        pk_alert_constant.g_flg_status_c || '''',
                                           rows_out                  => l_rowids_1);
            
                g_error := 'UPDATE INTERV_PRESC_DET';
                ts_interv_presc_det.upd(id_interv_presc_det_in => v_interv_prescription.id_interv_presc_det,
                                        flg_status_in          => CASE v_interv_prescription.flg_status
                                                                      WHEN pk_procedures_constant.g_interv_draft THEN
                                                                       pk_procedures_constant.g_interv_draft
                                                                      ELSE
                                                                       pk_procedures_constant.g_interv_req
                                                                  END,
                                        rows_out               => l_rowids_2);
            
                g_error := 'UPDATE INTERV_PRESC_PLAN';
                ts_interv_presc_plan.upd(dt_plan_tstz_in => g_sysdate_tstz,
                                         flg_status_in   => pk_procedures_constant.g_interv_plan_req,
                                         where_in        => 'id_interv_presc_det = ' ||
                                                            v_interv_prescription.id_interv_presc_det,
                                         rows_out        => l_rowids_3);
            END LOOP;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'INTERV_PRESCRIPTION',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'INTERV_PRESC_DET',
                                          i_rowids     => l_rowids_2,
                                          o_error      => o_error);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'INTERV_PRESC_PLAN',
                                          i_rowids     => l_rowids_3,
                                          o_error      => o_error);
        
            --VERIFICA PRESCRIES DE MEDICAMENTOS
            --VERIFICA MARCAO DE INTERVENES
            g_error := 'CALL TO PK_API_TR_MED.CREATE_PRESC';
            IF NOT pk_visit.create_presc(i_lang            => i_lang,
                                         i_prof            => l_prof,
                                         i_id_episode      => i_id_episode,
                                         i_id_patient      => i_id_patient,
                                         i_id_clin_service => i_id_clin_service,
                                         o_error           => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            --VERIFICA MARCAO DE INTERVENCOES ICNP
            l_next_req := NULL;
        
            l_recurr_definit_ids_coll := table_number();
        
            g_error := 'GET C_ICNP_INTERV';
            FOR v_icnp_interv IN c_icnp_interv(v_id_episode)
            LOOP
                IF v_icnp_interv.id_order_recurr_plan IS NOT NULL
                THEN
                    -- Create a recurrence
                    IF NOT
                        pk_order_recurrence_api_db.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                               i_prof                   => l_prof,
                                                                               i_order_recurr_area      => pk_icnp_constant.g_order_recurr_area,
                                                                               i_order_recurr_plan_from => v_icnp_interv.id_order_recurr_plan,
                                                                               o_order_recurr_desc      => l_order_recurr_desc,
                                                                               o_order_recurr_option    => l_order_recurr_option,
                                                                               o_start_date             => l_start_date,
                                                                               o_occurrences            => l_occurrences,
                                                                               o_duration               => l_duration,
                                                                               o_unit_meas_duration     => l_unit_meas_duration,
                                                                               o_duration_desc          => l_duration_desc,
                                                                               o_end_date               => l_end_date,
                                                                               o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                               o_order_recurr_plan      => l_order_recurr_plan,
                                                                               o_error                  => o_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.copy_from_order_recurr_plan',
                                                            o_error);
                    END IF;
                
                    -- Set a temporary order recurrence plan as definitive (final status)
                    IF NOT pk_order_recurrence_api_db.set_order_recurr_plan(i_lang                    => i_lang,
                                                                            i_prof                    => l_prof,
                                                                            i_order_recurr_plan       => l_order_recurr_plan,
                                                                            o_order_recurr_option     => l_order_recurr_option_id,
                                                                            o_final_order_recurr_plan => l_order_recurr_final_id,
                                                                            o_error                   => o_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_order_recurr_plan',
                                                            o_error);
                    END IF;
                
                    l_recurr_definit_ids_coll := table_number();
                
                    IF l_order_recurr_final_id IS NOT NULL
                    THEN
                        l_recurr_definit_ids_coll.extend;
                        l_recurr_definit_ids_coll(l_recurr_definit_ids_coll.count) := l_order_recurr_final_id;
                    END IF;
                
                    IF NOT pk_order_recurrence_api_db.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                                i_prof            => l_prof,
                                                                                i_order_plan      => l_recurr_definit_ids_coll,
                                                                                o_order_plan_exec => l_order_plan_exec,
                                                                                o_error           => o_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.prepare_order_recurr_plan',
                                                            o_error);
                    END IF;
                
                    IF l_order_plan_exec IS NOT empty
                    THEN
                        -- for each req and each execution
                        -- create executions
                        l_next_req                       := ts_icnp_epis_intervention.next_key('SEQ_ICNP_EPIS_INTERVENTION');
                        l_iei.id_icnp_epis_interv        := l_next_req;
                        l_iei.dt_icnp_epis_interv_tstz   := g_sysdate_tstz;
                        l_iei.id_patient                 := v_icnp_interv.id_patient;
                        l_iei.id_episode                 := i_id_episode;
                        l_iei.id_composition             := v_icnp_interv.id_composition;
                        l_iei.flg_status                 := v_icnp_interv.flg_status;
                        l_iei.notes                      := v_icnp_interv.notes;
                        l_iei.dt_begin_tstz              := v_icnp_interv.dt_begin_tstz;
                        l_iei.dt_end_tstz                := v_icnp_interv.dt_end_tstz;
                        l_iei.id_prof                    := v_icnp_interv.id_prof;
                        l_iei.flg_time                   := g_flg_time_e;
                        l_iei.flg_type                   := v_icnp_interv.flg_type;
                        l_iei.id_episode_origin          := v_icnp_interv.id_episode;
                        l_iei.id_order_recurr_plan       := l_order_plan_exec(1).id_order_recurrence_plan;
                        l_iei.flg_prn                    := v_icnp_interv.flg_prn;
                        l_iei.prn_notes                  := v_icnp_interv.prn_notes;
                        l_iei.id_icnp_epis_interv_parent := v_icnp_interv.id_icnp_epis_interv;
                    
                        g_error := 'INSERT INTO ICNP_EPIS_INTERVENTION';
                        ts_icnp_epis_intervention.ins(rec_in => l_iei, rows_out => l_iei_rowids);
                    
                        l_iei_rowids_ins := l_iei_rowids_ins MULTISET UNION l_iei_rowids;
                    
                        -- Actualizar os ids das requisies nas Guidelines
                        UPDATE guideline_process_task gpt
                           SET gpt.id_request = l_next_req, gpt.dt_request = current_timestamp
                         WHERE gpt.flg_status_last IN
                               (pk_guidelines.g_process_scheduled, pk_guidelines.g_process_running)
                           AND gpt.task_type = pk_guidelines.g_task_enfint
                           AND gpt.id_request = v_icnp_interv.id_icnp_epis_interv;
                    
                        -- Actualizar os ids das requisies nos Protocolos
                        UPDATE protocol_process_element ppe
                           SET ppe.id_request = l_next_req, ppe.dt_request = current_timestamp
                         WHERE ppe.flg_status IN (pk_protocol.g_process_scheduled, pk_protocol.g_process_running)
                           AND ppe.element_type = pk_protocol.g_element_task
                           AND ppe.id_protocol_task IN
                               (SELECT pt.id_protocol_task
                                  FROM protocol_task pt
                                 WHERE pt.task_type = pk_protocol.g_task_enfint)
                           AND ppe.id_request = v_icnp_interv.id_icnp_epis_interv;
                    
                        IF v_icnp_interv.flg_type != g_flg_sos
                        THEN
                            <<req>>
                            FOR req_idx IN 1 .. l_order_plan_exec.count
                            LOOP
                                -- Persist the data into the database and brodcast the update through the data
                                -- governace mechanism
                                ts_icnp_interv_plan.ins(id_icnp_interv_plan_in   => ts_icnp_interv_plan.next_key,
                                                        id_icnp_epis_interv_in   => l_next_req,
                                                        flg_status_in            => pk_icnp_constant.g_interv_plan_status_requested,
                                                        dt_plan_tstz_in          => l_order_plan_exec(req_idx).exec_timestamp,
                                                        id_prof_created_in       => i_prof.id,
                                                        dt_created_in            => g_sysdate_tstz,
                                                        dt_last_update_in        => g_sysdate_tstz,
                                                        id_epis_documentation_in => v_icnp_interv.id_epis_documentation,
                                                        notes_in                 => v_icnp_interv.notes_plan,
                                                        exec_number_in           => l_order_plan_exec(req_idx).exec_number,
                                                        rows_out                 => l_exec_rowids_coll);
                                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                              i_prof       => l_prof,
                                                              i_table_name => 'ICNP_INTERV_PLAN',
                                                              i_rowids     => l_exec_rowids_coll,
                                                              o_error      => o_error);
                            END LOOP req;
                        END IF;
                    
                        ts_icnp_epis_intervention.upd(id_episode_destination_in => i_id_episode,
                                                      where_in                  => 'id_icnp_epis_interv = ' ||
                                                                                   v_icnp_interv.id_icnp_epis_interv ||
                                                                                   ' AND id_episode_destination IS NULL',
                                                      rows_out                  => l_iei_rowids_upd);
                        IF v_icnp_interv.id_icnp_epis_diag IS NOT NULL
                        THEN
                            g_error := 'INSERT INTO ICNP_EPIS_DIAG_INTERV';
                            INSERT INTO icnp_epis_diag_interv
                                (id_icnp_epis_diag_interv, id_icnp_epis_diag, id_icnp_epis_interv)
                            VALUES
                                (seq_icnp_epis_diag_interv.nextval, v_icnp_interv.id_icnp_epis_diag, l_next_req);
                        END IF;
                    
                        SELECT isi.*
                          BULK COLLECT
                          INTO l_sug
                          FROM icnp_suggest_interv isi
                         WHERE isi.id_icnp_epis_interv = v_icnp_interv.id_icnp_epis_interv;
                    
                        IF l_sug.count > 0
                        THEN
                            FOR f IN 1 .. l_sug.count
                            LOOP
                                ts_icnp_suggest_interv.ins(id_icnp_sug_interv_in  => ts_icnp_suggest_interv.next_key,
                                                           id_req_in              => l_sug(f).id_req,
                                                           id_task_in             => l_sug(f).id_task,
                                                           id_task_type_in        => l_sug(f).id_task_type,
                                                           id_composition_in      => l_sug(f).id_composition,
                                                           id_patient_in          => l_sug(f).id_patient,
                                                           id_episode_in          => l_sug(f).id_episode,
                                                           flg_status_in          => l_sug(f).flg_status,
                                                           id_prof_last_update_in => l_sug(f).id_prof_last_update,
                                                           dt_last_update_in      => l_sug(f).dt_last_update,
                                                           id_icnp_epis_interv_in => v_icnp_interv.id_icnp_epis_interv,
                                                           flg_status_rel_in      => l_sug(f).flg_status_rel);
                            END LOOP;
                        END IF;
                    END IF;
                ELSE
                    -- for each req and each execution
                    -- create executions
                    l_next_req                       := ts_icnp_epis_intervention.next_key('SEQ_ICNP_EPIS_INTERVENTION');
                    l_iei.id_icnp_epis_interv        := l_next_req;
                    l_iei.dt_icnp_epis_interv_tstz   := g_sysdate_tstz;
                    l_iei.id_patient                 := v_icnp_interv.id_patient;
                    l_iei.id_episode                 := i_id_episode;
                    l_iei.id_composition             := v_icnp_interv.id_composition;
                    l_iei.flg_status                 := v_icnp_interv.flg_status;
                    l_iei.notes                      := v_icnp_interv.notes;
                    l_iei.dt_begin_tstz              := v_icnp_interv.dt_begin_tstz;
                    l_iei.dt_end_tstz                := v_icnp_interv.dt_end_tstz;
                    l_iei.id_prof                    := v_icnp_interv.id_prof;
                    l_iei.flg_time                   := g_flg_time_e;
                    l_iei.flg_type                   := v_icnp_interv.flg_type;
                    l_iei.id_episode_origin          := v_icnp_interv.id_episode;
                    l_iei.flg_prn                    := v_icnp_interv.flg_prn;
                    l_iei.prn_notes                  := v_icnp_interv.prn_notes;
                    l_iei.id_icnp_epis_interv_parent := v_icnp_interv.id_icnp_epis_interv;
                
                    g_error := 'INSERT INTO ICNP_EPIS_INTERVENTION';
                    ts_icnp_epis_intervention.ins(rec_in => l_iei, rows_out => l_iei_rowids);
                
                    l_iei_rowids_ins := l_iei_rowids_ins MULTISET UNION l_iei_rowids;
                
                    -- Actualizar os ids das requisies nas Guidelines
                    UPDATE guideline_process_task gpt
                       SET gpt.id_request = l_next_req, gpt.dt_request = current_timestamp
                     WHERE gpt.flg_status_last IN (pk_guidelines.g_process_scheduled, pk_guidelines.g_process_running)
                       AND gpt.task_type = pk_guidelines.g_task_enfint
                       AND gpt.id_request = v_icnp_interv.id_icnp_epis_interv;
                
                    -- Actualizar os ids das requisies nos Protocolos
                    UPDATE protocol_process_element ppe
                       SET ppe.id_request = l_next_req, ppe.dt_request = current_timestamp
                     WHERE ppe.flg_status IN (pk_protocol.g_process_scheduled, pk_protocol.g_process_running)
                       AND ppe.element_type = pk_protocol.g_element_task
                       AND ppe.id_protocol_task IN
                           (SELECT pt.id_protocol_task
                              FROM protocol_task pt
                             WHERE pt.task_type = pk_protocol.g_task_enfint)
                       AND ppe.id_request = v_icnp_interv.id_icnp_epis_interv;
                
                    IF v_icnp_interv.flg_prn != pk_alert_constant.g_yes
                       AND v_icnp_interv.flg_type != pk_icnp_constant.g_epis_interv_type_no_schedule
                    THEN
                        l_iip.id_icnp_interv_plan   := ts_icnp_interv_plan.next_key('SEQ_ICNP_INTERV_PLAN');
                        l_iip.id_icnp_epis_interv   := l_next_req;
                        l_iip.dt_plan_tstz          := v_icnp_interv.dt_plan_tstz;
                        l_iip.flg_status            := g_flg_status_r;
                        l_iip.notes                 := v_icnp_interv.notes_plan;
                        l_iip.id_epis_documentation := v_icnp_interv.id_epis_documentation;
                    
                        g_error := 'INSERT INTO ICNP_INTERV_PLAN';
                        ts_icnp_interv_plan.ins(rec_in => l_iip, rows_out => l_iip_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => l_prof,
                                                      i_table_name => 'ICNP_INTERV_PLAN',
                                                      i_rowids     => l_iip_rowids,
                                                      o_error      => o_error);
                    END IF;
                
                    ts_icnp_epis_intervention.upd(id_episode_destination_in => i_id_episode,
                                                  where_in                  => 'id_icnp_epis_interv = ' ||
                                                                               v_icnp_interv.id_icnp_epis_interv ||
                                                                               ' AND id_episode_destination IS NULL',
                                                  rows_out                  => l_iei_rowids_upd);
                
                    IF v_icnp_interv.id_icnp_epis_diag IS NOT NULL
                    THEN
                        g_error := 'INSERT INTO ICNP_EPIS_DIAG_INTERV';
                        INSERT INTO icnp_epis_diag_interv
                            (id_icnp_epis_diag_interv, id_icnp_epis_diag, id_icnp_epis_interv)
                        VALUES
                            (seq_icnp_epis_diag_interv.nextval, v_icnp_interv.id_icnp_epis_diag, l_next_req);
                    END IF;
                
                    SELECT isi.*
                      BULK COLLECT
                      INTO l_sug
                      FROM icnp_suggest_interv isi
                     WHERE isi.id_icnp_epis_interv = v_icnp_interv.id_icnp_epis_interv;
                
                    IF l_sug.count > 0
                    THEN
                        FOR f IN 1 .. l_sug.count
                        LOOP
                            ts_icnp_suggest_interv.ins(id_icnp_sug_interv_in  => ts_icnp_suggest_interv.next_key,
                                                       id_req_in              => l_sug(f).id_req,
                                                       id_task_in             => l_sug(f).id_task,
                                                       id_task_type_in        => l_sug(f).id_task_type,
                                                       id_composition_in      => l_sug(f).id_composition,
                                                       id_patient_in          => l_sug(f).id_patient,
                                                       id_episode_in          => l_sug(f).id_episode,
                                                       flg_status_in          => l_sug(f).flg_status,
                                                       id_prof_last_update_in => l_sug(f).id_prof_last_update,
                                                       dt_last_update_in      => l_sug(f).dt_last_update,
                                                       id_icnp_epis_interv_in => v_icnp_interv.id_icnp_epis_interv,
                                                       flg_status_rel_in      => l_sug(f).flg_status_rel);
                        END LOOP;
                    END IF;
                END IF;
            END LOOP;
        
            IF l_iei_rowids_ins IS NOT empty
            THEN
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_INSERT - ICNP_EPIS_INTERVENTION';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'ICNP_EPIS_INTERVENTION',
                                              i_rowids     => l_iei_rowids_ins,
                                              o_error      => o_error);
            END IF;
        
            IF l_iei_rowids_upd IS NOT empty
            THEN
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - ICNP_EPIS_INTERVENTION';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => l_prof,
                                              i_table_name => 'ICNP_EPIS_INTERVENTION',
                                              i_rowids     => l_iei_rowids_upd,
                                              o_error      => o_error);
            END IF;
        
            --VERIFICA MARCAO DE LEITURAS
            g_error      := 'GET C_MONIT';
            l_next_req   := NULL;
            l_rowids_aux := table_varchar();
        
            FOR v_monitorization IN c_monit(v_id_episode)
            LOOP
                --Valida se a monitorizao  a mesma, para apenas inserir os mesmos reqs que no episdio original
                IF l_prev_monit != v_monitorization.mon_id_monitorization
                THEN
                    l_prev_monit := v_monitorization.mon_id_monitorization;
                
                    g_error := 'INSERT INTO MONITORIZATION';
                    ts_monitorization.ins(id_monitorization_out     => l_next_req,
                                          dt_monitorization_tstz_in => v_monitorization.dt_monitorization_tstz,
                                          id_episode_in             => i_id_episode,
                                          id_professional_in        => v_monitorization.id_professional,
                                          notes_in                  => v_monitorization.notes,
                                          dt_begin_tstz_in          => v_monitorization.dt_begin_tstz,
                                          flg_time_in               => g_flg_time_e,
                                          dt_end_tstz_in            => v_monitorization.dt_end_tstz,
                                          interval_in               => v_monitorization.interval,
                                          flg_status_in             => v_monitorization.flg_status,
                                          id_episode_origin_in      => v_monitorization.id_episode,
                                          id_patient_in             => v_monitorization.id_patient,
                                          rows_out                  => l_rowsid);
                
                    g_error := 'CALL t_data_gov_mnt.process_insert';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => l_prof,
                                                  i_table_name => 'MONITORIZATION',
                                                  i_rowids     => l_rowsid,
                                                  o_error      => o_error);
                
                    -- Actualizar os ids das requisies nos Order Sets                
                    UPDATE order_set_process_task ospt
                       SET ospt.id_request = l_next_req
                     WHERE ospt.id_task_type = pk_order_sets.g_odst_task_monitoring
                       AND ospt.flg_status = pk_order_sets.g_order_set_proc_tsk_running
                       AND ospt.id_request = v_monitorization.id_monitorization;
                END IF;
            
                FOR v_monitorization_vs IN c_monit_vs(v_monitorization.id_monitorization)
                LOOP
                    g_error := 'INSERT INTO MONITORIZATION_VS';
                    ts_monitorization_vs.ins(id_monitorization_vs_out     => l_next_mvs,
                                             id_monitorization_in         => l_next_req,
                                             id_vital_sign_in             => v_monitorization_vs.id_vital_sign,
                                             notes_in                     => v_monitorization_vs.notes_det,
                                             flg_status_in                => v_monitorization_vs.flg_status_det,
                                             dt_monitorization_vs_tstz_in => v_monitorization_vs.dt_monitorization_vs_tstz,
                                             dt_order_in                  => v_monitorization_vs.dt_order,
                                             id_prof_order_in             => v_monitorization_vs.id_prof_order,
                                             id_order_type_in             => v_monitorization_vs.id_order_type,
                                             rows_out                     => l_rowids_aux);
                
                    l_rowids_mvs := l_rowids_mvs MULTISET UNION DISTINCT l_rowids_aux;
                
                    FOR v_monitorization_vsp IN c_monit_vsp(v_monitorization_vs.id_monitorization_vs)
                    LOOP
                        g_error := 'INSERT INTO MONITORIZATION_VS_PLAN';
                        ts_monitorization_vs_plan.ins(id_monitorization_vs_plan_out => l_next_mvsp,
                                                      id_monitorization_vs_in       => l_next_mvs,
                                                      dt_plan_tstz_in               => v_monitorization_vsp.dt_plan_tstz,
                                                      flg_status_in                 => v_monitorization_vsp.stat,
                                                      rows_out                      => l_rowsid_plan);
                    END LOOP;
                
                    g_error := 'CALL t_data_gov_mnt.process_insert';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => l_prof,
                                                  i_table_name => 'MONITORIZATION_VS_PLAN',
                                                  i_rowids     => l_rowsid_plan,
                                                  o_error      => o_error);
                END LOOP;
            
                g_error := 'UPDATE MONITORIZATION';
                ts_monitorization.upd(id_episode_destination_in => i_id_episode,
                                      where_in                  => 'id_monitorization = ' ||
                                                                   v_monitorization.id_monitorization ||
                                                                   ' AND id_episode_destination IS NULL',
                                      rows_out                  => l_rowsid_m);
            END LOOP;
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'MONITORIZATION',
                                          i_rowids     => l_rowsid_m,
                                          o_error      => o_error);
        
            -- Alert Data Governance
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'MONITORIZATION_VS',
                                          i_rowids     => l_rowids_mvs,
                                          o_error      => o_error);
        
            --VERIFICA REQUISIES DE PROCESSOS CLNICOS
            g_error    := 'GET C_CLI_REC_REQ';
            l_next_req := NULL;
        
            FOR v_cli_rec IN c_cli_rec_req(v_id_episode)
            LOOP
                SELECT seq_cli_rec_req.nextval
                  INTO l_next_req
                  FROM dual;
            
                g_error := 'INSERT INTO CLI_REC_REQ';
                INSERT INTO cli_rec_req
                    (id_cli_rec_req,
                     dt_cli_rec_req_tstz,
                     id_prof_req,
                     id_episode,
                     flg_status,
                     notes,
                     flg_time,
                     dt_begin_tstz,
                     id_schedule,
                     id_episode_origin)
                VALUES
                    (l_next_req,
                     v_cli_rec.dt_cli_rec_req_tstz,
                     v_cli_rec.id_prof_req,
                     i_id_episode,
                     v_cli_rec.flg_status,
                     v_cli_rec.notes,
                     g_flg_time_e,
                     v_cli_rec.dt_begin_tstz,
                     v_cli_rec.id_schedule,
                     v_cli_rec.id_episode);
            
                g_error := 'INSERT CLI_REC_REQ_DET';
                FOR v_cli_rec_det IN c_cli_rec_req_det(v_cli_rec.id_cli_rec_req)
                LOOP
                    INSERT INTO cli_rec_req_det
                        (id_cli_rec_req_det, id_cli_rec_req, flg_status, id_clin_record)
                    VALUES
                        (seq_cli_rec_req_det.nextval,
                         l_next_req,
                         v_cli_rec_det.flg_status_det,
                         v_cli_rec_det.id_clin_record);
                END LOOP;
            
                g_error := 'UPDATE CLI_REC_REQ';
                UPDATE cli_rec_req
                   SET id_episode_destination = i_id_episode
                 WHERE id_cli_rec_req = v_cli_rec.id_cli_rec_req
                   AND id_episode_destination IS NULL;
            END LOOP;
        
            g_error := 'CALL TO PK_SYSCONFIG.GET_CONFIG(end)';
            IF NOT pk_sysconfig.get_config('ID_CLIN_SERV_ANATOMY', i_prof, l_clin_serv)
            THEN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                           'PK_VISIT.CREATE_EXAM_REQ_PRESC / ' || g_error;
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            FOR v_vacc IN c_vacc(v_id_episode)
            LOOP
                SELECT seq_pat_vacc_adm.nextval
                  INTO l_next_req
                  FROM dual;
            
                g_error := 'GET VISIT';
                l_visit := pk_visit.get_visit(i_id_episode, o_error);
            
                IF o_error IS NOT NULL
                THEN
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                g_error := 'INSERT INTO PAT_VACC_ADM';
                INSERT INTO pat_vacc_adm
                    (id_pat_vacc_adm,
                     id_episode,
                     dt_pat_vacc_adm,
                     id_prof_writes,
                     id_vacc,
                     id_patient,
                     flg_status,
                     flg_time,
                     takes,
                     dosage,
                     flg_orig,
                     dt_presc,
                     prof_presc,
                     id_episode_origin)
                VALUES
                    (l_next_req,
                     i_id_episode,
                     v_vacc.dt_pat_vacc_adm,
                     v_vacc.id_prof_writes,
                     v_vacc.id_vacc,
                     i_id_patient,
                     v_vacc.flg_status,
                     g_flg_time_e,
                     v_vacc.takes,
                     v_vacc.dosage,
                     v_vacc.flg_orig,
                     v_vacc.dt_presc,
                     v_vacc.prof_presc,
                     v_vacc.id_episode);
            
                g_error := 'INSERT INTO PAT_VACC_ADM_DET';
                FOR v_vacc_det IN c_vacc_det(v_id_episode, v_vacc.id_pat_vacc_adm)
                LOOP
                    INSERT INTO pat_vacc_adm_det
                        (id_pat_vacc_adm_det,
                         id_pat_vacc_adm,
                         dt_take,
                         id_drug_presc_plan,
                         id_episode,
                         flg_status,
                         desc_vaccine,
                         lot_number,
                         dt_expiration,
                         flg_advers_react,
                         notes_advers_react,
                         application_spot,
                         report_orig,
                         notes,
                         emb_id,
                         id_unit_measure,
                         id_prof_writes)
                    VALUES
                        (seq_pat_vacc_adm_det.nextval,
                         l_next_req,
                         v_vacc_det.dt_taked,
                         v_vacc_det.id_drug_presc_pland,
                         i_id_episode,
                         v_vacc_det.flg_statusd,
                         v_vacc_det.desc_vaccined,
                         v_vacc_det.lot_numberd,
                         v_vacc_det.dt_expirationd,
                         v_vacc_det.flg_advers_reactd,
                         v_vacc_det.notes_advers_reactd,
                         v_vacc_det.application_spotd,
                         v_vacc_det.report_origd,
                         v_vacc_det.notesd,
                         v_vacc_det.emb_idd,
                         v_vacc_det.id_unit_measured,
                         v_vacc_det.id_prof_writesd);
                END LOOP;
            
                g_error := 'UPDATE PAT_VACC_ADM';
                UPDATE pat_vacc_adm
                   SET id_episode_destination = i_id_episode
                 WHERE id_pat_vacc_adm = v_vacc.id_pat_vacc_adm
                   AND id_episode_destination IS NULL;
            END LOOP;
        
            IF pk_sysconfig.get_config('EXAMS_WORKFLOW', l_prof) = pk_alert_constant.g_yes
            THEN
                g_error := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
                IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                          i_prof         => l_prof,
                                                          i_patient      => i_id_patient,
                                                          i_episode      => i_id_episode,
                                                          i_exam_req     => l_next_req,
                                                          i_exam_req_det => l_exam_next_req_det,
                                                          o_error        => o_error)
                THEN
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'CALL TO PK_GRID.INSERT_CLIN_REC_REQ_TASK';
            IF NOT pk_clinical_record.insert_clin_rec_req_task(i_lang          => i_lang,
                                                               i_episode       => i_id_episode,
                                                               i_prof          => l_prof,
                                                               i_prof_cat_type => NULL,
                                                               o_error         => o_error)
            THEN
                RAISE g_exception_ext;
            END IF;
        
            IF NOT pk_procedures_external_api_db.set_grid_task_procedures(i_lang    => i_lang,
                                                                          i_prof    => l_prof,
                                                                          i_episode => i_id_episode,
                                                                          o_error   => o_error)
            THEN
                RAISE g_exception_ext;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EXAM_REQ_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_exam_req_presc;

    /********************************************************************************************
    * CREATE_PRESC
    *
    * @param i_lang                language id
    * @param i_prof                professional id
    * @param i_id_episode          episode identifier
    * @param i_id_patient          patient identifier
    * @param i_id_clin_service     dep_clin_serv identifier
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luis Maia
    * @version                     2.6.1.1
    * @since                       2011/04/20
    * @dependents                  PK_VISIT.CREATE_EXAM_REQ_PRESC
    **********************************************************************************************/
    FUNCTION create_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN epis_info.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_clin_service IN episode.id_clinical_service%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        v_id_episode episode.id_episode%TYPE;
        v_found      BOOLEAN;
    
        e_process_event EXCEPTION;
        g_exception_ext EXCEPTION;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_epis IS --PROCURA ULTIMO EPISODIO DA MESMA ESPECIALIDADE DE UM PACIENTE
            SELECT id_episode
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND e.id_episode != i_id_episode
               AND e.id_clinical_service = i_id_clin_service
               AND e.dt_begin_tstz = (SELECT MAX(e1.dt_begin_tstz)
                                        FROM episode e1
                                       WHERE e1.id_patient = e.id_patient
                                         AND e1.id_episode != i_id_episode
                                         AND e1.id_clinical_service = e.id_clinical_service);
    
        l_list_id_presc table_number := table_number();
        l_copy_id_presc table_number := table_number();
        l_id_presc      pk_api_pfh_in.r_presc.id_presc%TYPE;
        l_exception EXCEPTION;
    
    BEGIN
        --VERIFICA QUAL O ULTIMO ID DE EPISODIO PARA ESTE PACIENTE/ESPECIALIDADE
        g_error := 'GET LAST EPISODE ID';
        OPEN c_epis;
        FETCH c_epis
            INTO v_id_episode;
        v_found := c_epis%FOUND;
        CLOSE c_epis;
    
        IF v_found
        THEN
            -------------------------------------------------------------------------
            -- obtem a lista de prescricoes do ultimo episodio da mesma especialidade
            IF NOT pk_api_pfh_in.get_next_epis_presc(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_id_patient => i_id_patient,
                                                     i_id_episode => v_id_episode,
                                                     o_id_presc   => l_list_id_presc,
                                                     o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -------------------------------------------------------------------------
            -- loop for each found presc
            IF l_list_id_presc.count != 0
            THEN
                FOR i IN 1 .. l_list_id_presc.last
                LOOP
                    -- copy presc and associate it to the new episode
                    IF NOT pk_api_pfh_in.copy_presc(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_presc      => l_list_id_presc(i),
                                                    i_id_patient    => i_id_patient,
                                                    i_id_episode    => i_id_episode, -- new episode
                                                    i_flg_confirm   => pk_alert_constant.g_yes,
                                                    i_flg_execution => pk_api_pfh_in.g_flg_exec_curr_episode,
                                                    o_id_presc      => l_id_presc,
                                                    o_error         => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- ckeck copied presc exists
                    IF l_id_presc IS NULL
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- call pk_rt_med_pfh.set_presc_co_sign function
                    IF NOT pk_rt_med_pfh.set_presc_co_sign(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_presc      => l_id_presc,
                                                           i_prof_co_sign  => i_prof.id,
                                                           i_order_type    => 6, -- other
                                                           i_dt_co_sign    => current_timestamp,
                                                           i_co_sign_notes => NULL,
                                                           o_error         => o_error)
                    THEN
                        g_error := 'error found while calling pk_rt_med_pfh.set_presc_co_sign function';
                        RAISE g_exception_ext;
                    END IF;
                
                    -- Actualizar os ids das requisicoes nos Care Plans
                    UPDATE care_plan_task_req
                       SET id_req = l_id_presc
                     WHERE id_req = l_list_id_presc(i)
                       AND id_task_type = (SELECT id_task_type
                                             FROM task_type
                                            WHERE flg_type = 'ML');
                
                    -- Actualizar os ids das requisicoes nas Guidelines
                    UPDATE guideline_process_task gpt
                       SET gpt.id_request = l_id_presc
                     WHERE gpt.flg_status_last IN (pk_guidelines.g_process_scheduled, pk_guidelines.g_process_running)
                       AND gpt.task_type = pk_guidelines.g_task_drug
                       AND gpt.id_request = l_list_id_presc(i);
                
                    -- Actualizar os ids das requisicoes nos Protocolos
                    UPDATE protocol_process_element ppe
                       SET ppe.id_request = l_id_presc
                     WHERE ppe.flg_status IN (pk_protocol.g_process_scheduled, pk_protocol.g_process_running)
                       AND ppe.element_type = pk_protocol.g_element_task
                       AND ppe.id_protocol_task IN
                           (SELECT pt.id_protocol_task
                              FROM protocol_task pt
                             WHERE pt.task_type = pk_protocol.g_task_drug)
                       AND ppe.id_request = l_list_id_presc(i);
                
                    -- Actualizar os ids das requisicoes nos Order Sets
                    UPDATE order_set_process_task ospt
                       SET ospt.id_request = l_id_presc
                     WHERE ospt.id_task_type = pk_order_sets.g_odst_task_local_drug
                       AND ospt.flg_status = pk_order_sets.g_order_set_proc_tsk_running
                       AND ospt.id_request = l_list_id_presc(i);
                
                -- TODO: actualizar campo id_episode_destination das prescricoes actualizadas
                -- campo ainda nao existe, validar se e necessario
                -- ts_drug_prescription.upd(id_episode_destination_in  => i_id_episode,
                --                          id_episode_destination_nin => FALSE,
                --                          where_in                   => 'id_drug_prescription = ' ||
                --                                                        v_drug_prescription.id_drug_prescription ||
                --                                                        ' AND id_episode_destination IS NULL',
                --                          rows_out                   => l_rowids_aux);
                END LOOP;
            END IF;
        
            -- update GRID TASK for the specified episode
            g_error := 'CALL TO pk_api_pfh_in.process_epis_grid_task';
            pk_api_pfh_in.process_epis_grid_task(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PRESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_presc;

    --
    /**********************************************************************************************
    * Gets the dep_clin_serv to be used in the episode
    *
    * @param i_lang                   the id language
    * @param i_id_professional        professional, software and institution ids
    * @param o_department             Service ID
    * @param o_dept                   department ID
    * @param o_clinical_service       Specialty ID
    * @param o_id_dep_clin_serv       dep_clin_serv ID
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jose Silva
    * @version                        1.0
    * @since                          2009/09/23
    **********************************************************************************************/
    FUNCTION get_epis_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_professional  IN profissional,
        o_department       OUT department.id_department%TYPE,
        o_dept             OUT dept.id_dept%TYPE,
        o_clinical_service OUT dep_clin_serv.id_clinical_service%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_department       department.id_department%TYPE;
        l_dept             dept.id_dept%TYPE;
        l_clinical_service dep_clin_serv.id_clinical_service%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_cur_software_edis   software.id_software%TYPE;
        l_cur_software_inp    software.id_software%TYPE;
        l_cur_software_triage software.id_software%TYPE;
        l_cur_software_ubu    software.id_software%TYPE;
    
        -- Inpatient
        CURSOR c_dep_clin_serv IS
            SELECT dcs.id_clinical_service, dcs.id_department, dcs.id_dep_clin_serv, dpt.id_dept
              FROM dep_clin_serv dcs, software_dept sdt, department dpt, prof_dep_clin_serv pdcs
             WHERE pdcs.flg_default = g_flg_default -- Servio clinico por defeito para o profissional
               AND dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
               AND dcs.id_department = dpt.id_department
               AND dpt.id_dept = sdt.id_dept
               AND instr(dpt.flg_type, 'I') > 0
               AND sdt.id_software = i_id_professional.software
               AND pdcs.flg_status = g_selected
               AND pdcs.id_professional = i_id_professional.id
               AND i_id_professional.software =
                   pk_episode.get_soft_by_epis_type(g_epis_type_inp, i_id_professional.institution)
                  -- LMAIA 22-10-2009
                  -- Guarantee institution filter
               AND dpt.id_institution = i_id_professional.institution
               AND pdcs.id_institution = i_id_professional.institution
             ORDER BY dcs.id_department;
    
        -- Jos Brito 29/04/2008 Necessrio para preencher EPIS_INFO.ID_DEP_CLIN_SERV
        -- na criao de episdios temporrios no EDIS
        CURSOR c_dep_clin_serv_edis IS
            SELECT dcs.id_clinical_service, dcs.id_department, dcs.id_dep_clin_serv, dpt.id_dept
              FROM dep_clin_serv dcs, software_dept sdt, department dpt, prof_dep_clin_serv pdcs
             WHERE dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
               AND dcs.id_department = dpt.id_department
               AND dpt.id_dept = sdt.id_dept
               AND instr(dpt.flg_type, 'U') > 0
               AND sdt.id_software = i_id_professional.software
               AND pdcs.flg_status = g_selected
               AND pdcs.id_professional = i_id_professional.id
                  -- Jos Brito 14/07/2008 Usar o servio clnico preferencial ao criar o episdio temporrio
               AND dpt.id_institution = i_id_professional.institution
               AND pdcs.flg_default = g_flg_default
             ORDER BY dcs.flg_default;
    BEGIN
    
        l_cur_software_edis   := pk_alert_constant.g_soft_edis;
        l_cur_software_inp    := pk_alert_constant.g_soft_inpatient;
        l_cur_software_triage := pk_alert_constant.g_soft_triage;
        l_cur_software_ubu    := pk_alert_constant.g_soft_ubu;
    
        IF i_id_professional.software IN (l_cur_software_edis, l_cur_software_triage, l_cur_software_ubu)
        THEN
            -- Jos Brito 29/04/2008 Necessrio para preencher EPIS_INFO.ID_DEP_CLIN_SERV
            -- na criao de episdios temporrios no EDIS
            g_error := 'OPEN C_DEP_CLIN_SERV_EDIS';
            OPEN c_dep_clin_serv_edis;
            FETCH c_dep_clin_serv_edis
                INTO l_clinical_service, l_department, l_id_dep_clin_serv, l_dept;
            CLOSE c_dep_clin_serv_edis;
        
        ELSIF i_id_professional.software = l_cur_software_inp
        THEN
            g_error := 'OPEN C_DEP_CLIN_SERV';
            OPEN c_dep_clin_serv;
            FETCH c_dep_clin_serv
                INTO l_clinical_service, l_department, l_id_dep_clin_serv, l_dept;
            CLOSE c_dep_clin_serv;
        END IF;
    
        o_department       := l_department;
        o_dept             := l_dept;
        o_clinical_service := l_clinical_service;
        o_id_dep_clin_serv := l_id_dep_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'GET_EPIS_DEP_CLIN_SERV',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_dep_clin_serv;
    --
    /**********************************************************************************************
    * Criar um episdio temporrio.
       necessrio criar uma nova visita pois no se sabe qual  o paciente.
    *
    * @param i_lang                   the id language
    * @param i_id_professional        professional, software and institution ids
    * @param o_episode                episode temporary id
    * @param o_patient                ID do paciente temporrio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Silvia Freitas
    * @version                        1.0
    * @since                          2006/07/25
    **********************************************************************************************/
    FUNCTION create_episode_temp
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN profissional,
        o_episode         OUT NUMBER,
        o_patient         OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_visit            NUMBER;
        l_next_epis_inst        NUMBER;
        l_next_epis_ext_sys     NUMBER;
        l_epis_type             NUMBER;
        l_room                  epis_type_room.id_room%TYPE;
        l_department            department.id_department%TYPE;
        l_dept                  dept.id_dept%TYPE;
        l_clinical_service      dep_clin_serv.id_clinical_service%TYPE;
        l_id_dep_clin_serv      dep_clin_serv.id_dep_clin_serv%TYPE;
        l_barcode               VARCHAR2(30);
        l_rank                  NUMBER;
        l_pat_dmgr_hist_row     pat_dmgr_hist%ROWTYPE;
        l_create_dmgr_hist_bool BOOLEAN;
        l_next_pat_dmgr_hist    pat_dmgr_hist.id_pat_dmgr_hist%TYPE;
        l_cur_epis_type         sys_config.value%TYPE;
        l_admin_default_room    sys_config.value%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_id_patient            patient.id_patient%TYPE;
        l_prof_cat              category.flg_type%TYPE;
        --
    
        -- Luis Maia 07-04-2008
        l_cur_software_edis sys_config.value%TYPE;
        l_cur_software_inp  sys_config.value%TYPE;
        -- Jos Brito 09-05-2008
        l_cur_software_triage sys_config.value%TYPE;
        -- Jos Brito 24-07-2008
        l_cur_software_ubu sys_config.value%TYPE;
    
        l_epis_doc_template table_number;
        err_default_template EXCEPTION;
    
        l_rowids table_varchar;
    
        CURSOR c_epis_room
        (
            l_epis_type     IN epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = i_id_professional.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv
             ORDER BY rank DESC;
    
        -- EDIS
        CURSOR c_room IS
            SELECT id_room
              FROM prof_room
             WHERE id_professional = i_id_professional.id
               AND id_room IN (SELECT r.id_room
                                 FROM room r, department d, software_dept sd
                                WHERE d.id_department = r.id_department
                                  AND d.id_institution = i_id_professional.institution
                                  AND sd.id_dept = d.id_dept
                                  AND sd.id_software = i_id_professional.software)
               AND flg_pref = g_room_pref;
    
        l_id_software software.id_software%TYPE;
    
        l_no_triage_color triage_color.id_triage_color%TYPE;
    
        g_exception_int EXCEPTION;
        l_error_message VARCHAR2(4000);
        l_msg           VARCHAR2(4000);
        l_exception_ext EXCEPTION;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        --
        g_error         := 'GET_CONFIGURATIONS';
        l_cur_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_id_professional);
    
        -- Luis Maia 07-04-2008
        l_cur_software_edis := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_id_professional);
        l_cur_software_inp  := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_id_professional);
        -- Jos Brito 09-05-2008
        l_cur_software_triage := pk_sysconfig.get_config('SOFTWARE_ID_TRIAGE', i_id_professional);
        -- Jos Brito 24-07-2008
        l_cur_software_ubu := pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_id_professional);
        -- No caso de ser o administrativo a criar um episdio temporrio, qual a sala por defeito
        l_admin_default_room := pk_sysconfig.get_config('ADMIN_DEFAULT_ROOM', i_id_professional);
        --
        -- Jos Brito 22/07/2008 Obter a categoria do profissional
        l_prof_cat := pk_edis_list.get_prof_cat(i_id_professional);
        --
    
        g_error := 'GET ID_DEP_CLIN_SERV';
        IF NOT get_epis_dep_clin_serv(i_lang             => i_lang,
                                      i_id_professional  => i_id_professional,
                                      o_department       => l_department,
                                      o_dept             => l_dept,
                                      o_clinical_service => l_clinical_service,
                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                      o_error            => o_error)
        THEN
            RAISE g_exception_int;
        END IF;
    
        IF i_id_professional.software IN (l_cur_software_edis, l_cur_software_triage, l_cur_software_ubu)
        THEN
            -- Jos Brito 22/07/2008 Permitir que o administrativo crie episdios temporrios,...
            IF l_id_dep_clin_serv IS NOT NULL
               OR l_prof_cat = g_cat_type_reg
            THEN
                -- Sala por defeito
                g_error := 'OPEN c_room';
                OPEN c_room;
                FETCH c_room
                    INTO l_room;
                CLOSE c_room;
            
                -- ... e que surja mensagem de erro caso o pessoal clnico no tiver seleccionado
                -- um servio clnico preferencial.
            ELSE
                l_msg           := 'CREATE_EPISODE_TEMP_M001';
                l_error_message := pk_message.get_message(i_lang, i_id_professional, 'CREATE_EPISODE_TEMP_M001');
                RAISE g_exception_int;
            END IF;
        
        ELSIF i_id_professional.software = l_cur_software_inp
        THEN
            --
            IF l_id_dep_clin_serv IS NOT NULL
            THEN
                -- Sala por defeito
                g_error := 'OPENC_EPIS_ROOM';
                OPEN c_epis_room(l_cur_epis_type, l_id_dep_clin_serv);
                FETCH c_epis_room
                    INTO l_room, l_rank;
                CLOSE c_epis_room;
            ELSE
                l_msg           := 'CREATE_EPISODE_TEMP_M001';
                l_error_message := pk_message.get_message(i_lang, i_id_professional, 'CREATE_EPISODE_TEMP_M001');
                RAISE g_exception_int;
            END IF;
        
        END IF;
        --
        -- Jos Brito 09/07/2008 Mostrar mensagem de erro, no caso de no existirem salas por defeito
        IF i_id_professional.software = l_cur_software_triage
           AND l_room IS NULL
        THEN
            l_msg           := 'CREATE_EPISODE_TEMP_M002';
            l_error_message := pk_message.get_message(i_lang, i_id_professional, 'CREATE_EPISODE_TEMP_M002');
            RAISE g_exception_int;
        ELSIF l_room IS NULL
              AND l_admin_default_room IS NULL
        THEN
            l_msg := 'CREATE_EPISODE_TEMP_M002';
        
            l_error_message := pk_message.get_message(i_lang, i_id_professional, 'CREATE_EPISODE_TEMP_M002');
            RAISE g_exception_int;
        
        END IF;
        --
        --
        g_error := 'GET SEQ_PATIENT.NEXTVAL';
        SELECT ts_patient.next_key
          INTO l_id_patient
          FROM dual;
    
        o_patient := l_id_patient;
        --
        g_error := 'GET SEQ_VISIT.NEXTVAL';
        SELECT seq_visit.nextval
          INTO l_next_visit
          FROM dual;
        --
        g_error := 'GET SEQ_EPIS_INSTITUTION.NEXTVAL ';
        SELECT seq_epis_institution.nextval
          INTO l_next_epis_inst
          FROM dual;
        --
        g_error := 'GET SEQ_EPIS_EXT_SYS.NEXTVAL';
        SELECT seq_epis_ext_sys.nextval
          INTO l_next_epis_ext_sys
          FROM dual;
        --
        g_error := 'INSERT PATIENT';
        ts_patient.ins(id_patient_in      => l_id_patient,
                       name_in            => pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || l_id_patient,
                       gender_in          => pk_message.get_message(i_lang, 'COMMON_M027'),
                       nick_name_in       => pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || l_id_patient,
                       adw_last_update_in => SYSDATE,
                       flg_status_in      => g_patient_active,
                       rows_out           => l_rowids);
    
        g_error := 'aaa';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'PATIENT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        --
        g_error := 'INSERT VISIT';
        INSERT INTO visit
            (id_visit, dt_begin_tstz, flg_status, id_patient, id_institution, dt_creation)
        VALUES
            (l_next_visit, g_sysdate_tstz, g_visit_active, o_patient, i_id_professional.institution, g_sysdate_tstz);
        --
        ------- GERAO DE CDIGO DE BARRAS
        --
        g_error := 'CALL TO PK_BARCODE.GENERATE_BARCODE';
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => i_id_professional.institution,
                                           i_software     => i_id_professional.software,
                                           o_barcode      => l_barcode,
                                           o_error        => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
        --
        g_error := 'INSERT EPISODE';
        ts_episode.ins(id_visit_in                => l_next_visit,
                       id_patient_in              => l_id_patient,
                       id_clinical_service_in     => nvl(l_clinical_service, -1),
                       id_department_in           => nvl(l_department, -1),
                       id_dept_in                 => nvl(l_dept, -1),
                       flg_type_in                => g_epis_flg_type_t,
                       dt_begin_tstz_in           => g_sysdate_tstz,
                       id_epis_type_in            => l_cur_epis_type,
                       flg_status_in              => g_epis_active,
                       barcode_in                 => l_barcode,
                       dt_creation_in             => g_sysdate_tstz,
                       id_episode_out             => l_id_episode,
                       id_institution_in          => i_id_professional.institution,
                       id_cs_requested_in         => -1,
                       id_department_requested_in => -1,
                       id_dept_requested_in       => -1,
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => i_id_professional,
                                                      i_patient     => l_id_patient,
                                                      i_new_episode => l_id_episode,
                                                      o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        -- END ALERT-41412
    
        l_rowids := table_varchar();
    
        o_episode := l_id_episode;
        --
        l_id_software := pk_episode.get_soft_by_epis_type(l_cur_epis_type, i_id_professional.institution);
    
        -- Jos Brito 04/11/2008 Preencher EPIS_INFO.ID_TRIAGE_COLOR com a cr genrica do
        -- tipo de triagem usado na instituio actual
        g_error := 'GET NO TRIAGE COLOR';
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, i_id_professional, o_episode)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
        
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_VISIT',
                                                  'CREATE_EPISODE_TEMP',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
        END;
    
        g_error := 'INSERT EPIS_INFO';
        /* <DENORM Fbio> */
        ts_epis_info.ins(id_episode_in               => o_episode,
                         id_schedule_in              => -1,
                         id_room_in                  => nvl(l_room, l_admin_default_room),
                         flg_unknown_in              => g_unknown,
                         flg_status_in               => g_epis_info_efectiv,
                         id_first_dep_clin_serv_in   => l_id_dep_clin_serv,
                         id_dep_clin_serv_in         => l_id_dep_clin_serv,
                         id_patient_in               => l_id_patient,
                         id_software_in              => l_id_software,
                         dt_last_interaction_tstz_in => g_sysdate_tstz,
                         triage_acuity_in            => pk_alert_constant.g_color_gray,
                         triage_color_text_in        => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in       => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in          => l_no_triage_color,
                         rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EPIS_INFO',
                                      o_error      => o_error,
                                      i_rowids     => l_rowids);
        --
        g_error := 'INSERT DOC TRIAGE ALERT';
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               i_id_professional,
                                               l_id_episode,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_nurse,
                                               pk_edis_triage.g_type_add,
                                               o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        --
        g_error := 'INSERT EPIS WAITING ALERT';
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               i_id_professional,
                                               l_id_episode,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_waiting,
                                               pk_edis_triage.g_type_add,
                                               o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        --
        g_error := 'INSERT EPIS_INSTITUTION';
        INSERT INTO epis_institution
            (id_epis_institution, id_institution, id_episode)
        VALUES
            (l_next_epis_inst, i_id_professional.institution, o_episode);
        --
    
        -- Fbio Oliveira 16/10/2008
        g_error := 'INSERT CLIN_RECORD';
        /* <DENORM Fbio> */
        ts_clin_record.ins(flg_status_in        => 'A',
                           id_patient_in        => o_patient,
                           id_institution_in    => i_id_professional.institution,
                           id_pat_family_in     => NULL,
                           num_clin_record_in   => NULL,
                           id_instit_enroled_in => i_id_professional.institution,
                           rows_out             => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang, i_id_professional, 'CLIN_RECORD', l_rowids, o_error);
    
        -- Luis Maia 07-04-2008
        IF i_id_professional.software = l_cur_software_inp
        THEN
            -- set the default episode touch option templates (INP: g_flg_type_clin_serv_type=S; OUTP, CARE e PP: g_flg_type_clin_serv_type=A)
            g_error := 'SET DEFAULT EPIS DOC TEMPLATES';
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => i_id_professional,
                                                                  i_episode            => o_episode,
                                                                  i_flg_type           => g_flg_template_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => o_error)
            THEN
                RAISE err_default_template;
            END IF;
        END IF;
    
        --
        g_error := 'GET SEQ_PAT_DMGR_HIST.NEXTVAL';
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_next_pat_dmgr_hist
          FROM dual;
        --
        l_pat_dmgr_hist_row.id_pat_dmgr_hist := l_next_pat_dmgr_hist;
        l_pat_dmgr_hist_row.id_patient       := o_patient;
        l_pat_dmgr_hist_row.id_professional  := i_id_professional.id;
        l_pat_dmgr_hist_row.id_institution   := i_id_professional.institution;
        l_pat_dmgr_hist_row.name             := pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || o_patient;
        l_pat_dmgr_hist_row.gender           := pk_message.get_message(i_lang, 'COMMON_M027');
        l_pat_dmgr_hist_row.dt_change_tstz   := g_sysdate_tstz;
        l_pat_dmgr_hist_row.nick_name        := pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || o_patient;
    
        -- calling the insertion function to the pat_dmgr_hist table
        g_error                 := 'CALL pk_dmgr_hist.create_dmgr_hist';
        l_create_dmgr_hist_bool := pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row,
                                                                 i_lang,
                                                                 i_id_professional,
                                                                 o_error);
        IF NOT l_create_dmgr_hist_bool
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
        --
        -- Jos Brito 15/04/2008
        -- Registo de FIRST OBS no deve ser feito na criao de um episdio temporrio.
    
        --ALERT-70086, ASantos 27-01-2009
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => i_id_professional,
                                                     i_episode            => o_episode,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => o_error)
        THEN
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - ID_EPISODE: ' || o_episode || '; LOG_ID: ' || o_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => 'PK_VISIT', sub_object_name => 'CREATE_EPISODE_TEMP');
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_int THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   l_msg,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CREATE_EPISODE_TEMP',
                                   l_msg,
                                   'U');
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes quando aplicavel-> so faz ROLLBACK
                pk_utils.undo_changes;
                -- return failure of function_dummy
                RETURN l_ret;
            END;
        
        WHEN err_default_template THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE_TEMP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE_TEMP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --

    /**********************************************************************************************
    * Creates temporary patients, according to the new logic requested by the ADT/Coding team.
    *
    * @param i_lang                   Language
    * @param i_id_prof                Professional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param i_id_patient             New patient ID
    * @param o_ora_sqlcode            Error code
    * @param o_ora_sqlerrm            Error message
    * @param o_err_desc               Error description
    * @param o_err_action             Error action (when applicable)
    *
    * @return                         New episode ID if sucessful, -1 otherwise
    *                                 (The new logic doesn't allow returning boolean values)
    *
    * @author                         Jose Brito (Based on CREATE_EPISODE_TEMP by Silvia Freitas)
    * @version                        1.0
    * @since                          2009/03/23
    **********************************************************************************************/
    FUNCTION create_episode_temp
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_ext_sys     IN external_sys.id_external_sys%TYPE DEFAULT NULL,
        i_value          IN epis_ext_sys.value%TYPE DEFAULT NULL,
        o_ora_sqlcode    OUT VARCHAR2,
        o_ora_sqlerrm    OUT VARCHAR2,
        o_err_desc       OUT VARCHAR2,
        o_err_action     OUT VARCHAR2
    ) RETURN NUMBER IS
        l_prof               profissional := profissional(i_id_prof, i_id_institution, i_id_software);
        l_next_visit         NUMBER;
        l_next_epis_inst     NUMBER;
        l_next_epis_ext_sys  NUMBER;
        l_epis_type          NUMBER;
        l_room               epis_type_room.id_room%TYPE;
        l_department         department.id_department%TYPE;
        l_dept               dept.id_dept%TYPE;
        l_clinical_service   dep_clin_serv.id_clinical_service%TYPE;
        l_id_dep_clin_serv   dep_clin_serv.id_dep_clin_serv%TYPE;
        l_barcode            VARCHAR2(30);
        l_rank               NUMBER;
        l_pat_dmgr_hist_row  pat_dmgr_hist%ROWTYPE;
        l_next_pat_dmgr_hist pat_dmgr_hist.id_pat_dmgr_hist%TYPE;
        l_cur_epis_type      sys_config.value%TYPE;
        l_admin_default_room sys_config.value%TYPE;
        l_id_episode         episode.id_episode%TYPE;
        l_prof_cat           category.flg_type%TYPE;
        --
        l_cur_software_edis   sys_config.value%TYPE;
        l_cur_software_inp    sys_config.value%TYPE;
        l_cur_software_triage sys_config.value%TYPE;
        l_cur_software_ubu    sys_config.value%TYPE;
        l_epis_doc_template   table_number;
        l_rowids              table_varchar;
        --
        l_id_software     software.id_software%TYPE;
        l_no_triage_color triage_color.id_triage_color%TYPE;
        --
        g_exception_int EXCEPTION;
        l_error_message VARCHAR2(4000);
        l_msg           VARCHAR2(4000);
        l_internal_error EXCEPTION;
        --
        l_return_false CONSTANT NUMBER(6) := -1;
        l_error t_error_out;
    
        CURSOR c_epis_room
        (
            l_epis_type     IN epis_type.id_epis_type%TYPE,
            l_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
            SELECT er.id_room, 0 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = l_prof.institution
               AND nvl(er.id_dep_clin_serv, 0) = 0
            UNION
            SELECT er.id_room, 1 rank
              FROM epis_type_room er
             WHERE er.id_epis_type = l_epis_type
               AND er.id_institution = l_prof.institution
               AND er.id_dep_clin_serv = l_dep_clin_serv
             ORDER BY rank DESC;
    
        -- EDIS
        CURSOR c_room IS
            SELECT id_room
              FROM prof_room
             WHERE id_professional = l_prof.id
               AND id_room IN (SELECT r.id_room
                                 FROM room r, department d, software_dept sd
                                WHERE d.id_department = r.id_department
                                  AND d.id_institution = l_prof.institution
                                  AND sd.id_dept = d.id_dept
                                  AND sd.id_software = l_prof.software)
               AND flg_pref = g_room_pref;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CONFIGURATIONS';
        pk_alertlog.log_debug(g_error);
        -- Type of Episode ID
        l_cur_epis_type := pk_sysconfig.get_config('EPIS_TYPE', l_prof);
        -- Software ID
        l_cur_software_edis   := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', l_prof);
        l_cur_software_inp    := pk_sysconfig.get_config('SOFTWARE_ID_INP', l_prof);
        l_cur_software_triage := pk_sysconfig.get_config('SOFTWARE_ID_TRIAGE', l_prof);
        l_cur_software_ubu    := pk_sysconfig.get_config('SOFTWARE_ID_UBU', l_prof);
        -- Registrar's default room
        l_admin_default_room := pk_sysconfig.get_config('ADMIN_DEFAULT_ROOM', l_prof);
    
        g_error := 'GET PROFESSIONAL CATEGORY';
        pk_alertlog.log_debug(g_error);
        l_prof_cat := pk_edis_list.get_prof_cat(l_prof);
    
        g_error := 'GET ID_DEP_CLIN_SERV';
        IF NOT get_epis_dep_clin_serv(i_lang             => i_lang,
                                      i_id_professional  => l_prof,
                                      o_department       => l_department,
                                      o_dept             => l_dept,
                                      o_clinical_service => l_clinical_service,
                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                      o_error            => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF l_prof.software IN (l_cur_software_edis, l_cur_software_triage, l_cur_software_ubu) -- EDIS and related softwares
        THEN
            -- Allow creation of temporary patients by the registrar
            IF l_id_dep_clin_serv IS NOT NULL
               OR l_prof_cat = g_cat_type_reg
            THEN
                -- Default room
                g_error := 'OPEN c_room';
                pk_alertlog.log_debug(g_error);
                OPEN c_room;
                FETCH c_room
                    INTO l_room;
                CLOSE c_room;
            ELSE
                -- Error message: a default clinical service was not selected
                l_msg           := 'CREATE_EPISODE_TEMP_M001';
                l_error_message := pk_message.get_message(i_lang, l_prof, 'CREATE_EPISODE_TEMP_M001');
                RAISE g_exception_int;
            END IF;
        
        ELSIF l_prof.software = l_cur_software_inp -- Inpatient
        THEN
            --
            IF l_id_dep_clin_serv IS NOT NULL
            THEN
                -- Default room
                g_error := 'OPENC_EPIS_ROOM';
                pk_alertlog.log_debug(g_error);
                OPEN c_epis_room(l_cur_epis_type, l_id_dep_clin_serv);
                FETCH c_epis_room
                    INTO l_room, l_rank;
                CLOSE c_epis_room;
            ELSE
                l_msg           := 'CREATE_EPISODE_TEMP_M001';
                l_error_message := pk_message.get_message(i_lang, l_prof, 'CREATE_EPISODE_TEMP_M001');
                RAISE g_exception_int;
            END IF;
        
        END IF;
    
        -- Error message: a default room was not selected
        IF l_prof.software = l_cur_software_triage
           AND l_room IS NULL
        THEN
            l_msg           := 'CREATE_EPISODE_TEMP_M002';
            l_error_message := pk_message.get_message(i_lang, l_prof, 'CREATE_EPISODE_TEMP_M002');
            RAISE g_exception_int;
        ELSIF l_room IS NULL
              AND l_admin_default_room IS NULL
        THEN
            l_msg           := 'CREATE_EPISODE_TEMP_M002';
            l_error_message := pk_message.get_message(i_lang, l_prof, 'CREATE_EPISODE_TEMP_M002');
            RAISE g_exception_int;
        END IF;
    
        g_error := 'GET SEQ_VISIT.NEXTVAL';
        pk_alertlog.log_debug(g_error);
        SELECT seq_visit.nextval
          INTO l_next_visit
          FROM dual;
    
        g_error := 'GET SEQ_EPIS_INSTITUTION.NEXTVAL ';
        pk_alertlog.log_debug(g_error);
        SELECT seq_epis_institution.nextval
          INTO l_next_epis_inst
          FROM dual;
    
        -- Create new visit
        g_error := 'INSERT VISIT';
        pk_alertlog.log_debug(g_error);
        INSERT INTO visit
            (id_visit, dt_begin_tstz, flg_status, id_patient, id_institution, dt_creation)
        VALUES
            (l_next_visit, g_sysdate_tstz, g_visit_active, i_id_patient, l_prof.institution, g_sysdate_tstz);
    
        -- Create new barcode
        g_error := 'CALL TO PK_BARCODE.GENERATE_BARCODE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => 'P',
                                           i_institution  => l_prof.institution,
                                           i_software     => l_prof.software,
                                           o_barcode      => l_barcode,
                                           o_error        => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Create new episode
        g_error := 'INSERT EPISODE';
        pk_alertlog.log_debug(g_error);
        ts_episode.ins(id_visit_in                => l_next_visit,
                       id_patient_in              => i_id_patient,
                       id_clinical_service_in     => nvl(l_clinical_service, -1),
                       id_department_in           => nvl(l_department, -1),
                       id_dept_in                 => nvl(l_dept, -1),
                       dt_begin_tstz_in           => g_sysdate_tstz,
                       flg_type_in                => g_epis_flg_type_t,
                       id_epis_type_in            => l_cur_epis_type,
                       flg_status_in              => g_epis_active,
                       barcode_in                 => l_barcode,
                       dt_creation_in             => g_sysdate_tstz,
                       id_episode_out             => l_id_episode,
                       id_institution_in          => l_prof.institution,
                       id_cs_requested_in         => -1,
                       id_department_requested_in => -1,
                       id_dept_requested_in       => -1,
                       rows_out                   => l_rowids);
    
        g_error := 'PROCESS INSERT - EPISODE';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        -- ALERT-41412: AS (03-06-2011)
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.SET_RECURR_PLAN';
        pk_alertlog.log_debug(text => g_error);
        IF NOT pk_advanced_directives.set_recurr_plan(i_lang        => i_lang,
                                                      i_prof        => l_prof,
                                                      i_patient     => i_id_patient,
                                                      i_new_episode => l_id_episode,
                                                      o_error       => l_error)
        THEN
            RAISE l_internal_error;
        END IF;
        -- END ALERT-41412
    
        l_rowids := table_varchar();
    
        g_error := 'GET CURRENT SOFTWARE';
        pk_alertlog.log_debug(g_error);
        l_id_software := pk_episode.get_soft_by_epis_type(l_cur_epis_type, l_prof.institution);
    
        -- Get triage generic color (no color)
        g_error := 'GET NO TRIAGE COLOR';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT tco.id_triage_color
              INTO l_no_triage_color
              FROM triage_color tco, triage_type tt
             WHERE tco.id_triage_type = tt.id_triage_type
               AND tt.id_triage_type = pk_edis_triage.get_triage_type(i_lang, l_prof, l_id_episode)
               AND tco.flg_type = 'S'
               AND rownum < 2;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_internal_error;
        END;
    
        -- Set EPIS_INFO
        g_error := 'INSERT EPIS_INFO';
        pk_alertlog.log_debug(g_error);
        ts_epis_info.ins(id_episode_in               => l_id_episode,
                         id_schedule_in              => -1,
                         id_room_in                  => nvl(l_room, l_admin_default_room),
                         flg_unknown_in              => g_unknown,
                         flg_status_in               => g_epis_info_efectiv,
                         id_first_dep_clin_serv_in   => l_id_dep_clin_serv,
                         id_dep_clin_serv_in         => l_id_dep_clin_serv,
                         id_patient_in               => i_id_patient,
                         id_software_in              => l_id_software,
                         dt_last_interaction_tstz_in => g_sysdate_tstz,
                         triage_acuity_in            => pk_alert_constant.g_color_gray,
                         triage_color_text_in        => pk_alert_constant.g_color_white,
                         triage_rank_acuity_in       => pk_alert_constant.g_rank_acuity,
                         id_triage_color_in          => l_no_triage_color,
                         rows_out                    => l_rowids);
    
        g_error := 'PROCESS INSERT - EPIS_INFO';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof,
                                      i_table_name => 'EPIS_INFO',
                                      o_error      => l_error,
                                      i_rowids     => l_rowids);
    
        -- Set triage alert
        g_error := 'INSERT DOC TRIAGE ALERT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               l_prof,
                                               l_id_episode,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_nurse,
                                               pk_edis_triage.g_type_add,
                                               l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'INSERT EPIS WAITING ALERT';
        IF NOT pk_edis_triage.set_alert_triage(i_lang,
                                               l_prof,
                                               l_id_episode,
                                               g_sysdate_tstz,
                                               pk_edis_triage.g_alert_waiting,
                                               pk_edis_triage.g_type_add,
                                               l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'INSERT EPIS_INSTITUTION';
        pk_alertlog.log_debug(g_error);
        INSERT INTO epis_institution
            (id_epis_institution, id_institution, id_episode)
        VALUES
            (l_next_epis_inst, l_prof.institution, l_id_episode);
    
        IF l_prof.software = l_cur_software_inp
        THEN
            -- set the default episode touch option templates (INP: g_flg_type_clin_serv_type=S; OUTP, CARE e PP: g_flg_type_clin_serv_type=A)
            g_error := 'SET DEFAULT EPIS DOC TEMPLATES';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => l_prof,
                                                                  i_episode            => l_id_episode,
                                                                  i_flg_type           => g_flg_template_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => l_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        g_error := 'GET SEQ_PAT_DMGR_HIST.NEXTVAL';
        pk_alertlog.log_debug(g_error);
        SELECT seq_pat_dmgr_hist.nextval
          INTO l_next_pat_dmgr_hist
          FROM dual;
        --
        l_pat_dmgr_hist_row.id_pat_dmgr_hist := l_next_pat_dmgr_hist;
        l_pat_dmgr_hist_row.id_patient       := i_id_patient;
        l_pat_dmgr_hist_row.id_professional  := l_prof.id;
        l_pat_dmgr_hist_row.id_institution   := l_prof.institution;
        l_pat_dmgr_hist_row.name             := pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || i_id_patient;
        l_pat_dmgr_hist_row.gender           := pk_message.get_message(i_lang, 'COMMON_M027');
        l_pat_dmgr_hist_row.dt_change_tstz   := g_sysdate_tstz;
        l_pat_dmgr_hist_row.nick_name        := pk_message.get_message(i_lang, 'COMMON_M026') || ' ' || i_id_patient;
    
        -- calling the insertion function to the pat_dmgr_hist table
        g_error := 'CALL pk_dmgr_hist.create_dmgr_hist';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_dmgr_hist.create_dmgr_hist(l_pat_dmgr_hist_row, i_lang, l_prof, l_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF i_id_ext_sys IS NOT NULL
           AND i_value IS NOT NULL
        THEN
            g_error := 'GET SEQ_EPIS_EXT_SYS.NEXTVAL';
            pk_alertlog.log_debug(g_error);
        
            SELECT seq_epis_ext_sys.nextval
              INTO l_next_epis_ext_sys
              FROM dual;
        
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (l_next_epis_ext_sys,
                 i_id_ext_sys,
                 l_id_episode,
                 i_value,
                 i_id_institution,
                 pk_sysconfig.get_config('EPIS_TYPE', profissional(i_id_prof, i_id_institution, i_id_software)),
                 decode(i_id_software, 8, 'URG', 29, 'URG', 11, 'INT', 1, 'CON', 3, 'CON', 12, 'CON', 'XXX'));
        END IF;
    
        --ALERT-70086, ASantos 27-01-2009
        IF NOT pk_diagnosis_core.set_visit_diagnosis(i_lang               => i_lang,
                                                     i_prof               => profissional(i_id_prof,
                                                                                          i_id_institution,
                                                                                          i_id_software),
                                                     i_episode            => l_id_episode,
                                                     i_tbl_epis_diagnosis => NULL,
                                                     o_error              => l_error)
        THEN
            g_error := 'SET_VISIT_DIAGNOSIS ERROR - ID_EPISODE: ' || l_id_episode || '; LOG_ID: ' || l_error.log_id;
            pk_alertlog.log_error(text => g_error, object_name => 'PK_VISIT', sub_object_name => 'CREATE_EPISODE_TEMP');
            RAISE l_internal_error;
        END IF;
    
        RETURN l_id_episode; -- Required by ADT/Coding: do NOT return boolean values!!
    
    EXCEPTION
    
        WHEN g_exception_int THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   l_msg,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CREATE_EPISODE_TEMP',
                                   l_msg,
                                   'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, l_error);
            
                -- Fill error information for JDBC
                o_ora_sqlcode := l_error.ora_sqlcode;
                o_ora_sqlerrm := l_error.ora_sqlerrm;
                o_err_desc    := l_error_message;
                o_err_action  := l_error.err_action;
            
                RETURN l_return_false; -- Required by ADT/Coding: do NOT return boolean values!!
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_EPISODE_TEMP',
                                              l_error);
        
            -- Fill error information for JDBC
            o_ora_sqlcode := l_error.ora_sqlcode;
            o_ora_sqlerrm := l_error.ora_sqlerrm;
            o_err_desc    := l_error.err_desc;
            o_err_action  := l_error.err_action;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN l_return_false; -- Required by ADT/Coding: do NOT return boolean values!!
    
    END create_episode_temp;

    --

    FUNCTION delete_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception_ext EXCEPTION;
    BEGIN
        IF NOT pk_visit.call_delete_episode(i_lang            => i_lang,
                                            i_id_sched        => i_id_sched,
                                            i_id_episode      => i_id_episode,
                                            i_id_professional => i_id_professional,
                                            o_error           => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'DELETE_EPISODE');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    --
    FUNCTION call_delete_episode
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Removes all episode information and in related tables.
                        An episode might be remove only if the state is "efectivado"
                        The visit is also deleted if contains no episode.
           PARAMETROS:  IN: I_LANG - Professional preferred language
                            I_ID_EPISODE - id do episdio
                            I_ID_PROFESSIONAL - profissional executing
        
              OUT:   O_ERROR - an error message
        
          CRIAO: LG 2006/09/14
          ALTERAO: CRS 2007/01/09 Par. entrada passa a ser ID_EPISODE em vez de ID_SCHEDULE
                  Episdios com informao so inactivados e no eliminados
                  cmf 2008-02-11 added dt_end and dt_end_tstz on update visit and episode when inactive
          NOTAS:
        *********************************************************************************/
        l_flg_status    schedule_outp.flg_state%TYPE;
        l_id_schedule   schedule.id_schedule%TYPE;
        l_id_episode    episode.id_episode%TYPE;
        l_id_visit      visit.id_visit%TYPE;
        l_counter       NUMBER;
        l_epis_inactive BOOLEAN;
    
        l_rows          table_varchar;
        l_error_message VARCHAR2(4000);
        g_exception_int EXCEPTION;
        g_exception_ext EXCEPTION;
    BEGIN
        IF nvl(i_id_episode, 0) = 0
           AND nvl(i_id_sched, 0) != 0
        THEN
            -- which episode belongs the schedule to?
            g_error := 'GET ID_EPISODE';
            SELECT id_episode, flg_status
              INTO l_id_episode, l_flg_status
              FROM epis_info
             WHERE id_schedule = i_id_sched;
            IF SQL%NOTFOUND
            THEN
                l_error_message := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                   'PK_VISIT.DELETE_EPISODE ' || g_error;
                RAISE g_exception_int;
            END IF;
            l_id_schedule := i_id_sched;
        
        ELSIF nvl(i_id_episode, 0) != 0
              AND nvl(i_id_sched, 0) = 0
        THEN
            g_error := 'GET ID_SCHEDULE';
            SELECT id_schedule, flg_status
              INTO l_id_schedule, l_flg_status
              FROM epis_info
             WHERE id_episode = i_id_episode;
            IF SQL%NOTFOUND
            THEN
                l_error_message := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                   'PK_VISIT.DELETE_EPISODE ' || g_error;
                RAISE g_exception_int;
            
            END IF;
            l_id_episode := i_id_episode;
        END IF;
    
        IF (l_flg_status <> g_epis_info_efectiv)
        THEN
            -- TODO : MENSAGE INFORMING USER THAT EPISODE IS NOT AVAILABLE FOR DELETION
            l_error_message := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_VISIT.DELETE_EPISODE ' ||
                               g_error;
            RAISE g_exception_int;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO DELETE_EPISODE_INFO';
        IF NOT delete_episode_info(i_lang            => i_lang,
                                   i_id_episode      => l_id_episode,
                                   i_id_sched        => l_id_schedule,
                                   i_id_professional => i_id_professional,
                                   o_error           => o_error)
        THEN
            --o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_VISIT.DELETE_EPISODE ' ||
            --g_error;
            RAISE g_exception_ext;
        
        END IF;
    
        g_error := 'DETELE FROM EPIS_INFO';
        /* <DENORM Fbio> */
        ts_epis_info.del_id_episode(id_episode_in => l_id_episode, rows_out => l_rows);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        -- delete from epis_institution
        g_error := 'DETELE FROM EPIS_INSTITUTION';
        DELETE FROM epis_institution
         WHERE id_episode = l_id_episode;
    
        -- find visit id
        g_error := 'FIND VISIT ID';
        SELECT id_visit
          INTO l_id_visit
          FROM episode
         WHERE id_episode = l_id_episode;
    
        -- delete from episode
        g_error := 'DETELE FROM EPISODE';
        BEGIN
            /* <DENORM Fbio> */
            ts_episode.del(id_episode_in => l_id_episode, rows_out => l_rows, handle_error_in => FALSE);
        
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_id_professional,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
            l_epis_inactive := FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                -- Se episdio j tem informao, fica inactivo
                ROLLBACK; -- No elimina registos em EPIS_TASK, EPIS_INFO, EPIS_INSTITUTION
                /* <DENORM Fbio> */
                l_rows := table_varchar();
                ts_episode.upd(id_episode_in   => l_id_episode,
                               flg_status_in   => g_epis_inactive,
                               dt_end_tstz_in  => current_timestamp,
                               dt_end_tstz_nin => FALSE,
                               rows_out        => l_rows);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_id_professional,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
                l_epis_inactive := TRUE;
        END;
    
        IF NOT l_epis_inactive
        THEN
            -- visit has more episodes?
            g_error := 'COUNT VISIT EPISODES';
            SELECT COUNT(*)
              INTO l_counter
              FROM episode
             WHERE id_visit = l_id_visit;
            IF (l_counter = 0)
            THEN
                -- delete from visit
                g_error := 'DELETE FROM VISIT';
                DELETE FROM visit
                 WHERE id_visit = l_id_visit;
            END IF;
        
        ELSE
        
            g_error := 'COUNT VISIT EPISODES';
            SELECT COUNT(*)
              INTO l_counter
              FROM episode
             WHERE id_visit = l_id_visit
               AND flg_status NOT IN (g_epis_inactive, g_epis_cancel);
        
            IF l_counter = 0
            THEN
            
                g_error := 'INACTIVATE VISIT / id_visit=' || l_id_visit;
                l_rows  := table_varchar();
                ts_visit.upd(id_visit_in     => l_id_visit,
                             flg_status_in   => g_visit_inactive,
                             flg_status_nin  => FALSE,
                             dt_end_tstz_in  => current_timestamp,
                             dt_end_tstz_nin => FALSE,
                             rows_out        => l_rows);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_id_professional,
                                              i_table_name   => 'VISIT',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
            
                --g_error := 'INACTIVATE VISIT';
                --UPDATE visit
                --   SET flg_status = g_visit_inactive, dt_end_tstz = current_timestamp
                -- WHERE id_visit = l_id_visit;
            END IF;
        
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_int THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   'COMMON_M001',
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CALL_DELETE_EPISODE',
                                   'COMMON_M001',
                                   'U');
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure of function_dummy
                RETURN l_ret;
            END;
        WHEN g_exception_ext THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CALL_DELETE_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END call_delete_episode;
    --
    --
    --
    /******************************************************************************
       OBJECTIVO:   Removes all episode information in related tables.
                    An episode might be remove only if the state is "efectivado"
       PARAMETROS:  IN: I_LANG - Professional preferred language
                        I_ID_EPISODE - id do episdio
                        I_ID_PROFESSIONAL - profissional executing
    
          OUT:   O_ERROR - an error message
    
      CRIAO: CRS 2007/01/09
      NOTAS:
    *********************************************************************************/

    FUNCTION delete_episode_info
    (
        i_lang            IN language.id_language%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_sched        IN schedule.id_schedule%TYPE,
        i_id_professional IN profissional,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where_clause      VARCHAR2(1000);
        l_rowids_aux        table_varchar;
        l_rowids_m_u        table_varchar := table_varchar();
        l_rowids_m_d        table_varchar := table_varchar();
        l_tab_out           table_varchar := table_varchar();
        l_tab_out_del       table_varchar := table_varchar();
        l_tab_out_del_dummy table_varchar := table_varchar();
    
    BEGIN
        -- if episode is to be deleted, also the prescriptions will be deleted
        IF NOT pk_api_pfh_in.delete_presc(i_lang       => i_lang,
                                          i_prof       => i_id_professional,
                                          i_id_episode => table_number(i_id_episode),
                                          o_error      => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        -- update interv_prescription
        g_error      := 'UPDATE INTERV_PRESCRIPTION';
        l_rowids_aux := table_varchar();
        ts_interv_prescription.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                                   id_episode_destination_nin => FALSE,
                                   where_in                   => 'id_episode_destination = ' || i_id_episode,
                                   rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_professional,
                                      i_table_name   => 'INTERV_PRESCRIPTION',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
    
        -- delete from interv_presc_plan
        g_error      := 'DETELE FROM INTERV_PRESC_PLAN';
        l_rowids_aux := table_varchar();
        ts_interv_presc_plan.del_by(where_clause_in => 'id_interv_presc_det IN
               (SELECT id_interv_presc_det
                  FROM interv_presc_det
                 WHERE id_interv_prescription IN (SELECT id_interv_prescription
                                                    FROM interv_prescription
                                                   WHERE id_episode = ' ||
                                                       i_id_episode || '))',
                                    rows_out        => l_rowids_aux);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'INTERV_PRESC_PLAN',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from interv_presc_det
        g_error      := 'DETELE FROM INTERV_PRESC_DET';
        l_rowids_aux := table_varchar();
        ts_interv_presc_det.del_by(where_clause_in => 'id_interv_prescription IN (SELECT id_interv_prescription
                                            FROM interv_prescription
                                           WHERE id_episode = ' ||
                                                      i_id_episode || ')',
                                   rows_out        => l_rowids_aux);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'INTERV_PRESC_DET',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from interv_prescription
        g_error      := 'DETELE FROM INTERV_PRESCRIPTION';
        l_rowids_aux := table_varchar();
        ts_interv_prescription.del_presc_epis_fk(id_episode_in => i_id_episode, rows_out => l_rowids_aux);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'INTERV_PRESCRIPTION',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- update analysis_req
        g_error := 'UPDATE ANALYSIS_REQ';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_analysis_req.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                            id_episode_destination_nin => FALSE,
                            where_in                   => 'id_episode_destination = ' || i_id_episode,
                            rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_professional,
                                      i_table_name   => 'ANALYSIS_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
    
        l_rowids_aux := table_varchar();
        -- update exam_req
        g_error := 'UPDATE EXAM_REQ';
        /* <DENORM Fbio> */
        ts_exam_req.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                        id_episode_destination_nin => FALSE,
                        where_in                   => 'id_episode_destination = ' || i_id_episode,
                        rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_id_professional,
                                      i_table_name   => 'EXAM_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
        l_rowids_aux := table_varchar();
    
        -- update monitorization
        g_error := 'UPDATE MONITORIZATION';
        ts_monitorization.upd(id_episode_destination_in  => NULL,
                              id_episode_destination_nin => FALSE,
                              where_in                   => 'id_episode_destination = ' || i_id_episode,
                              rows_out                   => l_rowids_m_u);
    
        -- update cli_rec_req
        g_error := 'UPDATE CLI_REC_REQ';
        UPDATE cli_rec_req
           SET id_episode_destination = NULL
         WHERE id_episode_destination = i_id_episode;
    
        -- DELETES FROM TABLES WHERE EPISODE WAS USED WHEN CREATING THE VISIT
        -- delete from grid_task
        g_error := 'DETELE FROM GRID_TASK';
        DELETE FROM grid_task
         WHERE id_episode = i_id_episode;
    
        g_error := 'DETELE FROM GRID_TASK_IMG';
        DELETE FROM grid_task_img
         WHERE id_episode = i_id_episode;
    
        -- delete from grid_task_between
        g_error := 'DETELE FROM GRID_TASK_BETWEEN';
        DELETE FROM grid_task_between
         WHERE id_episode = i_id_episode;
    
        -- delete from cli_rec_req_det
        g_error := 'DETELE FROM CLI_REC_REQ_DET';
        DELETE FROM cli_rec_req_det
         WHERE id_cli_rec_req IN (SELECT id_cli_rec_req
                                    FROM cli_rec_req
                                   WHERE id_episode = i_id_episode);
    
        -- delete from cli_rec_req
        g_error := 'DETELE FROM CLI_REC_REQ';
        DELETE FROM cli_rec_req
         WHERE id_episode = i_id_episode;
    
        -- delete from monitorization_vs_plan
        g_error        := 'DETELE FROM MONITORIZATION_VS_PLAN';
        l_where_clause := 'id_monitorization_vs IN ';
        l_where_clause := l_where_clause ||
                          '(SELECT id_monitorization_vs FROM monitorization_vs WHERE id_monitorization_vs IN ';
        l_where_clause := l_where_clause || '(SELECT id_monitorization FROM monitorization WHERE id_episode = ' ||
                          i_id_episode || '))';
        ts_monitorization_vs_plan.del_by(where_clause_in => l_where_clause, rows_out => l_rowids_aux);
    
        -- delete from monitorization_vs
        g_error        := 'DETELE FROM MONITORIZATION_VS';
        l_where_clause := 'id_monitorization IN (SELECT id_monitorization FROM monitorization WHERE id_episode = ' ||
                          i_id_episode || ')';
        ts_monitorization_vs.del_by(where_clause_in => l_where_clause, rows_out => l_rowids_aux);
    
        -- delete from monitorization
        g_error := 'DETELE FROM MONITORIZATION';
        ts_monitorization.del_by(where_clause_in => 'id_episode = ' || i_id_episode, rows_out => l_rowids_aux);
        l_rowids_m_d := l_rowids_m_d MULTISET UNION DISTINCT l_rowids_aux;
    
        -- delete from exam_req_det
        g_error := 'DETELE FROM EXAM_REQ_DET';
        /* <DENORM Fbio> */
        ts_exam_req_det.del_by(where_clause_in => 'id_exam_req IN (SELECT id_exam_req
                                 FROM exam_req
                                WHERE id_episode = ' || i_id_episode || ')',
                               rows_out        => l_rowids_aux);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from exam_req
        g_error := 'DETELE FROM EXAM_REQ';
        /* <DENORM Fbio> */
        ts_exam_req.del_ereq_epis_fk(id_episode_in => i_id_episode, rows_out => l_rowids_aux);
    
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'EXAM_REQ',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from grid_task_lab
        g_error := 'DELETE FROM GRID_TASK_LAB';
        DELETE FROM grid_task_lab
         WHERE id_episode = i_id_episode;
    
        -- delete from analysis_req_det
        g_error := 'DETELE FROM ANALYSIS_REQ_DET';
        /* <DENORM Fbio> */
        ts_analysis_req_det.del_by(where_clause_in => 'id_analysis_req IN (SELECT id_analysis_req
                                     FROM analysis_req
                                    WHERE id_episode = ' ||
                                                      i_id_episode || ')',
                                   rows_out        => l_rowids_aux);
    
        -- < DESNORM LMAIA 03-10-2008 retirado o IF >
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'ANALYSIS_REQ_DET',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from analysis_req
        g_error := 'DETELE FROM ANALYSIS_REQ';
        /* <DENORM Fbio> */
        ts_analysis_req.del_art_epis_fk(id_episode_in => i_id_episode, rows_out => l_rowids_aux);
    
        -- < DESNORM LMAIA 03-10-2008 retirado o IF >
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'ANALYSIS_REQ',
                                      i_rowids     => l_rowids_aux,
                                      o_error      => o_error);
    
        -- delete from epis_health_plan
        g_error := 'DETELE FROM EPIS_HEALTH_PLAN';
        DELETE FROM epis_health_plan
         WHERE id_episode = i_id_episode;
    
        -- UPDATE SCHEDULE STATE
        g_error := 'UPDATE SCHEDULE_OUTP';
        UPDATE schedule_outp
           SET flg_state = g_sched_scheduled
         WHERE id_schedule = i_id_sched;
    
        -- Alert Data Governance
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'MONITORIZATION',
                                      i_rowids     => l_rowids_m_u,
                                      o_error      => o_error);
    
        g_error := 'CALL t_data_gov_mnt.process_delete';
        t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                      i_prof       => i_id_professional,
                                      i_table_name => 'MONITORIZATION',
                                      i_rowids     => l_rowids_m_d,
                                      o_error      => o_error);
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'DELETE_EPISODE_INFO');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;
    --
    --
    /******************************************************************************
    * For use by the Flash application layer.
    *
    * @param i_lang            Professional preferred language
    * @param i_id_episode      Episode ID
    * @param i_prof            Professional executing the action
    * @param i_cancel_reason   Reason for cancelling this episode
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-Jun-03
    *
    ******************************************************************************/
    FUNCTION cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_can_refresh_mviews BOOLEAN := FALSE;
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CALL TO PK_VISIT.CALL_CANCEL_EPISODE';
        pk_alertlog.log_debug(g_error);
        IF NOT call_cancel_episode(i_lang           => i_lang,
                                   i_id_episode     => i_id_episode,
                                   i_prof           => i_prof,
                                   i_cancel_reason  => i_cancel_reason,
                                   i_cancel_type    => 'A',
                                   i_transaction_id => l_transaction_id,
                                   o_error          => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        l_can_refresh_mviews := TRUE;
    
        COMMIT;
    
        IF l_can_refresh_mviews
        THEN
            pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_prof);
        END IF;
    
        IF (i_transaction_id IS NULL AND l_transaction_id IS NOT NULL)
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CANCEL_EPISODE',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_episode;

    /** Flash wrapper do not use otherwise */
    FUNCTION cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.cancel_episode(i_lang           => i_lang,
                                       i_id_episode     => i_id_episode,
                                       i_prof           => i_prof,
                                       i_cancel_reason  => i_cancel_reason,
                                       i_transaction_id => NULL,
                                       o_error          => o_error);
    
    END cancel_episode;
    --
    /******************************************************************************
    * The main purposes of this function are:
    * - to allow ALERT from getting through third-party administrative systems the cancellation of an episode;
    * - to allow cancellation of episodes through ALERT ADT;
    * - to allow cancellation of temporary episodes within ALERT EDIS, ORIS and Inpatient.
    *
    * This function is used for cancelling episodes in ALERT EDIS, ORIS, Inpatient,
    * Outpatient and Private Practice. For the last two, this function calls
    * the other instance of PK_VISIT.CANCEL_EPISODE.
    * For ALERT EDIS, ORIS and Inpatient, this function checks if it's allowed to cancel
    * episodes with registered clinical information.
    *
    * @param i_lang            Professional preferred language
    * @param i_id_episode      Episode ID
    * @param i_prof            Professional executing the action
    * @param i_cancel_reason   Reason for cancelling this episode
    * @param i_cancel_type     'E' Cancel a registration; 'S' Cancel a scheduled episode;
    *                          'A' Cancelled in ALERTR (ADT included); 'I' Cancelled through INTER-ALERTR;
    *                          'D' Cancelled through medical discharge cancellation.
    * @param i_dt_cancel       Cancel date
    * @param i_transaction_id  scheduler 3 transaction id needed for calls to pk_schedule_api_upstream
    * @param i_goto_sch        true = allows scheduler 3 calls; false = refuses scheduler 3 calls
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-Apr-14
    *
    ******************************************************************************/
    FUNCTION call_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_transaction_id IN VARCHAR2,
        i_goto_sch       IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_unknown           epis_info.flg_unknown%TYPE; -- Temporary or definitive episode
        l_flg_status            episode.flg_status%TYPE; -- Episode status: active, pending, cancelled, etc.
        l_first_obs             epis_info.dt_first_obs_tstz%TYPE; -- Date of first clinical observation
        l_first_n_obs           epis_info.dt_first_nurse_obs_tstz%TYPE; -- Date of first nursing observation
        l_cancel_epis_first_obs VARCHAR2(1); -- Cancel episodes with first observation: Y/N
        l_cancel_temp_epis      VARCHAR2(1); -- Cancel temporary episodes: Y/N
        l_cancel_epis           VARCHAR2(1); -- Cancel episodes: Y/N
        l_epis_type             episode.id_epis_type%TYPE; -- Type of episode: emergency department, inpatient, outpatient...
        l_prev_epis_type        episode.id_epis_type%TYPE;
        l_message               VARCHAR2(400); -- Used for error messages
        l_msg_params            table_varchar; -- Used for error messages
        l_inp_prev_episode      episode.id_prev_episode%TYPE; -- Inpatient previous episode (if any)
        l_error                 VARCHAR2(400);
        l_flg_show              VARCHAR2(1);
        l_msg_title             VARCHAR2(200);
        l_msg_text              VARCHAR2(4000);
        l_button                VARCHAR2(200);
        l_value                 epis_ext_sys.value%TYPE;
        l_prev_value            epis_ext_sys.value%TYPE;
        l_flg_type              VARCHAR2(1);
        l_id_visit              visit.id_visit%TYPE;
        l_count                 NUMBER;
        l_disch_count           NUMBER;
        l_ann_arrival           announced_arrival.id_announced_arrival%TYPE;
        l_id_episode_surg       episode.id_episode%TYPE;
        l_flg_status_surg       episode.flg_status%TYPE;
        l_id_episode_surg_arr   table_number := table_number();
        l_flg_status_surg_arr   table_varchar := table_varchar();
    
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_id_department       department.id_department%TYPE;
        l_id_dept             dept.id_dept%TYPE;
        l_rowids              table_varchar;
    
        l_internal_exception        EXCEPTION;
        l_internal_cancel_exception EXCEPTION;
    
        l_error_in      t_error_in := t_error_in();
        l_ret           BOOLEAN;
        l_msg           VARCHAR2(4000);
        l_error_message VARCHAR2(4000);
        g_exception_int EXCEPTION;
        --
        l_total_pat_episodes NUMBER;
        l_patient            patient.id_patient%TYPE;
    
        l_id_external_sys external_sys.id_external_sys%TYPE;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        IF i_goto_sch
        THEN
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        END IF;
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET PATIENT';
        SELECT id_patient
          INTO l_patient
          FROM episode epi
         WHERE epi.id_episode = i_id_episode;
        pk_alertlog.log_debug('CALL_CANCEL_EPISODE  - INPUT PARAM - i_id_episode: ' || i_id_episode || ' l_patient:' ||
                              l_patient);
    
        l_id_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
    
        -- GET EPISODE DATA
        -- Check the type of episode;
        -- Get the status of the episode. Only 'active' episodes can be cancelled;
        -- Get the type of the episode (Outpatient, Inpatient, Private Practice, etc.);
        -- Check if it's a temporary (EPIS_INFO.FLG_UNKNOWN = 'Y') or definitive episode (EPIS_INFO.FLG_UNKNOWN = 'N');
        -- Get first observation dates (nurse/physician)
        BEGIN
            g_error := 'GET EPISODE DATA';
            pk_alertlog.log_debug(g_error);
            SELECT e.flg_type,
                   e.id_visit,
                   e.flg_status,
                   e.id_epis_type,
                   ei.flg_unknown,
                   ei.dt_first_obs_tstz,
                   ei.dt_first_nurse_obs_tstz,
                   ees.value
              INTO l_flg_type,
                   l_id_visit,
                   l_flg_status,
                   l_epis_type,
                   l_flg_unknown,
                   l_first_obs,
                   l_first_n_obs,
                   l_value
              FROM episode e, epis_info ei, epis_ext_sys ees
             WHERE e.id_episode = i_id_episode
               AND e.id_episode = ei.id_episode
               AND e.id_episode = ees.id_episode(+)
               AND ees.id_institution(+) = i_prof.institution
               AND ees.id_external_sys(+) = l_id_external_sys;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_internal_exception;
        END;
    
        IF check_epis_type_amb(i_epis_type => l_epis_type)
        THEN
        
            IF NOT cancel_outp_pp_episode(i_lang           => i_lang,
                                          i_id_episode     => i_id_episode,
                                          i_prof           => i_prof,
                                          i_cancel_type    => i_cancel_type,
                                          i_transaction_id => l_transaction_id,
                                          i_goto_sch       => i_goto_sch,
                                          o_error          => o_error)
            THEN
                RAISE l_internal_cancel_exception;
            END IF;
        
            IF i_goto_sch
               AND i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        
            -- If it's an Ambulatory episode, use this function.
            RETURN TRUE;
        
        ELSIF l_epis_type = g_epis_type_inp
        THEN
            BEGIN
                g_error := 'GET INPATIENT PREVIOUS EPISODE INFO';
                pk_alertlog.log_debug(g_error);
                SELECT e.id_episode, e.id_epis_type, ees.value
                  INTO l_inp_prev_episode, l_prev_epis_type, l_prev_value
                  FROM (SELECT e.id_prev_episode id_prev_epis
                          FROM episode e
                         WHERE e.id_episode = i_id_episode) prev_epis,
                       episode e,
                       epis_ext_sys ees
                 WHERE e.id_episode(+) = prev_epis.id_prev_epis
                   AND ees.id_episode(+) = e.id_episode
                   AND ees.id_institution(+) = i_prof.institution;
            
                -- When an INPATIENT episode has an EDIS previous episode, the episode IS NOT CANCELLED.
                -- Instead, updates EPIS_EXT_SYS if the episode was created in an external administrative software.
                IF l_prev_value IS NOT NULL
                   AND l_prev_value <> l_value
                   AND l_flg_unknown = g_no -- Only for non-temporary patients
                   AND l_prev_epis_type = g_epis_type_edis
                   AND l_id_external_sys <> pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_prof)
                THEN
                
                    g_error := 'UPDATE EPIS_EXT_SYS';
                    pk_alertlog.log_debug(g_error);
                    UPDATE epis_ext_sys ees
                       SET ees.value = l_prev_value, ees.cod_epis_type_ext = 'URG'
                     WHERE ees.id_episode = i_id_episode;
                
                    g_error := 'DELETE DISCHARGE ALERT';
                    pk_alertlog.log_debug(g_error);
                    g_ret := pk_discharge.del_disch_edis_to_inp_alert(i_lang, i_prof, i_id_episode, o_error);
                
                    g_error := 'UPDATE EPISODE.FLG_TYPE';
                    pk_alertlog.log_debug(g_error);
                    ts_episode.upd(flg_type_in   => g_inp_temporary,
                                   flg_type_nin  => FALSE,
                                   id_episode_in => i_id_episode,
                                   rows_out      => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPISODE',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    g_error := 'GET ID_FIRST_DEP_CLIN_SERV';
                    pk_alertlog.log_debug(g_error);
                    BEGIN
                        SELECT dcs.id_dep_clin_serv, dcs.id_clinical_service, d.id_department, d.id_dept
                          INTO l_id_dep_clin_serv, l_id_clinical_service, l_id_department, l_id_dept
                          FROM dep_clin_serv dcs, department d, epis_info ei
                         WHERE dcs.id_dep_clin_serv = ei.id_first_dep_clin_serv
                           AND dcs.id_department = d.id_department
                           AND ei.id_episode = i_id_episode;
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                
                    l_rowids := table_varchar();
                
                    g_error := 'UPDATE EPISODE (DEF)';
                    pk_alertlog.log_debug(g_error);
                    ts_episode.upd(id_clinical_service_in  => nvl(l_id_clinical_service, -1),
                                   id_clinical_service_nin => FALSE,
                                   id_department_in        => nvl(l_id_department, -1),
                                   id_department_nin       => FALSE,
                                   id_dept_in              => nvl(l_id_dept, -1),
                                   id_dept_nin             => FALSE,
                                   -- Remove previous episode info (avoids conflicts)
                                   id_prev_episode_in  => NULL,
                                   id_prev_episode_nin => FALSE,
                                   id_episode_in       => i_id_episode,
                                   rows_out            => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPISODE',
                                                  i_rowids       => l_rowids,
                                                  i_list_columns => table_varchar('id_dept',
                                                                                  'id_clinical_service',
                                                                                  'id_department',
                                                                                  'id_prev_episode'),
                                                  o_error        => o_error);
                
                    g_error := 'UPDATE EPIS_INFO';
                    pk_alertlog.log_debug(g_error);
                    /* <DENORM Fbio> */
                    l_rowids := table_varchar();
                    ts_epis_info.upd(id_episode_in        => i_id_episode,
                                     id_dep_clin_serv_in  => l_id_dep_clin_serv,
                                     id_dep_clin_serv_nin => FALSE,
                                     rows_out             => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'EPIS_INFO',
                                                  l_rowids,
                                                  o_error,
                                                  table_varchar('ID_DEP_CLIN_SERV'));
                
                    RETURN TRUE;
                    -- if the external value wasnt updated we need to clear the epis_ext_sys value
                ELSIF l_prev_value = l_value
                THEN
                    DELETE FROM epis_ext_sys ees
                     WHERE ees.id_episode = i_id_episode;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE l_internal_exception;
                WHEN OTHERS THEN
                    RAISE l_internal_exception;
            END;
        
        END IF;
    
        BEGIN
            g_error := 'GET DISCHARGE COUNT';
            -- Check if episode is currently discharged
            SELECT COUNT(*)
              INTO l_disch_count
              FROM discharge d
             WHERE d.flg_status NOT IN (g_flg_status_c)
               AND d.id_episode = i_id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_internal_exception;
        END;
    
        -- If the episode isn't active, returns an error message.
        IF (l_flg_status <> g_epis_active)
        THEN
            l_error      := 'BUILD ERROR MESSAGE 1';
            l_message    := pk_message.get_message(i_lang, 'VISIT_M009');
            l_error      := 'BUILD ERROR MESSAGE 2';
            l_msg_params := table_varchar(pk_sysdomain.get_domain(g_domain_episode_flg_status, l_flg_status, i_lang));
            l_error      := 'BUILD ERROR MESSAGE 3';
            IF (pk_message.format(i_lang, l_message, l_msg_params, l_message, o_error))
            THEN
                l_error := l_message;
            
                l_error_in.set_all(i_lang,
                                   'VISIT_M009',
                                   l_error,
                                   NULL,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CALL_CANCEL_EPISODE',
                                   l_error,
                                   'U');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END IF;
            pk_utils.undo_changes;
            RETURN FALSE;
            -- If the episode is discharged, it cannot be cancelled
        ELSIF l_disch_count > 0
        THEN
            l_msg           := 'VISIT_M026';
            l_error_message := pk_message.get_message(i_lang, i_prof, 'VISIT_M026');
            RAISE g_exception_int;
        END IF;
    
        -- Check if temporary and definitive episodes can be cancelled:
        g_error := 'GET CONFIGURATIONS';
        pk_alertlog.log_debug(g_error);
        l_cancel_temp_epis := pk_sysconfig.get_config(i_code_cf => 'CANCEL_TEMPORARY_EPISODES', i_prof => i_prof);
        l_cancel_epis      := pk_sysconfig.get_config(i_code_cf => 'CANCEL_EPISODES', i_prof => i_prof);
    
        pk_alertlog.log_debug('CALL_CANCEL_EPISODE  - CANCEL_TEMPORARY_EPISODES: ' || l_cancel_temp_epis ||
                              ' CANCEL_EPISODES:' || l_cancel_epis);
    
        IF (nvl(l_flg_unknown, g_definitive) = g_unknown AND l_cancel_temp_epis = g_no)
        THEN
            -- 1) temporary episodes can't be cancelled
            l_msg           := 'VISIT_M010';
            l_error_message := pk_message.get_message(i_lang, i_prof, 'VISIT_M010');
            RAISE g_exception_int;
        ELSIF (nvl(l_flg_unknown, g_definitive) = g_definitive AND l_cancel_epis = g_no)
        THEN
            -- 2) definitive episodes can't be cancelled
            l_msg           := 'VISIT_M011';
            l_error_message := pk_message.get_message(i_lang, i_prof, 'VISIT_M011');
            RAISE g_exception_int;
        END IF;
    
        -- Check if its allowed to cancel episodes with clinical info (i.e. have first observation).
        l_cancel_epis_first_obs := pk_sysconfig.get_config(i_code_cf => 'CANCEL_EPISODES_WITH_FIRST_OBS',
                                                           i_prof    => i_prof);
    
        pk_alertlog.log_debug('CALL_CANCEL_EPISODE  - CANCEL_EPISODES_WITH_FIRST_OBS: ' || l_cancel_epis_first_obs);
    
        -- If one of the first OBS dates is not null, then the episode has registered clinical information;
        -- If episodes with registered clinical information aren't allowed to be cancelled, returns an error message;
        IF ((l_first_obs IS NOT NULL OR l_first_n_obs IS NOT NULL) AND l_cancel_epis_first_obs = g_no)
        THEN
            l_msg           := 'VISIT_M012';
            l_error_message := pk_message.get_message(i_lang, 'VISIT_M012');
            RAISE g_exception_int;
        END IF;
    
        BEGIN
            g_error := 'VERIFY IF EPISODE HAS ANN_ARRIVAL';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT aa.id_announced_arrival
                  INTO l_ann_arrival
                  FROM announced_arrival aa
                 WHERE aa.id_episode = i_id_episode
                   AND aa.flg_status IN
                       (pk_announced_arrival.g_aa_arrival_status_a, pk_announced_arrival.g_aa_arrival_status_e);
            EXCEPTION
                WHEN no_data_found THEN
                    l_ann_arrival := NULL;
            END;
        
            IF l_ann_arrival IS NOT NULL
            THEN
                g_error := 'CANCEL ANN_ARRIVAL: ' || l_ann_arrival;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_announced_arrival.cancel_pat_arrival(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_announced_arrival => l_ann_arrival,
                                                               o_error             => o_error)
                THEN
                    RAISE l_internal_exception;
                END IF;
            
            END IF;
        
            IF l_epis_type = g_epis_type_inp
            THEN
                -- If it's an Inpatient episode, set the bed status to vacant.
                g_error := 'CALL TO SET_EPISODE_BED_STATUS_VACANT';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_bmng_pbl.set_episode_bed_status_vacant(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_id_episode     => i_id_episode,
                                                                 i_transaction_id => l_transaction_id,
                                                                 o_error          => o_error)
                THEN
                    RAISE l_internal_exception;
                END IF;
            
                -- Check if there's a surgery associated to this episode
                BEGIN
                    g_error := 'GET SURGICAL EPISODE INFO';
                    pk_alertlog.log_debug(g_error);
                    SELECT id_episode, flg_status
                      BULK COLLECT
                      INTO l_id_episode_surg_arr, l_flg_status_surg_arr
                      FROM episode e
                     WHERE e.id_prev_episode = i_id_episode
                       AND e.id_epis_type = g_epis_type_oris
                       AND e.flg_status NOT IN (g_epis_inactive, g_epis_cancel);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_episode_surg := NULL;
                    WHEN OTHERS THEN
                        RAISE l_internal_exception;
                END;
            
                -- Cancel the surgery
                FOR i IN 1 .. l_id_episode_surg_arr.count
                LOOP
                
                    l_id_episode_surg := l_id_episode_surg_arr(i);
                    l_flg_status_surg := l_flg_status_surg_arr(i);
                
                    IF l_id_episode_surg IS NOT NULL
                    THEN
                        g_error := 'CALL TO PK_SR_GRID.CALL_SET_PAT_STATUS (1)';
                        pk_alertlog.log_debug(g_error);
                        IF NOT pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => l_id_episode_surg,
                                                              i_flg_status_new => g_flg_status_c,
                                                              i_flg_status_old => l_flg_status_surg,
                                                              i_test           => g_yes,
                                                              i_transaction_id => l_transaction_id,
                                                              o_flg_show       => l_flg_show,
                                                              o_msg_title      => l_msg_title,
                                                              o_msg_text       => l_msg_text,
                                                              o_button         => l_button,
                                                              o_error          => o_error)
                        THEN
                            RAISE l_internal_exception;
                        END IF;
                    END IF;
                END LOOP;
            
            ELSIF l_epis_type = g_epis_type_oris
            THEN
                -- If it's an ORIS episode, use SET_PAT_STATUS to cancel the surgery
                g_error := 'CALL TO PK_SR_GRID.CALL_SET_PAT_STATUS (2)';
                pk_alertlog.log_debug(g_error);
                RETURN pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_episode        => i_id_episode,
                                                      i_flg_status_new => g_flg_status_c,
                                                      i_flg_status_old => l_flg_status,
                                                      i_test           => g_yes,
                                                      i_transaction_id => l_transaction_id,
                                                      o_flg_show       => l_flg_show,
                                                      o_msg_title      => l_msg_title,
                                                      o_msg_text       => l_msg_text,
                                                      o_button         => l_button,
                                                      o_error          => o_error);
            END IF;
        
            -- Updates episode data: set status to cancelled, professional who cancelled, cancellation reason and date.
            l_rowids := table_varchar();
        
            g_error := 'UPDATE EPISODE (TEMP)';
            pk_alertlog.log_debug(g_error);
            ts_episode.upd(flg_status_in          => g_flg_status_c,
                           flg_status_nin         => FALSE,
                           id_prof_cancel_in      => i_prof.id,
                           id_prof_cancel_nin     => FALSE,
                           dt_cancel_tstz_in      => i_dt_cancel,
                           dt_cancel_tstz_nin     => FALSE,
                           desc_cancel_reason_in  => i_cancel_reason,
                           desc_cancel_reason_nin => FALSE,
                           flg_cancel_type_in     => i_cancel_type,
                           flg_cancel_type_nin    => FALSE,
                           -- Remove previous episode info (avoids conflicts)
                           --id_prev_episode_in  => NULL,
                           --id_prev_episode_nin => FALSE,
                           id_episode_in => i_id_episode,
                           rows_out      => l_rowids);
        
            g_error := 'PROCESS UPDATE - EPISODE (TEMP)';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids,
                                          i_list_columns => table_varchar('flg_status',
                                                                          'id_prof_cancel',
                                                                          'dt_cancel_tstz',
                                                                          'desc_cancel_reason',
                                                                          'flg_cancel_type',
                                                                          'id_prev_episode'),
                                          o_error        => o_error);
        
            ts_epis_info.upd(id_episode_in  => i_id_episode,
                             flg_status_in  => g_flg_status_c,
                             flg_status_nin => FALSE,
                             rows_out       => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            --
            g_error := 'COUNT VISIT CANCELLED EPISODES';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(id_episode)
              INTO l_count
              FROM episode
             WHERE id_visit = l_id_visit
               AND flg_status <> g_epis_cancel;
        
            IF l_count = 0
            THEN
            
                g_error := 'UPDATE VISIT';
                pk_alertlog.log_debug(g_error);
                l_rowids := table_varchar();
                ts_visit.upd(id_visit_in    => l_id_visit,
                             flg_status_in  => g_flg_status_c,
                             flg_status_nin => FALSE,
                             rows_out       => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'VISIT',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            
                --g_error := 'UPDATE VISIT';
                --pk_alertlog.log_debug(g_error);
                --UPDATE visit v
                --   SET v.flg_status = g_flg_status_c
                -- WHERE v.id_visit = l_id_visit;
            END IF;
        
            --TO DO:
            --Redesenhar GRID_TASK para suportar este comportamento NL
            --RicardoNunoAlmeida
            g_error := 'WAITING LIST PROCESSING';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(we.id_waiting_list)
              INTO l_count
              FROM wtl_epis we
             INNER JOIN waiting_list wtl
                ON wtl.id_waiting_list = we.id_waiting_list
             WHERE we.id_episode = i_id_episode
               AND wtl.flg_status IN (pk_alert_constant.g_flg_status_a, 'I');
        
            IF l_count = 0
            THEN
                -- Delete records from GRID_TASK_* tables
                g_error := 'DELETE GRID_TASK DATA';
                pk_alertlog.log_debug(g_error);
            
                DELETE FROM grid_task_img gti
                 WHERE gti.id_episode = i_id_episode;
                DELETE FROM grid_task_lab gtl
                 WHERE gtl.id_episode = i_id_episode;
                DELETE FROM grid_task_oth_exm gto
                 WHERE gto.id_episode = i_id_episode;
                DELETE FROM grid_task gt
                 WHERE gt.id_episode = i_id_episode;
            
            END IF;
        
            -- Remove alerts for this episode
            g_error := 'REMOVE ALERTS';
            pk_alertlog.log_debug(g_error);
        
            l_ret := pk_alerts.delete_sys_alert_event_episode(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode,
                                                              i_delete  => 'Y',
                                                              o_error   => o_error);
        
            IF NOT l_ret
            THEN
                RAISE l_internal_exception;
            END IF;
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE l_internal_exception;
        END;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN l_internal_cancel_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CALL_CANCEL_EPISODE',
                                              o_error);
        
            pk_utils.undo_changes;
            IF i_goto_sch
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            END IF;
            RETURN FALSE;
        
        WHEN g_exception_int THEN
            DECLARE
                --Inicialization of object for input
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   l_msg,
                                   l_error_message,
                                   g_error,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CALL_CANCEL_EPISODE',
                                   l_msg,
                                   'U');
                -- execute error processing
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                -- return failure of function_dummy
                RETURN FALSE;
            END;
        
        WHEN l_internal_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CALL_CANCEL_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CALL_CANCEL_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END call_cancel_episode;

    /**Flash wrapper do not use otherwise */
    FUNCTION call_cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        i_cancel_type   IN VARCHAR2 DEFAULT 'E',
        i_dt_cancel     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_visit.call_cancel_episode(i_lang           => i_lang,
                                            i_id_episode     => i_id_episode,
                                            i_prof           => i_prof,
                                            i_cancel_reason  => i_cancel_reason,
                                            i_cancel_type    => i_cancel_type,
                                            i_dt_cancel      => nvl(i_dt_cancel, current_timestamp),
                                            i_transaction_id => NULL,
                                            i_goto_sch       => TRUE,
                                            o_error          => o_error);
    
    END call_cancel_episode;

    /*
    * Cancels an ambulatory episode (OUTP, PP, CARE, NUTRI).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_cancel_type     pk_visit.g_cancel_efectiv    - cancel patient registration (FLG_EHR = 'S')
    *                          pk_visit.g_cancel_sched_epis - cancel episode (FLG_STATUS = 'C')
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  LG
    * @version                  ??
    * @since                   2006/11/09
    */
    FUNCTION cancel_outp_pp_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_type    IN VARCHAR2 DEFAULT 'E',
        i_transaction_id IN VARCHAR2,
        i_goto_sch       IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status  epis_info.flg_status%TYPE;
        l_id_schedule schedule.id_schedule%TYPE;
        l_flg_ehr     episode.flg_ehr%TYPE;
        l_id_visit    visit.id_visit%TYPE;
        l_counter     NUMBER;
        l_message     VARCHAR2(400);
        l_msg_params  table_varchar;
    
        l_rowids_aux    table_varchar;
        l_rowids_m_u    table_varchar := table_varchar();
        l_rowids_mvs_u  table_varchar := table_varchar();
        l_rowids_mvsp_u table_varchar := table_varchar();
        l_error         VARCHAR2(2000);
        l_where_clause  VARCHAR2(1000);
    
        l_iip_where          VARCHAR2(200);
        l_iei_where          VARCHAR2(200);
        l_iip_rowids_upd     table_varchar;
        l_iei_rowids_upd     table_varchar;
        l_tab_out            table_varchar := table_varchar();
        l_rowid_tab          table_varchar := table_varchar();
        l_rowid_tab_dummy    table_varchar := table_varchar();
        l_where_clause_nurse VARCHAR2(4000);
        l_pat                visit.id_patient%TYPE;
        l_epis_type          epis_type.id_epis_type%TYPE;
    
        CURSOR c_analysis_req IS
            SELECT ard.id_analysis_req_det, ard.id_analysis_req
              FROM analysis_req_det ard, analysis_req ar
             WHERE ar.id_episode = i_id_episode
               AND ard.id_analysis_req = ar.id_analysis_req;
    
        CURSOR c_exam_req IS
            SELECT erd.id_exam_req_det, erd.id_exam_req, erd.id_exam
              FROM exam_req_det erd, exam_req er
             WHERE er.id_episode = i_id_episode
               AND erd.id_exam_req = er.id_exam_req;
    
        l_error_in t_error_in := t_error_in();
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        IF i_goto_sch
        THEN
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        END IF;
    
        g_sysdate_tstz := current_timestamp;
        -- which schedule belongs the episode?
        g_error := 'GET ID_SCHEDULE';
        BEGIN
            SELECT id_schedule, flg_status
              INTO l_id_schedule, l_flg_status
              FROM epis_info
             WHERE id_episode = i_id_episode;
        
            SELECT flg_ehr
              INTO l_flg_ehr
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN pk_alert_exceptions.process_error(i_lang,
                                                         SQLCODE,
                                                         SQLERRM,
                                                         g_error,
                                                         'ALERT',
                                                         'PK_VISIT',
                                                         'CANCEL_OUTP_PP_EPISODE',
                                                         o_error);
        END;
    
        IF l_flg_ehr = pk_ehr_access.g_flg_ehr_ehr
        THEN
            l_error := 'PK_VISIT.CANCEL_OUTP_PP_EPISODE -> Can''t cancel an EHR event';
        
            l_error_in.set_all(i_lang,
                               NULL,
                               l_error,
                               NULL,
                               'ALERT',
                               'PK_VISIT',
                               'CANCEL_OUTP_PP_EPISODE',
                               l_error,
                               'U');
        
            g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
        
            RETURN FALSE;
        END IF;
    
        IF (l_flg_status <> g_epis_info_efectiv AND l_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled)
        THEN
            l_message    := pk_message.get_message(i_lang, 'VISIT_M006');
            l_msg_params := table_varchar(pk_sysdomain.get_domain(g_domain_epis_info_flg_status, l_flg_status, i_lang));
        
            IF (pk_message.format(i_lang, l_message, l_msg_params, l_message, o_error))
            THEN
                l_error := l_message;
            
                l_error_in.set_all(i_lang,
                                   'VISIT_M006',
                                   l_error,
                                   NULL,
                                   'ALERT',
                                   'PK_VISIT',
                                   'CANCEL_OUTP_PP_EPISODE',
                                   l_error,
                                   'U');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END IF;
            RETURN FALSE;
        
        END IF;
    
        -- UPDATES IN TABLES WHERE EPISODE IS REFERED AS DESTINATION EPISODE
        -- update analysis_req
        g_error := 'UPDATE ANALYSIS_REQ DESTINATION';
        /* <DENORM Fbio> */
        ts_analysis_req.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                            id_episode_destination_nin => FALSE,
                            where_in                   => 'id_episode_destination = ' || i_id_episode,
                            rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ANALYSIS_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
        l_rowids_aux := table_varchar();
    
        -- update exam_req
        g_error := 'UPDATE EXAM_REQ DESTINATION';
        /* <DENORM Fbio> */
        ts_exam_req.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                        id_episode_destination_nin => FALSE,
                        where_in                   => 'id_episode_destination = ' || i_id_episode,
                        rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EXAM_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
        l_rowids_aux := table_varchar();
    
        -- update interv_prescription
        g_error := 'UPDATE INTERV_PRESCRIPTION DESTINATION';
        /* <DENORM Fbio> */
        ts_interv_prescription.upd(id_episode_destination_in  => CAST(NULL AS NUMBER),
                                   id_episode_destination_nin => FALSE,
                                   where_in                   => 'id_episode_destination = ' || i_id_episode,
                                   rows_out                   => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'INTERV_PRESCRIPTION',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE_DESTINATION'));
    
        -- update monitorization
        g_error := 'UPDATE MONITORIZATION DESTINATION';
        ts_monitorization.upd(id_episode_destination_in => NULL,
                              where_in                  => 'id_episode_destination = ' || i_id_episode,
                              rows_out                  => l_rowids_m_u);
    
        -- update cli_rec_req
        g_error := 'UPDATE CLI_REC_REQ DESTINATION';
        UPDATE cli_rec_req
           SET id_episode_destination = NULL
         WHERE id_episode_destination = i_id_episode;
    
        g_error := 'NO PATIENT FOUND FOR EPISODE = ' || i_id_episode;
        SELECT e.id_patient
          INTO l_pat
          FROM episode e, visit v
         WHERE e.id_visit = v.id_visit
           AND e.id_episode = i_id_episode;
    
        IF i_goto_sch
        THEN
            -- UPDATE SCHEDULE STATE
            g_error := 'UPDATE SCHEDULE_OUTP';
            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_id_schedule    => l_id_schedule,
                                                                       i_flg_state      => g_sched_scheduled,
                                                                       i_id_patient     => l_pat,
                                                                       i_transaction_id => l_transaction_id,
                                                                       o_error          => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END IF;
    
        -- CANCEL FROM TABLES WHERE EPISODE WAS USED WHEN CREATING THE VISIT
        -- update cli_rec_req_det
        g_error := 'UPDATE FROM CLI_REC_REQ_DET';
        UPDATE cli_rec_req_det
           SET flg_status = g_flg_status_c, dt_cancel_tstz = g_sysdate_tstz, id_prof_cancel = i_prof.id
         WHERE id_cli_rec_req IN (SELECT id_cli_rec_req
                                    FROM cli_rec_req
                                   WHERE id_episode = i_id_episode);
    
        -- update cli_rec_req
        g_error := 'UPDATE FROM CLI_REC_REQ';
        UPDATE cli_rec_req
           SET flg_status = g_flg_status_c, dt_cancel_tstz = current_timestamp, id_prof_cancel = i_prof.id
         WHERE id_episode = i_id_episode;
    
        -- update monitorization_vs_plan
        g_error        := 'UPDATE FROM MONITORIZATION_VS_PLAN';
        l_where_clause := 'id_monitorization_vs IN (';
        l_where_clause := l_where_clause ||
                          'SELECT id_monitorization_vs FROM monitorization_vs WHERE id_monitorization_vs IN (';
        l_where_clause := l_where_clause || 'SELECT id_monitorization FROM monitorization WHERE id_episode = ' ||
                          i_id_episode || '))';
        ts_monitorization_vs_plan.upd(flg_status_in => g_flg_status_c,
                                      where_in      => l_where_clause,
                                      rows_out      => l_rowids_mvsp_u);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MONITORIZATION_VS_PLAN',
                                      i_rowids     => l_rowids_mvsp_u,
                                      o_error      => o_error);
    
        -- update monitorization_vs
        g_error        := 'UPDATE FROM MONITORIZATION_VS';
        l_where_clause := 'id_monitorization IN (SELECT id_monitorization FROM monitorization WHERE id_episode = ' ||
                          i_id_episode || ')';
        ts_monitorization_vs.upd(flg_status_in     => g_flg_status_c,
                                 dt_cancel_tstz_in => g_sysdate_tstz,
                                 id_prof_cancel_in => i_prof.id,
                                 where_in          => l_where_clause,
                                 rows_out          => l_rowids_mvs_u);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MONITORIZATION_VS',
                                      i_rowids     => l_rowids_mvs_u,
                                      o_error      => o_error);
    
        -- update monitorization
        g_error := 'UPDATE FROM MONITORIZATION';
        ts_monitorization.upd(flg_status_in     => g_flg_status_c,
                              dt_cancel_tstz_in => g_sysdate_tstz,
                              id_prof_cancel_in => i_prof.id,
                              where_in          => 'id_episode = ' || i_id_episode,
                              rows_out          => l_rowids_m_u);
    
        -- update interv_presc_plan
        g_error := 'UPDATE FROM INTERV_PRESC_PLAN';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_interv_presc_plan.upd(flg_status_in      => g_flg_status_c,
                                 id_prof_cancel_in  => i_prof.id,
                                 id_prof_cancel_nin => FALSE,
                                 dt_cancel_tstz_in  => g_sysdate_tstz,
                                 dt_cancel_tstz_nin => FALSE,
                                 where_in           => 'id_interv_presc_det IN
               (SELECT id_interv_presc_det
                  FROM interv_presc_det
                 WHERE id_interv_prescription IN (SELECT id_interv_prescription
                                                    FROM interv_prescription
                                                   WHERE id_episode = ' ||
                                                       i_id_episode || '))',
                                 rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'INTERV_PRESC_PLAN',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        -- update interv_presc_det
        g_error := 'UPDATE FROM INTERV_PRESC_DET';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_interv_presc_det.upd(flg_status_in      => g_flg_status_c,
                                id_prof_cancel_in  => i_prof.id,
                                id_prof_cancel_nin => FALSE,
                                dt_cancel_tstz_in  => g_sysdate_tstz,
                                dt_cancel_tstz_nin => FALSE,
                                where_in           => 'id_interv_prescription IN (SELECT id_interv_prescription
                                            FROM interv_prescription
                                           WHERE id_episode = ' ||
                                                      i_id_episode || ')',
                                rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'INTERV_PRESC_DET',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        -- update interv_prescription
        g_error := 'UPDATE FROM INTERV_PRESCRIPTION';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_interv_prescription.upd(flg_status_in      => g_flg_status_c,
                                   id_prof_cancel_in  => i_prof.id,
                                   id_prof_cancel_nin => FALSE,
                                   dt_cancel_tstz_in  => g_sysdate_tstz,
                                   dt_cancel_tstz_nin => FALSE,
                                   where_in           => 'id_episode = ' || i_id_episode,
                                   rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'INTERV_PRESCRIPTION',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        -- <DENORM_JOSE_BRITO>
        -- update icnp_interv_plan
        l_iip_where := 'id_icnp_epis_interv IN (SELECT id_icnp_epis_interv FROM icnp_epis_intervention WHERE id_episode = ' ||
                       i_id_episode || ')';
    
        g_error := 'UPDATE FROM ICNP_INTERV_PLAN';
        ts_icnp_interv_plan.upd(flg_status_in     => g_flg_status_c,
                                dt_cancel_tstz_in => g_sysdate_tstz,
                                id_prof_cancel_in => i_prof.id,
                                where_in          => l_iip_where,
                                rows_out          => l_iip_rowids_upd);
    
        -- update icnp_epis_intervention
        l_iei_where := 'id_episode = ' || i_id_episode;
    
        g_error := 'UPDATE FROM ICNP_EPIS_INTERVENTION';
        ts_icnp_epis_intervention.upd(flg_status_in    => g_flg_status_c,
                                      dt_close_tstz_in => g_sysdate_tstz,
                                      id_prof_close_in => i_prof.id,
                                      where_in         => l_iei_where,
                                      rows_out         => l_iei_rowids_upd);
        -- </DENORM_JOSE_BRITO>
    
        -- update exam_req_det
        g_error := 'UPDATE FROM EXAM_REQ_DET';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_exam_req_det.upd(flg_status_in      => g_flg_status_c,
                            id_prof_cancel_in  => i_prof.id,
                            id_prof_cancel_nin => FALSE,
                            dt_cancel_tstz_in  => g_sysdate_tstz,
                            dt_cancel_tstz_nin => FALSE,
                            where_in           => 'id_exam_req IN (SELECT id_exam_req
                                 FROM exam_req
                                WHERE id_episode = ' || i_id_episode || ')',
                            rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EXAM_REQ_DET',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        --update task dependency state for cancel action and TDE process the affected dependencies (if any)
        FOR rec IN (SELECT id_exam_req_det
                      FROM exam_req_det erd
                     WHERE erd.rowid IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                           FROM TABLE(l_rowids_aux) t)
                       AND erd.id_task_dependency IS NOT NULL)
        LOOP
        
            g_error := 'Call pk_exams_external_api_db.update_tde_task_state';
            IF NOT pk_exams_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_exam_req_det => rec.id_exam_req_det,
                                                                  i_flg_action   => g_flg_status_c,
                                                                  o_error        => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END LOOP;
    
        -- update exam_req
        g_error := 'UPDATE FROM EXAM_REQ';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_exam_req.upd(flg_status_in      => g_flg_status_c,
                        id_prof_cancel_in  => i_prof.id,
                        id_prof_cancel_nin => FALSE,
                        dt_cancel_tstz_in  => g_sysdate_tstz,
                        dt_cancel_tstz_nin => FALSE,
                        where_in           => 'id_episode = ' || i_id_episode,
                        rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EXAM_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        FOR r_exam_req IN c_exam_req
        LOOP
        
            g_error := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
            IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_patient      => NULL,
                                                      i_episode      => i_id_episode,
                                                      i_exam_req     => r_exam_req.id_exam_req,
                                                      i_exam_req_det => r_exam_req.id_exam_req_det,
                                                      o_error        => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END LOOP;
    
        ---------------------------------------------------
        g_error := 'CALL TO pk_api_pfh_in.set_cancel_presc';
        IF NOT pk_api_pfh_in.set_cancel_presc(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              o_error      => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        -- update analysis_req_det
        g_error := 'UPDATE FROM ANALYSIS_REQ_DET';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_analysis_req_det.upd(flg_status_in      => g_flg_status_c,
                                id_prof_cancel_in  => i_prof.id,
                                id_prof_cancel_nin => FALSE,
                                dt_cancel_tstz_in  => g_sysdate_tstz,
                                dt_cancel_tstz_nin => FALSE,
                                where_in           => 'id_analysis_req IN (SELECT id_analysis_req
                                     FROM analysis_req
                                    WHERE id_episode = ' ||
                                                      i_id_episode || ')',
                                rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ANALYSIS_REQ_DET',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        FOR rec IN (SELECT ard.id_analysis_req_det
                      FROM analysis_req_det ard
                     WHERE ard.rowid IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                           FROM TABLE(l_rowids_aux) t)
                       AND ard.id_task_dependency IS NOT NULL)
        LOOP
            g_error := 'Call pk_lab_tests_external_api_db.update_tde_task_state';
            IF NOT pk_lab_tests_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_lab_test_req => rec.id_analysis_req_det,
                                                                      i_flg_action   => pk_alert_constant.g_analysis_det_canc,
                                                                      o_error        => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END LOOP;
    
        -- update analysis_req
        g_error := 'UPDATE FROM ANALYSIS_REQ';
        /* <DENORM Fbio> */
        l_rowids_aux := table_varchar();
        ts_analysis_req.upd(flg_status_in      => g_flg_status_c,
                            id_prof_cancel_in  => i_prof.id,
                            id_prof_cancel_nin => FALSE,
                            dt_cancel_tstz_in  => g_sysdate_tstz,
                            dt_cancel_tstz_nin => FALSE,
                            where_in           => 'id_episode = ' || i_id_episode,
                            rows_out           => l_rowids_aux);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ANALYSIS_REQ',
                                      i_rowids       => l_rowids_aux,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
    
        g_error := 'SELECT FROM ANALYSIS_REQ_DET';
    
        FOR r_analysis_req IN c_analysis_req
        LOOP
        
            g_error := 'PK_LAB_TECH.SET_LAB_TEST_GRID_TASK';
            IF NOT pk_lab_tech.set_lab_test_grid_task(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_patient          => NULL,
                                                      i_episode          => i_id_episode,
                                                      i_analysis_req     => r_analysis_req.id_analysis_req,
                                                      i_analysis_req_det => r_analysis_req.id_analysis_req_det,
                                                      o_error            => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        END LOOP;
    
        -- update epis_doc_template
        g_error := 'UPDATE FROP EPIS_DOC_TEMPLATE';
        UPDATE epis_doc_template
           SET dt_cancel = g_sysdate_tstz, id_prof_cancel = i_prof.id
         WHERE id_episode = i_id_episode;
    
        -- update epis_health_plan
    
        -- update epis_info, does not have canceled status
        g_error := 'UPDATE EPIS_INFO';
    
        -- update epis_institution
    
        -- find visit id
        g_error := 'FIND VISIT ID';
        SELECT id_visit, id_epis_type
          INTO l_id_visit, l_epis_type
          FROM episode e
         WHERE id_episode = i_id_episode;
    
        -- update episode
        l_rowids_aux := table_varchar();
    
        IF i_cancel_type = g_cancel_efectiv
           OR i_cancel_type IS NULL
           OR l_epis_type IN (pk_alert_constant.g_epis_type_psychologist,
                              pk_alert_constant.g_epis_type_resp_therapist,
                              pk_alert_constant.g_epis_type_dietitian,
                              pk_alert_constant.g_epis_type_social,
                              pk_alert_constant.g_epis_type_cdc_appointment)
        THEN
        
            --we dont cancel de episode, we put the episode not registered
            g_error := 'CALL ts_episode.upd I';
            ts_episode.upd(id_episode_in => i_id_episode,
                           flg_ehr_in    => g_flg_ehr_s,
                           flg_ehr_nin   => FALSE,
                           rows_out      => l_rowids_aux);
            g_error := 'CALL t_data_gov_mnt.process_update I';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids_aux,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_EHR'));
        ELSIF i_cancel_type = g_cancel_sched_epis
        THEN
            g_error := 'CALL ts_episode.upd II';
            ts_episode.upd(id_episode_in          => i_id_episode,
                           flg_status_in          => g_flg_status_c,
                           flg_status_nin         => FALSE,
                           dt_cancel_tstz_in      => g_sysdate_tstz,
                           dt_cancel_tstz_nin     => FALSE,
                           id_prof_cancel_in      => i_prof.id,
                           id_prof_cancel_nin     => FALSE,
                           desc_cancel_reason_in  => i_cancel_reason,
                           desc_cancel_reason_nin => FALSE,
                           flg_cancel_type_in     => i_cancel_type,
                           flg_cancel_type_nin    => FALSE,
                           rows_out               => l_rowids_aux);
            g_error := 'CALL t_data_gov_mnt.process_update II';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPISODE',
                                          i_rowids       => l_rowids_aux,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'DT_CANCEL_TSTZ',
                                                                          'ID_PROF_CANCEL'));
        END IF;
    
        -- visit has more episodes?
        g_error := 'COUNT VISIT EPISODES';
        SELECT COUNT(*)
          INTO l_counter
          FROM episode
         WHERE id_visit = l_id_visit;
    
        IF (l_counter = 0)
        THEN
            -- update visit
            g_error      := 'UPDATE FROM VISIT / ID_VISIT=' || l_id_visit;
            l_rowids_aux := table_varchar();
            ts_visit.upd(id_visit_in     => l_id_visit,
                         flg_status_in   => g_flg_status_i,
                         flg_status_nin  => FALSE,
                         dt_end_tstz_in  => current_timestamp,
                         dt_end_tstz_nin => FALSE,
                         rows_out        => l_rowids_aux);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rowids_aux,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        
            --g_error := 'UPDATE FROM VISIT';
            --UPDATE visit
            --   SET flg_status = g_flg_status_i, dt_end_tstz = current_timestamp
            -- WHERE id_visit = l_id_visit;
        END IF;
    
        -- Alert Data Governance
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'MONITORIZATION',
                                      i_rowids     => l_rowids_m_u,
                                      o_error      => o_error);
    
        -- <DENORM_JOSE_BRITO>
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - ICNP_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids     => SET(l_iei_rowids_upd),
                                      o_error      => o_error);
    
        pk_episode.update_mv_episodes_temp(i_lang => i_lang, i_prof => i_prof);
    
        IF i_goto_sch
           AND i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CANCEL_OUTP_PP_EPISODE',
                                              o_error);
        
            pk_utils.undo_changes;
            IF i_goto_sch
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            END IF;
            RETURN FALSE;
    END cancel_outp_pp_episode;

    /** Flash wrapper do no use otherwise */
    FUNCTION cancel_outp_pp_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        i_cancel_type IN VARCHAR2 DEFAULT 'E',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN cancel_outp_pp_episode(i_lang           => i_lang,
                                      i_id_episode     => i_id_episode,
                                      i_prof           => i_prof,
                                      i_cancel_type    => i_cancel_type,
                                      i_transaction_id => NULL,
                                      i_goto_sch       => TRUE,
                                      o_error          => o_error);
    
    END cancel_outp_pp_episode;

    /******************************************************************************
    * Used by Private Practice and Outpatient.
    *
    ******************************************************************************/
    FUNCTION cancel_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception_ext EXCEPTION;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        -- Jos Brito 17/06/2008 Usar a funo genrica de cancelamento
        IF NOT call_cancel_episode(i_lang           => i_lang,
                                   i_id_episode     => i_id_episode,
                                   i_prof           => i_prof,
                                   i_cancel_reason  => NULL,
                                   i_cancel_type    => NULL,
                                   i_transaction_id => l_transaction_id,
                                   o_error          => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'CANCEL_EPISODE');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            
            END;
        
    END;
    --
    /**********************************************************************************************
    * Reabrir um episdio de Urgncia ou de Internamento
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param i_flg_reopen             'Y' - Prentende reabrir, mas ainda no foi confirmado
                                      'N' - Confirma a reabertura do episdio
    * @param o_flg_show               Flag: Y - existe msg para mostrar; N -  existe
    * @param o_msg                    Mensagem a mostrar
    * @param o_msg_title              Ttulo da mensagem
    * @param o_button                 Botes a mostrar: N - no, R - lido, C - confirmado
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2007/01/20
    **********************************************************************************************/
    FUNCTION set_reopen_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis    IN episode.id_episode%TYPE,
        i_flg_reopen IN VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret                BOOLEAN;
        l_char               VARCHAR2(1);
        l_id_patient         patient.id_patient%TYPE;
        l_dt_admin           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_med             TIMESTAMP WITH LOCAL TIME ZONE;
        l_last_epis          episode.id_episode%TYPE;
        l_next               epis_readmission.id_epis_readmission%TYPE;
        l_reopen_timeout     sys_config.value%TYPE;
        l_can_reopen_epis    VARCHAR2(1);
        l_flg_reopen_at      VARCHAR2(1);
        l_epis_type          epis_type.id_epis_type%TYPE;
        l_id_discharge       discharge.id_discharge%TYPE;
        l_id_print_list_jobs table_number := table_number();
    
        l_cancel_print_jobs_excpt EXCEPTION;
        err_disposition           EXCEPTION;
        err_check                 EXCEPTION;
    
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
        l_rows    table_varchar;
        l_rows_ei table_varchar;
        --
        CURSOR c_prof_func(l_func_reopen IN sys_config.value%TYPE) IS
            SELECT 'X'
              FROM prof_func
             WHERE id_professional = i_prof.id
               AND id_institution = i_prof.institution
               AND id_functionality = l_func_reopen;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_patient IS
            SELECT e.id_patient, e.id_epis_type --v.id_patient
              FROM episode e --, visit v
             WHERE e.id_episode = i_id_epis;
        --AND e.id_visit = v.id_visit;
    
        CURSOR c_discharge IS
            SELECT pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, flg_status_adm, dt_admin_tstz) dt_admin_tstz,
                   dt_med_tstz,
                   id_discharge
              FROM discharge
             WHERE id_episode = i_id_epis
               AND flg_status = g_disch_active;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        o_flg_show := 'N';
        o_button   := 'NCR';
        --
        g_error       := 'GET CONFIGURATIONS';
        g_func_reopen := pk_sysconfig.get_config('FUNCTIONALITY_REOPEN', i_prof);
        --SYS_CONFIG
        -- Verificar se o profissional pode reabrir o episdio
        --
        g_error := 'OPEN C_PROF_FUNC';
        OPEN c_prof_func(g_func_reopen);
        FETCH c_prof_func
            INTO l_char;
        g_found := c_prof_func%FOUND;
        CLOSE c_prof_func;
        --
        IF g_found
        THEN
            -- PODE REABRIR EPISDIO
            --
            IF i_flg_reopen = g_reopen
            THEN
                g_error := 'OPEN C_PATIENT';
                OPEN c_patient;
                FETCH c_patient
                    INTO l_id_patient, l_epis_type;
                CLOSE c_patient;
                --
                -- Data administrativa do episdio a reabrir
                --
                g_error := 'C_DISCHARGE';
                OPEN c_discharge;
                FETCH c_discharge
                    INTO l_dt_admin, l_dt_med, l_id_discharge;
                CLOSE c_discharge;
                --
                l_reopen_timeout := pk_sysconfig.get_config('EPISODE_REOPEN_TIMEOUT', i_prof);
                --
                -- Qual o ltimo episdio do paciente
                --
                g_error := 'GET LAST EPISODE';
                IF NOT pk_episode.get_last_episode(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_patient      => l_id_patient,
                                                   o_last_episode => l_last_epis,
                                                   o_flg_reopen   => l_can_reopen_epis,
                                                   o_epis_type    => l_id_epis_type,
                                                   o_error        => o_error)
                THEN
                    RAISE err_check;
                END IF;
            
                --adicional validation to the Activity Therapist
                IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
                THEN
                    g_error := 'CALL pk_activity_therapist.check_reopen_episode for episode: ' || i_id_epis;
                    IF NOT pk_activity_therapist.check_reopen_episode(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_episode    => i_id_epis,
                                                                      o_flg_reopen => l_flg_reopen_at,
                                                                      o_error      => o_error)
                    THEN
                        RAISE err_check;
                    END IF;
                
                    IF (l_flg_reopen_at = pk_alert_constant.g_yes)
                    THEN
                        o_flg_show  := 'Y';
                        o_msg_title := pk_message.get_message(i_lang, 'COMMON_T059');
                        o_msg       := pk_message.get_message(i_lang, 'VISIT_M007'); -- PODE REABRIR
                        o_button    := 'NCR';
                    ELSE
                        o_flg_show  := 'Y';
                        o_msg_title := pk_message.get_message(i_lang, 'COMMON_T058');
                        o_msg       := pk_message.get_message(i_lang, 'VISIT_M008'); -- NaO PODE REABRIR
                        o_button    := 'NC';
                    END IF;
                
                ELSE
                
                    IF l_last_epis = i_id_epis
                       AND l_can_reopen_epis = 'Y'
                       AND g_sysdate_tstz < (nvl(l_dt_admin, l_dt_med) + numtodsinterval(l_reopen_timeout / 24, 'DAY'))
                    THEN
                        --
                        o_flg_show  := 'Y';
                        o_msg_title := pk_message.get_message(i_lang, 'COMMON_T059');
                        o_msg       := pk_message.get_message(i_lang, 'VISIT_M007'); -- PODE REABRIR
                        o_button    := 'NCR';
                    ELSE
                        o_flg_show  := 'Y';
                        o_msg_title := pk_message.get_message(i_lang, 'COMMON_T058');
                        o_msg       := pk_message.get_message(i_lang, 'VISIT_M008'); -- NO PODE REABRIR
                        o_button    := 'NC';
                    END IF;
                END IF;
            
            ELSE
                -- REABRIR EPISDIO
                ---- Episdio = ACTIVO
                ---- Alta(Discharge) = REABERTO
                ---- Insert EPIS_READMISSION
                /* <DENORM Fbio> */
                g_error := 'UPDATE EPISODE';
                ts_episode.upd(flg_status_in => g_epis_active, flg_status_nin => FALSE, dt_end_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_end_tstz_nin => FALSE, id_episode_in => i_id_epis, rows_out => l_rows);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
                --
                g_error := 'UPDATE VISIT';
                l_rows  := table_varchar();
                ts_visit.upd(flg_status_in   => g_epis_active,
                             flg_status_nin  => FALSE,
                             dt_end_tstz_in  => NULL,
                             dt_end_tstz_nin => FALSE,
                             where_in        => 'id_visit IN (SELECT epis.id_visit
																FROM episode epis
															 WHERE epis.id_episode = ' || i_id_epis || ')',
                             rows_out        => l_rows);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'VISIT',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
            
                --g_error := 'UPDATE VISIT';
                --UPDATE visit
                --   SET flg_status = g_epis_active, dt_end_tstz = NULL
                -- WHERE id_visit IN (SELECT epis.id_visit
                --                      FROM episode epis
                --                     WHERE epis.id_episode = i_id_epis);
            
                --
                g_error := 'OPEN C_PATIENT';
                OPEN c_patient;
                FETCH c_patient
                    INTO l_id_patient, l_epis_type;
                CLOSE c_patient;
            
                g_error := 'C_DISCHARGE';
                OPEN c_discharge;
                FETCH c_discharge
                    INTO l_dt_admin, l_dt_med, l_id_discharge;
                CLOSE c_discharge;
            
                IF (NOT (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type AND l_id_discharge IS NULL))
                THEN
                    g_error := 'REopen disposition';
                    l_ret   := pk_disposition.set_reopen_disposition(i_lang, i_prof, i_id_epis, o_error);
                    IF l_ret = FALSE
                    THEN
                        RAISE err_disposition;
                    END IF;
                END IF;
            
                g_error := 'UPDATE DISCHARGE';
                pk_alertlog.log_debug(g_error);
                UPDATE discharge
                   SET flg_status = g_disch_reopen, flg_status_adm = decode(flg_status_adm, NULL, NULL, g_disch_reopen)
                 WHERE id_episode = i_id_epis
                   AND flg_status = g_disch_active;
            
                g_error := 'CALL TO REMOVE ALL EXISTING PRINT JOBS IN THE PRINTING LIST';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_discharge.cancel_disch_print_jobs(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_patient            => l_id_patient,
                                                            i_episode            => i_id_epis,
                                                            o_id_print_list_jobs => l_id_print_list_jobs,
                                                            o_error              => o_error)
                THEN
                    RAISE l_cancel_print_jobs_excpt;
                END IF;
            
                g_error := 'CALL TO TS_EPIS_INFO.UPD';
                pk_alertlog.log_debug(g_error);
                ts_epis_info.upd(id_episode_in      => i_id_epis,
                                 flg_status_in      => g_epis_active,
                                 flg_dsch_status_in => g_disch_reopen,
                                 rows_out           => l_rows_ei);
            
                g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_INFO',
                                              i_rowids       => l_rows_ei,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_DSCH_STATUS', 'FLG_STATUS'));
                --
                g_error := 'GET SEQ_EPIS_READMISSION.NEXTVAL';
                pk_alertlog.log_debug(g_error);
                SELECT seq_epis_readmission.nextval
                  INTO l_next
                  FROM dual;
                --
                g_error := 'INSERT EPIS_READMISSION';
                INSERT INTO epis_readmission
                    (id_epis_readmission, id_episode, dt_begin_tstz, dt_end_tstz, id_professional)
                VALUES
                    (l_next, i_id_epis, g_sysdate_tstz, nvl(l_dt_admin, l_dt_med), i_prof.id);
            
                g_error := 'pk_patient_tracking.set_auto_reopen_status';
                IF NOT pk_patient_tracking.set_auto_reopen_status(i_lang, i_prof, i_id_epis, o_error)
                THEN
                    RAISE err_disposition;
                END IF;
            
                --
                -- LMAIA 02-07-2009 (Task Timeline functionality)
                -- When there is an episode reopen it is necessary re-populate tasks in easy access table TASK_TIMELINE_EA
                -- If table DISCHARGE start using database framework, it is possible make this function call automatic
                g_error := 'POPULATE TASKS IN TASK_TIMELINE_EA';
                IF NOT pk_ea_logic_tasktimeline.reopen_epis_tl_tasks(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_id_episode => i_id_epis,
                                                                     o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                -- in the activity therapy episodes the request state should be changed to the state undergoing
                IF (l_epis_type = pk_act_therap_constant.g_activ_therap_epis_type)
                THEN
                    g_error := 'CALL update_request_state for id_episode: ' || i_id_epis;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_activity_therapist.update_request_state(i_lang          => i_lang,
                                                                      i_prof          => i_prof,
                                                                      i_id_episode_at => i_id_epis,
                                                                      i_from_states   => table_varchar(pk_opinion.g_opinion_over),
                                                                      i_to_state      => pk_opinion.g_opinion_accepted,
                                                                      o_error         => o_error)
                    THEN
                        RAISE err_check;
                    END IF;
                END IF;
            
            END IF;
        
        ELSE
            IF i_flg_reopen = g_reopen
            THEN
                o_msg_title := pk_message.get_message(i_lang, 'COMMON_T058');
                o_flg_show  := 'Y';
                o_msg       := pk_message.get_message(i_lang, 'VISIT_M008'); -- NO PODE REABRIR sys_message
                o_button    := 'NC';
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_cancel_print_jobs_excpt THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN err_disposition THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_REOPEN_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_REOPEN_EPIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    FUNCTION set_epis_prof_rec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN epis_prof_rec.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception_ext EXCEPTION;
    BEGIN
    
        IF NOT call_set_epis_prof_rec(i_lang     => i_lang,
                                      i_prof     => i_prof,
                                      i_episode  => i_episode,
                                      i_patient  => i_patient,
                                      i_flg_type => i_flg_type,
                                      o_error    => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'SET_EPIS_PROF_REC');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;

    -- Jos Brito 29/08/2008 Criada para evitar ROLLBACK/COMMIT na interaco com a funo de cancelamento de episdios
    FUNCTION call_set_epis_prof_rec
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN epis_prof_rec.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Insere actualiza a data do ltimo registo que o profissional efectuou
                          no episdio
           PARAMETROS:  Entrada: I_LANG - Lngua registada como preferncia do profissional
                                 I_PROF - ID do profissional, instituio e software
                I_EPISODE - Id do episdio
             I_PATIENT - ID do paciente
                                 I_FLG_TYPE - Tipo de registo. Valores possveis: R- Registo
               Saida: O_ERROR - Erro
        
          CRIAO: RB 2007/02/01
          NOTAS:
        *********************************************************************************/
        l_id_epis_prof_rec epis_prof_rec.id_epis_prof_rec%TYPE;
    
        CURSOR c_prof IS
            SELECT id_epis_prof_rec
              FROM epis_prof_rec
             WHERE id_episode = i_episode
               AND id_professional = i_prof.id
               AND nvl(flg_type, g_flg_type_rec) = i_flg_type;
    
    BEGIN
        --Verifica se j existe registo para este profissional
        g_error := 'OPEN C_PROF';
        OPEN c_prof;
        FETCH c_prof
            INTO l_id_epis_prof_rec;
        g_found := c_prof%FOUND;
        CLOSE c_prof;
    
        --Se j existe registo, actualiza a data da ltima modificao, seno insere um novo registo
        IF g_found
        THEN
            g_error := 'UPDATE DT_LAST_REC';
            UPDATE epis_prof_rec
               SET dt_last_rec_tstz = current_timestamp
             WHERE id_epis_prof_rec = l_id_epis_prof_rec;
        ELSE
            g_error := 'INSERT EPIS_PROF_REC';
            INSERT INTO epis_prof_rec
                (id_epis_prof_rec, id_episode, id_professional, id_patient, flg_type, dt_last_rec_tstz)
            VALUES
                (seq_epis_prof_rec.nextval, i_episode, i_prof.id, i_patient, i_flg_type, current_timestamp);
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_VISIT', 'CALL_SET_EPIS_PROF_REC');
            
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            
            END;
        
    END;
    --
    /********************************************************************************************
    * Sets the professional dep_clin_serv associated with a given episode.
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID
    * @param o_error                      Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Jos Silva
    * @version                            1.0
    * @since                              05-06-2008
    **********************************************************************************************/
    FUNCTION set_epis_prof_dcs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_prof_dsc      dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_prof IS
            SELECT eps.id_dep_clin_serv
              FROM epis_prof_dcs eps
             WHERE id_episode = i_episode
               AND id_professional = i_prof.id
             ORDER BY eps.dt_reg DESC;
    
    BEGIN
    
        g_error := 'OPEN C_PROF';
        OPEN c_prof;
        FETCH c_prof
            INTO l_id_dep_clin_serv;
        g_found := c_prof%FOUND;
        CLOSE c_prof;
    
        g_error       := 'GET PROF SPEC';
        l_id_prof_dsc := pk_prof_utils.get_prof_dcs(i_prof);
    
        IF l_id_prof_dsc IS NOT NULL
           AND (NOT g_found OR l_id_prof_dsc <> l_id_dep_clin_serv)
        THEN
            g_error := 'INSERT EPIS_PROF_DCS';
            INSERT INTO epis_prof_dcs
                (id_professional, id_episode, dt_reg, id_dep_clin_serv)
            VALUES
                (i_prof.id, i_episode, current_timestamp, l_id_prof_dsc);
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_EPIS_PROF_DCS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_prof_dcs;
    --
    /******************************************************************************
    * This function is for exclusive internal use by the database. It checks
    * if an episode can be cancelled:
    * 1) Registrars can cancel all types of episode within ALERT ADT.
    * 2) Physician's and nurses can only cancel TEMPORARY EPISODES of their responsability.
    *
    * @param i_lang            Professional prefered language
    * @param i_prof            Professional information
    * @param i_episode         Episode ID
    *
    * @return                  Y if episode can be cancelled, N otherwise
    *
    * @author                  Jos Brito
    * @version                 0.1
    * @since                   2008-04-15
    *
    ******************************************************************************/
    FUNCTION check_flg_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_unknown           epis_info.flg_unknown%TYPE;
        l_cancel_epis           VARCHAR2(1);
        l_cancel_temp_epis      VARCHAR2(1);
        l_cancel_epis_first_obs VARCHAR2(1);
        l_check_adt             VARCHAR2(1);
        l_hand_off_type         sys_config.value%TYPE;
        l_first_obs             epis_info.dt_first_obs_tstz%TYPE;
        l_first_n_obs           epis_info.dt_first_nurse_obs_tstz%TYPE;
        l_flg_status            episode.flg_status%TYPE;
        l_prof_cat              category.flg_type%TYPE;
        l_disch_count           NUMBER(6);
        --
        --ALERT-160739 - Ability to configure the option to cancel an A and E admission
        l_cfg_cancel_def_epis CONSTANT sys_config.id_sys_config%TYPE := 'CANCEL_DEFINITIVE_EPISODE';
        l_cancel_def_epis sys_config.value%TYPE;
        l_can_cancel      VARCHAR2(1 CHAR);
    BEGIN
    
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
    
        IF l_can_cancel = g_no
        THEN
            RETURN g_no;
        END IF;
    
        -- Check if definitive episodes can be cancelled
        l_cancel_epis := pk_sysconfig.get_config(i_code_cf => 'CANCEL_EPISODES', i_prof => i_prof);
        -- Check if the cancellation of temporary episodes is allowed
        l_cancel_temp_epis := pk_sysconfig.get_config(i_code_cf => 'CANCEL_TEMPORARY_EPISODES', i_prof => i_prof);
        -- Check if the cancellation of episodes with registered clinical info is allowed
        l_cancel_epis_first_obs := pk_sysconfig.get_config(i_code_cf => 'CANCEL_EPISODES_WITH_FIRST_OBS',
                                                           i_prof    => i_prof);
        -- Type of hand-off
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        BEGIN
            -- Check if it's a temporary (FLG_UNKNOWN = 'Y') or definitive episode (FLG_UNKNOWN = 'N');
            SELECT ei.flg_unknown, ei.dt_first_obs_tstz, ei.dt_first_nurse_obs_tstz
              INTO l_flg_unknown, l_first_obs, l_first_n_obs
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
            -- Get the status of the episode. Only ACTIVE episodes can be cancelled.
            SELECT e.flg_status
              INTO l_flg_status
              FROM episode e
             WHERE e.id_episode = i_episode;
            -- Get professional category
            SELECT c.flg_type
              INTO l_prof_cat
              FROM prof_cat p, category c
             WHERE p.id_category = c.id_category
               AND p.id_professional = i_prof.id
               AND p.id_institution = i_prof.institution;
            -- Check if episode is currently discharged
            SELECT COUNT(*)
              INTO l_disch_count
              FROM discharge d
             WHERE d.flg_status NOT IN (g_flg_status_c)
               AND d.id_episode = i_episode;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN g_no;
        END;
    
        -- Temporary episodes can be cancelled if are in active state and:
        -- 1) Are in active state;
        -- 2) Have no current active, reopened or pending discharge;
        -- 3.1) If have no registered clinical info, or...;
        -- 3.2) If institution allows cancellation of episodes with registered clinical info;
        IF l_flg_unknown = g_unknown
           AND l_cancel_temp_epis = g_yes
           AND l_flg_status = g_epis_active
           AND l_disch_count = 0
           AND ((l_first_obs IS NULL AND l_first_n_obs IS NULL) OR l_cancel_epis_first_obs = g_yes)
        THEN
            -- Physicians and nurses can only cancel episodes under their responsability.
            IF l_prof_cat IN (g_cat_type_doc, g_cat_type_nurse)
            THEN
            
                IF pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    i_episode,
                                                                                    l_prof_cat,
                                                                                    l_hand_off_type),
                                                i_prof.id) != -1
                THEN
                    RETURN g_yes;
                ELSE
                    RETURN g_no;
                END IF;
            
            ELSIF l_prof_cat = g_cat_type_reg
            THEN
                RETURN g_yes;
            ELSE
                RETURN g_no;
            END IF;
        
            -- Definitive episodes can only be cancelled by registrars, through ALERT ADT.
        ELSIF l_flg_unknown = g_definitive
              AND l_cancel_epis = g_yes
              AND l_prof_cat = g_cat_type_reg
              AND l_flg_status = g_epis_active
              AND l_disch_count = 0
              AND ((l_first_obs IS NULL AND l_first_n_obs IS NULL) OR l_cancel_epis_first_obs = g_yes)
        THEN
            --ALERT-160739 - Ability to configure the option to cancel an A and E admission
            l_cancel_def_epis := pk_sysconfig.get_config(i_code_cf => l_cfg_cancel_def_epis, i_prof => i_prof);
        
            IF l_cancel_def_epis = pk_alert_constant.g_yes
            THEN
                RETURN g_yes;
            ELSE
                -- Check if ALERT ADT is available.
                l_check_adt := pk_sysconfig.get_config(i_code_cf => 'CHECK_ALERT_ADT', i_prof => i_prof);
            
                IF l_check_adt = g_yes
                THEN
                    RETURN g_yes;
                ELSE
                    RETURN g_no;
                END IF;
            END IF;
        ELSE
            RETURN g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END;

    /***********************************************************************************************************
    *  Esta funo verifica se o episodio ja tem data de inicio
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_episode            ID do episodio
    * @param      i_prof               ID do profissional
    * @param      i_pat                ID do paciente
    * @param      o_msg_title - Ttulo da msg a mostrar ao utilizador, caso
    * @param      o_flg_show = Y
    * @param      o_msg - Texto da msg a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param      o_button - Botes a mostrar: N - no, R - lido, C - confirmado. Tb pode mostrar combinaes destes, qd  p/ mostrar + do q 1 boto
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since
    ***********************************************************************************************************/

    FUNCTION check_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        i_pat        IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_text   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_dt_begin   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg           VARCHAR2(2000);
        l_dt_init       VARCHAR2(200);
        l_exist_dt_init VARCHAR2(200);
    
        l_msg_type VARCHAR2(2000);
        l_exception_ext EXCEPTION;
    
        l_prof_cat            category.flg_type%TYPE;
        l_epis_type           epis_type.id_epis_type%TYPE;
        l_check_functionality VARCHAR2(1 CHAR);
        l_dt_first_obs        epis_info.dt_first_obs_tstz%TYPE;
        l_sp_flg_state        schedule_outp.flg_state%TYPE;
        k_flg_no_show         schedule_outp.flg_state%TYPE := 'B';
        l_dt_first_nur_obs    epis_info.dt_first_nurse_obs_tstz%TYPE;
        l_flg_ehr             episode.flg_ehr%TYPE;
    BEGIN
        o_flg_show := 'N';
    
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        --Only applicable to AMB
        IF (i_prof.software NOT IN (pk_alert_constant.g_soft_outpatient,
                                    pk_alert_constant.g_soft_primary_care,
                                    pk_alert_constant.g_soft_private_practice,
                                    pk_alert_constant.g_soft_nutritionist,
                                    pk_alert_constant.g_soft_social,
                                    pk_alert_constant.g_soft_rehab,
                                    pk_alert_constant.g_soft_psychologist,
                                    pk_alert_constant.g_soft_resptherap,
                                    pk_alert_constant.g_soft_home_care) OR
           (l_prof_cat NOT IN (pk_alert_constant.g_cat_type_doc,
                                pk_alert_constant.g_cat_type_nurse,
                                pk_alert_constant.g_cat_type_nutritionist,
                                pk_alert_constant.g_cat_type_social,
                                pk_alert_constant.g_cat_type_coordinator,
                                pk_alert_constant.g_cat_type_pharmacist,
                                pk_alert_constant.g_cat_type_psychologist,
                                pk_alert_constant.g_cat_type_technician,
                                pk_alert_constant.g_cat_type_cdc,
                                pk_alert_constant.g_cat_type_physiotherapist)) OR
           l_check_functionality = pk_alert_constant.g_yes)
        THEN
            RETURN TRUE;
        END IF;
    
        IF i_id_episode IS NOT NULL
        THEN
        
            IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                            i_id_epis   => i_id_episode,
                                            o_epis_type => l_epis_type,
                                            o_error     => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        
            g_epis_type_nurse := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        
            IF ((l_epis_type = g_epis_type_nurse AND l_prof_cat = pk_alert_constant.g_cat_type_doc) OR
               (l_epis_type IN (pk_alert_constant.g_epis_type_primary_care,
                                 pk_alert_constant.g_epis_type_outpatient,
                                 pk_alert_constant.g_epis_type_private_practice,
                                 pk_alert_constant.g_epis_type_emergency,
                                 pk_alert_constant.g_epis_type_inpatient,
                                 pk_alert_constant.g_epis_type_operating) AND
               l_prof_cat <> pk_alert_constant.g_cat_type_doc) OR
               (l_epis_type = pk_alert_constant.g_epis_type_home_health_care AND
               l_prof_cat NOT IN (pk_alert_constant.g_cat_type_doc,
                                    pk_alert_constant.g_cat_type_nurse,
                                    pk_alert_constant.g_cat_type_nutritionist,
                                    pk_alert_constant.g_cat_type_social,
                                    pk_alert_constant.g_cat_type_coordinator,
                                    pk_alert_constant.g_cat_type_physiotherapist,
                                    pk_alert_constant.g_cat_type_psychologist,
                                    pk_alert_constant.g_cat_type_technician,
                                    pk_alert_constant.g_cat_type_cdc)))
            THEN
                RETURN TRUE;
            END IF;
        
            IF (l_epis_type = pk_alert_constant.g_epis_type_home_health_care)
            THEN
                BEGIN
                    SELECT sp.flg_state
                      INTO l_sp_flg_state
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                     WHERE ei.id_episode = i_id_episode;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                IF (l_sp_flg_state = k_flg_no_show)
                THEN
                    RETURN TRUE;
                END IF;
            END IF;
        
            SELECT flg_ehr
              INTO l_flg_ehr
              FROM episode e
             WHERE id_episode = i_id_episode;
        
            IF l_flg_ehr = pk_ehr_access.g_access_ehr
            THEN
                RETURN TRUE;
            END IF;
        
            IF NOT pk_visit.get_visit_init(i_lang             => i_lang,
                                           i_id_episode       => i_id_episode,
                                           i_prof             => i_prof,
                                           o_dt_init          => l_dt_init,
                                           o_exist_dt_init    => l_exist_dt_init,
                                           o_dt_begin         => o_dt_begin,
                                           o_dt_first_obs     => l_dt_first_obs,
                                           o_dt_first_nur_obs => l_dt_first_nur_obs,
                                           o_error            => o_error)
            THEN
                RAISE l_exception_ext;
            END IF;
        
            IF (l_dt_init IS NULL OR l_exist_dt_init = g_no)
               AND ((l_dt_first_obs IS NULL AND (l_epis_type <> g_epis_type_nurse OR g_epis_type_nurse IS NULL) AND
               l_prof_cat <> pk_alert_constant.g_cat_type_nurse) OR
               (l_dt_first_nur_obs IS NULL AND
               (l_epis_type = g_epis_type_nurse OR g_epis_type_nurse IS NULL OR g_epis_type_nurse = -1) AND
               l_prof_cat = pk_alert_constant.g_cat_type_nurse))
            THEN
                -- A data de inicio no est preenchida
                SELECT decode(e.id_epis_type,
                              g_epis_type_session,
                              pk_message.get_message(i_lang, i_prof, 'VISIT_M025'),
                              pk_message.get_message(i_lang, i_prof, 'VISIT_M020'))
                  INTO l_msg_type
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            
                o_msg_text  := l_msg || l_msg_type;
                o_msg_title := pk_message.get_message(i_lang, i_prof, 'VISIT_M019');
                o_button    := 'NC';
                o_flg_show  := 'Y';
            END IF;
        END IF;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CHECK_VISIT_INIT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    /***********************************************************************************************************
    *  Esta funo permite registar a data de inicio da consulta.
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_episode            ID do episodio
    * @param      i_prof               ID do profissional
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since
    * @alteration Joao Martins 2008/05/30 If the episode refers to a PM AND R session, updates table SCHEDULE_INTERVENTION
    ***********************************************************************************************************/

    FUNCTION set_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        i_dt_init    IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_schedule  schedule_intervention.id_schedule%TYPE;
        l_id_epis_type epis_type.id_epis_type%TYPE;
        l_rows_ei      table_varchar;
        l_exception EXCEPTION;
        l_param     EXCEPTION;
        l_room                 room.id_room%TYPE;
        l_prof_pref_room_avail sys_config.value%TYPE;
        l_cfg_prof_pref_room_avail CONSTANT sys_config.id_sys_config%TYPE := 'PAT_DEFAULT_ROOM';
        l_prof_cat_type            CONSTANT category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_flg_show      VARCHAR2(10);
        l_msg           VARCHAR2(4000);
        l_msg_title     VARCHAR2(4000);
        l_button        VARCHAR2(10);
        l_id_patient    patient.id_patient%TYPE;
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_flg_ehr       episode.flg_ehr%TYPE;
        l_id_episode    episode.id_episode%TYPE;
    
        l_dt_init        TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_room        epis_info.id_room%TYPE;
        tbl_epis_1st_obs table_number := table_number(pk_alert_constant.g_epis_type_rehab_session,
                                                      pk_alert_constant.g_epis_type_rehab_appointment,
                                                      pk_alert_constant.g_epis_type_psychologist,
                                                      pk_alert_constant.g_epis_type_resp_therapist,
                                                      pk_alert_constant.g_epis_type_cdc_appointment,
                                                      pk_alert_constant.g_epis_type_home_health_care,
                                                      pk_alert_constant.g_epis_type_dietitian,
                                                      pk_alert_constant.g_epis_type_social,
                                                      pk_alert_constant.g_epis_type_outpatient,
                                                      pk_alert_constant.g_epis_type_urgent_care,
                                                      pk_alert_constant.g_epis_type_private_practice);
    
    BEGIN
        IF i_dt_init IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        ELSE
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_init,
                                                 i_timezone  => NULL,
                                                 o_timestamp => g_sysdate_tstz,
                                                 o_error     => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        l_dt_init := g_sysdate_tstz;
    
        SELECT ei.id_schedule, e.id_epis_type, e.id_patient, ei.id_dep_clin_serv, id_room
          INTO l_id_schedule, l_id_epis_type, l_id_patient, l_dep_clin_serv, l_id_room
          FROM epis_info ei, episode e
         WHERE e.id_episode = ei.id_episode
           AND ei.id_episode = i_id_episode;
    
        IF l_id_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            IF NOT pk_visit.create_visit(i_lang            => i_lang,
                                         i_id_pat          => l_id_patient,
                                         i_id_institution  => i_prof.institution,
                                         i_id_sched        => l_id_schedule,
                                         i_id_professional => i_prof,
                                         i_id_episode      => i_id_episode,
                                         i_external_cause  => NULL,
                                         i_health_plan     => NULL,
                                         i_epis_type       => l_id_epis_type,
                                         i_dep_clin_serv   => l_dep_clin_serv,
                                         i_origin          => NULL,
                                         i_flg_ehr         => g_no,
                                         o_episode         => l_id_episode,
                                         o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
        --Set professional's preferral room as patient's room
        g_error := 'UPDATE PATIENT ROOM';
    
        l_prof_pref_room_avail := pk_sysconfig.get_config(i_code_cf => l_cfg_prof_pref_room_avail, i_prof => i_prof);
    
        l_room := pk_prof_utils.get_prof_pref_room(i_lang => i_lang, i_prof => i_prof);
    
        IF l_prof_pref_room_avail = pk_alert_constant.g_yes
           AND l_room IS NOT NULL
           AND (l_id_schedule != -1 AND
           l_id_epis_type NOT IN
           (pk_alert_constant.g_epis_type_rehab_session, pk_alert_constant.g_epis_type_home_health_care))
        THEN
            IF l_id_room IS NULL
            THEN
                g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                           'INVALID ID_ROOM_FROM (MISSING EPIS_TYPE_ROOM CONFIGURATION)';
                --     pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                RAISE l_param;
            
            END IF;
            IF NOT pk_movement.set_new_location_no_commit(i_lang          => i_lang,
                                                          i_episode       => i_id_episode,
                                                          i_prof          => i_prof,
                                                          i_room          => l_room,
                                                          i_prof_cat_type => l_prof_cat_type,
                                                          o_flg_show      => l_flg_show,
                                                          o_msg           => l_msg,
                                                          o_msg_title     => l_msg_title,
                                                          o_button        => l_button,
                                                          o_error         => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'UPDATE EPIS_INFO';
    
        ts_epis_info.upd(id_episode_in => i_id_episode, dt_init_in => l_dt_init, rows_out => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('DT_INIT'));
    
        g_error := 'UPDATE SCHEDULE_INTERVENTION';
    
        IF l_id_schedule IS NOT NULL
           AND l_id_epis_type = g_epis_type_session
        THEN
            UPDATE schedule_intervention si
               SET si.flg_state = g_sched_sess
             WHERE si.id_schedule = l_id_schedule;
        END IF;
    
        --        g_error := 'START HHC APPOINTMENT';
        IF l_id_epis_type MEMBER OF tbl_epis_1st_obs
        THEN
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_id_episode,
                                          i_pat                 => l_id_patient,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => l_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          i_flg_triage_call     => pk_alert_constant.g_no,
                                          o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --Trigger the begin apointment event to interfaces
        g_error := 'CALL pk_ia_event_common.episode_appointment_start || i_id_institution = ' || i_prof.institution ||
                   ', i_id_episode = ' || i_id_episode;
        pk_ia_event_common.episode_appointment_start(i_id_institution => i_prof.institution,
                                                     i_id_episode     => i_id_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              g_error,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_VISIT_INIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'SET_VISIT_INIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_visit_init;

    FUNCTION set_visit_init
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN set_visit_init(i_lang       => i_lang,
                              i_id_episode => i_id_episode,
                              i_dt_init    => NULL,
                              i_prof       => i_prof,
                              o_error      => o_error);
    END;

    /***********************************************************************************************************
    *  Esta funo retorna a data de inicio da consulta.
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_id_episode        ID do episodio
    * @param      i_prof               ID do profissional
    
    * @param      o_dt_init           Data de incio
    * @param      o_exist_dt_init     Se tem preenchida a data de inicio (Y/N)
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since
    ***********************************************************************************************************/

    FUNCTION get_visit_init
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN epis_info.id_episode%TYPE,
        i_prof             IN profissional,
        o_dt_init          OUT VARCHAR2,
        o_exist_dt_init    OUT VARCHAR2,
        o_dt_begin         OUT VARCHAR2,
        o_dt_first_obs     OUT epis_info.dt_first_obs_tstz%TYPE,
        o_dt_first_nur_obs OUT epis_info.dt_first_nurse_obs_tstz%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_init_ts TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_init    VARCHAR2(200);
        l_flg_ehr    episode.flg_ehr%TYPE;
        l_dt_begin   episode.dt_begin_tstz%TYPE;
    BEGIN
        o_exist_dt_init := g_yes;
    
        g_sysdate_tstz := current_timestamp;
    
        BEGIN
            SELECT ei.dt_init, e.flg_ehr, e.dt_begin_tstz, ei.dt_first_obs_tstz, ei.dt_first_nurse_obs_tstz
              INTO l_dt_init_ts, l_flg_ehr, l_dt_begin, o_dt_first_obs, o_dt_first_nur_obs
              FROM epis_info ei
              JOIN episode e
                ON e.id_episode = ei.id_episode
             WHERE ei.id_episode = i_id_episode
               AND e.flg_ehr = pk_ehr_access.g_flg_ehr_normal;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        l_dt_init := pk_date_utils.date_send_tsz(i_lang, l_dt_init_ts, i_prof);
        IF l_flg_ehr <> 'S'
        THEN
            o_dt_begin := pk_date_utils.date_send_tsz(i_lang, l_dt_begin, i_prof);
        END IF;
    
        IF l_dt_init_ts IS NULL
        THEN
            o_exist_dt_init := g_no;
            l_dt_init       := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        END IF;
    
        o_dt_init := l_dt_init;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'GET_VISIT_INIT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    FUNCTION check_first_obs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_info.id_episode%TYPE,
        i_id_schedule IN epis_info.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_count  PLS_INTEGER := 0;
        l_return VARCHAR2(10 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_info ei
          JOIN episode e
            ON e.id_episode = ei.id_episode
         WHERE (ei.id_episode = i_id_episode OR ei.id_schedule = i_id_schedule)
           AND ei.dt_first_obs_tstz IS NOT NULL;
    
        IF l_count = 0
        THEN
            l_return := pk_alert_constant.g_no;
        ELSE
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            RETURN pk_alert_constant.g_no;
        
    END check_first_obs;

    FUNCTION check_first_obs_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE
    ) RETURN VARCHAR2 IS
        l_count  PLS_INTEGER := 0;
        l_return VARCHAR2(10 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM schedule s
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
           AND ei.id_patient = sg.id_patient
         WHERE s.id_group = i_id_group
           AND ei.dt_first_obs_tstz IS NOT NULL;
    
        IF l_count = 0
        THEN
            l_return := pk_alert_constant.g_no;
        ELSE
            l_return := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            RETURN pk_alert_constant.g_no;
        
    END check_first_obs_group;

    /**********************************************************************************************
    * This functiom creates an definitive episode+visit for the specified patient.
    * If the patient is omitted a new patient is created.
    * If the patient already has active episodes the user will receive a warning/error
    *
    * @param i_lang            ui language
    * @param i_prof            user object
    * @param i_patient         patient id. If null, a new patient
    * @param i_test            test only if episode can be created, don't commit data
    * @oaran i_num_health_plan public health plan number
    * @param o_flg_show        tell wether the error message must be shown or not
    * @param o_button          buttons to show
    * @param o_msg_title       message title
    * @param o_msg             message
    * @param o_new_episode     new episode id
    * @param o_new_patient     new patient id
    * @param o_error           error message
    *
    * @return                  TRUE if sucessfull, FALSE otherwise
    *
    * @author                  Joo Eiras
    * @version                 1.0
    * @since                   2008/04/30
    **********************************************************************************************/
    FUNCTION create_quick_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_test    IN VARCHAR2,
        
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_transaction_id IN VARCHAR2,
        
        o_flg_show   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_can_create OUT VARCHAR2,
        
        o_new_episode OUT episode.id_episode%TYPE,
        o_new_patient OUT patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type   epis_type.id_epis_type%TYPE;
        l_id_software software.id_software%TYPE;
    
        l_count_ttl  PLS_INTEGER;
        l_count_inst PLS_INTEGER;
        l_insts      table_varchar;
    
        l_epis_default_room room.id_room%TYPE;
        l_id_external_sys   epis_ext_sys.id_external_sys%TYPE;
    
        l_keys   table_varchar;
        l_values table_varchar;
    
        l_id_room epis_info.id_room%TYPE;
        l_rows    table_varchar;
    
        l_department       department.id_department%TYPE;
        l_dept             dept.id_dept%TYPE;
        l_clinical_service dep_clin_serv.id_clinical_service%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_error VARCHAR2(2000);
    
        l_error_in t_error_in := t_error_in();
        l_exception_ext EXCEPTION;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        l_keys   := nvl(i_keys, table_varchar());
        l_values := nvl(i_values, table_varchar());
    
        IF l_keys.count != l_values.count
        THEN
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_VISIT',
                                                     'CREATE_QUICK_EPISODE',
                                                     o_error);
        
        END IF;
    
        g_sysdate_tstz := current_timestamp;
        --contar visitas activas que este paciente tenha
        g_error := 'COUNT VISIT';
        SELECT COUNT(0),
               SUM(decode(id_institution, i_prof.institution, 1, 0)),
               CAST(COLLECT(pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || id_institution)) AS
                    table_varchar) insts
          INTO l_count_ttl, l_count_inst, l_insts
          FROM (SELECT DISTINCT id_institution
                  FROM visit
                 WHERE id_patient = i_patient
                   AND flg_status = g_visit_active);
    
        o_flg_show := 'N';
    
        IF l_count_inst > 0
        THEN
            --o paciente j tem uma visita activa nesta isntituio
            o_can_create := 'N';
            l_error      := pk_message.get_message(i_lang, 'VISIT_M018');
        
            l_error_in.set_all(i_lang,
                               'VISIT_M018',
                               l_error,
                               NULL,
                               'ALERT',
                               'PK_VISIT',
                               'CREATE_QUICK_EPISODE',
                               l_error,
                               'U');
        
            g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
        
            RETURN FALSE;
        
        ELSE
            --validao extra: saber se o paciente tem visitas activas noutras
            -- instituies para apresentar uma mensagem de aviso
            IF i_patient IS NOT NULL
               AND i_test = g_yes
            THEN
                o_can_create := 'Y';
                IF l_count_ttl > 0
                THEN
                
                    o_flg_show  := 'Y';
                    o_button    := 'NC';
                    o_msg_title := pk_message.get_message(i_lang, 'COMMON_M055');
                    IF l_insts.count = 1
                    THEN
                        --singular
                        o_msg := REPLACE(pk_message.get_message(i_lang, 'VISIT_M016'), '@1', l_insts(1));
                    ELSE
                        --plural
                        o_msg := REPLACE(pk_message.get_message(i_lang, 'VISIT_M017'),
                                         '@1',
                                         pk_utils.concat_table(l_insts, ', '));
                    END IF;
                END IF;
            
                RETURN TRUE;
            ELSIF i_test = g_yes
            THEN
                o_can_create := 'Y';
                RETURN TRUE;
            END IF;
        
        END IF;
    
        --se no for especificado o paciente, pesquisa-se por um pelo nmero de sus, ou cria-se um novo caso no haja
        IF i_patient IS NULL
        THEN
            g_error := 'UNDEFINED PATIENT';
            RAISE l_exception_ext;
        ELSE
            o_new_patient := i_patient;
        END IF;
    
        --saber id_epis_type para o software actual
        g_error     := 'GET EPIS_TYPE';
        l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
    
        g_error       := 'GET ID_SOFTWARE';
        l_id_software := pk_episode.get_soft_by_epis_type(l_epis_type, i_prof.institution);
    
        g_error := 'GET ID_DEP_CLIN_SERV';
        IF NOT get_epis_dep_clin_serv(i_lang             => i_lang,
                                      i_id_professional  => i_prof,
                                      o_department       => l_department,
                                      o_dept             => l_dept,
                                      o_clinical_service => l_clinical_service,
                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                      o_error            => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        --e por fim criar a visita+episdio
        g_error := 'PK_VISIT.CALL_CREATE_VISIT';
        IF NOT call_create_visit(i_lang                 => i_lang,
                                 i_id_pat               => o_new_patient,
                                 i_id_institution       => i_prof.institution,
                                 i_id_sched             => NULL,
                                 i_id_professional      => profissional(NULL, i_prof.institution, i_prof.software),
                                 i_id_episode           => NULL,
                                 i_external_cause       => NULL,
                                 i_health_plan          => NULL,
                                 i_epis_type            => l_epis_type,
                                 i_dep_clin_serv        => l_id_dep_clin_serv,
                                 i_origin               => NULL,
                                 i_flg_ehr              => 'N',
                                 i_dt_begin             => current_timestamp,
                                 i_flg_appointment_type => NULL,
                                 i_transaction_id       => l_transaction_id,
                                 o_episode              => o_new_episode,
                                 o_error                => o_error)
        THEN
            RAISE l_exception_ext;
        END IF;
    
        --atribuir sala por defeito caso esta no esteja parametrizada
        l_epis_default_room := pk_sysconfig.get_config('ADMIN_DEFAULT_ROOM', i_prof);
    
        BEGIN
            SELECT id_room
              INTO l_id_room
              FROM prof_room
             WHERE id_professional = i_prof.id
               AND id_room IN (SELECT r.id_room
                                 FROM room r, department d, software_dept sd
                                WHERE d.id_department = r.id_department
                                  AND d.id_institution = i_prof.institution
                                  AND sd.id_dept = d.id_dept
                                  AND sd.id_software = l_id_software)
               AND flg_pref = g_room_pref
               AND rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_room := NULL;
        END;
    
        /* <DENORM Fbio> */
        ts_epis_info.upd(id_episode_in => o_new_episode,
                         id_room_in    => nvl(l_id_room, l_epis_default_room),
                         id_room_nin   => FALSE,
                         rows_out      => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rows, o_error, table_varchar('ID_ROOM'));
    
        --fazer registo de nmero de episdio externo
        l_id_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        IF l_id_external_sys IS NOT NULL
        THEN
            INSERT INTO epis_ext_sys
                (id_epis_ext_sys, id_external_sys, id_episode, VALUE, id_institution, id_epis_type, cod_epis_type_ext)
            VALUES
                (seq_epis_ext_sys.nextval,
                 l_id_external_sys,
                 o_new_episode,
                 o_new_episode,
                 i_prof.institution,
                 l_epis_type,
                 decode(l_id_software, 8, 'URG', 29, 'URG', 11, 'INT', 1, 'CON', 3, 'CON', 12, 'CON', 'XXX'));
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              'CREATE_QUICK_EPISODE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
    END;

    /** Flash wrapper do not use otherwise */
    FUNCTION create_quick_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_test        IN VARCHAR2,
        i_keys        IN table_varchar,
        i_values      IN table_varchar,
        o_flg_show    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_can_create  OUT VARCHAR2,
        o_new_episode OUT episode.id_episode%TYPE,
        o_new_patient OUT patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_visit.create_quick_episode(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_patient     => i_patient,
                                             i_test        => i_test,
                                             i_keys        => i_keys,
                                             i_values      => i_values,
                                             o_flg_show    => o_flg_show,
                                             o_button      => o_button,
                                             o_msg_title   => o_msg_title,
                                             o_msg         => o_msg,
                                             o_can_create  => o_can_create,
                                             o_new_episode => o_new_episode,
                                             o_new_patient => o_new_patient,
                                             o_error       => o_error);
    
    END create_quick_episode;

    /***********************************************************************************************************
    *  Esta funo retorna a USF e a equipa do profissional
    *
    * @param      i_lang               Lngua registada como preferncia do profissional
    * @param      i_prof               ID do profissional
    
    * @param      o_usf           id usf
    * @param      o_prof_team     id da equipa
    * @param      o_error              mensagem de erro
    *
    * @return     se a funo termina com sucesso e FALSE caso contrrio
    * @author     Teresa Coutinho
    * @version    2.4.3.
    * @since
    ***********************************************************************************************************/

    FUNCTION get_usf_prof_team
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_usf       OUT VARCHAR2,
        o_prof_team OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_prof_team       prof_team.id_prof_team%TYPE;
        l_id_institution_usf prof_team.id_institution%TYPE;
        CURSOR c_usf IS
            SELECT ptd.id_prof_team, upt.id_institution
              FROM prof_team pt, prof_team upt, prof_team_det ptd
             WHERE ptd.id_professional = i_prof.id
               AND ptd.id_prof_team = pt.id_prof_team
               AND upt.id_prof_team = upt.id_prof_team;
    
    BEGIN
        g_error := 'OPEN C_USF';
        OPEN c_usf;
        FETCH c_usf
            INTO l_id_prof_team, l_id_institution_usf;
        g_found := c_usf%FOUND;
        CLOSE c_usf;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_VISIT',
                                                     'GET_USF_PROF_TEAM',
                                                     o_error);
        
    END;

    /********************************************************************************************
    * Retorna os dados do processo de criacao do contacto indirecto (nesta revisao especificamente para CARE)
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_episode      Episode ID
    * @param OUT  o_contact_data output cursor with contact data
    * @param OUT  o_clin_services cursor containing clinical services for this professional
    * @param OUT  o_error        Error structure
    *
    *
    * @author                   Pedro Teixeira
    * @since                    26/05/2009
    ********************************************************************************************/
    FUNCTION get_contact_reg_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_contact_data  OUT pk_types.cursor_type,
        o_clin_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_max_dt_begin    episode.dt_begin_tstz%TYPE;
        c_clin_services   pk_types.cursor_type;
        l_clin_servs      table_number;
        l_departments     table_number;
        l_dep_clin_servs  table_number;
        l_desc_clin_servs table_varchar;
        l_permissions     table_varchar;
        l_prof_cat        category.flg_type%TYPE;
        l_def_cs          clinical_service.id_clinical_service%TYPE;
        l_exception EXCEPTION;
    
        CURSOR c_discharge IS
            SELECT MAX(d.dt_med_tstz)
              FROM discharge d
             WHERE d.id_episode = i_episode
               AND d.flg_status = g_active;
    
        CURSOR c_epis_dt_end IS
            SELECT dt_end_tstz
              FROM episode e
             WHERE e.id_episode = i_episode;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_prof_cat     := pk_tools.get_prof_cat(i_prof => i_prof);
    
        ------------------------
        g_error := 'OPEN C_DISCHARGE';
        OPEN c_discharge;
        FETCH c_discharge
            INTO l_max_dt_begin;
        g_found := c_discharge%FOUND;
        CLOSE c_discharge;
    
        ------------------------
        IF NOT g_found
           OR l_max_dt_begin IS NULL
        THEN
            g_error := 'OPEN C_EPIS_DT_END';
            OPEN c_epis_dt_end;
            FETCH c_epis_dt_end
                INTO l_max_dt_begin;
            g_found := c_epis_dt_end%FOUND;
            CLOSE c_epis_dt_end;
        
            IF NOT g_found
               OR l_max_dt_begin IS NULL
            THEN
                l_max_dt_begin := g_sysdate_tstz;
            END IF;
        END IF;
    
        IF l_max_dt_begin > g_sysdate_tstz
        THEN
            l_max_dt_begin := g_sysdate_tstz;
        END IF;
    
        -- get list of possible clinical services
        g_error := 'CALL pk_ehr_access.get_clinical_services';
        IF NOT pk_ehr_access.get_clinical_services(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_flg_context   => NULL,
                                                   o_clin_services => c_clin_services,
                                                   o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- fetch c_clin_services
        g_error := 'FETCH c_clin_services';
        FETCH c_clin_services BULK COLLECT
            INTO l_clin_servs, l_departments, l_dep_clin_servs, l_desc_clin_servs, l_permissions;
        CLOSE c_clin_services;
    
        -- get default clinical service
        IF l_prof_cat = pk_alert_constant.g_cat_type_doc
        THEN
            l_def_cs := pk_sysconfig.get_config(i_code_cf => 'NEW_CONTACT_CLINICAL_SERVICE', i_prof => i_prof);
        ELSIF l_prof_cat = pk_alert_constant.g_cat_type_nurse
        THEN
            l_def_cs := pk_sysconfig.get_config(i_code_cf => 'NEW_NURSING_CONTACT_CLINICAL_SERVICE', i_prof => i_prof);
        END IF;
    
        ------------------------
        g_error := 'OPEN O_CONTACT_DATA';
        OPEN o_contact_data FOR
            SELECT decode(t.id_schedule, NULL, pk_events.g_cont_type_absent, t.flg_contact_type) flg_appointment_type,
                   pk_sysdomain.get_domain(pk_grid_amb.g_domain_sch_presence,
                                           decode(t.id_schedule, NULL, pk_events.g_cont_type_absent, t.flg_contact_type),
                                           i_lang) desc_appointment_type,
                   CASE
                        WHEN cs_in_list > 0 THEN
                         t.id_clinical_service
                        ELSE
                         NULL
                    END id_clinical_service,
                   CASE
                        WHEN cs_in_list > 0 THEN
                         pk_translation.get_translation(i_lang, t.code_clinical_service)
                        ELSE
                         NULL
                    END desc_clinical_service,
                   decode(t.id_schedule, NULL, g_flg_request_type_patient, t.flg_request_type) flg_request_type,
                   decode(t.id_schedule,
                          NULL,
                          pk_sysdomain.get_domain(g_sched_flg_req_type, g_flg_request_type_patient, i_lang),
                          pk_sysdomain.get_domain(g_sched_flg_req_type, t.flg_request_type, i_lang)) desc_request_type,
                   pk_date_utils.date_send_tsz(i_lang, nvl(t.dt_begin_tstz, l_max_dt_begin), i_prof) dt_begin,
                   NULL dt_begin_min,
                   pk_date_utils.date_send_tsz(i_lang, l_max_dt_begin, i_prof) dt_begin_max,
                   pk_date_utils.dt_chr_tsz(i_lang, nvl(t.dt_begin_tstz, l_max_dt_begin), i_prof) rep_date,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    nvl(t.dt_begin_tstz, l_max_dt_begin),
                                                    i_prof.institution,
                                                    i_prof.software) rep_hour,
                   pk_message.get_message(i_lang, i_prof, decode(t.id_schedule, NULL, 'GRID_AMB_T029', 'GRID_AMB_T028')) schedule_type
              FROM (SELECT e.id_clinical_service,
                           e.dt_begin_tstz,
                           cs.code_clinical_service,
                           pk_utils.search_table_number(l_clin_servs, e.id_clinical_service) cs_in_list,
                           s.id_schedule,
                           s.flg_request_type,
                           sg.flg_contact_type
                      FROM episode e
                      JOIN clinical_service cs
                        ON e.id_clinical_service = cs.id_clinical_service
                      JOIN epis_info ei
                        ON e.id_episode = ei.id_episode
                      LEFT JOIN schedule s
                        ON ei.id_schedule = s.id_schedule
                       AND s.id_schedule > 0
                      LEFT JOIN sch_group sg
                        ON ei.id_schedule = sg.id_schedule
                     WHERE e.id_episode = i_episode) t;
    
        g_error := 'OPEN o_clin_services';
        OPEN o_clin_services FOR
            SELECT id_clinical_service,
                   id_department,
                   id_dep_clin_serv,
                   desc_clinical_service,
                   has_permission,
                   decode(id_clinical_service, l_def_cs, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM (SELECT dcs.id_clinical_service,
                           dcs.id_department,
                           dcs.id_dep_clin_serv,
                           xsql4.desc_clinical_service,
                           pk_alert_constant.g_yes     has_permission,
                           xsql4.rn1                   order_rank
                      FROM dep_clin_serv dcs
                      JOIN (SELECT id_dep_clin_serv, desc_clinical_service, rn1
                             FROM (SELECT /*+ opt_estimate(table t3 rows=1)*/
                                    t3.column_value id_dep_clin_serv, rownum rn1
                                     FROM TABLE(l_dep_clin_servs) t3) xsql1
                             JOIN (SELECT /*+ opt_estimate(table t4 rows=1)*/
                                   t4.column_value desc_clinical_service, rownum rn2
                                    FROM TABLE(l_desc_clin_servs) t4) xsql2
                               ON xsql2.rn2 = xsql1.rn1
                            WHERE rownum > 0) xsql4
                        ON xsql4.id_dep_clin_serv = dcs.id_dep_clin_serv)
             ORDER BY order_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONTACT_REG_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_contact_data);
            pk_types.open_my_cursor(o_clin_services);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Retorna os dados do processo de criacao do contacto indirecto (nesta revisao especificamente para CARE)
    *
    * @param IN   i_lang                 Language ID
    * @param IN   i_prof                 Professional ID
    * @param IN   i_patient              Patient ID
    * @param IN   i_episode              Episode ID
    * @param IN   i_dt_begin             data de inicio do episodio
    * @param IN   i_flg_enc_type         encounter type flag
    * @param IN   i_id_clinical_service  Episode ID
    * @param IN   i_flg_request_type     Episode ID
    
    * @param OUT  o_error        Error structure
    *
    *
    * @author                   Pedro Teixeira
    * @since                    26/05/2009
    ********************************************************************************************/
    FUNCTION set_contact_reg_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_flg_enc_type        IN sch_group.flg_contact_type%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_request_type    IN schedule.flg_request_type%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids                table_varchar;
        l_epis_count            NUMBER;
        l_id_schedule           schedule.id_schedule%TYPE;
        l_epis_doc_template     table_number;
        l_nursing_sched_minutes NUMBER;
        l_visit                 visit.id_visit%TYPE;
        l_exception EXCEPTION;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
        l_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_epis IS
            SELECT COUNT(1)
              FROM episode e
             WHERE e.id_episode = i_episode
               AND e.id_patient = i_patient;
    
        CURSOR c_epis_info IS
            SELECT ei.id_schedule
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
    
    BEGIN
        pk_alertlog.log_debug(text            => 'i_dt_begin: ' || i_dt_begin || ', i_flg_enc_type: ' || i_flg_enc_type ||
                                                 ', i_id_clinical_service: ' || i_id_clinical_service ||
                                                 ', i_id_dep_clin_serv: ' || i_id_dep_clin_serv ||
                                                 ', i_flg_request_type: ' || i_flg_request_type,
                              object_name     => g_package_name,
                              sub_object_name => 'SET_CONTACT_REG_DATA');
    
        l_dt_begin_tstz         := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_nursing_sched_minutes := CAST(pk_sysconfig.get_config('NEW_NURSING_SCHEDULE_DURATION_MINUTES', i_prof) AS
                                        NUMBER);
    
        g_error := 'OPEN C_EPIS CURSOR';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis_count;
        g_found := c_epis%FOUND;
        CLOSE c_epis;
    
        IF g_found
        THEN
            ----------------------------------------------------------------
            -- update episode
            l_rowids := table_varchar();
            g_error  := 'TS_EPISODE.UPD';
            ts_episode.upd(id_episode_in          => i_episode,
                           dt_begin_tstz_in       => nvl(l_dt_begin_tstz, current_timestamp),
                           flg_status_in          => pk_alert_constant.g_epis_status_active,
                           id_clinical_service_in => i_id_clinical_service,
                           rows_out               => l_rowids);
        
            g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPISODE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            ----------------------------------------------------------------
            -- update epis_info
            l_rowids := table_varchar();
            g_error  := 'TS_EPIS_INFO.UPD';
            ts_epis_info.upd(id_episode_in              => i_episode,
                             id_dep_clin_serv_in        => i_id_dep_clin_serv,
                             id_dep_clin_serv_nin       => FALSE,
                             id_first_dep_clin_serv_in  => i_id_dep_clin_serv,
                             id_first_dep_clin_serv_nin => FALSE,
                             rows_out                   => l_rowids);
        
            g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPIS_INFO';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            ----------------------------------------------------------------
            -- update epis_doc_template for (new) clinical_service
            g_error := 'CALL SET_DEFAULT_EPIS_DOC_TEMPLATES';
            IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_episode            => i_episode,
                                                                  i_flg_type           => g_flg_type_appointment_type,
                                                                  o_epis_doc_templates => l_epis_doc_template,
                                                                  o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            ----------------------------------------------------------------
            -- update schedule
            g_error := 'OPEN C_EPIS_INFO CURSOR';
            OPEN c_epis_info;
            FETCH c_epis_info
                INTO l_id_schedule;
            CLOSE c_epis_info;
        
            g_error := 'UPDATE SCHEDULE';
            IF l_id_schedule IS NOT NULL
               AND l_id_schedule != -1
            THEN
                -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
                g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
            
                g_error := 'UPDATE SCHEDULE';
                IF NOT pk_schedule_api_upstream.update_sch_proc_and_dates(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_id_schedule      => l_id_schedule,
                                                                          i_dt_begin_tstz    => l_dt_begin_tstz,
                                                                          i_dt_end_tszt      => l_dt_begin_tstz +
                                                                                                numtodsinterval(l_nursing_sched_minutes,
                                                                                                                'MINUTE'),
                                                                          i_dep_clin_serv    => i_id_dep_clin_serv,
                                                                          i_flg_request_type => i_flg_request_type,
                                                                          i_transaction_id   => l_transaction_id,
                                                                          o_error            => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF i_flg_enc_type IS NOT NULL
                THEN
                    l_rowids := table_varchar();
                    g_error  := 'CALL ts_sch_group.upd';
                    ts_sch_group.upd(flg_contact_type_in  => i_flg_enc_type,
                                     flg_contact_type_nin => FALSE,
                                     where_in             => 'id_schedule=' || l_id_schedule || ' and id_patient=' ||
                                                             i_patient,
                                     rows_out             => l_rowids);
                    g_error := 'CALL t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'SCH_GROUP',
                                                  i_rowids       => l_rowids,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_CONTACT_TYPE'));
                
                    g_error := 'CALL pk_schedule_api_upstream.set_flg_contact_type';
                    IF NOT pk_schedule_api_upstream.set_flg_contact_type(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_transaction_id   => l_transaction_id,
                                                                         i_id_schedule      => l_id_schedule,
                                                                         i_id_patient       => i_patient,
                                                                         i_flg_contact_type => i_flg_enc_type,
                                                                         o_error            => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END IF;
        
            ----------------------------------------------------------------
            -- update visit init
            IF NOT set_visit_init(i_lang => i_lang, i_id_episode => i_episode, i_prof => i_prof, o_error => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            ----------------------------------------------------------------
            -- update visit
            g_error  := 'CALL pk_episode.get_id_visit';
            l_visit  := pk_episode.get_id_visit(i_episode => i_episode);
            l_rowids := table_varchar();
            g_error  := 'CALL ts_visit.upd';
            ts_visit.upd(id_visit_in       => l_visit,
                         dt_begin_tstz_in  => nvl(l_dt_begin_tstz, current_timestamp),
                         dt_begin_tstz_nin => FALSE,
                         rows_out          => l_rowids);
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('DT_BEGIN_TSTZ'));
        
        ELSE
            RAISE l_exception;
        END IF;
    
        pk_schedule_api_upstream.do_commit(i_id_transaction => l_transaction_id, i_prof => i_prof);
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CONTACT_REG_DATA',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    *
    *
    * @param IN   i_lang         Language ID
    * @param IN   i_prof         Professional ID
    * @param IN   i_patient      Patient ID
    * @param IN   i_episode      Episode ID
    * @param OUT  o_permission   Permission to update contact data
    * @param OUT  o_error        Error structure
    *
    *
    * @author                   Pedro Teixeira
    * @since                    26/05/2009
    ********************************************************************************************/
    FUNCTION get_contact_permission_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_permission OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cs              episode.id_clinical_service%TYPE;
        l_id_schedule     epis_info.id_schedule%TYPE;
        l_cont_type_perm  VARCHAR2(1 CHAR);
        l_specialty_perm  VARCHAR2(1 CHAR);
        l_initiative_perm VARCHAR2(1 CHAR);
    
        CURSOR c_epis IS
            SELECT e.id_clinical_service
              FROM episode e
             WHERE e.id_episode = i_episode
               AND e.id_patient = i_patient;
    
        CURSOR c_sched IS
            SELECT ei.id_schedule
              FROM epis_info ei
             WHERE ei.id_episode = i_episode
               AND ei.id_schedule > 0;
    
    BEGIN
        g_error := 'OPEN C_EPIS CURSOR';
        OPEN c_epis;
        FETCH c_epis
            INTO l_cs;
        g_found := c_epis%FOUND;
        CLOSE c_epis;
    
        IF g_found
           AND l_cs < 0
        THEN
            l_specialty_perm := g_yes;
        ELSE
            l_specialty_perm := g_no;
        END IF;
    
        g_error := 'OPEN C_SCHED CURSOR';
        OPEN c_sched;
        FETCH c_sched
            INTO l_id_schedule;
        g_found := c_sched%FOUND;
        CLOSE c_sched;
    
        IF g_found
        THEN
            l_cont_type_perm  := pk_alert_constant.g_yes;
            l_initiative_perm := g_yes;
        ELSE
            l_cont_type_perm  := pk_alert_constant.g_no;
            l_initiative_perm := g_no;
        END IF;
    
        pk_alertlog.log_debug(text            => 'l_cont_type_perm: ' || l_cont_type_perm || ', l_specialty_perm: ' ||
                                                 l_specialty_perm || ', l_initiative_perm: ' || l_initiative_perm,
                              object_name     => g_package_name,
                              sub_object_name => 'GET_CONTACT_PERMISSION_DATA');
    
        g_error := 'OPEN o_permission';
        OPEN o_permission FOR
            SELECT l_cont_type_perm cont_type_perm, l_specialty_perm specialty_perm, l_initiative_perm initiative_perm
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_permission);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_CONTACT_PERMISSION_DATA',
                                                     o_error);
        
    END;

    /********************************************************************************************
    * Currently only for the NL market and executable in a very specific situation, thus being
    * a little too simplistic.
    *
    * @param IN   i_lang                 Language ID
    * @param IN   i_prof                 Professional ID
    * @param IN   i_id_epis              Episode ID
    * @param OUT  o_error                Error structure
    *
    *
    * @author                   RicardoNunoAlmeida
    * @since                    26/06/2009
    ********************************************************************************************/
    FUNCTION set_reactivate_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type            episode.flg_type%TYPE;
        l_id_visit            episode.id_visit%TYPE;
        l_epis_type           episode.id_epis_type%TYPE;
        l_flg_visit           visit.flg_status%TYPE;
        l_dt_vis_end          visit.dt_end_tstz%TYPE;
        l_id_adm_req          adm_request.id_adm_request%TYPE;
        l_period              sys_config.value%TYPE;
        l_flg_status          episode.flg_status%TYPE;
        l_id_episode_surg     episode.id_episode%TYPE;
        l_flg_status_surg     episode.flg_status%TYPE;
        l_dt_cancel           episode.dt_cancel_tstz%TYPE;
        l_dummy               VARCHAR2(4000);
        l_id_episode_surg_arr table_number := table_number();
        l_flg_status_surg_arr table_varchar := table_varchar();
        l_internal_exception     EXCEPTION;
        l_restore_period_expired EXCEPTION;
    
        l_rows           table_varchar;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        g_error        := 'BEGIN SET_REACTIVE_EPIS';
        g_sysdate_tstz := current_timestamp;
    
        g_error  := 'GET SYS_CONFIG';
        l_period := pk_sysconfig.get_config(i_code_cf => 'WTL_RESTORE_PERIOD', i_prof => i_prof);
    
        g_error := 'GET EPISODE DATA';
        pk_alertlog.log_debug(g_error);
        SELECT e.flg_type, e.id_visit, e.id_epis_type, ar.id_adm_request, v.flg_status, v.dt_end_tstz, e.dt_cancel_tstz
          INTO l_flg_type, l_id_visit, l_epis_type, l_id_adm_req, l_flg_visit, l_dt_vis_end, l_dt_cancel
          FROM episode e
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN visit v
            ON v.id_visit = e.id_visit
          LEFT JOIN adm_request ar
            ON ar.id_dest_episode = e.id_episode
         WHERE e.id_episode = i_id_epis
           AND e.flg_status = pk_alert_constant.g_flg_status_c;
    
        IF (current_timestamp > l_dt_cancel + to_number(l_period))
        THEN
            RAISE l_restore_period_expired;
        END IF;
    
        IF (l_flg_status <> pk_alert_constant.g_flg_status_c)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'SET EPISODE SPECIFICS';
        IF l_epis_type = pk_alert_constant.g_epis_type_operating
        THEN
            RETURN TRUE;
        ELSIF l_epis_type = pk_alert_constant.g_epis_type_inpatient
              AND l_id_adm_req IS NOT NULL
        THEN
            --No need to check on the previous episode stuff, if this episode
            --came from EDIS it would never have been cancelled in the first place.
            BEGIN
                g_error := 'GET SURGICAL EPISODE INFO';
                pk_alertlog.log_debug(g_error);
                SELECT id_episode, flg_status
                  BULK COLLECT
                  INTO l_id_episode_surg_arr, l_flg_status_surg_arr
                  FROM episode e
                 WHERE e.id_prev_episode = i_id_epis
                   AND e.id_epis_type = g_epis_type_oris
                   AND e.flg_status = pk_alert_constant.g_flg_status_c;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode_surg := NULL;
            END;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            -- Cancel the surgery
            FOR i IN 1 .. l_id_episode_surg_arr.count
            LOOP
            
                l_id_episode_surg := l_id_episode_surg_arr(i);
                l_flg_status_surg := l_flg_status_surg_arr(i);
            
                IF l_id_episode_surg IS NOT NULL
                THEN
                    g_error := 'CALL TO PK_SR_GRID.CALL_SET_PAT_STATUS';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => l_id_episode_surg,
                                                          i_flg_status_new => pk_alert_constant.g_flg_status_a,
                                                          i_flg_status_old => l_flg_status_surg,
                                                          i_test           => pk_alert_constant.g_yes,
                                                          i_transaction_id => l_transaction_id,
                                                          o_flg_show       => l_dummy,
                                                          o_msg_title      => l_dummy,
                                                          o_msg_text       => l_dummy,
                                                          o_button         => l_dummy,
                                                          o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        ELSE
            --Raise exception.
            RAISE l_internal_exception;
        END IF;
    
        g_error := 'UPDATE EPISODE';
        ts_episode.upd(flg_status_in => g_epis_active, flg_status_nin => FALSE, dt_end_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_end_tstz_nin => FALSE, dt_cancel_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_cancel_tstz_nin => FALSE, id_prof_cancel_in => NULL, id_prof_cancel_nin => FALSE, desc_cancel_reason_in => NULL, desc_cancel_reason_nin => FALSE, id_episode_in => i_id_epis, rows_out => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS',
                                                                      'DT_END_TSTZ',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'ID_PROF_CANCEL',
                                                                      'DESC_CANCEL_REASON'));
        --
        IF l_flg_visit != g_epis_active
           OR l_dt_vis_end IS NOT NULL
        THEN
            l_rows  := table_varchar();
            g_error := 'CALL TS_VISIT.UPD';
            ts_visit.upd(flg_status_in => g_epis_active, flg_status_nin => FALSE, dt_end_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_end_tstz_nin => FALSE,
            --
            id_visit_in => l_id_visit, rows_out => l_rows);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'VISIT',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN l_restore_period_expired THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              pk_message.get_message(i_lang, 'SURG_ADM_REQUEST_E028'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UNDELETE_WTLIST',
                                              'U',
                                              NULL,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
            --
        WHEN l_internal_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
            --
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REACTIVATE_EPIS',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_reactivate_epis;

    /*
    * Checks if an episode type is of Ambulatory products
    * (OUTP, PP, CARE, NUTRI, SOCIAL).
    *
    * @param i_epis_type       episode type identifier
    *
    * @return                  true, if the episode type is of Ambulatory products,
    *                          or false, otherwise.
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/12
    */
    FUNCTION check_epis_type_amb(i_epis_type IN episode.id_epis_type%TYPE) RETURN BOOLEAN IS
        l_ret BOOLEAN;
    BEGIN
        IF i_epis_type IS NULL
        THEN
            l_ret := FALSE;
        ELSIF i_epis_type IN (g_epis_type_care,
                              g_epis_type_outp,
                              g_epis_type_pp,
                              g_epis_type_nurse,
                              g_epis_type_nurse_outp,
                              g_epis_type_nurse_pp,
                              g_epis_type_nutri,
                              pk_alert_constant.g_epis_type_social,
                              pk_alert_constant.g_epis_type_psychologist,
                              pk_alert_constant.g_epis_type_resp_therapist,
                              pk_alert_constant.g_epis_type_cdc_appointment)
        THEN
            l_ret := TRUE;
        ELSE
            l_ret := FALSE;
        END IF;
    
        RETURN l_ret;
    END check_epis_type_amb;

    /*******************************************************************************************************************************************
    * INS_VISIT                       Create an visit for an patient with send parameters and returns id_visit created
    *
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new visit
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EXTERNAL_CAUSE         EXTERNAL_CAUSE identifier that should be associated with new visit
    * @param I_DT_BEGIN               Date begin for current visit
    * @param I_DT_CREATION            Date creation of current visit
    * @param I_ID_ORIGIN              Origin identifier
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param O_ID_VISIT               VISIT identifier corresponding to created visit
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luis Maia
    * @version                        2.6.0.3
    * @since                          2010/May/25
    *
    *******************************************************************************************************************************************/
    FUNCTION ins_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_prof           IN profissional,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_dt_begin       IN visit.dt_begin_tstz%TYPE,
        i_dt_creation    IN visit.dt_begin_tstz%TYPE,
        i_id_origin      IN visit.id_origin%TYPE,
        i_flg_migration  IN visit.flg_migration%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set      IN VARCHAR2 DEFAULT 'N',
        o_id_visit       OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit NUMBER;
        l_rows     table_varchar := table_varchar();
        l_exception EXCEPTION;
    BEGIN
        --
        l_id_visit := ts_visit.next_key();
        --
        g_error := 'CALL TS_VISIT.INS WITH ID_PATIENT:' || i_id_patient;
        ts_visit.ins(id_visit_in          => l_id_visit,
                     flg_status_in        => CASE
                                                 WHEN i_order_set = pk_alert_constant.g_no
                                                      OR i_order_set IS NULL THEN
                                                  pk_alert_constant.g_active
                                                 ELSE
                                                  pk_admission_request.g_flg_status_pd
                                             END,
                     id_institution_in    => nvl(i_inst_dest, i_prof.institution),
                     id_external_cause_in => i_external_cause,
                     id_patient_in        => CASE
                                                 WHEN i_order_set = pk_alert_constant.g_no
                                                      OR i_order_set IS NULL THEN
                                                  i_id_patient
                                                 ELSE
                                                  -1
                                             END,
                     dt_begin_tstz_in     => i_dt_begin,
                     dt_creation_in       => i_dt_creation,
                     id_origin_in         => i_id_origin,
                     flg_migration_in     => nvl(i_flg_migration, 'A'),
                     rows_out             => l_rows);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'VISIT',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
        o_id_visit := l_id_visit;
    
        --Amanda add for test allergy start ----
        IF pk_sysconfig.get_config('CREATE_DEFAULT_ALLERGY', i_prof) = pk_alert_constant.g_yes
        THEN
            IF NOT pk_allergy.create_default_allergy(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_id_patient,
                                                     i_episode => NULL,
                                                     o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --Amanda add for test allergy end   ----
        --
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
                                              'INS_VISIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_visit;

    /**********************************************************************************************
    * Check if professional category can update EPIS_INFO.DT_FIRST_OBS_TSTZ value.
    *
    * @param i_lang                 Language ID
    * @param i_prof_cat             Professional category
    *
    * @return                         YES/NO
    *
    * @author                         Jose Brito
    * @version                        2.5.1
    * @since                          2011/05/16
    **********************************************************************************************/
    FUNCTION check_first_obs_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CHECK_FIRST_OBS_CATEGORY';
    
        l_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_first_obs_cat VARCHAR2(1 CHAR);
    
        l_error t_error_out;
    BEGIN
    
        IF i_prof_cat = g_cat_type_doc
           OR i_prof_cat = g_cat_type_fisio
           OR i_prof_cat = g_cat_type_nutri
           OR i_prof_cat = pk_alert_constant.g_cat_type_social
           OR i_prof_cat = pk_alert_constant.g_cat_type_psychologist
           OR i_prof_cat = pk_alert_constant.g_cat_type_coordinator
           OR i_prof_cat = pk_alert_constant.g_cat_type_physiotherapist
        THEN
            l_is_first_obs_cat := l_yes;
        ELSE
            l_is_first_obs_cat := l_no;
        END IF;
    
        RETURN l_is_first_obs_cat;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              l_func_name,
                                              l_error);
            RETURN l_no;
    END check_first_obs_category;

    FUNCTION check_first_obs_category
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CHECK_FIRST_OBS_CATEGORY';
    
        l_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_is_first_obs_cat VARCHAR2(1 CHAR);
    
        l_error t_error_out;
    BEGIN
    
        IF i_prof_cat = pk_alert_constant.g_cat_type_technician
           AND i_prof.software = pk_alert_constant.g_soft_resptherap
        THEN
            l_is_first_obs_cat := l_yes;
        ELSE
            l_is_first_obs_cat := check_first_obs_category(i_lang, i_prof_cat);
        END IF;
    
        RETURN l_is_first_obs_cat;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              l_func_name,
                                              l_error);
            RETURN l_no;
    END check_first_obs_category;

    /*
    * Get episode type by schedule.
    *
    * @param i_schedule     schedule identifier
    *
    * @return               episode type identifier
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.7
    * @since                2010/09/09
    */
    FUNCTION get_epis_type(i_schedule IN schedule.id_schedule%TYPE) RETURN epis_type.id_epis_type%TYPE IS
        l_ret epis_type.id_epis_type%TYPE;
    
        CURSOR c_epis_type_sch IS
            SELECT sp.id_epis_type
              FROM schedule_outp sp
             WHERE sp.id_schedule = i_schedule;
    BEGIN
        OPEN c_epis_type_sch;
        FETCH c_epis_type_sch
            INTO l_ret;
        CLOSE c_epis_type_sch;
    
        RETURN l_ret;
    END get_epis_type;

    FUNCTION set_dt_last_interaction
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_ei       table_varchar;
        l_epis_info     epis_info%ROWTYPE;
        l_prof_cat_type category.flg_type%TYPE;
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SET_DT_LAST_INTERACTION';
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        SELECT ei.*
          INTO l_epis_info
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        l_prof_cat_type := pk_tools.get_prof_cat(i_prof);
    
        l_rows_ei := table_varchar();
        ts_epis_info.upd(id_episode_in               => i_id_episode,
                         dt_last_interaction_tstz_in => l_current_timestamp,
                         rows_out                    => l_rows_ei);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rows_ei,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('dt_last_interaction_tstz'));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_VISIT',
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_dt_last_interaction;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_visit_active   := 'A';
    g_epis_active    := 'A';
    g_visit_inactive := 'I';
    g_epis_pend      := 'P';
    g_epis_inactive  := 'I';
    g_epis_cancel    := 'C';

    g_epis_info_efectiv     := 'E';
    g_epis_info_wait        := 'C';
    g_epis_info_first_nurse := 'N';
    g_epis_info_doctor      := 'T';
    g_epis_info_last_nurse  := 'P';
    g_epis_info_clin_disch  := 'D';
    g_epis_info_adm_disch   := 'M';

    g_sched_first_nurse := 'N';
    g_sched_doctor      := 'T';
    g_sched_efectiv     := 'E';
    g_sched_scheduled   := 'A';
    g_sched_nurse_prev  := 'W';
    g_sched_nurse       := 'N';
    g_sched_nurse_end   := 'P';

    g_sched_cancel := 'C';

    g_sched_sess := 'S';

    g_cat_type_doc    := 'D';
    g_cat_type_nurse  := 'N';
    g_cat_type_reg    := 'A';
    g_cat_type_fisio  := 'F';
    g_cat_type_triage := 'M';
    g_cat_type_nutri  := 'U';

    g_flg_time_e := 'E';
    g_flg_time_n := 'N';
    g_flg_time_b := 'B';

    g_flg_status_a := 'A';
    g_flg_status_c := 'C';
    g_flg_status_f := 'F';
    g_flg_status_x := 'X';
    g_flg_status_d := 'D';
    g_flg_status_r := 'R';
    g_flg_status_i := 'I';

    g_software_consh  := 1;
    g_software_conscs := 3;
    g_room_pref       := 'Y';

    g_flg_sos        := 'S';
    g_flg_cont       := 'C';
    g_unknown        := 'Y';
    g_definitive     := 'N';
    g_patient_active := 'A';
    --
    g_cat_prof       := 'Y';
    g_category_avail := 'Y';
    g_flg_type_d     := 'D';
    g_flg_type_n     := 'N';

    g_domain_epis_info_flg_status := 'EPIS_INFO.FLG_STATUS';
    g_domain_episode_flg_status   := 'EPISODE.FLG_STATUS';
    g_epis_type                   := 2;

    g_wr_available         := 'WL_WAITING_ROOM_AVAILABLE';
    g_selected             := 'S';
    g_epis_type_edis       := 2;
    g_epis_type_inp        := 5;
    g_epis_type_ubu        := 9;
    g_epis_type_outp       := 1;
    g_epis_type_pp         := 11;
    g_epis_type_nurse      := 14;
    g_epis_type_nurse_outp := 16;
    g_epis_type_nurse_pp   := 17;
    g_epis_type_oris       := 4;
    g_disch_reopen         := 'R';
    --lg 2007-03-02
    g_disch_active := 'A';
    g_reopen       := 'Y';
    --
    g_flg_default := 'Y';
    g_yes         := 'Y';
    g_no          := 'N';

    g_between     := 'B';
    g_flg_co_sign := 'N';

    g_flg_type_s    := 'S';
    g_flg_type_p    := 'P';
    g_consultsubs_y := 'Y';
    g_consultsubs_n := 'N';

    g_complaint := 'C';
    g_activo    := 'A';

    -- ti_log variables
    g_analysis_type_req     := 'AR';
    g_analysis_type_req_det := 'AD';
    g_analysis_type_harv    := 'AH';
    g_exam_type_req         := 'ER';
    g_exam_type_det         := 'ED';

    g_flg_time_betw    := 'B';
    g_flg_time_epis    := 'E';
    g_interv_det_req   := 'R';
    g_interv_det_exec  := 'E';
    g_interv_det_pend  := 'D';
    g_interv_plan_req  := 'R';
    g_interv_plan_pend := 'D';

    -- RL 2008-05-16
    g_epis_type_session := 15;

    g_inp_definitive := 'D';
    g_inp_temporary  := 'T';

    g_profile_type_intern := 'I';

END pk_visit;
/
