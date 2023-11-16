/*-- Last Change Revision: $Rev: 2028768 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tests_api_reports IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_lab_tests_orders
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_flg_location          IN VARCHAR2,
        o_list                  OUT pk_types.cursor_type,
        o_lt_clinical_questions OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

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
    ) RETURN BOOLEAN;

    FUNCTION get_lab_tests_co_sign
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_lab_test_co_sign OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a lab test detail history
    *
    * @param     i_lang                          Language id
    * @param     i_prof                          Professional
    * @param     i_episode                       Episode id
    * @param     i_analysis_req_det              Lab tests' order detail id
    * @param     o_lab_test_order                Cursor
    * @param     o_lab_test_co_sign              Cursor
    * @param     o_lab_test_clinical_questions   Cursor
    * @param     o_lab_test_harvest              Cursor
    * @param     o_lab_test_result               Cursor
    * @param     o_lab_test_doc                  Cursor
    * @param     o_lab_test_review               Cursor
    * @param     o_error                         Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */

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
    ) RETURN BOOLEAN;

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_lab_tests_api_reports;
/
