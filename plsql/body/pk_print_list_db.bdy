/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_print_list_db IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_retval  BOOLEAN;
    g_exception_np EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    /**
    * Add new print job to print jobs table
    *
    * @param   i_lang                 preferred language id for this professional
    * @param   i_prof                 professional id structure
    * @param   i_patient              patient id
    * @param   i_episode              episode id
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List of context data needed to relate the print list job with its area
    * @param   i_print_arguments      List of print arguments
    * @param   o_print_list_jobs      cursor with the print jobs ids list
    * @param   o_error                error information    
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   07-10-2014
    */
    FUNCTION add_print_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        i_print_arguments  IN table_varchar,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_jobs';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_areas=' || pk_utils.to_string(i_print_list_areas);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.add_print_jobs / ' || l_params;
        g_retval := pk_print_list.add_print_jobs(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_patient          => i_patient,
                                                 i_episode          => i_episode,
                                                 i_print_list_areas => i_print_list_areas,
                                                 i_context_data     => i_context_data,
                                                 i_print_arguments  => i_print_arguments,
                                                 o_print_list_jobs  => o_print_list_jobs,
                                                 o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END add_print_jobs;

    /**
    * Add a print list job to the print list, in a predefined state. No print arguments are set.
    *
    * @param   i_lang                 preferred language id for this professional
    * @param   i_prof                 professional id structure
    * @param   i_patient              patient id
    * @param   i_episode              episode id
    * @param   i_print_list_areas     List of print area ids
    * @param   i_context_data         List with print jobs context data
    * @param   o_print_list_jobs      List of print list jobs identifiers created
    * @param   o_error                error information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   10-10-2014
    */
    FUNCTION add_print_jobs_predef
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'add_print_jobs_predef';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_areas=' || pk_utils.to_string(i_print_list_areas);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.add_print_jobs_predef / ' || l_params;
        g_retval := pk_print_list.add_print_jobs_predef(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_patient          => i_patient,
                                                        i_episode          => i_episode,
                                                        i_print_list_areas => i_print_list_areas,
                                                        i_context_data     => i_context_data,
                                                        o_print_list_jobs  => o_print_list_jobs,
                                                        o_error            => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END add_print_jobs_predef;

    /**
    * Check if exists a similar job related to this context data in print list
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  VARCHAR2                     Y- exists a similar job in print list N- otherwise
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   08-10-2014
    */
    FUNCTION check_if_context_exists
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN print_list_job.id_patient%TYPE DEFAULT NULL,
        i_episode                IN print_list_job.id_episode%TYPE,
        i_print_list_area        IN print_list_job.id_print_list_area%TYPE,
        i_print_job_context_data IN print_list_job.context_data%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_if_context_exists';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.check_if_context_exists / ' || l_params;
        RETURN pk_print_list.check_if_context_exists(i_lang                   => i_lang,
                                                     i_prof                   => i_prof,
                                                     i_patient                => i_patient,
                                                     i_episode                => i_episode,
                                                     i_print_list_area        => i_print_list_area,
                                                     i_print_job_context_data => i_print_job_context_data);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN NULL;
    END check_if_context_exists;

    /**
    * Set list jobs status to cancel
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job          list print list job identifiers  
    * @param   o_id_print_list_job          list print list job identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                     
    *
    * @author  miguel.gomes
    * @version 1.0
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
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
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
                                                        i_flg_ignore_prof_req => pk_alert_constant.g_yes,
                                                        o_id_print_list_job => o_id_print_list_job,
                                                        o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END set_print_jobs_cancel;

    /**
    * Changes status of the print list jobs to pending
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)    
    * @param   i_id_print_list_job    list print list job identifiers  
    * @param   i_print_arguments      list of print arguments
    * @param   o_id_print_list_job    list print list job identifiers
    * @param   o_error                Error information
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   10-10-2014
    */
    FUNCTION set_print_jobs_pending
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        i_print_arguments   IN table_varchar,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_pending';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.set_print_jobs_pending / ' || l_params;
        g_retval := pk_print_list.set_print_jobs_pending(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_print_list_job => i_id_print_list_job,
                                                         i_print_arguments   => i_print_arguments,
                                                         o_id_print_list_job => o_id_print_list_job,
                                                         o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END set_print_jobs_pending;

    /**
    * Set list jobs status to error
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
    FUNCTION set_print_jobs_error
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_error';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.set_print_jobs_error / ' || l_params;
        g_retval := pk_print_list.set_print_jobs_error(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_print_list_job => i_id_print_list_job,
                                                       o_id_print_list_job => o_id_print_list_job,
                                                       o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END set_print_jobs_error;

    /**
    * Set list jobs status to complete
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
    FUNCTION set_print_jobs_complete
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN table_number,
        o_id_print_list_job OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_print_jobs_complete';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_job=' ||
                    pk_utils.to_string(i_id_print_list_job);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.set_print_jobs_complete / ' || l_params;
        g_retval := pk_print_list.set_print_jobs_complete(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_print_list_job => i_id_print_list_job,
                                                          o_id_print_list_job => o_id_print_list_job,
                                                          o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END set_print_jobs_complete;

    /**
     * Gets print list default option
     *
     * @param   i_lang               preferred language id for this professional
     * @param   i_prof               professional id structure
     * @param   i_print_list_area    Print list area identifier
     * @param   o_default_option     Default option configured for this print list area
     * @param   o_error              error information    
     *
     * @return  boolean              True on sucess, otherwise false
     *
     * @author  ana.monteiro
     * @since   10-10-2014
    */
    FUNCTION get_print_list_def_option
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        o_default_option  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_print_list_def_option';
        l_configs v_print_list_cfg%ROWTYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        -- get configs for a given print list area
        g_error  := 'Call pk_print_list.get_print_list_configs / id_print_list_area=' || i_print_list_area || ' / ' ||
                    l_params;
        g_retval := pk_print_list.get_print_list_configs(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_print_list_area => i_print_list_area,
                                                         o_print_list_cfgs => l_configs,
                                                         o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        o_default_option := l_configs.flg_print_option_default;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END get_print_list_def_option;

    /**
    * Delete all print lists n days after episode close. Number of days is a configurable for each area
    *   
    * @author  Miguel Gomes
    * @version 1.0
    * @since   13-10-2014
    */
    PROCEDURE clear_print_list IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'CLEAR_PRINT_LIST';
        l_error_out t_error_out;
        l_lang      language.id_language%TYPE;
    
    BEGIN
        g_error := 'Init ' || l_func_name;
        pk_alertlog.log_debug(g_error);
        pk_print_list.clear_print_list;
    
        COMMIT;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_utils.undo_changes;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            pk_utils.undo_changes;
    END clear_print_list;

    /**
    * Checks if this professional can add a job to the print list
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   o_flg_can_add         Flag that indicates if professional can add a job to the print list
    * @param   o_error               An error message, set when return=false
    *
    * @value   o_flg_can_add         {*} Y- this professional can add {*} N- otherwise
    *  
    * @return  boolean               True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   09-10-2014
    */
    FUNCTION check_func_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_can_add';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.check_func_can_add / ' || l_params;
        g_retval := pk_print_list.check_func_can_add(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     o_flg_can_add => o_flg_can_add,
                                                     o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END check_func_can_add;

    /**
    * Gets all print list jobs of the print list, that are similar to print list job context data
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    * @param   i_print_job_context_data     Print list job context data
    *
    * @return  table_number                 Print list jobs that are similar to i_print_list_job
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   07-10-2014
    */
    FUNCTION get_similar_print_list_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN print_list_job.id_patient%TYPE,
        i_episode                IN print_list_job.id_episode%TYPE,
        i_print_list_area        IN print_list_job.id_print_list_area%TYPE,
        i_print_job_context_data IN print_list_job.context_data%TYPE
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_similar_print_list_jobs';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.get_similar_print_list_jobs / ' || l_params;
        RETURN pk_print_list.get_similar_print_list_jobs(i_lang                   => i_lang,
                                                         i_prof                   => i_prof,
                                                         i_patient                => i_patient,
                                                         i_episode                => i_episode,
                                                         i_print_list_area        => i_print_list_area,
                                                         i_print_job_context_data => i_print_job_context_data);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN table_number();
    END get_similar_print_list_jobs;

    /**
    * Gets all print list jobs identifiers of the print list
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_patient                    Patient identifier
    * @param   i_episode                    Episode identifier
    * @param   i_print_list_area            Print list area identifier
    *
    * @return  table_number                 Print list jobs identifiers that are in print list
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   15-10-2014
    */
    FUNCTION get_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN print_list_job.id_patient%TYPE,
        i_episode         IN print_list_job.id_episode%TYPE,
        i_print_list_area IN print_list_job.id_print_list_area%TYPE
    ) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_print_list_jobs';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_print_list_area=' || i_print_list_area;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error := 'Call pk_print_list.get_print_list_jobs / ' || l_params;
        RETURN pk_print_list.get_print_list_jobs(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_patient         => i_patient,
                                                 i_episode         => i_episode,
                                                 i_print_list_area => i_print_list_area);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
            RETURN table_number();
    END get_print_list_jobs;

    /**
    * Gets all print list jobs print arguments
    * Used by reports in order to generate reports in background
    *
    * @param   i_lang                       preferred language id for this professional
    * @param   i_prof                       professional id structure
    * @param   i_id_print_list_jobs         Array of print list jobs identifiers
    * @param   o_print_args                 Print arguments of the print list jobs identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
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
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_print_list_jobs=' ||
                    pk_utils.to_string(i_id_print_list_jobs);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.get_print_list_jobs_args / ' || l_params;
        g_retval := pk_print_list.get_print_list_jobs_args(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_print_list_jobs => i_id_print_list_jobs,
                                                           o_print_args         => o_print_args,
                                                           o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END get_print_list_jobs_args;

    /**
    * This function deletes all data related to print list jobs of an episode
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patients                Array of patient identifiers
    * @param   i_id_episodes                Array of episode identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   16-10-2014
    */
    FUNCTION reset_print_list_job
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'reset_print_list_job';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patients.count=' || i_id_patients.count ||
                    ' i_id_episodes.count=' || i_id_episodes.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.reset_print_list_job / ' || l_params;
        g_retval := pk_print_list.reset_print_list_job(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_patients => i_id_patients,
                                                       i_id_episodes => i_id_episodes,
                                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END reset_print_list_job;

    /**
    * Updates a print list job data: context_data and print_arguments
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)   
    * @param   i_print_list_jobs      List with the print jobs ids
    * @param   i_context_data         List of new context data
    * @param   i_print_arguments      List of new print arguments
    * @param   o_print_list_jobs      List with the print jobs ids updated
    * @param   o_error                Error information    
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   26-11-2014
    */
    FUNCTION update_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_print_list_jobs IN table_number,
        i_context_data    IN table_clob,
        i_print_arguments IN table_varchar,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'update_print_list_jobs';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_print_list_jobs=' ||
                    substr(pk_utils.to_string(i_print_list_jobs), 1, 200) || ' i_context_data.count=' ||
                    i_context_data.count || ' i_print_arguments.count=' || i_print_arguments.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_print_list.update_print_list_jobs / ' || l_params;
        g_retval := pk_print_list.update_print_list_jobs(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_print_list_jobs => i_print_list_jobs,
                                                         i_context_data    => i_context_data,
                                                         i_print_arguments => i_print_arguments,
                                                         o_print_list_jobs => o_print_list_jobs,
                                                         o_error           => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
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
            RETURN FALSE;
    END update_print_list_jobs;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_print_list_db;
/
