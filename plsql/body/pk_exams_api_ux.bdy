/*-- Last Change Revision: $Rev: 2027140 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exams_api_ux IS

    FUNCTION create_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN exam_req.id_episode%TYPE,
        i_exam_req                IN exam_req.id_exam_req%TYPE DEFAULT NULL, --5
        i_exam                    IN table_number,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar, --10
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --15
        i_flg_fasting             IN table_varchar,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_clob, --20
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_laterality              IN table_varchar,
        i_exec_room               IN table_number,
        i_exec_institution        IN table_number, --25
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --30
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --35
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN exam_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar, --40
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
    
    BEGIN
    
        g_error := 'CALL CREATE_EXAM_ORDER';
        IF NOT pk_exam_core.create_exam_order(i_lang                    => i_lang,
                                              i_prof                    => i_prof,
                                              i_patient                 => i_patient,
                                              i_episode                 => i_episode,
                                              i_exam_req                => i_exam_req,
                                              i_exam_req_det            => NULL,
                                              i_exam                    => i_exam,
                                              i_flg_type                => i_flg_type,
                                              i_dt_req                  => NULL,
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
                                              i_diagnosis_notes         => i_diagnosis_notes,
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
            IF o_error.ora_sqlcode IN ('EXAM_M010', 'EXAM_M008')
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF o_flg_show = pk_exam_constant.g_yes
            THEN
                pk_utils.undo_changes;
                RETURN TRUE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_exam_order;

    FUNCTION create_exam_for_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN exam_req.id_episode%TYPE,
        i_exam                  IN table_number,
        i_codification          IN table_number,
        i_flg_type              IN table_varchar,
        i_prof_performed        IN exam_req_det.id_prof_performed%TYPE,
        i_start_time            IN VARCHAR2,
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
        i_doc_flg_type          IN doc_template_context.flg_type%TYPE,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_id_doc_element_qualif IN table_table_number,
        i_documentation_notes   IN epis_documentation.notes%TYPE,
        i_questionnaire         IN table_number,
        i_response              IN table_varchar,
        i_notes                 IN table_varchar,
        o_exam_req_array        OUT NOCOPY table_number,
        o_exam_req_det_array    OUT NOCOPY table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.CREATE_EXAM_FOR_EXECUTION';
        IF NOT pk_exam_core.create_exam_for_execution(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_patient               => i_patient,
                                                      i_episode               => i_episode,
                                                      i_exam                  => i_exam,
                                                      i_codification          => i_codification,
                                                      i_flg_type              => i_flg_type,
                                                      i_prof_performed        => i_prof_performed,
                                                      i_start_time            => i_start_time,
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
                                                      i_doc_flg_type          => i_doc_flg_type,
                                                      i_id_documentation      => i_id_documentation,
                                                      i_id_doc_element        => i_id_doc_element,
                                                      i_id_doc_element_crit   => i_id_doc_element_crit,
                                                      i_value                 => i_value,
                                                      i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                      i_documentation_notes   => i_documentation_notes,
                                                      i_questionnaire         => i_questionnaire,
                                                      i_response              => i_response,
                                                      i_notes                 => i_notes,
                                                      o_exam_req_array        => o_exam_req_array,
                                                      o_exam_req_det_array    => o_exam_req_det_array,
                                                      o_error                 => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EXAM_FOR_EXECUTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_exam_for_execution;

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
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
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
    
        g_error := 'CALL PK_EXAM_CORE.CREATE_EXAM_WITH_RESULT';
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
                                                    i_result_status       => i_result_status,
                                                    i_abnormality         => i_abnormality,
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_exam_with_result;

    FUNCTION create_exam_visit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_schedule     IN schedule_exam.id_schedule%TYPE,
        i_exam_req_det IN table_number,
        o_episode      OUT episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_EXAM_VISIT';
        IF NOT pk_exam_core.create_exam_visit(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_patient      => i_patient,
                                              i_episode      => i_episode,
                                              i_schedule     => i_schedule,
                                              i_exam_req_det => i_exam_req_det,
                                              o_episode      => o_episode,
                                              o_error        => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_exam_visit;

    FUNCTION set_exam_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN table_number,
        i_flg_time                IN table_varchar, --5
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_flg_fasting             IN table_varchar, --10
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar, --15     
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
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar, --30
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_ORDER';
        IF NOT pk_exam_core.set_exam_order(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_episode                 => i_episode,
                                           i_exam_req_det            => i_exam_req_det,
                                           i_flg_time                => i_flg_time,
                                           i_dt_begin                => i_dt_begin,
                                           i_priority                => i_priority,
                                           i_flg_prn                 => i_flg_prn,
                                           i_notes_prn               => i_notes_prn,
                                           i_flg_fasting             => i_flg_fasting,
                                           i_notes                   => i_notes,
                                           i_notes_scheduler         => i_notes_scheduler,
                                           i_notes_technician        => i_notes_technician,
                                           i_notes_patient           => i_notes_patient,
                                           i_diagnosis_notes         => i_diagnosis_notes,
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
                                           i_clinical_question       => i_clinical_question,
                                           i_response                => i_response,
                                           i_clinical_question_notes => i_clinical_question_notes,
                                           o_error                   => o_error)
        THEN
            IF o_error.ora_sqlcode = 'EXAM_M010'
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_order;

    FUNCTION set_exam_time_out
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_test              IN VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT sys_message.desc_message%TYPE,
        o_msg_body              OUT pk_types.cursor_type,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_TIME_OUT';
        IF NOT pk_exam_core.set_exam_time_out(i_lang                  => i_lang,
                                              i_prof                  => i_prof,
                                              i_episode               => i_episode,
                                              i_exam_req_det          => i_exam_req_det,
                                              i_doc_area              => i_doc_area,
                                              i_doc_template          => i_doc_template,
                                              i_epis_documentation    => i_epis_documentation,
                                              i_flg_type              => i_flg_type,
                                              i_id_documentation      => i_id_documentation,
                                              i_id_doc_element        => i_id_doc_element,
                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                              i_value                 => i_value,
                                              i_notes                 => i_notes,
                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                              i_epis_context          => i_epis_context,
                                              i_summary_and_notes     => i_summary_and_notes,
                                              i_episode_context       => i_episode_context,
                                              i_flg_test              => i_flg_test,
                                              o_flg_show              => o_flg_show,
                                              o_msg_title             => o_msg_title,
                                              o_msg_body              => o_msg_body,
                                              o_epis_documentation    => o_epis_documentation,
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
                                              'SET_EXAM_TIME_OUT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_time_out;

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
                                             o_error                 => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_perform;

    FUNCTION set_exam_result
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN exam_result.id_patient%TYPE,
        i_episode               IN exam_result.id_episode_write%TYPE,
        i_exam_req_det          IN exam_req_det.id_exam_req_det%TYPE,
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_result;

    FUNCTION set_exam_import_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN exam_result.id_patient%TYPE,
        i_episode             IN exam_result.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN table_varchar,
        i_external_doc        IN table_number,
        i_external_doc_cancel IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_EXAM_IMPORT_RESULT';
        IF NOT pk_exam_core.set_exam_import_result(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_patient             => i_patient,
                                                   i_episode             => i_episode,
                                                   i_exam_req_det        => i_exam_req_det,
                                                   i_flg_result_origin   => i_flg_result_origin,
                                                   i_result_origin_notes => i_result_origin_notes,
                                                   i_notes               => i_notes,
                                                   i_external_doc        => i_external_doc,
                                                   i_external_doc_cancel => i_external_doc_cancel,
                                                   o_error               => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_IMPORT_RESULT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_import_result;

    FUNCTION set_exam_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN exam_result.id_patient%TYPE,
        i_episode              IN exam_result.id_episode%TYPE,
        i_exam_req_det         IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL SET_EXAM_DOC_ASSOCIATED';
        IF NOT pk_exam_core.set_exam_doc_associated(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_patient              => i_patient,
                                                    i_episode              => i_episode,
                                                    i_exam_req_det         => i_exam_req_det,
                                                    i_flg_import           => i_flg_import,
                                                    i_id_doc               => i_id_doc,
                                                    i_tbl_ds_internal_name => i_tbl_ds_internal_name,
                                                    i_tbl_val              => i_tbl_val,
                                                    i_tbl_real_val         => i_tbl_real_val,
                                                    o_error                => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_DOC_ASSOCIATED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_doc_associated;

    FUNCTION set_exam_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        i_status       IN exam_req_det.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_EXAM_STATUS';
        IF NOT pk_exam_core.set_exam_status(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_exam_req_det    => i_exam_req_det,
                                            i_status          => i_status,
                                            i_notes           => NULL,
                                            i_notes_scheduler => NULL,
                                            o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_status;

    FUNCTION set_exam_status_read
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        i_exam_result  IN table_table_number,
        i_flg_relevant IN table_table_varchar,
        i_diagnosis    IN table_clob,
        i_result_notes IN exam_result.id_result_notes%TYPE,
        i_notes_result IN exam_result.notes_result%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_STATUS_READ';
        IF NOT pk_exam_core.set_exam_status_read(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_exam_req_det => i_exam_req_det,
                                                 i_exam_result  => i_exam_result,
                                                 i_flg_relevant => i_flg_relevant,
                                                 i_diagnosis    => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                             i_prof   => i_prof,
                                                                                             i_params => i_diagnosis),
                                                 i_result_notes => i_result_notes,
                                                 i_notes_result => i_notes_result,
                                                 o_error        => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_status_read;

    FUNCTION set_exam_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_questionnaire IN table_number,
        i_response      IN table_varchar,
        i_notes         IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_QUESTIONNAIRE';
        IF NOT pk_exam_core.set_exam_questionnaire(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_episode       => i_episode,
                                                   i_exam_req_det  => i_exam_req_det,
                                                   i_questionnaire => i_questionnaire,
                                                   i_response      => i_response,
                                                   i_notes         => i_notes,
                                                   o_error         => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EXAM_QUESTIONNAIRE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_questionnaire;

    FUNCTION set_exam_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req        IN table_number,
        i_dt_begin        IN VARCHAR2,
        i_notes_scheduler IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.SET_EXAM_DATE';
        IF NOT pk_exam_core.set_exam_date(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_exam_req        => i_exam_req(1),
                                          i_dt_begin        => i_dt_begin,
                                          i_notes_scheduler => i_notes_scheduler,
                                          o_error           => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_date;

    FUNCTION update_exam_perform
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
    
        g_error := 'CALL CANCEL_EXAM_RESULT';
        IF NOT pk_exam_core.update_exam_perform(i_lang                  => i_lang,
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_EXAM_PERFORM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_exam_perform;

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
        i_btn                   IN sys_button_prop.id_sys_button_prop%TYPE,
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
                                               i_btn                   => i_btn,
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_exam_result;

    FUNCTION update_exam_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN table_number,
        i_exam_req IN table_number,
        i_dt_begin IN table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL UPDATE_EXAM_DATE';
        IF NOT pk_exam_core.update_exam_date(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_exam_req        => i_exam_req,
                                             i_dt_begin        => i_dt_begin,
                                             i_notes_scheduler => NULL,
                                             o_error           => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_exam_date;

    FUNCTION cancel_exam_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req      IN table_number,
        i_cancel_reason IN exam_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN exam_req.notes_cancel%TYPE,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.CANCEL_EXAM_ORDER';
        IF NOT pk_exam_core.cancel_exam_order(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_exam_req      => i_exam_req,
                                              i_cancel_reason => i_cancel_reason,
                                              i_cancel_notes  => i_cancel_notes,
                                              i_prof_order    => i_prof_order,
                                              i_dt_order      => i_dt_order,
                                              i_order_type    => i_order_type,
                                              o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_exam_order;

    FUNCTION cancel_exam_request
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN table_number,
        i_cancel_reason IN exam_req_det.id_cancel_reason%TYPE,
        i_cancel_notes  IN exam_req_det.notes_cancel%TYPE,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.CANCEL_EXAM_REQUEST';
        IF NOT pk_exam_core.cancel_exam_request(i_lang          => i_lang,
                                                i_prof          => i_prof,
                                                i_exam_req_det  => i_exam_req_det,
                                                i_dt_cancel     => NULL,
                                                i_cancel_reason => i_cancel_reason,
                                                i_cancel_notes  => i_cancel_notes,
                                                i_prof_order    => i_prof_order,
                                                i_dt_order      => i_dt_order,
                                                i_order_type    => i_order_type,
                                                o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        COMMIT;
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_exam_result;

    FUNCTION cancel_exam_doc_associated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CANCEL_EXAM_DOC_ASSOCIATED';
        IF NOT pk_exam_core.cancel_exam_doc_associated(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_exam_req_det => i_exam_req_det,
                                                       i_doc_external => i_doc_external,
                                                       o_error        => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EXAM_DOC_ASSOCIATED',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_exam_doc_associated;

    FUNCTION set_technician_grid_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN exam_req.id_patient%TYPE,
        i_episode     IN exam_req.id_episode%TYPE,
        i_exam_req    IN exam_req.id_exam_req%TYPE,
        i_flg_contact IN exam_req.flg_contact%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_TECHNICIAN_GRID_STATUS';
        IF NOT pk_exams.set_technician_grid_status(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_patient     => i_patient,
                                                   i_episode     => i_episode,
                                                   i_exam_req    => i_exam_req,
                                                   i_flg_contact => i_flg_contact,
                                                   o_error       => o_error)
        THEN
            IF o_error.err_desc IS NOT NULL
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TECHNICIAN_GRID_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_technician_grid_status;

    FUNCTION get_technician_grid_view
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_TECHNICIAN_GRID_VIEW';
        IF NOT
            pk_exams.get_technician_grid_view(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
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
                                              'GET_TECHNICIAN_GRID_VIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_technician_grid_view;

    FUNCTION get_technician_grid_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_TECHNICIAN_GRID_LIST';
        IF NOT pk_exams.get_technician_grid_list(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_exam_req => i_exam_req,
                                                 o_list     => o_list,
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
                                              'GET_TECHNICIAN_GRID_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_technician_grid_list;

    FUNCTION get_technician_grid
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_filter IN VARCHAR2,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_TECHNICIAN_GRID';
        IF NOT pk_exams.get_technician_grid(i_lang   => i_lang,
                                            i_prof   => i_prof,
                                            i_filter => i_filter,
                                            o_list   => o_list,
                                            o_error  => o_error)
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
                                              'GET_TECHNICIAN_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_technician_grid;

    FUNCTION check_technician_contact
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam_req  IN exam_req.id_exam_req%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CHECK_TECHNICIAN_CONTACT';
        IF NOT pk_exams.check_technician_contact(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_exam_req  => i_exam_req,
                                                 o_flg_show  => o_flg_show,
                                                 o_msg_title => o_msg_title,
                                                 o_msg       => o_msg,
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
                                              'CHECK_TECHNICIAN_CONTACT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_technician_contact;

    FUNCTION get_exam_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_TO_SCHEDULE_LIST';
        IF NOT pk_exams.get_exam_to_schedule_list(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_patient => i_patient,
                                                  o_list    => o_list,
                                                  o_error   => o_error)
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
                                              'GET_EXAM_TO_SCHEDULE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_to_schedule_list;

    FUNCTION get_exam_thumbnailview
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN exam_req.id_episode%TYPE,
        i_exam_type   IN exam.flg_type%TYPE,
        o_exam_list   OUT pk_types.cursor_type,
        o_filter_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_THUMBNAILVIEW';
        IF NOT pk_exam_core.get_exam_thumbnailview(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_patient     => i_patient,
                                                   i_episode     => i_episode,
                                                   i_exam_type   => i_exam_type,
                                                   o_exam_list   => o_exam_list,
                                                   o_filter_list => o_filter_list,
                                                   o_error       => o_error)
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
                                              'GET_EXAM_THUMBNAILVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_exam_list);
            pk_types.open_my_cursor(o_filter_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_thumbnailview;

    FUNCTION get_exam_timelineview
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN exam_req.id_episode%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_time_list OUT pk_types.cursor_type,
        o_exam_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_TIMELINEVIEW';
        IF NOT pk_exam_core.get_exam_timelineview(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_patient   => i_patient,
                                                  i_exam_type => i_exam_type,
                                                  o_time_list => o_time_list,
                                                  o_exam_list => o_exam_list,
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
                                              'GET_EXAM_TIMELINEVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_time_list);
            pk_types.open_my_cursor(o_exam_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_timelineview;

    FUNCTION get_exam_orders
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_exam    IN exam.id_exam%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_IMAGES';
        IF NOT pk_exam_core.get_exam_orders(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_exam    => i_exam,
                                            o_list    => o_list,
                                            o_error   => o_error)
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
                                              'GET_EXAM_ORDERS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_orders;

    FUNCTION get_exam_questionnaire
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_exam     IN exam.id_exam%TYPE,
        i_flg_type IN VARCHAR2,
        i_flg_time IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_QUESTIONNAIRE';
        IF NOT pk_exam_core.get_exam_questionnaire(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_patient  => i_patient,
                                                   i_episode  => i_episode,
                                                   i_exam     => i_exam,
                                                   i_flg_type => i_flg_type,
                                                   i_flg_time => i_flg_time,
                                                   o_list     => o_list,
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
                                              'GET_EXAM_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_questionnaire;

    FUNCTION get_exam_time_out_completion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_exam_req_det       IN exam_req_det.id_exam_req_det%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_complete       OUT exam_time_out.flg_complete%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_TIME_OUT_COMPLETION';
        IF NOT pk_exam_core.get_exam_time_out_completion(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_exam_req_det       => i_exam_req_det,
                                                         i_epis_documentation => i_epis_documentation,
                                                         o_flg_complete       => o_flg_complete,
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
                                              'GET_EXAM_TIME_OUT_COMPLETION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_time_out_completion;

    FUNCTION get_exam_images
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req.id_exam_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_IMAGES';
        IF NOT pk_exam_core.get_exam_images(i_lang         => i_lang,
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
                                              'GET_EXAM_IMAGES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_images;

    FUNCTION get_exam_codification_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_CODIFICATION_DET';
        IF NOT pk_exam_core.get_exam_codification_det(i_lang         => i_lang,
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
                                              'GET_EXAM_CODIFICATION_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_codification_det;

    FUNCTION get_exam_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_LIST';
        IF NOT pk_exams.get_exam_list(i_lang    => i_lang,
                                      i_prof    => i_prof,
                                      i_patient => i_patient,
                                      i_episode => i_episode,
                                      o_list    => o_list,
                                      o_error   => o_error)
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
                                              'GET_EXAM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_list;

    FUNCTION get_exam_list_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_LIST_EDIT';
        IF NOT pk_exams.get_exam_list_edit(i_lang         => i_lang,
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
                                              'GET_EXAM_LIST_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_list_edit;

    FUNCTION get_exam_order_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_exam_req           IN exam_req.id_exam_req%TYPE,
        o_exam_order         OUT pk_types.cursor_type,
        o_exam_order_barcode OUT pk_types.cursor_type,
        o_exam_order_history OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_ORDER_DETAIL';
        IF NOT pk_exam_core.get_exam_order_detail(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_exam_req           => i_exam_req,
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
                                              'GET_EXAM_ORDER_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_order_barcode);
            pk_types.open_my_cursor(o_exam_order_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_order_detail;

    FUNCTION get_exam_order_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_record IN exam_req.id_exam_req%TYPE,
        i_area      IN dd_content.area%TYPE,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_ORDER_DETAIL';
        IF NOT pk_exam_core.get_exam_order_detail(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_id_record => i_id_record,
                                                  i_area      => i_area,
                                                  o_detail    => o_detail,
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
                                              'GET_EXAM_ORDER_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_order_detail;

    FUNCTION get_exam_order_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_record IN exam_req.id_exam_req%TYPE,
        i_area      IN dd_content.area%TYPE,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_ORDER_HIST';
        IF NOT pk_exam_core.get_exam_order_hist(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_id_record => i_id_record,
                                                i_area      => i_area,
                                                o_detail    => o_detail,
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
                                              'GET_EXAM_ORDER_HIST',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_order_hist;

    FUNCTION get_exam_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_DETAIL';
        IF NOT pk_exam_external.get_exam_detail(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_episode                 => i_episode,
                                                i_exam_req_det            => i_exam_req_det,
                                                o_exam_order              => o_exam_order,
                                                o_exam_co_sign            => o_exam_co_sign,
                                                o_exam_clinical_questions => o_exam_clinical_questions,
                                                o_exam_perform            => o_exam_perform,
                                                o_exam_result             => o_exam_result,
                                                o_exam_result_images      => o_exam_result_images,
                                                o_exam_doc                => o_exam_doc,
                                                o_exam_review             => o_exam_review,
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
                                              'GET_EXAM_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_co_sign);
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail;

    FUNCTION get_exam_detail_history
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_DETAIL_HISTORY';
        IF NOT pk_exam_external.get_exam_detail_history(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_episode                 => i_episode,
                                                        i_exam_req_det            => i_exam_req_det,
                                                        o_exam_order              => o_exam_order,
                                                        o_exam_co_sign            => o_exam_co_sign,
                                                        o_exam_clinical_questions => o_exam_clinical_questions,
                                                        o_exam_perform            => o_exam_perform,
                                                        o_exam_result             => o_exam_result,
                                                        o_exam_result_images      => o_exam_result_images,
                                                        o_exam_doc                => o_exam_doc,
                                                        o_exam_review             => o_exam_review,
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
                                              'GET_EXAM_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_exam_order);
            pk_types.open_my_cursor(o_exam_co_sign);
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail_history;

    FUNCTION get_exam_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_ORDER';
        IF NOT pk_exam_core.get_exam_order(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_episode                 => i_episode,
                                           i_exam_req_det            => i_exam_req_det,
                                           o_exam                    => o_exam,
                                           o_exam_clinical_questions => o_exam_clinical_questions,
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
                                              'GET_EXAM_ORDER',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_order;

    FUNCTION get_exam_perform
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_PERFORM';
        IF NOT pk_exam_core.get_exam_perform(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_episode                 => i_episode,
                                             i_exam_req_det            => i_exam_req_det,
                                             o_exam                    => o_exam,
                                             o_exam_clinical_questions => o_exam_clinical_questions,
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
                                              'GET_EXAM_PERFORM',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_perform;

    FUNCTION get_exam_result
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_exam         OUT pk_types.cursor_type,
        o_exam_result  OUT pk_types.cursor_type,
        o_exam_images  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_RESULT';
        IF NOT pk_exam_core.get_exam_result(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_exam_req_det => i_exam_req_det,
                                            o_exam         => o_exam,
                                            o_exam_result  => o_exam_result,
                                            o_exam_images  => o_exam_images,
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
                                              'GET_EXAM_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_images);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_result;

    FUNCTION get_exam_doc_associated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_DOC_ASSOCIATED';
        IF NOT pk_exam_core.get_exam_doc_associated(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_exam_req_det => i_exam_req_det,
                                                    o_exam_doc     => o_exam_doc,
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
                                              'GET_EXAM_DOC_ASSOCIATED',
                                              o_error);
            pk_types.open_my_cursor(o_exam_doc);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_doc_associated;

    FUNCTION get_exam_import_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_exam    IN exam.id_exam%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_IMPORT_LIST';
        IF NOT pk_exam_core.get_exam_import_list(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => i_episode,
                                                 i_exam    => i_exam,
                                                 o_list    => o_list,
                                                 o_error   => o_error)
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
                                              'GET_EXAM_IMPORT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_import_list;

    FUNCTION get_hpi_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_type       IN epis_type.id_epis_type%TYPE,
        o_title_anamnesis OUT VARCHAR2,
        o_anamnesis       OUT VARCHAR2,
        o_title_diagnosis OUT VARCHAR2,
        o_diagnosis       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_HPI_SUMMARY';
        IF NOT pk_exams.get_hpi_summary(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_patient         => i_patient,
                                        i_episode         => i_episode,
                                        i_epis_type       => i_epis_type,
                                        o_title_anamnesis => o_title_anamnesis,
                                        o_anamnesis       => o_anamnesis,
                                        o_title_diagnosis => o_title_diagnosis,
                                        o_diagnosis       => o_diagnosis,
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
                                              'GET_HPI_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_hpi_summary;

    FUNCTION get_exam_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_flg_type     IN VARCHAR2 DEFAULT pk_exam_constant.g_exam_institution,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM TABLE(pk_exam_core.get_exam_selection_list(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => i_patient,
                                                              i_episode      => i_episode,
                                                              i_exam_type    => i_exam_type,
                                                              i_flg_type     => i_flg_type,
                                                              i_codification => i_codification));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_selection_list;

    FUNCTION get_exam_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_value        IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_SEARCH';
        IF NOT pk_exam_core.get_exam_search(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_patient       => i_patient,
                                            i_exam_type     => i_exam_type,
                                            i_codification  => i_codification,
                                            i_dep_clin_serv => NULL,
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_search;

    FUNCTION get_exam_category_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_CATEGORY_SEARCH';
        IF NOT pk_exam_core.get_exam_category_search(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => i_patient,
                                                     i_exam_type    => i_exam_type,
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
                                              'GET_EXAM_CATEGORY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_category_search;

    FUNCTION get_body_structure_exams_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_mcs_concept         IN body_structure_rel.id_mcs_concept%TYPE,
        i_exam_cat            IN exam.id_exam_cat%TYPE,
        i_exam_type           IN exam.flg_type%TYPE,
        i_codification        IN codification.id_codification%TYPE,
        o_body_structure_list OUT pk_types.cursor_type,
        o_exams_list          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL GET_EXAM_BODY_PART_SEARCH';
        IF NOT pk_exam_core.get_exam_body_part_search(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_patient      => i_patient,
                                                      i_mcs_concept  => i_mcs_concept,
                                                      i_exam_cat     => i_exam_cat,
                                                      i_exam_type    => i_exam_type,
                                                      i_codification => NULL,
                                                      o_list         => o_body_structure_list,
                                                      o_exam_list    => o_exams_list,
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
                                              'GET_BODY_STRUCTURE_EXAMS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_body_structure_list);
            pk_types.open_my_cursor(o_exams_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_body_structure_exams_list;

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
    
        g_error := 'CALL GET_EXAM_IN_GROUP';
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_in_group;

    FUNCTION get_exam_to_edit
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN table_number,
        o_exam                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_TO_EDIT';
        IF NOT pk_exam_core.get_exam_to_edit(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_episode                 => i_episode,
                                             i_exam_req_det            => i_exam_req_det,
                                             o_exam                    => o_exam,
                                             o_exam_clinical_questions => o_exam_clinical_questions,
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
                                              'GET_EXAM_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_to_edit;

    FUNCTION get_exam_order_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_ORDER_LIST';
        IF NOT
            pk_exam_core.get_exam_order_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
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
                                              'GET_EXAM_ORDER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_order_list;

    FUNCTION get_exam_selection_filter_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_FILTER_LIST';
        IF NOT pk_exam_core.get_exam_filter_list(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_patient   => i_patient,
                                                 i_episode   => i_episode,
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
                                              'GET_EXAM_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_selection_filter_list;

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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_time_list;

    FUNCTION get_exam_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_PRIORITY_LIST';
        IF NOT pk_exam_core.get_exam_priority_list(i_lang  => i_lang,
                                                   i_prof  => i_prof,
                                                   i_exam  => i_exam,
                                                   o_list  => o_list,
                                                   o_error => o_error)
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
                                              'GET_EXAM_PRIORITY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_priority_list;

    FUNCTION get_exam_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_DIAGNOSIS_LIST';
        IF NOT pk_exam_core.get_exam_diagnosis_list(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_episode => i_episode,
                                                    o_list    => o_list,
                                                    o_error   => o_error)
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
                                              'GET_EXAM_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_diagnosis_list;

    FUNCTION get_exam_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_LOCATION_LIST';
        IF NOT pk_exam_core.get_exam_location_list(i_lang  => i_lang,
                                                   i_prof  => i_prof,
                                                   i_exam  => i_exam,
                                                   o_list  => o_list,
                                                   o_error => o_error)
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
                                              'GET_EXAM_LOCATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_location_list;

    FUNCTION get_exam_clinical_purpose_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_CLINICAL_PURPOSE_LIST';
        IF NOT pk_exam_core.get_exam_clinical_purpose_list(i_lang  => i_lang,
                                                           i_prof  => i_prof,
                                                           o_list  => o_list,
                                                           o_error => o_error)
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
                                              'GET_EXAM_CLINICAL_PURPOSE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_clinical_purpose_list;

    FUNCTION get_exam_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_PRN_LIST';
        IF NOT pk_exam_core.get_exam_prn_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
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
                                              'GET_EXAM_PRN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_prn_list;

    FUNCTION get_exam_fasting_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_FASTING_LIST';
        IF NOT
            pk_exam_core.get_exam_fasting_list(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
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
                                              'GET_EXAM_FASTING_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_fasting_list;

    FUNCTION get_exam_codification_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_exam  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_CODIFICATION_LIST';
        IF NOT pk_exam_core.get_exam_codification_list(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       i_exam  => i_exam,
                                                       o_list  => o_list,
                                                       o_error => o_error)
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
                                              'GET_EXAM_CODIFICATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_codification_list;

    FUNCTION get_exam_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_HEALTH_PLAN_LIST';
        IF NOT pk_exam_core.get_exam_health_plan_list(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_patient => i_patient,
                                                      o_list    => o_list,
                                                      o_error   => o_error)
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
                                              'GET_EXAM_HEALTH_PLAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_health_plan_list;

    FUNCTION get_exam_time_out_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        o_id_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_TIME_OUT_LIST';
        IF NOT pk_exam_core.get_exam_time_out_list(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_episode         => i_episode,
                                                   i_exam_req_det    => i_exam_req_det,
                                                   o_id_doc_template => o_id_doc_template,
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
                                              'GET_EXAM_TIME_OUT_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_time_out_list;

    FUNCTION get_exam_documentation_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_DOCUMENTATION_LIST';
        IF NOT pk_exam_core.get_exam_documentation_list(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_list  => o_list,
                                                        o_error => o_error)
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
                                              'GET_EXAM_DOCUMENTATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_documentation_list;

    FUNCTION get_exam_result_status_list
    (
        i_lang  IN language.id_language%TYPE, --1
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_RESULT_STATUS_LIST';
        IF NOT pk_exam_core.get_exam_result_status_list(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_list  => o_list,
                                                        o_error => o_error)
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
                                              'GET_EXAM_RESULT_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_result_status_list;

    FUNCTION get_exam_result_abnormal_list
    (
        i_lang  IN language.id_language%TYPE, --1
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_RESULT_ABNORMAL_LIST';
        IF NOT pk_exam_core.get_exam_result_abnormal_list(i_lang  => i_lang,
                                                          i_prof  => i_prof,
                                                          o_list  => o_list,
                                                          o_error => o_error)
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
                                              'GET_EXAM_RESULT_ABNORMAL_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_result_abnormal_list;

    FUNCTION get_exam_result_origin_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_RESULT_ORIGIN_LIST';
        IF NOT pk_exam_core.get_exam_result_origin_list(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_list  => o_list,
                                                        o_error => o_error)
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
                                              'GET_EXAM_RESULT_ORIGIN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_result_origin_list;

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

    FUNCTION get_exam_result_diagnosis_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_RESULT_DIAGNOSIS_LIST';
        IF NOT pk_exam_core.get_exam_result_diagnosis_list(i_lang         => i_lang,
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
                                              'GET_EXAM_RESULT_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_result_diagnosis_list;

    FUNCTION get_exam_result_category_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_exam_type IN exam.flg_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_CORE.GET_EXAM_RESULT_CATEGORY_LIST';
        IF NOT pk_exam_core.get_exam_result_category_list(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_patient   => i_patient,
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
                                              'GET_EXAM_RESULT_CATEGORY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_result_category_list;

    FUNCTION get_exam_questionnaire_resp
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_exam_req_det           IN exam_question_response.id_exam_req_det%TYPE,
        i_flg_time               IN exam_question_response.flg_time%TYPE,
        o_exam_question_response OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_EXAM_QUEST_RESPONSE';
        IF NOT pk_exam_core.get_exam_questionnaire_resp(i_lang                   => i_lang,
                                                        i_prof                   => i_prof,
                                                        i_exam_req_det           => i_exam_req_det,
                                                        i_flg_time               => i_flg_time,
                                                        o_exam_question_response => o_exam_question_response,
                                                        o_error                  => o_error)
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
                                              'GET_EXAM_QUEST_RESPONSE',
                                              o_error);
            RETURN FALSE;
    END get_exam_questionnaire_resp;

    FUNCTION get_exam_print_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN exam.flg_type%TYPE,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_PRINT_LIST';
        IF NOT pk_exams_external_api_db.get_exam_print_list(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_flg_type => i_flg_type,
                                                            o_options  => o_options,
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
                                              'GET_EXAM_PRINT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_exam_print_list;

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_exam_req_det    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.ADD_PRINT_LIST_JOBS';
        IF NOT pk_exams_external_api_db.add_print_list_jobs(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_patient         => i_patient,
                                                            i_episode         => i_episode,
                                                            i_exam_req_det    => i_exam_req_det,
                                                            i_print_arguments => i_print_arguments,
                                                            o_print_list_job  => o_print_list_job,
                                                            o_error           => o_error)
        THEN
            IF o_error.ora_sqlcode = 'REP_EXCEPTION_018'
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSE
                RAISE g_other_exception;
            END IF;
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
                                              'ADD_PRINT_LIST_JOBS',
                                              o_error);
            RETURN FALSE;
    END add_print_list_jobs;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exams_api_ux;
/
