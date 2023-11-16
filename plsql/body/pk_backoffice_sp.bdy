/*-- Last Change Revision: $Rev: 2026804 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_sp IS

    /*
    * Function to validate if professional exists
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_professional professional, institution and software ids    
    * @return  true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2014/02/07
    */
    FUNCTION professional_exists
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_professional(x_id_professional professional.id_professional%TYPE) IS
            SELECT *
              FROM professional p
             WHERE p.id_professional = x_id_professional;
        l_prof professional%ROWTYPE;
    BEGIN
    
        /* Verify if professional exists */
        g_error := 'Error geting professional record';
        OPEN c_professional(i_id_professional);
        FETCH c_professional
            INTO l_prof;
        g_found := c_professional%FOUND;
        CLOSE c_professional;
    
        IF g_found
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SP',
                                              'PROFESSIONAL_EXISTS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END professional_exists;

    /*
    * Function to validate if username is in use by a professional different from
    * the one provided  
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_username username 
    * @param   i_id_professional professional, institution and software ids    
    * @return  returns true if in use byor false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2014/02/07
    */
    FUNCTION is_username_available
    (
        i_lang            IN language.id_language%TYPE,
        i_username        IN alert_core_data.ab_user_info.login%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_desc_user(x_login alert_core_data.ab_user_info.login%TYPE) IS
            SELECT *
              FROM alert_core_data.ab_user_info ui
             WHERE upper(ui.login) = upper(x_login);
        l_user_info_row alert_core_data.ab_user_info%ROWTYPE;
    BEGIN
    
        /* Verify if username is already used */
        g_error := 'Error getting user record';
        OPEN c_desc_user(i_username);
        FETCH c_desc_user
            INTO l_user_info_row;
        g_found := c_desc_user%FOUND;
        CLOSE c_desc_user;
    
        IF g_found
           AND i_id_professional != l_user_info_row.id_ab_user_info
        THEN
            g_error := i_username || pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T125');
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SP',
                                              'IS_USERNAME_AVAILABLE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END is_username_available;

    /*
    * Function to create new username
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_id_professional professional, institution and software ids    
    * @return  true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013/11/18
    */
    FUNCTION set_username
    (
        i_lang            IN language.id_language%TYPE,
        i_user_name       IN VARCHAR2,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        prof_not_found_exception  EXCEPTION;
        username_in_use_exception EXCEPTION;
    
        l_username ab_user_info.login%TYPE;
    
    BEGIN
        /* add space removal from begin/end username string */
        l_username := TRIM(upper(i_user_name));
    
        g_error := 'Professional does not exists';
        IF NOT professional_exists(i_lang, i_id_professional, o_error)
        THEN
            RAISE prof_not_found_exception;
        END IF;
    
        g_error := 'Username already in use by another professional';
        IF NOT is_username_available(i_lang, l_username, i_id_professional, o_error)
        THEN
            g_error := l_username || pk_message.get_message(i_lang, 'ADMINISTRATOR_IDENT_T125');
            RAISE username_in_use_exception;
        END IF;
    
        g_error := 'Error updating username';
        pk_api_ab_tables.update_ab_user_info_login(i_id_ab_user_info => i_id_professional, i_login => l_username);
    
        RETURN TRUE;
    EXCEPTION
        WHEN username_in_use_exception THEN
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => 'CREATE_USER',
                                              i_sqlerrm     => g_error,
                                              i_message     => g_error,
                                              i_owner       => 'ALERT',
                                              i_package     => 'PK_BACKOFFICE_SP',
                                              i_function    => 'SET_USERNAME',
                                              i_action_type => 'U',
                                              o_error       => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN prof_not_found_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SP',
                                              'SET_USERNAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_SP',
                                              'SET_USERNAME',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_username;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_backoffice_sp;
/
