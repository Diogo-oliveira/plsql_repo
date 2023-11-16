/*-- Last Change Revision: $Rev: 2045843 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-09-22 10:24:49 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_procedures_api_ux IS

    FUNCTION create_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_episode_destination     IN table_number,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar, --10
        i_diagnosis               IN table_clob,
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar, --15
        i_flg_prn                 IN table_varchar,
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number, --20
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number,
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar, --25
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number, --30
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN table_number, --35
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_day_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_ORDER';
        IF NOT pk_procedures_core.create_procedure_order(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_patient                 => i_patient,
                                                         i_episode                 => i_episode,
                                                         i_intervention            => i_intervention,
                                                         i_flg_time                => i_flg_time,
                                                         i_dt_begin                => i_dt_begin,
                                                         i_episode_destination     => i_episode_destination,
                                                         i_order_recurrence        => i_order_recurrence,
                                                         i_diagnosis_notes         => i_diagnosis_notes,
                                                         i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                                i_prof   => i_prof,
                                                                                                                i_params => i_diagnosis),
                                                         i_clinical_purpose        => i_clinical_purpose,
                                                         i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                         i_laterality              => i_laterality,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_exec_institution        => i_exec_institution,
                                                         i_flg_location            => i_flg_location,
                                                         i_supply                  => i_supply,
                                                         i_supply_set              => i_supply_set,
                                                         i_supply_qty              => i_supply_qty,
                                                         i_dt_return               => i_dt_return,
                                                         i_supply_loc              => NULL,
                                                         i_not_order_reason        => i_not_order_reason,
                                                         i_notes                   => i_notes,
                                                         i_prof_order              => i_prof_order,
                                                         i_dt_order                => i_dt_order,
                                                         i_order_type              => i_order_type,
                                                         i_codification            => i_codification,
                                                         i_health_plan             => i_health_plan,
                                                         i_exemption               => i_exemption,
                                                         i_clinical_question       => i_clinical_question,
                                                         i_response                => i_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         i_clinical_decision_rule  => i_clinical_decision_rule,
                                                         i_flg_origin_req          => i_flg_origin_req,
                                                         i_test                    => i_test,
                                                         o_flg_show                => o_flg_show,
                                                         o_msg_title               => o_msg_title,
                                                         o_msg_req                 => o_msg_req,
                                                         o_interv_presc_array      => o_interv_presc_array,
                                                         o_interv_presc_det_array  => o_interv_presc_det_array,
                                                         o_error                   => o_error)
        THEN
            IF o_error.ora_sqlcode = 'INTERV_M010'
            THEN
                RAISE l_next_day_exception;
            ELSIF o_error.ora_sqlcode = 'INTERV_M006'
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF o_flg_show = pk_procedures_constant.g_yes
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
        WHEN l_next_day_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                     i_sqlcode     => NULL,
                                                     i_sqlerrm     => pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'INTERV_M010'),
                                                     i_message     => g_error,
                                                     i_owner       => g_package_owner,
                                                     i_package     => g_package_name,
                                                     i_function    => NULL,
                                                     i_action_type => 'U',
                                                     i_action_msg  => NULL,
                                                     i_msg_title   => pk_message.get_message(i_lang, 'COMMON_T006'),
                                                     i_msg_type    => NULL,
                                                     o_error       => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROCEDURE_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_procedure_order;

    FUNCTION create_procedure_order
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_root_name              IN VARCHAR2,
        i_tbl_id_pk              IN table_number,
        i_tbl_data               IN table_table_varchar,
        i_tbl_ds_internal_name   IN table_varchar,
        i_tbl_real_val           IN table_table_varchar,
        i_tbl_val_clob           IN table_table_clob,
        i_tbl_val_array          IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc     IN tt_table_varchar DEFAULT NULL,
        i_clinical_question_pk   IN table_number,
        i_clinical_question      IN table_varchar,
        i_response               IN table_table_varchar,
        i_test                   IN VARCHAR2,
        i_flg_update             IN VARCHAR2,
        i_flg_origin_req         IN VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_msg_req                OUT VARCHAR2,
        o_interv_presc_array     OUT NOCOPY table_number,
        o_interv_presc_det_array OUT NOCOPY table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next_day_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_ORDER';
        IF NOT pk_procedures_core.create_procedure_order(i_lang                   => i_lang,
                                                         i_prof                   => i_prof,
                                                         i_episode                => i_episode,
                                                         i_patient                => i_patient,
                                                         i_root_name              => i_root_name,
                                                         i_tbl_id_pk              => i_tbl_id_pk,
                                                         i_tbl_data               => i_tbl_data,
                                                         i_tbl_ds_internal_name   => i_tbl_ds_internal_name,
                                                         i_tbl_real_val           => i_tbl_real_val,
                                                         i_tbl_val_clob           => i_tbl_val_clob,
                                                         i_tbl_val_array          => i_tbl_val_array,
                                                         i_tbl_val_array_desc     => i_tbl_val_array_desc,
                                                         i_clinical_question_pk   => i_clinical_question_pk,
                                                         i_clinical_question      => i_clinical_question,
                                                         i_response               => i_response,
                                                         i_test                   => i_test,
                                                         i_flg_update             => i_flg_update,
                                                         i_flg_origin_req         => i_flg_origin_req,
                                                         o_flg_show               => o_flg_show,
                                                         o_msg_title              => o_msg_title,
                                                         o_msg_req                => o_msg_req,
                                                         o_interv_presc_array     => o_interv_presc_array,
                                                         o_interv_presc_det_array => o_interv_presc_det_array,
                                                         o_error                  => o_error)
        THEN
            IF o_error.ora_sqlcode = 'INTERV_M010'
            THEN
                RAISE l_next_day_exception;
            ELSIF o_error.ora_sqlcode = 'INTERV_M006'
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            ELSIF o_flg_show = pk_procedures_constant.g_yes
            THEN
                pk_utils.undo_changes;
                RETURN TRUE;
            ELSE
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_next_day_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                     i_sqlcode     => NULL,
                                                     i_sqlerrm     => pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'INTERV_M010'),
                                                     i_message     => g_error,
                                                     i_owner       => g_package_owner,
                                                     i_package     => g_package_name,
                                                     i_function    => NULL,
                                                     i_action_type => 'U',
                                                     i_action_msg  => NULL,
                                                     i_msg_title   => pk_message.get_message(i_lang, 'COMMON_T006'),
                                                     i_msg_type    => NULL,
                                                     o_error       => o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROCEDURE_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_procedure_order;

    FUNCTION create_procedure_for_execution
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_intervention            IN table_number,
        i_prof_performed          IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time              IN VARCHAR2,
        i_end_time                IN VARCHAR2,
        i_dt_next                 IN VARCHAR2,
        i_modifiers               IN table_varchar,
        i_supply_workflow         IN table_number,
        i_supply                  IN table_number,
        i_supply_set              IN table_number,
        i_supply_qty              IN table_number,
        i_supply_type             IN table_varchar,
        i_barcode_scanned         IN table_varchar,
        i_deliver_needed          IN table_varchar,
        i_flg_cons_type           IN table_varchar,
        i_flg_supplies_reg        IN VARCHAR2,
        i_dt_expiration           IN table_varchar,
        i_flg_validation          IN table_varchar,
        i_lot                     IN table_varchar,
        i_notes                   IN epis_interv.notes%TYPE,
        i_doc_template            IN doc_template.id_doc_template%TYPE,
        i_flg_type                IN doc_template_context.flg_type%TYPE,
        i_id_documentation        IN table_number,
        i_id_doc_element          IN table_number,
        i_id_doc_element_crit     IN table_number,
        i_value                   IN table_varchar,
        i_id_doc_element_qualif   IN table_table_number,
        i_vs_element_list         IN table_number,
        i_vs_save_mode_list       IN table_varchar,
        i_vs_list                 IN table_number,
        i_vs_value_list           IN table_number,
        i_vs_uom_list             IN table_number,
        i_vs_scales_list          IN table_number,
        i_vs_date_list            IN table_varchar,
        i_vs_read_list            IN table_number,
        i_clinical_decision_rule  IN cdr_call.id_cdr_call%TYPE,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_interv_presc_det        OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_FOR_EXECUTION';
        IF NOT pk_procedures_core.create_procedure_for_execution(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_patient                 => i_patient,
                                                                 i_episode                 => i_episode,
                                                                 i_intervention            => i_intervention,
                                                                 i_prof_performed          => i_prof_performed,
                                                                 i_start_time              => i_start_time,
                                                                 i_end_time                => i_end_time,
                                                                 i_dt_next                 => i_dt_next,
                                                                 i_modifiers               => i_modifiers,
                                                                 i_supply_workflow         => i_supply_workflow,
                                                                 i_supply                  => i_supply,
                                                                 i_supply_set              => i_supply_set,
                                                                 i_supply_qty              => i_supply_qty,
                                                                 i_supply_type             => i_supply_type,
                                                                 i_barcode_scanned         => i_barcode_scanned,
                                                                 i_deliver_needed          => i_deliver_needed,
                                                                 i_flg_cons_type           => i_flg_cons_type,
                                                                 i_flg_supplies_reg        => i_flg_supplies_reg,
                                                                 i_dt_expiration           => i_dt_expiration,
                                                                 i_flg_validation          => i_flg_validation,
                                                                 i_lot                     => i_lot,
                                                                 i_notes                   => i_notes,
                                                                 i_doc_template            => i_doc_template,
                                                                 i_flg_type                => i_flg_type,
                                                                 i_id_documentation        => i_id_documentation,
                                                                 i_id_doc_element          => i_id_doc_element,
                                                                 i_id_doc_element_crit     => i_id_doc_element_crit,
                                                                 i_value                   => i_value,
                                                                 i_id_doc_element_qualif   => i_id_doc_element_qualif,
                                                                 i_vs_element_list         => i_vs_element_list,
                                                                 i_vs_save_mode_list       => i_vs_save_mode_list,
                                                                 i_vs_list                 => i_vs_list,
                                                                 i_vs_value_list           => i_vs_value_list,
                                                                 i_vs_uom_list             => i_vs_uom_list,
                                                                 i_vs_scales_list          => i_vs_scales_list,
                                                                 i_vs_date_list            => i_vs_date_list,
                                                                 i_vs_read_list            => i_vs_read_list,
                                                                 i_clinical_decision_rule  => i_clinical_decision_rule,
                                                                 i_clinical_question       => i_clinical_question,
                                                                 i_response                => i_response,
                                                                 i_clinical_question_notes => i_clinical_question_notes,
                                                                 o_interv_presc_det        => o_interv_presc_det,
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
                                              'CREATE_PROCEDURE_FOR_EXECUTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_procedure_for_execution;

    FUNCTION create_procedure_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_schedule         IN schedule_intervention.id_schedule%TYPE,
        i_interv_presc_det IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CREATE_PROCEDURE_VISIT';
        IF NOT pk_procedures_core.create_procedure_visit(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_patient          => i_patient,
                                                         i_episode          => i_episode,
                                                         i_schedule         => i_schedule,
                                                         i_interv_presc_det => i_interv_presc_det,
                                                         o_error            => o_error)
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
                                              'CREATE_PROCEDURE_VISIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_procedure_visit;

    FUNCTION set_procedure_time_out
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_interv_presc_det      IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan     IN interv_presc_plan.id_interv_presc_plan%TYPE,
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
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_test              IN VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT sys_message.desc_message%TYPE,
        o_msg_body              OUT pk_types.cursor_type,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.SET_PROCEDURE_TIME_OUT';
        IF NOT pk_procedures_core.set_procedure_time_out(i_lang                  => i_lang,
                                                         i_prof                  => i_prof,
                                                         i_interv_presc_det      => i_interv_presc_det,
                                                         i_interv_presc_plan     => i_interv_presc_plan,
                                                         i_episode               => i_episode,
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
                                              'SET_PROCEDURE_TIME_OUT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_procedure_time_out;

    FUNCTION set_procedure_execution
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_presc_det        IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan       IN interv_presc_plan.id_interv_presc_plan%TYPE, --5
        i_prof_performed          IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time              IN VARCHAR2,
        i_end_time                IN VARCHAR2,
        i_dt_next                 IN VARCHAR2,
        i_flg_next_change         IN VARCHAR2, --10
        i_modifiers               IN table_varchar,
        i_supply_workflow         IN table_number,
        i_supply                  IN table_number,
        i_supply_set              IN table_number,
        i_supply_qty              IN table_number, --15
        i_supply_type             IN table_varchar,
        i_barcode_scanned         IN table_varchar,
        i_deliver_needed          IN table_varchar,
        i_flg_cons_type           IN table_varchar,
        i_flg_supplies_reg        IN VARCHAR2, --20
        i_dt_expiration           IN table_varchar,
        i_flg_validation          IN table_varchar,
        i_lot                     IN table_varchar,
        i_notes                   IN epis_interv.notes%TYPE,
        i_doc_template            IN doc_template.id_doc_template%TYPE, --25
        i_flg_type                IN doc_template_context.flg_type%TYPE,
        i_id_documentation        IN table_number,
        i_id_doc_element          IN table_number,
        i_id_doc_element_crit     IN table_number,
        i_value                   IN table_varchar, --30
        i_id_doc_element_qualif   IN table_table_number,
        i_vs_element_list         IN table_number,
        i_vs_save_mode_list       IN table_varchar,
        i_vs_list                 IN table_number,
        i_vs_value_list           IN table_number, --35
        i_vs_uom_list             IN table_number,
        i_vs_scales_list          IN table_number,
        i_vs_date_list            IN table_varchar,
        i_vs_read_list            IN table_number,
        i_clinical_decision_rule  IN cdr_call.id_cdr_call%TYPE, --40
        i_clinical_question       IN table_number,
        i_response                IN table_varchar,
        i_clinical_question_notes IN table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.SET_PROCEDURE_EXECUTION';
        IF NOT pk_procedures_core.set_procedure_execution(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_episode                 => i_episode,
                                                          i_interv_presc_det        => i_interv_presc_det,
                                                          i_interv_presc_plan       => i_interv_presc_plan,
                                                          i_prof_performed          => i_prof_performed,
                                                          i_start_time              => i_start_time,
                                                          i_end_time                => i_end_time,
                                                          i_dt_next                 => i_dt_next,
                                                          i_flg_next_change         => i_flg_next_change,
                                                          i_modifiers               => i_modifiers,
                                                          i_supply_workflow         => i_supply_workflow,
                                                          i_supply                  => i_supply,
                                                          i_supply_set              => i_supply_set,
                                                          i_supply_qty              => i_supply_qty,
                                                          i_supply_type             => i_supply_type,
                                                          i_barcode_scanned         => i_barcode_scanned,
                                                          i_deliver_needed          => i_deliver_needed,
                                                          i_flg_cons_type           => i_flg_cons_type,
                                                          i_flg_supplies_reg        => i_flg_supplies_reg,
                                                          i_dt_expiration           => i_dt_expiration,
                                                          i_flg_validation          => i_flg_validation,
                                                          i_lot                     => i_lot,
                                                          i_notes                   => i_notes,
                                                          i_doc_template            => i_doc_template,
                                                          i_flg_type                => i_flg_type,
                                                          i_id_documentation        => i_id_documentation,
                                                          i_id_doc_element          => i_id_doc_element,
                                                          i_id_doc_element_crit     => i_id_doc_element_crit,
                                                          i_value                   => i_value,
                                                          i_id_doc_element_qualif   => i_id_doc_element_qualif,
                                                          i_vs_element_list         => i_vs_element_list,
                                                          i_vs_save_mode_list       => i_vs_save_mode_list,
                                                          i_vs_list                 => i_vs_list,
                                                          i_vs_value_list           => i_vs_value_list,
                                                          i_vs_uom_list             => i_vs_uom_list,
                                                          i_vs_scales_list          => i_vs_scales_list,
                                                          i_vs_date_list            => i_vs_date_list,
                                                          i_vs_read_list            => i_vs_read_list,
                                                          i_clinical_decision_rule  => i_clinical_decision_rule,
                                                          i_clinical_question       => i_clinical_question,
                                                          i_response                => i_response,
                                                          i_clinical_question_notes => i_clinical_question_notes,
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
                                              'SET_PROCEDURE_EXECUTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_procedure_execution;

    FUNCTION set_procedure_doc_associated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_interv_presc_det     IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan    IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_flg_import           IN table_varchar,
        i_id_doc               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_PROCEDURE_DOC_ASSOCIATED';
        IF NOT pk_procedures_core.set_procedure_doc_associated(i_lang                 => i_lang,
                                                               i_prof                 => i_prof,
                                                               i_patient              => i_patient,
                                                               i_episode              => i_episode,
                                                               i_interv_presc_det     => i_interv_presc_det,
                                                               i_interv_presc_plan    => i_interv_presc_plan,
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
                                              'SET_PROCEDURE_DOC_ASSOCIATED',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_procedure_doc_associated;

    FUNCTION set_interv_favorite
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_intervention IN intervention.id_intervention%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL SET_INTERV_FAVORITE';
        IF NOT pk_procedures_utils.set_interv_favorite(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_intervention => i_id_intervention,
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
                                              'SET_INTERV_FAVORITE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_interv_favorite;

    FUNCTION update_procedure_order
    (
        i_lang                    IN language.id_language%TYPE, --1
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_interv_prescription     IN table_number,
        i_interv_presc_det        IN table_number, --5
        i_flg_time                IN table_varchar,
        i_dt_begin                IN table_varchar,
        i_order_recurrence        IN table_number,
        i_diagnosis_notes         IN table_varchar,
        i_diagnosis               IN table_clob, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
        i_flg_location            IN table_varchar,
        i_supply                  IN table_table_number,
        i_supply_set              IN table_table_number,
        i_supply_qty              IN table_table_number, --20
        i_dt_return               IN table_table_varchar,
        i_not_order_reason        IN table_number,
        i_notes                   IN table_varchar,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar, --25
        i_order_type              IN table_number,
        i_codification            IN table_number,
        i_health_plan             IN table_number,
        i_exemption               IN table_number,
        i_clinical_question       IN table_table_number, --30
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.UPDATE_PROCEDURE_ORDER';
        IF NOT pk_procedures_core.update_procedure_order(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_episode                 => i_episode,
                                                         i_interv_prescription     => i_interv_prescription(1),
                                                         i_interv_presc_det        => i_interv_presc_det,
                                                         i_flg_time                => i_flg_time,
                                                         i_dt_begin                => i_dt_begin,
                                                         i_order_recurrence        => i_order_recurrence,
                                                         i_diagnosis_notes         => i_diagnosis_notes,
                                                         i_diagnosis               => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                                i_prof   => i_prof,
                                                                                                                i_params => i_diagnosis),
                                                         i_clinical_purpose        => i_clinical_purpose,
                                                         i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                         i_laterality              => i_laterality,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_exec_institution        => i_exec_institution,
                                                         i_flg_location            => i_flg_location,
                                                         i_supply                  => i_supply,
                                                         i_supply_set              => i_supply_set,
                                                         i_supply_qty              => i_supply_qty,
                                                         i_dt_return               => i_dt_return,
                                                         i_not_order_reason        => i_not_order_reason,
                                                         i_notes                   => i_notes,
                                                         i_prof_order              => i_prof_order,
                                                         i_dt_order                => i_dt_order,
                                                         i_order_type              => i_order_type,
                                                         i_codification            => i_codification,
                                                         i_health_plan             => i_health_plan,
                                                         i_exemption               => i_exemption,
                                                         i_clinical_question       => i_clinical_question,
                                                         i_response                => i_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         o_error                   => o_error)
        THEN
            IF o_error.ora_sqlcode IN ('INTERV_M010', 'INTERV_M006')
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
                                              'UPDATE_PROCEDURE_ORDER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_procedure_order;

    FUNCTION cancel_procedure_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN interv_presc_det.id_cancel_reason%TYPE,
        i_cancel_notes     IN interv_presc_det.notes_cancel%TYPE,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CANCEL_PROCEDURE_REQUEST';
        IF NOT pk_procedures_core.cancel_procedure_request(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_interv_presc_det => i_interv_presc_det,
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
                                              'CANCEL_PROCEDURE_REQUEST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_procedure_request;

    FUNCTION cancel_procedure_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_plan           IN VARCHAR2,
        i_cancel_reason     IN interv_presc_plan.id_cancel_reason%TYPE,
        i_cancel_notes      IN interv_presc_plan.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CANCEL_PROCEDURE_EXECUTION';
        IF NOT pk_procedures_core.cancel_procedure_execution(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_interv_presc_plan => i_interv_presc_plan,
                                                             i_dt_plan           => i_dt_plan,
                                                             i_cancel_reason     => i_cancel_reason,
                                                             i_cancel_notes      => i_cancel_notes,
                                                             o_error             => o_error)
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
                                              'CANCEL_PROCEDURE_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_execution;

    FUNCTION cancel_procedure_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_doc_external      IN doc_external.id_doc_external%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.CANCEL_PROCEDURE_DOC';
        IF NOT pk_procedures_core.cancel_procedure_doc(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_interv_presc_det  => i_interv_presc_det,
                                                       i_interv_presc_plan => i_interv_presc_plan,
                                                       i_doc_external      => i_doc_external,
                                                       o_error             => o_error)
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
                                              'CANCEL_PROCEDURE_DOC',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_doc;

    FUNCTION get_procedure_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2,
        i_flg_filter   IN VARCHAR2 DEFAULT pk_procedures_constant.g_interv_institution,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT /*+opt_estimate (table t rows=1)*/
             *
              FROM TABLE(pk_procedures_core.get_procedure_selection_list(i_lang         => i_lang,
                                                                         i_prof         => i_prof,
                                                                         i_patient      => i_patient,
                                                                         i_episode      => i_episode,
                                                                         i_flg_type     => i_flg_type,
                                                                         i_flg_filter   => i_flg_filter,
                                                                         i_codification => i_codification)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROCEDURE_SELECTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_selection_list;

    FUNCTION get_procedure_search
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_codification IN codification.id_codification%TYPE,
        i_value        IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_SEARCH';
        IF NOT pk_procedures_core.get_procedure_search(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_patient      => i_patient,
                                                       i_codification => i_codification,
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
                                              'GET_PROCEDURE_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_search;

    FUNCTION get_procedure_category_search
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_codification   IN codification.id_codification%TYPE,
        i_procedure_type IN intervention.flg_type%TYPE DEFAULT NULL,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_CATEGORY_SEARCH';
        IF NOT pk_procedures_core.get_procedure_category_search(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_patient        => i_patient,
                                                                i_procedure_type => i_procedure_type,
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
                                              'GET_PROCEDURE_CATEGORY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_category_search;

    FUNCTION get_procedure_in_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_interv_category IN interv_category.id_interv_category%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_procedure_type  IN intervention.flg_type%TYPE DEFAULT NULL,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_IN_CATEGORY';
        IF NOT pk_procedures_core.get_procedure_in_category(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_patient         => i_patient,
                                                            i_interv_category => i_interv_category,
                                                            i_procedure_type  => i_procedure_type,
                                                            i_codification    => i_codification,
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
                                              'GET_PROCEDURE_IN_CATEGORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_in_category;

    FUNCTION get_procedure_timelineview
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_start_column IN PLS_INTEGER,
        i_end_column   IN PLS_INTEGER,
        i_last_column  IN PLS_INTEGER DEFAULT 9,
        o_task_list    OUT pk_types.cursor_type,
        o_list         OUT pk_types.cursor_type,
        o_count_list   OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_TIMELINEVIEW';
        IF NOT pk_procedures_core.get_procedure_timelineview(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_patient      => i_patient,
                                                             i_episode      => i_episode,
                                                             i_start_column => i_start_column,
                                                             i_end_column   => i_end_column,
                                                             i_last_column  => i_last_column,
                                                             o_task_list    => o_task_list,
                                                             o_list         => o_list,
                                                             o_count_list   => o_count_list,
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
                                              'GET_PROCEDURE_TIMELINEVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_timelineview;

    FUNCTION get_procedure_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_QUESTIONNAIRE';
        IF NOT pk_procedures_core.get_procedure_questionnaire(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_patient       => i_patient,
                                                              i_episode       => i_episode,
                                                              i_intervention  => i_intervention,
                                                              i_flg_time      => i_flg_time,
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
                                              'GET_PROCEDURE_QUESTIONNAIRE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_questionnaire;

    FUNCTION get_procedure_codification_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_CODIFICATION_DET';
        IF NOT pk_procedures_core.get_procedure_codification_det(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_interv_presc_det => i_interv_presc_det,
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
                                              'GET_PROCEDURE_CODIFICATION_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_codification_det;

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_API_DB.GET_PROCEDURE_DETAIL';
        IF NOT pk_procedures_api_db.get_procedure_detail(i_lang                      => i_lang,
                                                         i_prof                      => i_prof,
                                                         i_episode                   => i_episode,
                                                         i_interv_presc_det          => i_interv_presc_det,
                                                         o_interv_order              => o_interv_order,
                                                         o_interv_co_sign            => o_interv_co_sign,
                                                         o_interv_clinical_questions => o_interv_clinical_questions,
                                                         o_interv_execution          => o_interv_execution,
                                                         o_interv_execution_images   => o_interv_execution_images,
                                                         o_interv_doc                => o_interv_doc,
                                                         o_interv_review             => o_interv_review,
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
                                              'GET_PROCEDURE_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            RETURN FALSE;
    END get_procedure_detail;

    FUNCTION get_procedure_detail_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_API_DB.GET_PROCEDURE_DETAIL_HISTORY';
        IF NOT pk_procedures_api_db.get_procedure_detail_history(i_lang                      => i_lang,
                                                                 i_prof                      => i_prof,
                                                                 i_episode                   => i_episode,
                                                                 i_interv_presc_det          => i_interv_presc_det,
                                                                 o_interv_order              => o_interv_order,
                                                                 o_interv_co_sign            => o_interv_co_sign,
                                                                 o_interv_clinical_questions => o_interv_clinical_questions,
                                                                 o_interv_execution          => o_interv_execution,
                                                                 o_interv_execution_images   => o_interv_execution_images,
                                                                 o_interv_doc                => o_interv_doc,
                                                                 o_interv_review             => o_interv_review,
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
                                              'GET_PROCEDURE_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            RETURN FALSE;
    END get_procedure_detail_history;

    FUNCTION get_procedure_order
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv                    OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_ORDER';
        IF NOT pk_procedures_core.get_procedure_order(i_lang                      => i_lang,
                                                      i_prof                      => i_prof,
                                                      i_episode                   => i_episode,
                                                      i_interv_presc_det          => i_interv_presc_det,
                                                      o_interv                    => o_interv,
                                                      o_interv_clinical_questions => o_interv_clinical_questions,
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
                                              'GET_PROCEDURE_ORDER',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_order;

    FUNCTION get_procedure_execution
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_interv_presc_plan     IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv                OUT pk_types.cursor_type,
        o_interv_images         OUT pk_types.cursor_type,
        o_interv_history        OUT pk_types.cursor_type,
        o_interv_images_history OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_EXECUTION';
        IF NOT pk_procedures_core.get_procedure_execution(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_interv_presc_plan     => i_interv_presc_plan,
                                                          o_interv                => o_interv,
                                                          o_interv_images         => o_interv_images,
                                                          o_interv_history        => o_interv_history,
                                                          o_interv_images_history => o_interv_images_history,
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
                                              'GET_PROCEDURE_EXECUTION',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_interv_history);
            RETURN FALSE;
    END get_procedure_execution;

    FUNCTION get_procedure_doc_associated
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv_doc        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DOC_ASSOCIATED';
        IF NOT pk_procedures_core.get_procedure_doc_associated(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_interv_presc_det  => i_interv_presc_det,
                                                               i_interv_presc_plan => i_interv_presc_plan,
                                                               o_interv_doc        => o_interv_doc,
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
                                              'GET_PROCEDURE_DOC_ASSOCIATED',
                                              o_error);
            pk_types.open_my_cursor(o_interv_doc);
            RETURN FALSE;
    END get_procedure_doc_associated;

    FUNCTION get_procedure_to_edit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN table_number,
        o_interv                    OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_TO_EDIT';
        IF NOT pk_procedures_core.get_procedure_to_edit(i_lang                      => i_lang,
                                                        i_prof                      => i_prof,
                                                        i_episode                   => i_episode,
                                                        i_interv_presc_det          => i_interv_presc_det,
                                                        o_interv                    => o_interv,
                                                        o_interv_supplies           => o_interv_supplies,
                                                        o_interv_clinical_questions => o_interv_clinical_questions,
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
                                              'GET_PROCEDURE_TO_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_to_edit;

    FUNCTION get_procedure_for_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_supplies          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_FOR_EXECUTION';
        IF NOT pk_procedures_core.get_procedure_for_execution(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_interv_presc_det  => i_interv_presc_det,
                                                              i_interv_presc_plan => i_interv_presc_plan,
                                                              o_interv            => o_interv,
                                                              o_supplies          => o_supplies,
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
                                              'GET_PROCEDURE_FOR_EXECUTION',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_for_execution;

    FUNCTION get_procedure_to_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_TO_CANCEL';
        IF NOT pk_procedures_core.get_procedure_to_cancel(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_interv_presc_plan => i_interv_presc_plan,
                                                          o_interv            => o_interv,
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
                                              'GET_PROCEDURE_TO_CANCEL',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_to_cancel;

    FUNCTION get_procedure_execution_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_EXECUTION_LIST';
        IF NOT pk_procedures_core.get_procedure_execution_list(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_episode          => i_episode,
                                                               i_interv_presc_det => i_interv_presc_det,
                                                               o_interv           => o_interv,
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
                                              'GET_PROCEDURE_EXECUTION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_execution_list;

    FUNCTION get_procedure_filter_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_FILTER_LIST';
        IF NOT pk_procedures_core.get_procedure_filter_list(i_lang    => i_lang,
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
                                              'GET_PROCEDURE_FILTER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_filter_list;

    FUNCTION get_procedure_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_TIME_LIST';
        IF NOT pk_procedures_core.get_procedure_time_list(i_lang      => i_lang,
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
                                              'GET_PROCEDURE_TIME_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_time_list;

    FUNCTION get_procedure_priority_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_PRIORITY_LIST';
        IF NOT pk_procedures_core.get_procedure_priority_list(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_intervention => i_intervention,
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
                                              'GET_PROCEDURE_PRIORITY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_priority_list;

    FUNCTION get_procedure_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_PRN_LIST';
        IF NOT pk_procedures_core.get_procedure_prn_list(i_lang  => i_lang,
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
                                              'GET_PROCEDURE_PRN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_prn_list;

    FUNCTION get_procedure_diagnosis_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DIAGNOSIS_LIST';
        IF NOT pk_procedures_core.get_procedure_diagnosis_list(i_lang    => i_lang,
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
                                              'GET_PROCEDURE_DIAGNOSIS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_diagnosis_list;

    FUNCTION get_procedure_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_CLINICAL_PURPOSE';
        IF NOT pk_procedures_core.get_procedure_clinical_purpose(i_lang  => i_lang,
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
                                              'GET_PROCEDURE_CLINICAL_PURPOSE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_clinical_purpose;

    FUNCTION get_procedure_location_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_LOCATION_LIST';
        IF NOT pk_procedures_core.get_procedure_location_list(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_intervention => i_intervention,
                                                              i_flg_time     => i_flg_time,
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
                                              'GET_PROCEDURE_LOCATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_location_list;

    FUNCTION get_procedure_parameter_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_intervention    IN table_number,
        o_weight          OUT VARCHAR2,
        o_analysis_result OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_PARAMETER_LIST';
        IF NOT pk_procedures_core.get_procedure_parameter_list(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_patient         => i_patient,
                                                               i_intervention    => i_intervention,
                                                               o_weight          => o_weight,
                                                               o_analysis_result => o_analysis_result,
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
                                              'GET_PROCEDURE_PARAMETER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_analysis_result);
            RETURN FALSE;
    END get_procedure_parameter_list;

    FUNCTION get_procedure_codification_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_CODIFICATION_LIST';
        IF NOT pk_procedures_core.get_procedure_codification_list(i_lang         => i_lang,
                                                                  i_prof         => i_prof,
                                                                  i_intervention => i_intervention,
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
                                              'GET_PROCEDURE_CODIFICATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_codification_list;

    FUNCTION get_procedure_health_plan_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_HEALTH_PLAN_LIST';
        IF NOT pk_procedures_core.get_procedure_health_plan_list(i_lang    => i_lang,
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
                                              'GET_PROCEDURE_HEALTH_PLAN_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_health_plan_list;

    FUNCTION get_procedure_time_out_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_id_doc_template  OUT doc_template.id_doc_template%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_TIME_OUT_LIST';
        IF NOT pk_procedures_core.get_procedure_time_out_list(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_episode          => i_episode,
                                                              i_interv_presc_det => i_interv_presc_det,
                                                              o_id_doc_template  => o_id_doc_template,
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
                                              'GET_PROCEDURE_TIME_OUT_LIST',
                                              o_error);
            RETURN FALSE;
    END get_procedure_time_out_list;

    FUNCTION get_procedure_modifiers_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_intervention IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_MODIFIERS_LIST';
        IF NOT pk_procedures_core.get_procedure_modifiers_list(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_intervention => i_intervention,
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
                                              'GET_PROCEDURE_MODIFIERS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_modifiers_list;

    FUNCTION get_procedure_viewer_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_VIEWER_LIST';
        IF NOT pk_procedures_external.get_procedure_viewer_list(i_lang    => i_lang,
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
                                              'GET_PROCEDURE_VIEWER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_viewer_list;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_api_ux;
/
