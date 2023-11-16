/*-- Last Change Revision: $Rev: 1988131 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-05-05 15:55:18 +0100 (qua, 05 mai 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_cancel_reason_ux IS

    /**
    * Checks if the cancel reason is to be shown or not.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           The professional record.
    * @param i_tbl_task_type  The array of task types related with the areas.
    *
    * @param o_flg_mandatory  Y - Cancel reason is mandatory, will be shown in cancel screen; N - Isn't mandatory.
    * @param o_error          Error
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    * based on check_cancel_reason_mandatory but receiving an array of task types
    */
    FUNCTION check_cancel_reason_mandatory
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_task_type IN table_number,
        i_action        IN NUMBER DEFAULT NULL,
        o_flg_mandatory OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_priority_mandatory VARCHAR2(1 CHAR);
        l_priority_default_value VARCHAR(1 CHAR);
        l_flg_date_visible       VARCHAR2(1 CHAR);
        l_date_mandatory         VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        l_min_date VARCHAR2(200 CHAR);
        --
        l_func_name VARCHAR2(100) := 'CHECK_CANCEL_REASON_MANDATORY';
    BEGIN
        g_error := 'CALL PK_CANCEL_REASON.GET_CANCEL_CONFIGURATIONS - GETTING CONFIGURATION VALUE FOR ARRAY OF ID_TASK_TYPE - FIRST BEING: ' ||
                   i_tbl_task_type(1);
        IF NOT pk_cancel_reason.get_cancel_configurations(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_episode                   => NULL,
                                                          i_tbl_task_type             => i_tbl_task_type,
                                                          i_action                    => i_action,
                                                          o_flg_cancel_reas_mandatory => o_flg_mandatory,
                                                          o_flg_priority_mandatory    => l_flg_priority_mandatory,
                                                          o_priority_default_value    => l_priority_default_value,
                                                          o_flg_date_visible          => l_flg_date_visible,
                                                          o_date_mandatory            => l_date_mandatory,
                                                          o_min_date                  => l_min_date,
                                                          
                                                          o_error => o_error)
        THEN
        
            RAISE l_exception;
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END check_cancel_reason_mandatory;

    /**
    * Checks if the priority field is to be shown and returns the corresponding default value.
    * 
    * @param i_lang           Language identifier.
    * @param i_prof           The professional record.
    * @param i_tbl_task_type  The array of task types related with the areas.
    *
    * @param o_flg_mandatory  Y - Priority field is mandatory, will be shown in cancel screen; N - Isn't mandatory.
    * @param o_default_value  Y - Checked; N- Otherwise.
    * @param o_error          Error
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Nuno Alves
    * @version  2.6.5
    * @since    16-03-2015
    * based on check_priority_mandatory but receiving an array of task types
    */
    FUNCTION check_configurations
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_tbl_task_type    IN table_number,
        i_action           IN NUMBER DEFAULT NULL,
        o_flg_mandatory    OUT VARCHAR2,
        o_default_value    OUT VARCHAR2,
        o_flg_date_visible OUT VARCHAR2,
        o_date_mandatory   OUT VARCHAR2,
        o_min_date         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_cancel_reas_mandatory VARCHAR2(1 CHAR);
        l_exception EXCEPTION;
        --
        l_func_name VARCHAR2(100) := 'CHECK_PRIORITY_MANDATORY';
    BEGIN
        g_error := 'CALL PK_CANCEL_REASON.GET_CANCEL_CONFIGURATIONS - GETTING CONFIGURATION VALUE FOR ARRAY OF ID_TASK_TYPE - FIRST BEING: ' ||
                   i_tbl_task_type(1);
        IF NOT pk_cancel_reason.get_cancel_configurations(i_lang                      => i_lang,
                                                          i_prof                      => i_prof,
                                                          i_episode                   => i_episode,
                                                          i_tbl_task_type             => i_tbl_task_type,
                                                          i_action                    => i_action,
                                                          o_flg_cancel_reas_mandatory => l_flg_cancel_reas_mandatory,
                                                          o_flg_priority_mandatory    => o_flg_mandatory,
                                                          o_priority_default_value    => o_default_value,
                                                          o_flg_date_visible          => o_flg_date_visible,
                                                          o_date_mandatory            => o_date_mandatory,
                                                          o_min_date                  => o_min_date,
                                                          o_error                     => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END check_configurations;

    FUNCTION get_content_by_id
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE
    ) RETURN cancel_reason.id_content%TYPE IS
    
        l_cancel_reason cancel_reason.id_content%TYPE;
    BEGIN
    
        l_cancel_reason := pk_cancel_reason.get_content_by_id(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_cancel_reason => i_id_cancel_reason);
    
        RETURN l_cancel_reason;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_content_by_id;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_cancel_reason_ux;
/
