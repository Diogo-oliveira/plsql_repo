/*-- Last Change Revision: $Rev: 2028913 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_reset IS

    -- Author  : JOANA.BARROSO
    -- Created : 16-04-2010 12:32:24
    -- Purpose : 

    /**
    *  This function deletes all data related to Referral.
    *
    * @param      I_LANG                      Language ID
    * @param      I_ID_EXTERNAL_REQUEST       External Request ID
    * @param      O_ERROR                     Error message
    *
    * @return     BOOLEAN             TRUE if sucess, FALSE otherwise
    *
    * @author     Ana Coelho
    * @version
    * @since      12/04/2010
    */

    FUNCTION CLEAR_REFERRAL_RESET
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    g_lang_en_usa CONSTANT LANGUAGE.id_language%TYPE := 2;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    g_exception EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;
    g_null         CONSTANT VARCHAR2(1) := NULL;
    g_default_lang CONSTANT LANGUAGE.id_language%TYPE := g_lang_en_usa;

    SUBTYPE flag IS VARCHAR2(1 CHAR);
    SUBTYPE counter IS NUMBER(24);
    SUBTYPE medium_var IS VARCHAR2(200 CHAR);
    SUBTYPE max_var IS VARCHAR2(1000 CHAR);
    SUBTYPE log_var IS VARCHAR2(10000 CHAR);
    SUBTYPE package_var IS VARCHAR2(50 CHAR);
    SUBTYPE exec_date IS DATE;
    SUBTYPE ids_to_reset_var IS log_var;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Log variables
    g_func_name     package_var;
    g_package_name  package_var;
    g_package_owner package_var;
    g_lang          LANGUAGE.id_language%TYPE := g_default_lang;

END pk_ref_reset;
/
