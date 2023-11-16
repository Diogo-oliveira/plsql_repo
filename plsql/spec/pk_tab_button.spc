/*-- Last Change Revision: $Rev: 2029004 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_tab_button IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 23-02-2010 10:37:13
    -- Purpose : Package responsible for managing the tab button in the ALERT application.

    /*
    * Returns all available tab buttons that should be presented to one user depending on is profile
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  SUBJECT                     SUBJECT string that identifies the tab buttons that should be returned
    * @param  O_TAB_BUTTON                information of available tab buttons
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Elisabete Bugalho
    * @version 1.0
    * @since   23-Feb-2010
    *
    */
    FUNCTION get_prof_tab_button
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN tab.subject%TYPE,
        o_tab_button OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the default option for this professional
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  SUBJECT                     SUBJECT string that identifies the tab buttons that should be returned
    * @param  o_tab_button_default        Default tab button
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Elisabete Bugalho
    * @version 1.0
    * @since   23-Feb-2010
    *
    */
    FUNCTION get_prof_tab_button_default
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_subject            IN tab.subject%TYPE,
        o_tab_button_default OUT tab_button_ptm.flg_identifier%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    -- Log initialization.
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error VARCHAR2(1000);
    -- Global Variables
    g_yes CONSTANT VARCHAR2(0001) := 'Y';
    g_no  CONSTANT VARCHAR2(0001) := 'N';

END pk_tab_button;
/
