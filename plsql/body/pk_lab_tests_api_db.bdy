/*-- Last Change Revision: $Rev: 2027300 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_api_db IS

    FUNCTION create_lab_test_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_analysis_req            IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det        IN table_number,
        i_analysis_req_det_parent IN table_number,
        i_harvest                 IN harvest.id_harvest%TYPE,
        i_analysis                IN table_number,
        i_analysis_group          IN table_table_varchar, --10
        i_flg_type                IN table_varchar,
        i_dt_req                  IN table_varchar,
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_dt_begin_limit          IN table_varchar, --15
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar, --20
        i_specimen                IN table_number,
        i_body_location           IN table_table_number,
        i_laterality              IN table_table_varchar,
        i_collection_room         IN table_number,
        i_notes                   IN table_varchar, --25
        i_notes_scheduler         IN table_varchar,
        i_notes_technician        IN table_varchar,
        i_notes_patient           IN table_varchar,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis,
        i_exec_institution        IN table_number, --30
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_flg_col_inst            IN table_varchar,
        i_flg_fasting             IN table_varchar,
        i_lab_req                 IN table_number, --35
        i_prof_cc                 IN table_table_varchar,
        i_prof_bcc                IN table_table_varchar,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number, --40
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar, --45
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN analysis_req_det.flg_req_origin_module%TYPE DEFAULT 'D',
        i_task_dependency         IN table_number,
        i_flg_task_depending      IN table_varchar, --50
        i_episode_followup_app    IN table_number,
        i_schedule_followup_app   IN table_number,
        i_event_followup_app      IN table_number,
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
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CREATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_core.create_lab_test_order(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_patient                 => i_patient,
                                                       i_episode                 => i_episode,
                                                       i_analysis_req            => i_analysis_req,
                                                       i_analysis_req_det        => i_analysis_req_det,
                                                       i_analysis_req_det_parent => i_analysis_req_det_parent,
                                                       i_harvest                 => i_harvest,
                                                       i_analysis                => i_analysis,
                                                       i_analysis_group          => i_analysis_group,
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
                                                       i_specimen                => i_specimen,
                                                       i_body_location           => i_body_location,
                                                       i_laterality              => i_laterality,
                                                       i_collection_room         => i_collection_room,
                                                       i_notes                   => i_notes,
                                                       i_notes_scheduler         => i_notes_scheduler,
                                                       i_notes_technician        => i_notes_technician,
                                                       i_notes_patient           => i_notes_patient,
                                                       i_diagnosis_notes         => i_diagnosis_notes,
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
            IF o_error.err_desc IS NOT NULL
            THEN
                g_error_code := o_error.ora_sqlcode;
                g_error      := o_error.ora_sqlerrm;
            
                RAISE g_user_exception;
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
                                              'CREATE_LAB_TEST_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_order;

    FUNCTION create_lab_test_recurrence
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CREATE_LAB_TEST_RECURRENCE';
        IF NOT pk_lab_tests_core.create_lab_test_recurrence(i_lang            => i_lang,
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
                                              'CREATE_LAB_TEST_RECURRENCE',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_recurrence;

    FUNCTION create_lab_test_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_exam.id_schedule%TYPE,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.CREATE_LAB_TEST_VISIT';
        IF NOT pk_lab_tests_core.create_lab_test_visit(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_patient          => i_patient,
                                                       i_episode          => i_episode,
                                                       i_schedule         => i_schedule,
                                                       i_analysis_req_det => i_analysis_req_det,
                                                       i_dt_begin         => i_dt_begin,
                                                       i_transaction_id   => i_transaction_id,
                                                       o_episode          => o_episode,
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
                                              'CREATE_LAB_TEST_VISIT',
                                              o_error);
            RETURN FALSE;
    END create_lab_test_visit;

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST';
        IF NOT pk_lab_tests_harvest_core.set_harvest(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_analysis_req_det => i_analysis_req_det,
                                                     i_harvest          => i_harvest,
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
                                              'SET_HARVEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest;

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number, --5
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar, --15
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
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
                                                          i_specimen_condition        => i_specimen_condition,
                                                          i_collection_room           => i_collection_room,
                                                          i_lab                       => i_lab,
                                                          i_exec_institution          => i_exec_institution,
                                                          i_sample_recipient          => i_sample_recipient,
                                                          i_num_recipient             => i_num_recipient,
                                                          i_collection_time           => i_collection_time,
                                                          i_collection_amount         => i_collection_amount,
                                                          i_collection_transportation => i_collection_transportation,
                                                          i_notes                     => i_notes,
                                                          i_flg_orig_harvest          => i_flg_orig_harvest,
                                                          o_error                     => o_error)
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
                                              'SET_HARVEST_EDIT',
                                              o_error);
            RETURN FALSE;
    END set_harvest_edit;

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN NUMBER,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
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
                                                             i_specimen_condition        => i_specimen_condition,
                                                             i_collection_room           => i_collection_room,
                                                             i_lab                       => i_lab,
                                                             i_exec_institution          => i_exec_institution,
                                                             i_sample_recipient          => i_sample_recipient,
                                                             i_num_recipient             => i_num_recipient,
                                                             i_collection_time           => i_collection_time,
                                                             i_collection_amount         => i_collection_amount,
                                                             i_collection_transportation => i_collection_transportation,
                                                             i_notes                     => i_notes,
                                                             i_flg_orig_harvest          => i_flg_orig_harvest,
                                                             o_harvest                   => o_harvest,
                                                             o_error                     => o_error)
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
                                              'SET_HARVEST_COMBINE',
                                              o_error);
            RETURN FALSE;
    END set_harvest_combine;

    FUNCTION set_harvest_repeat
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_visit                     IN visit.id_visit%TYPE,
        i_episode                   IN episode.id_episode%TYPE, --5
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number,
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE, --10
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE, --15
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --20
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_REPEAT';
        IF NOT pk_lab_tests_harvest_core.set_harvest_repeat(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_patient                   => i_patient,
                                                            i_visit                     => i_visit,
                                                            i_episode                   => i_episode,
                                                            i_harvest                   => i_harvest,
                                                            i_analysis_harvest          => i_analysis_harvest,
                                                            i_analysis_req_det          => i_analysis_req_det,
                                                            i_body_location             => i_body_location,
                                                            i_laterality                => i_laterality,
                                                            i_collection_method         => i_collection_method,
                                                            i_specimen_condition        => i_specimen_condition,
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
                                                            i_rep_coll_reason           => i_rep_coll_reason,
                                                            i_flg_orig_harvest          => i_flg_orig_harvest,
                                                            o_error                     => o_error)
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
                                              'SET_HARVEST_REPEAT',
                                              o_error);
            RETURN FALSE;
    END set_harvest_repeat;

    FUNCTION set_harvest_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_harvest            IN table_number,
        i_cancel_reason      IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes       IN harvest.notes_cancel%TYPE,
        i_specimen_condition IN harvest.id_specimen_condition%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_REJECT';
        IF NOT pk_lab_tests_harvest_core.set_harvest_reject(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_patient            => i_patient,
                                                            i_episode            => i_episode,
                                                            i_harvest            => i_harvest,
                                                            i_cancel_reason      => i_cancel_reason,
                                                            i_cancel_notes       => i_cancel_notes,
                                                            i_specimen_condition => i_specimen_condition,
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
                                              'SET_HARVEST_REJECT',
                                              o_error);
            RETURN FALSE;
    END set_harvest_reject;

    FUNCTION set_lab_test_result
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN analysis_result.id_patient%TYPE,
        i_episode                    IN analysis_result.id_episode%TYPE,
        i_analysis                   IN analysis.id_analysis%TYPE,
        i_sample_type                IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter         IN table_number,
        i_analysis_param             IN table_number,
        i_analysis_req_det           IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par           IN table_number,
        i_analysis_result_par        IN table_number,
        i_analysis_result_par_parent IN table_number,
        i_flg_type                   IN table_varchar,
        i_harvest                    IN harvest.id_harvest%TYPE,
        i_dt_sample                  IN VARCHAR2,
        i_prof_req                   IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result         IN VARCHAR2,
        i_flg_result_origin          IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes        IN analysis_result.result_origin_notes%TYPE,
        i_result_notes               IN analysis_result.notes%TYPE,
        i_loinc_code                 IN analysis_result.loinc_code%TYPE DEFAULT NULL,
        i_dt_ext_registry            IN table_varchar DEFAULT NULL,
        i_instit_origin              IN table_number DEFAULT NULL,
        i_result_value_1             IN table_varchar,
        i_result_value_2             IN table_number DEFAULT NULL,
        i_analysis_desc              IN table_number,
        i_doc_external               IN table_table_number DEFAULT NULL,
        i_comparator                 IN table_varchar DEFAULT NULL,
        i_separator                  IN table_varchar DEFAULT NULL,
        i_standard_code              IN table_varchar DEFAULT NULL,
        i_unit_measure               IN table_number,
        i_desc_unit_measure          IN table_varchar DEFAULT NULL,
        i_result_status              IN table_number,
        i_ref_val                    IN table_varchar DEFAULT NULL,
        i_ref_val_min                IN table_varchar,
        i_ref_val_max                IN table_varchar,
        i_parameter_notes            IN table_varchar,
        i_interface_notes            IN table_varchar DEFAULT NULL,
        i_laboratory                 IN table_number DEFAULT NULL,
        i_laboratory_desc            IN table_varchar DEFAULT NULL,
        i_laboratory_short_desc      IN table_varchar DEFAULT NULL,
        i_coding_system              IN table_varchar DEFAULT NULL,
        i_method                     IN table_varchar DEFAULT NULL,
        i_equipment                  IN table_varchar DEFAULT NULL,
        i_abnormality                IN table_number DEFAULT NULL,
        i_abnormality_nature         IN table_number DEFAULT NULL,
        i_prof_validation            IN table_number DEFAULT NULL,
        i_dt_validation              IN table_varchar DEFAULT NULL,
        i_flg_intf_orig              IN analysis_result_par.flg_intf_orig%TYPE DEFAULT 'N',
        i_flg_orig_analysis          IN analysis_result.flg_orig_analysis%TYPE,
        i_clinical_decision_rule     IN NUMBER,
        o_result                     OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_LAB_TESTS_CORE.SET_LAB_TEST_RESULT';
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
                                                     i_analysis_result_par_parent => i_analysis_result_par_parent,
                                                     i_flg_type                   => i_flg_type,
                                                     i_harvest                    => i_harvest,
                                                     i_dt_sample                  => i_dt_sample,
                                                     i_prof_req                   => i_prof_req,
                                                     i_dt_analysis_result         => i_dt_analysis_result,
                                                     i_flg_result_origin          => i_flg_result_origin,
                                                     i_result_origin_notes        => i_result_origin_notes,
                                                     i_result_notes               => i_result_notes,
                                                     i_loinc_code                 => i_loinc_code,
                                                     i_dt_ext_registry            => i_dt_ext_registry,
                                                     i_instit_origin              => i_instit_origin,
                                                     i_result_value_1             => i_result_value_1,
                                                     i_result_value_2             => i_result_value_2,
                                                     i_analysis_desc              => i_analysis_desc,
                                                     i_doc_external               => i_doc_external,
                                                     i_comparator                 => i_comparator,
                                                     i_separator                  => i_separator,
                                                     i_standard_code              => i_standard_code,
                                                     i_unit_measure               => i_unit_measure,
                                                     i_desc_unit_measure          => i_desc_unit_measure,
                                                     i_result_status              => i_result_status,
                                                     i_ref_val                    => i_ref_val,
                                                     i_ref_val_min                => i_ref_val_min,
                                                     i_ref_val_max                => i_ref_val_max,
                                                     i_parameter_notes            => i_parameter_notes,
                                                     i_interface_notes            => i_interface_notes,
                                                     i_laboratory                 => i_laboratory,
                                                     i_laboratory_desc            => i_laboratory_desc,
                                                     i_laboratory_short_desc      => i_laboratory_short_desc,
                                                     i_coding_system              => i_coding_system,
                                                     i_method                     => i_method,
                                                     i_equipment                  => i_equipment,
                                                     i_abnormality                => i_abnormality,
                                                     i_abnormality_nature         => i_abnormality_nature,
                                                     i_prof_validation            => i_prof_validation,
                                                     i_dt_validation              => i_dt_validation,
                                                     i_flg_intf_orig              => i_flg_intf_orig,
                                                     i_flg_orig_analysis          => i_flg_orig_analysis,
                                                     i_clinical_decision_rule     => i_clinical_decision_rule,
                                                     o_result                     => o_result,
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
                                              'SET_LAB_TEST_RESULT',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_result;

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
                                              'SET_LAB_TEST_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_status;

    FUNCTION set_lab_test_status_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis_result_par IN table_number,
        i_flg_relevant        IN table_varchar,
        i_notes               IN table_varchar,
        i_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_STATUS_READ';
        IF NOT pk_lab_tests_core.set_lab_test_status_read(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_analysis_result_par => i_analysis_result_par,
                                                          i_flg_relevant        => i_flg_relevant,
                                                          i_notes               => i_notes,
                                                          i_cancel_reason       => i_cancel_reason,
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
                                              'SET_LAB_TEST_DATE',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_date;

    FUNCTION set_lab_test_grid_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TECH.SET_LAB_TEST_GRID_TASK';
        IF NOT pk_lab_tech.set_lab_test_grid_task(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_patient          => i_patient,
                                                  i_episode          => i_episode,
                                                  i_analysis_req     => i_analysis_req,
                                                  i_analysis_req_det => i_analysis_req_det,
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
                                              'SET_LAB_TEST_GRID_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_grid_task;

    FUNCTION update_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN table_number,
        i_status           IN table_varchar,
        i_collected_by     IN table_number,
        i_collection_time  IN table_varchar,
        i_flg_orig_harvest IN harvest.flg_orig_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.UPDATE_HARVEST';
        IF NOT pk_lab_tests_harvest_core.update_harvest(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_harvest          => i_harvest,
                                                        i_status           => i_status,
                                                        i_collected_by     => i_collected_by,
                                                        i_collection_time  => i_collection_time,
                                                        i_flg_orig_harvest => i_flg_orig_harvest,
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
                                              'UPDATE_HARVEST',
                                              o_error);
            RETURN FALSE;
    END update_harvest;

    FUNCTION update_lab_test_result
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN analysis_req.id_episode%TYPE,
        i_analysis_result_par    IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN VARCHAR2,
        i_dt_ext_registry        IN VARCHAR2 DEFAULT NULL,
        i_instit_origin          IN analysis_result_par.id_instit_origin%TYPE DEFAULT NULL,
        i_result_value_1         IN analysis_result_par.desc_analysis_result%TYPE,
        i_result_value_2         IN analysis_result_par.analysis_result_value_2%TYPE DEFAULT NULL,
        i_analysis_desc          IN analysis_desc.id_analysis_desc%TYPE,
        i_comparator             IN analysis_result_par.comparator%TYPE DEFAULT NULL,
        i_separator              IN analysis_result_par.separator%TYPE DEFAULT NULL,
        i_standard_code          IN analysis_result_par.standard_code%TYPE DEFAULT NULL,
        i_unit_measure           IN analysis_result_par.id_unit_measure%TYPE,
        i_desc_unit_measure      IN analysis_result_par.desc_unit_measure%TYPE DEFAULT NULL,
        i_result_status          IN analysis_result_par.id_result_status%TYPE,
        i_ref_val                IN analysis_result_par.ref_val%TYPE DEFAULT NULL,
        i_ref_val_min            IN analysis_result_par.ref_val_min_str%TYPE,
        i_ref_val_max            IN analysis_result_par.ref_val_max_str%TYPE,
        i_parameter_notes        IN analysis_result_par.parameter_notes%TYPE,
        i_interface_notes        IN analysis_result_par.interface_notes%TYPE DEFAULT NULL,
        i_laboratory             IN analysis_result_par.id_laboratory%TYPE DEFAULT NULL,
        i_laboratory_desc        IN analysis_result_par.laboratory_desc%TYPE DEFAULT NULL,
        i_laboratory_short_desc  IN analysis_result_par.laboratory_short_desc%TYPE DEFAULT NULL,
        i_coding_system          IN analysis_result_par.coding_system%TYPE DEFAULT NULL,
        i_method                 IN analysis_result_par.method%TYPE DEFAULT NULL,
        i_equipment              IN analysis_result_par.equipment%TYPE DEFAULT NULL,
        i_abnormality            IN analysis_result_par.id_abnormality%TYPE DEFAULT NULL,
        i_abnormality_nature     IN analysis_result_par.id_abnormality_nature%TYPE DEFAULT NULL,
        i_prof_validation        IN analysis_result_par.id_prof_validation%TYPE DEFAULT NULL,
        i_dt_validation          IN VARCHAR2 DEFAULT NULL,
        i_clinical_decision_rule IN analysis_result_par.id_cdr%TYPE,
        o_result                 OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_result analysis_result.id_analysis_result%TYPE;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.UPDATE_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_core.update_lab_test_result(i_lang                   => i_lang,
                                                        i_prof                   => i_prof,
                                                        i_episode                => i_episode,
                                                        i_analysis_result_par    => i_analysis_result_par,
                                                        i_dt_sample              => i_dt_sample,
                                                        i_prof_req               => i_prof_req,
                                                        i_dt_analysis_result     => i_dt_analysis_result,
                                                        i_flg_result_origin      => i_flg_result_origin,
                                                        i_result_origin_notes    => i_result_origin_notes,
                                                        i_result_notes           => i_result_notes,
                                                        i_dt_ext_registry        => i_dt_ext_registry,
                                                        i_instit_origin          => i_instit_origin,
                                                        i_result_value_1         => i_result_value_1,
                                                        i_result_value_2         => i_result_value_2,
                                                        i_analysis_desc          => i_analysis_desc,
                                                        i_comparator             => i_comparator,
                                                        i_separator              => i_separator,
                                                        i_standard_code          => i_standard_code,
                                                        i_unit_measure           => i_unit_measure,
                                                        i_desc_unit_measure      => i_desc_unit_measure,
                                                        i_result_status          => i_result_status,
                                                        i_ref_val                => i_ref_val,
                                                        i_ref_val_min            => i_ref_val_min,
                                                        i_ref_val_max            => i_ref_val_max,
                                                        i_parameter_notes        => i_parameter_notes,
                                                        i_interface_notes        => i_interface_notes,
                                                        i_laboratory             => i_laboratory,
                                                        i_laboratory_desc        => i_laboratory_desc,
                                                        i_laboratory_short_desc  => i_laboratory_short_desc,
                                                        i_coding_system          => i_coding_system,
                                                        i_method                 => i_method,
                                                        i_equipment              => i_equipment,
                                                        i_abnormality            => i_abnormality,
                                                        i_abnormality_nature     => i_abnormality_nature,
                                                        i_prof_validation        => i_prof_validation,
                                                        i_dt_validation          => i_dt_validation,
                                                        i_clinical_decision_rule => i_clinical_decision_rule,
                                                        o_result                 => o_result,
                                                        o_id_result              => l_id_result,
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
                                              'UPDATE_LAB_TEST_RESULT',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_result;

    FUNCTION update_lab_test_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_begin         IN table_varchar,
        i_notes_scheduler  IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.UPDATE_LAB_TEST_DATE';
        IF NOT pk_lab_tests_core.update_lab_test_date(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_analysis_req_det => i_analysis_req_det,
                                                      i_dt_begin         => i_dt_begin,
                                                      i_notes_scheduler  => i_notes_scheduler,
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
                                              'UPDATE_LAB_TEST_DATE',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_date;

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
            RETURN FALSE;
    END cancel_lab_test_order;

    FUNCTION cancel_lab_test_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
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
                                                         i_dt_cancel        => i_dt_cancel,
                                                         i_cancel_reason    => i_cancel_reason,
                                                         i_cancel_notes     => i_cancel_notes,
                                                         i_prof_order       => i_prof_order,
                                                         i_dt_order         => i_dt_order,
                                                         i_order_type       => i_order_type,
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
                                              'CANCEL_LAB_TEST_REQUEST',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_request;

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
            RETURN FALSE;
    END cancel_lab_test_result;

    FUNCTION cancel_lab_test_schedule
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_lab_tests_core.cancel_lab_test_schedule(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_analysis_req => i_analysis_req,
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
                                              'CANCEL_LAB_TEST_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_schedule;

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE, --1
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE, --5
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.CANCEL_HARVEST';
        IF NOT pk_lab_tests_harvest_core.cancel_harvest(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_patient       => i_patient,
                                                        i_episode       => i_episode,
                                                        i_harvest       => i_harvest,
                                                        i_cancel_reason => i_cancel_reason,
                                                        i_cancel_notes  => i_cancel_notes,
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
                                              'CANCEL_HARVEST',
                                              o_error);
            RETURN FALSE;
    END cancel_harvest;

    FUNCTION get_lab_test_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2 DEFAULT 'M',
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE DEFAULT NULL,
        i_harvest      IN harvest.id_harvest%TYPE DEFAULT NULL
    ) RETURN t_tbl_lab_tests_for_selection IS
    
    BEGIN
    
        RETURN pk_lab_tests_core.get_lab_test_selection_list(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_patient      => i_patient,
                                                             i_episode      => i_episode,
                                                             i_flg_type     => i_flg_type,
                                                             i_codification => i_codification,
                                                             i_analysis_req => i_analysis_req,
                                                             i_harvest      => i_harvest);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_lab_test_selection_list;

    FUNCTION get_lab_test_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_analysis_req IN analysis_req.id_analysis_req%TYPE DEFAULT NULL,
        i_harvest      IN harvest.id_harvest%TYPE DEFAULT NULL,
        i_value        IN VARCHAR2
    ) RETURN t_table_lab_tests_search IS
    
    BEGIN
    
        RETURN pk_lab_tests_core.get_lab_test_search(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => i_patient,
                                                     i_codification => i_codification,
                                                     i_analysis_req => i_analysis_req,
                                                     i_harvest      => i_harvest,
                                                     i_value        => i_value);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_lab_test_search;

    FUNCTION get_lab_test_group_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_GROUP_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_group_search(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_analysis_req => NULL,
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
                                              'GET_LAB_TEST_GROUP_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_group_search;

    FUNCTION get_lab_test_sample_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_codification IN codification.id_codification%TYPE,
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
                                                            i_analysis_req => NULL,
                                                            i_harvest      => NULL,
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
        o_list            OUT t_tbl_lab_tests_cat_search,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_CATEGORY_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_category_search(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_sample_type     => i_sample_type,
                                                              i_exam_cat_parent => i_exam_cat_parent,
                                                              i_codification    => i_codification,
                                                              i_analysis_req    => NULL,
                                                              i_harvest         => NULL,
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
            RETURN FALSE;
    END get_lab_test_category_search;

    FUNCTION get_lab_test_category_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        o_list            OUT pk_types.cursor_type, --t_tbl_lab_tests_cat_search,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_CATEGORY_SEARCH';
        IF NOT pk_lab_tests_core.get_lab_test_category_search(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_sample_type     => i_sample_type,
                                                              i_exam_cat_parent => i_exam_cat_parent,
                                                              i_codification    => i_codification,
                                                              i_analysis_req    => NULL,
                                                              i_harvest         => NULL,
                                                              o_list            => l_list,
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
            RETURN FALSE;
    END get_lab_test_category_search;

    FUNCTION get_lab_test_for_selection
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        o_list            OUT t_tbl_lab_tests_for_selection,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_FOR_SELECTION';
        IF NOT pk_lab_tests_core.get_lab_test_for_selection(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_patient         => i_patient,
                                                            i_sample_type     => i_sample_type,
                                                            i_exam_cat        => i_exam_cat,
                                                            i_exam_cat_parent => i_exam_cat_parent,
                                                            i_codification    => i_codification,
                                                            i_analysis_req    => NULL,
                                                            i_harvest         => NULL,
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
                                              'GET_LAB_TEST_FOR_SELECTION',
                                              o_error);
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
            RETURN FALSE;
    END get_lab_test_in_group;

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
    
        g_error := 'CALL PK_LAB_TESTS_CORE.';
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
            pk_types.open_my_cursor(o_lab_test_order_barcode);
            pk_types.open_my_cursor(o_lab_test_order_history);
            RETURN FALSE;
    END get_lab_test_order_detail;

    FUNCTION get_lab_test_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lab_test_order              t_tbl_lab_tests_detail;
        l_lab_test_clinical_questions t_tbl_lab_tests_cq;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_core.get_lab_test_detail(i_lang                        => i_lang,
                                                     i_prof                        => i_prof,
                                                     i_episode                     => i_episode,
                                                     i_analysis_req_det            => i_analysis_req_det,
                                                     i_flg_report                  => i_flg_report,
                                                     o_lab_test_order              => l_lab_test_order,
                                                     o_lab_test_co_sign            => o_lab_test_co_sign,
                                                     o_lab_test_clinical_questions => l_lab_test_clinical_questions,
                                                     o_lab_test_harvest            => o_lab_test_harvest,
                                                     o_lab_test_result             => o_lab_test_result,
                                                     o_lab_test_doc                => o_lab_test_doc,
                                                     o_lab_test_review             => o_lab_test_review,
                                                     o_error                       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_LAB_TEST_ORDER';
        OPEN o_lab_test_order FOR
            SELECT id_analysis_req_det,
                   registry,
                   desc_analysis,
                   num_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(clinical_indication,
                                                                        diagnosis_notes,
                                                                        desc_diagnosis,
                                                                        clinical_purpose),
                                                          'T') clinical_indication,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(instructions,
                                                                        priority,
                                                                        desc_status,
                                                                        title_order_set,
                                                                        task_depend,
                                                                        desc_time,
                                                                        desc_time_limit,
                                                                        order_recurrence,
                                                                        prn,
                                                                        notes_prn),
                                                          'T') instructions,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang,
                                                               i_prof,
                                                               table_clob(patient_instructions, fasting, notes_patient),
                                                               'T') patient_instructions,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(fasting), 'F') fasting,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang, i_prof, table_clob(notes_patient), 'F') notes_patient,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(collection, collection_location, notes_scheduler),
                                                          'T') collection,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(collection_location), 'F') collection_location,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes_scheduler), 'F') notes_scheduler,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(execution,
                                                                        perform_location,
                                                                        notes_technician,
                                                                        notes),
                                                          'T') execution,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes_technician), 'F') notes_technician,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(results, prof_cc, prof_bcc),
                                                          'T') results,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_cc), 'F') prof_cc,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_bcc), 'F') prof_bcc,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(co_sign, order_type, prof_order, dt_order),
                                                          'T') co_sign,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(health_insurance,
                                                                        financial_entity,
                                                                        health_plan,
                                                                        insurance_number,
                                                                        exemption),
                                                          'T') health_insurance,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(cancellation,
                                                                        cancel_reason,
                                                                        cancel_notes,
                                                                        cancel_order_type,
                                                                        cancel_prof_order,
                                                                        cancel_dt_order),
                                                          'T') cancellation,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                   dt_ord
              FROM (SELECT t.id_analysis_req_det  id_analysis_req_det,
                           t.registry             registry,
                           t.desc_analysis        desc_analysis,
                           t.num_order            num_order,
                           t.clinical_indication  clinical_indication,
                           t.diagnosis_notes      diagnosis_notes,
                           t.desc_diagnosis       desc_diagnosis,
                           t.clinical_purpose     clinical_purpose,
                           t.instructions         instructions,
                           t.priority             priority,
                           t.desc_status          desc_status,
                           t.title_order_set      title_order_set,
                           t.task_depend          task_depend,
                           t.desc_time            desc_time,
                           t.desc_time_limit      desc_time_limit,
                           t.order_recurrence     order_recurrence,
                           t.prn                  prn,
                           t.notes_prn            notes_prn,
                           t.patient_instructions patient_instructions,
                           t.fasting              fasting,
                           t.notes_patient        notes_patient,
                           t.collection           collection,
                           t.collection_location  collection_location,
                           t.notes_scheduler      notes_scheduler,
                           t.execution            execution,
                           t.perform_location     perform_location,
                           t.notes_technician     notes_technician,
                           t.notes                notes,
                           t.results              results,
                           t.prof_cc              prof_cc,
                           t.prof_bcc             prof_bcc,
                           t.co_sign              co_sign,
                           t.order_type           order_type,
                           t.prof_order           prof_order,
                           t.dt_order             dt_order,
                           t.health_insurance     health_insurance,
                           t.financial_entity     financial_entity,
                           t.health_plan          health_plan,
                           t.insurance_number     insurance_number,
                           t.exemption            exemption,
                           t.cancellation         cancellation,
                           t.cancel_reason        cancel_reason,
                           t.cancel_notes         cancel_notes,
                           t.cancel_order_type    cancel_order_type,
                           t.cancel_prof_order    cancel_prof_order,
                           t.cancel_dt_order      cancel_dt_order,
                           t.dt_ord               dt_ord
                      FROM TABLE(l_lab_test_order) t);
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT t.id_analysis_req_det    id_analysis_req_det,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question
              FROM TABLE(l_lab_test_clinical_questions) t;
    
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
            RETURN FALSE;
    END get_lab_test_detail;

    FUNCTION get_lab_test_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report                  IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lab_test_order              t_tbl_lab_tests_detail;
        l_lab_test_clinical_questions t_tbl_lab_tests_cq;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_core.get_lab_test_detail_history(i_lang                        => i_lang,
                                                             i_prof                        => i_prof,
                                                             i_episode                     => i_episode,
                                                             i_analysis_req_det            => i_analysis_req_det,
                                                             i_flg_report                  => i_flg_report,
                                                             o_lab_test_order              => l_lab_test_order,
                                                             o_lab_test_co_sign            => o_lab_test_co_sign,
                                                             o_lab_test_clinical_questions => l_lab_test_clinical_questions,
                                                             o_lab_test_harvest            => o_lab_test_harvest,
                                                             o_lab_test_result             => o_lab_test_result,
                                                             o_lab_test_doc                => o_lab_test_doc,
                                                             o_lab_test_review             => o_lab_test_review,
                                                             o_error                       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_LAB_TEST_ORDER';
        OPEN o_lab_test_order FOR
            SELECT id_analysis_req_det,
                   registry,
                   desc_analysis,
                   num_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(clinical_indication,
                                                                        diagnosis_notes,
                                                                        desc_diagnosis,
                                                                        clinical_purpose),
                                                          'T') clinical_indication,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(instructions,
                                                                        priority,
                                                                        desc_status,
                                                                        title_order_set,
                                                                        task_depend,
                                                                        desc_time,
                                                                        desc_time_limit,
                                                                        order_recurrence,
                                                                        prn,
                                                                        notes_prn),
                                                          'T') instructions,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang,
                                                               i_prof,
                                                               table_clob(patient_instructions, fasting, notes_patient),
                                                               'T') patient_instructions,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(fasting), 'F') fasting,
                   pk_lab_tests_utils.get_lab_test_detail_clob(i_lang, i_prof, table_clob(notes_patient), 'F') notes_patient,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(collection, collection_location, notes_scheduler),
                                                          'T') collection,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(collection_location), 'F') collection_location,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes_scheduler), 'F') notes_scheduler,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(execution,
                                                                        perform_location,
                                                                        notes_technician,
                                                                        notes),
                                                          'T') execution,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes_technician), 'F') notes_technician,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(results, prof_cc, prof_bcc),
                                                          'T') results,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_cc), 'F') prof_cc,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_bcc), 'F') prof_bcc,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(co_sign, order_type, prof_order, dt_order),
                                                          'T') co_sign,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(health_insurance,
                                                                        financial_entity,
                                                                        health_plan,
                                                                        insurance_number,
                                                                        exemption),
                                                          'T') health_insurance,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang,
                                                          i_prof,
                                                          table_varchar(cancellation,
                                                                        cancel_reason,
                                                                        cancel_notes,
                                                                        cancel_order_type,
                                                                        cancel_prof_order,
                                                                        cancel_dt_order),
                                                          'T') cancellation,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                   pk_lab_tests_utils.get_lab_test_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                   dt_ord,
                   dt_last_update
              FROM (SELECT t.id_analysis_req_det  id_analysis_req_det,
                           t.registry             registry,
                           t.desc_analysis        desc_analysis,
                           t.num_order            num_order,
                           t.clinical_indication  clinical_indication,
                           t.diagnosis_notes      diagnosis_notes,
                           t.desc_diagnosis       desc_diagnosis,
                           t.clinical_purpose     clinical_purpose,
                           t.instructions         instructions,
                           t.priority             priority,
                           t.desc_status          desc_status,
                           t.title_order_set      title_order_set,
                           t.task_depend          task_depend,
                           t.desc_time            desc_time,
                           t.desc_time_limit      desc_time_limit,
                           t.order_recurrence     order_recurrence,
                           t.prn                  prn,
                           t.notes_prn            notes_prn,
                           t.patient_instructions patient_instructions,
                           t.fasting              fasting,
                           t.notes_patient        notes_patient,
                           t.collection           collection,
                           t.collection_location  collection_location,
                           t.notes_scheduler      notes_scheduler,
                           t.execution            execution,
                           t.perform_location     perform_location,
                           t.notes_technician     notes_technician,
                           t.notes                notes,
                           t.results              results,
                           t.prof_cc              prof_cc,
                           t.prof_bcc             prof_bcc,
                           t.co_sign              co_sign,
                           t.order_type           order_type,
                           t.prof_order           prof_order,
                           t.dt_order             dt_order,
                           t.health_insurance     health_insurance,
                           t.financial_entity     financial_entity,
                           t.health_plan          health_plan,
                           t.insurance_number     insurance_number,
                           t.exemption            exemption,
                           t.cancellation         cancellation,
                           t.cancel_reason        cancel_reason,
                           t.cancel_notes         cancel_notes,
                           t.cancel_order_type    cancel_order_type,
                           t.cancel_prof_order    cancel_prof_order,
                           t.cancel_dt_order      cancel_dt_order,
                           t.dt_ord               dt_ord,
                           t.dt_last_update
                      FROM TABLE(l_lab_test_order) t);
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT t.id_analysis_req_det    id_analysis_req_det,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question,
                   t.dt_last_update,
                   t.num_clinical_question,
                   t.rn
              FROM TABLE(l_lab_test_clinical_questions) t;
    
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
            RETURN FALSE;
    END get_lab_test_detail_history;

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
            RETURN FALSE;
    END get_lab_test_result;

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        i_flg_report               IN VARCHAR2 DEFAULT 'N',
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.GET_HARVEST_MOVEMENT_DETAIL';
        IF NOT pk_lab_tests_harvest_core.get_harvest_movement_detail(i_lang                     => i_lang,
                                                                     i_prof                     => i_prof,
                                                                     i_harvest                  => i_harvest,
                                                                     i_flg_report               => i_flg_report,
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
            RETURN FALSE;
    END get_harvest_movement_detail;

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
            RETURN FALSE;
    END get_lab_test_time_list;

    FUNCTION get_lab_test_location_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_analysis    IN table_number,
        i_sample_type IN table_number,
        i_flg_type    IN analysis_room.flg_type%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_ROOM_INSTIT';
        IF NOT pk_lab_tests_core.get_lab_test_location_list(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_analysis    => i_analysis,
                                                            i_sample_type => i_sample_type,
                                                            i_flg_type    => i_flg_type,
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
            RETURN FALSE;
    END get_lab_test_location_list;

    FUNCTION get_alias_translation
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_flg_type                  IN VARCHAR2 DEFAULT 'A',
        i_analysis_code_translation IN translation.code_translation%TYPE,
        i_sample_code_translation   IN translation.code_translation%TYPE,
        i_dep_clin_serv             IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_ALIAS_TRANSLATION';
        RETURN pk_lab_tests_utils.get_alias_translation(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_flg_type                  => i_flg_type,
                                                        i_analysis_code_translation => i_analysis_code_translation,
                                                        i_sample_code_translation   => i_sample_code_translation,
                                                        i_dep_clin_serv             => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_alias_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2 DEFAULT 'A',
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_ALIAS_TRANSLATION';
        RETURN pk_lab_tests_utils.get_alias_translation(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_flg_type         => i_flg_type,
                                                        i_code_translation => i_code_translation,
                                                        i_dep_clin_serv    => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_lab_test_unit_measure
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis           IN analysis.id_analysis%TYPE,
        i_sample_type        IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_LAB_TEST_UNIT_MEASURE';
        RETURN pk_lab_tests_utils.get_lab_test_unit_measure(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_analysis           => i_analysis,
                                                            i_sample_type        => i_sample_type,
                                                            i_analysis_parameter => i_analysis_parameter);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_unit_measure;

    FUNCTION get_lab_test_access_permission
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN analysis.id_analysis%TYPE,
        i_flg_type IN group_access.flg_type%TYPE DEFAULT pk_lab_tests_constant.g_infectious_diseases_orders
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_LAB_TEST_ACCESS_PERMISSION';
        RETURN pk_lab_tests_utils.get_lab_test_access_permission(i_lang     => i_lang,
                                                                 i_prof     => i_prof,
                                                                 i_analysis => i_analysis,
                                                                 i_flg_type => i_flg_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_access_permission;

    FUNCTION get_lab_test_result_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_LAB_TEST_RESULT_PARAMETERS';
        RETURN pk_lab_tests_utils.get_lab_test_result_parameters(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_analysis_req_det => i_analysis_req_det);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result_parameters;

    FUNCTION get_pat_blood_type_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_result analysis_result.id_analysis_result%TYPE;
    
    BEGIN
        SELECT pbg.id_analysis_result
          INTO l_analysis_result
          FROM pat_blood_group pbg
         WHERE pbg.id_pat_blood_group = i_pat_blood_group;
    
        IF NOT pk_lab_tests_core.get_lab_test_result_detail(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_analysis_result => l_analysis_result,
                                                            o_detail          => o_detail,
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
                                              'GET_PAT_BLOOD_TYPE_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_pat_blood_type_detail;

    FUNCTION get_pat_blood_type_det_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_result analysis_result.id_analysis_result%TYPE;
    
    BEGIN
        SELECT pbg.id_analysis_result
          INTO l_analysis_result
          FROM pat_blood_group pbg
         WHERE pbg.id_pat_blood_group = i_pat_blood_group;
    
        IF NOT pk_lab_tests_core.get_lab_test_result_det_hist(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_analysis_result => l_analysis_result,
                                                              o_detail          => o_detail,
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
                                              'GET_LAB_TEST_RESULT_DET_HIST',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_pat_blood_type_det_hist;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_api_db;
/
