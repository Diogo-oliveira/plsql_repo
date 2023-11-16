/*-- Last Change Revision: $Rev: 1637937 $*/
/*-- Last Change by: $Author: rui.spratley $*/
/*-- Date of last change: $Date: 2014-09-24 11:50:45 +0100 (qua, 24 set 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_ux_profile IS

    k_package_owner VARCHAR2(0050 CHAR);
    k_package_name  VARCHAR2(0050 CHAR);

    /**
    * This function serves as constructor for current package.
    *
    * @version  2.6.8.3
    * @since    21-10-2013
    * @author   Carlos Ferreira
    */
    PROCEDURE inicialize IS
    BEGIN
        pk_alertlog.who_am_i(owner => k_package_owner, name => k_package_name);
        pk_alertlog.log_init(object_name => k_package_name, owner => k_package_owner);
    END inicialize;

    /**
    * This function returns the last login for a professional
    *
    * @param    i_id_prof             Professional
    * @param    o_res                 result cursor
    * @param    o_error               error message
    *
    * @return   boolean
    *
    * @version  2.6.8.3
    * @since    26-11-2013
    * @author   Rui Spratley
    */
    FUNCTION get_prof_login_info
    (
        i_user_id  IN NUMBER,
        o_username OUT VARCHAR2,
        o_lang     OUT NUMBER,
        o_inst     OUT NUMBER,
        o_software OUT NUMBER,
        o_category OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PROF_LOGIN_INFO';
        l_error VARCHAR2(1000 CHAR);
        l_lang  language.id_language%TYPE;
    BEGIN
        SELECT *
          INTO o_username, o_software, o_inst, o_lang, o_category
          FROM (SELECT aui.login, asiui.id_ab_software id_software, asiui.id_ab_institution id_institution, asiui.id_ab_language id_language, 0 id_category
                  FROM ab_user_info aui
                  LEFT OUTER JOIN ab_soft_inst_user_info asiui
                    ON asiui.id_ab_user_info = aui.id_ab_user_info
                 WHERE aui.id_ab_user_info = i_user_id
                 ORDER BY asiui.dt_log_tstz DESC NULLS LAST)
         WHERE rownum = 1;
    
        l_lang := to_number(pk_login_sysconfig.get_config('LANGUAGE'));
    
        o_lang := nvl(o_lang, l_lang);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            l_error := SQLERRM;
            pk_alert_exceptions.process_error(i_lang     => o_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => l_error,
                                              i_message  => l_error,
                                              i_owner    => k_package_owner,
                                              i_package  => k_package_name,
                                              i_function => k_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END get_prof_login_info;

BEGIN

    inicialize();
END pk_ux_profile;
/
