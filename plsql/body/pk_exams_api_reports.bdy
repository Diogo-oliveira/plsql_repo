/*-- Last Change Revision: $Rev: 2027138 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exams_api_reports IS

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_LISTVIEW';
        IF NOT pk_exams_external_api_db.get_exam_listview(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_patient    => NULL,
                                                          i_episode    => NULL,
                                                          i_exam_type  => i_exam_type,
                                                          i_scope      => i_scope,
                                                          i_flg_scope  => i_flg_scope,
                                                          i_start_date => i_start_date,
                                                          i_end_date   => i_end_date,
                                                          i_cancelled  => i_cancelled,
                                                          i_crit_type  => i_crit_type,
                                                          i_flg_status => i_flg_status,
                                                          i_flg_rep    => pk_alert_constant.g_yes,
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
                                              'GET_EXAM_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_listview;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_ORDERS';
        IF NOT pk_exams_external_api_db.get_exam_orders(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_episode                 => i_episode,
                                                        i_exam_type               => i_exam_type,
                                                        i_flg_location            => i_flg_location,
                                                        i_flg_reports             => pk_alert_constant.g_yes,
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
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_orders;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_DETAIL';
        IF NOT pk_exams_external_api_db.get_exam_detail(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_episode                 => i_episode,
                                                        i_exam_req_det            => i_exam_req_det,
                                                        i_flg_report              => pk_exam_constant.g_yes,
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
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.GET_EXAM_DETAIL';
        IF NOT pk_exams_external_api_db.get_exam_detail_history(i_lang                    => i_lang,
                                                                i_prof                    => i_prof,
                                                                i_episode                 => i_episode,
                                                                i_exam_req_det            => i_exam_req_det,
                                                                i_flg_report              => pk_exam_constant.g_yes,
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
            pk_types.open_my_cursor(o_exam_clinical_questions);
            pk_types.open_my_cursor(o_exam_perform);
            pk_types.open_my_cursor(o_exam_result);
            pk_types.open_my_cursor(o_exam_result_images);
            pk_types.open_my_cursor(o_exam_doc);
            pk_types.open_my_cursor(o_exam_review);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_detail_history;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
