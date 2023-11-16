/*-- Last Change Revision: $Rev: 1631606 $*/
/*-- Last Change by: $Author: rui.spratley $*/
/*-- Date of last change: $Date: 2014-09-10 10:51:04 +0100 (qua, 10 set 2014) $*/

CREATE OR REPLACE PACKAGE pk_ux_profile IS

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
    ) RETURN BOOLEAN;

END pk_ux_profile;
/
