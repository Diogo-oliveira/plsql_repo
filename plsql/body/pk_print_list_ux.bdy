/*-- Last Change Revision: $Rev: 1922708 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2019-10-29 08:31:42 +0000 (ter, 29 out 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_print_list_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_retval  BOOLEAN;
    g_exception_np EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    FUNCTION get_print_list_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_shortcut OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PRINT_LIST.GET_PRINT_LIST_SHORTCUT';
        IF NOT pk_print_list.get_print_list_shortcut(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_episode  => i_episode,
                                                     o_shortcut => o_shortcut,
                                                     o_error    => o_error)
        THEN
            RAISE g_exception_np;
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
                                              'GET_PRINT_LIST_SHORTCUT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_print_list_shortcut;

    /**
    * Get print jobs list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)  
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   o_print_list_jobs    Cursor with the print jobs list
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   23-09-2014
    */
    FUNCTION get_print_jobs_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_print_jobs OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_jobs_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient ||
                    ' i_episode=' || i_episode;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.get_print_jobs_list / ' || l_params;
        g_retval := pk_print_list.get_print_jobs_list(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_patient    => i_patient,
                                                      i_episode    => i_episode,
                                                      o_print_jobs => o_print_jobs,
                                                      o_error      => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_print_jobs);
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_print_jobs);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_print_jobs_list;

    /**
     * Get information for add button
     *
     * @param   i_lang               Preferred language id for this professional
     * @param   i_prof               Professional id structure
     * @param   i_id_sys_button_prop SysButtonProp Identifier (used for get acesses for childrens)
     * @param   o_list               List of values
     * @param   o_error              Error information
     *
     * @return  boolean              True on sucess, otherwise false
     *
     * @author  miguel.gomes
     * @since   1-10-2014
    */
    FUNCTION get_actions_button_add
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_btn_prp_parent%TYPE,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_actions_button_add';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_sys_button_prop=' ||
                    i_id_sys_button_prop;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.get_actions_button_add / ' || l_params;
        g_retval := pk_print_list.get_actions_button_add(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_sys_button_prop => i_id_sys_button_prop,
                                                         o_list               => o_list,
                                                         o_error              => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_actions_button_add;

    /**
    * Set list jobs status to cancel
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          List print list job identifiers  
    * @param   o_id_print_list_job          List print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @since   30-09-2014
    */
    FUNCTION set_print_jobs_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_cancel';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.set_print_jobs_cancel / ' || l_params;
        g_retval := pk_print_list.set_print_jobs_cancel(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_print_list_job => i_id_print_list_job,
                                                        o_id_print_list_job => o_id_print_list_job,
                                                        o_error             => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_print_jobs_cancel;

    /**
    * Gets print list configuration to generate report
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)  
    * @param   o_config         Config value
    * @param   o_error          Error information
    *
    * @value   o_config         {*} PP - Preview and print
    *                           {*} P  - Print
    *                           {*} BP - Generate in background and print
    *                           {*} B  - Only generate in background  
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   08-10-2014
    */
    FUNCTION get_generate_report_cfg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_config OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_generate_report_cfg';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.get_generate_report_cfg / ' || l_params;
        RETURN pk_print_list.get_generate_report_cfg(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     o_config => o_config,
                                                     o_error  => o_error);
    
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_generate_report_cfg;

    /**
    * Checks if this professional has the functionality of printing
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_flg_can_print       Flag that indicates if professional has the functionality of printing
    * @param   o_error               Error information
    *
    * @value   o_flg_can_print       {*} Y- this professional has the functionality of printing {*} N- otherwise
    *  
    * @return  boolean               True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   29-09-2014
    */
    FUNCTION check_func_can_print
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_flg_can_print OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_func_can_print';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.check_func_can_print / ' || l_params;
        RETURN pk_print_list.check_func_can_print(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  o_flg_can_print => o_flg_can_print,
                                                  o_error         => o_error);
    
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_func_can_print;

    /**
    * Gets all print list jobs print arguments
    * Used by reports in order to generate reports in background
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)   
    * @param   i_id_print_list_jobs    Array of print list jobs identifiers
    * @param   o_print_args            Print arguments of the print list jobs identifiers
    * @param   o_error                 Error information
    *
    * @return  boolean                 True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   17-10-2014
    */
    FUNCTION get_print_list_jobs_args
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_print_list_jobs IN table_number,
        o_print_args         OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_list_jobs_args';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.get_print_list_jobs_args / ' || l_params;
        RETURN pk_print_list.get_print_list_jobs_args(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_print_list_jobs => i_id_print_list_jobs,
                                                      o_print_args         => o_print_args,
                                                      o_error              => o_error);
    
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_print_list_jobs_args;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_print_list_ux;
/
