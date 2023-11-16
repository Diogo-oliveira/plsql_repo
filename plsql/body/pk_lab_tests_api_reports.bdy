/*-- Last Change Revision: $Rev: 2027302 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_api_reports IS

    FUNCTION get_lab_tests_listview
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
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
    
        g_error := 'CALL GET_LAB_TEST_LISTVIEW';
        IF NOT pk_lab_tests_external_api_db.get_lab_tests_listview(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_patient    => NULL,
                                                                   i_episode    => NULL,
                                                                   i_scope      => i_scope,
                                                                   i_flg_scope  => i_flg_scope,
                                                                   i_start_date => i_start_date,
                                                                   i_end_date   => i_end_date,
                                                                   i_cancelled  => pk_lab_tests_constant.g_no,
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
        o_list             OUT pk_types.cursor_type,
        o_result_list      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_RESULTSVIEW';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_resultsview(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_patient          => i_patient,
                                                                     i_visit            => i_visit,
                                                                     i_episode          => i_episode,
                                                                     i_analysis_req_det => i_analysis_req_det,
                                                                     i_flg_type         => i_flg_type,
                                                                     i_dt_min           => i_dt_min,
                                                                     i_dt_max           => i_dt_max,
                                                                     i_flg_report       => pk_lab_tests_constant.g_yes,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_REPORTS_TABLE1';
        IF NOT pk_lab_tests_external_api_db.get_reports_table1(i_lang          => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_REPORTS_TABLE2';
        IF NOT pk_lab_tests_external_api_db.get_reports_table2(i_lang               => i_lang,
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_REPORTS_COUNTER';
        IF NOT pk_lab_tests_external_api_db.get_reports_counter(i_lang       => i_lang,
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
        o_list                  OUT pk_types.cursor_type,
        o_lt_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_ORDERS';
        IF NOT pk_lab_tests_external_api_db.get_lab_tests_orders(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_episode               => i_episode,
                                                                 i_flg_location          => i_flg_location,
                                                                 i_flg_reports           => pk_alert_constant.g_yes,
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
                                              'GET_LAB_TESTS_ORDERS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_tests_orders;

    FUNCTION get_lab_tests_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_CO_SIGN';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_co_sign(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_episode          => i_episode,
                                                                 i_analysis_req_det => i_analysis_req_det,
                                                                 i_flg_report       => pk_lab_tests_constant.g_yes,
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
                                              'GET_LAB_TESTS_CO_SIGN',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_co_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_tests_co_sign;

    FUNCTION get_lab_tests_detail
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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_detail(i_lang                        => i_lang,
                                                                i_prof                        => i_prof,
                                                                i_episode                     => i_episode,
                                                                i_analysis_req_det            => i_analysis_req_det,
                                                                i_flg_report                  => pk_lab_tests_constant.g_yes,
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
                                              'GET_LAB_TESTS_DETAIL',
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
    END get_lab_tests_detail;

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
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.GET_LAB_TEST_DETAIL';
        IF NOT pk_lab_tests_external_api_db.get_lab_test_detail_history(i_lang                        => i_lang,
                                                                        i_prof                        => i_prof,
                                                                        i_episode                     => i_episode,
                                                                        i_analysis_req_det            => i_analysis_req_det,
                                                                        i_flg_report                  => pk_lab_tests_constant.g_yes,
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
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.GET_HARVEST_MOVEMENT_DETAIL';
        IF NOT pk_lab_tests_api_db.get_harvest_movement_detail(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_harvest                  => i_harvest,
                                                               i_flg_report               => pk_lab_tests_constant.g_yes,
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

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_api_reports;
/
