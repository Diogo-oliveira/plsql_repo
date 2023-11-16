/*-- Last Change Revision: $Rev: 1991069 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-06-04 15:35:16 +0100 (sex, 04 jun 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_orders_cpoe IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception    EXCEPTION;

    /**
    * Creates a draft communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patient                 Patient identifier
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order              Array of communication orders identifier
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
    FUNCTION create_draft
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
        i_task_duration           IN table_number,
        i_order_recurr            IN table_number,
        i_clinical_question       IN table_table_number,
        i_response                IN table_table_varchar,
        i_clinical_question_notes IN table_table_varchar,
        i_task_type               IN NUMBER,
        o_id_comm_order_req       OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_draft';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient || ' i_id_episode=' ||
                    i_id_episode || ' i_id_comm_order.count=' || i_id_comm_order.count;
    
        g_error  := 'Call pk_comm_orders.create_comm_order_req_draft / ' || l_params;
        g_retval := pk_comm_orders.create_comm_order_req_draft(i_lang                    => i_lang,
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
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
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
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_draft;

    /**
    * Updates a task
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
    * @param   i_dt_begin_str               Start date. Format YYYYMMDDhh24miss
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
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION set_task_parameters
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN table_number,
        i_flg_free_text         IN table_varchar,
        i_desc_comm_order       IN table_clob,
        i_notes                 IN table_clob,
        i_clinical_indication   IN table_clob,
        i_flg_clinical_purpose  IN table_varchar,
        i_clinical_purpose_desc IN table_varchar,
        i_flg_priority          IN table_varchar,
        i_flg_prn               IN table_varchar,
        i_prn_condition         IN table_clob,
        i_dt_begin_str          IN table_varchar,
        i_dt_order_str          IN table_varchar,
        i_id_prof_order         IN table_number,
        i_id_order_type         IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_task_parameters';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req.count=' ||
                    i_id_comm_order_req.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.update_comm_order_req / ' || l_params;
        g_retval := pk_comm_orders.update_comm_order_req(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
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
                                                         i_dt_begin_str            => i_dt_begin_str,
                                                         i_dt_order_str            => i_dt_order_str,
                                                         i_id_prof_order           => i_id_prof_order,
                                                         i_id_order_type           => i_id_order_type,
                                                         i_task_duration           => table_number(NULL),
                                                         i_order_recurr            => table_number(NULL),
                                                         i_clinical_question       => table_table_number(table_number(NULL)),
                                                         i_response                => table_table_varchar(table_varchar(NULL)),
                                                         i_clinical_question_notes => table_table_varchar(table_varchar(NULL)),
                                                         o_error                   => o_error);
    
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
    END set_task_parameters;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_requests  Array of task request ids to expire
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'expire_task';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_task_requests.count=' ||
                    i_task_requests.count;
        g_error  := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.set_action_expire / ' || l_params;
        g_retval := pk_comm_orders.set_action_expire(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_id_comm_order_req    => i_task_requests,
                                                     i_flg_ignore_trs_error => pk_alert_constant.g_yes,
                                                     o_error                => o_error);
    
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
    END expire_task;

    /**
    * Get actions available to a task
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_request   Array of task request identifiers to get the actions available
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        i_task_type    IN NUMBER,
        o_action       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_task_actions';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_task_request=' ||
                    pk_utils.to_string(i_task_request);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.get_actions / ' || l_params;
        g_retval := pk_comm_orders.get_actions(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_comm_order_req => i_task_request,
                                               i_task_type         => i_task_type,
                                               o_list              => o_action,
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
    END get_task_actions;

    /**
    * Changes task from state
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_action         Action identifier
    * @param   i_task_request   Array with task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION set_action
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_action       IN action.id_action%TYPE,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_action';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_action=' || i_action ||
                    ' i_task_request=' || pk_utils.to_string(i_task_request);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.set_action / ' || l_params;
        g_retval := pk_comm_orders.set_action(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_action         => i_action,
                                              i_id_comm_order_req => i_task_request,
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
    END set_action;

    /**
    * Check conflicts upon created drafts (verify if drafts can be requested or not)
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Draft identifier
    * @param   o_flg_conflict   Array of draft conflicts indicators
    * @param   o_msg_template   Array of message/pop-up templates
    * @param   o_msg_title      Array of message titles
    * @param   o_msg_body       Array of message bodies
    * @param   o_error          Error information
    *
    * @value   o_flg_conflict   {*} 'Y' the draft has conflicts
    *                           {*} 'N' no conflicts found
    *
    * @value   o_msg_template   {*} 'WARNING_READ' Warning Read
    *                           {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                           {*} 'WARNING_CANCEL' Warning Cancel
    *                           {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                           {*} 'WARNING_SECURITY' Warning Security
    *                           {*} 'CONFIRMATION' Confirmation
    *                           {*} 'DETAIL' Detail
    *                           {*} 'HELP' Help
    *                           {*} 'WIZARD' Wizard
    *                           {*} 'ADVANCED_INPUT' Advanced Input
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION check_draft_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT table_varchar,
        o_msg_title    OUT table_varchar,
        o_msg_body     OUT table_varchar,
        o_msg_template OUT table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'check_draft_conflicts';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_draft.count=' ||
                    i_draft.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        o_flg_conflict := table_varchar();
        o_msg_title    := table_varchar();
        o_msg_body     := table_varchar();
        o_msg_template := table_varchar();
    
        g_error := 'extend(' || i_draft.count || ') / ' || l_params;
        o_flg_conflict.extend(i_draft.count);
        o_msg_title.extend(i_draft.count);
        o_msg_body.extend(i_draft.count);
        o_msg_template.extend(i_draft.count);
    
        g_error := 'FOR i IN 1 .. ' || i_draft.count || ' / ' || l_params;
        FOR i IN 1 .. i_draft.count
        LOOP
            o_flg_conflict(i) := pk_alert_constant.g_no;
        END LOOP;
    
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
    END check_draft_conflicts;

    /**
    * Changes task from state
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_request   Task request identifier to get the actions available
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_type            IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'copy_to_draft';
        l_params  VARCHAR2(1000 CHAR);
        l_sysdate TIMESTAMP(0) -- precision 0 removes mili seconds from actual date (important)
        WITH LOCAL TIME ZONE;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_task_type       task_type.id_task_type%TYPE;
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_task_request=' ||
                    i_task_request;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_sysdate := i_task_start_timestamp;
        ELSE
            l_sysdate := current_timestamp;
        END IF;
    
        SELECT a.id_target_task_type
          INTO l_task_type
          FROM cpoe_task_type a
         WHERE a.id_task_type = i_task_type;
    
        -- func
        g_error  := 'Call pk_comm_orders.copy_comm_order_req / i_id_status=' || pk_comm_orders.g_id_sts_draft ||
                    ' i_id_episode=' || i_episode || ' i_dt_begin=' || l_sysdate || ' / ' || l_params;
        g_retval := pk_comm_orders.copy_comm_order_req(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_comm_order_req => i_task_request,
                                                       i_id_status         => pk_comm_orders.g_id_sts_draft,
                                                       i_id_episode        => i_episode,
                                                       i_dt_begin          => l_sysdate,
                                                       i_task_type         => l_task_type,
                                                       o_id_comm_order_req => o_draft,
                                                       o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_episode);
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        
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
    END copy_to_draft;

    /**
    * Activates draft tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Array of task requests identifiers
    * @param   i_flg_commit     Flag that indicates to commit transaction (or not)
    * @param   o_created_tasks  Array with created task request Ids
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   21-02-2014
    */
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'activate_drafts';
        l_params  VARCHAR2(1000 CHAR);
        l_sysdate TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_draft.count=' ||
                    i_draft.count || ' i_flg_commit=' || i_flg_commit;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
        l_sysdate := current_timestamp;
    
        -- func
        g_error  := 'Call pk_comm_orders.copy_comm_order_req / i_id_status=' || pk_comm_orders.g_id_sts_draft ||
                    ' i_id_episode=' || i_episode || ' i_dt_begin=' || l_sysdate || ' / ' || l_params;
        g_retval := pk_comm_orders.set_action_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_episode        => i_episode,
                                                    i_id_comm_order_req => i_draft,
                                                    i_dt_order          => NULL,
                                                    i_id_prof_order     => NULL,
                                                    i_id_order_type     => NULL,
                                                    o_error             => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- created task request Ids are exactly the same passed as draft Ids
        o_created_tasks := i_draft;
    
        IF i_flg_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
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
    END activate_drafts;

    /**
    * Cancels all draft tasks related to the visit of this episode
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'cancel_all_drafts';
        l_params             VARCHAR2(1000 CHAR);
        l_id_visit           episode.id_visit%TYPE;
        l_comm_order_req_tab table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
    
        -- getting id_visit
        l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        -- getting comm orders req related to this visit, that are in state draft
        g_error  := 'Call pk_comm_orders.get_comm_order_req_ids / l_id_visit=' || l_id_visit || ' i_id_status=' ||
                    pk_comm_orders.g_id_sts_draft || ' / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_req_ids(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_visit           => l_id_visit,
                                                          i_id_status          => pk_comm_orders.g_id_sts_draft,
                                                          i_tbl_task_type      => table_number(pk_alert_constant.g_task_comm_orders,
                                                                                               pk_alert_constant.g_task_medical_orders),
                                                          o_comm_order_req_tab => l_comm_order_req_tab,
                                                          o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_comm_order_req_tab.count > 0
        THEN
            --
            g_error  := 'Call pk_comm_orders.delete_comm_order_req / l_comm_order_req_tab.count=' ||
                        l_comm_order_req_tab.count || ' / ' || l_params;
            g_retval := pk_comm_orders.delete_comm_order_req(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_comm_order_req => l_comm_order_req_tab,
                                                             o_error             => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
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
    END cancel_all_drafts;

    /**
    * Cancels draft tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_draft          Array of task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ANA.MONTEIRO
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'cancel_draft';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_draft.count=' ||
                    i_draft.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.delete_comm_order_req / ' || l_params;
        g_retval := pk_comm_orders.delete_comm_order_req(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_id_comm_order_req => i_draft,
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
    END cancel_draft;

    /**
    * Gets communication orders list
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_patient                    Patient id
    * @param   i_episode                    Episode id
    * @param   i_task_request               Communication order request id
    * @param   i_filter_tstz                Date filter (used by CPOE),
    * @param   i_filter_status              Status filter (used by CPOE),
    * @param   i_flg_report                 Flag that indicates if this function was called to get data to generate report (used by CPOE)
    *
    * @value   i_flg_report                 {*} Y- called to get data to generate report {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_order_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_task_request   IN table_number,
        i_filter_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status  IN table_varchar,
        i_flg_report     IN VARCHAR2 DEFAULT 'N',
        i_cpoe_task_type IN cpoe_task_type.id_task_type%TYPE DEFAULT NULL,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list      OUT pk_types.cursor_type,
        o_task_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_comm_order_list';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_patient=' || i_patient || ' i_episode=' || i_episode ||
                    ' i_task_request=' || pk_utils.to_string(i_task_request) || ' i_filter_tstz=' || i_filter_tstz ||
                    ' i_filter_status=' || pk_utils.to_string(i_filter_status) || ' i_flg_report=' || i_flg_report;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.get_comm_order_list / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_list(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_patient,
                                                       i_episode        => i_episode,
                                                       i_task_request   => i_task_request,
                                                       i_filter_tstz    => i_filter_tstz,
                                                       i_filter_status  => i_filter_status,
                                                       i_flg_report     => i_flg_report,
                                                       i_cpoe_task_type => i_cpoe_task_type,
                                                       i_dt_begin       => i_dt_begin,
                                                       i_dt_end         => i_dt_end,
                                                       o_plan_list      => o_plan_list,
                                                       o_task_list      => o_task_list,
                                                       o_error          => o_error);
    
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
    END get_comm_order_list;

    /**
    * Gets communication orders status
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              episode id
    * @param   i_task_request         array of communication order request ids
    * @param   o_task_status          cursor with all communication order tasks status
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_task_status';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_comm_order_req=' ||
                    pk_utils.to_string(i_task_request);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.get_comm_order_status / ' || l_params;
        g_retval := pk_comm_orders.get_comm_order_status(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_episode        => i_episode,
                                                         i_comm_order_req => i_task_request,
                                                         o_task_status    => o_task_status,
                                                         o_error          => o_error);
    
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
    END get_task_status;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_comm_orders_cpoe;
/
