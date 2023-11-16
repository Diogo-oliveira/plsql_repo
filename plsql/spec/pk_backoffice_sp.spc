/*-- Last Change Revision: $Rev: 2028528 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_sp IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    my_exception EXCEPTION;

    g_sysdate DATE;
    g_error   VARCHAR2(2000);
    g_found   BOOLEAN;

END pk_backoffice_sp;
/
