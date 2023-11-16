/*-- Last Change Revision: $Rev: 2028687 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_exams_api_reports IS

    /*
    * Returns a list of exams for a patient within a visit (list view)
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_patient        Patient id
    * @param     i_episode        Episode id
    * @param     i_exam_type      Exam type: I - image; E - other exam
    * @param     o_list           Cursor
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2010/01/20
    */

    FUNCTION get_exam_orders
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_type               IN exam.flg_type%TYPE,
        i_flg_location            IN exam_req_det.flg_location%TYPE,
        o_list                    OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_exam_listview
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_exam_type  IN exam.flg_type%TYPE,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_status IN table_varchar DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     o_exam_order                Cursor
    * @param     o_exam_co_sign              Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_exam_perform              Cursor
    * @param     o_exam_result               Cursor
    * @param     o_exam_result_images        Cursor
    * @param     o_exam_doc                  Cursor
    * @param     o_exam_review               Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/03/03
    */

    FUNCTION get_exam_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns an exam detail history
    *
    * @param     i_lang                      Language id
    * @param     i_prof                      Professional
    * @param     i_episode                   Episode id
    * @param     i_exam_req_det              Exam detail order id
    * @param     o_exam_order                Cursor
    * @param     o_exam_co_sign              Cursor
    * @param     o_exam_clinical_questions   Cursor
    * @param     o_exam_perform              Cursor
    * @param     o_exam_result               Cursor
    * @param     o_exam_result_images        Cursor
    * @param     o_exam_doc                  Cursor
    * @param     o_exam_review               Cursor
    * @param     o_error                     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.6.1
    * @since     2011/05/04
    */
    FUNCTION get_exam_detail_history
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_user_exception  EXCEPTION;
    g_error VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END;
/
