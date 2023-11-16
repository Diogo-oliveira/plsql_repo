/*-- Last Change Revision: $Rev: 2028434 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_access IS

    /**
    * Auxiliary type for get_shortcuts_array
    */
    TYPE map_vnumber IS TABLE OF NUMBER INDEX BY VARCHAR2(200);
    k_sbp_visible CONSTANT VARCHAR2(0001 CHAR) := 'Y';

    TYPE t_shortcut IS RECORD(
        id_sys_application_area    NUMBER(24),
        btn_dest                   NUMBER(24),
        screen_name                VARCHAR2(1000 CHAR),
        flg_area                   VARCHAR2(1 CHAR),
        deepnav_id_sys_button_prop NUMBER(24),
        btn_label                  pk_translation.t_desc_translation,
        son_intern_name            VARCHAR2(1000 CHAR),
        btn_parent                 NUMBER(24),
        btn_prop_parent            NUMBER(24),
        screen_area                NUMBER(24),
        screen_area_parent         NUMBER(24),
        par_intern_name            VARCHAR2(1000 CHAR),
        id_sys_button_prop         NUMBER(24),
        exist_child                VARCHAR2(0001 CHAR),
        action                     VARCHAR2(1000 CHAR),
        msg_copyright              VARCHAR2(1000 CHAR),
        flg_screen_mode            VARCHAR2(2 CHAR),
        screen_params              table_varchar);

    TYPE c_shortcut IS REF CURSOR RETURN t_shortcut;

    PROCEDURE open_my_cursor(i_cursor IN OUT c_shortcut);

    /**
    * Preloads a few shortcuts into a global variable, which can be
    * accessed quickly and efficiently later. For more details see get_shortcuts_array.
    * NOTE: Calling this functions mutiple times does not accumulate.
    *       Previous shortcuts are erased.
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info
    * @param i_screens table_varchar with screen names (sys_shortcut.intern_name)
    * @param i_scr_alias alias array to get the shortcut id. Each alias matches with the
    *        intern_name in the same position on the i_screens array
    * @return false (error), true (all ok)
    *
    * @author -
    * @version -
    * @since -
    */

    FUNCTION preload_shortcuts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_screens   IN table_varchar,
        i_scr_alias IN table_varchar DEFAULT NULL,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a shortcut id, after being properly preloaded using preload_shortcuts
    *
    * @param i_intern_name the name, or alias, of the shortcut
    *
    * @return the shortcut id
    * @author -
    * @version -
    * @since -
    */
    FUNCTION get_shortcut(i_intern_name sys_shortcut.intern_name%TYPE) RETURN sys_shortcut.id_sys_shortcut%TYPE;

    /**
    *
    *
    * @param i_lang language id
    * @param i_id_prof object with user info (Professional ID, Institution ID, Software ID)
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    /*
    -- hidden by CMF on 18/05/2018
    FUNCTION set_prof_acc_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    */
    /**
    * Get the buttons that professional have on an applicaion area
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_application_area application area
    * @param o_access list of application areas
    * @param o_sub_button
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION get_prof_access_new
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN NUMBER,
        i_episode          IN NUMBER,
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        o_access           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get deep_navs that professional have access on a button or sub deep_navs inside a deep_nav
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_id_button button to analyse
    * @param i_id_button_prop
    * @param i_application_area application area
    * @param o_sub_butt list deep_navs
    * @param o_parent returns info from the parent button
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION get_prof_access_sub_butt_new
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN NUMBER,
        i_episode          IN NUMBER,
        i_id_button        IN sys_button.id_sys_button%TYPE,
        i_id_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        o_sub_butt         OUT pk_types.cursor_type,
        o_parent           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the "parents" button of a shortcut destiny
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_short professional's shortcut
    * @param o_parent "Parents" of shortcut button
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION get_shortcut_parent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_parent OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verify if button have deep_nav child and if professional have access to them
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_application_area application area
    * @param i_id_button button to verify
    *
    * @return list of deep_nav child
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION exist_child
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN NUMBER,
        i_episode          IN NUMBER,
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        i_id_button        IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2;

    /**
    * Verify if button have parents and if professional have access to them
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_application_area application area
    * @param i_id_button button to verify
    *
    * @return list of parents
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION exist_parent(i_id_button IN sys_button_prop.id_sys_button_prop%TYPE) RETURN VARCHAR2;

    /**
    *  Set user alerts
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION set_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN department.id_department%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Delete alerts from user accordingly to the profiles, software and institution been removed beeing removed.
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION del_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_ID_SHORTCUT                  Gets the shortcut associated to the given intern_name
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_field                   Functionality internal name
    * @param o_val                     Value result ('Y' - exists; 'N' - not exists)
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Luís Maia
    * @version                         2.6.1.2
    * @since                           21-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION check_has_prof_field
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN sys_functionality.intern_name_func%TYPE,
        o_val   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_field_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_field   IN sys_field.id_sys_field%TYPE,
        o_func    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_func    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION find_prof_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_func    IN prof_func.id_functionality%TYPE,
        o_exist   OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_room    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION count_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_episode   IN NUMBER,
        i_id_button IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER;

    /**
    * Return all approaches to the software/profile that the user is authenticated.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_environment        Environment information (institution/software)
    * @param o_approaches         The approaches list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION get_software_approaches
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_environment OUT pk_types.cursor_type,
        o_approaches  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets the approach of the authenticated professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_val_appr           The approach val to be used
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION set_prof_approach
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_val_appr IN profile_template.flg_approach%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the command string for setting an action to call an external application in a sys_button_prop
    *
    * @param i_external_app       External application id
    *
    * @return                Correct command string to use on sys_button_prop
    *
    * @author                Fábio Oliveira
    * @version               2.6.0.2
    * @since                 01-Apr-2010
    */
    FUNCTION get_external_app_string(i_external_app IN NUMBER) RETURN VARCHAR2;

    /**
    * Sets the action to call an external application in a sys_button_prop
    *
    * @param i_sys_button_prop   SYS_BUTTON_PROP id
    * @param i_external_app      External application id
    *
    * @author                Fábio Oliveira
    * @version               2.6.0.2
    * @since                 01-Apr-2010
    */
    PROCEDURE set_action_external_app
    (
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_external_app    IN NUMBER
    );

    ----------------------------------------------------------

    /**
    * Get buttons that professional have access when enter on a shortcut
    *
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_short professional's shortcut
    * @param o_access buttons that professional have access
    * @param o_parent "Parents" of shortcut button
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION get_shortcut
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access OUT c_shortcut,
        o_prt    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_screen_name_by_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_short       IN sys_shortcut.id_sys_shortcut%TYPE,
        o_screen_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grandparent_button_info
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN NUMBER,
        i_episode            IN NUMBER,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_sql                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_first_child_button_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_patient              IN NUMBER,
        i_episode              IN NUMBER,
        o_id_button_prop_child OUT sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_child      OUT sys_button.id_sys_button%TYPE,
        o_id_screen_area       OUT sys_screen_area.id_sys_screen_area%TYPE,
        o_screen_name          OUT sys_button_prop.screen_name%TYPE,
        o_flg_screen_mode      OUT sys_button_prop.flg_screen_mode%TYPE,
        o_screen_params        OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns first child of given button, ordered by rank
    *
    * @param i_lang                 Id da language
    * @param i_prof                 ID Professional, ID institution, ID software
    * @param i_application_area     Application area ID
    * @param i_id_button            id_sys_button_prop of given button
    *
    * @author                Rui Batista
    * @version               2.6.1
    * @since                 04-03-2011
    */
    FUNCTION get_first_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_episode   IN NUMBER,
        i_id_button IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER;

    /**
    * Returns prepared string according to flag configured
    *
    * @param i_action        action from sys_button_prop
    *
    * @author                Carlos Ferreira
    * @version               2.6.5.2
    * @since                 04-03-2011
    */
    FUNCTION get_string_action(i_action IN VARCHAR2) RETURN VARCHAR2;
	
    FUNCTION get_grandparent_button_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN NUMBER,
        i_episode            IN NUMBER,
        i_application_area   IN sys_application_area.id_sys_application_area%TYPE,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_sql                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_first_child_button_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN NUMBER,
        i_episode              IN NUMBER,
        i_application_area     IN sys_application_area.id_sys_application_area%TYPE,
        i_id_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_prop_child OUT sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_child      OUT sys_button.id_sys_button%TYPE,
        o_id_screen_area       OUT sys_screen_area.id_sys_screen_area%TYPE,
        o_screen_name          OUT sys_button_prop.screen_name%TYPE,
        o_flg_screen_mode      OUT sys_button_prop.flg_screen_mode%TYPE,
        o_screen_params        OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_button_prop_params(i_id_sys_button_prop sys_button_prop.id_sys_button_prop%TYPE) RETURN table_varchar;

    /********************************************************************************************
    * GET_ID_SHORTCUT                  Gets the shortcut associated to the given intern_name
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Shortcut internal name
    * @param i_flg_validate_parent     Y-returns only the shortcuts with id_parent = null. N-do not validate the id_parent
    * @param o_id_shortcut             Shortcut id
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_id_shortcut
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intern_name         IN sys_shortcut.intern_name%TYPE,
        i_flg_validate_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_id_shortcut         OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_msg_copyright
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_msg  IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_screen_name
    (
        i_action      IN VARCHAR2,
        i_screen_name IN VARCHAR2,
        i_count_child IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_action
    (
        i_action      IN VARCHAR2,
        i_count_child IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION check_func
    (
        i_flg_value           IN VARCHAR2,
        i_check_functionality IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC;

    FUNCTION get_access
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN NUMBER,
        i_episode         IN NUMBER,
        i_id_button_prop  IN table_number,
        i_flg_visible_all IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_access_pta
    (
        i_prof                IN profissional,
        i_pat_age             IN NUMBER,
        i_pat_gender          IN VARCHAR2,
        i_epis_type           IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_access_ptae
    (
        i_prof                IN profissional,
        i_pat_age             IN NUMBER,
        i_pat_gender          IN VARCHAR2,
        i_epis_type           IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_access_pta_ptae
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_agg_access
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN NUMBER,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_agg_access
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access;

    FUNCTION get_profile_template_tree( i_prof in profissional, i_id_profile_template IN NUMBER) RETURN table_number;

    /********************************************************************************************
    * set_button_text                  sets text/title for a sys_button_prop. REturned on 
    *                                  function get_prof_access_new on cursor o_access.button_text .
    * @param i_lang                    language associated to the professional executing the request
    * @param i_id_sys_button_prop      id of sys_button_prop to configure
    * @param i_text                    text associated with given sys_button_prop
    *
    * @author                          Carlos Ferreira
    * @version                         2.6.2.1.7
    * @since                           12-09-2012
    *
    **********************************************************************************************/
    PROCEDURE set_button_text
    (
        i_lang               IN NUMBER,
        i_id_sys_button_prop IN NUMBER,
        i_text               IN VARCHAR2
    );

    FUNCTION get_deepnav
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN NUMBER,
        l_id_profile_template IN NUMBER
    ) RETURN t_tbl_access;

    FUNCTION get_profile(i_prof IN profissional) RETURN profile_template%ROWTYPE;

    /**
    * Validates if a shortcut is available for profissional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional executing the request
    * @param i_shortcut                shortcut to valdiate
    *
    * @return 0 no records and >0 with records
    *
    * @author Rui Spratley
    * @version 2.6.2
    * @since 2012-oct-11
    */
    FUNCTION verify_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN NUMBER,
        i_episode  IN NUMBER,
        i_shortcut sys_shortcut.id_sys_shortcut%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * Get all alert id by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_serv_sys_alert
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN table_number;
    /********************************************************************************************
    * Get all No alerts configuration flg by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID   
    * @param i_service                Service ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_no_alert_validation
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * get_sys_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE
    * @param i_screen_name    sys_button_prop.screen_name%TYPE
    * @param o_id_sys_shortcut        id_sys_shortcut
    * @param o_error                     error message
    *
    * @return                         boolean
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.3
    * @since                          2014/03/11
    **********************************************************************************************/
    FUNCTION get_sys_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_screen_name        IN sys_button_prop.screen_name%TYPE,
        o_id_sys_shortcut    OUT profile_templ_access.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000); -- Localização do erro
    g_sbs_visible CONSTANT sys_button_prop.flg_visible%TYPE := 'Y';
    g_func_available  sys_functionality.flg_available%TYPE;
    g_field_available sys_field.flg_available%TYPE;
    g_found           BOOLEAN;
    g_flg_type_remove CONSTANT profile_templ_access_exception.flg_type%TYPE := 'R';
    g_flg_type_add    CONSTANT profile_templ_access_exception.flg_type%TYPE := 'A';
    -- internal name for view only profile functionality
    g_view_only_profile CONSTANT sys_functionality.intern_name_func%TYPE := 'READ ONLY PROFILE';
    g_exception EXCEPTION;

    g_package_owner CONSTANT VARCHAR2(6 CHAR) := 'ALERT';
    g_package_name VARCHAR2(32 CHAR);

    /*
        FUNCTION get_shortcuts_array
        (
            i_lang      IN language.id_language%TYPE,
            i_prof      IN profissional,
            i_screens   IN table_varchar,
            i_scr_alias IN table_varchar DEFAULT NULL,
            o_shortcuts OUT map_vnumber,
            o_error     OUT t_error_out
        ) RETURN BOOLEAN;
    
        FUNCTION get_shortcuts_array
        (
            i_lang      IN language.id_language%TYPE,
            i_prof      IN profissional,
            i_patient   IN NUMBER,
            i_episode   IN NUMBER,
            i_screens   IN table_varchar,
            i_scr_alias IN table_varchar DEFAULT NULL,
            o_shortcuts OUT map_vnumber,
            o_error     OUT t_error_out
        ) RETURN BOOLEAN;
    */
    FUNCTION get_shortcut
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access OUT c_shortcut,
        o_prt    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

--   FUNCTION get_sbp_area(i_application_area IN NUMBER) RETURN table_number;

    FUNCTION get_shortcut_html
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_short   IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access  OUT pk_types.cursor_type,
        o_prt     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_access;
/
