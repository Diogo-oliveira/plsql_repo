/*-- Last Change Revision: $Rev: 2026730 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_referral_out IS

    /* CAN'T TOUCH THIS */
    --g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /**
    * Sets the parameter context 
    * Used by inter
    *
    * @param   i_name     Parameter name
    * @param   i_value    Parameter value
    *
    * @author  Ana Monteiro
    * @version 1.0
    * @since   06-12-2011
    */
    PROCEDURE set_parameter
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
    BEGIN
        pk_context_api.set_parameter(p_name => i_name, p_value => i_value);
    END set_parameter;

    /**
    * Gets sys_config value 
    * Used by inter
    *    
    * @param   i_prof     Professional id, institution and software
    * @param   i_code_cf  Sys config code
    *
    * @RETURN  sys config value
    * @author  Ana Monteiro
    * @version 1.0
    * @since   12-12-2011
    */
    FUNCTION get_config
    (
        i_prof    IN profissional,
        i_code_cf IN sys_config.id_sys_config%TYPE
    ) RETURN sys_config.value%TYPE IS
    BEGIN
        RETURN pk_sysconfig.get_config(i_code_cf => i_code_cf, i_prof => i_prof);
    END get_config;

    /**
    * Gets translation value 
    * Used by interfaces.
    *    
    * @param   i_lang       Language identifier
    * @param   i_code_mess  Translation code
    *
    * @RETURN  translation value
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-01-2012
    */
    FUNCTION get_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_code_mess IN translation.code_translation%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    BEGIN
        RETURN pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_mess);
    END get_translation;

    /**
    * Gets domain value description
    * Used by interfaces.
    *    
    * @param   i_code_dom Domain code
    * @param   i_val      Domain value description
    * @param   i_lang     Language identifier    
    *
    * @RETURN  translation value
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-01-2012
    */
    FUNCTION get_domain
    (
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE,
        i_lang     IN language.id_language%TYPE
    ) RETURN sys_domain.desc_val%TYPE IS
    BEGIN
        RETURN pk_sysdomain.get_domain(i_lang => i_lang, i_code_dom => i_code_dom, i_val => i_val);
    END get_domain;

BEGIN
    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_api_referral_out;
/
