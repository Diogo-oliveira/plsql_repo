/*-- Last Change Revision: $Rev: 2027310 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_external_api_db IS

    PROCEDURE episode___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_for_episode_timeline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_for_episode_timeline(i_lang    => i_lang,
                                                                       i_prof    => i_prof,
                                                                       i_episode => i_episode,
                                                                       i_type    => i_type);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_for_episode_timeline;

    PROCEDURE reports___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_tests_listview
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TESTS_LISTVIEW';
        IF NOT pk_lab_tests_external.get_lab_tests_listview(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_patient    => i_patient,
                                                            i_episode    => i_episode,
                                                            i_scope      => i_scope,
                                                            i_flg_scope  => i_flg_scope,
                                                            i_start_date => i_start_date,
                                                            i_end_date   => i_end_date,
                                                            i_cancelled  => i_cancelled,
                                                            i_crit_type  => i_crit_type,
                                                            o_list       => o_list,
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
                                              'GET_LAB_TESTS_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_tests_listview;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        i_flg_report       IN VARCHAR2,
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_external.get_lab_test_resultsview(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_patient          => i_patient,
                                                              i_visit            => i_visit,
                                                              i_episode          => i_episode,
                                                              i_analysis_req_det => i_analysis_req_det,
                                                              i_flg_type         => i_flg_type,
                                                              i_dt_min           => i_dt_min,
                                                              i_dt_max           => i_dt_max,
                                                              i_flg_report       => i_flg_report,
                                                              o_list             => o_list,
                                                              o_result_list      => o_result_list,
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
                                              'GET_LAB_TEST_RESULTSVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_resultsview;

    FUNCTION get_reports_table1
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_column_number IN NUMBER,
        i_episode       IN episode.id_episode%TYPE,
        i_visit         IN visit.id_visit%TYPE,
        i_crit_type     IN VARCHAR2 DEFAULT 'A',
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        o_list_columns  OUT pk_types.cursor_type,
        o_list_rows     OUT pk_types.cursor_type,
        o_list_values   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_REPORTS_TABLE1';
        IF NOT pk_lab_tests_external.get_reports_table1(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_patient       => i_patient,
                                                        i_column_number => i_column_number,
                                                        i_episode       => i_episode,
                                                        i_visit         => i_visit,
                                                        i_crit_type     => i_crit_type,
                                                        i_start_date    => i_start_date,
                                                        i_end_date      => i_end_date,
                                                        o_list_columns  => o_list_columns,
                                                        o_list_rows     => o_list_rows,
                                                        o_list_values   => o_list_values,
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
                                              'GET_REPORTS_TABLE1',
                                              o_error);
            pk_types.open_my_cursor(o_list_columns);
            pk_types.open_my_cursor(o_list_rows);
            pk_types.open_my_cursor(o_list_values);
            RETURN FALSE;
    END get_reports_table1;

    FUNCTION get_reports_table2
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_visit              IN visit.id_visit%TYPE,
        i_crit_type          IN VARCHAR2 DEFAULT 'A',
        i_start_date         IN VARCHAR2,
        i_end_date           IN VARCHAR2,
        o_list_columns       OUT pk_types.cursor_type,
        o_list_rows          OUT pk_types.cursor_type,
        o_list_values        OUT pk_types.cursor_type,
        o_list_minmax_values OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_REPORTS_TABLE2';
        IF NOT pk_lab_tests_external.get_reports_table2(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_patient            => i_patient,
                                                        i_episode            => i_episode,
                                                        i_visit              => i_visit,
                                                        i_crit_type          => i_crit_type,
                                                        i_start_date         => i_start_date,
                                                        i_end_date           => i_end_date,
                                                        o_list_columns       => o_list_columns,
                                                        o_list_rows          => o_list_rows,
                                                        o_list_values        => o_list_values,
                                                        o_list_minmax_values => o_list_minmax_values,
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
                                              'GET_REPORTS_TABLE2',
                                              o_error);
            pk_types.open_my_cursor(o_list_columns);
            pk_types.open_my_cursor(o_list_rows);
            pk_types.open_my_cursor(o_list_values);
            pk_types.open_my_cursor(o_list_minmax_values);
            RETURN FALSE;
    END get_reports_table2;

    FUNCTION get_reports_counter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_visit      IN visit.id_visit%TYPE,
        i_crit_type  IN VARCHAR2 DEFAULT 'A',
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_counter    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_REPORTS_COUNTER';
        IF NOT pk_lab_tests_external.get_reports_counter(i_lang       => i_lang,
                                                         i_prof       => i_prof,
                                                         i_patient    => i_patient,
                                                         i_episode    => i_episode,
                                                         i_visit      => i_visit,
                                                         i_crit_type  => i_crit_type,
                                                         i_start_date => i_start_date,
                                                         i_end_date   => i_end_date,
                                                         o_counter    => o_counter,
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
                                              'GET_REPORTS_COUNTER',
                                              o_error);
            RETURN FALSE;
    END get_reports_counter;

    FUNCTION get_lab_tests_orders
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_location          IN VARCHAR2,
        i_flg_reports           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_list                  OUT pk_types.cursor_type,
        o_lt_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TESTS_ORDERS';
        IF NOT pk_lab_tests_external.get_lab_tests_orders(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_episode               => i_episode,
                                                          i_flg_location          => i_flg_location,
                                                          i_flg_reports           => i_flg_reports,
                                                          o_list                  => o_list,
                                                          o_lt_clinical_questions => o_lt_clinical_questions,
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
                                              'GET_LAB_TEST_ORDERS',
                                              o_error);
            RETURN FALSE;
    END get_lab_tests_orders;

    FUNCTION get_lab_test_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_report       IN VARCHAR2 DEFAULT pk_lab_tests_constant.g_no,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_CO_SIGN';
        IF NOT pk_lab_tests_external.get_lab_test_co_sign(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_episode          => i_episode,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          i_flg_report       => i_flg_report,
                                                          o_lab_test_co_sign => o_lab_test_co_sign,
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
                                              'GET_LAB_TEST_CO_SIGN',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_co_sign;

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
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_external.get_lab_test_detail(i_lang                        => i_lang,
                                                         i_prof                        => i_prof,
                                                         i_episode                     => i_episode,
                                                         i_analysis_req_det            => i_analysis_req_det,
                                                         i_flg_report                  => i_flg_report,
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
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_external.get_lab_test_detail_history(i_lang                        => i_lang,
                                                                 i_prof                        => i_prof,
                                                                 i_episode                     => i_episode,
                                                                 i_analysis_req_det            => i_analysis_req_det,
                                                                 i_flg_report                  => i_flg_report,
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

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_HARVEST_BARCODE_FOR_PRINT';
        RETURN pk_lab_tests_external.get_harvest_barcode_for_print(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_harvest => i_harvest);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_harvest_barcode_for_print;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.TF_CM_LAB_EPISODES';
        RETURN pk_lab_tests_external.tf_get_print_job_info(i_lang              => i_lang,
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
    
        RETURN pk_lab_tests_external.tf_compare_print_jobs(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_print_job_context_data => i_print_job_context_data,
                                                           i_tbl_print_list_jobs    => i_tbl_print_list_jobs);
    END tf_compare_print_jobs;

    FUNCTION get_lab_test_in_print_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN print_list_job.context_data%TYPE IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_in_print_list(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_print_list_job => i_print_list_job);
    END get_lab_test_in_print_list;

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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.ADD_PRINT_LIST_JOBS';
        IF NOT pk_lab_tests_external.add_print_list_jobs(i_lang             => i_lang,
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

    FUNCTION get_lab_test_print_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_PRINT_LIST';
        IF NOT pk_lab_tests_external.get_lab_test_print_list(i_lang    => i_lang,
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

    FUNCTION tf_get_lab_test_to_print
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_varchar
    ) RETURN table_varchar IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.tf_get_lab_test_to_print(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_analysis_req_det => i_analysis_req_det);
    END tf_get_lab_test_to_print;

    PROCEDURE pdms_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_tests_allowed
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_context IN CLOB
    ) RETURN NUMBER IS
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TESTS_ALLOWED';
        RETURN pk_lab_tests_external.get_lab_tests_allowed(i_lang => i_lang, i_prof => i_prof, i_context => i_context);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_lab_tests_allowed;

    FUNCTION get_lab_test_pdmsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_result_gridview  OUT pk_types.cursor_type,
        o_result_graphview OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_CDR';
        IF NOT pk_lab_tests_external.get_lab_test_pdmsview(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_patient          => i_patient,
                                                           i_visit            => i_visit,
                                                           i_analysis_req_det => i_analysis_req_det,
                                                           i_flg_type         => i_flg_type,
                                                           i_dt_min           => i_dt_min,
                                                           i_dt_max           => i_dt_max,
                                                           o_result_gridview  => o_result_gridview,
                                                           o_result_graphview => o_result_graphview,
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
                                              'GET_LAB_TEST_PDMSVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_result_gridview);
            pk_types.open_my_cursor(o_result_graphview);
            RETURN FALSE;
    END get_lab_test_pdmsview;

    PROCEDURE co_sign___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_description(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_analysis_req_det => i_analysis_req_det,
                                                              i_co_sign_hist     => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_description;

    FUNCTION get_lab_test_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_instructions(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_analysis_req_det => i_analysis_req_det,
                                                               i_co_sign_hist     => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_instructions;

    FUNCTION get_lab_test_action_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_action           IN co_sign.id_action%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_action_desc(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_analysis_req_det => i_analysis_req_det,
                                                              i_action           => i_action,
                                                              i_co_sign_hist     => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_action_desc;

    FUNCTION get_lab_test_date_to_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_co_sign_hist     IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_date_to_order(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_analysis_req_det => i_analysis_req_det,
                                                                i_co_sign_hist     => i_co_sign_hist);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_date_to_order;

    PROCEDURE cdr_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_id_content
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_analysis IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_id_content(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_analysis => i_analysis);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_id_content;

    FUNCTION get_lab_test_param_id_content
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_parameter IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_param_id_content(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_analysis_parameter => i_analysis_parameter);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_param_id_content;

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN VARCHAR2 DEFAULT 'A',
        i_content       IN VARCHAR2,
        i_dep_clin_serv IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_alias_translation(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_flg_type      => i_flg_type,
                                                           i_content       => i_content,
                                                           i_dep_clin_serv => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_translation;

    FUNCTION get_lab_test_parameter_for_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_analysis_param     IN table_number,
        o_analysis_parameter OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_PARAMETER_FOR_CDR';
        IF NOT pk_lab_tests_external.get_lab_test_parameter_for_cdr(i_lang               => i_lang,
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

    FUNCTION get_lab_test_cdr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_analysis_parameter IN VARCHAR2,
        i_date               IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_CDR';
        IF NOT pk_lab_tests_external.get_lab_test_cdr(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_patient            => i_patient,
                                                      i_analysis_parameter => i_analysis_parameter,
                                                      i_date               => i_date,
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
                                              'GET_LAB_TEST_CDR',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_cdr;

    FUNCTION check_lab_test_cdr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_analysis         IN VARCHAR2,
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_analysis_req_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_CDR';
        IF NOT pk_lab_tests_external.check_lab_test_cdr(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_patient          => i_patient,
                                                        i_analysis         => i_analysis,
                                                        i_date             => i_date,
                                                        o_analysis_req_det => o_analysis_req_det,
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
                                              'CHECK_LAB_TEST_CDR',
                                              o_error);
            RETURN FALSE;
        
    END check_lab_test_cdr;

    PROCEDURE referral___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION update_lab_test_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_exec_institution IN analysis_req_det.id_exec_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.UPDATE_LAB_TEST_INSTITUTION';
        IF NOT pk_lab_tests_external.update_lab_test_institution(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_analysis_req_det => i_analysis_req_det,
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
                                              'UPDATE_LAB_TEST_EXEC_INSTITUTION',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_institution;

    FUNCTION update_lab_test_referral
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_referral     IN analysis_req_det.flg_referral%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.UPDATE_LAB_TEST_REFERRAL';
        IF NOT pk_lab_tests_external.update_lab_test_referral(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_analysis_req_det => i_analysis_req_det,
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
                                              'UPDATE_LAB_TEST_REFERRAL',
                                              o_error);
            RETURN FALSE;
    END update_lab_test_referral;

    FUNCTION get_lab_test_resultsview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_lab_tests_external.t_cur_lab_test_result,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_external.get_lab_test_resultsview(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_patient          => i_patient,
                                                              i_episode          => i_episode,
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
                                              'GET_LAB_TEST_RESULTSVIEW',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_resultsview;

    FUNCTION check_lab_test_workflow_end
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_WORKFLOW_END';
        IF NOT pk_lab_tests_external.check_lab_test_workflow_end(i_lang             => i_lang,
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
                                              'CHECK_LAB_TEST_WORKFLOW_END',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_workflow_end;

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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.COPY_LAB_TEST_TO_DRAFT';
        IF NOT pk_lab_tests_external.copy_lab_test_to_draft(i_lang                 => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_DRAFT_CONFLICT';
        IF NOT pk_lab_tests_external.check_lab_test_draft_conflict(i_lang         => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_DRAFT';
        IF NOT pk_lab_tests_external.check_lab_test_draft(i_lang      => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_DRAFT_ACTIVATION';
        IF NOT pk_lab_tests_external.set_lab_test_draft_activation(i_lang          => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CANCEL_LAB_TEST_DRAFT';
        IF NOT pk_lab_tests_external.cancel_lab_test_draft(i_lang    => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CANCEL_LAB_TEST_ALL_DRAFTS';
        IF NOT pk_lab_tests_external.cancel_lab_test_all_drafts(i_lang    => i_lang,
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
        i_flg_out_of_cpoe IN VARCHAR2 DEFAULT 'N',
        i_flg_report      IN VARCHAR2 DEFAULT 'N',
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_print_items IN VARCHAR2 DEFAULT 'N',
        i_cpoe_tab        IN VARCHAR2 DEFAULT 'A',
        o_task_list       OUT pk_types.cursor_type,
        o_plan_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_LIST';
        IF NOT pk_lab_tests_external.get_lab_test_task_list(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_patient         => i_patient,
                                                            i_episode         => i_episode,
                                                            i_task_request    => i_task_request,
                                                            i_filter_tstz     => i_filter_tstz,
                                                            i_filter_status   => i_filter_status,
                                                            i_flg_out_of_cpoe => i_flg_out_of_cpoe,
                                                            i_flg_report      => i_flg_report,
                                                            i_dt_begin        => i_dt_begin,
                                                            i_dt_end          => i_dt_end,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_ACTIONS';
        IF NOT pk_lab_tests_external.get_lab_test_actions(i_lang         => i_lang,
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
                                              'CPOE_GET_TASK_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_action);
            RETURN FALSE;
    END get_task_actions;

    PROCEDURE order_sets_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN table_number,
        o_analysis_req_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_REQ_DET';
        IF NOT pk_lab_tests_external.get_lab_test_req_det(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_task_request     => i_task_request,
                                                          o_analysis_req_det => o_analysis_req_det,
                                                          o_error            => o_error)
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
                                              'GET_LAB_TEST_REQ_DET',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_req_det;

    FUNCTION get_lab_test_task_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_TITLE';
        IF NOT pk_lab_tests_external.get_lab_test_task_title(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_task_request     => i_task_request,
                                                             i_task_request_det => i_task_request_det,
                                                             o_task_desc        => o_task_desc,
                                                             o_error            => o_error)
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
                                              'GET_LAB_TEST_TASK_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_title;

    FUNCTION get_lab_test_task_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det  IN analysis_req_det.id_analysis_req_det%TYPE,
        i_flg_showdate      IN VARCHAR2 DEFAULT 'Y',
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_INSTRUCTIONS';
        IF NOT pk_lab_tests_external.get_lab_test_task_instructions(i_lang              => i_lang,
                                                                    i_prof              => i_prof,
                                                                    i_task_request      => i_task_request,
                                                                    i_task_request_det  => i_task_request_det,
                                                                    i_flg_showdate      => i_flg_showdate,
                                                                    o_task_instructions => o_task_instructions,
                                                                    o_error             => o_error)
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
                                              'GET_LAB_TEST_TASK_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_instructions;

    FUNCTION get_lab_test_task_description
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN tde_task_dependency.id_task_request%TYPE,
        o_task_desc        OUT VARCHAR2,
        o_task_status_desc OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_DESCRIPTION';
        IF NOT pk_lab_tests_external.get_lab_test_task_description(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_analysis_req_det => i_task_request,
                                                                   o_labtest_desc     => o_task_desc,
                                                                   o_task_status_desc => o_task_status_desc,
                                                                   o_error            => o_error)
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
                                              'GET_LAB_TEST_TASK_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_description;

    FUNCTION get_lab_test_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_status    OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_STATUS';
        IF NOT pk_lab_tests_external.get_lab_test_status(i_lang          => i_lang,
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
                                              'GET_LAB_TEST_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_status;

    FUNCTION get_lab_test_questionnaire
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_QUESTIONNAIRE';
        IF NOT pk_lab_tests_external.get_lab_test_questionnaire(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_patient      => i_patient,
                                                                i_episode      => i_episode,
                                                                i_task_request => i_task_request,
                                                                o_list         => o_list,
                                                                o_error        => o_error)
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
                                              'GET_LAB_TEST_QUESTIONNAIRE',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_questionnaire;

    FUNCTION get_lab_test_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_DATE_LIMITS';
        IF NOT pk_lab_tests_external.get_lab_test_date_limits(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_task_request => i_task_request,
                                                              o_list         => o_list,
                                                              o_error        => o_error)
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
                                              'GET_LAB_TEST_DATE_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_date_limits;

    FUNCTION get_lab_test_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_request     IN analysis_req.id_analysis_req%TYPE,
        i_task_request_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_id      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_ID';
        IF NOT pk_lab_tests_external.get_lab_test_task_id(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_task_request     => i_task_request,
                                                          i_task_request_det => i_task_request_det,
                                                          o_lab_test_id      => o_lab_test_id,
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
                                              'GET_LAB_TEST_ID',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_id;

    FUNCTION set_lab_test_request_task
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
        i_clinical_decision_rule  IN analysis_req_det.id_cdr%TYPE,
        i_task_dependency         IN table_number,
        i_flg_task_dependency     IN table_varchar,
        o_analysis_req            OUT table_number,
        o_analysis_req_det        OUT table_table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_REQUEST_TASK';
        IF NOT pk_lab_tests_external.set_lab_test_request_task(i_lang                    => i_lang,
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
                                                               o_analysis_req            => o_analysis_req,
                                                               o_analysis_req_det        => o_analysis_req_det,
                                                               o_error                   => o_error)
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
                                              'SET_LAB_TEST_REQUEST_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_request_task;

    FUNCTION set_lab_test_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_task_request OUT analysis_req.id_analysis_req%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_COPY_TASK';
        IF NOT pk_lab_tests_external.set_lab_test_copy_task(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_patient      => i_patient,
                                                            i_episode      => i_episode,
                                                            i_task_request => i_task_request,
                                                            o_analysis_req => o_task_request,
                                                            o_error        => o_error)
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
                                              'SET_LAB_TEST_COPY_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_copy_task;

    FUNCTION set_lab_test_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_DELETE_TASK';
        IF NOT pk_lab_tests_external.set_lab_test_delete_task(i_lang         => i_lang,
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
                                              'SET_LAB_TEST_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_delete_task;

    FUNCTION set_lab_test_diagnosis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_diagnosis    IN pk_edis_types.rec_in_epis_diagnosis,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_DIAGNOSIS';
        IF NOT pk_lab_tests_external.set_lab_test_diagnosis(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_episode      => i_episode,
                                                            i_task_request => i_task_request,
                                                            i_diagnosis    => i_diagnosis,
                                                            o_error        => o_error)
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
                                              'SET_LAB_TEST_DIAGNOSIS',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_diagnosis;

    FUNCTION set_lab_test_execute_time
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_EXECUTE_TIME';
        IF NOT pk_lab_tests_external.set_lab_test_execute_time(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_task_request => i_task_request,
                                                               o_error        => o_error)
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
                                              'SET_LAB_TEST_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_execute_time;

    FUNCTION check_lab_test_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_CHECK_MANDATORY_FIELDS';
        IF NOT pk_lab_tests_external.check_lab_test_mandatory_field(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_task_request => i_task_request,
                                                                    o_check        => o_check,
                                                                    o_error        => o_error)
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
                                              'CHECK_LAB_TEST_MANDATORY_FIELD',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_mandatory_field;

    FUNCTION check_lab_test_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_task_request IN analysis_req.id_analysis_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_CONFLICT';
        IF NOT pk_lab_tests_external.check_lab_test_conflict(i_lang         => i_lang,
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
                                              'CHECK_LAB_TEST_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_conflict;

    FUNCTION check_lab_test_cancel
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN analysis_req_det.id_analysis_req_det%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_CANCEL';
        IF NOT pk_lab_tests_external.check_lab_test_cancel(i_lang         => i_lang,
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
                                              'CHECK_LAB_TEST_CANCEL',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_cancel;

    PROCEDURE medication_______________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_analysis_result_par IN analysis_result_par.dt_analysis_result_par_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(1000 CHAR);
    BEGIN
    
        l_description := pk_lab_tests_external.get_lab_test_result_desc(i_lang                   => i_lang,
                                                                        i_prof                   => i_prof,
                                                                        i_id_analysis_result_par => i_id_analysis_result_par,
                                                                        i_dt_analysis_result_par => i_dt_analysis_result_par);
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END get_lab_test_result_desc;

    PROCEDURE tde_______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION check_lab_test_conflict
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_analysis       IN analysis.id_analysis%TYPE,
        i_analysis_group IN analysis_group.id_analysis_group%TYPE,
        o_flg_reason_msg OUT VARCHAR2,
        o_flg_conflict   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CHECK_LAB_TEST_CONFLICT';
        IF NOT pk_lab_tests_external.check_lab_test_conflict(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => i_patient,
                                                             i_episode        => i_episode,
                                                             i_analysis       => i_analysis,
                                                             i_analysis_group => i_analysis_group,
                                                             o_flg_reason_msg => o_flg_reason_msg,
                                                             o_flg_conflict   => o_flg_conflict,
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
                                              'CHECK_LAB_TEST_CONFLICT',
                                              o_error);
            RETURN FALSE;
    END check_lab_test_conflict;

    FUNCTION get_lab_test_cancel_permission
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        o_flg_cancel   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_CANCEL_PERMISSION';
        IF NOT pk_lab_tests_external.get_lab_test_cancel_permission(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_analysis_req_det => i_task_request,
                                                                    o_flg_cancel       => o_flg_cancel,
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
                                              'GET_LAB_TEST_CANCEL_PERMISSION',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_cancel_permission;

    FUNCTION start_lab_test_task_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.START_LAB_TEST_TASK_REQ';
        IF NOT pk_lab_tests_external.start_lab_test_task_req(i_lang         => i_lang,
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
                                              'START_LAB_TEST_TASK_REQ',
                                              o_error);
            RETURN FALSE;
    END start_lab_test_task_req;

    FUNCTION cancel_lab_test_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN analysis_req_det.id_analysis_req_det%TYPE,
        i_reason       IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes IN VARCHAR2,
        i_prof_order   IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order     IN VARCHAR2,
        i_order_type   IN co_sign.id_order_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.CANCEL_LAB_TEST_TASK';
        IF NOT pk_lab_tests_external.cancel_lab_test_task(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_task_request => i_task_request,
                                                          i_reason       => i_reason,
                                                          i_reason_notes => i_reason_notes,
                                                          i_prof_order   => i_prof_order,
                                                          i_dt_order     => i_dt_order,
                                                          i_order_type   => i_order_type,
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
                                              'CANCEL_LAB_TEST_TASK',
                                              o_error);
            RETURN FALSE;
    END cancel_lab_test_task;

    FUNCTION get_lab_test_ongoing_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_ONGOING_TASKS';
        RETURN pk_lab_tests_external.get_lab_test_ongoing_tasks(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_patient => i_patient);
    
    END get_lab_test_ongoing_tasks;

    FUNCTION suspend_lab_test_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN NUMBER,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SUSPEND_LAB_TEST_TASK';
        IF NOT pk_lab_tests_external.suspend_lab_test_task(i_lang       => i_lang,
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
                                              'SUSPEND_LAB_TEST_TASK',
                                              o_error);
            RETURN FALSE;
    END suspend_lab_test_task;

    FUNCTION reactivate_lab_test_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN NUMBER,
        o_msg_error OUT VARCHAR,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.REACTIVATE_LAB_TEST_TASK';
        IF NOT pk_lab_tests_external.reactivate_lab_test_task(i_lang      => i_lang,
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
                                              'REACTIVATE_LAB_TEST_TASK',
                                              o_error);
            RETURN FALSE;
    END reactivate_lab_test_task;

    FUNCTION get_lab_test_task_execute_time
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_request  IN tde_task_dependency.id_task_request%TYPE,
        o_flg_time      OUT VARCHAR2,
        o_flg_time_desc OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_TASK_EXECUTE_TIME';
        IF NOT pk_lab_tests_external.get_lab_test_task_execute_time(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_analysis_req_det => i_task_request,
                                                                    o_flg_time         => o_flg_time,
                                                                    o_flg_time_desc    => o_flg_time_desc,
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
                                              'GET_LAB_TEST_TASK_EXECUTE_TIME',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_task_execute_time;

    FUNCTION update_tde_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_lab_test_req    IN analysis_req.id_analysis_req%TYPE,
        i_flg_action      IN VARCHAR2,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_reason_notes    IN VARCHAR2 DEFAULT NULL,
        i_transaction_id  IN VARCHAR2 DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.UPDATE_TDE_TASK_STATE';
        IF NOT pk_lab_tests_external.update_tde_task_state(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_lab_test_req    => i_lab_test_req,
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

    PROCEDURE pregnancy_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_count_lab_test_results
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_id_content        IN table_varchar,
        i_dt_min_lab_result IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_COUNT_LAB_TEST_RESULTS';
        RETURN pk_lab_tests_external.get_count_lab_test_results(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_patient           => i_patient,
                                                                i_id_content        => i_id_content,
                                                                i_dt_min_lab_result => i_dt_min_lab_result);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_lab_test_results;

    PROCEDURE single_page________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_req_det_by_id_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE,
        o_analysis_req_det OUT analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_REQ_DET_BY_ID_RECURR';
        IF NOT pk_lab_tests_external.get_lab_req_det_by_id_recurr(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_order_recurrence => i_order_recurrence,
                                                                  o_analysis_req_det => o_analysis_req_det,
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
                                              'GET_LAB_REQ_DET_BY_ID_RECURR',
                                              o_error);
            RETURN FALSE;
    END get_lab_req_det_by_id_recurr;

    FUNCTION get_lab_test_result_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_varchar IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_result_list(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode);
    END get_lab_test_result_list;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock    IN pk_types.t_flg_char DEFAULT NULL,
        o_description            OUT CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_RESULT_DESC';
        IF NOT pk_lab_tests_external.get_lab_test_result_desc(i_lang                   => i_lang,
                                                              i_prof                   => i_prof,
                                                              i_id_analysis_result_par => i_id_analysis_result_par,
                                                              i_description_condition  => i_description_condition,
                                                              i_flg_desc_for_dblock    => i_flg_desc_for_dblock,
                                                              o_description            => o_description,
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
                                              'GET_LAB_TEST_RESULT_DESC',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_result_desc;

    FUNCTION get_analysis_status_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_status              OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_lab_tests_external.get_lab_test_result_desc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_lab_tests_external.get_analysis_status_desc(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_analysis_req_det => i_id_analysis_req_det,
                                                              o_status              => o_status,
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
                                              'GET_ANALYSIS_STATUS_DESC',
                                              o_error);
            RETURN FALSE;
    END get_analysis_status_desc;

    FUNCTION get_alias_code_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2,
        i_code_translation IN translation.code_translation%TYPE,
        i_dep_clin_serv    IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN translation.code_translation%TYPE IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_UTILS.GET_ALIAS_CODE_TRANSLATION';
        RETURN pk_lab_tests_utils.get_alias_code_translation(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_flg_type         => i_flg_type,
                                                             i_code_translation => i_code_translation,
                                                             i_dep_clin_serv    => i_dep_clin_serv);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation;

    FUNCTION get_lab_test_result_param
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_param IN table_number,
        i_dt_result      IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXTERNAL.GET_LAB_TEST_RESULT_PARAM';
        IF NOT pk_lab_tests_external.get_lab_test_result_param(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_patient        => i_patient,
                                                               i_analysis_param => i_analysis_param,
                                                               i_dt_result      => i_dt_result,
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
                                              'GET_LAB_TEST_RESULT_PARAM',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_lab_test_result_param;

    FUNCTION get_lab_test_parameters
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN table_number IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_parameters(i_prof        => i_prof,
                                                             i_analysis    => i_analysis,
                                                             i_sample_type => i_sample_type);
    END get_lab_test_parameters;

    FUNCTION get_lab_test_param_count
    (
        i_prof        IN profissional,
        i_analysis    IN analysis.id_analysis%TYPE,
        i_sample_type IN sample_type.id_sample_type%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_param_count(i_prof        => i_prof,
                                                              i_analysis    => i_analysis,
                                                              i_sample_type => i_sample_type);
    END get_lab_test_param_count;

    FUNCTION is_lab_test_recurr_finished
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_recurrence IN analysis_req_det.id_order_recurrence%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.IS_LAB_TEST_RECURR_FINISHED';
        RETURN pk_lab_tests_external.is_lab_test_recurr_finished(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_order_recurrence => i_order_recurrence);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END is_lab_test_recurr_finished;

    FUNCTION is_lab_result_outside_params
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_type_comparison   IN VARCHAR2,
        i_desc_analysis_result  IN analysis_result_par.desc_analysis_result%TYPE,
        i_analysis_result_value IN analysis_result_par.analysis_result_value_1%TYPE,
        i_ref_val               IN analysis_result_par.ref_val_min%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.IS_LAB_RESULT_OUTSIDE_PARAMS';
        RETURN pk_lab_tests_external.is_lab_result_outside_params(i_lang                  => i_lang,
                                                                  i_prof                  => i_prof,
                                                                  i_flg_type_comparison   => i_flg_type_comparison,
                                                                  i_desc_analysis_result  => i_desc_analysis_result,
                                                                  i_analysis_result_value => i_analysis_result_value,
                                                                  i_ref_val               => i_ref_val);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END is_lab_result_outside_params;

    PROCEDURE hand_off__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_tests_by_status
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_analysis OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TESTS_BY_STATUS';
        RETURN pk_lab_tests_external.get_lab_tests_by_status(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_episode  => i_episode,
                                                             o_analysis => o_analysis,
                                                             o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TESTS_BY_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            RETURN FALSE;
    END get_lab_tests_by_status;

    PROCEDURE sev_score_________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_result
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_result_value       OUT NUMBER,
        o_result_um          OUT unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_external.get_lab_test_result(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_episode            => i_episode,
                                                         i_analysis_parameter => i_analysis_parameter,
                                                         i_flg_parameter      => i_flg_parameter,
                                                         i_dt_min             => i_dt_min,
                                                         i_dt_max             => i_dt_max,
                                                         o_result_value       => o_result_value,
                                                         o_result_um          => o_result_um)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result;

    FUNCTION get_lab_test_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_RESULT';
        RETURN pk_lab_tests_external.get_lab_test_result(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_episode       => i_episode,
                                                         i_id_mtos_param => i_id_mtos_param,
                                                         i_flg_parameter => i_flg_parameter,
                                                         i_dt_min        => i_dt_min,
                                                         i_dt_max        => i_dt_max);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result;

    FUNCTION get_lab_test_result_um
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_RESULTS_COUNT';
        RETURN pk_lab_tests_external.get_lab_test_result_um(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_episode       => i_episode,
                                                            i_id_mtos_param => i_id_mtos_param,
                                                            i_flg_parameter => i_flg_parameter,
                                                            i_dt_min        => i_dt_min,
                                                            i_dt_max        => i_dt_max);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_lab_test_result_um;

    FUNCTION get_results_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_analysis_parameter IN table_varchar,
        i_flg_parameter      IN VARCHAR2,
        i_dt_min             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max             IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_RESULTS_COUNT';
        RETURN pk_lab_tests_external.get_results_count(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_episode            => i_episode,
                                                       i_analysis_parameter => i_analysis_parameter,
                                                       i_flg_parameter      => i_flg_parameter,
                                                       i_dt_min             => i_dt_min,
                                                       i_dt_max             => i_dt_max);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_results_count;

    PROCEDURE viewer___________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL, --se ‘N’ os código não serão traduzidos
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_ORDERED_LIST';
        IF NOT pk_lab_tests_external.get_ordered_list(i_lang         => i_lang,
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
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_ordered_list_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_ORDERED_LIST_DET';
        IF NOT pk_lab_tests_external.get_ordered_list_det(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_analysis_req_det => i_analysis_req_det,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_COUNT_AND_FIRST';
        IF NOT pk_lab_tests_external.get_count_and_first(i_lang        => i_lang,
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

    FUNCTION get_lab_test_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.GET_LAB_TEST_VIEWER_CHECKLIST';
        RETURN pk_lab_tests_external.get_lab_test_viewer_checklist(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_scope_type => i_scope_type,
                                                                   i_episode    => i_episode,
                                                                   i_patient    => i_patient);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_lab_test_viewer_checklist;

    PROCEDURE upd_viewer_ehr_ea
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    
    BEGIN
    
        pk_lab_tests_external.upd_viewer_ehr_ea(i_lang => i_lang, i_prof => i_prof);
    
    END upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.UPD_VIEWER_EHR_EA_PAT';
        IF NOT pk_lab_tests_external.upd_viewer_ehr_ea_pat(i_lang              => i_lang,
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

    PROCEDURE crisis_machine_____________ IS
    BEGIN
        NULL;
    END;

    FUNCTION tf_cm_lab_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_search_interval IN crisis_machine.interval_search%TYPE
    ) RETURN t_tbl_cm_episodes IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.TF_CM_LAB_EPISODES';
        RETURN pk_lab_tests_external.tf_cm_lab_episodes(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_search_interval => i_search_interval);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_cm_lab_episodes;

    FUNCTION tf_cm_lab_episode_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN t_tbl_lab_episodes IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.TF_CM_LAB_EPISODE_DETAIL';
        RETURN pk_lab_tests_external.tf_cm_lab_episode_detail(i_lang     => i_lang,
                                                              i_prof     => i_prof,
                                                              i_episode  => i_episode,
                                                              i_schedule => i_schedule);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_cm_lab_episode_detail;

    PROCEDURE hie______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_serialized_results
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_start_column       IN PLS_INTEGER,
        i_end_column         IN PLS_INTEGER,
        i_last_column_number IN PLS_INTEGER DEFAULT 6,
        o_serialized_results OUT pk_types.cursor_type,
        o_serialized_columns OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_lab_tests_core.get_lab_test_timelineview(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_start_column => i_start_column,
                                                           i_end_column   => i_end_column,
                                                           o_list_results => o_serialized_results,
                                                           o_list_columns => o_serialized_columns,
                                                           o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END get_serialized_results;

    PROCEDURE cda______________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_cda
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type_scope   IN VARCHAR2,
        i_id_scope     IN NUMBER,
        o_lab_test_cda OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_cda(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_type_scope   => i_type_scope,
                                                      i_id_scope     => i_id_scope,
                                                      o_lab_test_cda => o_lab_test_cda,
                                                      o_error        => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_CDA',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_cda;

    PROCEDURE scheduler__________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION get_lab_test_req_to_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN table_number,
        i_patient       IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_department IN room.id_department%TYPE DEFAULT NULL,
        i_pat_age_min   IN patient.age%TYPE DEFAULT NULL,
        i_pat_age_max   IN patient.age%TYPE DEFAULT NULL,
        i_pat_gender    IN patient.gender%TYPE DEFAULT NULL,
        i_start         IN NUMBER DEFAULT NULL,
        i_offset        IN NUMBER DEFAULT NULL,
        o_list          OUT pk_lab_tests_external.t_cur_lab_test_to_schedule,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_lab_tests_external.get_lab_test_req_to_schedule(i_lang          => i_lang,
                                                                  i_prof          => i_prof,
                                                                  i_institution   => i_institution,
                                                                  i_patient       => i_patient,
                                                                  i_id_department => i_id_department,
                                                                  i_pat_age_min   => i_pat_age_min,
                                                                  i_pat_age_max   => i_pat_age_max,
                                                                  i_pat_gender    => i_pat_gender,
                                                                  i_start         => i_start,
                                                                  i_offset        => i_offset,
                                                                  o_list          => o_list,
                                                                  o_error         => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAB_TEST_REQ_TO_SCHEDULE',
                                              o_error);
            RETURN FALSE;
    END get_lab_test_req_to_schedule;

    PROCEDURE match____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION set_lab_test_match
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.SET_LAB_TEST_MATCH';
        IF NOT pk_lab_tests_external.set_lab_test_match(i_lang         => i_lang,
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
                                              'SET_LAB_TEST_MATCH',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_match;

    PROCEDURE reset_____________________ IS
    BEGIN
        NULL;
    END;

    FUNCTION reset_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL.RESET_LAB_TESTS';
        IF NOT pk_lab_tests_external.reset_lab_tests(i_lang         => i_lang,
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
                                              'RESET_LAB_TESTS',
                                              o_error);
            RETURN FALSE;
    END reset_lab_tests;

    PROCEDURE system__________________ IS
    BEGIN
        NULL;
    END;

    PROCEDURE process_lab_test_pending IS
    BEGIN
        pk_lab_tests_external.process_lab_test_pending;
    END;

    FUNCTION inactivate_lab_tests_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_ids table_number := table_number();
    
    BEGIN
    
        IF NOT pk_lab_tests_external.inactivate_lab_tests_tasks(i_lang        => i_lang,
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
                                              'INACTIVATE_LAB_TESTS_TASKS',
                                              o_error);
            RETURN FALSE;
    END inactivate_lab_tests_tasks;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_external_api_db;
/
