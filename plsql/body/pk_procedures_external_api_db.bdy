/*-- Last Change Revision: $Rev: 2027523 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_procedures_external_api_db IS

    PROCEDURE dashboards_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_last_execution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_status       IN interv_presc_det.flg_status%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_LAST_EXECUTION';
        RETURN pk_procedures_external.get_procedure_last_execution(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_interv_presc_det => i_interv_presc_det,
                                                                   i_flg_status       => i_flg_status);
    
    END get_procedure_last_execution;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_listview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_scope            IN NUMBER,
        i_flg_scope        IN VARCHAR2,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        i_cancelled        IN VARCHAR2,
        i_crit_type        IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_LISTVIEW';
        IF NOT pk_procedures_external.get_procedure_listview(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => i_interv_presc_det,
                                                             i_scope            => i_scope,
                                                             i_flg_scope        => i_flg_scope,
                                                             i_start_date       => i_start_date,
                                                             i_end_date         => i_end_date,
                                                             i_cancelled        => i_cancelled,
                                                             i_crit_type        => i_crit_type,
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
                                              'GET_PROCEDURE_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_procedure_listview;

    FUNCTION get_procedure_orders
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order     OUT pk_types.cursor_type,
        o_interv_execution OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_ORDERS';
        IF NOT pk_procedures_external.get_procedure_orders(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_interv_presc_det => i_interv_presc_det,
                                                           o_interv_order     => o_interv_order,
                                                           o_interv_execution => o_interv_execution,
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
                                              'GET_PROCEDURE_ORDERS',
                                              o_error);
            pk_types.open_my_cursor(o_interv_order);
            pk_types.open_my_cursor(o_interv_execution);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_orders;

    FUNCTION get_procedure_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_report                IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_DETAIL';
        IF NOT pk_procedures_external.get_procedure_detail(i_lang                      => i_lang,
                                                           i_prof                      => i_prof,
                                                           i_episode                   => i_episode,
                                                           i_interv_presc_det          => i_interv_presc_det,
                                                           i_flg_report                => i_flg_report,
                                                           o_interv_order              => o_interv_order,
                                                           o_interv_supplies           => o_interv_supplies,
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
            pk_types.open_my_cursor(o_interv_supplies);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            pk_alert_exceptions.reset_error_state;
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
        o_interv_supplies           OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_DETAIL_HISTORY';
        IF NOT pk_procedures_external.get_procedure_detail_history(i_lang                      => i_lang,
                                                                   i_prof                      => i_prof,
                                                                   i_episode                   => i_episode,
                                                                   i_interv_presc_det          => i_interv_presc_det,
                                                                   i_flg_report                => i_flg_report,
                                                                   o_interv_order              => o_interv_order,
                                                                   o_interv_supplies           => o_interv_supplies,
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
            pk_types.open_my_cursor(o_interv_supplies);
            pk_types.open_my_cursor(o_interv_co_sign);
            pk_types.open_my_cursor(o_interv_clinical_questions);
            pk_types.open_my_cursor(o_interv_execution);
            pk_types.open_my_cursor(o_interv_execution_images);
            pk_types.open_my_cursor(o_interv_doc);
            pk_types.open_my_cursor(o_interv_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_procedure_detail_history;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_procedures_external.get_procedure_description(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_interv_presc_det => i_interv_presc_det,
                                                                i_co_sign_hist     => i_co_sign_hist);
    
    END get_procedure_description;

    FUNCTION get_procedure_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_procedures_external.get_procedure_instructions(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_interv_presc_det => i_interv_presc_det,
                                                                 i_co_sign_hist     => i_co_sign_hist);
    
    END get_procedure_instructions;

    FUNCTION get_procedure_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_procedures_external.get_procedure_action_desc(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_interv_presc_det => i_interv_presc_det,
                                                                i_action           => i_action,
                                                                i_co_sign_hist     => i_co_sign_hist);
    
    END get_procedure_action_desc;

    FUNCTION get_procedure_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
    BEGIN
    
        RETURN pk_procedures_external.get_procedure_date_to_order(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_interv_presc_det => i_interv_presc_det,
                                                                  i_co_sign_hist     => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_procedure_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_intervention     IN intervention.id_intervention%TYPE,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_presc_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_CDR';
        IF NOT pk_procedures_external.check_procedure_cdr(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => i_patient,
                                                          i_intervention     => i_intervention,
                                                          i_date             => i_date,
                                                          o_interv_presc_det => o_interv_presc_det,
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
                                              'CHECK_PROCEDURE_CDR',
                                              o_error);
            RETURN FALSE;
    END check_procedure_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_procedure_laterality
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_laterality   IN interv_presc_det.flg_laterality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.UPDATE_PROCEDURE_LATERALITY';
        IF NOT pk_procedures_external.update_procedure_laterality(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_interv_presc_det => i_interv_presc_det,
                                                                  i_flg_laterality   => i_flg_laterality,
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
                                              'UPDATE_PROCEDURE_LATERALITY',
                                              o_error);
            RETURN FALSE;
    END update_procedure_laterality;

    FUNCTION update_procedure_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_exec_institution IN interv_presc_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.UPDATE_PROCEDURE_INSTITUTION';
        IF NOT pk_procedures_external.update_procedure_institution(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_interv_presc_det => i_interv_presc_det,
                                                                   i_exec_institution => i_exec_institution,
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
                                              'UPDATE_PROCEDURE_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_procedure_institution;

    FUNCTION update_procedure_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_referral     IN interv_presc_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.UPDATE_PROCEDURE_REFERRAL';
        IF NOT pk_procedures_external.update_procedure_referral(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_interv_presc_det => i_interv_presc_det,
                                                                i_flg_referral     => i_flg_referral,
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
                                              'UPDATE_PROCEDURE_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_procedure_referral;

    FUNCTION get_procedure_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_procedures_external.t_cur_procedure,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_LISTVIEW';
        IF NOT pk_procedures_external.get_procedure_listview(i_lang    => i_lang,
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
                                              'GET_PROCEDURE_LISTVIEW',
                                              o_error);
            RETURN FALSE;
    END get_procedure_listview;

    FUNCTION get_procedure_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_NOTES';
        RETURN pk_procedures_external.get_procedure_notes(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_interv_presc_det => i_interv_presc_det);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_notes;

    FUNCTION get_exec_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_EXEC_INSTITUTION';
        RETURN pk_procedures_external.get_exec_institution(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_interv_presc_det => i_interv_presc_det);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exec_institution;

    PROCEDURE cpoe______________________ IS
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.COPY_PROCEDURE_TO_DRAFT';
        IF NOT pk_procedures_external.copy_procedure_to_draft(i_lang                 => i_lang,
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_DRAFT_CONFLICT';
        IF NOT pk_procedures_external.check_procedure_draft_conflict(i_lang         => i_lang,
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

    FUNCTION check_draft_in_episode
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_has_draft OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_DRAFT';
        IF NOT pk_procedures_external.check_procedure_draft(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_episode   => i_episode,
                                                            o_has_draft => o_has_draft,
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
                                              'CHECK_DRAFT_IN_EPISODE',
                                              o_error);
            RETURN FALSE;
    END check_draft_in_episode;

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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_DRAFT_ACTIVATION';
        IF NOT pk_procedures_external.set_procedure_draft_activation(i_lang          => i_lang,
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CANCEL_PROCEDURE_DRAFT';
        IF NOT pk_procedures_external.cancel_procedure_draft(i_lang    => i_lang,
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

    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CANCEL_PROCEDURE_ALL_DRAFTS';
        IF NOT pk_procedures_external.cancel_procedure_all_drafts(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
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
                                              'CANCEL_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_all_drafts;

    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_EXPIRATION';
        IF NOT pk_procedures_external.set_procedure_expiration(i_lang          => i_lang,
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
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT pk_procedures_constant.g_no,
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_task_list     OUT pk_types.cursor_type,
        o_plan_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_TASK_LIST';
        IF NOT pk_procedures_external.get_procedure_task_list(i_lang          => i_lang,
                                                              i_prof          => i_prof,
                                                              i_patient       => i_patient,
                                                              i_episode       => i_episode,
                                                              i_task_request  => i_task_request,
                                                              i_filter_tstz   => i_filter_tstz,
                                                              i_filter_status => i_filter_status,
                                                              i_flg_report    => i_flg_report,
                                                              i_dt_begin      => i_dt_begin,
                                                              i_dt_end        => i_dt_end,
                                                              o_task_list     => o_task_list,
                                                              o_plan_list     => o_plan_list,
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_ACTIONS';
        IF NOT pk_procedures_external.get_procedure_actions(i_lang         => i_lang,
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
            pk_types.open_my_cursor(o_action);
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_STATUS';
        IF NOT pk_procedures_external.get_procedure_status(i_lang         => i_lang,
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
            pk_types.open_my_cursor(o_task_status);
            RETURN FALSE;
    END get_task_status;

    PROCEDURE order_sets_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_interv_presc_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_REQ_DET';
        IF NOT pk_procedures_external.get_procedure_req_det(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_task_request     => i_task_request,
                                                            o_interv_presc_det => o_interv_presc_det,
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
                                              'GET_PROCEDURE_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_procedure_req_det;

    FUNCTION get_procedure_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_TASK_TITLE';
        IF NOT pk_procedures_external.get_procedure_task_title(i_lang             => i_lang,
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
                                              'GET_PROCEDURE_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_title;

    FUNCTION get_procedure_task_instruction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det  IN interv_presc_det.id_interv_presc_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT pk_procedures_constant.g_yes,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_TASK_INSTRUCTION';
        IF NOT pk_procedures_external.get_procedure_task_instruction(i_lang              => i_lang,
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
                                              'GET_PROCEDURE_TASK_INSTRUCTION',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_instruction;

    FUNCTION get_procedure_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_presc_det.id_interv_presc_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_TASK_DESCRIPTION';
        IF NOT pk_procedures_external.get_procedure_task_description(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_interv_presc_det => i_task_request,
                                                                     o_interv_desc      => o_task_desc,
                                                                     o_task_status_desc => o_task_status_desc,
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
                                              'GET_PROCEDURE_TASK_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_description;

    FUNCTION get_procedure_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_STATUS';
        IF NOT pk_procedures_external.get_procedure_status(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_task_request  => i_task_request,
                                                           o_flg_status    => o_flg_status,
                                                           o_status_string => o_status_string,
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
                                              'GET_PROCEDURE_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_procedure_status;

    FUNCTION get_procedure_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_QUESTIONNAIRE';
        IF NOT pk_procedures_external.get_procedure_questionnaire(i_lang         => i_lang,
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
                                              'GET_PROCEDURE_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
    END get_procedure_questionnaire;

    FUNCTION get_procedure_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_DATE_LIMITS';
        IF NOT pk_procedures_external.get_procedure_date_limits(i_lang         => i_lang,
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
                                              'GET_PROCEDURE_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_procedure_date_limits;

    FUNCTION get_procedure_task_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN interv_prescription.id_interv_prescription%TYPE,
        i_task_request_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_id        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_TASK_ID';
        IF NOT pk_procedures_external.get_procedure_task_id(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_task_request     => i_task_request,
                                                            i_task_request_det => i_task_request_det,
                                                            o_interv_id        => o_interv_id,
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
                                              'GET_PROCEDURE_TASK_ID',
                                              o_error);
            RETURN FALSE;
    END get_procedure_task_id;

    FUNCTION set_procedure_request_task
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
        o_interv_presc            OUT table_number,
        o_interv_presc_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_REQUEST_TASK';
        IF NOT pk_procedures_external.set_procedure_request_task(i_lang                    => i_lang,
                                                                 i_prof                    => i_prof,
                                                                 i_task_request            => i_task_request,
                                                                 i_prof_order              => i_prof_order,
                                                                 i_dt_order                => i_dt_order,
                                                                 i_order_type              => i_order_type,
                                                                 i_clinical_question       => i_clinical_question,
                                                                 i_response                => i_response,
                                                                 i_clinical_question_notes => i_clinical_question_notes,
                                                                 i_clinical_decision_rule  => i_clinical_decision_rule,
                                                                 o_interv_presc            => o_interv_presc,
                                                                 o_interv_presc_det        => o_interv_presc_det,
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
                                              'SET_PROCEDURE_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_request_task;

    FUNCTION set_procedure_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_interv_presc OUT interv_prescription.id_interv_prescription%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_COPY_TASK';
        IF NOT pk_procedures_external.set_procedure_copy_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => i_patient,
                                                              i_episode      => i_episode,
                                                              i_task_request => i_task_request,
                                                              o_interv_presc => o_interv_presc,
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
                                              'SET_PROCEDURE_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_copy_task;

    FUNCTION set_procedure_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_DELETE_TASK';
        IF NOT pk_procedures_external.set_procedure_delete_task(i_lang         => i_lang,
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
                                              'SET_PROCEDURE_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_procedure_delete_task;

    FUNCTION set_procedure_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_DIAGNOSIS';
        IF NOT pk_procedures_external.set_procedure_diagnosis(i_lang         => i_lang,
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
                                              'SET_PROCEDURE_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_procedure_diagnosis;

    FUNCTION set_procedure_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_EXECUTE_TIME';
        IF NOT pk_procedures_external.set_procedure_execute_time(i_lang         => i_lang,
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
                                              'SET_PROCEDURE_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_procedure_execute_time;

    FUNCTION check_procedure_mandatory
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_MANDATORY';
        IF NOT pk_procedures_external.check_procedure_mandatory(i_lang         => i_lang,
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
                                              'CHECK_PROCEDURE_MANDATORY',
                                              o_error);
            RETURN FALSE;
    END check_procedure_mandatory;

    FUNCTION check_procedure_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN interv_prescription.id_interv_prescription%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_CONFLICT';
        IF NOT pk_procedures_external.check_procedure_conflict(i_lang         => i_lang,
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
                                              'CHECK_PROCEDURE_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_procedure_conflict;

    FUNCTION check_procedure_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN interv_presc_det.id_interv_presc_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_CANCEL';
        IF NOT pk_procedures_external.check_procedure_cancel(i_lang         => i_lang,
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
                                              'CHECK_PROCEDURE_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_procedure_cancel;

    FUNCTION cancel_procedure_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN table_number,
        i_dt_cancel        IN VARCHAR2,
        i_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        i_prof_order       IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN co_sign.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CANCEL_PROCEDURE_TASK';
        IF NOT pk_procedures_external.cancel_procedure_task(i_lang             => i_lang,
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
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_procedure_task;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_ONGOING_TASKS';
        RETURN pk_procedures_external.get_procedure_ongoing_tasks(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_patient => i_patient);
    
    END get_procedure_ongoing_tasks;

    FUNCTION suspend_procedure_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SUSPEND_PROCEDURE_TASK';
        IF NOT pk_procedures_external.suspend_procedure_task(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => i_id_task,
                                                             i_flg_reason       => i_flg_reason,
                                                             o_msg_error        => o_msg_error,
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
                                              'SUSPEND_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END suspend_procedure_task;

    FUNCTION reactivate_procedure_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.REACTIVATE_PROCEDURE_TASK';
        IF NOT pk_procedures_external.reactivate_procedure_task(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_interv_presc_det => i_id_task,
                                                                o_msg_error        => o_msg_error,
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
                                              'REACTIVATE_PROCEDURE_TASK',
                                              o_error);
            RETURN FALSE;
    END reactivate_procedure_task;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_by_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_interv  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_BY_STATUS';
        IF NOT pk_procedures_external.get_procedure_by_status(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              o_interv  => o_interv,
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
                                              'GET_PROCEDURE_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_by_status;

    PROCEDURE discharge_summary____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_technical_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_GET_TECHNICAL_PROCEDURES';
        IF NOT pk_procedures_external.get_technical_procedures(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode,
                                                               o_list    => o_list,
                                                               o_error   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GET_TECHNICAL_PROCEDURES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_technical_procedures;

    FUNCTION check_technical_procedure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_technical exam.flg_technical%TYPE;
    
    BEGIN
    
        l_flg_technical := pk_procedures_external.check_technical_procedure(i_lang             => i_lang,
                                                                            i_prof             => i_prof,
                                                                            i_interv_presc_det => i_interv_presc_det);
        RETURN l_flg_technical;
    
    END check_technical_procedure;

    PROCEDURE viewer____________________ IS
    BEGIN
        NULL;
    END;

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
                                              'GET_ORDERED_LIST',
                                              o_error);
            RETURN FALSE;
    END get_procedure_viewer_list;

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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_ORDERED_LIST_INTERNAL';
        IF NOT pk_procedures_external.get_ordered_list(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_patient      => i_patient,
                                                       i_episode      => i_episode,
                                                       i_translate    => i_translate,
                                                       i_viewer_area  => i_viewer_area,
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_ORDERED_LIST_DET';
        IF NOT pk_procedures_external.get_ordered_list_det(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_interv_presc_det => i_interv_presc_det,
                                                           o_ordered_list_det => o_ordered_list_det,
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
                                              'GET_ORDERED_LIST_DET',
                                              o_error);
            RETURN FALSE;
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_COUNT_AND_FIRST';
        IF NOT pk_procedures_external.get_count_and_first(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_patient     => i_patient,
                                                          i_episode     => i_episode,
                                                          i_viewer_area => i_viewer_area,
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

    FUNCTION get_procedure_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_VIEWER_CHECKLIST';
        RETURN pk_procedures_external.get_procedure_viewer_checklist(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_scope_type => i_scope_type,
                                                                     i_episode    => i_episode,
                                                                     i_patient    => i_patient);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_procedure_viewer_checklist;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
    BEGIN
    
        pk_procedures_external.upd_viewer_ehr_ea(i_lang => i_lang, i_prof => i_prof);
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.UPD_VIEWER_EHR_EA_PAT';
        IF NOT pk_procedures_external.upd_viewer_ehr_ea_pat(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_patient => i_patient,
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
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    PROCEDURE medication_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_procedure_with_medication
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_medication   IN NUMBER,
        i_notes        IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_WITH_MEDICATION';
        IF NOT pk_procedures_external.set_procedure_with_medication(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_patient      => i_patient,
                                                                    i_episode      => i_episode,
                                                                    i_intervention => i_intervention,
                                                                    i_flg_time     => i_flg_time,
                                                                    i_dt_begin     => i_dt_begin,
                                                                    i_medication   => i_medication,
                                                                    i_notes        => i_notes,
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
                                              'SET_PROCEDURE_WITH_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_with_medication;

    PROCEDURE progress_notes_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_in_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_order   IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_IN_EPISODE';
        IF NOT pk_procedures_external.get_procedure_in_episode(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_episode => i_episode,
                                                               i_order   => i_order,
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
                                              'GET_PROCEDURE_IN_EPISODE',
                                              o_error);
            RETURN FALSE;
    END get_procedure_in_episode;

    FUNCTION get_procedure_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_INFO';
        IF NOT pk_procedures_external.get_procedure_info(i_lang             => i_lang,
                                                         i_prof             => i_prof,
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
                                              'GET_PROCEDURE_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_info;

    FUNCTION check_procedure_revision
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.CHECK_PROCEDURE_REVISION';
        RETURN pk_procedures_external.check_procedure_revision(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_treatment => i_treatment);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_procedure_revision;

    PROCEDURE flowsheets_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets IS
    
    BEGIN
    
        RETURN pk_procedures_external.get_procedure_flowsheets(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_type_scope => i_type_scope,
                                                               i_id_scope   => i_id_scope);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_procedure_flowsheets;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_procedure_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_PROCEDURE_MATCH';
        IF NOT pk_procedures_external.set_procedure_match(i_lang         => i_lang,
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
                                              'SET_PROCEDURE_MATCH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_procedure_match;

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_procedure_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_interv     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_LIST';
        IF NOT pk_procedures_external.get_procedure_list(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_scope      => i_scope,
                                                         i_flg_scope  => i_flg_scope,
                                                         i_start_date => i_start_date,
                                                         i_end_date   => i_end_date,
                                                         i_cancelled  => i_cancelled,
                                                         i_crit_type  => i_crit_type,
                                                         o_interv     => o_interv,
                                                         o_error      => o_error)
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
                                              'GET_PROCEDURE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_procedure_list;

    FUNCTION get_procedure_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_CDA';
        IF NOT pk_procedures_external.get_procedure_cda(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_type_scope => i_type_scope,
                                                        i_id_scope   => i_id_scope,
                                                        o_proc_cda   => o_proc_cda,
                                                        o_error      => o_error)
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
                                              'GET_PROCEDURE_CDA',
                                              o_error);
            RETURN FALSE;
    END get_procedure_cda;

    FUNCTION get_procedure_detail_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_proc_det   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.GET_PROCEDURE_DETAIL_CDA';
        IF NOT pk_procedures_external.get_procedure_detail_cda(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_type_scope => i_type_scope,
                                                               i_id_scope   => i_id_scope,
                                                               o_proc_det   => o_proc_det,
                                                               o_error      => o_error)
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
                                              'GET_PROCEDURE_DETAIL_CDA',
                                              o_error);
            RETURN FALSE;
    END get_procedure_detail_cda;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.RESET_PROCEDURES';
        IF NOT pk_procedures_external.reset_procedures(i_lang    => i_lang,
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
                                              'RESET_PROCEDURES',
                                              o_error);
            RETURN FALSE;
    END reset_procedures;

    PROCEDURE system__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION inactivate_procedures_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
    
        IF NOT pk_procedures_external.inactivate_procedures_tasks(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_inst        => i_inst,
                                                                  i_ids_exclude => l_tbl_ids,
                                                                  o_has_error   => o_has_error,
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
                                              'INACTIVATE_PROCEDURES_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_procedures_tasks;

    FUNCTION set_grid_task_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL.SET_GRID_TASK_PROCEDURES';
        IF NOT pk_procedures_external.set_grid_task_procedures(i_lang    => i_lang,
                                                               i_prof    => i_prof,
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
                                              'SET_GRID_TASK_PROCEDURES',
                                              o_error);
            RETURN FALSE;
    END set_grid_task_procedures;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_external_api_db;
/
