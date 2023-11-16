/*-- Last Change Revision: $Rev: 2027142 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:17 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exams_external_api_db IS

    PROCEDURE episode___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_for_episode_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_for_episode_timeline(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              i_type    => i_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_for_episode_timeline;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_listview
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_type    IN exam.flg_type%TYPE,
        i_flg_all_exam IN VARCHAR2 DEFAULT 'N',
        i_scope        IN NUMBER DEFAULT NULL,
        i_flg_scope    IN VARCHAR2 DEFAULT '',
        i_start_date   IN VARCHAR2 DEFAULT NULL,
        i_end_date     IN VARCHAR2 DEFAULT NULL,
        i_cancelled    IN VARCHAR2 DEFAULT NULL,
        i_crit_type    IN VARCHAR2 DEFAULT 'A',
        i_flg_status   IN table_varchar DEFAULT NULL,
        i_flg_rep      IN VARCHAR2 DEFAULT 'N',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_LISTVIEW';
        IF NOT pk_exam_external.get_exam_listview(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_patient,
                                                  i_episode      => i_episode,
                                                  i_exam_type    => i_exam_type,
                                                  i_flg_all_exam => i_flg_all_exam,
                                                  i_scope        => i_scope,
                                                  i_flg_scope    => i_flg_scope,
                                                  i_start_date   => i_start_date,
                                                  i_end_date     => i_end_date,
                                                  i_cancelled    => i_cancelled,
                                                  i_crit_type    => i_crit_type,
                                                  i_flg_status   => i_flg_status,
                                                  i_flg_rep      => i_flg_rep,
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
                                              'GET_EXAM_LISTVIEW',
                                              o_error);
            RETURN FALSE;
    END get_exam_listview;

    FUNCTION get_exam_orders
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_type               IN exam.flg_type%TYPE,
        i_flg_location            IN exam_req_det.flg_location%TYPE,
        i_flg_reports             IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_ORDERS';
        IF NOT pk_exam_external.get_exam_orders(i_lang                    => i_lang,
                                                i_prof                    => i_prof,
                                                i_episode                 => i_episode,
                                                i_exam_type               => i_exam_type,
                                                i_flg_location            => i_flg_location,
                                                i_flg_reports             => i_flg_reports,
                                                o_list                    => o_list,
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
                                              'GET_EXAM_ORDERS',
                                              o_error);
            RETURN FALSE;
    END get_exam_orders;

    FUNCTION get_exam_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_RESULT_LIST';
        IF NOT pk_exam_external.get_exam_result_list(i_lang    => i_lang,
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
                                              'GET_EXAM_RESULTS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_result_list;

    FUNCTION get_exam_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
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
                                                i_flg_report              => i_flg_report,
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
        i_flg_report              IN VARCHAR2 DEFAULT pk_exam_constant.g_no,
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
                                                        i_flg_report              => i_flg_report,
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
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail_history;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.TF_GET_PRINT_JOB_INFO';
        RETURN pk_exam_external.tf_get_print_job_info(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_id_print_list_job => i_id_print_list_job);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_get_print_job_info;

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_compare_print_jobs(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_print_job_context_data => i_print_job_context_data,
                                                      i_tbl_print_list_jobs    => i_tbl_print_list_jobs);
    END tf_compare_print_jobs;

    FUNCTION get_exam_in_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN print_list_job.context_data%TYPE IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_in_print_list(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_print_list_job => i_print_list_job);
    END get_exam_in_print_list;

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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.ADD_PRINT_LIST_JOBS';
        IF NOT pk_exam_external.add_print_list_jobs(i_lang            => i_lang,
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

    FUNCTION get_exam_print_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN exam.flg_type%TYPE,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_PRINT_LIST';
        IF NOT pk_exam_external.get_exam_print_list(i_lang     => i_lang,
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

    FUNCTION tf_get_exam_to_print
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_varchar
    ) RETURN table_varchar IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_get_exam_to_print(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_exam_req_det => i_exam_req_det);
    END tf_get_exam_to_print;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_description(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_exam_req_det => i_exam_req_det,
                                                     i_co_sign_hist => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_description;

    FUNCTION get_exam_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_instructions(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_exam_req_det => i_exam_req_det,
                                                      i_co_sign_hist => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_instructions;

    FUNCTION get_exam_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_action_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_exam_req_det => i_exam_req_det,
                                                     i_action       => i_action,
                                                     i_co_sign_hist => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_action_desc;

    FUNCTION get_exam_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_date_to_order(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_exam_req_det => i_exam_req_det,
                                                       i_co_sign_hist => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_id_content
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_exam IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_id_content(i_lang => i_lang, i_prof => i_prof, i_exam => i_exam);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_exam_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_exam_external.get_alias_translation(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_content       => i_content,
                                                      i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION check_exam_cdr
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN VARCHAR2,
        i_date         IN exam_req.dt_begin_tstz%TYPE,
        o_exam_req_det OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_CDR';
        IF NOT pk_exam_external.check_exam_cdr(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_date         => i_date,
                                               i_exam         => i_exam,
                                               o_exam_req_det => o_exam_req_det,
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
                                              'CHECK_EXAM_CDR',
                                              o_error);
            RETURN FALSE;
    END check_exam_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_exam_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_exam_req_det   IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_laterality IN exam_req_det.flg_laterality%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.UPDATE_EXAM_LATERALITY';
        IF NOT pk_exam_external.update_exam_laterality(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_exam_req_det   => i_exam_req_det,
                                                       i_flg_laterality => i_flg_laterality,
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
                                              'UPDATE_EXAM_LATERALITY',
                                              o_error);
            RETURN FALSE;
    END update_exam_laterality;

    FUNCTION update_exam_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        i_exec_institution IN exam_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.UPDATE_EXAM_INSTITUTION';
        IF NOT pk_exam_external.update_exam_institution(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_exam_req_det     => i_exam_req_det,
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
                                              'UPDATE_EXAM_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_exam_institution;

    FUNCTION update_exam_referral
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_referral IN exam_req_det.flg_referral%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.UPDATE_EXAM_REFERRAL';
        IF NOT pk_exam_external.update_exam_referral(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_exam_req_det => i_exam_req_det,
                                                     i_flg_referral => i_flg_referral,
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
                                              'UPDATE_EXAM_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_exam_referral;

    FUNCTION get_exam_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_exam_external.t_cur_exam_result,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_LISTVIEW';
        IF NOT pk_exam_external.get_exam_listview(i_lang    => i_lang,
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
                                              'GET_EXAM_LISTVIEW',
                                              o_error);
            RETURN FALSE;
    END get_exam_listview;

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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.COPY_EXAM_TO_DRAFT';
        IF NOT pk_exam_external.copy_exam_to_draft(i_lang                 => i_lang,
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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_DRAFT_CONFLICT';
        IF NOT pk_exam_external.check_exam_draft_conflict(i_lang         => i_lang,
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
        g_exception_error EXCEPTION;
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_DRAFT';
        IF NOT pk_exam_external.check_exam_draft(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_episode   => i_episode,
                                                 o_has_draft => o_has_draft,
                                                 o_error     => o_error)
        THEN
            RAISE g_exception_error;
        END IF;
    
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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_DRAFT_ACTIVATION';
        IF NOT pk_exam_external.set_exam_draft_activation(i_lang          => i_lang,
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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CANCEL_EXAM_DRAFT';
        IF NOT pk_exam_external.cancel_exam_draft(i_lang    => i_lang,
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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CANCEL_EXAM_ALL_DRAFTS';
        IF NOT pk_exam_external.cancel_exam_all_drafts(i_lang    => i_lang,
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
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_LIST';
        IF NOT pk_exam_external.get_exam_task_list(i_lang            => i_lang,
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
                                                   i_cpoe_tab        => i_cpoe_tab,
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
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_ACTIONS';
        IF NOT pk_exam_external.get_exam_actions(i_lang         => i_lang,
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

    PROCEDURE order_sets_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_exam_req_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_REQ_DET';
        IF NOT pk_exam_external.get_exam_req_det(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_task_request => i_task_request,
                                                 o_exam_req_det => o_exam_req_det,
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
                                              'GET_EXAM_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_exam_req_det;

    FUNCTION get_exam_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_TITLE';
        IF NOT pk_exam_external.get_exam_task_title(i_lang             => i_lang,
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
                                              'GET_EXAM_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_title;

    FUNCTION get_exam_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN exam_req.id_exam_req%TYPE,
        i_task_request_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT 'Y',
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_TASK_INSTRUCTIONS';
        IF NOT pk_exam_external.get_exam_task_instructions(i_lang              => i_lang,
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
                                              'GET_EXAM_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_instructions;

    FUNCTION get_exam_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN tde_task_dependency.id_task_request%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_TASK_EXAMS_DESCRIPTION';
        IF NOT pk_exam_external.get_exam_task_description(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_exam_req_det  => i_task_request,
                                                          o_exams_desc       => o_task_desc,
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
                                              'GET_TASK_EXAMS_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_description;

    FUNCTION get_exam_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_STATUS';
        IF NOT pk_exam_external.get_exam_status(i_lang          => i_lang,
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
                                              'GET_EXAM_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_exam_status;

    FUNCTION get_exam_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_QUESTIONNAIRE';
        IF NOT pk_exam_external.get_exam_questionnaire(i_lang         => i_lang,
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
                                              'GET_EXAM_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
    END get_exam_questionnaire;

    FUNCTION get_exam_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_DATE_LIMITS';
        IF NOT pk_exam_external.get_exam_date_limits(i_lang         => i_lang,
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
                                              'GET_EXAM_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_exam_date_limits;

    FUNCTION get_exam_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN exam_req.id_exam_req%TYPE,
        i_task_request_det IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_id          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_ID';
        IF NOT pk_exam_external.get_exam_task_id(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_task_request     => i_task_request,
                                                 i_task_request_det => i_task_request_det,
                                                 o_exam_id          => o_exam_id,
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
                                              'GET_EXAM_ID',
                                              o_error);
            RETURN FALSE;
    END get_exam_id;

    FUNCTION set_exam_request_task
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
        i_clinical_decision_rule  IN exam_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_exam_req                OUT table_number,
        o_exam_req_det            OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_REQUEST_TASK';
        IF NOT pk_exam_external.set_exam_request_task(i_lang                    => i_lang,
                                                      i_prof                    => i_prof,
                                                      i_task_request            => i_task_request,
                                                      i_prof_order              => i_prof_order,
                                                      i_dt_order                => i_dt_order,
                                                      i_order_type              => i_order_type,
                                                      i_clinical_question       => i_clinical_question,
                                                      i_response                => i_response,
                                                      i_clinical_question_notes => i_clinical_question_notes,
                                                      i_clinical_decision_rule  => i_clinical_decision_rule,
                                                      i_task_dependency         => i_task_dependency,
                                                      i_flg_task_dependency     => i_flg_task_dependency,
                                                      o_exam_req                => o_exam_req,
                                                      o_exam_req_det            => o_exam_req_det,
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
                                              'SET_EXAM_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_request_task;

    FUNCTION set_exam_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_exam_req     OUT exam_req.id_exam_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_COPY_TASK';
        IF NOT pk_exam_external.set_exam_copy_task(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_patient      => i_patient,
                                                   i_episode      => i_episode,
                                                   i_task_request => i_task_request,
                                                   o_exam_req     => o_exam_req,
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
                                              'SET_EXAM_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_copy_task;

    FUNCTION set_exam_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_DELETE_TASK';
        IF NOT pk_exam_external.set_exam_delete_task(i_lang         => i_lang,
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
                                              'SET_EXAM_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_exam_delete_task;

    FUNCTION set_exam_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_DIAGNOSIS';
        IF NOT pk_exam_external.set_exam_diagnosis(i_lang         => i_lang,
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
                                              'SET_EXAM_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_exam_diagnosis;

    FUNCTION set_exam_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_EXECUTE_TIME';
        IF NOT pk_exam_external.set_exam_execute_time(i_lang         => i_lang,
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
                                              'SET_EXAM_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_exam_execute_time;

    FUNCTION check_exam_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_MANDATORY_FIELD';
        IF NOT pk_exam_external.check_exam_mandatory_field(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_task_request => i_task_request,
                                                           o_check        => o_check,
                                                           o_error        => o_error)
        THEN
            dbms_output.put_line('> ' || SQLCODE || ' - ' || SQLERRM);
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAM_MANDATORY_FIELD',
                                              o_error);
            RETURN FALSE;
    END check_exam_mandatory_field;

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN exam_req.id_exam_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_CONFLICT';
        IF NOT pk_exam_external.check_exam_conflict(i_lang         => i_lang,
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
                                              'CHECK_EXAM_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_exam_conflict;

    FUNCTION check_exam_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN exam_req_det.id_exam_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_CANCEL';
        IF NOT pk_exam_external.check_exam_cancel(i_lang         => i_lang,
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
                                              'CHECK_EXAM_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_exam_cancel;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_exam_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam         IN exam.id_exam%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CHECK_EXAM_CONFLICT';
        IF NOT pk_exam_external.check_exam_conflict(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_exam         => i_exam,
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
                                              'CHECK_EXAM_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_exam_conflict;

    FUNCTION get_exam_cancel_permission
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_CANCEL_PERMISSION';
        IF NOT pk_exam_external.get_exam_cancel_permission(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_id_exam_req_det => i_task_request,
                                                           o_flg_cancel      => o_flg_cancel,
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
                                              'GET_EXAM_CANCEL_PERMISSION',
                                              o_error);
            RETURN FALSE;
    END get_exam_cancel_permission;

    FUNCTION start_exam_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.START_EXAM_TASK_REQ';
        IF NOT pk_exam_external.start_exam_task_req(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_task_request => i_task_request,
                                                    i_start_tstz   => i_start_tstz,
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
                                              'START_EXAM_TASK_REQ',
                                              o_error);
            RETURN FALSE;
    END start_exam_task_req;

    FUNCTION cancel_exam_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_request   IN tde_task_dependency.id_task_request%TYPE,
        i_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes   IN VARCHAR2,
        i_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order       IN VARCHAR2,
        i_order_type     IN co_sign.id_order_type%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.CANCEL_EXAM_TASK';
        IF NOT pk_exam_external.cancel_exam_task(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_task_request   => i_task_request,
                                                 i_reason         => i_reason,
                                                 i_reason_notes   => i_reason_notes,
                                                 i_prof_order     => i_prof_order,
                                                 i_dt_order       => i_dt_order,
                                                 i_order_type     => i_order_type,
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
                                              'CANCEL_EXAM_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_exam_task;

    FUNCTION get_exam_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_ONGOING_TASKS';
        RETURN pk_exam_external.get_exam_ongoing_tasks(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
    END get_exam_ongoing_tasks;

    FUNCTION suspend_exam_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SUSPEND_EXAM_TASK';
        IF NOT pk_exam_external.suspend_exam_task(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_task    => i_id_task,
                                                  i_flg_reason => i_flg_reason,
                                                  o_msg_error  => o_msg_error,
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
                                              'SUSPEND_EXAM_TASK',
                                              o_error);
            RETURN FALSE;
    END suspend_exam_task;

    FUNCTION reactivate_exam_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.REACTIVATE_EXAM_TASK';
        IF NOT pk_exam_external.reactivate_exam_task(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_id_task   => i_id_task,
                                                     o_msg_error => o_msg_error,
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
                                              'REACTIVATE_EXAM_TASK',
                                              o_error);
            RETURN FALSE;
    END reactivate_exam_task;

    FUNCTION get_exam_task_execute_time
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN tde_task_dependency.id_task_request%TYPE,
        o_flg_time      OUT VARCHAR2,
        o_flg_time_desc OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_TASK_EXAMS_DESCRIPTION';
        IF NOT pk_exam_external.get_exam_task_execute_time(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_id_exam_req_det => i_task_request,
                                                           o_flg_time        => o_flg_time,
                                                           o_flg_time_desc   => o_flg_time_desc,
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
                                              'GET_EXAM_TASK_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END get_exam_task_execute_time;

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.UPDATE_TDE_TASK_STATE';
        IF NOT pk_exam_external.update_tde_task_state(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_exam_req_det    => i_exam_req_det,
                                                      i_flg_action      => i_flg_action,
                                                      i_task_dependency => i_task_dependency,
                                                      i_reason          => i_reason,
                                                      i_reason_notes    => i_reason_notes,
                                                      i_transaction_id  => i_transaction_id,
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
                                              'UPDATE_TDE_TASK_STATE',
                                              o_error);
            RETURN FALSE;
    END update_tde_task_state;

    PROCEDURE single_page________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE,
        o_exam_req_det     OUT exam_req_det.id_exam_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_REQ_DET_BY_ID_RECURR';
        IF NOT pk_exam_external.get_exam_req_det_by_id_recurr(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_order_recurrence => i_order_recurrence,
                                                              o_exam_req_det     => o_exam_req_det,
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
                                              'GET_EXAM_REQ_DET_BY_ID_RECURR',
                                              o_error);
            RETURN FALSE;
    END get_exam_req_det_by_id_recurr;

    FUNCTION get_exam_result_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam_result IN exam_result.id_exam_result%TYPE,
        i_flg_image_exam IN pk_types.t_flg_char,
        o_description    OUT CLOB,
        o_notes_result   OUT CLOB,
        o_result_notes   OUT CLOB,
        o_interpretation OUT CLOB,
        o_exec_date      OUT exam_req_det.start_time%TYPE,
        o_result         OUT pk_translation.t_desc_translation,
        o_report_date    OUT exam_req.dt_req_tstz%TYPE,
        o_inst_name      OUT CLOB,
        o_result_date    OUT exam_result.dt_exam_result_tstz%TYPE,
        o_exam_desc      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_RESULTS';
        IF NOT pk_exam_external.get_exam_result_desc(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_exam_result => i_id_exam_result,
                                                     i_flg_image_exam => i_flg_image_exam,
                                                     o_description    => o_description,
                                                     o_notes_result   => o_notes_result,
                                                     o_result_notes   => o_result_notes,
                                                     o_interpretation => o_interpretation,
                                                     o_exec_date      => o_exec_date,
                                                     o_result         => o_result,
                                                     o_report_date    => o_report_date,
                                                     o_inst_name      => o_inst_name,
                                                     o_result_date    => o_result_date,
                                                     o_exam_desc      => o_exam_desc,
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
                                              'GET_EXAM_RESULTS',
                                              o_error);
            RETURN FALSE;
    END get_exam_result_desc;

    FUNCTION get_exam_status_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_status          OUT CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_RESULTS';
        IF NOT pk_exam_external.get_exam_status_desc(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_exam_req_det => i_id_exam_req_det,
                                                     o_status          => o_status,
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
                                              'GET_EXAM_STATUS_DESC',
                                              o_error);
            RETURN FALSE;
    END get_exam_status_desc;

    FUNCTION get_alias_code_translation
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN exam_alias.code_exam_alias%TYPE IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_UTILS.GET_ALIAS_CODE_TRANSLATION';
        RETURN pk_exam_utils.get_alias_code_translation(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_code_exam     => i_code_exam,
                                                        i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation;

    PROCEDURE pregnancy_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_exam_pregnancy_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exam_req_det    IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_last_result IN VARCHAR2 DEFAULT pk_exam_constant.g_no
    ) RETURN t_tbl_exams_pregnancy_result IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.TF_EXAM_PREGNANCY_INFO';
        RETURN pk_exam_external.tf_exam_pregnancy_info(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_exam_req_det    => i_exam_req_det,
                                                       i_flg_last_result => i_flg_last_result);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_exam_pregnancy_info;

    FUNCTION tf_exam_pregnancy_result_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam_result IN exam_result.id_exam_result%TYPE
    ) RETURN t_tbl_exams_pregnancy_result IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.TF_EXAM_PREGNANCY_RESULT_INFO';
        RETURN pk_exam_external.tf_exam_pregnancy_result_info(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_exam_result => i_exam_result);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_exam_pregnancy_result_info;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN exam.flg_type%TYPE,
        o_exam     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_BY_STATUS';
        IF NOT pk_exam_external.get_exam_by_status(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_episode  => i_episode,
                                                   i_flg_type => i_flg_type,
                                                   o_exam     => o_exam,
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
                                              'GET_EXAM_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            RETURN FALSE;
    END get_exam_by_status;

    PROCEDURE discharge_summary____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_technical_exam
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_technical exam.flg_technical%TYPE;
    
    BEGIN
    
        l_flg_technical := pk_exam_external.check_technical_exam(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_exam_req_det => i_exam_req_det);
        RETURN l_flg_technical;
    
    END check_technical_exam;

    FUNCTION get_exam_exec_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_exec_date VARCHAR2(50);
    
    BEGIN
    
        l_exec_date := pk_exam_external.get_exam_exec_date(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_exam_req_det => i_exam_req_det);
    
        RETURN l_exec_date;
    
    END get_exam_exec_date;

    PROCEDURE flowsheets________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_flowsheets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER
    ) RETURN t_coll_mcdt_flowsheets IS
        l_error t_error_out;
    BEGIN
    
        RETURN pk_exam_external.get_exam_flowsheets(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_type_scope => i_type_scope,
                                                    i_id_scope   => i_id_scope);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_FLOWSHEETS',
                                              l_error);
            RETURN NULL;
    END get_exam_flowsheets;

    PROCEDURE scheduler_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_exam_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        i_status   IN exam_req.flg_status%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_STATUS';
        IF NOT pk_exam_external.set_exam_status(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                i_exam_req => i_exam_req,
                                                i_status   => i_status,
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
                                              'SET_EXAM_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_exam_status;

    FUNCTION get_exam_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_market         IN market.id_market%TYPE,
        i_pat_search_values IN pk_utils.hashtable_pls_integer,
        i_ids_content       IN table_varchar,
        i_min_date          IN VARCHAR2,
        i_max_date          IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_ids_prof          IN table_number,
        i_ids_exam_cat      IN table_number,
        i_priorities        IN table_varchar,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_SEARCH';
        IF NOT pk_exam_external.get_exam_search(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_market         => i_id_market,
                                                i_pat_search_values => i_pat_search_values,
                                                i_ids_content       => i_ids_content,
                                                i_min_date          => i_min_date,
                                                i_max_date          => i_max_date,
                                                i_id_cancel_reason  => i_id_cancel_reason,
                                                i_ids_prof          => i_ids_prof,
                                                i_ids_exam_cat      => i_ids_exam_cat,
                                                i_priorities        => i_priorities,
                                                o_list              => o_list,
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
                                              'GET_EXAM_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_search;

    FUNCTION get_exam_request_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_type      IN exam.flg_type%TYPE DEFAULT NULL,
        i_id_content    IN exam.id_content%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_exam_external.t_cur_exam_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAM_REQUEST_TO_SCHEDULE';
        IF NOT pk_exam_external.get_exam_request_to_schedule(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_institution   => i_institution,
                                                             i_patient       => i_patient,
                                                             i_flg_type      => i_flg_type,
                                                             i_id_content    => i_id_content,
                                                             i_id_department => i_id_department,
                                                             i_pat_age_min   => i_pat_age_min,
                                                             i_pat_age_max   => i_pat_age_max,
                                                             i_pat_gender    => i_pat_gender,
                                                             i_start         => i_start,
                                                             i_offset        => i_offset,
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
                                              'GET_EXAM_REQUEST_TO_SCHEDULE',
                                              o_error);
        
            RETURN FALSE;
    END get_exam_request_to_schedule;

    FUNCTION is_exam_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN exam_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.IS_EXAM_RECURR_FINISHED';
        RETURN pk_exam_external.is_exam_recurr_finished(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_order_recurrence => i_order_recurrence);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END is_exam_recurr_finished;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION e_get_order_rank
    (
        i_flg_status        IN exam_req_det.flg_status%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE,
        i_id_episode_origin IN exam_req.id_episode_origin%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.E_GET_ORDER_RANK';
        RETURN pk_exam_external.e_get_order_rank(i_flg_status        => i_flg_status,
                                                 i_flg_time          => i_flg_time,
                                                 i_dt_begin          => i_dt_begin,
                                                 i_id_episode_origin => i_id_episode_origin);
    
    END e_get_order_rank;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_ORDERED_LIST_INTERNAL';
        IF NOT pk_exam_external.get_ordered_list(i_lang         => i_lang,
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exam_req_det     IN exam_req_det.id_exam_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_ORDERED_LIST_DET';
        IF NOT pk_exam_external.get_ordered_list_det(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_exam_req_det     => i_exam_req_det,
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
            pk_types.open_my_cursor(o_ordered_list_det);
            RETURN FALSE;
    END get_ordered_list_det;

    FUNCTION get_count_and_first
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_num_occur   OUT NUMBER,
        o_desc_first  OUT VARCHAR2,
        o_code_first  OUT VARCHAR2,
        o_dt_first    OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_COUNT_AND_FIRST';
        IF NOT pk_exam_external.get_count_and_first(i_lang        => i_lang,
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

    /*
    *  Get current state of imaging exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit
    * @param     i_episode      Episode id
    * @param     i_patient      Patient id
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */
    FUNCTION get_imaging_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_IMAGING_VIEWER_CHECKLIST';
        RETURN pk_exam_external.get_imaging_viewer_checklist(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_scope_type => i_scope_type,
                                                             i_episode    => i_episode,
                                                             i_patient    => i_patient);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_imaging_viewer_checklist;

    /*
    *  Get current state of other exams for viewer checlist 
    *             
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_scope_type   Scope flag: 'P' - Patient; 'E' - Episode; 'V' - Visit
    * @param     i_episode      Episode id
    * @param     i_patient      Patient id
    *
    * @return    String
    * 
    * @author    Ana Matos
    * @version   2.7.0
    * @since     2016/10/27                         
    */
    FUNCTION get_exams_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.GET_EXAMS_VIEWER_CHECKLIST';
        RETURN pk_exam_external.get_exams_viewer_checklist(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_scope_type => i_scope_type,
                                                           i_episode    => i_episode,
                                                           i_patient    => i_patient);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_exams_viewer_checklist;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
    BEGIN
    
        pk_exam_external.upd_viewer_ehr_ea(i_lang => i_lang, i_prof => i_prof);
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.UPD_VIEWER_EHR_EA_PAT';
        IF NOT pk_exam_external.upd_viewer_ehr_ea_pat(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_table_id_patients => i_table_id_patients,
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
                                              'UPD_VIEWER_EHR_EA_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_viewer_ehr_ea_pat;

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_exam_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_scope IN VARCHAR2,
        i_id_scope   IN NUMBER,
        o_exam_cda   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_exam_external.get_exam_cda(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_type_scope => i_type_scope,
                                             i_id_scope   => i_id_scope,
                                             o_exam_cda   => o_exam_cda,
                                             o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_CDA',
                                              o_error);
            RETURN FALSE;
    END get_exam_cda;

    PROCEDURE crisis_machine_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_cm_imaging_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_cm_imaging_episodes(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_search_interval => i_search_interval);
    
    END tf_cm_imaging_episodes;

    FUNCTION tf_cm_imaging_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_imaging_episodes IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_cm_imaging_episode_detail(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_episode  => i_episode,
                                                             i_schedule => i_schedule);
    END tf_cm_imaging_episode_detail;

    FUNCTION tf_cm_exams_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_cm_exams_episodes(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_search_interval => i_search_interval);
    
    END tf_cm_exams_episodes;

    FUNCTION tf_cm_exams_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_other_exams_episodes IS
    
    BEGIN
    
        RETURN pk_exam_external.tf_cm_exams_episode_detail(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_episode  => i_episode,
                                                           i_schedule => i_schedule);
    
    END tf_cm_exams_episode_detail;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_exam_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.SET_EXAM_MATCH';
        IF NOT pk_exam_external.set_exam_match(i_lang         => i_lang,
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
                                              'SET_EXAM_MATCH',
                                              o_error);
            RETURN FALSE;
    END set_exam_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_exams
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAM_EXTERNAL.RESET_EXAMS';
        IF NOT pk_exam_external.reset_exams(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_patient      => i_patient,
                                            i_episode      => i_episode,
                                            io_transaction => io_transaction,
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
                                              'RESET_EXAMS',
                                              o_error);
            RETURN FALSE;
    END reset_exams;

    PROCEDURE system__________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE process_exam_pending IS
    BEGIN
        pk_exam_external.process_exam_pending;
    END;

    FUNCTION inactivate_exams_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        i_flg_type  IN exam.flg_type%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
    
        IF NOT pk_exam_external.inactivate_exams_tasks(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_inst        => i_inst,
                                                       i_flg_type    => i_flg_type,
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
                                              'INACTIVATE_EXAMS_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_exams_tasks;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exams_external_api_db;
/
