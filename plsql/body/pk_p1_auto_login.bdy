/*-- Last Change Revision: $Rev: 2027420 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_p1_auto_login AS

    /**
    * Validates if the session is valid. Return professional data.
    *
    * @param   i_id_session    Session identifier
    * @param   i_provider      Provider identifier. {*} REFERRAL {*} P1
    * @param   o_professional  Professional identifier
    * @param   o_user         professional login
    * @param   o_language      Professional language identifier
    * @param   o_institution   Institution identifier
    * @param   o_software      Software identifier
    * @param   o_error error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joao Sa
    * @version 1.0
    * @since   10-12-2007
    */
    FUNCTION validate_session
    (
        i_id_session   IN VARCHAR2,
        i_provider     IN VARCHAR2,
        o_professional OUT professional.id_professional%TYPE,
        o_user         OUT ab_user_info.login%TYPE,
        o_language     OUT language.id_language%TYPE,
        o_institution  OUT institution.id_institution%TYPE,
        o_software     OUT software.id_software%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prof
        (
            x_i institution.ext_code%TYPE,
            x_p professional.num_order%TYPE
        ) IS
            SELECT p.id_professional, su.login, su.id_language, i.id_institution, g_referral_soft_id
              FROM professional p, institution i, prof_institution pi, ab_user_info su
             WHERE p.num_order = x_p
               AND p.flg_state = pk_ref_constant.g_active
               AND i.ext_code = x_i
               AND p.id_professional = su.id_ab_user_info
               AND p.id_professional = pi.id_professional
               AND i.id_institution = pi.id_institution
               AND i.flg_available = pk_ref_constant.g_yes -- JFA, 2010-06-22 : ALERT-106560
               AND pi.flg_state = pk_ref_constant.g_active
               AND pi.dt_end_tstz IS NULL; -- ACM, 2009-11-10: ALERT-55888 - active professionals at this moment
    
        l_inst_code   institution.ext_code%TYPE;
        l_prof_number professional.num_order%TYPE;
    
        l_lang language.id_language%TYPE := 1;
    
        l_e_invalid_session EXCEPTION;
        l_e_user_not_found  EXCEPTION;
    
    BEGIN
    
        g_error := 'Init validate_session / ID_SESSION= ' || i_id_session || ' PROVIDER=' || i_provider;
        pk_alertlog.log_debug(g_error);
    
        IF i_provider = pk_ref_constant.g_provider_referral
        THEN
        
            g_error := 'CALL pk_api_ref_ext.validate_session / ID_SESSION= ' || i_id_session;
            pk_alertlog.log_debug(g_error);
            g_retval := pk_api_ref_ext.validate_session(i_id_session   => i_id_session,
                                                        o_professional => o_professional,
                                                        o_user         => o_user,
                                                        o_language     => o_language,
                                                        o_institution  => o_institution,
                                                        o_software     => o_software,
                                                        o_error        => o_error);
            IF NOT g_retval
            THEN
                g_error := 'Error: ' || g_error;
                RAISE g_exception;
            END IF;
        
        ELSE
            g_error := 'Call interface_p1.pk_p1_url.get_session_state / ID_SESSION=' || i_id_session;
            pk_alertlog.log_debug(g_error);
            -- cmf OPSDEV-1073
            --g_retval := interface_p1.pk_p1_url.get_session_state(i_id_session, l_inst_code, l_prof_number, g_error);
            g_retval := TRUE; -- cmf OPSDEV-1073
        
            IF NOT g_retval
            THEN
                IF g_error IS NOT NULL
                THEN
                    g_error := 'Interface error: ' || g_error;
                    RAISE g_exception;
                END IF;
                RAISE l_e_invalid_session;
            END IF;
        
            g_error := 'OPEN c_prof(' || l_inst_code || ', ' || l_prof_number || ')';
            pk_alertlog.log_debug(g_error);
        
            OPEN c_prof(l_inst_code, l_prof_number);
            FETCH c_prof
                INTO o_professional, o_user, o_language, o_institution, o_software;
            g_found := c_prof%FOUND;
            CLOSE c_prof;
        
            g_error := 'o_language=' || o_language;
            pk_alertlog.log_debug(g_error);
        
            IF o_language IS NOT NULL
            THEN
                l_lang := o_language;
            END IF;
        
            IF NOT g_found
            THEN
                RAISE l_e_user_not_found;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_e_invalid_session THEN
            DECLARE
                --Initialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_ret           BOOLEAN;
                l_error_message VARCHAR2(1000 CHAR) := pk_message.get_message(l_lang, 'P1_DOCTOR_CS_T080') || ' ' ||
                                                       pk_message.get_message(l_lang, 'P1_DOCTOR_CS_T081');
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(l_lang,
                                   'l_e_invalid_session',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'VALIDATE_SESSION',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
        WHEN l_e_user_not_found THEN
            DECLARE
                --Initialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_ret           BOOLEAN;
                l_error_message VARCHAR2(1000 CHAR) := pk_message.get_message(l_lang, 'P1_DOCTOR_CS_T080') || ' ' ||
                                                       pk_message.get_message(l_lang, 'P1_DOCTOR_CS_T082');
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(l_lang,
                                   'l_e_user_not_found',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'VALIDATE_SESSION',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
        
        WHEN g_exception THEN
        
            DECLARE
                --Initialization of object for input
                l_error_in      t_error_in := t_error_in();
                l_ret           BOOLEAN;
                l_error_message VARCHAR2(1000 CHAR) := pk_message.get_message(l_lang, 'P1_DOCTOR_CS_T080'); -- || ' ' || g_error;
            BEGIN
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(l_lang,
                                   'g_exception',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'VALIDATE_SESSION',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                -- execute error processing
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'VALIDATE_SESSION',
                                                     o_error    => o_error);
    END validate_session;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_referral_soft_id := 4;

END pk_p1_auto_login;
/
