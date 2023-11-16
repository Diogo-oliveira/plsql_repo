/*-- Last Change Revision: $Rev: 2027134 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exams_api_db IS

    FUNCTION create_exam_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL,
        i_exam_req_det            IN table_number,
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
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
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_laterality              IN table_varchar DEFAULT NULL,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar DEFAULT NULL,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number DEFAULT NULL,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_exam_req_array          OUT NOCOPY table_number,
        o_exam_req_det_array      OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notes_patient table_clob := table_clob();
    
    BEGIN
    
        FOR i IN 1 .. i_notes_patient.count
        LOOP
            l_notes_patient.extend;
            l_notes_patient(i) := i_notes_patient(i);
        END LOOP;
    
        g_error := 'CALL CREATE_EXAM_REQUEST';
        IF NOT pk_exam_core.create_exam_order(i_lang                    => i_lang,
                                              i_prof                    => i_prof,
                                              i_patient                 => i_patient,
                                              i_episode                 => i_episode,
                                              i_exam_req                => i_exam_req,
                                              i_exam_req_det            => i_exam_req_det,
                                              i_exam                    => i_exam,
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
                                              i_notes_patient           => l_notes_patient,
                                              i_diagnosis_notes         => i_diagnosis_notes,
                                              i_diagnosis               => i_diagnosis,
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
                                              i_clinical_question       => i_clinical_question,
                                              i_response                => i_response,
                                              i_clinical_question_notes => i_clinical_question_notes,
                                              i_clinical_decision_rule  => i_clinical_decision_rule,
                                              i_flg_origin_req          => i_flg_origin_req,
                                              i_task_dependency         => i_task_dependency,
                                              i_flg_task_depending      => i_flg_task_depending,
                                              i_episode_followup_app    => i_episode_followup_app,
                                              i_schedule_followup_app   => i_schedule_followup_app,
                                              i_event_followup_app      => i_event_followup_app,
                                              i_test                    => i_test,
                                              o_flg_show                => o_flg_show,
                                              o_msg_title               => o_msg_title,
                                              o_msg_req                 => o_msg_req,
                                              o_button                  => o_button,
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

    FUNCTION create_exam_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_exam_core.create_exam_recurrence(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_exec_tab        => i_exec_tab,
                                                   o_exec_to_process => o_exec_to_process,
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
                                              'CREATE_EXAM_RECURRENCE',
                                              o_error);
            RETURN FALSE;
    END create_exam_recurrence;

    FUNCTION create_exam_with_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_flg_pregnancy       IN VARCHAR2 DEFAULT 'N',
        i_result_status       IN result_status.id_result_status%TYPE DEFAULT NULL,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_EXAM_REQUEST';
        IF NOT pk_exam_core.create_exam_with_result(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_patient             => i_patient,
                                                    i_episode             => i_episode,
                                                    i_exam_req_det        => i_exam_req_det,
                                                    i_reg                 => i_reg,
                                                    i_exam                => i_exam,
                                                    i_prof_performed      => i_prof_performed,
                                                    i_start_time          => i_start_time,
                                                    i_end_time            => i_end_time,
                                                    i_flg_pregnancy       => i_flg_pregnancy,
                                                    i_result_status       => i_result_status,
                                                    i_flg_result_origin   => i_flg_result_origin,
                                                    i_result_origin_notes => i_result_origin_notes,
                                                    i_notes               => i_notes,
                                                    i_flg_import          => i_flg_import,
                                                    i_id_doc              => i_id_doc,
                                                    i_doc_type            => i_doc_type,
                                                    i_desc_doc_type       => i_desc_doc_type,
                                                    i_dt_doc              => i_dt_doc,
                                                    i_dest                => i_dest,
                                                    i_desc_dest           => i_desc_dest,
                                                    i_ori_doc_type        => i_ori_doc_type,
                                                    i_desc_ori_doc_type   => i_desc_ori_doc_type,
                                                    i_original            => i_original,
                                                    i_desc_original       => i_desc_original,
                                                    i_title               => i_title,
                                                    i_desc_perf_by        => i_desc_perf_by,
                                                    o_exam_req            => o_exam_req,
                                                    o_exam_req_det        => o_exam_req_det,
                                                    o_error               => o_error)
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
                                              'CREATE_EXAM_WITH_RESULT',
                                              o_error);
            RETURN FALSE;
    END create_exam_with_result;

    FUNCTION create_exam_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_schedule       IN schedule_exam.id_schedule%TYPE,
        i_exam_req_det   IN table_number,
        i_dt_begin       IN VARCHAR2 DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_EXAM_VISIT';
        IF NOT pk_exam_core.create_exam_visit(i_lang           => i_lang,
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
        i_questionnaire         IN table_number,
        i_response              IN table_varchar,
        i_notes                 IN table_varchar,
        i_transaction_id        IN VARCHAR2 DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_EXAM_PERFORM';
        IF NOT pk_exam_core.set_exam_perform(i_lang                  => i_lang,
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
                                             i_questionnaire         => i_questionnaire,
                                             i_response              => i_response,
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
    
        g_error := 'CALL CREATE_EXAM_REQUEST';
        IF NOT pk_exam_core.set_exam_result(i_lang                  => i_lang,
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
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_STATUS';
        IF NOT pk_exam_core.set_exam_status(i_lang            => i_lang,
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

    FUNCTION set_exam_status_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN table_number,
        i_exam_result   IN table_table_number,
        i_flg_relevant  IN table_table_varchar,
        i_diagnosis     IN pk_edis_types.table_in_epis_diagnosis DEFAULT NULL,
        i_result_notes  IN exam_result.id_result_notes%TYPE,
        i_notes_result  IN exam_result.notes_result%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_STATUS_READ';
        IF NOT pk_exam_core.set_exam_status_read(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_exam_req_det  => i_exam_req_det,
                                                 i_exam_result   => i_exam_result,
                                                 i_flg_relevant  => i_flg_relevant,
                                                 i_diagnosis     => i_diagnosis,
                                                 i_result_notes  => i_result_notes,
                                                 i_notes_result  => i_notes_result,
                                                 i_cancel_reason => i_cancel_reason,
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
                                              'SET_EXAM_STATUS_READ',
                                              o_error);
            RETURN FALSE;
    END set_exam_status_read;

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
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_DATE';
        IF NOT pk_exam_core.set_exam_date(i_lang            => i_lang,
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

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS.SET_EXAM_GRID_TASK';
        IF NOT pk_exams.set_exam_grid_task(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_patient      => i_patient,
                                           i_episode      => i_episode,
                                           i_exam_req     => i_exam_req,
                                           i_exam_req_det => i_exam_req_det,
                                           o_error        => o_error)
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
                                              'SET_EXAM_GRID_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_grid_task;

    FUNCTION update_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE,
        i_exam_req_det            IN table_number, --5
        i_exam                    IN table_number,
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --10
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --15
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
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
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.UPDATE_EXAM_ORDER';
        IF NOT pk_exam_core.update_exam_order(i_lang                    => i_lang,
                                              i_prof                    => i_prof,
                                              i_episode                 => i_episode,
                                              i_exam_req                => i_exam_req,
                                              i_exam_req_det            => i_exam_req_det,
                                              i_exam                    => i_exam,
                                              i_flg_time                => NULL,
                                              i_dt_begin                => i_dt_begin,
                                              i_priority                => i_priority,
                                              i_flg_prn                 => i_flg_prn,
                                              i_notes_prn               => i_notes_prn,
                                              i_flg_fasting             => i_flg_fasting,
                                              i_notes                   => i_notes,
                                              i_notes_scheduler         => i_notes_scheduler,
                                              i_notes_technician        => i_notes_technician,
                                              i_notes_patient           => i_notes_patient,
                                              i_diagnosis_notes         => NULL,
                                              i_diagnosis               => i_diagnosis,
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
                                              i_clinical_question       => i_clinical_question,
                                              i_response                => i_response,
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
    
        g_error := 'CALL UPDATE_EXAM_RESULT';
        IF NOT pk_exam_core.update_exam_result(i_lang                  => i_lang,
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
                                               i_btn                   => NULL,
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
    
        g_error := 'CALL PK_EXAM_CORE.UPDATE_EXAM_DATE';
        IF NOT pk_exam_core.update_exam_date(i_lang            => i_lang,
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
    
        g_error := 'CALL PK_EXAM_CORE.CANCEL_EXAM_ORDER';
        IF NOT pk_exam_core.cancel_exam_order(i_lang           => i_lang,
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN exam_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        i_flg_schedule     IN VARCHAR2 DEFAULT pk_exam_constant.g_yes,
        i_transaction_id   IN VARCHAR2,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.CANCEL_EXAM_REQUEST';
        IF NOT pk_exam_core.cancel_exam_request(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_exam_req_det     => i_exam_req_det,
                                                i_dt_cancel        => i_dt_cancel,
                                                i_cancel_reason    => i_cancel_reason,
                                                i_cancel_notes     => i_cancel_notes,
                                                i_prof_order       => i_prof_order,
                                                i_dt_order         => i_dt_order,
                                                i_order_type       => i_order_type,
                                                i_flg_schedule     => i_flg_schedule,
                                                i_transaction_id   => i_transaction_id,
                                                i_flg_cancel_event => i_flg_cancel_event,
                                                o_error            => o_error)
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
    FUNCTION cancel_exam_perform
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN exam_req_det.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CANCEL_EXAM_RESULT';
        IF NOT pk_exam_core.cancel_exam_perform(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_exam_req_det  => i_exam_req_det,
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
                                              'CANCEL_EXAM_PERFORM',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_perform;

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
    
        g_error := 'CALL CANCEL_EXAM_RESULT';
        IF NOT pk_exam_core.cancel_exam_result(i_lang          => i_lang,
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

    FUNCTION cancel_exam_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_exam_core.cancel_exam_schedule(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_exam_req => i_exam_req,
                                                 o_error    => o_error)
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
                                              'CANCEL_EXAM_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_schedule;

    FUNCTION get_exam_selection_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN VARCHAR2 DEFAULT pk_exam_constant.g_exam_freq,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN t_tbl_exams_for_selection IS
    
    BEGIN
    
        RETURN pk_exam_core.get_exam_selection_list(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_patient       => i_patient,
                                                    i_episode       => i_episode,
                                                    i_exam_type     => i_exam_type,
                                                    i_flg_type      => i_flg_type,
                                                    i_codification  => i_codification,
                                                    i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_exam_selection_list;

    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN exam_dep_clin_serv.flg_type%TYPE DEFAULT pk_exam_constant.g_exam_can_req,
        i_codification  IN codification.id_codification%TYPE,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE,
        i_value         IN VARCHAR2
    ) RETURN t_table_exams_search IS
    
    BEGIN
    
        RETURN pk_exam_core.get_exam_search(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_exam_type     => i_exam_type,
                                            i_flg_type      => i_flg_type,
                                            i_codification  => i_codification,
                                            i_dep_clin_serv => i_dep_clin_serv,
                                            i_value         => i_value);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_exam_search;

    FUNCTION get_exam_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_codification  IN codification.id_codification%TYPE DEFAULT NULL,
        i_dep_clin_serv IN exam_cat_dcs.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_value         IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_exam_core.get_exam_search(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_exam_type     => i_exam_type,
                                            i_codification  => i_codification,
                                            i_dep_clin_serv => i_dep_clin_serv,
                                            i_value         => i_value,
                                            o_flg_show      => o_flg_show,
                                            o_msg           => o_msg,
                                            o_msg_title     => o_msg_title,
                                            o_list          => o_list,
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
                                              'GET_EXAM_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_search;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_exam_core.get_exam_category_search(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_patient       => i_patient,
                                                     i_exam_type     => i_exam_type,
                                                     i_codification  => i_codification,
                                                     i_dep_clin_serv => i_dep_clin_serv,
                                                     o_list          => o_list,
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
                                              'GET_EXAM_CATEGORY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_category_search;

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
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT gender, trunc(months_between(SYSDATE, dt_birth) / 12) age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_pat           c_pat%ROWTYPE;
        l_prof_cat_type category.flg_type%TYPE;
        l_prof_access   PLS_INTEGER;
        l_msg           sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T117');
    
    BEGIN
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_pat;
        CLOSE c_pat;
    
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'GET PROF ACCESS';
        BEGIN
            SELECT COUNT(1)
              INTO l_prof_access
              FROM group_access ga
             INNER JOIN group_access_prof gaf
                ON gaf.id_group_access = ga.id_group_access
             INNER JOIN group_access_record gar
                ON gar.id_group_access = ga.id_group_access
             INNER JOIN exam e
                ON e.id_exam = gar.id_record
             WHERE gaf.id_professional = i_prof.id
               AND gaf.flg_available = pk_exam_constant.g_available
               AND ga.id_institution IN (i_prof.institution, 0)
               AND ga.flg_type = 'E'
               AND ga.flg_available = pk_exam_constant.g_available
               AND gar.flg_type = 'E'
               AND e.flg_type = i_exam_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_access := 0;
        END;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT e.id_exam,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) desc_exam,
                   decode(edcs.flg_execute, pk_exam_constant.g_no, l_msg, NULL) desc_perform,
                   'E' TYPE,
                   pk_touch_option.get_doc_template_internal(i_lang,
                                                             i_prof,
                                                             NULL,
                                                             NULL,
                                                             pk_exam_constant.g_doc_area_exam,
                                                             e.id_exam) doc_template_exam,
                   pk_touch_option.get_doc_template_internal(i_lang,
                                                             i_prof,
                                                             NULL,
                                                             NULL,
                                                             pk_exam_constant.g_doc_area_exam_result,
                                                             e.id_exam) doc_template_exam_result
              FROM exam e,
                   (SELECT *
                      FROM exam_dep_clin_serv
                     WHERE flg_type = pk_exam_constant.g_exam_can_req
                       AND id_software = i_prof.software
                       AND id_institution = i_prof.institution) edcs,
                   (SELECT DISTINCT id_exam
                      FROM exam_questionnaire
                     WHERE flg_time = pk_exam_constant.g_exam_cq_on_order
                       AND id_institution = i_prof.institution
                       AND flg_available = pk_exam_constant.g_available) eq,
                   (SELECT DISTINCT gar.id_record id_exam
                      FROM group_access ga
                     INNER JOIN group_access_prof gaf
                        ON gaf.id_group_access = ga.id_group_access
                     INNER JOIN group_access_record gar
                        ON gar.id_group_access = ga.id_group_access
                     WHERE gaf.id_professional = i_prof.id
                       AND ga.id_institution IN (i_prof.institution, 0)
                       AND ga.flg_type = 'E'
                       AND gar.flg_type = 'E'
                       AND ga.flg_available = pk_exam_constant.g_available
                       AND gaf.flg_available = pk_exam_constant.g_available
                       AND gar.flg_available = pk_exam_constant.g_available) ecs
             WHERE e.flg_type = i_exam_type
               AND e.flg_available = pk_exam_constant.g_available
               AND e.id_exam_cat = i_exam_cat
               AND ((EXISTS
                    (SELECT 1
                        FROM prof_dep_clin_serv pdcs, exam_cat_dcs ecd
                       WHERE id_professional = i_prof.id
                         AND pdcs.id_institution = i_prof.institution
                         AND pdcs.flg_status = pk_exam_constant.g_selected
                         AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                         AND ecd.id_exam_cat = e.id_exam_cat) AND l_prof_cat_type != pk_alert_constant.g_cat_type_doc) OR
                   l_prof_cat_type = pk_alert_constant.g_cat_type_doc)
               AND e.id_exam = edcs.id_exam
               AND (i_codification IS NULL OR (i_codification IS NOT NULL AND EXISTS
                    (SELECT 1
                                                  FROM codification_instit_soft cis, exam_codification ec
                                                 WHERE cis.id_codification = i_codification
                                                   AND cis.id_institution = i_prof.institution
                                                   AND cis.id_software = i_prof.software
                                                   AND cis.id_codification = ec.id_codification
                                                   AND ec.flg_available = pk_exam_constant.g_available
                                                   AND ec.id_exam = e.id_exam)))
               AND e.id_exam = eq.id_exam(+)
               AND e.id_exam = ecs.id_exam(+)
               AND (l_prof_access = 0 OR (l_prof_access != 0 AND ecs.id_exam IS NOT NULL))
               AND (i_patient IS NULL OR
                   (((l_pat.gender IS NOT NULL AND coalesce(e.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_pat.gender)) OR
                   l_pat.gender IS NULL OR l_pat.gender IN ('I', 'U', 'N')) AND
                   (nvl(l_pat.age, 0) BETWEEN nvl(e.age_min, 0) AND nvl(e.age_max, nvl(l_pat.age, 0)) OR
                   nvl(l_pat.age, 0) = 0)))
               AND rownum > 0 -- to solve performance problem when no records are returned
            UNION ALL
            SELECT eg.id_exam_group id_exam,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) desc_exam,
                   'G' TYPE,
                   decode(edcs.flg_execute, pk_exam_constant.g_no, l_msg, NULL) desc_perform,
                   NULL doc_template_exam,
                   NULL doc_template_exam_result
              FROM exam_group eg,
                   exam_egp ee,
                   exam e,
                   (SELECT *
                      FROM exam_dep_clin_serv
                     WHERE flg_type = pk_exam_constant.g_exam_can_req
                       AND id_software = i_prof.software
                       AND id_institution = i_prof.institution) edcs,
                   (SELECT DISTINCT id_exam_group
                      FROM exam_questionnaire
                     WHERE flg_time = pk_exam_constant.g_exam_cq_on_order
                       AND id_institution = i_prof.institution
                       AND flg_available = pk_exam_constant.g_available) eq
             WHERE eg.id_group_parent IS NOT NULL
               AND eg.id_exam_group = ee.id_exam_group
               AND ee.id_exam = e.id_exam
               AND e.flg_type = i_exam_type
               AND e.flg_available = pk_exam_constant.g_available
               AND e.id_exam_cat = i_exam_cat
               AND ((EXISTS
                    (SELECT 1
                        FROM prof_dep_clin_serv pdcs, exam_cat_dcs ecd
                       WHERE id_professional = i_prof.id
                         AND pdcs.id_institution = i_prof.institution
                         AND pdcs.flg_status = pk_exam_constant.g_selected
                         AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                         AND ecd.id_exam_cat = e.id_exam_cat) AND l_prof_cat_type != pk_alert_constant.g_cat_type_doc) OR
                   l_prof_cat_type = pk_alert_constant.g_cat_type_doc)
               AND e.id_exam = edcs.id_exam
               AND (l_prof_access = 0 OR
                   (l_prof_access != 0 AND EXISTS (SELECT 1
                                                      FROM exam_group eg1,
                                                           exam_egp egp,
                                                           (SELECT DISTINCT gar.id_record id_exam
                                                              FROM group_access ga
                                                             INNER JOIN group_access_prof gaf
                                                                ON gaf.id_group_access = ga.id_group_access
                                                             INNER JOIN group_access_record gar
                                                                ON gar.id_group_access = ga.id_group_access
                                                             WHERE gaf.id_professional = i_prof.id
                                                               AND ga.id_institution IN (i_prof.institution, 0)
                                                               AND ga.flg_type = 'E'
                                                               AND gar.flg_type = 'E'
                                                               AND ga.flg_available = pk_exam_constant.g_available
                                                               AND gaf.flg_available = pk_exam_constant.g_available
                                                               AND gar.flg_available = pk_exam_constant.g_available) ecs
                                                     WHERE eg1.id_exam_group = eg.id_exam_group
                                                       AND eg1.id_exam_group = egp.id_exam_group
                                                       AND egp.id_exam = ecs.id_exam
                                                       AND egp.id_exam = ee.id_exam)))
               AND (i_patient IS NULL OR
                   (((l_pat.gender IS NOT NULL AND coalesce(e.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_pat.gender)) OR
                   l_pat.gender IS NULL OR l_pat.gender IN ('I', 'U', 'N')) AND
                   (nvl(l_pat.age, 0) BETWEEN nvl(e.age_min, 0) AND nvl(e.age_max, nvl(l_pat.age, 0)) OR
                   nvl(l_pat.age, 0) = 0)))
               AND rownum > 0 -- to solve performance problem when no records are returned
             ORDER BY desc_exam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_IN_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_in_category;

    FUNCTION get_exam_in_group
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_group   IN exam_group.id_exam_group%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_exam_core.get_exam_in_group(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_exam_group   => i_exam_group,
                                              i_codification => i_codification,
                                              o_list         => o_list,
                                              o_error        => o_error)
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
                                              'GET_EXAM_IN_GROUP',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_in_group;

    FUNCTION get_exam_order_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_exam_req           IN exam_req.id_exam_req%TYPE,
        i_flg_report         IN VARCHAR2 DEFAULT 'N',
        o_exam_order         OUT pk_types.cursor_type,
        o_exam_order_barcode OUT pk_types.cursor_type,
        o_exam_order_history OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_DETAIL';
        IF NOT pk_exam_core.get_exam_order_detail(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_exam_req           => i_exam_req,
                                                  i_flg_report         => i_flg_report,
                                                  o_exam_order         => o_exam_order,
                                                  o_exam_order_barcode => o_exam_order_barcode,
                                                  o_exam_order_history => o_exam_order_history,
                                                  o_error              => o_error)
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
                                              'GET_EXAM_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_order_barcode);
            pk_types.open_my_cursor(o_exam_order_history);
            RETURN FALSE;
    END get_exam_order_detail;

    FUNCTION get_exam_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_EPISODE';
        SELECT nvl(er.id_episode, er.id_episode_origin)
          INTO l_id_episode
          FROM exam_req_det erd
          JOIN exam_req er
            ON er.id_exam_req = erd.id_exam_req
         WHERE erd.id_exam_req_det = i_exam_req_det;
    
        g_error := 'CALL GET_EXAM_DETAIL';
        IF NOT pk_exam_core.get_exam_detail(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_episode      => l_id_episode,
                                            i_exam_req_det => i_exam_req_det,
                                            o_detail       => o_detail,
                                            o_error        => o_error)
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
                                              'GET_EXAM_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_exam_detail;

    FUNCTION get_exam_detail_history
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_detail       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_EPISODE';
        SELECT nvl(er.id_episode, er.id_episode_origin)
          INTO l_id_episode
          FROM exam_req_det erd
          JOIN exam_req er
            ON er.id_exam_req = erd.id_exam_req
         WHERE erd.id_exam_req_det = i_exam_req_det;
    
        g_error := 'CALL GET_EXAM_DETAIL_HISTORY';
        IF NOT pk_exam_core.get_exam_detail_history(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => l_id_episode,
                                                    i_exam_req_det => i_exam_req_det,
                                                    o_detail       => o_detail,
                                                    o_error        => o_error)
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
                                              'GET_EXAM_DETAIL_HISTORY',
                                              o_error);
            RETURN FALSE;
    END get_exam_detail_history;

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_utils.get_alias_translation(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_code_exam     => i_code_exam,
                                                   i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_exam_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_TIME_LIST';
        IF NOT pk_exam_core.get_exam_time_list(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_epis_type => i_epis_type,
                                               i_exam_type => i_exam_type,
                                               o_list      => o_list,
                                               o_error     => o_error)
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
                                              'GET_EXAM_TIME_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_time_list;

    FUNCTION get_exam_result_notes_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_result_notes OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_RESULT_NOTES_LIST';
        IF NOT pk_exam_core.get_exam_result_notes_list(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       o_result_notes => o_result_notes,
                                                       o_error        => o_error)
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
                                              'GET_EXAM_RESULT_NOTES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_result_notes);
            RETURN FALSE;
    END get_exam_result_notes_list;

    FUNCTION get_exam_documents_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_question_response.id_exam_req_det%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL GET_EXAM_DOCUMENTS_LIST';
        IF NOT pk_exam_core.get_exam_documents_list(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_exam_req_det => i_exam_req_det,
                                                    o_list         => o_list,
                                                    o_error        => o_error)
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
                                              'GET_EXAM_DOCUMENTS_LIST',
                                              o_error);
            RETURN FALSE;
    END get_exam_documents_list;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exams_api_db;
/
