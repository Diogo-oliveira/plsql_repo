/*-- Last Change Revision: $Rev: 2046763 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-10-04 11:01:49 +0100 (ter, 04 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_procedures_api_db IS

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
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis, --10
        i_clinical_purpose        IN table_number,
        i_clinical_purpose_notes  IN table_varchar,
        i_laterality              IN table_varchar,
        i_priority                IN table_varchar,
        i_flg_prn                 IN table_varchar, --15
        i_notes_prn               IN table_varchar,
        i_exec_institution        IN table_number,
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
        i_clinical_decision_rule  IN table_number,
        i_flg_origin_req          IN VARCHAR2 DEFAULT 'D',
        i_test                    IN VARCHAR2, --35
        o_flg_show                OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_msg_req                 OUT VARCHAR2,
        o_interv_presc_array      OUT NOCOPY table_number,
        o_interv_presc_det_array  OUT NOCOPY table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
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
                                                         i_diagnosis_notes         => NULL,
                                                         i_diagnosis               => i_diagnosis,
                                                         i_clinical_purpose        => i_clinical_purpose,
                                                         i_clinical_purpose_notes  => i_clinical_purpose_notes,
                                                         i_laterality              => i_laterality,
                                                         i_priority                => i_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_notes_prn               => i_notes_prn,
                                                         i_exec_institution        => i_exec_institution,
                                                         i_flg_location            => NULL,
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
                                              'CREATE_PROCEDURE_ORDER',
                                              o_error);
            RETURN FALSE;
    END create_procedure_order;

    FUNCTION set_procedure_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_interv_presc_det       IN interv_presc_plan.id_interv_presc_det%TYPE,
        i_interv_presc_plan      IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN interv_presc_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN interv_presc_plan.notes%TYPE,
        i_epis_documentation     IN interv_presc_plan.id_epis_documentation%TYPE DEFAULT NULL,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        o_interv_presc_plan      OUT interv_presc_plan.id_interv_presc_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.SET_PROCEDURE_EXECUTION';
        IF NOT pk_procedures_core.set_procedure_execution(i_lang                    => i_lang,
                                                          i_prof                    => i_prof,
                                                          i_episode                 => i_episode,
                                                          i_interv_presc_det        => i_interv_presc_det,
                                                          i_interv_presc_plan       => i_interv_presc_plan,
                                                          i_dt_next                 => i_dt_next,
                                                          i_prof_performed          => i_prof_performed,
                                                          i_start_time              => i_start_time,
                                                          i_end_time                => i_end_time,
                                                          i_flg_supplies            => i_flg_supplies,
                                                          i_notes                   => i_notes,
                                                          i_epis_documentation      => i_epis_documentation,
                                                          i_clinical_decision_rule  => i_clinical_decision_rule,
                                                          i_clinical_question       => table_number(NULL),
                                                          i_response                => table_varchar(''),
                                                          i_clinical_question_notes => table_varchar(''),
                                                          o_interv_presc_plan       => o_interv_presc_plan,
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
                                              'SET_PROCEDURE_EXECUTION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_execution;

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
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
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
                                              'CANCEL_PROCEDURE_REQUEST',
                                              o_error);
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

    FUNCTION get_procedure_selection_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_type     IN VARCHAR2,
        i_flg_filter   IN VARCHAR2 DEFAULT 'S',
        i_codification IN codification.id_codification%TYPE
    ) RETURN t_tbl_procedures_for_selection IS
    
    BEGIN
    
        RETURN pk_procedures_core.get_procedure_selection_list(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => i_patient,
                                                               i_episode      => i_episode,
                                                               i_flg_type     => i_flg_type,
                                                               i_flg_filter   => i_flg_filter,
                                                               i_codification => i_codification);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_procedure_selection_list;

    FUNCTION get_procedure_search
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_procedure_type IN intervention.flg_type%TYPE DEFAULT pk_procedures_constant.g_type_interv,
        i_flg_type       IN interv_dep_clin_serv.flg_type%TYPE DEFAULT pk_procedures_constant.g_interv_can_req,
        i_codification   IN codification.id_codification%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_value          IN VARCHAR2
    ) RETURN t_table_procedures_search IS
    
    BEGIN
    
        RETURN pk_procedures_core.get_procedure_search(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_procedure_type => i_procedure_type,
                                                       i_flg_type       => i_flg_type,
                                                       i_codification   => i_codification,
                                                       i_dep_clin_serv  => i_dep_clin_serv,
                                                       i_value          => i_value);
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_procedure_search;

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_order              t_tbl_procedures_detail;
        l_interv_clinical_questions t_tbl_procedures_cq;
        l_interv_execution          t_tbl_procedures_execution;
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DETAIL';
        IF NOT pk_procedures_core.get_procedure_detail(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_episode                   => i_episode,
                                                       i_interv_presc_det          => i_interv_presc_det,
                                                       i_flg_report                => i_flg_report,
                                                       o_interv_order              => l_interv_order,
                                                       o_interv_co_sign            => o_interv_co_sign,
                                                       o_interv_clinical_questions => l_interv_clinical_questions,
                                                       o_interv_execution          => l_interv_execution,
                                                       o_interv_execution_images   => o_interv_execution_images,
                                                       o_interv_doc                => o_interv_doc,
                                                       o_interv_review             => o_interv_review,
                                                       o_error                     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_ORDER';
        OPEN o_interv_order FOR
            SELECT id_interv_presc_det,
                   registry,
                   desc_procedure,
                   num_order,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(clinical_indication,
                                                                          diagnosis_notes,
                                                                          desc_diagnosis,
                                                                          clinical_purpose,
                                                                          laterality),
                                                            'T') clinical_indication,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(laterality), 'F') laterality,
                   pk_procedures_utils.get_procedure_detail(i_lang,
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
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                   pk_procedures_utils.get_procedure_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(execution,
                                                                          perform_location,
                                                                          dt_req,
                                                                          desc_supplies,
                                                                          lab_result,
                                                                          weight,
                                                                          not_order_reason,
                                                                          notes),
                                                            'T') execution,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(dt_req), 'F') dt_req,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_supplies), 'F') desc_supplies,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(lab_result), 'F') lab_result,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(weight), 'F') weight,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(not_order_reason), 'F') not_order_reason,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(co_sign, order_type, prof_order, dt_order),
                                                            'T') co_sign,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(health_insurance,
                                                                          financial_entity,
                                                                          health_plan,
                                                                          insurance_number,
                                                                          exemption),
                                                            'T') health_insurance,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(cancellation,
                                                                          cancel_reason,
                                                                          cancel_notes,
                                                                          cancel_order_type,
                                                                          cancel_prof_order,
                                                                          cancel_dt_order),
                                                            'T') cancellation,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                   dt_ord
              FROM (SELECT t.id_interv_presc_det id_interv_presc_det,
                           t.registry            registry,
                           t.desc_procedure      desc_procedure,
                           t.num_order           num_order,
                           t.clinical_indication clinical_indication,
                           t.diagnosis_notes     diagnosis_notes,
                           t.desc_diagnosis      desc_diagnosis,
                           t.clinical_purpose    clinical_purpose,
                           t.laterality          laterality,
                           t.instructions        instructions,
                           t.priority            priority,
                           t.desc_status         desc_status,
                           t.title_order_set     title_order_set,
                           t.task_depend         task_depend,
                           t.desc_time           desc_time,
                           t.desc_time_limit     desc_time_limit,
                           t.order_recurrence    order_recurrence,
                           t.prn                 prn,
                           t.notes_prn           notes_prn,
                           t.execution           execution,
                           t.perform_location    perform_location,
                           t.dt_req              dt_req,
                           t.desc_supplies       desc_supplies,
                           t.lab_result          lab_result,
                           t.weight              weight,
                           t.not_order_reason    not_order_reason,
                           t.notes               notes,
                           t.co_sign             co_sign,
                           t.prof_order          prof_order,
                           t.dt_order            dt_order,
                           t.order_type          order_type,
                           t.health_insurance    health_insurance,
                           t.financial_entity    financial_entity,
                           t.health_plan         health_plan,
                           t.insurance_number    insurance_number,
                           t.exemption           exemption,
                           t.cancellation        cancellation,
                           t.cancel_reason       cancel_reason,
                           t.cancel_notes        cancel_notes,
                           t.cancel_prof_order   cancel_prof_order,
                           t.cancel_dt_order     cancel_dt_order,
                           t.cancel_order_type   cancel_order_type,
                           t.dt_ord              dt_ord
                      FROM TABLE(l_interv_order) t);
    
        g_error := 'OPEN O_INTERV_CLINICAL_QUESTIONS';
        OPEN o_interv_clinical_questions FOR
            SELECT t.id_interv_presc_det    id_interv_presc_det,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question
              FROM TABLE(l_interv_clinical_questions) t;
    
        g_error := 'OPEN O_INTERV_EXECUTION';
        OPEN o_interv_execution FOR
            SELECT t.id_interv_presc_plan id_interv_presc_plan,
                   t.registry             registry,
                   t.desc_procedure       desc_procedure,
                   t.prof_perform         prof_perform,
                   t.start_time           start_time,
                   t.end_time             end_time,
                   t.next_perform_date    next_perform_date,
                   t.desc_modifiers       desc_modifiers,
                   t.desc_supplies        desc_supplies,
                   t.desc_time_out        desc_time_out,
                   t.desc_perform         desc_perform,
                   t.cancel_reason        cancel_reason,
                   t.cancel_notes         cancel_notes,
                   t.dt_ord               dt_ord
              FROM TABLE(l_interv_execution) t;
    
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
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            RETURN FALSE;
    END get_procedure_detail;

    FUNCTION get_procedure_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            SELECT coalesce(ip.id_episode, ip.id_episode_origin, ip.id_episode_destination)
              INTO l_id_episode
              FROM interv_presc_det ipd
              JOIN interv_prescription ip
                ON ip.id_interv_prescription = ipd.id_interv_prescription
             WHERE ipd.id_interv_presc_det = i_interv_presc_det;
        ELSE
            l_id_episode := i_episode;
        END IF;
    
        RETURN pk_procedures_core.get_procedure_detail(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_episode          => l_id_episode,
                                                       i_interv_presc_det => i_interv_presc_det,
                                                       o_detail           => o_detail,
                                                       o_error            => o_error);
    
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
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_procedure_detail;

    FUNCTION get_procedure_detail_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_order              t_tbl_procedures_detail;
        l_interv_clinical_questions t_tbl_procedures_cq;
        l_interv_execution          t_tbl_procedures_execution;
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_DETAIL_HISTORY';
        IF NOT pk_procedures_core.get_procedure_detail_history(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_episode                   => i_episode,
                                                               i_interv_presc_det          => i_interv_presc_det,
                                                               i_flg_report                => i_flg_report,
                                                               o_interv_order              => l_interv_order,
                                                               o_interv_co_sign            => o_interv_co_sign,
                                                               o_interv_clinical_questions => l_interv_clinical_questions,
                                                               o_interv_execution          => l_interv_execution,
                                                               o_interv_execution_images   => o_interv_execution_images,
                                                               o_interv_doc                => o_interv_doc,
                                                               o_interv_review             => o_interv_review,
                                                               o_error                     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN O_INTERV_ORDER';
        OPEN o_interv_order FOR
            SELECT id_interv_presc_det,
                   registry,
                   desc_procedure,
                   num_order,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(clinical_indication,
                                                                          diagnosis_notes,
                                                                          desc_diagnosis,
                                                                          clinical_purpose,
                                                                          laterality),
                                                            'T') clinical_indication,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(diagnosis_notes), 'F') diagnosis_notes,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_diagnosis), 'F') desc_diagnosis,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(clinical_purpose), 'F') clinical_purpose,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(laterality), 'F') laterality,
                   pk_procedures_utils.get_procedure_detail(i_lang,
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
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(priority), 'F') priority,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_status), 'F') desc_status,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(title_order_set), 'F') title_order_set,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(task_depend), 'F') task_depend,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_time), 'F') desc_time,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_time_limit), 'F') desc_time_limit,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(order_recurrence), 'F') order_recurrence,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(prn), 'F') prn,
                   pk_procedures_utils.get_procedure_detail_clob(i_lang, i_prof, table_clob(notes_prn), 'F') notes_prn,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(execution,
                                                                          perform_location,
                                                                          dt_req,
                                                                          desc_supplies,
                                                                          lab_result,
                                                                          weight,
                                                                          not_order_reason,
                                                                          notes),
                                                            'T') execution,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(perform_location), 'F') perform_location,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(dt_req), 'F') dt_req,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(desc_supplies), 'F') desc_supplies,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(lab_result), 'F') lab_result,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(weight), 'F') weight,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(not_order_reason), 'F') not_order_reason,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(notes), 'F') notes,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(co_sign, order_type, prof_order, dt_order),
                                                            'T') co_sign,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(order_type), 'F') order_type,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(prof_order), 'F') prof_order,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(dt_order), 'F') dt_order,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(health_insurance,
                                                                          financial_entity,
                                                                          health_plan,
                                                                          insurance_number,
                                                                          exemption),
                                                            'T') health_insurance,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(financial_entity), 'F') financial_entity,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(health_plan), 'F') health_plan,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(insurance_number), 'F') insurance_number,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(exemption), 'F') exemption,
                   pk_procedures_utils.get_procedure_detail(i_lang,
                                                            i_prof,
                                                            table_varchar(cancellation,
                                                                          cancel_reason,
                                                                          cancel_notes,
                                                                          cancel_order_type,
                                                                          cancel_prof_order,
                                                                          cancel_dt_order),
                                                            'T') cancellation,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_reason), 'F') cancel_reason,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_notes), 'F') cancel_notes,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_order_type), 'F') cancel_order_type,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_prof_order), 'F') cancel_prof_order,
                   pk_procedures_utils.get_procedure_detail(i_lang, i_prof, table_varchar(cancel_dt_order), 'F') cancel_dt_order,
                   dt_ord,
                   dt_last_update
              FROM (SELECT t.id_interv_presc_det id_interv_presc_det,
                           t.registry            registry,
                           t.desc_procedure      desc_procedure,
                           t.num_order           num_order,
                           t.clinical_indication clinical_indication,
                           t.diagnosis_notes     diagnosis_notes,
                           t.desc_diagnosis      desc_diagnosis,
                           t.clinical_purpose    clinical_purpose,
                           t.laterality          laterality,
                           t.instructions        instructions,
                           t.priority            priority,
                           t.desc_status         desc_status,
                           t.title_order_set     title_order_set,
                           t.task_depend         task_depend,
                           t.desc_time           desc_time,
                           t.desc_time_limit     desc_time_limit,
                           t.order_recurrence    order_recurrence,
                           t.prn                 prn,
                           t.notes_prn           notes_prn,
                           t.execution           execution,
                           t.perform_location    perform_location,
                           t.dt_req              dt_req,
                           t.desc_supplies       desc_supplies,
                           t.lab_result          lab_result,
                           t.weight              weight,
                           t.not_order_reason    not_order_reason,
                           t.notes               notes,
                           t.co_sign             co_sign,
                           t.prof_order          prof_order,
                           t.dt_order            dt_order,
                           t.order_type          order_type,
                           t.health_insurance    health_insurance,
                           t.financial_entity    financial_entity,
                           t.health_plan         health_plan,
                           t.insurance_number    insurance_number,
                           t.exemption           exemption,
                           t.cancellation        cancellation,
                           t.cancel_reason       cancel_reason,
                           t.cancel_notes        cancel_notes,
                           t.cancel_prof_order   cancel_prof_order,
                           t.cancel_dt_order     cancel_dt_order,
                           t.cancel_order_type   cancel_order_type,
                           t.dt_ord              dt_ord,
                           t.dt_last_update
                      FROM TABLE(l_interv_order) t);
    
        g_error := 'OPEN O_INTERV_CLINICAL_QUESTIONS';
        OPEN o_interv_clinical_questions FOR
            SELECT t.id_interv_presc_det    id_interv_presc_det,
                   t.flg_time               flg_time,
                   t.desc_clinical_question desc_clinical_question,
                   t.dt_last_update,
                   t.num_clinical_question,
                   t.rn
              FROM TABLE(l_interv_clinical_questions) t;
    
        g_error := 'OPEN O_INTERV_EXECUTION';
        OPEN o_interv_execution FOR
            SELECT t.id_interv_presc_plan id_interv_presc_plan,
                   t.registry             registry,
                   t.desc_procedure       desc_procedure,
                   t.prof_perform         prof_perform,
                   t.start_time           start_time,
                   t.end_time             end_time,
                   t.next_perform_date    next_perform_date,
                   t.desc_modifiers       desc_modifiers,
                   t.desc_supplies        desc_supplies,
                   t.desc_time_out        desc_time_out,
                   t.desc_perform         desc_perform,
                   t.cancel_reason        cancel_reason,
                   t.cancel_notes         cancel_notes,
                   t.dt_ord               dt_ord
              FROM TABLE(l_interv_execution) t;
    
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
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            RETURN FALSE;
    END get_procedure_detail_history;

    FUNCTION get_procedure_detail_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            SELECT coalesce(ip.id_episode, ip.id_episode_origin, ip.id_episode_destination)
              INTO l_id_episode
              FROM interv_presc_det ipd
              JOIN interv_prescription ip
                ON ip.id_interv_prescription = ipd.id_interv_prescription
             WHERE ipd.id_interv_presc_det = i_interv_presc_det;
        ELSE
            l_id_episode := i_episode;
        END IF;
    
        RETURN pk_procedures_core.get_procedure_detail_history(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_episode          => l_id_episode,
                                                               i_interv_presc_det => i_interv_presc_det,
                                                               o_detail           => o_detail,
                                                               o_error            => o_error);
    
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
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_procedure_detail_history;

    FUNCTION get_procedure_for_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_CORE.GET_PROCEDURE_FOR_EXECUTION';
        IF NOT pk_procedures_core.get_procedure_for_execution(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_interv_presc_det  => i_interv_presc_det,
                                                              i_interv_presc_plan => i_interv_presc_plan,
                                                              o_interv            => o_interv,
                                                              o_supplies          => l_dummy,
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

    FUNCTION get_alias_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_procedures_utils.get_alias_translation(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_code_interv   => i_code_interv,
                                                         i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_procedure_time_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis_type IN epis_type.id_epis_type%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL GET_PROCEDURE_TIME_LIST';
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

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_api_db;
/
