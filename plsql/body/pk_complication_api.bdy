/*-- Last Change Revision: $Rev: 2026894 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_complication_api IS

    -- Private variable declarations
    g_general_error EXCEPTION;

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Gets the list of complications for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_complications             List of complications for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-12-2009
    */
    FUNCTION get_epis_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_complications OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_COMPLICATIONS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET EPIS_COMPLICATIONS';
        IF NOT pk_complication_core.get_epis_complications(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_episode       => i_episode,
                                                           o_complications => o_complications,
                                                           o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_complications);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complications);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_complications;

    /**
    * Gets the list of requests for the given episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_requests                  List of requests for the given episode
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_epis_requests
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_requests OUT NOCOPY pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_EPIS_REQUESTS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET EPIS_REQUESTS';
        IF NOT pk_complication_core.get_epis_requests(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_episode  => i_episode,
                                                      o_requests => o_requests,
                                                      o_error    => o_error)
        THEN
            pk_types.open_my_cursor(o_requests);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_requests;

    /**
    * Gets the list of complication specific button actions
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   i_type                      C - Complication; R - Request
    * @param   i_subject                   Subject: CREATE - Button create options; ACTION - Button action options
    * @param   o_actions                   List of actions
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-12-2009
    */
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_type              IN VARCHAR2,
        i_subject           IN action.subject%TYPE,
        o_actions           OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ACTIONS';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET ACTIONS';
        IF NOT pk_complication_core.get_actions(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_epis_complication => i_epis_complication,
                                                i_type              => i_type,
                                                i_subject           => i_subject,
                                                o_actions           => o_actions,
                                                o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    /**
    * Gets the specified selection list type
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   i_parent_axe                Parent axe id or NULL to get root values
    * @param   o_axes                      List of pathologies/locations/external factors/effects
    * @param   o_max_level                 Maximum level that has this type of lis
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_axes_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type       IN sys_list_group_rel.flg_context%TYPE,
        i_parent_axe IN comp_axe.id_comp_axe%TYPE,
        o_axes       OUT pk_types.cursor_type,
        o_max_level  OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_AXES_LIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET AXES';
        IF NOT pk_complication_core.get_axes_list(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_type       => i_type,
                                                  i_parent_axe => i_parent_axe,
                                                  o_axes       => o_axes,
                                                  o_max_level  => o_max_level,
                                                  o_error      => o_error)
        THEN
            pk_types.open_my_cursor(o_axes);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_axes);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_axes_list;

    /**
    * Gets selection list type groups
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_type                      Type of list to be returned
    * @param   o_groups                    List of pathologies/locations/external factors/effects
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @value   i_type                      P  - Pathology
    *                                      L  - Location
    *                                      EF - External factor
    *                                      E  - Effect
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-03-2009
    */
    FUNCTION get_axes_grp_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN sys_list_group_rel.flg_context%TYPE,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_AXES_GRP_LIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET AXES';
        IF NOT pk_complication_core.get_axes_grp_list(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_type   => i_type,
                                                      o_groups => o_groups,
                                                      o_error  => o_error)
        THEN
            pk_types.open_my_cursor(o_groups);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_groups);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_axes_grp_list;

    /**
    * Gets the complication selection list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_def_path                  List of default complications pathologies
    * @param   o_def_loc                   List of default complications locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   09-12-2009
    */
    FUNCTION get_complication_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT NOCOPY pk_types.cursor_type,
        o_def_path      OUT NOCOPY pk_types.cursor_type,
        o_def_loc       OUT NOCOPY pk_types.cursor_type,
        o_def_ext_fact  OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_LIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATIONS';
        IF NOT pk_complication_core.get_complication_list(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          o_complications => o_complications,
                                                          o_def_path      => o_def_path,
                                                          o_def_loc       => o_def_loc,
                                                          o_def_ext_fact  => o_def_ext_fact,
                                                          o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_complications);
            pk_types.open_my_cursor(o_def_path);
            pk_types.open_my_cursor(o_def_loc);
            pk_types.open_my_cursor(o_def_ext_fact);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complications);
            pk_types.open_my_cursor(o_def_path);
            pk_types.open_my_cursor(o_def_loc);
            pk_types.open_my_cursor(o_def_ext_fact);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complication_list;

    /**
    * Gets the complication selection list (Without default values)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_complications             List of complications
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_lst
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_complications OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_LST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATIONS';
        IF NOT pk_complication_core.get_complication_lst(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         o_complications => o_complications,
                                                         o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_complications);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complications);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complication_lst;

    /**
    * Gets the complication default values lists
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_complication              Complication id
    * @param   o_def_path                  List of default pathologies
    * @param   o_def_loc                   List of default locations
    * @param   o_def_ext_fact              List of default external factors
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   23-03-2010
    */
    FUNCTION get_complication_dft_lst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_complication IN complication.id_complication%TYPE,
        o_def_path     OUT pk_complication_core.epis_comp_def_cursor,
        o_def_loc      OUT pk_complication_core.epis_comp_def_cursor,
        o_def_ext_fact OUT pk_complication_core.epis_comp_def_cursor,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_DFT_LST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATION DEFAULT VALUES';
        IF NOT pk_complication_core.get_complication_dft_lst(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_complication => i_complication,
                                                             o_def_path     => o_def_path,
                                                             o_def_loc      => o_def_loc,
                                                             o_def_ext_fact => o_def_ext_fact,
                                                             o_error        => o_error)
        THEN
            pk_types.open_my_cursor(o_def_path);
            pk_types.open_my_cursor(o_def_loc);
            pk_types.open_my_cursor(o_def_ext_fact);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_def_path);
            pk_types.open_my_cursor(o_def_loc);
            pk_types.open_my_cursor(o_def_ext_fact);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complication_dft_lst;

    /**
    * Get complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_comp_detail               All complication detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_comp_detail       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATION DATA';
        IF NOT pk_complication_core.get_complication(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_epis_complication => i_epis_complication,
                                                     o_complication      => o_complication,
                                                     o_comp_detail       => o_comp_detail,
                                                     o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_complication);
            pk_types.open_my_cursor(o_comp_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complication);
            pk_types.open_my_cursor(o_comp_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complication;

    /**
    * Gets complication detail data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_complication              All complication data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_complication_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_complication      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_COMPLICATION_DETAIL';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATION DETAIL DATA';
        IF NOT pk_complication_core.get_complication_detail(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_epis_complication => i_epis_complication,
                                                            o_complication      => o_complication,
                                                            o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_complication);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complication);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_complication_detail;

    /**
    * Gets request data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Episode complication id
    * @param   o_request                   All request data
    * @param   o_request_detail            All request detail data
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   04-01-2010
    */
    FUNCTION get_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        o_request           OUT pk_types.cursor_type,
        o_request_detail    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'GET COMPLICATION DATA';
        IF NOT pk_complication_core.get_request(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_epis_complication => i_epis_complication,
                                                o_request           => o_request,
                                                o_request_detail    => o_request_detail,
                                                o_error             => o_error)
        THEN
            pk_types.open_my_cursor(o_request);
            pk_types.open_my_cursor(o_request_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_request);
            pk_types.open_my_cursor(o_request_detail);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_request;

    /**
    * Add/Upd a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication, Otherwise is to update a existing complication
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_complication_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_COMPLICATION_INT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CREATE COMPLICATION';
        IF NOT pk_complication_core.set_complication(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_cols              => i_cols,
                                                     i_vals              => i_vals,
                                                     i_is_ins            => i_is_ins,
                                                     o_epis_complication => o_epis_complication,
                                                     o_epis_comp_detail  => o_epis_comp_detail,
                                                     o_epis_comp_prof    => o_epis_comp_prof,
                                                     o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_complication_int;

    /**
    * Add/Upd a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   i_is_ins                    True - Is to insert a new complication request, Otherwise is to update a existing complication request
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_comp_request_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        i_is_ins            IN BOOLEAN,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_COMP_REQUEST_INT';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CREATE COMPLICATION REQUEST';
        IF NOT pk_complication_core.set_request(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_cols              => i_cols,
                                                i_vals              => i_vals,
                                                i_is_ins            => i_is_ins,
                                                o_epis_complication => o_epis_complication,
                                                o_epis_comp_detail  => o_epis_comp_detail,
                                                o_epis_comp_prof    => o_epis_comp_prof,
                                                o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_comp_request_int;

    /**
    * Add a new complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION create_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CREATE COMPLICATION';
        IF NOT set_complication_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_cols              => i_cols,
                                    i_vals              => i_vals,
                                    i_is_ins            => TRUE,
                                    o_epis_complication => o_epis_complication,
                                    o_epis_comp_detail  => o_epis_comp_detail,
                                    o_epis_comp_prof    => o_epis_comp_prof,
                                    o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_complication;

    /**
    * Update a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CREATE COMPLICATION';
        IF NOT set_complication_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_cols              => i_cols,
                                    i_vals              => i_vals,
                                    i_is_ins            => FALSE,
                                    o_epis_complication => o_epis_complication,
                                    o_epis_comp_detail  => o_epis_comp_detail,
                                    o_epis_comp_prof    => o_epis_comp_prof,
                                    o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_complication;

    /**
    * Add a new complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION create_comp_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_COMP_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CREATE COMPLICATION REQUEST';
        IF NOT set_comp_request_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_cols              => i_cols,
                                    i_vals              => i_vals,
                                    i_is_ins            => TRUE,
                                    o_epis_complication => o_epis_complication,
                                    o_epis_comp_detail  => o_epis_comp_detail,
                                    o_epis_comp_prof    => o_epis_comp_prof,
                                    o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_comp_request;

    /**
    * Update a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_epis_complication         Created epis complication id
    * @param   o_epis_comp_detail          Created epis comp detail id's
    * @param   o_epis_comp_prof            Created epis comp prof id's
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-12-2009
    */
    FUNCTION set_comp_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_cols              IN table_varchar,
        i_vals              IN table_varchar,
        o_epis_complication OUT epis_complication.id_epis_complication%TYPE,
        o_epis_comp_detail  OUT table_number,
        o_epis_comp_prof    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_COMP_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'SET COMPLICATION REQUEST';
        IF NOT set_comp_request_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_cols              => i_cols,
                                    i_vals              => i_vals,
                                    i_is_ins            => FALSE,
                                    o_epis_complication => o_epis_complication,
                                    o_epis_comp_detail  => o_epis_comp_detail,
                                    o_epis_comp_prof    => o_epis_comp_prof,
                                    o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_comp_request;

    /********************************************************************************************
    * Gets the list of tasks to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   o_type_tasks                Type of tasks
    * @param   o_tasks                     Tasks list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_assoc_task_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_type_tasks OUT pk_types.cursor_type,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ASSOC_TASK_LIST';
    
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO GET_ASSOC_TASK_LIST';
        IF NOT pk_complication_core.get_assoc_task_list(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_patient    => i_patient,
                                                        i_episode    => i_episode,
                                                        o_type_tasks => o_type_tasks,
                                                        o_tasks      => o_tasks,
                                                        o_error      => o_error)
        THEN
            pk_types.open_my_cursor(o_type_tasks);
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_type_tasks);
            pk_types.open_my_cursor(o_tasks);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_assoc_task_list;

    /********************************************************************************************
    * Gets the type of treatments to associate with the complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_treat                     Types of treatment
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6
    * @since   04-01-2010
    ********************************************************************************************/
    FUNCTION get_treat_perf_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_treat OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_TREAT_PERF_LIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO GET_TREAT_PERF_LIST';
        IF NOT pk_complication_core.get_treat_perf_list(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_treat => o_treat,
                                                        o_error => o_error)
        THEN
            pk_types.open_my_cursor(o_treat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_treat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_treat_perf_list;

    /**
    * Cancel a complication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_complication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_COMPLICATION';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO CANCEL_COMPLICATION';
        IF NOT pk_complication_core.cancel_complication(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_epis_complication => i_epis_complication,
                                                        i_cancel_reason     => i_cancel_reason,
                                                        i_notes_cancel      => i_notes_cancel,
                                                        o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_complication;

    /**
    * Cancel a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_cancel_reason             Cancel reason id
    * @param   i_notes_cancel              Cancelation notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION cancel_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_cancel_reason     IN epis_complication.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_complication.notes_cancel%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO CANCEL_REQUEST';
        IF NOT pk_complication_core.cancel_request(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_epis_complication => i_epis_complication,
                                                   i_cancel_reason     => i_cancel_reason,
                                                   i_notes_cancel      => i_notes_cancel,
                                                   o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_request;

    /**
    * Reject a complication request
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_complication         Epis complication id
    * @param   i_reject_reason             Reject reason id
    * @param   i_notes_reject              Reject notes
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   06-01-2010
    */
    FUNCTION set_reject_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_complication IN epis_complication.id_epis_complication%TYPE,
        i_reject_reason     IN epis_complication.id_reject_reason%TYPE,
        i_notes_reject      IN epis_complication.notes_rejected%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_REJECT_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO REJECT_REQUEST';
        IF NOT pk_complication_core.set_reject_request(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_epis_complication => i_epis_complication,
                                                       i_reject_reason     => i_reject_reason,
                                                       i_notes_reject      => i_notes_reject,
                                                       o_error             => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_reject_request;

    /**
    * Accept the request and insert complication data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_cols                      Columns names
    * @param   i_vals                      Columns values
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   07-01-2009
    */
    FUNCTION set_accept_request
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_cols  IN table_varchar,
        i_vals  IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_REJECT_REQUEST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO ACCEPT_REQUEST';
        IF NOT pk_complication_core.set_accept_request(i_lang  => i_lang,
                                                       i_prof  => i_prof,
                                                       i_cols  => i_cols,
                                                       i_vals  => i_vals,
                                                       o_error => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_accept_request;

    /**
    * Gets discharge confirmation message
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   o_show                      Y - Confirmation message is to be shown; Otherwise N
    * @param   o_title                     Confirmation title
    * @param   o_quest                     Confirmation question
    * @param   o_msg                       Confirmation message
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   25-02-2010
    */
    FUNCTION get_disch_conf_msg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_show    OUT VARCHAR2,
        o_title   OUT VARCHAR2,
        o_quest   OUT VARCHAR2,
        o_msg     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DISCH_CONF_MSG';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO DISCH_CONF_MSG';
        IF NOT pk_complication_core.get_disch_conf_msg(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_episode => i_episode,
                                                       o_show    => o_show,
                                                       o_title   => o_title,
                                                       o_quest   => o_quest,
                                                       o_msg     => o_msg,
                                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_disch_conf_msg;

    /**
    * Gets the clinical services list to which the current professional is allocated
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   o_clin_serv                 Clinical services list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   01-03-2010
    */
    FUNCTION get_prof_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_CLIN_SERV_LIST';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO PROF_CLIN_SERV';
        IF NOT pk_complication_core.get_prof_clin_serv_list(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            o_clin_serv => o_clin_serv,
                                                            o_error     => o_error)
        THEN
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_clin_serv);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_clin_serv_list;

    /**
    * Get domain values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_code_dom                  Element domain
    * @param   i_dep_clin_serv             Dep_clin_serv ID                                                              
    * @param   o_data                      Domain values list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  ALEXANDRE.SANTOS
    * @version v2.6
    * @since   18-03-2010
    */
    FUNCTION get_domain_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_dom      IN sys_domain.code_domain%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DOMAIN_VALUES';
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        g_error := 'CALL TO GET_DOMAIN_VALUES';
        IF NOT pk_complication_core.get_domain_values(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_code_dom      => i_code_dom,
                                                      i_dep_clin_serv => i_dep_clin_serv,
                                                      o_data          => o_data,
                                                      o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_domain_values;

    /**********************************************************************************************
    * Get complaint for CDA section: Chief Complaint and Reason for Visit
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_complaint             Cursor with all complaints for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.3
    * @since                         2013/12/23 
    ***********************************************************************************************/
    FUNCTION get_epis_complaint_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        o_complaint  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(32 CHAR) := 'GET_EPIS_COMPLAINT_CDA';
    BEGIN
        g_error := 'GET EPIS_COMPLICATIONS RECORDS';
        IF NOT pk_complaint.get_epis_complaint_cda(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_scope      => i_scope,
                                                   i_scope_type => i_scope_type,
                                                   o_complaint  => o_complaint,
                                                   o_error      => o_error)
        THEN
            pk_types.open_my_cursor(o_complaint);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_complaint);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_complaint_cda;

BEGIN
    -- Initialization
    --< STATEMENT >;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_complication_api;
/
