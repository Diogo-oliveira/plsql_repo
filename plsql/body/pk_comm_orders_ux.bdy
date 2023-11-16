/*-- Last Change Revision: $Rev: 1917580 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2019-09-19 09:26:02 +0100 (qui, 19 set 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_orders_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_retval  BOOLEAN;
    g_exception_np EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    /**
    * Get the list of communication order types
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   o_list               Cursor containing information about communication order types
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN NUMBER,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_comm_order_type_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_type_list / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_type_list(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_task_type => i_task_type,
                                                            o_list      => o_list,
                                                            o_error     => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_type_list;

    /**
    * Get the list of communication orders related to this communication order type
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_comm_order_type Communication order type identifier
    * @param   i_id_comm_order_par  Communication order parent identifier. If specified, returns all communication orders 'sons'
    * @param   o_list               Cursor containing information about communication orders
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_selection_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order_type IN NUMBER, -- COMMUNICATION_ORDERS_EA.id_concept_type%TYPE
        i_id_comm_order_par  IN NUMBER, -- COMMUNICATION_ORDERS_EA.id_concept_term%TYPE
        i_task_type          IN NUMBER,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_selection_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_type=' || i_id_comm_order_type ||
                    ' i_id_comm_order_par=' || i_id_comm_order_par;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_selection_list / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_selection_list(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_id_comm_order_type => i_id_comm_order_type,
                                                                 i_id_comm_order_par  => i_id_comm_order_par,
                                                                 i_task_type          => i_task_type,
                                                                 o_list               => o_list,
                                                                 o_error              => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_selection_list;

    /**
    * Search communication orders by name 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_comm_order_search  String to search for communication orders
    * @param   o_list               Cursor containing information about communication orders 
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   13-02-2014
    */
    FUNCTION get_comm_order_search
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_comm_order_search IN pk_translation.t_desc_translation,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_comm_order_search';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_comm_order_search=' || i_comm_order_search;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_search / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_search(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_comm_order_search => i_comm_order_search,
                                                         o_list              => o_list,
                                                         o_error             => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_search;

    /**
    * Returns a list of options with the clinical purpose for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_clinical_purpose
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_clinical_purpose';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_clinical_purpose / ' || l_params;
        g_retval := pk_comm_orders.get_clinical_purpose(i_lang  => i_lang,
                                                        i_prof  => i_prof,
                                                        o_list  => o_list,
                                                        o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_clinical_purpose;

    /**
    * Returns a list of options with the priority for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_priority
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_priority';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_priority / ' || l_params;
        g_retval := pk_comm_orders.get_priority(i_lang  => i_lang,
                                                i_prof  => i_prof,
                                                o_list  => o_list,
                                                o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_priority;

    /**
    * Returns a list of options with the prn for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   14-02-2014
    */
    FUNCTION get_prn
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_prn';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_prn / ' || l_params;
        g_retval := pk_comm_orders.get_prn(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_prn;

    /**
    * Returns a list of options with diagnoses for a communication order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)    
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   18-02-2014
    */
    FUNCTION get_diagnoses_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_diagnoses_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode;
    
        g_error  := 'Call pk_comm_orders.get_diagnoses_list / ' || l_params;
        g_retval := pk_comm_orders.get_diagnoses_list(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_episode => i_episode,
                                                      o_list    => o_list,
                                                      o_error   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_diagnoses_list;

    /**
    * Returns instructions default
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order              Array of communication order identifiers
    * @param   i_id_comm_order_type         Array of communication order types identifiers
    * @param   o_list                       Cursor containing information about instructions default
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   19-02-2014
    */
    FUNCTION get_instructions_default
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_comm_order      IN table_number,
        i_id_comm_order_type IN table_number,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_instructions_default';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order.count=' || i_id_comm_order.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_instructions_default / ' || l_params;
        g_retval := pk_comm_orders.get_instructions_default(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_comm_order      => i_id_comm_order,
                                                            i_id_comm_order_type => i_id_comm_order_type,
                                                            o_list               => o_list,
                                                            o_error              => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_instructions_default;

    FUNCTION get_comm_order_summary
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_comm_order_req       IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order              OUT pk_types.cursor_type,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_COMM_ORDERS.GET_COMM_ORDER_SUMMARY';
        IF NOT pk_comm_orders.get_comm_order_summary(i_lang                    => i_lang,
                                                     i_prof                    => i_prof,
                                                     i_episode                 => i_episode,
                                                     i_id_comm_order_req       => i_id_comm_order_req,
                                                     o_comm_order              => o_comm_order,
                                                     o_comm_clinical_questions => o_comm_clinical_questions,
                                                     o_error                   => o_error)
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
                                              'GET_COMM_ORDER_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_comm_order);
            pk_types.open_my_cursor(o_comm_clinical_questions);
            RETURN FALSE;
    END get_comm_order_summary;

    /**
    * Creates an ongoing communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patient                 Patient identifier    
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order              Array of communication order identifiers
    * @param   i_id_comm_order_type         Array of communication orders types identifiers
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)   
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_clinical_indication        Array of clinical indication information
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_clinical_purpose_desc      Array of clinical purpose descriptions
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   i_dt_begin_str               Array of start dates. Format YYYYMMDDhh24miss
    * @param   i_dt_order_str               Array of order dates. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Array of order professional identifiers
    * @param   i_id_order_type              Array of request order types (telephone, verbal, ...)
    * @param   o_id_comm_order_req         Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION create_comm_order_req_ong
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN comm_order_req.id_patient%TYPE,
        i_id_episode              IN comm_order_req.id_episode%TYPE,
        i_id_comm_order           IN table_number,
        i_id_comm_order_type      IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_begin_str            IN table_varchar,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number, --20
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_comm_order_req_ong';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient || ' i_id_episode=' ||
                    i_id_episode || ' i_id_comm_order.count=' || i_id_comm_order.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.create_comm_order_req_ong / ' || l_params;
        g_retval := pk_comm_orders.create_comm_order_req_ong(i_lang                    => i_lang,
                                                             i_prof                    => i_prof,
                                                             i_id_patient              => i_id_patient,
                                                             i_id_episode              => i_id_episode,
                                                             i_id_comm_order           => i_id_comm_order,
                                                             i_id_comm_order_type      => i_id_comm_order_type,
                                                             i_flg_free_text           => i_flg_free_text,
                                                             i_desc_comm_order         => i_desc_comm_order,
                                                             i_notes                   => i_notes,
                                                             i_clinical_indication     => i_clinical_indication,
                                                             i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                                             i_clinical_purpose_desc   => i_clinical_purpose_desc,
                                                             i_flg_priority            => i_flg_priority,
                                                             i_flg_prn                 => i_flg_prn,
                                                             i_prn_condition           => i_prn_condition,
                                                             i_dt_begin_str            => i_dt_begin_str,
                                                             i_dt_order_str            => i_dt_order_str,
                                                             i_id_prof_order           => i_id_prof_order,
                                                             i_id_order_type           => i_id_order_type,
                                                             i_task_duration           => i_task_duration,
                                                             i_order_recurr            => i_order_recurr,
                                                             i_clinical_question       => i_clinical_question,
                                                             i_response                => i_response,
                                                             i_clinical_question_notes => i_clinical_question_notes,
                                                             i_task_type               => i_task_type,
                                                             o_id_comm_order_req       => o_id_comm_order_req,
                                                             o_error                   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_comm_order_req_ong;

    /**
    * Creates a predefined communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order              Array of communication orders identifier
    * @param   i_id_comm_order_type         Array of communication orders types identifiers
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)   
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_clinical_indication        Array of clinical indication information
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   o_id_comm_order_req         Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    /*
    FUNCTION create_comm_order_req_predf
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_comm_order        IN table_number,
        i_id_comm_order_type   IN table_number,
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_clinical_indication  IN table_clob,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        o_id_comm_order_req    OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_comm_order_req_predf';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order.count=' || i_id_comm_order.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.create_comm_order_req_predf / ' || l_params;
        g_retval := pk_comm_orders.create_comm_order_req_predf(i_lang                 => i_lang,
                                                               i_prof                 => i_prof,
                                                               i_id_comm_order        => i_id_comm_order,
                                                               i_id_comm_order_type   => i_id_comm_order_type,
                                                               i_flg_free_text        => i_flg_free_text,
                                                               i_desc_comm_order      => i_desc_comm_order,
                                                               i_notes                => i_notes,
                                                               i_clinical_indication  => i_clinical_indication,
                                                               i_flg_clinical_purpose => i_flg_clinical_purpose,
                                                               i_flg_priority         => i_flg_priority,
                                                               i_flg_prn              => i_flg_prn,
                                                               i_prn_condition        => i_prn_condition,
                                                               o_id_comm_order_req    => o_id_comm_order_req,
                                                               o_error                => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_comm_order_req_predf;
    */

    /**
    * Updates a communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_flg_free_text              Flag indicating if this communication orders is free text
    * @param   i_desc_comm_order            Communication orders request description (in case of free text)   
    * @param   i_notes                      Communication orders request notes
    * @param   i_clinical_indication        Clinical indication information
    * @param   i_flg_clinical_purpose       Flag that indicates the clinical purpose
    * @param   i_clinical_purpose_desc      Clinical purpose descriptions
    * @param   i_flg_priority               Flag that indicates the priority
    * @param   i_flg_prn                    Flag that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Notes to indicate the PRN conditions
    * @param   i_dt_order_str               Order date. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Order professional identifier
    * @param   i_id_order_type              Request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION update_comm_order_req
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_id_comm_order_req       IN table_number,
        i_flg_free_text           IN table_varchar,
        i_desc_comm_order         IN table_clob,
        i_notes                   IN table_clob,
        i_clinical_indication     IN table_clob,
        i_flg_clinical_purpose    IN table_varchar,
        i_clinical_purpose_desc   IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_flg_prn                 IN table_varchar,
        i_prn_condition           IN table_clob,
        i_dt_order_str            IN table_varchar,
        i_id_prof_order           IN table_number,
        i_id_order_type           IN table_number,
        i_task_duration           IN table_number,
        i_dt_begin_str            IN table_varchar,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'update_comm_order_req';
        l_params       VARCHAR2(1000 CHAR);
        l_dt_begin_str table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        IF i_dt_begin_str.count <> i_id_comm_order_req.count
        THEN
            l_dt_begin_str := table_varchar();
            l_dt_begin_str.extend(i_id_comm_order_req.count);
        ELSE
            l_dt_begin_str := table_varchar();
            l_dt_begin_str := i_dt_begin_str;
        END IF;
    
        g_error  := 'Call pk_comm_orders.update_comm_order_req / ' || l_params;
        g_retval := pk_comm_orders.update_comm_order_req(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_episode                 => i_episode,
                                                         i_id_comm_order_req       => i_id_comm_order_req,
                                                         i_flg_free_text           => i_flg_free_text,
                                                         i_desc_comm_order         => i_desc_comm_order,
                                                         i_notes                   => i_notes,
                                                         i_clinical_indication     => i_clinical_indication,
                                                         i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                                         i_clinical_purpose_desc   => i_clinical_purpose_desc,
                                                         i_flg_priority            => i_flg_priority,
                                                         i_flg_prn                 => i_flg_prn,
                                                         i_prn_condition           => i_prn_condition,
                                                         i_dt_begin_str            => l_dt_begin_str,
                                                         i_dt_order_str            => i_dt_order_str,
                                                         i_id_prof_order           => i_id_prof_order,
                                                         i_id_order_type           => i_id_order_type,
                                                         i_task_duration           => i_task_duration,
                                                         i_order_recurr            => i_order_recurr,
                                                         i_clinical_question       => i_clinical_question,
                                                         i_response                => i_response,
                                                         i_clinical_question_notes => i_clinical_question_notes,
                                                         o_error                   => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_comm_order_req;

    /**
    * Cancels a communication order request, updating state to canceled
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_cancel_reason           Cancel reason identifier
    * @param   i_notes_cancel               Cancelling notes
    * @param   i_id_order_type              Co-sign request order type (telephone, verbal, ...)
    * @param   i_id_prof_order              Co-sign order professional identifier
    * @param   i_dt_order                   Co-sign order date. Format YYYYMMDDHH24MISS    
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   20-02-2014
    */
    FUNCTION set_action_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_id_episode        IN comm_order_req.id_episode%TYPE,
        i_id_cancel_reason  IN comm_order_req.id_cancel_reason%TYPE,
        i_notes_cancel      IN pk_translation.t_lob_char,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_dt_order          IN VARCHAR2,
        i_task_type         IN task_type.id_task_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_action_cancel';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req.count=' ||
                    i_id_comm_order_req.count || ' i_id_episode=' || i_id_episode || ' i_dt_order=' || i_dt_order ||
                    ' i_id_prof_order=' || i_id_prof_order || ' i_id_order_type=' || i_id_order_type;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.set_action_cancel_discontinue / ' || l_params;
        g_retval := pk_comm_orders.set_action_cancel_discontinue(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_id_comm_order_req => i_id_comm_order_req,
                                                                 i_id_episode        => i_id_episode,
                                                                 i_id_reason         => i_id_cancel_reason,
                                                                 i_notes             => i_notes_cancel,
                                                                 i_dt_order          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                      i_prof,
                                                                                                                      i_dt_order,
                                                                                                                      NULL),
                                                                 i_id_prof_order     => i_id_prof_order,
                                                                 i_id_order_type     => i_id_order_type,
                                                                 o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_utils.undo_changes;
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_action_cancel;

    /**
    * Gets communication order requests information
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Array of communication orders requests identifiers
    * @param   o_info                       Information about communication order requests
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_comm_order_req       IN table_number,
        o_info                    OUT pk_types.cursor_type,
        o_comm_clinical_questions OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_comm_order_req_info';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req.count=' ||
                    i_id_comm_order_req.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_req_info / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_req_info(i_lang                    => i_lang,
                                                           i_prof                    => i_prof,
                                                           i_id_comm_order_req       => i_id_comm_order_req,
                                                           i_flg_escape_char         => pk_alert_constant.g_no,
                                                           o_info                    => o_info,
                                                           o_comm_clinical_questions => o_comm_clinical_questions,
                                                           o_error                   => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_info);
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
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_comm_order_req_info;

    /**
    * Gets communication order requests to be shown in detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Communication orders request identifier
    * @param   o_status                     Status description
    * @param   o_title                      Title description
    * @param   o_cur_current                Communication order current information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_req_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_task_type         IN task_type.id_task_type%TYPE,
        o_status            OUT VARCHAR2,
        o_title             OUT VARCHAR2,
        o_cur_current       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_req_detail';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' || i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_req_detail / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_req_detail(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => i_id_comm_order_req,
                                                             o_status            => o_status,
                                                             o_title             => o_title,
                                                             o_cur_current       => o_cur_current,
                                                             o_error             => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_cur_current);
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
            pk_types.open_my_cursor(o_cur_current);
            RETURN FALSE;
    END get_comm_order_req_detail;

    /**
    * Gets communication order requests to be shown in history detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req         Communication orders request identifier
    * @param   o_cur_hist                   Communication order history information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION get_comm_order_req_detail_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_cur_hist          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_req_detail_h';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' || i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_req_detail_h / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_req_detail_h(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_comm_order_req => i_id_comm_order_req,
                                                               o_cur_hist          => o_cur_hist,
                                                               o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_cur_hist);
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
            pk_types.open_my_cursor(o_cur_hist);
            RETURN FALSE;
    END get_comm_order_req_detail_h;

    /**
    * Get the information of communication orders requests identifiers
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req Array of communication orders requests identifiers
    * @param   o_list               Cursor containing information of communication orders requests
    * @param   o_error              Error information
    *
    * @return  boolean              True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-03-2014
    */
    FUNCTION get_comm_order_req_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_req_type';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req.count=' ||
                    i_id_comm_order_req.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_req_type / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_req_type(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_comm_order_req => i_id_comm_order_req,
                                                           o_list              => o_list,
                                                           o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_req_type;

    /**
    * Returns communication order detail for the viewer
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_comm_order_req             Communication order request identifier
    * @param   o_detail                     Cursor containing communication order req detail
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   04-12-2014
    */
    FUNCTION get_comm_order_viewer_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_comm_order_viewer_detail';
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_prof=' || pk_utils.to_string(i_prof) || ' i_comm_order_req=' ||
                   i_comm_order_req;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_retval := pk_comm_orders.get_comm_order_viewer_detail(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_comm_order_req => i_comm_order_req,
                                                                o_detail         => o_detail,
                                                                o_error          => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_detail);
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
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_comm_order_viewer_detail;

    FUNCTION get_comm_order_questionnaire
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_comm_order    IN comm_order_ea.id_comm_order%TYPE,
        i_flg_time      IN VARCHAR2,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50 CHAR) := 'get_comm_order_questionnaire';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_type_list / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_questionnaire(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_patient       => i_patient,
                                                                i_episode       => i_episode,
                                                                i_comm_order    => i_comm_order,
                                                                i_flg_time      => i_flg_time,
                                                                i_dep_clin_serv => i_dep_clin_serv,
                                                                o_list          => o_list,
                                                                o_error         => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
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
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_comm_order_questionnaire;

    FUNCTION get_comm_order_execution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        o_comm_order_plan OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(100 CHAR) := 'get_comm_order_execution_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.get_comm_order_execution_list / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_execution_list(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_episode         => i_episode,
                                                                 i_comm_order_req  => i_comm_order_req,
                                                                 o_comm_order_plan => o_comm_order_plan,
                                                                 o_error           => o_error);
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_comm_order_plan);
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
            pk_types.open_my_cursor(o_comm_order_plan);
            RETURN FALSE;
    END get_comm_order_execution_list;

    FUNCTION get_execution_action_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.get_execution_action_list(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_episode,
                                                        i_subject        => i_subject,
                                                        i_from_state     => i_from_state,
                                                        i_comm_order_req => i_comm_order_req,
                                                        o_actions        => o_actions,
                                                        o_error          => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EXECUTION_ACTION_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_execution_action_list;

    FUNCTION get_comm_order_for_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.get_comm_order_for_execution(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_comm_order_req  => i_comm_order_req,
                                                           i_comm_order_plan => i_comm_order_plan,
                                                           o_comm_order      => o_comm_order,
                                                           o_error           => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_comm_order);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_COMM_ORDER_FOR_EXECUTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_comm_order);
            RETURN FALSE;
    END get_comm_order_for_execution;

    FUNCTION set_comm_order_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_comm_order_req         IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan        IN comm_order_plan.id_comm_order_plan%TYPE,
        i_flg_status             IN comm_order_plan.flg_status%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN comm_order_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN comm_order_plan.notes%TYPE,
        i_doc_template           IN doc_template.id_doc_template%TYPE,
        i_flg_type               IN doc_template_context.flg_type%TYPE,
        i_id_documentation       IN table_number,
        i_id_doc_element         IN table_number,
        i_id_doc_element_crit    IN table_number,
        i_value                  IN table_varchar,
        i_id_doc_element_qualif  IN table_table_number,
        i_vs_element_list        IN table_number,
        i_vs_save_mode_list      IN table_varchar,
        i_vs_list                IN table_number,
        i_vs_value_list          IN table_number,
        i_vs_uom_list            IN table_number,
        i_vs_scales_list         IN table_number,
        i_vs_date_list           IN table_varchar,
        i_vs_read_list           IN table_number,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        o_comm_order_plan        OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.set_comm_order_execution(i_lang                   => i_lang,
                                                       i_prof                   => i_prof,
                                                       i_episode                => i_episode,
                                                       i_comm_order_req         => i_comm_order_req,
                                                       i_comm_order_plan        => i_comm_order_plan,
                                                       i_flg_status             => i_flg_status,
                                                       i_dt_next                => i_dt_next,
                                                       i_prof_performed         => i_prof_performed,
                                                       i_start_time             => i_start_time,
                                                       i_end_time               => i_end_time,
                                                       i_flg_supplies           => i_flg_supplies,
                                                       i_notes                  => i_notes,
                                                       i_doc_template           => i_doc_template,
                                                       i_flg_type               => i_flg_type,
                                                       i_id_documentation       => i_id_documentation,
                                                       i_id_doc_element         => i_id_doc_element,
                                                       i_id_doc_element_crit    => i_id_doc_element_crit,
                                                       i_value                  => i_value,
                                                       i_id_doc_element_qualif  => i_id_doc_element_qualif,
                                                       i_vs_element_list        => i_vs_element_list,
                                                       i_vs_save_mode_list      => i_vs_save_mode_list,
                                                       i_vs_list                => i_vs_list,
                                                       i_vs_value_list          => i_vs_value_list,
                                                       i_vs_uom_list            => i_vs_uom_list,
                                                       i_vs_scales_list         => i_vs_scales_list,
                                                       i_vs_date_list           => i_vs_date_list,
                                                       i_vs_read_list           => i_vs_read_list,
                                                       i_clinical_decision_rule => i_clinical_decision_rule,
                                                       i_id_po_param_reg        => i_id_po_param_reg,
                                                       o_comm_order_plan        => o_comm_order_plan,
                                                       o_error                  => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_EXECUTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_comm_order_execution;

    FUNCTION set_comm_order_execution
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_comm_order_req         IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan        IN comm_order_plan.id_comm_order_plan%TYPE,
        i_flg_status             IN comm_order_plan.flg_status%TYPE,
        i_dt_next                IN VARCHAR2,
        i_prof_performed         IN comm_order_plan.id_prof_performed%TYPE,
        i_start_time             IN VARCHAR2,
        i_end_time               IN VARCHAR2,
        i_flg_supplies           IN VARCHAR2,
        i_notes                  IN comm_order_plan.notes%TYPE,
        i_epis_documentation     IN epis_documentation.id_epis_documentation%TYPE,
        i_clinical_decision_rule IN cdr_call.id_cdr_call%TYPE,
        i_id_po_param_reg        IN po_param_reg.id_po_param_reg%TYPE,
        o_comm_order_plan        OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.set_comm_order_execution(i_lang                   => i_lang,
                                                       i_prof                   => i_prof,
                                                       i_episode                => i_episode,
                                                       i_comm_order_req         => i_comm_order_req,
                                                       i_comm_order_plan        => i_comm_order_plan,
                                                       i_flg_status             => i_flg_status,
                                                       i_dt_next                => i_dt_next,
                                                       i_prof_performed         => i_prof_performed,
                                                       i_start_time             => i_start_time,
                                                       i_end_time               => i_end_time,
                                                       i_flg_supplies           => i_flg_supplies,
                                                       i_notes                  => i_notes,
                                                       i_epis_documentation     => i_epis_documentation,
                                                       i_doc_template           => NULL,
                                                       i_flg_type               => NULL,
                                                       i_id_documentation       => table_number(NULL),
                                                       i_id_doc_element         => table_number(NULL),
                                                       i_id_doc_element_crit    => table_number(NULL),
                                                       i_value                  => table_varchar(NULL),
                                                       i_id_doc_element_qualif  => table_table_number(NULL),
                                                       i_vs_element_list        => table_number(NULL),
                                                       i_vs_save_mode_list      => table_varchar(NULL),
                                                       i_vs_list                => table_number(NULL),
                                                       i_vs_value_list          => table_number(NULL),
                                                       i_vs_uom_list            => table_number(NULL),
                                                       i_vs_scales_list         => table_number(NULL),
                                                       i_vs_date_list           => table_varchar(NULL),
                                                       i_vs_read_list           => table_number(NULL),
                                                       i_clinical_decision_rule => i_clinical_decision_rule,
                                                       i_id_po_param_reg        => i_id_po_param_reg,
                                                       o_comm_order_plan        => o_comm_order_plan,
                                                       o_error                  => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_EXECUTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_comm_order_execution;

    FUNCTION set_comm_order_conclusion
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        o_comm_order_plan OUT comm_order_plan.id_comm_order_plan%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.set_comm_order_conclusion(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_episode         => i_episode,
                                                        i_comm_order_req  => i_comm_order_req,
                                                        i_comm_order_plan => i_comm_order_plan,
                                                        o_comm_order_plan => o_comm_order_plan,
                                                        o_error           => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_COMM_ORDER_CONCLUSION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_comm_order_conclusion;

    FUNCTION cancel_comm_order_execution
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_dt_plan         IN VARCHAR2,
        i_cancel_reason   IN interv_presc_plan.id_cancel_reason%TYPE,
        i_cancel_notes    IN interv_presc_plan.notes_cancel%TYPE,
        i_task_type       IN task_type.id_task_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.cancel_comm_order_execution(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_comm_order_plan => i_comm_order_plan,
                                                          i_dt_plan         => i_dt_plan,
                                                          i_cancel_reason   => i_cancel_reason,
                                                          i_cancel_notes    => i_cancel_notes,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_COMM_ORDER_EXECUTION',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_comm_order_execution;

    FUNCTION cancel_comm_order_exec_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_comm_order_plan    IN comm_order_plan.id_comm_order_plan%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_po_param_reg       IN po_param_reg.id_po_param_reg%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_comm_orders.cancel_comm_order_exec_values(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_comm_order_plan    => i_comm_order_plan,
                                                            i_epis_documentation => i_epis_documentation,
                                                            i_po_param_reg       => i_po_param_reg,
                                                            o_error              => o_error)
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CANCEL_COMM_ORDER_EXEC_VALUES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_comm_order_exec_values;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_comm_orders_ux;
/
