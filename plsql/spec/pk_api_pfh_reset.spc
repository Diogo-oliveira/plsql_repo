/*-- Last Change Revision: $Rev: 2028490 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_reset IS

    /*
    * Resets lab tests info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.5
    * @since     2011/02/18
    */

    FUNCTION reset_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resets exams info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.5
    * @since     2011/02/18
    */

    FUNCTION reset_exams
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resets procedures info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.6.1
    * @since     2011/04/29
    */

    FUNCTION reset_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resets blood products info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.4.5
    * @since     2018/11/12
    */

    FUNCTION reset_bp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resets care_plan info by patient and /or episode
    *     
    * @param    i_lang      Language
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.5
    * @since     2011/02/18
    */

    FUNCTION reset_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_api_pfh_reset;
/
