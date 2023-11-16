/*-- Last Change Revision: $Rev: 2026911 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:24 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_co_sign_ux AS

    /**
    * Checks if the current professional needs co-sign to complete the action
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PROF_NEEDS_COSIGN';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_CO_SIGN.CHECK_PROF_NEEDS_COSIGN';
        IF NOT pk_co_sign.check_prof_needs_cosign(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_episode                => i_episode,
                                                  i_tbl_id_task_type       => i_tbl_id_task_type,
                                                  i_cosign_def_action_type => i_cosign_def_action_type,
                                                  i_action                 => i_action,
                                                  o_flg_prof_need_cosign   => o_flg_prof_need_cosign,
                                                  o_error                  => o_error)
        
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
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_prof_needs_cosign;

    /**
    * Checks if the current professional needs co-sign to complete the action at the order 
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN task_type.id_task_type%TYPE,
        o_flg_prof_need_cosign OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PROF_NEEDS_COSIGN';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_CO_SIGN.CHECK_PROF_NEEDS_COSIGN';
        IF NOT pk_co_sign.check_prof_needs_cosign(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_episode                => i_episode,
                                                  i_task_type              => i_task_type,
                                                  i_cosign_def_action_type => pk_co_sign.g_cosign_action_def_add,
                                                  i_action                 => NULL,
                                                  o_flg_prof_need_cosign   => o_flg_prof_need_cosign,
                                                  o_error                  => o_error)
        
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
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_prof_needs_cosign_order;

    /********************************************************************************************
    * Gets all co-sing tasks, by professional identifier and patient episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                The episode ID
    * @param o_co_sign_list           Cursor containing the task list to co-sign 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION get_co_sign_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_co_sign_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_CO_SIGN_LIST';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_co_sign.get_cosign_list(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_episode      => i_episode,
                                          i_flg_filter   => pk_alert_constant.g_yes,
                                          o_co_sign_list => o_co_sign_list,
                                          o_error        => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_co_sign_list;

    /********************************************************************************************
    * Changes the co-sign status to "co-signed" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_tbl_id_co_sign          Co-sign record identifier
    * @param i_id_prof_cosigned        Professinonal that co-signs the order
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional was made authentication: 
                                       (Y) - Yes, (N) - No
    * @param o_tbl_id_co_sign_hist     Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_co_signed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_co_sign      IN table_number,
        i_id_prof_cosigned    IN co_sign.id_prof_co_signed%TYPE,
        i_cosign_notes        IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth       IN co_sign.flg_made_auth%TYPE,
        o_tbl_id_co_sign_hist OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_co_sign.set_task_co_signed(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_episode             => i_episode,
                                             i_tbl_id_co_sign      => i_tbl_id_co_sign,
                                             i_id_prof_cosigned    => i_id_prof_cosigned,
                                             i_dt_cosigned         => current_timestamp,
                                             i_cosign_notes        => i_cosign_notes,
                                             i_flg_made_auth       => i_flg_made_auth,
                                             o_tbl_id_co_sign_hist => o_tbl_id_co_sign_hist,
                                             o_error               => o_error);
    END set_task_co_signed;

    /********************************************************************************************
    * Gets a set of professionals that can made the co-sign
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              The episode ID
    * @param o_prof_list               Professional data
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_co_sign.get_prof_list(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_id_episode,
                                        o_prof_list  => o_prof_list,
                                        o_error      => o_error);
    
    END get_prof_list;

    /********************************************************************************************
    * Gets a set of professionals that can made the co-sign
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              The episode ID
    * @param i_id_order_type              Order type identifier
    * @param o_prof_list               Professional data
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_co_sign.get_prof_list(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_episode    => i_id_episode,
                                        i_id_order_type => i_id_order_type,
                                        o_prof_list     => o_prof_list,
                                        o_error         => o_error);
    
    END get_prof_list;

    /********************************************************************************************
    * List all types of orders existing in co-sign 
    *
    * @param i_lang                   The language ID
    * @param o_order_type             Order list
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/04
    **********************************************************************************************/
    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_co_sign.get_order_type(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         o_order_type => o_order_type,
                                         o_error      => o_error);
    END get_order_type;

    /********************************************************************************************
    * Detailed current information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              Co-sign task identifier
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/11
    **********************************************************************************************/

    FUNCTION get_co_sign_current_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN co_sign.id_co_sign%TYPE,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_CO_SIGN_DETAILS';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_co_sign.get_co_sign_details(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_co_sign   => table_number(i_id_co_sign),
                                              i_flg_detail   => pk_co_sign.g_cosign_curr_info,
                                              o_co_sign_info => o_co_sign_info,
                                              o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_co_sign_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_co_sign_current_det;

    /********************************************************************************************
    * Detailed history information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              Co-sign task identifier
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/11
    **********************************************************************************************/

    FUNCTION get_co_sign_history_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN co_sign.id_co_sign%TYPE,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_CO_SIGN_DETAILS';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_co_sign.get_co_sign_details(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_co_sign   => table_number(i_id_co_sign),
                                              i_flg_detail   => pk_co_sign.g_cosign_hist_info,
                                              o_co_sign_info => o_co_sign_info,
                                              o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_co_sign_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_co_sign_history_det;

    /********************************************************************************************
    * Detailed current information about a co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign              table_number
    * @param o_co_sign_info            Co-sign task info
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Elisabete Bugalho
    * @since                          2017/03/15
    **********************************************************************************************/

    FUNCTION get_co_sign_current_det_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_CO_SIGN_DETAILS';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_co_sign.get_co_sign_details(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_co_sign   => i_id_co_sign,
                                              i_flg_detail   => pk_co_sign.g_cosign_curr_info,
                                              o_co_sign_info => o_co_sign_info,
                                              o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_co_sign_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_co_sign_current_det_list;

    FUNCTION get_co_sign_current_det_by_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        i_tbl_status   IN table_varchar DEFAULT NULL,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'GET_CO_SIGN_CURRENT_DET_BY_STATUS';
        --
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_co_sign.get_co_sign_details(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_co_sign   => i_id_co_sign,
                                              i_flg_detail   => pk_co_sign.g_cosign_curr_info,
                                              i_tbl_status   => i_tbl_status,
                                              o_co_sign_info => o_co_sign_info,
                                              o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_co_sign_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_co_sign_current_det_by_status;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_co_sign_ux;
/
