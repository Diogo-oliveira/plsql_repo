/*-- Last Change Revision: $Rev: 2027515 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_procedures_api_reports IS

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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_LISTVIEW';
        IF NOT pk_procedures_external_api_db.get_procedure_listview(i_lang             => i_lang,
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
            pk_alert_exceptions.reset_error_state;
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_ORDERS';
        IF NOT pk_procedures_external_api_db.get_procedure_orders(i_lang             => i_lang,
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_DETAIL';
        IF NOT pk_procedures_external_api_db.get_procedure_detail(i_lang                      => i_lang,
                                                                  i_prof                      => i_prof,
                                                                  i_episode                   => i_episode,
                                                                  i_interv_presc_det          => i_interv_presc_det,
                                                                  i_flg_report                => pk_procedures_constant.g_yes,
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
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.GET_PROCEDURE_DETAIL_HISTORY';
        IF NOT pk_procedures_external_api_db.get_procedure_detail_history(i_lang                      => i_lang,
                                                                          i_prof                      => i_prof,
                                                                          i_episode                   => i_episode,
                                                                          i_interv_presc_det          => i_interv_presc_det,
                                                                          i_flg_report                => pk_procedures_constant.g_yes,
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

    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
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

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_procedures_api_reports;
/
