/*-- Last Change Revision: $Rev: 2000569 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-11-05 15:35:04 +0000 (sex, 05 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_exam IS

    FUNCTION create_exam_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL,
        i_exam_req_det            IN table_number,
        i_exam_content            IN table_varchar,
        i_flg_type                IN table_varchar,
        i_exam_codification       IN table_number,
        i_dt_req                  IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis               IN table_clob,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_varchar,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam              table_number := table_number();
        l_clinical_question table_table_number := table_table_number();
        l_response          table_table_varchar := table_table_varchar();
    
        l_flg_show  VARCHAR2(10);
        l_msg_title VARCHAR2(10);
        l_msg_req   VARCHAR2(10);
        l_button    VARCHAR2(10);
    
    BEGIN
    
        FOR i IN 1 .. i_exam_content.count
        LOOP
            l_exam.extend;
        
            g_error := 'CALL GET_EXAM_BY_ID_CONTENT';
            IF NOT pk_api_exam.get_exam_by_id_content(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_content => i_exam_content(i),
                                                      o_exam    => l_exam(i),
                                                      o_error   => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_clinical_question.extend;
            l_clinical_question(i) := table_number();
        
            l_response.extend;
            l_response(i) := table_varchar();
        
            FOR j IN 1 .. i_clinical_question(i).count
            LOOP
                IF i_clinical_question(i) (j) IS NOT NULL
                THEN
                    l_clinical_question(i).extend();
                    l_response(i).extend();
                
                    g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - CQ';
                    IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_content  => i_clinical_question(i) (j),
                                                                 i_flg_type => 'CQ',
                                                                 o_id       => l_clinical_question(i)
                                                                               (l_clinical_question(i).count),
                                                                 o_error    => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF i_response(i) (j) IS NOT NULL
                    THEN
                        g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - R';
                        IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_content  => i_response(i) (j),
                                                                     i_flg_type => 'R',
                                                                     o_id       => l_response(i) (l_response(i).count),
                                                                     o_error    => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    ELSE
                        l_response(i)(j) := i_response(i) (j);
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
    
        g_error := 'CALL PK_EXAMS_API_DB.CREATE_EXAM_ORDER';
        IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_patient                 => i_patient,
                                                 i_episode                 => i_episode,
                                                 i_exam_req                => i_exam_req,
                                                 i_exam_req_det            => i_exam_req_det,
                                                 i_exam                    => l_exam,
                                                 i_flg_type                => i_flg_type,
                                                 i_dt_req                  => i_dt_req,
                                                 i_flg_time                => i_flg_time,
                                                 i_dt_begin                => i_dt_begin,
                                                 i_dt_begin_limit          => i_dt_begin_limit,
                                                 i_episode_destination     => i_episode_destination,
                                                 i_order_recurrence        => i_order_recurrence,
                                                 i_priority                => i_priority,
                                                 i_flg_prn                 => i_flg_prn,
                                                 i_notes_prn               => i_notes_prn,
                                                 i_flg_fasting             => i_flg_fasting,
                                                 i_notes                   => i_notes,
                                                 i_notes_scheduler         => i_notes_scheduler,
                                                 i_notes_technician        => i_notes_technician,
                                                 i_notes_patient           => i_notes_patient,
                                                 i_diagnosis_notes         => NULL,
                                                 i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                        i_prof   => i_prof,
                                                                                                        i_params => i_diagnosis),
                                                 i_laterality              => i_laterality,
                                                 i_exec_room               => i_exec_room,
                                                 i_exec_institution        => i_exec_institution,
                                                 i_clinical_purpose        => i_clinical_purpose,
                                                 i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                 i_codification            => i_exam_codification,
                                                 i_health_plan             => i_health_plan,
                                                 i_exemption               => i_exemption,
                                                 i_prof_order              => i_prof_order,
                                                 i_dt_order                => i_dt_order,
                                                 i_order_type              => i_order_type,
                                                 i_clinical_question       => l_clinical_question,
                                                 i_response                => l_response,
                                                 i_clinical_question_notes => i_clinical_question_notes,
                                                 i_clinical_decision_rule  => i_clinical_decision_rule,
                                                 i_flg_origin_req          => i_flg_origin_req,
                                                 i_task_dependency         => i_task_dependency,
                                                 i_flg_task_depending      => i_flg_task_depending,
                                                 i_episode_followup_app    => i_episode_followup_app,
                                                 i_schedule_followup_app   => i_schedule_followup_app,
                                                 i_event_followup_app      => i_event_followup_app,
                                                 i_test                    => pk_exam_constant.g_no,
                                                 o_flg_show                => l_flg_show,
                                                 o_msg_title               => l_msg_title,
                                                 o_msg_req                 => l_msg_req,
                                                 o_button                  => l_button,
                                                 o_exam_req_array          => o_exam_req_array,
                                                 o_exam_req_det_array      => o_exam_req_det_array,
                                                 o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EXAM_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_exam_order;

    FUNCTION create_exam_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_schedule       IN schedule_exam.id_schedule%TYPE,
        i_exam_req_det   IN table_number,
        i_dt_begin       IN VARCHAR2 DEFAULT NULL,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.CREATE_EXAM_VISIT';
        IF NOT pk_exams_api_db.create_exam_visit(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_patient        => i_patient,
                                                 i_episode        => i_episode,
                                                 i_schedule       => i_schedule,
                                                 i_exam_req_det   => i_exam_req_det,
                                                 i_dt_begin       => i_dt_begin,
                                                 i_transaction_id => i_transaction_id,
                                                 o_episode        => o_episode,
                                                 o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EXAM_VISIT',
                                              o_error);
            RETURN FALSE;
    END create_exam_visit;

    FUNCTION set_exam_perform
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_prof_performed        IN exam_req_det.id_prof_performed%TYPE,
        i_start_time            IN VARCHAR2,
        i_end_time              IN VARCHAR2,
        i_supply_workflow       IN table_number,
        i_supply                IN table_number,
        i_supply_set            IN table_number,
        i_supply_qty            IN table_number,
        i_supply_type           IN table_varchar,
        i_barcode_scanned       IN table_varchar,
        i_deliver_needed        IN table_varchar,
        i_flg_cons_type         IN table_varchar,
        i_dt_expiration         IN table_varchar,
        i_flg_validation        IN table_varchar,
        i_lot                   IN table_varchar,
        i_notes_supplies        IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        i_questionnaire         IN table_varchar,
        i_response              IN table_varchar,
        i_notes                 IN table_varchar,
        i_transaction_id        IN VARCHAR2 DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_questionnaire table_number := table_number();
        l_response      table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_questionnaire.count
        LOOP
            l_questionnaire.extend;
        
            g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - CQ';
            IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_content  => i_questionnaire(i),
                                                         i_flg_type => 'CQ',
                                                         o_id       => l_questionnaire(i),
                                                         o_error    => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        FOR i IN 1 .. i_response.count
        LOOP
            l_response.extend;
        
            g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - R';
            IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_content  => i_response(i),
                                                         i_flg_type => 'R',
                                                         o_id       => l_response(i),
                                                         o_error    => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_PERFORM';
        IF NOT pk_exams_api_db.set_exam_perform(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_exam_req_det          => i_exam_req_det,
                                                i_prof_performed        => i_prof_performed,
                                                i_start_time            => i_start_time,
                                                i_end_time              => i_end_time,
                                                i_supply_workflow       => i_supply_workflow,
                                                i_supply                => i_supply,
                                                i_supply_set            => i_supply_set,
                                                i_supply_qty            => i_supply_qty,
                                                i_supply_type           => i_supply_type,
                                                i_barcode_scanned       => i_barcode_scanned,
                                                i_deliver_needed        => i_deliver_needed,
                                                i_flg_cons_type         => i_flg_cons_type,
                                                i_dt_expiration         => i_dt_expiration,
                                                i_flg_validation        => i_flg_validation,
                                                i_lot                   => i_lot,
                                                i_notes_supplies        => i_notes_supplies,
                                                i_doc_template          => i_doc_template,
                                                i_flg_type              => i_flg_type,
                                                i_id_documentation      => i_id_documentation,
                                                i_id_doc_element        => i_id_doc_element,
                                                i_id_doc_element_crit   => i_id_doc_element_crit,
                                                i_value                 => i_value,
                                                i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                i_documentation_notes   => i_documentation_notes,
                                                i_questionnaire         => l_questionnaire,
                                                i_response              => l_response,
                                                i_notes                 => i_notes,
                                                i_transaction_id        => i_transaction_id,
                                                o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_PERFORM',
                                              o_error);
            RETURN FALSE;
    END set_exam_perform;

    FUNCTION set_exam_result
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN exam_result.id_patient%TYPE,
        i_episode               IN exam_result.id_episode_write%TYPE,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result           IN exam_req_det.id_exam_req_det%TYPE DEFAULT NULL,
        i_dt_result             IN VARCHAR2 DEFAULT NULL,
        i_result_status         IN result_status.id_result_status%TYPE,
        i_abnormality           IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin     IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes   IN exam_result.result_origin_notes%TYPE,
        i_flg_import            IN table_varchar,
        i_id_doc                IN table_number,
        i_doc_type              IN table_number,
        i_desc_doc_type         IN table_varchar,
        i_dt_doc                IN table_varchar,
        i_dest                  IN table_number,
        i_desc_dest             IN table_varchar,
        i_ori_doc_type          IN table_number,
        i_desc_ori_doc_type     IN table_varchar,
        i_original              IN table_number,
        i_desc_original         IN table_varchar,
        i_title                 IN table_varchar,
        i_desc_perf_by          IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        o_exam_result           OUT exam_result.id_exam_result%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_RESULT';
        IF NOT pk_exams_api_db.set_exam_result(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_patient               => i_patient,
                                               i_episode               => i_episode,
                                               i_exam_req_det          => i_exam_req_det,
                                               i_exam_result           => i_exam_result,
                                               i_dt_result             => i_dt_result,
                                               i_result_status         => i_result_status,
                                               i_abnormality           => i_abnormality,
                                               i_flg_result_origin     => i_flg_result_origin,
                                               i_result_origin_notes   => i_result_origin_notes,
                                               i_flg_import            => i_flg_import,
                                               i_id_doc                => i_id_doc,
                                               i_doc_type              => i_doc_type,
                                               i_desc_doc_type         => i_desc_doc_type,
                                               i_dt_doc                => i_dt_doc,
                                               i_dest                  => i_dest,
                                               i_desc_dest             => i_desc_dest,
                                               i_ori_doc_type          => i_ori_doc_type,
                                               i_desc_ori_doc_type     => i_desc_ori_doc_type,
                                               i_original              => i_original,
                                               i_desc_original         => i_desc_original,
                                               i_title                 => i_title,
                                               i_desc_perf_by          => i_desc_perf_by,
                                               i_doc_template          => i_doc_template,
                                               i_flg_type              => i_flg_type,
                                               i_id_documentation      => i_id_documentation,
                                               i_id_doc_element        => i_id_doc_element,
                                               i_id_doc_element_crit   => i_id_doc_element_crit,
                                               i_value                 => i_value,
                                               i_id_doc_element_qualif => i_id_doc_element_qualif,
                                               i_documentation_notes   => i_documentation_notes,
                                               o_exam_result           => o_exam_result,
                                               o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_RESULT',
                                              o_error);
            RETURN FALSE;
    END set_exam_result;

    FUNCTION set_exam_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req        IN exam_req.id_exam_req%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_notes_scheduler IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_EXAMS_API_DB.CALL_SET_EXAM_DATE';
        IF NOT pk_exams_api_db.set_exam_date(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_exam_req        => i_exam_req,
                                             i_dt_begin        => i_dt_begin,
                                             i_notes_scheduler => i_notes_scheduler,
                                             o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_DATE',
                                              o_error);
            RETURN FALSE;
    END set_exam_date;

    FUNCTION set_exam_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN table_number,
        i_status          IN VARCHAR2,
        i_notes           IN table_varchar,
        i_notes_scheduler IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.SET_EXAM_STATUS';
        IF NOT pk_exams_api_db.set_exam_status(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_exam_req_det    => i_exam_req_det,
                                               i_status          => i_status,
                                               i_notes           => i_notes,
                                               i_notes_scheduler => i_notes_scheduler,
                                               o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_exam_status;

    FUNCTION set_exam_status_undo
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_error VARCHAR2(1000 CHAR);
    
    BEGIN
    
        FOR i IN 1 .. i_exam_req_det.count
        LOOP
            g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.REACTIVATE_EXAM_TASK';
            IF NOT pk_exams_external_api_db.reactivate_exam_task(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_id_task   => i_exam_req_det(i),
                                                                 o_msg_error => l_msg_error,
                                                                 o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_STATUS_UNDO',
                                              o_error);
            RETURN FALSE;
    END set_exam_status_undo;

    FUNCTION set_exam_mov_end
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_movement movement.id_movement%TYPE;
        l_mov_status  movement.flg_status%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT erd.id_movement
              INTO l_id_movement
              FROM exam_req_det erd
             INNER JOIN exam_req er
                ON erd.id_exam_req = er.id_exam_req
             WHERE erd.id_exam_req_det = i_exam_req_det;
        
            IF l_id_movement IS NOT NULL
            THEN
                SELECT m.flg_status
                  INTO l_mov_status
                  FROM movement m
                 WHERE m.id_movement = l_id_movement;
            
                IF l_mov_status IN (pk_alert_constant.g_mov_status_req, pk_alert_constant.g_mov_status_pend)
                THEN
                    IF NOT pk_movement.set_mov_begin(i_lang     => i_lang,
                                                     i_movement => l_id_movement,
                                                     i_prof     => i_prof,
                                                     o_error    => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                IF l_mov_status NOT IN (pk_alert_constant.g_mov_status_finish,
                                        pk_alert_constant.g_mov_status_interr,
                                        pk_alert_constant.g_mov_status_cancel)
                THEN
                    IF NOT pk_movement.set_mov_end(i_lang          => i_lang,
                                                   i_movement      => l_id_movement,
                                                   i_prof          => i_prof,
                                                   i_prof_cat_type => NULL,
                                                   o_error         => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_movement := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_MOV_END',
                                              o_error);
            RETURN FALSE;
    END set_exam_mov_end;

    FUNCTION update_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE,
        i_exam_req_det            IN table_number, --5
        i_exam_content            IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --10
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --15
        i_diagnosis               IN table_clob,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number, --20
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number, --25
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_varchar,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exam              table_number := table_number();
        l_clinical_question table_table_number := table_table_number();
        l_response          table_table_varchar := table_table_varchar();
    
    BEGIN
    
        FOR i IN 1 .. i_exam_content.count
        LOOP
            l_exam.extend;
        
            g_error := 'CALL GET_EXAM_BY_ID_CONTENT';
            IF NOT pk_api_exam.get_exam_by_id_content(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_content => i_exam_content(i),
                                                      o_exam    => l_exam(i),
                                                      o_error   => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            FOR j IN 1 .. i_clinical_question.count
            LOOP
                l_clinical_question.extend;
            
                IF i_clinical_question(i).count > 0
                THEN
                    g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - CQ';
                    IF i_clinical_question(i) (j) IS NOT NULL
                    THEN
                        IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_content  => i_clinical_question(i) (j),
                                                                     i_flg_type => 'CQ',
                                                                     o_id       => l_clinical_question(i)
                                                                                   (l_clinical_question.count),
                                                                     o_error    => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        
            FOR j IN 1 .. i_response.count
            LOOP
                l_response.extend;
            
                g_error := 'CALL GET_EXAM_CQ_BY_ID_CONTENT - R';
                IF i_response(i).count > 0
                THEN
                    IF i_response(i) (j) IS NOT NULL
                    THEN
                        IF NOT pk_api_exam.get_exam_cq_by_id_content(i_lang     => i_lang,
                                                                     i_prof     => i_prof,
                                                                     i_content  => i_response(i) (j),
                                                                     i_flg_type => 'R',
                                                                     o_id       => l_response(i) (l_response.count),
                                                                     o_error    => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
    
        g_error := 'CALL PK_EXAMS_API_DB.UPDATE_EXAM_ORDER';
        IF NOT pk_exams_api_db.update_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_episode                 => i_episode,
                                                 i_exam_req                => i_exam_req,
                                                 i_exam_req_det            => i_exam_req_det,
                                                 i_exam                    => l_exam,
                                                 i_dt_begin                => i_dt_begin,
                                                 i_priority                => i_priority,
                                                 i_flg_prn                 => i_flg_prn,
                                                 i_notes_prn               => i_notes_prn,
                                                 i_flg_fasting             => i_flg_fasting,
                                                 i_notes                   => i_notes,
                                                 i_notes_scheduler         => i_notes_scheduler,
                                                 i_notes_technician        => i_notes_technician,
                                                 i_notes_patient           => i_notes_patient,
                                                 i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                        i_prof   => i_prof,
                                                                                                        i_params => i_diagnosis),
                                                 i_laterality              => i_laterality,
                                                 i_exec_room               => i_exec_room,
                                                 i_exec_institution        => i_exec_institution,
                                                 i_clinical_purpose        => i_clinical_purpose,
                                                 i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                 i_codification            => i_codification,
                                                 i_health_plan             => i_health_plan,
                                                 i_exemption               => i_exemption,
                                                 i_prof_order              => i_prof_order,
                                                 i_dt_order                => i_dt_order,
                                                 i_order_type              => i_order_type,
                                                 i_clinical_question       => l_clinical_question,
                                                 i_response                => l_response,
                                                 i_clinical_question_notes => i_clinical_question_notes,
                                                 o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_EXAM_ORDER',
                                              o_error);
            RETURN FALSE;
    END update_exam_order;

    FUNCTION update_exam_result
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN exam_result.id_patient%TYPE,
        i_episode               IN exam_result.id_episode_write%TYPE,
        i_exam_result           IN exam_result.id_exam_result%TYPE,
        i_result_status         IN result_status.id_result_status%TYPE,
        i_abnormality           IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin     IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes   IN exam_result.result_origin_notes%TYPE,
        i_flg_import            IN table_varchar,
        i_id_doc                IN table_number,
        i_doc_type              IN table_number,
        i_desc_doc_type         IN table_varchar,
        i_dt_doc                IN table_varchar,
        i_dest                  IN table_number,
        i_desc_dest             IN table_varchar,
        i_ori_doc_type          IN table_number,
        i_desc_ori_doc_type     IN table_varchar,
        i_original              IN table_number,
        i_desc_original         IN table_varchar,
        i_title                 IN table_varchar,
        i_desc_perf_by          IN table_varchar,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_flg_type              IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.UPDATE_EXAM_RESULT';
        IF NOT pk_exams_api_db.update_exam_result(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_patient               => i_patient,
                                                  i_episode               => i_episode,
                                                  i_exam_result           => i_exam_result,
                                                  i_result_status         => i_result_status,
                                                  i_abnormality           => i_abnormality,
                                                  i_flg_result_origin     => i_flg_result_origin,
                                                  i_result_origin_notes   => i_result_origin_notes,
                                                  i_flg_import            => i_flg_import,
                                                  i_id_doc                => i_id_doc,
                                                  i_doc_type              => i_doc_type,
                                                  i_desc_doc_type         => i_desc_doc_type,
                                                  i_dt_doc                => i_dt_doc,
                                                  i_dest                  => i_dest,
                                                  i_desc_dest             => i_desc_dest,
                                                  i_ori_doc_type          => i_ori_doc_type,
                                                  i_desc_ori_doc_type     => i_desc_ori_doc_type,
                                                  i_original              => i_original,
                                                  i_desc_original         => i_desc_original,
                                                  i_title                 => i_title,
                                                  i_desc_perf_by          => i_desc_perf_by,
                                                  i_doc_template          => i_doc_template,
                                                  i_flg_type              => i_flg_type,
                                                  i_id_documentation      => i_id_documentation,
                                                  i_id_doc_element        => i_id_doc_element,
                                                  i_id_doc_element_crit   => i_id_doc_element_crit,
                                                  i_value                 => i_value,
                                                  i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                  i_documentation_notes   => i_documentation_notes,
                                                  o_error                 => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_EXAM_RESULT',
                                              o_error);
            RETURN FALSE;
    END update_exam_result;

    FUNCTION update_exam_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req        IN table_number,
        i_dt_begin        IN table_varchar,
        i_notes_scheduler IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.UPDATE_EXAM_DATE';
        IF NOT pk_exams_api_db.update_exam_date(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_exam_req        => i_exam_req,
                                                i_dt_begin        => i_dt_begin,
                                                i_notes_scheduler => i_notes_scheduler,
                                                o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_EXAM_DATE',
                                              o_error);
            RETURN FALSE;
    END update_exam_date;

    FUNCTION cancel_exam_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req       IN table_number,
        i_cancel_reason  IN exam_req.id_cancel_reason%TYPE,
        i_cancel_notes   IN exam_req.notes_cancel%TYPE,
        i_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order       IN VARCHAR2,
        i_order_type     IN co_sign.id_order_type%TYPE,
        i_flg_schedule   IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.CANCEL_EXAM_ORDER';
        IF NOT pk_exams_api_db.cancel_exam_order(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_exam_req       => i_exam_req,
                                                 i_cancel_reason  => i_cancel_reason,
                                                 i_cancel_notes   => i_cancel_notes,
                                                 i_prof_order     => i_prof_order,
                                                 i_dt_order       => i_dt_order,
                                                 i_order_type     => i_order_type,
                                                 i_flg_schedule   => i_flg_schedule,
                                                 i_transaction_id => i_transaction_id,
                                                 o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EXAM_ORDER',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_order;

    FUNCTION cancel_exam_request
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req_det   IN table_number,
        i_dt_cancel      IN VARCHAR2,
        i_cancel_reason  IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes   IN exam_req_det.notes_cancel%TYPE,
        i_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order       IN VARCHAR2,
        i_order_type     IN co_sign.id_order_type%TYPE,
        i_flg_schedule   IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.CANCEL_EXAM_REQUEST';
        IF NOT pk_exams_api_db.cancel_exam_request(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_exam_req_det   => i_exam_req_det,
                                                   i_dt_cancel      => i_dt_cancel,
                                                   i_cancel_reason  => i_cancel_reason,
                                                   i_cancel_notes   => i_cancel_notes,
                                                   i_prof_order     => i_prof_order,
                                                   i_dt_order       => i_dt_order,
                                                   i_order_type     => i_order_type,
                                                   i_flg_schedule   => i_flg_schedule,
                                                   i_transaction_id => i_transaction_id,
                                                   o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EXAM_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_request;

    FUNCTION cancel_exam_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result   IN exam_result.id_exam_result%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN exam_result.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_API_DB.CANCEL_EXAM_RESULT';
        IF NOT pk_exams_api_db.cancel_exam_result(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_exam_req_det  => i_exam_req_det,
                                                  i_exam_result   => i_exam_result,
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_notes_cancel  => i_notes_cancel,
                                                  o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EXAM_RESULT',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_result;

    FUNCTION get_exam_movement
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_id_room_from OUT movement.id_room_from%TYPE,
        o_id_room_to   OUT movement.id_room_to%TYPE,
        o_id_necessity OUT movement.id_necessity%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_movement movement.id_movement%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT erd.id_movement
              INTO l_id_movement
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = i_exam_req_det;
        
            IF l_id_movement IS NOT NULL
            THEN
                SELECT m.id_room_from, m.id_room_to, m.id_necessity
                  INTO o_id_room_from, o_id_room_to, o_id_necessity
                  FROM movement m
                 WHERE m.id_movement = l_id_movement;
            ELSE
                o_id_room_from := NULL;
                o_id_room_to   := NULL;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_id_room_from := NULL;
                o_id_room_to   := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_MOVEMENT',
                                              o_error);
            RETURN FALSE;
    END get_exam_movement;

    FUNCTION get_exam_by_id_content
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_content IN VARCHAR2,
        o_exam    OUT exam.id_exam%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET ID_EXAM';
        SELECT e.id_exam
          INTO o_exam
          FROM exam e
         WHERE e.id_content = i_content;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_exam_by_id_content;

    FUNCTION get_exam_cq_by_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_content  IN VARCHAR2,
        i_flg_type IN VARCHAR2,
        o_id       OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_type = 'CQ'
        THEN
            g_error := 'GET ID_QUESTIONNAIRE';
            SELECT q.id_questionnaire
              INTO o_id
              FROM questionnaire q
             WHERE q.id_content = i_content;
        ELSE
            g_error := 'GET ID_RESPONSE';
            SELECT r.id_response
              INTO o_id
              FROM response r
             WHERE r.id_content = i_content;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_CQ_BY_ID_CONTENT',
                                              o_error);
            RETURN FALSE;
    END get_exam_cq_by_id_content;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_exam;
/
