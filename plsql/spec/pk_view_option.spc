/*-- Last Change Revision: $Rev: 2029039 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_view_option IS

    -- Author  : LUIS.MAIA
    -- Created : 06-03-2009 14:14:11
    -- Purpose : Package responsible for managing the View button in the ALERT application.

    /*
    * Returns all available options that should be presented to one user when selected the VIEW button.
    * (the result depends of professional profile, selected button and selected button parent button)
    *
    * @param  I_LANG                      language associated to the professional executing the request
    * @param  I_PROF                      professional (ID, INSTITUTION, SOFTWARE)
    * @param  I_SUBJECT                   SUBJECT string that identifies the view options that should be returned to FLASH
    * @param  O_VIEW_OPTIONS              information of available options in VIEW button
    * @param  O_ERROR                     warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Maia
    * @version 1.0
    * @since   09-Mar-2009
    *
    */
    FUNCTION get_prof_view_options
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN view_option.subject%TYPE,
        o_view_options OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_default_view
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN view_option.subject%TYPE,
        o_id_view_option OUT view_option.id_view_option%TYPE,
        o_screen         OUT view_option.screen_identifier%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    --
    -- Log initialization.
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --
    g_error                    VARCHAR2(1000);
    g_generic_db_error_message VARCHAR2(0050);

    -- Global Variables
    g_yes CONSTANT VARCHAR2(0001) := 'Y';
    g_no  CONSTANT VARCHAR2(0001) := 'N';

END pk_view_option;
/
