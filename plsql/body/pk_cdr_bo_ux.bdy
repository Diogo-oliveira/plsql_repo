/*-- Last Change Revision: $Rev: 2026857 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cdr_bo_ux IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    /**********************************************************************************************
    * Get list of definitions for the settings grid screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_list              list of definitions for the settings grid screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_setting_grid_def
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_rule_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_GRID_DEF';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'CALL pk_cdr_bo_core.get_setting_grid_def';
        IF NOT pk_cdr_bo_core.get_setting_grid_def(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   o_rule_list => o_rule_list,
                                                   o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_list);
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
    END get_setting_grid_def;

    /**********************************************************************************************
    * Get list of definitions for the settings selection screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of definitions for the selection screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_setting_select_def
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_rule_def_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SELECT_DEF';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'CALL pk_cdr_bo_core.get_setting_select_def';
        IF NOT pk_cdr_bo_core.get_setting_select_def(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     o_rule_def_list => o_rule_def_list,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_def_list);
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
    END get_setting_select_def;

    /**********************************************************************************************
    * Returns the list of definition rules from a determine type
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_type            Id type of cdr
    * @param o_def_list               list of definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_setting_select_def_by_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_cdr_type IN cdr_type.id_cdr_type%TYPE,
        o_def_list    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SELECT_DEF_BY_TYPE';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_setting_select_def_by_type';
        IF NOT pk_cdr_bo_core.get_setting_select_def_by_type(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_cdr_type => i_id_cdr_type,
                                                             o_def_list    => o_def_list,
                                                             o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_def_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_def_list);
            RETURN FALSE;
    END get_setting_select_def_by_type;

    /**********************************************************************************************
    * Get list of exceptions for the settings summary screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param o_exception              list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_setting_summary_def
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_exception  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SUMMARY_DEF';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_setting_summary_def';
        IF NOT pk_cdr_bo_core.get_setting_summary_def(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_definition => i_definition,
                                                      o_exception  => o_exception,
                                                      o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_exception);
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_exception);
            RETURN FALSE;
    END get_setting_summary_def;

    /**
    * Get list of exceptions for the settings summary screen,
    * through user setting defined lists.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_definition   rule definition identifier
    * @param i_software     software identifiers list
    * @param i_specialty    specialty identifiers list
    * @param i_profile      profile identifiers list
    * @param i_professional professional identifiers list
    * @param i_severity     severity identifiers list
    * @param i_action       action identifiers list
    * @param i_e_soft       exception software identifiers list
    * @param i_e_spec       exception specialty identifiers list
    * @param i_e_pt         exception profile identifiers list
    * @param i_e_prof       exception professional identifiers list
    * @param i_e_cdrs       exception severity identifiers list
    * @param i_e_cdra       exception action identifiers list
    * @param o_exception    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/25
    */
    FUNCTION get_setting_summary_def_coll
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_definition   IN cdr_definition.id_cdr_definition%TYPE,
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        i_e_soft       IN table_number,
        i_e_spec       IN table_number,
        i_e_pt         IN table_number,
        i_e_prof       IN table_number,
        i_e_cdrs       IN table_number,
        i_e_cdra       IN table_number,
        o_exception    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SETTING_SUMMARY_DEF_COLL';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_setting_summary_def_coll';
        IF NOT pk_cdr_bo_core.get_setting_summary_def_coll(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_definition   => i_definition,
                                                           i_software     => i_software,
                                                           i_specialty    => i_specialty,
                                                           i_profile      => i_profile,
                                                           i_professional => i_professional,
                                                           i_severity     => i_severity,
                                                           i_action       => i_action,
                                                           i_e_soft       => i_e_soft,
                                                           i_e_spec       => i_e_spec,
                                                           i_e_pt         => i_e_pt,
                                                           i_e_prof       => i_e_prof,
                                                           i_e_cdrs       => i_e_cdrs,
                                                           i_e_cdra       => i_e_cdra,
                                                           o_exception    => o_exception,
                                                           o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_exception);
            RETURN FALSE;
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
            pk_types.open_my_cursor(i_cursor => o_exception);
            RETURN FALSE;
    END get_setting_summary_def_coll;

    /**********************************************************************************************
    * Returns the list of all rules instance execptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_inst_list         list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_rules_inst_settings
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_rule_inst_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_RULES_INST_SETTINGS');
    
        g_error := 'OPEN CURSOR o_rule_inst_list';
        IF NOT pk_cdr_bo_core.get_rules_inst_settings(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      o_rule_inst_list => o_rule_inst_list,
                                                      o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_inst_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RULES_INST_SETTINGS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rules_inst_settings;

    /**********************************************************************************************
    * Get list of actions by definition.
    *
    * @param i_lang                   the id language
    * @param i_definition             ID Definition
    * @param o_list                   list of definition actions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/24
    **********************************************************************************************/
    FUNCTION get_list_action_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_ACTION_BY_DEF';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_action_by_def';
        IF NOT pk_cdr_bo_core.get_list_action_by_def(i_lang       => i_lang,
                                                     i_definition => i_definition,
                                                     o_list       => o_list,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
    END get_list_action_by_def;

    /**********************************************************************************************
    * Returns the list of department filtered by a list of software
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_dept_list              list of department available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_department
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_software  IN table_number,
        o_dept_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_DEPARTMENT';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_department';
        IF NOT pk_cdr_bo_core.get_list_department(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_software  => i_software,
                                                  o_dept_list => o_dept_list,
                                                  o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_dept_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_dept_list);
            RETURN FALSE;
    END get_list_department;

    /**********************************************************************************************
    * Get list of professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param i_dep_clin_serv          table with dep_clin_serv 
    * @param i_profile_template       table with profile_template 
    * @param o_list                   list of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_professional
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN table_number,
        i_dep_clin_serv    IN table_number,
        i_profile_template IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_PROFESSIONAL';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'CALL pk_cdr_bo_core.get_list_professional';
        IF NOT pk_cdr_bo_core.get_list_professional(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_software         => i_software,
                                                    i_dep_clin_serv    => i_dep_clin_serv,
                                                    i_profile_template => i_profile_template,
                                                    o_list             => o_list,
                                                    o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
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
    END get_list_professional;

    /**********************************************************************************************
    * Get list of profiles.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_list                   list of profiles
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_profile
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_software IN table_number,
        o_templ    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_list_profile';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_software:' ||
                              pk_utils.concat_table(i_tab => i_software) || ']',
                              g_package,
                              l_func_name);
    
        g_error := 'CALL  pk_cdr_bo_core.get_list_profile';
        IF NOT pk_cdr_bo_core.get_list_profile(i_lang     => i_lang,
                                               i_prof     => i_prof,
                                               i_software => i_software,
                                               o_templ    => o_templ,
                                               o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_templ);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_list_profile;

    /**
    * Get list of services by department.
    *
    * @param i_lang         language identifier
    * @param i_dept         department identifier
    * @param o_list         list of services by department
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/24
    */
    FUNCTION get_list_service
    (
        i_lang  IN language.id_language%TYPE,
        i_dept  IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SERVICE';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_service';
        IF NOT pk_cdr_bo_core.get_list_service(i_lang => i_lang, i_dept => i_dept, o_list => o_list, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
    END get_list_service;

    /**
    * Get list of severities by definition.
    *
    * @param i_lang         language identifier
    * @param i_definition   rule definition identifier
    * @param o_list         list of severities by definition
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/18
    */
    FUNCTION get_list_severity_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SEVERITY_BY_DEF';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_severity_by_def';
        IF NOT pk_cdr_bo_core.get_list_severity_by_def(i_lang       => i_lang,
                                                       i_definition => i_definition,
                                                       o_list       => o_list,
                                                       o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
    END get_list_severity_by_def;

    /**********************************************************************************************
    * Get list of softwares.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_software               list of softwares
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_software
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_SOFTWARE';
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']', g_package, l_func_name);
    
        g_error := 'CALL pk_cdr_bo_core.get_list_software';
        IF NOT pk_cdr_bo_core.get_list_software(i_lang     => i_lang,
                                                i_prof     => i_prof,
                                                o_software => o_software,
                                                o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_software);
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
    END get_list_software;

    /**********************************************************************************************
    * Returns the list of dep_clin_serv by department and service.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_dept                   department identifier
    * @param i_department             service identifier
    * @param o_list                   list of dep_clin_serv available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/05
    **********************************************************************************************/
    FUNCTION get_list_specialty
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dept       IN dept.id_dept%TYPE,
        i_department IN department.id_department%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_list_specialty';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_specialty';
        IF NOT pk_cdr_bo_core.get_list_specialty(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_dept       => i_dept,
                                                 i_department => i_department,
                                                 o_list       => o_list,
                                                 o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
    END get_list_specialty;

    /**********************************************************************************************
    * Get list of rule types.
    *
    * @param i_lang                   the id language
    * @param i_prof                   logged professional structure
    * @param o_list                   list of rule types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_list_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_LIST_TYPE';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_list_type';
        IF NOT pk_cdr_bo_core.get_list_type(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_list_type;

    /**********************************************************************************************
    * Set definition settings.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_severity               instance severity
    * @param i_action                 list os distinct action of instance                  
    * @param o_cdrdcf_ids             created setting identifiers                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_setting_def
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_definition   IN cdr_definition.id_cdr_definition%TYPE,
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        o_cdrdcf_ids   OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_SETTING_DEF';
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.set_setting_def';
        IF NOT pk_cdr_bo_core.set_setting_def(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_definition   => i_definition,
                                              i_software     => i_software,
                                              i_specialty    => i_specialty,
                                              i_profile      => i_profile,
                                              i_professional => i_professional,
                                              i_severity     => i_severity,
                                              i_action       => i_action,
                                              o_cdrdcf_ids   => o_cdrdcf_ids,
                                              o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_setting_def;

    /**********************************************************************************************
    * Returns the list of action types available
    *
    * @param i_lang                   the id language
    * @param o_action_type_list       list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/15
    **********************************************************************************************/
    FUNCTION get_action_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_cdr_bo_core.get_action_type_list(i_lang             => i_lang,
                                                   o_action_type_list => o_action_type_list,
                                                   o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_action_type_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ACTION_TYPE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_action_type_list;

    /**********************************************************************************************
    * Returns the list of severity types available
    *
    * @param i_lang                   the id language
    * @param o_severity_type_list     list of severity types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_severity_type_list
    (
        i_lang               IN language.id_language%TYPE,
        o_severity_type_list OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.get_severity_type_list';
        IF NOT pk_cdr_bo_core.get_severity_type_list(i_lang               => i_lang,
                                                     o_severity_type_list => o_severity_type_list,
                                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_severity_type_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SEVERITY_TYPE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_severity_type_list;

    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_conditions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_condition_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_cdr_bo_core.get_cdr_conditions(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 o_condition_list => o_condition_list,
                                                 o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_condition_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_WARNING_TYPE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_conditions;

    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_definition_concepts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_concepts_list     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ']',
                              g_package,
                              'GET_CDR_DEFINITION_CONCEPTS');
        g_error := 'OPEN o_condition_list';
        IF NOT pk_cdr_bo_core.get_cdr_definition_concepts(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_cdr_definition => i_id_cdr_definition,
                                                          o_concepts_list     => o_concepts_list,
                                                          o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_concepts_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_DEFINITION_CONCEPTS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_definition_concepts;

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is either NULL or not.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition (Only in cases that we want the list of instances of a definition)
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/19
    **********************************************************************************************/
    FUNCTION get_rules_instances_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_rule_inst_list    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_definition:' ||
                              i_id_cdr_definition || ']',
                              g_package,
                              'GET_RULES_INSTANCES_LIST');
    
        g_error := 'CALL pk_cdr_bo_core.get_rules_instances_list';
        IF NOT pk_cdr_bo_core.get_rules_instances_list(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_cdr_definition => i_id_cdr_definition,
                                                       o_rule_inst_list    => o_rule_inst_list,
                                                       o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rule_inst_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RULES_INSTANCES_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_rules_instances_list;

    /**********************************************************************************************
    * Set/change the rule instance state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_instance_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_cdr_status      IN cdr_instance.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_RULES_INSTANCES_LIST');
    
        IF NOT pk_cdr_bo_core.set_cdr_instance_status(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_id_cdr_instance => i_id_cdr_instance,
                                                      i_cdr_status      => i_cdr_status,
                                                      o_error           => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'SET_CDR_INSTANCE_STATUS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_cdr_instance_status;

    /**********************************************************************************************
    * Set/change the rule definition state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_definition_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_cdr_status        IN cdr_definition.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_cdr_bo_core.set_cdr_definition_status';
        IF NOT pk_cdr_bo_core.set_cdr_definition_status(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_cdr_definition => i_id_cdr_definition,
                                                        i_cdr_status        => i_cdr_status,
                                                        o_error             => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'SET_CDR_DEFINITION_STATUS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_cdr_definition_status;

    /**********************************************************************************************
    * Get all information to the edit screen in order to edit a rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of all rule definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_edit_cdr_definition
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_cdr_definition      IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_definition         OUT pk_types.cursor_type,
        o_cdr_def_condition      OUT pk_types.cursor_type,
        o_cdr_concepts           OUT pk_types.cursor_type,
        o_cdr_actions            OUT pk_types.cursor_type,
        o_cdr_severity           OUT pk_types.cursor_type,
        o_cdr_parameters         OUT pk_types.cursor_type,
        o_cdr_parameters_actions OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_core.get_edit_cdr_definition';
        IF NOT pk_cdr_bo_core.get_edit_cdr_definition(i_lang                   => i_lang,
                                                      i_prof                   => i_prof,
                                                      i_id_cdr_definition      => i_id_cdr_definition,
                                                      o_cdr_definition         => o_cdr_definition,
                                                      o_cdr_def_condition      => o_cdr_def_condition,
                                                      o_cdr_concepts           => o_cdr_concepts,
                                                      o_cdr_actions            => o_cdr_actions,
                                                      o_cdr_severity           => o_cdr_severity,
                                                      o_cdr_parameters         => o_cdr_parameters,
                                                      o_cdr_parameters_actions => o_cdr_parameters_actions,
                                                      o_screen_labels          => o_screen_labels,
                                                      o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cdr_definition);
            pk_types.open_my_cursor(o_cdr_def_condition);
            pk_types.open_my_cursor(o_cdr_concepts);
            pk_types.open_my_cursor(o_cdr_actions);
            pk_types.open_my_cursor(o_cdr_severity);
            pk_types.open_my_cursor(o_cdr_parameters);
            pk_types.open_my_cursor(o_cdr_parameters_actions);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EDIT_CDR_DEFINITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_edit_cdr_definition;

    /**********************************************************************************************
    * Cancel Rule definition
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_definition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_notes             IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_definition:' ||
                              i_id_cdr_definition || ' i_cancel_reason:' || i_cancel_reason || ']',
                              g_package,
                              'CANCEL_CDR_DEFINITION');
    
        g_error := 'CALL  pk_cdr_bo_core.cancel_cdr_definition';
        IF NOT pk_cdr_bo_core.cancel_cdr_definition(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_cdr_definition => i_id_cdr_definition,
                                                    i_notes             => i_notes,
                                                    i_cancel_reason     => i_cancel_reason,
                                                    o_error             => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'CANCEL_CDR_DEFINITION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_cdr_definition;

    /**********************************************************************************************
    * Cancel Rule instance
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_instance
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_notes           IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ' i_cancel_reason:' || i_cancel_reason || ']',
                              g_package,
                              'CANCEL_CDR_DEFINITION');
    
        g_error := 'CALL  pk_cdr_bo_core.cancel_cdr_instance';
        IF NOT pk_cdr_bo_core.cancel_cdr_instance(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_cdr_instance => i_id_cdr_instance,
                                                  i_notes           => i_notes,
                                                  i_cancel_reason   => i_cancel_reason,
                                                  o_error           => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'CANCEL_CDR_INSTANCE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_cdr_instance;

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is NOT NULL.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_cdr_instances
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_inst          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_definition:' ||
                              i_id_cdr_definition || ']',
                              g_package,
                              'GET_CDR_INSTANCES');
    
        g_error := 'CALL pk_cdr_bo_core.get_rules_instances_list';
        IF NOT pk_cdr_bo_core.get_cdr_instances(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_cdr_definition => i_id_cdr_definition,
                                                o_cdr_inst          => o_cdr_inst,
                                                o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cdr_inst);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CDR_INSTANCES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_cdr_instances;

    /**********************************************************************************************
    * Returns the list of all cdr instance exceptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_inst_exception     list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_cdr_inst_exception
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_cdr_instance    IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_inst_exception OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_CDR_INST_EXCEPTION');
    
        g_error := 'CALL pk_cdr_bo_core.get_cdr_inst_exception';
        IF NOT pk_cdr_bo_core.get_cdr_inst_exception(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_cdr_instance    => i_id_cdr_instance,
                                                     o_cdr_inst_exception => o_cdr_inst_exception,
                                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_cdr_inst_exception);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_CDR_INST_EXCEPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_inst_exception;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_labels             list of all labels used on screen
    * @param o_software               list of software exceptions
    * @param o_profile                list of profile templates exceptions
    * @param o_dep_clin_serv          list of dep_clin_serv exceptions
    * @param o_professional           list of professionals exceptions
    * @param o_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION get_edit_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_labels      OUT pk_types.cursor_type,
        o_software        OUT pk_types.cursor_type,
        o_profile         OUT pk_types.cursor_type,
        o_dep_clin_serv   OUT pk_types.cursor_type,
        o_professional    OUT pk_types.cursor_type,
        o_action          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'GET_EDIT_CDR_INST_EXCEPTION');
    
        g_error := 'CALL pk_cdr_bo_core.get_cdr_def_exception';
        IF NOT pk_cdr_bo_core.get_edit_cdr_inst_exception(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_cdr_instance => i_id_cdr_instance,
                                                          o_cdr_labels      => o_cdr_labels,
                                                          o_software        => o_software,
                                                          o_profile         => o_profile,
                                                          o_dep_clin_serv   => o_dep_clin_serv,
                                                          o_professional    => o_professional,
                                                          o_action          => o_action,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_cdr_labels);
            pk_types.open_my_cursor(o_software);
            pk_types.open_my_cursor(o_profile);
            pk_types.open_my_cursor(o_dep_clin_serv);
            pk_types.open_my_cursor(o_professional);
            pk_types.open_my_cursor(o_action);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EDIT_CDR_INST_EXCEPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_edit_cdr_inst_exception;

    /**********************************************************************************************
    * Cancel a instance exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_ins_config      ID rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_inst_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_ins_config cdr_inst_config.id_cdr_inst_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_ins_config:' ||
                              i_id_cdr_ins_config || ']',
                              g_package,
                              'cancel_cdr_inst_exception');
    
        g_error := 'CALL pk_cdr_bo_core.cancel_cdr_inst_exception';
        IF NOT pk_cdr_bo_core.cancel_cdr_inst_exception(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_cdr_ins_config => i_id_cdr_ins_config,
                                                        o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_CDR_INST_EXCEPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_cdr_inst_exception;

    /**********************************************************************************************
    * Cancel a definition exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_def_config      ID rule definition exception 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_def_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_def_config cdr_inst_config.id_cdr_inst_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_def_config:' ||
                              i_id_cdr_def_config || ']',
                              g_package,
                              'cancel_cdr_inst_exception');
    
        g_error := 'CALL pk_cdr_bo_core.cancel_cdr_def_exception';
        IF NOT pk_cdr_bo_core.cancel_cdr_def_exception(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_cdr_def_config => i_id_cdr_def_config,
                                                       o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_CDR_DEF_EXCEPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_cdr_def_exception;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Elisabete Bugalho
     * @version                         0.1
     * @since                           2011/05/03
    **********************************************************************************************/
    FUNCTION get_cdr_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_subject   IN action.subject%TYPE,
        i_exception IN NUMBER,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[i_subject:' || i_subject || ' i_exception:' || i_exception || ']',
                              g_package,
                              'get_cdr_actions');
    
        g_error := 'CALL pk_cdr_bo_core.get_cdr_actions';
        IF NOT pk_cdr_bo_core.get_cdr_actions(i_lang      => i_lang,
                                              i_subject   => i_subject,
                                              i_exception => i_exception,
                                              o_actions   => o_actions,
                                              o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_profile_template_list',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_actions;

    /**********************************************************************************************
    * Returns the list of action types available  for a instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_warning_type_list      list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_cdr_inst_action_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cdr_instance  IN cdr_instance.id_cdr_instance%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_id_cdr_instance:' ||
                              i_id_cdr_instance || ']',
                              g_package,
                              'get_cdr_inst_action_list');
    
        g_error := 'CALL pk_cdr_bo_core.get_cdr_inst_action_list';
        IF NOT pk_cdr_bo_core.get_cdr_inst_action_list(i_lang             => i_lang,
                                                       i_prof             => i_prof,
                                                       i_id_cdr_instance  => i_id_cdr_instance,
                                                       o_action_type_list => o_action_type_list,
                                                       o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_action_type_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_cdr_inst_action_list',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_cdr_inst_action_list;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/06
    **********************************************************************************************/

    FUNCTION set_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_software        IN table_number,
        i_profile         IN table_number,
        i_dep_clin_serv   IN table_number,
        i_professional    IN table_number,
        i_action          IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[Institution: ' || i_prof.institution || ' i_software:' ||
                              pk_utils.concat_table(i_tab => i_software) || ']',
                              g_package,
                              'GET_DEPT_LIST');
    
        g_error := 'CALL pk_cdr_bo_core.get_dept_list';
        IF NOT pk_cdr_bo_core.set_cdr_inst_exception(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_cdr_instance => i_id_cdr_instance,
                                                     i_software        => i_software,
                                                     i_profile         => i_profile,
                                                     i_dep_clin_serv   => i_dep_clin_serv,
                                                     i_professional    => i_professional,
                                                     i_action          => i_action,
                                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'set_cdr_inst_exception',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_cdr_inst_exception;
    /**
    *  Set the Status of a rule (id_Cdr_definition) on table cdr_def_inst by [A]dd or [R]emove
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.set_rule_status';
        IF NOT pk_cdr_bo_core.set_rule_status(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_cdr_definition => i_id_cdr_definition,
                                              i_flg_add_remove    => i_flg_add_remove,
                                              o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'set_rule_status',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_rule_status;
    /**
    *  Get the rule (id_cdr_definition) data in bulk, definition, status, url info button
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_sep               IN VARCHAR2 DEFAULT ' - ',
        i_sep_final         IN VARCHAR2 DEFAULT '; ',
        o_rule_info         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.get_rule_bulk';
    
        IF NOT pk_cdr_bo_core.get_rule_bulk(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_cdr_definition => i_id_cdr_definition,
                                            i_sep               => i_sep,
                                            i_sep_final         => i_sep_final,
                                            o_rule_info         => o_rule_info,
                                            o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_rule_bulk',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_rule_bulk;

    /**
    *  Return Y or N if have or not exceptions
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_have_exceptions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_have_exceptions   OUT sys_domain.val%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.GET_HAVE_EXCEPTIONS';
    
        IF NOT pk_cdr_bo_core.get_have_exceptions(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_id_cdr_definition => i_id_cdr_definition,
                                                  o_have_exceptions   => o_have_exceptions,
                                                  o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_HAVE_EXCEPTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_have_exceptions;

    /**
    *  set the rule data in bulk, links, status
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        i_id_links          IN links.id_links%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.set_rule_bulk';
    
        IF NOT pk_cdr_bo_core.set_rule_bulk(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_cdr_definition => i_id_cdr_definition,
                                            i_flg_add_remove    => i_flg_add_remove,
                                            i_id_links          => i_id_links,
                                            o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_RULE_BULK',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_rule_bulk;

    /**
    *  get the rule detail
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.get_rule_detail';
    
        IF NOT pk_cdr_bo_core.get_rule_detail(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_cdr_definition => i_id_cdr_definition,
                                              o_history           => o_history,
                                              o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_RULE_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rule_detail;

    /**
    *  get the rule detail history
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL pk_cdr_bo_ux.get_rule_detail_hist';
    
        IF NOT pk_cdr_bo_core.get_rule_detail_hist(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_cdr_definition => i_id_cdr_definition,
                                                   o_history           => o_history,
                                                   o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_RULE_DETAIL_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rule_detail_hist;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_cdr_bo_ux;
/
