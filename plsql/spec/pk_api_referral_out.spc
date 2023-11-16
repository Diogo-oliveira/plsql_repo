/*-- Last Change Revision: $Rev: 2028493 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_referral_out IS

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
    );

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
    ) RETURN sys_config.value%TYPE;

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
    ) RETURN pk_translation.t_desc_translation;

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
    ) RETURN sys_domain.desc_val%TYPE;

END pk_api_referral_out;
/
