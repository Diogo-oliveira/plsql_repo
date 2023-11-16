/*-- Last Change Revision: $Rev: 2027304 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_api_ux IS

    FUNCTION create_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar, --15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar, --20
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar, --25
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar, --30
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar, --35
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --40
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number, --45
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number DEFAULT NULL,
        i_flg_task_depending      IN table_varchar DEFAULT NULL,
        i_episode_followup_app    IN table_number DEFAULT NULL,
        i_schedule_followup_app   IN table_number DEFAULT NULL, --50
        i_event_followup_app      IN table_number DEFAULT NULL,
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_analysis_req_array      OUT NOCOPY table_number,
        o_analysis_req_det_array  OUT NOCOPY table_number,
        o_analysis_req_par_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.create_lab_test_order(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_patient                 => i_patient,
                                                       i_episode                 => i_episode,
                                                       i_analysis_req            => i_analysis_req,
                                                       i_analysis_req_det        => NULL,
                                                       i_analysis_req_det_parent => NULL,
                                                       i_harvest                 => i_harvest,
                                                       i_analysis                => i_analysis,
                                                       i_analysis_group          => i_analysis_group,
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
                                                       i_specimen                => i_specimen,
                                                       i_body_location           => i_body_location,
                                                       i_laterality              => i_laterality,
                                                       i_collection_room         => i_collection_room,
                                                       i_notes                   => i_notes,
                                                       i_notes_scheduler         => i_notes_scheduler,
                                                       i_notes_technician        => i_notes_technician,
                                                       i_notes_patient           => i_notes_patient,
                                                       i_diagnosis_notes         => i_diagnosis_notes,
                                                       i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                              i_prof   => i_prof,
                                                                                                              i_params => i_diagnosis),
                                                       i_exec_institution        => i_exec_institution,
                                                       i_clinical_purpose        => i_clinical_purpose,
                                                       i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                       i_flg_col_inst            => i_flg_col_inst,
                                                       i_flg_fasting             => i_flg_fasting,
                                                       i_lab_req                 => i_lab_req,
                                                       i_prof_cc                 => i_prof_cc,
                                                       i_prof_bcc                => i_prof_bcc,
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
                                                       o_analysis_req_array      => o_analysis_req_array,
                                                       o_analysis_req_det_array  => o_analysis_req_det_array,
                                                       o_analysis_req_par_array  => o_analysis_req_par_array,
                                                       o_error                   => o_error)
        THEN
            IF o_error.ora_sqlcode IN ('ANALYSIS_M012', 'ANALYSIS_M009')
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF o_flg_show = pk_lab_tests_constant.g_yes
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
                                              'CREATE_LAB_TEST_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_lab_test_order;

    FUNCTION create_lab_test_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_exam.id_schedule%TYPE,
        i_analysis_req_det IN table_number,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL CREATE_LAB_TEST_VISIT';
        IF NOT pk_lab_tests_core.create_lab_test_visit(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_patient          => i_patient,
                                                       i_episode          => i_episode,
                                                       i_schedule         => i_schedule,
                                                       i_analysis_req_det => i_analysis_req_det,
                                                       o_episode          => o_episode,
                                                       o_error            => o_error)
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
                                              'CREATE_LAB_TEST_VISIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_lab_test_visit;

    FUNCTION set_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det        IN table_number,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar,
        i_flg_type                IN table_varchar,
        i_flg_time                IN table_varchar, --10
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number, --20
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis               IN table_clob, --25
        i_exec_institution        IN table_number,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar, --30
        i_lab_req                 IN table_number,
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --35
        i_exemption               IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number, --40
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number, --45
        i_flg_task_depending      IN table_varchar,
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.set_lab_test_order(i_lang                    => i_lang,
                                                    i_prof                    => i_prof,
                                                    i_patient                 => i_patient,
                                                    i_episode                 => i_episode,
                                                    i_analysis_req            => i_analysis_req,
                                                    i_analysis_req_det        => i_analysis_req_det,
                                                    i_analysis                => i_analysis,
                                                    i_analysis_group          => i_analysis_group,
                                                    i_flg_type                => i_flg_type,
                                                    i_flg_time                => i_flg_time,
                                                    i_dt_begin                => i_dt_begin,
                                                    i_dt_begin_limit          => i_dt_begin_limit,
                                                    i_order_recurrence        => i_order_recurrence,
                                                    i_priority                => i_priority,
                                                    i_flg_prn                 => i_flg_prn,
                                                    i_notes_prn               => i_notes_prn,
                                                    i_specimen                => i_specimen,
                                                    i_body_location           => i_body_location,
                                                    i_laterality              => i_laterality,
                                                    i_collection_room         => i_collection_room,
                                                    i_notes                   => i_notes,
                                                    i_notes_scheduler         => i_notes_scheduler,
                                                    i_notes_technician        => i_notes_technician,
                                                    i_notes_patient           => i_notes_patient,
                                                    i_diagnosis               => i_diagnosis,
                                                    i_exec_institution        => i_exec_institution,
                                                    i_clinical_purpose        => i_clinical_purpose,
                                                    i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                    i_flg_col_inst            => i_flg_col_inst,
                                                    i_flg_fasting             => i_flg_fasting,
                                                    i_lab_req                 => i_lab_req,
                                                    i_prof_cc                 => i_prof_cc,
                                                    i_prof_bcc                => i_prof_bcc,
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
                                                    o_error                   => o_error)
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
                                              'SET_LAB_TEST_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_order;

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number, --5
        i_analysis_req_det          IN table_table_number,
        i_body_location             IN table_number,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --15
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE, --20
        i_revised_by                IN professional.id_professional%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_COLLECT';
        IF NOT pk_lab_tests_harvest_core.set_harvest_collect(i_lang                      => i_lang,
                                                             i_prof                      => i_prof,
                                                             i_episode                   => i_episode,
                                                             i_harvest                   => i_harvest,
                                                             i_analysis_harvest          => i_analysis_harvest,
                                                             i_analysis_req_det          => i_analysis_req_det,
                                                             i_body_location             => i_body_location,
                                                             i_laterality                => NULL,
                                                             i_collection_method         => i_collection_method,
                                                             i_specimen_condition        => NULL,
                                                             i_collection_room           => i_collection_room,
                                                             i_lab                       => i_lab,
                                                             i_exec_institution          => i_exec_institution,
                                                             i_sample_recipient          => i_sample_recipient,
                                                             i_num_recipient             => i_num_recipient,
                                                             i_collected_by              => i_collected_by,
                                                             i_collection_time           => i_collection_time,
                                                             i_collection_amount         => i_collection_amount,
                                                             i_collection_transportation => i_collection_transportation,
                                                             i_notes                     => i_notes,
                                                             i_flg_rep_collection        => i_flg_rep_collection,
                                                             i_rep_coll_reason           => i_rep_coll_reason,
                                                             i_flg_orig_harvest          => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                                                             i_revised_by                => i_revised_by,
                                                             o_error                     => o_error)
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
                                              'SET_HARVEST_COLLECT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_collect;

    FUNCTION set_lab_test_result
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_doc_external           IN table_table_number DEFAULT NULL,
        i_doc_type               IN table_table_number DEFAULT NULL,
        i_doc_ori_type           IN table_table_number DEFAULT NULL,
        i_title                  IN table_table_varchar DEFAULT NULL,
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        o_result                 OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_core.set_lab_test_result(i_lang                       => i_lang,
                                                     i_prof                       => i_prof,
                                                     i_patient                    => i_patient,
                                                     i_episode                    => i_episode,
                                                     i_analysis                   => i_analysis,
                                                     i_sample_type                => i_sample_type,
                                                     i_analysis_parameter         => i_analysis_parameter,
                                                     i_analysis_param             => i_analysis_param,
                                                     i_analysis_req_det           => i_analysis_req_det,
                                                     i_analysis_req_par           => i_analysis_req_par,
                                                     i_analysis_result_par        => i_analysis_result_par,
                                                     i_analysis_result_par_parent => NULL,
                                                     i_flg_type                   => i_flg_type,
                                                     i_harvest                    => i_harvest,
                                                     i_dt_sample                  => i_dt_sample,
                                                     i_prof_req                   => i_prof_req,
                                                     i_dt_analysis_result         => i_dt_analysis_result,
                                                     i_flg_result_origin          => i_flg_result_origin,
                                                     i_result_origin_notes        => i_result_origin_notes,
                                                     i_result_notes               => i_result_notes,
                                                     i_loinc_code                 => NULL,
                                                     i_dt_ext_registry            => NULL,
                                                     i_instit_origin              => NULL,
                                                     i_result_value_1             => i_result,
                                                     i_analysis_desc              => i_analysis_desc,
                                                     i_doc_external               => i_doc_external,
                                                     i_doc_type                   => i_doc_type,
                                                     i_doc_ori_type               => i_doc_ori_type,
                                                     i_title                      => i_title,
                                                     i_unit_measure               => i_unit_measure,
                                                     i_desc_unit_measure          => NULL,
                                                     i_result_status              => i_result_status,
                                                     i_ref_val                    => NULL,
                                                     i_ref_val_min                => i_ref_val_min,
                                                     i_ref_val_max                => i_ref_val_max,
                                                     i_parameter_notes            => i_parameter_notes,
                                                     i_interface_notes            => NULL,
                                                     i_laboratory_desc            => NULL,
                                                     i_laboratory_short_desc      => NULL,
                                                     i_coding_system              => NULL,
                                                     i_method                     => NULL,
                                                     i_equipment                  => NULL,
                                                     i_abnormality                => NULL,
                                                     i_abnormality_nature         => NULL,
                                                     i_prof_validation            => NULL,
                                                     i_dt_validation              => NULL,
                                                     i_flg_orig_analysis          => i_flg_orig_analysis,
                                                     i_clinical_decision_rule     => i_clinical_decision_rule,
                                                     o_result                     => o_result,
                                                     o_error                      => o_error)
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
                                              'SET_LAB_TEST_RESULT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_result;

    FUNCTION set_lab_test_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN exam_result.id_patient%TYPE,
        i_episode              IN exam_result.id_episode%TYPE,
        i_analysis_req_det     IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_LAB_TEST_DOC_ASSOCIATED';
        IF NOT pk_lab_tests_core.set_lab_test_doc_associated(i_lang                 => i_lang,
                                                             i_prof                 => i_prof,
                                                             i_patient              => i_patient,
                                                             i_episode              => i_episode,
                                                             i_analysis_req_det     => i_analysis_req_det,
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
                                              'SET_LAB_TEST_DOC_ASSOCIATED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_doc_associated;

    FUNCTION set_lab_test_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_status           IN analysis_req_det.flg_status%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS';
        IF NOT pk_lab_tests_core.set_lab_test_status(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_analysis_req_det => i_analysis_req_det,
                                                     i_status           => i_status,
                                                     o_error            => o_error)
        THEN
            IF o_error.ora_sqlcode = 'ANALYSIS_M009'
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
                                              'SET_LAB_TEST_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_status;

    FUNCTION set_lab_test_status_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN table_number,
        i_flg_relevant        IN table_varchar,
        i_notes               IN table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS_READ';
        IF NOT pk_lab_tests_core.set_lab_test_status_read(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_analysis_result_par => i_analysis_result_par,
                                                          i_flg_relevant        => i_flg_relevant,
                                                          i_notes               => i_notes,
                                                          o_error               => o_error)
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
                                              'SET_LAB_TEST_STATUS_READ',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_status_read;

    FUNCTION set_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_notes_scheduler  IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_DATE';
        IF NOT pk_lab_tests_core.set_lab_test_date(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_analysis_req_det => i_analysis_req_det,
                                                   i_dt_begin         => i_dt_begin,
                                                   i_notes_scheduler  => i_notes_scheduler,
                                                   o_error            => o_error)
        THEN
            IF o_error.ora_sqlcode = 'EXAM_M011'
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
                                              'SET_LAB_TEST_DATE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_date;

    FUNCTION set_lab_test_timeline
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_param IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_TIMELINE';
        IF NOT pk_lab_tests_core.set_lab_test_timeline(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_analysis_param => i_analysis_param,
                                                       o_error          => o_error)
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
                                              'SET_LAB_TEST_TIMELINE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_lab_test_timeline;

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number,
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_EDIT';
        IF NOT pk_lab_tests_harvest_core.set_harvest_edit(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_harvest                   => i_harvest,
                                                          i_analysis_harvest          => i_analysis_harvest,
                                                          i_body_location             => i_body_location,
                                                          i_laterality                => i_laterality,
                                                          i_collection_method         => i_collection_method,
                                                          i_specimen_condition        => NULL,
                                                          i_collection_room           => i_collection_room,
                                                          i_lab                       => i_lab,
                                                          i_exec_institution          => i_exec_institution,
                                                          i_sample_recipient          => i_sample_recipient,
                                                          i_num_recipient             => i_num_recipient,
                                                          i_collection_time           => i_collection_time,
                                                          i_collection_amount         => i_collection_amount,
                                                          i_collection_transportation => i_collection_transportation,
                                                          i_notes                     => i_notes,
                                                          o_error                     => o_error)
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
                                              'SET_HARVEST_EDIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_edit;

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        o_harvest                   OUT harvest.id_harvest%TYPE,
        o_error                     OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_COMBINE';
        IF NOT pk_lab_tests_harvest_core.set_harvest_combine(i_lang                      => i_lang,
                                                             i_prof                      => i_prof,
                                                             i_patient                   => i_patient,
                                                             i_episode                   => i_episode,
                                                             i_harvest                   => i_harvest,
                                                             i_analysis_harvest          => i_analysis_harvest,
                                                             i_collection_method         => i_collection_method,
                                                             i_specimen_condition        => NULL,
                                                             i_collection_room           => i_collection_room,
                                                             i_lab                       => i_lab,
                                                             i_exec_institution          => i_exec_institution,
                                                             i_sample_recipient          => i_sample_recipient,
                                                             i_num_recipient             => i_num_recipient,
                                                             i_collection_time           => i_collection_time,
                                                             i_collection_amount         => i_collection_amount,
                                                             i_collection_transportation => i_collection_transportation,
                                                             i_notes                     => i_notes,
                                                             i_flg_orig_harvest          => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                                                             o_harvest                   => o_harvest,
                                                             o_error                     => o_error)
        
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
                                              'SET_HARVEST_COMBINE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_combine;

    FUNCTION set_harvest_divide
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_harvest          IN table_table_number, --5
        i_flg_divide                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number, --10
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar, --15
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_DIVIDE';
        IF NOT pk_lab_tests_harvest_core.set_harvest_divide(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_patient                   => i_patient,
                                                            i_episode                   => i_episode,
                                                            i_analysis_harvest          => i_analysis_harvest,
                                                            i_flg_divide                => i_flg_divide,
                                                            i_collection_method         => i_collection_method,
                                                            i_collection_room           => i_collection_room,
                                                            i_lab                       => i_lab,
                                                            i_exec_institution          => i_exec_institution,
                                                            i_sample_recipient          => i_sample_recipient,
                                                            i_num_recipient             => i_num_recipient,
                                                            i_collection_time           => i_collection_time,
                                                            i_collection_amount         => i_collection_amount,
                                                            i_collection_transportation => i_collection_transportation,
                                                            i_notes                     => i_notes,
                                                            o_error                     => o_error)
        
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
                                              'SET_HARVEST_DIVIDE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_divide;

    FUNCTION set_harvest_divide_and_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE, --5
        i_analysis_harvest          IN table_table_number,
        i_analysis_req_det          IN table_table_number,
        i_flg_divide                IN table_varchar,
        i_flg_collect               IN table_varchar,
        i_collection_method         IN table_varchar, --10
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number,
        i_body_location             IN table_number,
        i_sample_recipient          IN table_number, --15
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar, --20
        i_notes                     IN table_varchar,
        o_harvest                   OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_DIVIDE_AND_COLLECT';
        IF NOT pk_lab_tests_harvest_core.set_harvest_divide_and_collect(i_lang                      => i_lang,
                                                                        i_prof                      => i_prof,
                                                                        i_patient                   => i_patient,
                                                                        i_episode                   => i_episode,
                                                                        i_harvest                   => i_harvest,
                                                                        i_analysis_harvest          => i_analysis_harvest,
                                                                        i_analysis_req_det          => i_analysis_req_det,
                                                                        i_flg_divide                => i_flg_divide,
                                                                        i_flg_collect               => i_flg_collect,
                                                                        i_body_location             => i_body_location,
                                                                        i_laterality                => NULL,
                                                                        i_collection_method         => i_collection_method,
                                                                        i_specimen_condition        => NULL,
                                                                        i_collection_room           => i_collection_room,
                                                                        i_lab                       => i_lab,
                                                                        i_exec_institution          => i_exec_institution,
                                                                        i_sample_recipient          => i_sample_recipient,
                                                                        i_num_recipient             => i_num_recipient,
                                                                        i_collected_by              => i_collected_by,
                                                                        i_collection_time           => i_collection_time,
                                                                        i_collection_amount         => i_collection_amount,
                                                                        i_collection_transportation => i_collection_transportation,
                                                                        i_notes                     => i_notes,
                                                                        i_flg_orig_harvest          => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                                                                        o_harvest                   => o_harvest,
                                                                        o_error                     => o_error)
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
                                              'SET_HARVEST_DIVIDE_AND_COLLECT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_divide_and_collect;

    FUNCTION set_harvest_questionnaire
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN table_number,
        i_questionnaire    IN table_table_number,
        i_response         IN table_table_varchar,
        i_notes            IN table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_QUESTIONNAIRE';
        IF NOT pk_lab_tests_harvest_core.set_harvest_questionnaire(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_episode          => i_episode,
                                                                   i_analysis_req_det => i_analysis_req_det,
                                                                   i_harvest          => i_harvest,
                                                                   i_questionnaire    => i_questionnaire,
                                                                   i_response         => i_response,
                                                                   i_notes            => i_notes,
                                                                   o_error            => o_error)
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
                                              'SET_HARVEST_QUESTIONNAIRE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_questionnaire;

    FUNCTION update_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req_det        IN table_number,
        i_flg_time                IN table_varchar, --5
        i_dt_begin                IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_specimen                IN table_number, --10
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar,
        i_notes_scheduler         IN table_varchar, --15
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob,
        i_exec_institution        IN table_number, --20
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number, --25
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --30
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --35
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.UPDATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.update_lab_test_order(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_episode                 => i_episode,
                                                       i_analysis_req            => NULL,
                                                       i_analysis_req_det        => i_analysis_req_det,
                                                       i_flg_time                => i_flg_time,
                                                       i_dt_begin                => i_dt_begin,
                                                       i_priority                => i_priority,
                                                       i_flg_prn                 => i_flg_prn,
                                                       i_notes_prn               => i_notes_prn,
                                                       i_specimen                => i_specimen,
                                                       i_body_location           => i_body_location,
                                                       i_laterality              => i_laterality,
                                                       i_collection_room         => i_collection_room,
                                                       i_notes                   => i_notes,
                                                       i_notes_scheduler         => i_notes_scheduler,
                                                       i_notes_technician        => i_notes_technician,
                                                       i_notes_patient           => i_notes_patient,
                                                       i_diagnosis_notes         => i_diagnosis_notes,
                                                       i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                              i_prof   => i_prof,
                                                                                                              i_params => i_diagnosis),
                                                       i_exec_institution        => i_exec_institution,
                                                       i_clinical_purpose        => i_clinical_purpose,
                                                       i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                       i_flg_col_inst            => i_flg_col_inst,
                                                       i_flg_fasting             => i_flg_fasting,
                                                       i_lab_req                 => i_lab_req,
                                                       i_prof_cc                 => i_prof_cc,
                                                       i_prof_bcc                => i_prof_bcc,
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
            IF o_error.ora_sqlcode = 'ANALYSIS_M012'
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
                                              'UPDATE_LAB_TEST_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_lab_test_order;

    FUNCTION update_harvest
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN table_number,
        i_status  IN table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.UPDATE_HARVEST';
        IF NOT pk_lab_tests_harvest_core.update_harvest(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_harvest          => i_harvest,
                                                        i_status           => i_status,
                                                        i_flg_orig_harvest => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                                                        o_error            => o_error)
        
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
                                              'UPDATE_HARVEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_harvest;

    FUNCTION cancel_lab_test_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_analysis_req  IN table_number,
        i_cancel_reason IN analysis_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN analysis_req.notes_cancel%TYPE,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.cancel_lab_test_order(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_analysis_req  => i_analysis_req,
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
                                              'CANCEL_LAB_TEST_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_lab_test_order;

    FUNCTION cancel_lab_test_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_cancel_reason    IN analysis_req_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN analysis_req_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_REQUEST';
        IF NOT pk_lab_tests_core.cancel_lab_test_request(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_analysis_req_det => i_analysis_req_det,
                                                         i_dt_cancel        => NULL,
                                                         i_cancel_reason    => i_cancel_reason,
                                                         i_cancel_notes     => i_cancel_notes,
                                                         i_prof_order       => i_prof_order,
                                                         i_dt_order         => i_dt_order,
                                                         i_order_type       => i_order_type,
                                                         o_error            => o_error)
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
                                              'CANCEL_LAB_TEST_REQUEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_lab_test_request;

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.CANCEL_HARVEST';
        IF NOT pk_lab_tests_harvest_core.cancel_harvest(i_lang          => i_lang, --1
                                                        i_prof          => i_prof,
                                                        i_patient       => i_patient,
                                                        i_episode       => i_episode,
                                                        i_harvest       => i_harvest,
                                                        i_cancel_reason => i_cancel_reason, --5
                                                        i_cancel_notes  => i_cancel_notes,
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
                                              'CANCEL_HARVEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_harvest;

    FUNCTION cancel_lab_test_result
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_cancel_reason       IN analysis_result_par.id_cancel_reason%TYPE,
        i_notes_cancel        IN analysis_result_par.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_core.cancel_lab_test_result(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_analysis_result_par => i_analysis_result_par,
                                                        i_cancel_reason       => i_cancel_reason,
                                                        i_notes_cancel        => i_notes_cancel,
                                                        o_error               => o_error)
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
                                              'CANCEL_LAB_TEST_RESULT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_lab_test_result;

    FUNCTION cancel_lab_test_doc_associated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_doc_external     IN doc_external.id_doc_external%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CANCEL_LAB_TEST_DOC_ASSOCIATED';
        IF NOT pk_lab_tests_core.cancel_lab_test_doc_associated(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_analysis_req_det => i_analysis_req_det,
                                                                i_doc_external     => i_doc_external,
                                                                o_error            => o_error)
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
                                              'CANCEL_LAB_TEST_DOC_ASSOCIATED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_lab_test_doc_associated;

    FUNCTION get_lab_test_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_analysis_institution,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM TABLE(pk_lab_tests_core.get_lab_test_selection_list(i_lang         => i_lang,
                                                                       i_prof         => i_prof,
                                                                       i_patient      => i_patient,
                                                                       i_episode      => i_episode,
                                                                       i_flg_type     => i_flg_type,
                                                                       i_codification => i_codification,
                                                                       i_analysis_req => i_analysis_req,
                                                                       i_harvest      => i_harvest));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_selection_list;

    FUNCTION get_lab_test_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        i_value        IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_search(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => i_patient,
                                                     i_codification => i_codification,
                                                     i_analysis_req => i_analysis_req,
                                                     i_harvest      => i_harvest,
                                                     i_value        => i_value,
                                                     o_flg_show     => o_flg_show,
                                                     o_msg          => o_msg,
                                                     o_msg_title    => o_msg_title,
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
                                              'GET_LAB_TEST_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_search;

    FUNCTION get_lab_test_group_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_GROUP_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_group_search(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_analysis_req => i_analysis_req,
                                                           o_list         => o_list,
                                                           o_error        => o_error)
        THEN
            RAISE g_other_exception;
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
                                              i_function => 'GET_LAB_TEST_GROUP_SEARCH',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_group_search;

    FUNCTION get_lab_test_sample_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_SAMPLE_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_sample_search(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_patient      => i_patient,
                                                            i_exam_cat     => i_exam_cat,
                                                            i_codification => i_codification,
                                                            i_analysis_req => i_analysis_req,
                                                            i_harvest      => i_harvest,
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
                                              'GET_LAB_TEST_SAMPLE_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_sample_search;

    FUNCTION get_lab_test_category_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_list t_tbl_lab_tests_cat_search;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_CATEGORY_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_category_search(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_sample_type     => i_sample_type,
                                                              i_exam_cat_parent => i_exam_cat_parent,
                                                              i_codification    => i_codification,
                                                              i_analysis_req    => i_analysis_req,
                                                              i_harvest         => i_harvest,
                                                              o_list            => o_list,
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
                                              'GET_LAB_TEST_CATEGORY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_category_search;

    FUNCTION get_lab_test_parameter_search
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_value     IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_PARAMETER_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_parameter_search(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_value     => i_value,
                                                               o_flg_show  => o_flg_show,
                                                               o_msg       => o_msg,
                                                               o_msg_title => o_msg_title,
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
                                              'GET_LAB_TEST_PARAMETER_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_parameter_search;

    FUNCTION get_lab_test_for_selection
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list t_tbl_lab_tests_for_selection;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_FOR_SELECTION';
        IF NOT pk_lab_tests_core.get_lab_test_for_selection(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_patient         => i_patient,
                                                            i_sample_type     => i_sample_type,
                                                            i_exam_cat        => i_exam_cat,
                                                            i_exam_cat_parent => i_exam_cat_parent,
                                                            i_codification    => i_codification,
                                                            i_analysis_req    => i_analysis_req,
                                                            i_harvest         => i_harvest,
                                                            o_list            => l_list,
                                                            o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM TABLE(l_list);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_FOR_SELECTION',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_for_selection;

    FUNCTION get_lab_test_in_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_IN_GROUP';
        IF NOT pk_lab_tests_core.get_lab_test_in_group(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_analysis_group => i_analysis_group,
                                                       i_codification   => i_codification,
                                                       o_list           => o_list,
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
                                              'GET_LAB_TEST_IN_GROUP',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_in_group;

    FUNCTION get_lab_test_parameter
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_PARAMETER';
        IF NOT pk_lab_tests_core.get_lab_test_parameter(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_analysis    => i_analysis,
                                                        i_sample_type => i_sample_type,
                                                        o_list        => o_list,
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
                                              'GET_LAB_TEST_PARAMETER',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_parameter;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list t_tbl_lab_tests_results;
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_resultsview(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_type         => i_flg_type,
                                                          i_dt_min           => i_dt_min,
                                                          i_dt_max           => i_dt_max,
                                                          o_list             => l_list,
                                                          o_error            => o_error)
        
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT ar.flg_type,
                   ar.id_analysis_req,
                   ar.id_analysis_req_det,
                   ar.id_ard_parent,
                   ar.id_analysis_req_par,
                   ar.id_analysis_result,
                   ar.id_analysis_result_par,
                   ar.id_arp_parent,
                   ar.id_analysis,
                   ar.id_analysis_parameter,
                   ar.id_sample_type,
                   ar.id_exam_cat,
                   ar.id_harvest,
                   ar.desc_analysis,
                   ar.desc_parameter,
                   ar.desc_sample,
                   ar.desc_category,
                   ar.partial_result,
                   ar.desc_unit_measure,
                   ar.dt_harvest,
                   ar.dt_result,
                   ar.result,
                   ar.flg_multiple_result,
                   ar.flg_result_type,
                   ar.flg_status,
                   ar.flg_result_status,
                   ar.flg_relevant,
                   ar.result_status,
                   ar.result_range,
                   ar.result_color,
                   ar.ref_val,
                   ar.prof_req,
                   ar.dt_req,
                   ar.result_notes,
                   ar.parameter_notes,
                   ar.desc_lab,
                   ar.desc_lab_notes,
                   ar.avail_button_create,
                   ar.avail_button_edit,
                   ar.avail_button_cancel,
                   ar.avail_button_read,
                   ar.avail_button_context,
                   ar.rank_analysis,
                   ar.rank_parameter,
                   ar.rank_category,
                   ar.dt_harvest_ord,
                   ar.dt_result_ord,
                   ar.rn
              FROM TABLE(l_list) ar
             WHERE ar.rn = 1
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        g_error := 'OPEN CURSOR';
        OPEN o_result_list FOR
            SELECT ar.flg_type,
                   ar.id_analysis_req,
                   ar.id_analysis_req_det,
                   ar.id_ard_parent,
                   ar.id_analysis_req_par,
                   ar.id_analysis_result,
                   ar.id_analysis_result_par,
                   ar.id_arp_parent,
                   ar.id_analysis,
                   ar.id_analysis_parameter,
                   ar.id_sample_type,
                   ar.id_exam_cat,
                   ar.id_harvest,
                   ar.desc_analysis,
                   ar.desc_parameter,
                   ar.desc_sample,
                   ar.desc_category,
                   ar.partial_result,
                   ar.desc_unit_measure,
                   ar.dt_harvest,
                   ar.dt_result,
                   ar.result,
                   ar.flg_multiple_result,
                   ar.flg_result_type,
                   ar.flg_status,
                   ar.flg_result_status,
                   ar.flg_relevant,
                   ar.result_status,
                   ar.result_range,
                   ar.result_color,
                   ar.ref_val,
                   ar.prof_req,
                   ar.dt_req,
                   ar.result_notes,
                   ar.parameter_notes,
                   ar.desc_lab,
                   ar.desc_lab_notes,
                   ar.avail_button_create,
                   ar.avail_button_edit,
                   ar.avail_button_cancel,
                   ar.avail_button_read,
                   ar.avail_button_context,
                   ar.rank_analysis,
                   ar.rank_parameter,
                   ar.rank_category,
                   ar.dt_harvest_ord,
                   ar.dt_result_ord,
                   ar.rn
              FROM TABLE(l_list) ar
             ORDER BY ar.rank_category,
                      ar.desc_category,
                      ar.rank_analysis,
                      ar.desc_analysis,
                      decode(i_flg_type, 'H', ar.dt_harvest_ord, ar.dt_result_ord) DESC,
                      decode(i_flg_type, 'H', ar.id_harvest, ar.id_analysis_result) DESC,
                      ar.flg_type,
                      ar.rank_parameter,
                      ar.desc_parameter;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_RESULTSVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_result_list);
            RETURN FALSE;
    END get_lab_test_resultsview;

    FUNCTION get_lab_test_timelineview
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_start_column       IN PLS_INTEGER,
        i_end_column         IN PLS_INTEGER,
        i_last_column_number IN PLS_INTEGER DEFAULT 6,
        o_list_results       OUT pk_types.cursor_type,
        o_list_columns       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_TIMELINEVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_timelineview(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => i_patient,
                                                           i_start_column       => i_start_column,
                                                           i_end_column         => i_end_column,
                                                           i_last_column_number => i_last_column_number,
                                                           o_list_results       => o_list_results,
                                                           o_list_columns       => o_list_columns,
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
                                              'GET_LAB_TEST_TIMELINEVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list_results);
            pk_types.open_my_cursor(o_list_columns);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_timelineview;

    FUNCTION get_lab_test_graphview
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        o_units_convert     OUT table_table_varchar,
        o_cursor_values     OUT pk_types.cursor_type,
        o_cursor_ref_values OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_GRAPHVIEW';
        IF NOT pk_lab_tests_core.get_lab_test_graphview(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_patient           => i_patient,
                                                        o_units_convert     => o_units_convert,
                                                        o_cursor_values     => o_cursor_values,
                                                        o_cursor_ref_values => o_cursor_ref_values,
                                                        o_error             => o_error)
        
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
                                              'GET_LAB_TEST_GRAPHVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_values);
            pk_types.open_my_cursor(o_cursor_ref_values);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_graphview;

    FUNCTION get_lab_test_graphview_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        id_tl_timeline     IN tl_timeline.id_tl_timeline%TYPE,
        id_tl_scale        IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        i_patient          IN NUMBER,
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_GRAPHVIEW_DATA';
        IF NOT pk_lab_tests_core.get_lab_test_graphview_data(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             id_tl_timeline     => id_tl_timeline,
                                                             id_tl_scale        => id_tl_scale,
                                                             i_block_req_number => i_block_req_number,
                                                             i_request_date     => i_request_date,
                                                             i_direction        => i_direction,
                                                             i_patient          => i_patient,
                                                             o_time_data        => o_x_data,
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
                                              'GET_LAB_TEST_GRAPHVIEW_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_x_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_graphview_data;

    FUNCTION get_harvest_movement_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_MOVEMENT_LISTVIEW';
        IF NOT pk_lab_tests_harvest_core.get_harvest_movement_listview(i_lang    => i_lang,
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
                                              'GET_HARVEST_MOVEMENT_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_movement_listview;

    FUNCTION get_harvest_preview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_PREVIEW';
        IF NOT pk_lab_tests_harvest_core.get_harvest_preview(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_analysis_req_det => i_analysis_req_det,
                                                             o_list             => o_list,
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
                                              'GET_HARVEST_PREVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_preview;

    FUNCTION get_lab_test_questionnaire
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        i_room        IN room.id_room%TYPE,
        i_flg_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_QUESTIONNAIRE';
        IF NOT pk_lab_tests_core.get_lab_test_questionnaire(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_patient     => i_patient,
                                                            i_episode     => i_episode,
                                                            i_analysis    => i_analysis,
                                                            i_sample_type => i_sample_type,
                                                            i_room        => i_room,
                                                            i_flg_type    => i_flg_type,
                                                            i_flg_time    => i_flg_time,
                                                            o_list        => o_list,
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
                                              'GET_LAB_TEST_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_questionnaire;

    FUNCTION get_lab_test_codification_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_CODIFICATION_DET';
        IF NOT pk_lab_tests_core.get_lab_test_codification_det(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_analysis_req_det => i_analysis_req_det,
                                                               o_list             => o_list,
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
                                              'GET_LAB_TEST_CODIFICATION_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_codification_det;

    FUNCTION get_lab_test_no_result
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_NO_RESULT';
        IF NOT pk_lab_tests_core.get_lab_test_no_result(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_patient     => i_patient,
                                                        i_analysis    => i_analysis,
                                                        i_sample_type => i_sample_type,
                                                        o_list        => o_list,
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
                                              'GET_LAB_TEST_NO_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_no_result;

    FUNCTION get_lab_test_order_detail
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_analysis_req           IN analysis_req.id_analysis_req%TYPE,
        o_lab_test_order         OUT pk_types.cursor_type,
        o_lab_test_order_barcode OUT pk_types.cursor_type,
        o_lab_test_order_history OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_ORDER_DETAIL';
        IF NOT pk_lab_tests_core.get_lab_test_order_detail(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_analysis_req           => i_analysis_req,
                                                           o_lab_test_order         => o_lab_test_order,
                                                           o_lab_test_order_barcode => o_lab_test_order_barcode,
                                                           o_lab_test_order_history => o_lab_test_order_history,
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
                                              'GET_LAB_TEST_ORDER_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_order_detail;

    FUNCTION get_lab_test_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_api_db.get_lab_test_detail(i_lang                        => i_lang,
                                                       i_prof                        => i_prof,
                                                       i_episode                     => i_episode,
                                                       i_analysis_req_det            => i_analysis_req_det,
                                                       o_lab_test_order              => o_lab_test_order,
                                                       o_lab_test_co_sign            => o_lab_test_co_sign,
                                                       o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                       o_lab_test_harvest            => o_lab_test_harvest,
                                                       o_lab_test_result             => o_lab_test_result,
                                                       o_lab_test_doc                => o_lab_test_doc,
                                                       o_lab_test_review             => o_lab_test_review,
                                                       o_error                       => o_error)
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
                                              'GET_LAB_TEST_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_result);
            pk_types.open_my_cursor(o_lab_test_doc);
            pk_types.open_my_cursor(o_lab_test_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_detail;

    FUNCTION get_lab_test_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_api_db.get_lab_test_detail_history(i_lang                        => i_lang,
                                                               i_prof                        => i_prof,
                                                               i_episode                     => i_episode,
                                                               i_analysis_req_det            => i_analysis_req_det,
                                                               o_lab_test_order              => o_lab_test_order,
                                                               o_lab_test_co_sign            => o_lab_test_co_sign,
                                                               o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                               o_lab_test_harvest            => o_lab_test_harvest,
                                                               o_lab_test_result             => o_lab_test_result,
                                                               o_lab_test_doc                => o_lab_test_doc,
                                                               o_lab_test_review             => o_lab_test_review,
                                                               o_error                       => o_error)
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
                                              'GET_LAB_TEST_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_result);
            pk_types.open_my_cursor(o_lab_test_doc);
            pk_types.open_my_cursor(o_lab_test_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_detail_history;

    FUNCTION get_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_DETAIL';
        IF NOT pk_lab_tests_harvest_core.get_harvest_detail(i_lang                        => i_lang,
                                                            i_prof                        => i_prof,
                                                            i_harvest                     => i_harvest,
                                                            o_lab_test_harvest            => o_lab_test_harvest,
                                                            o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                            o_error                       => o_error)
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
                                              'GET_HARVEST_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_detail;

    FUNCTION get_harvest_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_DETAIL_HISTORY';
        IF NOT pk_lab_tests_harvest_core.get_harvest_detail(i_lang                        => i_lang,
                                                            i_prof                        => i_prof,
                                                            i_harvest                     => i_harvest,
                                                            o_lab_test_harvest            => o_lab_test_harvest,
                                                            o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                            o_error                       => o_error)
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
                                              'GET_HARVEST_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_detail_history;

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_MOVEMENT_DETAIL';
        IF NOT pk_lab_tests_harvest_core.get_harvest_movement_detail(i_lang                     => i_lang,
                                                                     i_prof                     => i_prof,
                                                                     i_harvest                  => i_harvest,
                                                                     o_lab_test_harvest         => o_lab_test_harvest,
                                                                     o_lab_test_harvest_history => o_lab_test_harvest_history,
                                                                     o_error                    => o_error)
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
                                              'GET_HARVEST_MOVEMENT_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_harvest_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_movement_detail;

    FUNCTION get_lab_test_order
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.get_lab_test_order(i_lang                        => i_lang,
                                                    i_prof                        => i_prof,
                                                    i_episode                     => i_episode,
                                                    i_analysis_req_det            => i_analysis_req_det,
                                                    o_lab_test_order              => o_lab_test_order,
                                                    o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                    o_error                       => o_error)
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
                                              'GET_LAB_TEST_ORDER',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_order;

    FUNCTION get_lab_test_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_HARVEST';
        IF NOT pk_lab_tests_core.get_lab_test_harvest(i_lang                        => i_lang,
                                                      i_prof                        => i_prof,
                                                      i_analysis_req_det            => i_analysis_req_det,
                                                      o_lab_test_harvest            => o_lab_test_harvest,
                                                      o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                      o_error                       => o_error)
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
                                              'GET_LAB_TEST_HARVEST',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_harvest;

    FUNCTION get_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_analysis_result_par        IN table_number,
        o_lab_test_result            OUT pk_types.cursor_type,
        o_lab_test_result_laboratory OUT pk_types.cursor_type,
        o_lab_test_result_history    OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_core.get_lab_test_result(i_lang                       => i_lang,
                                                     i_prof                       => i_prof,
                                                     i_analysis_result_par        => i_analysis_result_par,
                                                     o_lab_test_result            => o_lab_test_result,
                                                     o_lab_test_result_laboratory => o_lab_test_result_laboratory,
                                                     o_lab_test_result_history    => o_lab_test_result_history,
                                                     o_error                      => o_error)
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
                                              'GET_LAB_TEST_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_result);
            pk_types.open_my_cursor(o_lab_test_result_history);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result;

    FUNCTION get_lab_test_doc_associated
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_doc     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_DOC_ASSOCIATED';
        IF NOT pk_lab_tests_core.get_lab_test_doc_associated(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_analysis_req_det => i_analysis_req_det,
                                                             o_lab_test_doc     => o_lab_test_doc,
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
                                              'GET_LAB_TEST_DOC_ASSOCIATED',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_doc);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_doc_associated;

    FUNCTION get_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST';
        IF NOT pk_lab_tests_harvest_core.get_harvest(i_lang                        => i_lang,
                                                     i_prof                        => i_prof,
                                                     i_harvest                     => i_harvest,
                                                     o_lab_test_harvest            => o_lab_test_harvest,
                                                     o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                     o_error                       => o_error)
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
                                              'GET_HARVEST',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest;

    FUNCTION get_harvest_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_lab_test_harvest OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_BARCODE';
        IF NOT pk_lab_tests_harvest_core.get_harvest_barcode(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_harvest          => i_harvest,
                                                             o_lab_test_harvest => o_lab_test_harvest,
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
                                              'GET_HARVEST_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_barcode;

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_harvest           IN table_number,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_BARCODE_FOR_PRINT';
        IF NOT pk_lab_tests_harvest_core.get_harvest_barcode_for_print(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_harvest           => i_harvest,
                                                                       o_printer           => o_printer,
                                                                       o_codification_type => o_codification_type,
                                                                       o_barcode           => o_barcode,
                                                                       o_error             => o_error)
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
                                              'GET_HARVEST_BARCODE_FOR_PRINT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_barcode_for_print;

    FUNCTION get_lab_test_to_edit
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN table_number,
        o_lab_test                    OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_TO_EDIT';
        IF NOT pk_lab_tests_core.get_lab_test_to_edit(i_lang                        => i_lang,
                                                      i_prof                        => i_prof,
                                                      i_episode                     => i_episode,
                                                      i_analysis_req_det            => i_analysis_req_det,
                                                      o_lab_test                    => o_lab_test,
                                                      o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                      o_error                       => o_error)
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
                                              'GET_LAB_TEST_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_to_edit;

    FUNCTION get_lab_test_response_to_edit
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_analysis_req_det            IN analysis_question_response.id_analysis_req_det%TYPE,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESPONSE_TO_EDIT';
        IF NOT pk_lab_tests_core.get_lab_test_response_to_edit(i_lang                        => i_lang,
                                                               i_prof                        => i_prof,
                                                               i_analysis_req_det            => i_analysis_req_det,
                                                               o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                               o_error                       => o_error)
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
                                              'GET_LAB_TEST_RESPONSE_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_response_to_edit;

    FUNCTION get_lab_test_to_result
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis         IN analysis.id_analysis%TYPE,
        i_sample_type      IN sample_type.id_sample_type%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_analysis_result  IN analysis_result.id_analysis_result%TYPE,
        i_flg_type         IN VARCHAR2,
        o_lab_test         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_TO_RESULT';
        IF NOT pk_lab_tests_core.get_lab_test_to_result(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_patient          => i_patient,
                                                        i_analysis         => i_analysis,
                                                        i_sample_type      => i_sample_type,
                                                        i_analysis_req_det => i_analysis_req_det,
                                                        i_harvest          => i_harvest,
                                                        i_analysis_result  => i_analysis_result,
                                                        i_flg_type         => i_flg_type,
                                                        o_lab_test         => o_lab_test,
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
                                              'GET_LAB_TEST_TO_RESULT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_to_result;

    FUNCTION get_lab_test_to_read
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_lab_test         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_TO_READ';
        IF NOT pk_lab_tests_core.get_lab_test_to_read(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_analysis_req_det => i_analysis_req_det,
                                                      o_lab_test         => o_lab_test,
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
                                              'GET_LAB_TEST_TO_READ',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_to_read;

    FUNCTION get_harvest_to_collect
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN table_number,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_TO_COLLECT';
        IF NOT pk_lab_tests_harvest_core.get_harvest_to_collect(i_lang                        => i_lang,
                                                                i_prof                        => i_prof,
                                                                i_harvest                     => i_harvest,
                                                                o_lab_test_order              => o_lab_test_order,
                                                                o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                                o_lab_test_harvest            => o_lab_test_harvest,
                                                                o_error                       => o_error)
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
                                              'GET_HARVEST_TO_COLLECT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_to_collect;

    FUNCTION get_harvest_laboratory
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_LABORATORY';
        IF NOT pk_lab_tests_harvest_core.get_harvest_laboratory(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_episode => i_episode,
                                                                i_harvest => i_harvest,
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
                                              'GET_HARVEST_LABORATORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_laboratory;

    FUNCTION get_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_SAMPLE_RECIPIENT';
        IF NOT pk_lab_tests_harvest_core.get_harvest_sample_recipient(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_episode => i_episode,
                                                                      i_harvest => i_harvest,
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
                                              'GET_HARVEST_SAMPLE_RECIPIENT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_sample_recipient;

    FUNCTION get_lab_test_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_analysis_req      IN analysis_req.id_analysis_req%TYPE,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_BARCODE_FOR_PRINT';
        IF NOT pk_lab_tests_core.get_lab_test_barcode_for_print(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_analysis_req      => i_analysis_req,
                                                                o_printer           => o_printer,
                                                                o_codification_type => o_codification_type,
                                                                o_barcode           => o_barcode,
                                                                o_error             => o_error)
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
                                              'GET_LAB_TEST_BARCODE_FOR_PRINT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_barcode_for_print;

    FUNCTION get_lab_test_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_FILTER_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_filter_list(i_lang    => i_lang,
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
                                              'GET_LAB_TEST_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_filter_list;

    FUNCTION get_lab_test_order_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        i_harvest      IN harvest.id_harvest%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_ORDER_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_order_list(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_patient      => i_patient,
                                                         i_analysis_req => i_analysis_req,
                                                         i_harvest      => i_harvest,
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
                                              'GET_LAB_TEST_ORDER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_order_list;

    FUNCTION get_lab_test_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_TIME_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_time_list(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_epis_type => i_epis_type,
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
                                              'GET_LAB_TEST_TIME_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_time_list;

    FUNCTION get_lab_test_priority_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_PRIORITY_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_priority_list(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_analysis    => i_analysis,
                                                            i_sample_type => i_sample_type,
                                                            o_list        => o_list,
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
                                              'GET_LAB_TEST_PRIORITY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_priority_list;

    FUNCTION get_lab_test_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_DIAGNOSIS_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_diagnosis_list(i_lang    => i_lang,
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
                                              'GET_LAB_TEST_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_diagnosis_list;

    FUNCTION get_lab_test_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_CLINICAL_PURPOSE';
        IF NOT pk_lab_tests_core.get_lab_test_clinical_purpose(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_CLINICAL_PURPOSE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_clinical_purpose;

    FUNCTION get_lab_test_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_PRN_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_prn_list(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_PRN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_prn_list;

    FUNCTION get_lab_test_fasting_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_FASTING_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_fasting_list(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_FASTING_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_fasting_list;

    FUNCTION get_lab_test_specimen_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN table_number,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_SPECIMEN_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_specimen_list(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_analysis => i_analysis,
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
                                              'GET_LAB_TEST_SPECIMEN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_specimen_list;

    FUNCTION get_lab_test_body_part_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN sample_type.id_sample_type%TYPE,
        i_value       IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_BODY_PART_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_body_part_list(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_analysis    => i_analysis,
                                                             i_sample_type => i_sample_type,
                                                             i_value       => i_value,
                                                             o_list        => o_list,
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
                                              'GET_LAB_TEST_BODY_PART_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_body_part_list;

    FUNCTION get_lab_test_location_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_LOCATION_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_location_list(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_analysis    => i_analysis,
                                                            i_sample_type => i_sample_type,
                                                            i_flg_type    => NULL,
                                                            o_list        => o_list,
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
                                              'GET_LAB_TEST_LOCATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_location_list;

    FUNCTION get_lab_test_codification_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_CODIFICATION_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_codification_list(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_analysis    => i_analysis,
                                                                i_sample_type => i_sample_type,
                                                                o_list        => o_list,
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
                                              'GET_LAB_TEST_CODIFICATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_codification_list;

    FUNCTION get_lab_test_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_LAB_TEST_HEALTH_PLAN_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_health_plan_list(i_lang    => i_lang,
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
                                              'GET_LAB_TEST_HEALTH_PLAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_health_plan_list;

    FUNCTION get_harvest_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_HARVEST_ORDER_LIST';
        IF NOT pk_lab_tests_harvest_core.get_harvest_order_list(i_lang    => i_lang,
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
                                              'GET_HARVEST_ORDER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_order_list;

    FUNCTION get_harvest_method_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_COREGET_HARVEST_METHOD_LIST';
        IF NOT pk_lab_tests_harvest_core.get_harvest_method_list(i_lang  => i_lang,
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
                                              'GET_HARVEST_METHOD_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_method_list;

    FUNCTION get_harvest_transport_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_HARVEST_TRANSPORT_LIST';
        IF NOT pk_lab_tests_harvest_core.get_harvest_transport_list(i_lang  => i_lang,
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
                                              'GET_HARVEST_TRANSPORT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_transport_list;

    FUNCTION get_harvest_reason_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_REASON_LIST';
        IF NOT pk_lab_tests_harvest_core.get_harvest_reason_list(i_lang  => i_lang,
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
                                              'GET_HARVEST_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_harvest_reason_list;

    FUNCTION get_lab_test_result_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_result_list(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_analysis           => i_analysis,
                                                          i_sample_type        => i_sample_type,
                                                          i_analysis_parameter => i_analysis_parameter,
                                                          o_list               => o_list,
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
                                              'GET_LAB_TEST_RESULT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_list;

    FUNCTION get_lab_test_unit_measure_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_UNIT_MEASURE_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_unit_measure_list(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_analysis           => i_analysis,
                                                                i_sample_type        => i_sample_type,
                                                                i_analysis_parameter => i_analysis_parameter,
                                                                o_list               => o_list,
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
                                              'GET_LAB_TEST_UNIT_MEASURE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_unit_measure_list;

    FUNCTION get_lab_test_result_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_analysis_param IN analysis_param.id_analysis_param%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT_TYPE';
        IF NOT pk_lab_tests_core.get_lab_test_result_type(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_analysis_param => i_analysis_param,
                                                          o_list           => o_list,
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
                                              'GET_LAB_TEST_RESULT_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_type;

    FUNCTION get_lab_test_result_status
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT_STATUS';
        IF NOT pk_lab_tests_core.get_lab_test_result_status(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_RESULT_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_status;

    FUNCTION get_lab_test_result_origin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT_ORIGIN';
        IF NOT pk_lab_tests_core.get_lab_test_result_origin(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_RESULT_ORIGIN',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_origin;

    FUNCTION get_lab_test_result_prof_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_RESULT_PROF_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_result_prof_list(i_lang  => i_lang,
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
                                              'GET_LAB_TEST_RESULT_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_prof_list;

    FUNCTION get_lab_test_result_url
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_url_type         IN VARCHAR2,
        o_url              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_LAB_TEST_RESULT_URL';
        IF NOT pk_lab_tests_utils.get_lab_test_result_url(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_url_type         => i_url_type,
                                                          o_url              => o_url,
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
                                              'GET_LAB_TEST_RESULT_URL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_result_url;

    FUNCTION get_lab_test_unit_conversion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_unit_measure_src   IN unit_measure.id_unit_measure%TYPE,
        i_unit_measure_dst   IN unit_measure.id_unit_measure%TYPE,
        i_values             IN table_varchar,
        o_list               OUT table_varchar,
        o_unit_measure_list  OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_UNIT_CONVERSION';
        IF NOT pk_lab_tests_core.get_lab_test_unit_conversion(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_analysis_parameter => i_analysis_parameter,
                                                              i_unit_measure_src   => i_unit_measure_src,
                                                              i_unit_measure_dst   => i_unit_measure_dst,
                                                              i_values             => i_values,
                                                              o_list               => o_list,
                                                              o_unit_measure_list  => o_unit_measure_list,
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
                                              'GET_LAB_TEST_UNIT_CONVERSION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_unit_conversion;

    FUNCTION get_lab_test_param_unit_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        i_unit_measure       IN lab_tests_par_uni_mea.id_unit_measure%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_PARAMETER_UNIT_LIST';
        IF NOT pk_lab_tests_core.get_lab_test_parameter_unit_list(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_patient            => i_patient,
                                                                  i_analysis_parameter => i_analysis_parameter,
                                                                  i_unit_measure       => i_unit_measure,
                                                                  o_list               => o_list,
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
                                              'GET_LAB_TEST_PARAMETER_UNIT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_param_unit_list;

    FUNCTION get_lab_test_parameter_for_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_param     IN table_number,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_PARAMETER_FOR_CDR';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_parameter_for_cdr(i_lang               => i_lang,
                                                                           i_prof               => i_prof,
                                                                           i_analysis_param     => i_analysis_param,
                                                                           o_analysis_parameter => o_analysis_parameter,
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
                                              'GET_LAB_TEST_PARAMETER_FOR_CDR',
                                              o_error);
            pk_types.open_my_cursor(o_analysis_parameter);
            RETURN FALSE;
    END get_lab_test_parameter_for_cdr;

    FUNCTION get_lab_test_context_help
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis            IN table_varchar,
        i_analysis_result_par IN table_number,
        o_content             OUT table_varchar,
        o_map_target_code     OUT table_varchar,
        o_id_map_set          OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_INFO_BUTTON';
        RETURN pk_lab_tests_external.get_lab_test_context_help(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_analysis            => i_analysis,
                                                               i_analysis_result_par => i_analysis_result_par,
                                                               o_content             => o_content,
                                                               o_map_target_code     => o_map_target_code,
                                                               o_id_map_set          => o_id_map_set,
                                                               o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_lab_test_context_help;

    FUNCTION get_lab_test_print_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_PRINT_LIST';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_print_list(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    o_options => o_options,
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
                                              'GET_LAB_TEST_PRINT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_lab_test_print_list;

    FUNCTION add_print_list_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_print_arguments  IN table_varchar,
        o_print_list_job   OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.ADD_PRINT_LIST_JOBS';
        IF NOT pk_lab_tests_external_api_db.add_print_list_jobs(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_patient          => i_patient,
                                                                i_episode          => i_episode,
                                                                i_analysis_req_det => i_analysis_req_det,
                                                                i_print_arguments  => i_print_arguments,
                                                                o_print_list_job   => o_print_list_job,
                                                                o_error            => o_error)
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

    FUNCTION get_lab_test_all_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_analysis_req    IN analysis_req.id_analysis_req%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_harvest         IN harvest.id_harvest%TYPE,
        i_flg_search_type IN VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.ADD_PRINT_LIST_JOBS';
        IF NOT pk_lab_tests_core.get_lab_test_all_search(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_patient         => i_patient,
                                                         i_analysis_req    => i_analysis_req,
                                                         i_sample_type     => i_sample_type,
                                                         i_exam_cat        => i_exam_cat,
                                                         i_exam_cat_parent => i_exam_cat_parent,
                                                         i_codification    => i_codification,
                                                         i_harvest         => i_harvest,
                                                         i_flg_search_type => i_flg_search_type,
                                                         o_list            => o_list,
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
                                              'GET_LAB_TEST_ALL_SEARCH',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_all_search;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_api_ux;
/
