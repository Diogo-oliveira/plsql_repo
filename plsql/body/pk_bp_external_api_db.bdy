CREATE OR REPLACE PACKAGE BODY pk_bp_external_api_db IS

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_DETAIL';
        IF NOT pk_bp_external.get_bp_detail(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_episode               => i_episode,
                                            i_blood_product_det     => i_blood_product_det,
                                            o_bp_detail             => o_bp_detail,
                                            o_bp_clinical_questions => o_bp_clinical_questions,
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
                                              'GET_BP_DETAIL',
                                              o_error);
            RETURN FALSE;
    END get_bp_detail;

    FUNCTION get_bp_detail_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_blood_product_det     IN blood_product_det.id_blood_product_det%TYPE,
        o_bp_detail             OUT pk_types.cursor_type,
        o_bp_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_DETAIL_HISTORY';
        IF NOT pk_bp_external.get_bp_detail_history(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_episode               => i_episode,
                                                    i_blood_product_det     => i_blood_product_det,
                                                    o_bp_detail             => o_bp_detail,
                                                    o_bp_clinical_questions => o_bp_clinical_questions,
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
                                              'GET_BP_DETAIL_HISTORY',
                                              o_error);
            RETURN FALSE;
    END get_bp_detail_history;

    FUNCTION get_bp_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_scope     IN NUMBER,
        o_bp_list   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_TASK_LIST';
        IF NOT pk_bp_external.get_bp_task_list(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_episode   => i_episode,
                                               i_flg_scope => i_flg_scope,
                                               i_scope     => i_scope,
                                               o_bp_list   => o_bp_list,
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
                                              'GET_BP_TASK_LIST',
                                              o_error);
            RETURN FALSE;
    END get_bp_task_list;

    FUNCTION get_bp_adverse_reaction
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_blood_product_det   IN blood_product_det.id_blood_product_det%TYPE,
        o_data_transfusion    OUT pk_types.cursor_type,
        o_data_vital_signs    OUT pk_types.cursor_type,
        o_data_clinical_sympt OUT VARCHAR2,
        o_data_medicine       OUT VARCHAR2,
        o_data_lab_tests_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_ADVERSE_REACTION';
        IF NOT pk_bp_external.get_bp_adverse_reaction(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_blood_product_det   => i_blood_product_det,
                                                      o_data_transfusion    => o_data_transfusion,
                                                      o_data_vital_signs    => o_data_vital_signs,
                                                      o_data_clinical_sympt => o_data_clinical_sympt,
                                                      o_data_medicine       => o_data_medicine,
                                                      o_data_lab_tests_list => o_data_lab_tests_list,
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
                                              'GET_BP_ADVERSE_REACTION',
                                              o_error);
            RETURN FALSE;
    END get_bp_adverse_reaction;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_bp_external.get_bp_description(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_blood_product_det => i_blood_product_det,
                                                 i_co_sign_hist      => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_description;

    FUNCTION get_bp_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_bp_external.get_bp_instructions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_blood_product_det => i_blood_product_det,
                                                  i_co_sign_hist      => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_instructions;

    FUNCTION get_bp_action_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_action            IN co_sign.id_action%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_bp_external.get_bp_action_desc(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_blood_product_det => i_blood_product_det,
                                                 i_action            => i_action,
                                                 i_co_sign_hist      => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_action_desc;

    FUNCTION get_bp_date_to_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        i_co_sign_hist      IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
    BEGIN
    
        RETURN pk_bp_external.get_bp_date_to_order(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_blood_product_det => i_blood_product_det,
                                                   i_co_sign_hist      => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bp_date_to_order;

    PROCEDURE cpoe_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.COPY_TO_DRAFT';
        IF NOT pk_bp_external.copy_to_draft(i_lang                 => i_lang,
                                            i_prof                 => i_prof,
                                            i_episode              => i_episode,
                                            i_task_request         => i_task_request,
                                            i_task_start_timestamp => i_task_start_timestamp,
                                            i_task_end_timestamp   => i_task_end_timestamp,
                                            o_draft                => o_draft,
                                            o_error                => o_error)
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
                                              'COPY_TO_DRAFT',
                                              o_error);
            RETURN FALSE;
    END copy_to_draft;

    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CHECK_DRAFT_CONFLICTS';
        IF NOT pk_bp_external.check_draft_conflicts(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => i_episode,
                                                    i_draft        => i_draft,
                                                    o_flg_conflict => o_flg_conflict,
                                                    o_msg_title    => o_msg_title,
                                                    o_msg_body     => o_msg_body,
                                                    o_msg_template => o_msg_template,
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
                                              'CHECK_DRAFT_CONFLICTS',
                                              o_error);
            RETURN FALSE;
    END check_draft_conflicts;

    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        i_id_cdr_call   IN cdr_call.id_cdr_call%TYPE,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.ACTIVATE_DRAFTS';
        IF NOT pk_bp_external.activate_drafts(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              i_draft         => i_draft,
                                              i_flg_commit    => i_flg_commit,
                                              i_id_cdr_call   => i_id_cdr_call,
                                              o_created_tasks => o_created_tasks,
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
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_drafts;

    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CANCEL_DRAFT';
        IF NOT pk_bp_external.cancel_draft(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_episode => i_episode,
                                           i_draft   => i_draft,
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
                                              'CANCEL_DRAFT',
                                              o_error);
            RETURN FALSE;
    END cancel_draft;

    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.EXPIRE_TASK';
        IF NOT pk_bp_external.expire_task(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_episode       => i_episode,
                                          i_task_requests => i_task_requests,
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
                                              'EXPIRE_TASK',
                                              o_error);
            RETURN FALSE;
    END expire_task;

    FUNCTION get_cpoe_task_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_task_request    IN table_number,
        i_filter_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status   IN table_varchar,
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_type        IN VARCHAR2,
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_CPOE_TASK_LIST';
        IF NOT pk_bp_external.get_cpoe_task_list(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_patient         => i_patient,
                                                 i_episode         => i_episode,
                                                 i_task_request    => i_task_request,
                                                 i_filter_tstz     => i_filter_tstz,
                                                 i_filter_status   => i_filter_status,
                                                 i_flg_report      => i_flg_report,
                                                 i_dt_begin        => i_dt_begin,
                                                 i_dt_end          => i_dt_end,
                                                 i_flg_type        => i_flg_type,
                                                 i_flg_out_of_cpoe => i_flg_out_of_cpoe,
                                                 i_flg_print_items => i_flg_print_items,
                                                 o_task_list       => o_task_list,
                                                 o_plan_list       => o_plan_list,
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
                                              'GET_CPOE_TASK_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END get_cpoe_task_list;

    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_TASK_ACTIONS';
        IF NOT pk_bp_external.get_task_actions(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_task_request => i_task_request,
                                               o_action       => o_action,
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
                                              'GET_TASK_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_task_actions;

    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_TASK_STATUS';
        IF NOT pk_bp_external.get_task_status(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_episode      => i_episode,
                                              i_task_request => i_task_request,
                                              o_task_status  => o_task_status,
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
                                              'GET_TASK_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_task_status;

    PROCEDURE order_sets________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_bp_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN blood_product_req.id_blood_product_req%TYPE,
        i_task_request_det IN blood_product_det.id_blood_product_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_TASK_TITLE';
        IF NOT pk_bp_external.get_bp_task_title(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_task_request     => i_task_request,
                                                i_task_request_det => i_task_request_det,
                                                o_task_desc        => o_task_desc,
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
                                              'GET_BP_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_bp_task_title;

    FUNCTION get_bp_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN blood_product_req.id_blood_product_req%TYPE,
        i_task_request_det  IN blood_product_det.id_blood_product_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_TASK_INSTRUCTIONS';
        IF NOT pk_bp_external.get_bp_task_instructions(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_task_request      => i_task_request,
                                                       i_task_request_det  => i_task_request_det,
                                                       i_flg_showdate      => i_flg_showdate,
                                                       o_task_instructions => o_task_instructions,
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
                                              'GET_BP_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_bp_task_instructions;

    FUNCTION get_bp_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN blood_product_det.id_blood_product_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_STATUS';
        IF NOT pk_bp_external.get_bp_status(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_task_request  => i_task_request,
                                            o_flg_status    => o_flg_status,
                                            o_status_string => o_status_string,
                                            
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
                                              'GET_BP_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_bp_status;

    FUNCTION get_bp_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_QUESTIONNAIRE';
        IF NOT pk_bp_external.get_bp_questionnaire(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_patient      => i_patient,
                                                   i_episode      => i_episode,
                                                   i_task_request => i_task_request,
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
                                              'GET_BP_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
    END get_bp_questionnaire;

    FUNCTION get_bp_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_BP_DATE_LIMITS';
        IF NOT pk_bp_external.get_bp_date_limits(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_task_request => i_task_request,
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
                                              'GET_BP_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_bp_date_limits;

    FUNCTION set_bp_request_task
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_task_request            IN table_number,
        i_prof_order              IN table_number,
        i_dt_order                IN table_varchar,
        i_order_type              IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_clinical_decision_rule  IN interv_presc_det.id_cdr_event%TYPE,
        o_bp_req                  OUT table_number,
        o_bp_det                  OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.SET_BP_REQUEST_TASK';
        IF NOT pk_bp_external.set_bp_request_task(i_lang                    => i_lang,
                                                  i_prof                    => i_prof,
                                                  i_task_request            => i_task_request,
                                                  i_prof_order              => i_prof_order,
                                                  i_dt_order                => i_dt_order,
                                                  i_order_type              => i_order_type,
                                                  i_clinical_question       => i_clinical_question,
                                                  i_response                => i_response,
                                                  i_clinical_question_notes => i_clinical_question_notes,
                                                  i_clinical_decision_rule  => i_clinical_decision_rule,
                                                  o_bp_req                  => o_bp_req,
                                                  o_bp_det                  => o_bp_det,
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
                                              'SET_BP_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_request_task;

    FUNCTION set_bp_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_bp_req       OUT blood_product_req.id_blood_product_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.SET_BP_COPY_TASK';
        IF NOT pk_bp_external.set_bp_copy_task(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_episode      => i_episode,
                                               i_task_request => i_task_request,
                                               o_bp_req       => o_bp_req,
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
                                              'SET_BP_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_copy_task;

    FUNCTION set_bp_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.SET_BP_DELETE_TASK';
        IF NOT pk_bp_external.set_bp_delete_task(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_task_request => i_task_request,
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
                                              'SET_BP_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_bp_delete_task;

    FUNCTION set_bp_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.SET_BP_DIAGNOSIS';
        IF NOT pk_bp_external.set_bp_diagnosis(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_episode      => i_episode,
                                               i_task_request => i_task_request,
                                               i_diagnosis    => i_diagnosis,
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
                                              'SET_BP_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_bp_diagnosis;

    FUNCTION cancel_bp_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_bp_det        IN table_number,
        i_dt_cancel     IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN VARCHAR2,
        i_prof_order    IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order      IN VARCHAR2,
        i_order_type    IN co_sign.id_order_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CANCEL_BP_TASK';
        IF NOT pk_bp_external.cancel_bp_task(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_bp_det        => i_bp_det,
                                             i_dt_cancel     => i_dt_cancel,
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
                                              'CANCEL_BP_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_bp_task;

    FUNCTION check_bp_mandatory
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CHECK_BP_MANDATORY';
        IF NOT pk_bp_external.check_bp_mandatory(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_task_request => i_task_request,
                                                 o_check        => o_check,
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
                                              'CHECK_BP_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_bp_mandatory;

    FUNCTION check_bp_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN blood_product_req.id_blood_product_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CHECK_BP_CONFLICT';
        IF NOT pk_bp_external.check_bp_conflict(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_patient      => i_patient,
                                                i_task_request => i_task_request,
                                                o_flg_conflict => o_flg_conflict,
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
                                              'CHECK_BP_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_bp_conflict;

    FUNCTION check_bp_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN blood_product_det.id_blood_product_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.CHECK_BP_CANCEL';
        IF NOT pk_bp_external.check_bp_cancel(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_episode      => i_episode,
                                              i_task_request => i_task_request,
                                              o_flg_cancel   => o_flg_cancel,
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
                                              'CHECK_BP_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_bp_cancel;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_ORDERED_LIST';
        IF NOT pk_bp_external.get_ordered_list(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_translate    => i_translate,
                                               i_viewer_area  => i_viewer_area,
                                               i_episode      => i_episode,
                                               o_ordered_list => o_ordered_list,
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
                                              'GET_ORDERED_LIST',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_ordered_list_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_blood_product_det IN blood_product_det.id_blood_product_det%TYPE,
        o_ordered_list_det  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_ORDERED_LIST_DET';
        IF NOT pk_bp_external.get_ordered_list_det(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_blood_product_det => i_blood_product_det,
                                                   o_ordered_list_det  => o_ordered_list_det,
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
                                              'GET_ORDERED_LIST_DET',
                                              o_error);
            pk_types.open_my_cursor(o_ordered_list_det);
    END get_ordered_list_det;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_viewer_area IN VARCHAR2,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.GET_COUNT_AND_FIRST';
        IF NOT pk_bp_external.get_count_and_first(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_patient     => i_patient,
                                                  i_viewer_area => i_viewer_area,
                                                  i_episode     => i_episode,
                                                  o_num_occur   => o_num_occur,
                                                  o_desc_first  => o_desc_first,
                                                  o_code_first  => o_code_first,
                                                  o_dt_first    => o_dt_first,
                                                  o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              'U',
                                              g_error,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_count_and_first;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_bp_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.SET_BP_MATCH';
        IF NOT pk_bp_external.set_bp_match(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_patient      => i_patient,
                                           i_episode      => i_episode,
                                           i_episode_temp => i_episode_temp,
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
                                              'SET_BP_MATCH',
                                              o_error);
            RETURN FALSE;
    END set_bp_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_bp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL.RESET_BP';
        IF NOT pk_bp_external.reset_bp(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       i_episode => i_episode,
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
                                              'RESET_BP',
                                              o_error);
            RETURN FALSE;
    END reset_bp;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_bp_external_api_db;
/
