CREATE OR REPLACE PACKAGE BODY pk_comm_orders_order_sets IS

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
    * @param   i_id_prof_order              Order professional identifiers
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
                                                         i_clinical_question       => table_table_number(NULL),
                                                         i_response                => table_table_varchar(NULL),
                                                         i_clinical_question_notes => table_table_varchar(NULL),
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
    * Gets communication order title (title and notes)
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Communication order request id
    * @param   i_flg_with_notes       Flag that indicates if notes should appear under the title or not
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION get_task_title
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_request   IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_with_notes IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_task_title';
        l_params           VARCHAR2(1000 CHAR);
        l_comm_order_title VARCHAR2(1000 CHAR);
    BEGIN
    
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || i_task_request;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get commmunication order title / ' || l_params;
        SELECT pk_comm_orders.get_comm_order_title(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_concept_type             => cor.id_concept_type,
                                                    i_concept_term             => cor.id_concept_term,
                                                    i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                    i_concept_version          => cor.id_concept_version,
                                                    i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                    i_flg_free_text            => cor.flg_free_text,
                                                    i_desc_concept_term        => pk_translation.get_translation_trs(cor.desc_concept_term),
                                                    i_task_type                => cor.id_task_type,
                                                    i_flg_bold_title           => (CASE
                                                                                      WHEN i_flg_with_notes = pk_alert_constant.g_yes THEN
                                                                                       pk_alert_constant.g_yes
                                                                                  END),
                                                    i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                    i_flg_trunc_clobs          => pk_alert_constant.g_yes) ||
               -- concat notes field if not empty
                CASE
                    WHEN i_flg_with_notes = pk_alert_constant.g_yes
                         AND pk_translation.get_translation_trs(cor.notes) IS NOT NULL
                         AND length(pk_translation.get_translation_trs(cor.notes)) > 0 THEN
                     chr(10) || htf.escape_sc(pk_string_utils.clob_to_varchar2(pk_translation.get_translation_trs(cor.notes) ||
                                                                               pk_comm_orders.g_str_separator,
                                                                               200))
                    ELSE
                     NULL
                END
          INTO l_comm_order_title
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_task_request;
    
        -- return communication order title
        RETURN l_comm_order_title;
    
    END get_task_title;

    /**
    * Gets communication order instructions
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Communication order request id
    * @param   i_flg_show_start_date  Flag that indicates if start date must be shown on instructions description or not
    * @param   o_task_instr           Task instructions
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION get_task_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_task_request        IN comm_order_req.id_comm_order_req%TYPE,
        i_flg_show_start_date IN VARCHAR2,
        o_task_instr          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_task_instructions';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || i_task_request ||
                    ' i_flg_show_start_date=' || i_flg_show_start_date;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get commmunication order instructions / ' || l_params;
        SELECT
        -- concat notes field if not empty
         CASE
              WHEN pk_translation.get_translation_trs(cor.notes) IS NOT NULL
                   AND length(pk_translation.get_translation_trs(cor.notes)) > 0 THEN
               pk_string_utils.clob_to_varchar2(pk_translation.get_translation_trs(cor.notes) ||
                                                pk_comm_orders.g_str_separator,
                                                200)
              ELSE
               NULL
          END ||
         -- get communication order instructions
          pk_comm_orders.get_comm_order_instr(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_flg_priority    => cor.flg_priority,
                                              i_flg_prn         => cor.flg_prn,
                                              i_prn_condition   => pk_translation.get_translation_trs(cor.prn_condition),
                                              i_dt_begin        => decode(i_flg_show_start_date,
                                                                          pk_alert_constant.g_yes,
                                                                          cor.dt_begin,
                                                                          NULL),
                                              i_flg_trunc_clobs => pk_alert_constant.g_yes,
                                              i_flg_escape_char => pk_alert_constant.g_no)
          INTO o_task_instr
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_task_request;
    
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
            RETURN FALSE;
    END get_task_instructions;

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
    * @param   i_clinical_purpose_desc      Array of clinical purpose descriptions
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
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION create_predefined_task
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order         IN table_number,
        i_id_comm_order_type    IN table_number,
        i_flg_free_text         IN table_varchar,
        i_desc_comm_order       IN table_clob,
        i_notes                 IN table_clob,
        i_clinical_indication   IN table_clob,
        i_flg_clinical_purpose  IN table_varchar,
        i_clinical_purpose_desc IN table_varchar,
        i_flg_priority          IN table_varchar,
        i_flg_prn               IN table_varchar,
        i_prn_condition         IN table_clob,
        o_id_comm_order_req     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_predefined_task';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order.count=' || i_id_comm_order.count;
    
        g_error  := 'Call pk_comm_orders.create_comm_order_req_predf / ' || l_params;
        g_retval := pk_comm_orders.create_comm_order_req_predf(i_lang                  => i_lang,
                                                               i_prof                  => i_prof,
                                                               i_id_comm_order         => i_id_comm_order,
                                                               i_id_comm_order_type    => i_id_comm_order_type,
                                                               i_flg_free_text         => i_flg_free_text,
                                                               i_desc_comm_order       => i_desc_comm_order,
                                                               i_notes                 => i_notes,
                                                               i_clinical_indication   => i_clinical_indication,
                                                               i_flg_clinical_purpose  => i_flg_clinical_purpose,
                                                               i_clinical_purpose_desc => i_clinical_purpose_desc,
                                                               i_flg_priority          => i_flg_priority,
                                                               i_flg_prn               => i_flg_prn,
                                                               i_prn_condition         => i_prn_condition,
                                                               o_id_comm_order_req     => o_id_comm_order_req,
                                                               o_error                 => o_error);
    
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
    END create_predefined_task;

    /**
    * Cancels predefined tasks
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_episode        Episode identifier
    * @param   i_task_request   Array of task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   26-02-2014
    */
    FUNCTION cancel_predefined_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'cancel_predefined_task';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || pk_utils.to_string(i_task_request);
    
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
    END cancel_predefined_task;

    /**
    * Cancels a communication order request, updating state to canceled
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req          Array of communication orders request identifiers
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_cancel_reason           Cancel reason identifier
    * @param   i_notes_cancel               Cancelling notes
    * @param   i_dt_order                   Co-sign order date
    * @param   i_id_prof_order              Co-sign order professional identifier
    * @param   i_id_order_type              Co-sign request order type (telephone, verbal, ...)
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
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
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
                                                                 i_dt_order          => i_dt_order,
                                                                 i_id_prof_order     => i_id_prof_order,
                                                                 i_id_order_type     => i_id_order_type,
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
    END set_action_cancel;

    /**
    * Checks if a communication order can be executed or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode Id
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_flg_conflict               Conflict status 
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION check_comm_order_conflict
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_flg_conflict      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'check_comm_order_conflict';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_id_comm_order_req=' ||
                    i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- TODO
        o_flg_conflict := pk_alert_constant.g_no;
    
        /*g_error  := 'Call pk_comm_orders.set_action_cancel / ' || l_params;
            g_retval := pk_comm_orders.set_action_cancel(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_comm_order_req => i_id_comm_order_req,
                                                         i_id_cancel_reason   => i_id_cancel_reason,
                                                         i_notes_cancel       => i_notes_cancel,
                                                         o_error              => o_error);
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        */
        RETURN TRUE;
    
    EXCEPTION
        --WHEN g_exception_np THEN
        --    pk_alertlog.log_warn(g_error);
        --    RETURN FALSE;
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
    END check_comm_order_conflict;

    /**
    * Checks if a communication order can be canceled or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode Id
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_flg_cancel                 Flag that indicates if cancel option is available or not for this communication order
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION check_comm_order_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_flg_cancel        OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'check_comm_order_conflict';
        l_params VARCHAR2(1000 CHAR);
    
        -- wf
        l_id_category         category.id_category%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_id_comm_order_req=' ||
                    i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
        l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof);
    
        -- func
        g_error := 'check if cancel option is available / ' || l_params;
        SELECT pk_comm_orders.check_transition(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_workflow         => cor.id_workflow,
                                               i_id_status_begin     => cor.id_status,
                                               i_id_status_end       => pk_comm_orders.g_id_sts_canceled,
                                               i_id_workflow_action  => pk_comm_orders.g_id_action_cancel,
                                               i_id_category         => l_id_category,
                                               i_id_profile_template => l_id_profile_template,
                                               i_id_comm_order_req   => cor.id_comm_order_req,
                                               i_dt_begin            => cor.dt_begin) AS flg_cancel
          INTO o_flg_cancel
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
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
            RETURN FALSE;
    END check_comm_order_cancel;

    /**
    * Gets communication orders status
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_episode              episode id
    * @param   i_task_request         array of communication order request ids
    * @param   o_date_limits          cursor with communication 
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   25-02-2014
    */
    FUNCTION get_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_date_limits  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_date_limits';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_comm_order_req=' ||
                    pk_utils.to_string(i_task_request);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get commmunication orders date limits / ' || l_params;
        OPEN o_date_limits FOR
            SELECT cor.id_comm_order_req, cor.dt_begin, NULL AS dt_end
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              column_value
                                               FROM TABLE(i_task_request) t);
    
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
            pk_types.open_my_cursor(o_date_limits);
            RETURN FALSE;
    END get_date_limits;

    /**
    * Creates a new communication order request based on an existing one (copy)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request identifier
    * @param   i_id_patient                 New patient identifier. If null, copy value from the original
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   i_dt_begin                   New begin date. If null, copy value from the original
    * @param   o_id_comm_order_req         New communication order req identifier created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   27-02-2014
    */
    FUNCTION copy_comm_order_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_id_patient        IN comm_order_req.id_patient%TYPE DEFAULT NULL,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_dt_begin          IN comm_order_req.dt_begin%TYPE DEFAULT NULL,
        o_id_comm_order_req OUT comm_order_req.id_comm_order_req%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'copy_comm_order_req';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' || i_id_comm_order_req ||
                    ' i_id_patient=' || i_id_patient || ' i_id_episode=' || i_id_episode || ' i_dt_begin=' ||
                    i_dt_begin;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_comm_orders.copy_comm_order_req / ' || l_params;
        g_retval := pk_comm_orders.copy_comm_order_req(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_comm_order_req => i_id_comm_order_req,
                                                       --i_id_status         => pk_comm_orders.g_id_sts_ongoing,
                                                       i_id_patient        => i_id_patient,
                                                       i_id_episode        => i_id_episode,
                                                       i_dt_begin          => i_dt_begin,
                                                       o_id_comm_order_req => o_id_comm_order_req,
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
    END copy_comm_order_req;

    /**
    * Gets communication order status string
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request Id
    * @param   o_task_status                Communication order status string
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION get_comm_order_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        o_task_status       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_comm_order_status';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' || i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get commmunication order status string / ' || l_params;
        SELECT pk_comm_orders.get_comm_order_status_string(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_id_comm_order_req => i_id_comm_order_req,
                                                           i_id_status         => cor.id_status,
                                                           i_dt_begin          => cor.dt_begin,
                                                           i_flg_need_ack      => cor.flg_need_ack,
                                                           i_flg_ignore_ack    => pk_alert_constant.g_yes) AS status_string
          INTO o_task_status
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_id_comm_order_req;
    
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
            RETURN FALSE;
    END get_comm_order_status;

    /**
    * Gets communication order icon
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req         Communication order request Id
    *
    * @return  varchar2                     Communication order icon
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION get_comm_order_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_comm_order_icon';
        l_params VARCHAR2(1000 CHAR);
    
        l_task_icon sys_domain.img_name%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' || i_id_comm_order_req;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get commmunication order icon / ' || l_params;
        SELECT pk_translation.get_translation(i_lang, cotype.code_icon) AS task_icon
          INTO l_task_icon
          FROM comm_order_req cor
          JOIN comm_order_type cotype
            ON cor.id_concept_type = cotype.id_comm_order_type
         WHERE cor.id_comm_order_req = i_id_comm_order_req
           AND cor.id_task_type = cotype.id_task_type;
    
        RETURN l_task_icon;
    
    END get_comm_order_icon;

    /**
    * Order a communication order request, updating state to ongoing
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 New episode identifier. If null mantains the value
    * @param   i_id_comm_order_req         Array of communication orders request identifiers
    * @param   i_dt_order                   Order date. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Order professional identifiers
    * @param   i_id_order_type              Request order type (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   28-02-2014
    */
    FUNCTION set_action_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN comm_order_req.id_episode%TYPE DEFAULT NULL,
        i_id_comm_order_req IN table_number,
        i_dt_order          IN co_sign.dt_ordered_by%TYPE,
        i_id_prof_order     IN co_sign.id_prof_ordered_by%TYPE,
        i_id_order_type     IN co_sign.id_order_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_action_order';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode ||
                    ' i_id_comm_order_req=' || pk_utils.to_string(i_id_comm_order_req) || ' i_dt_order=' || i_dt_order ||
                    ' i_id_prof_order=' || i_id_prof_order || ' i_id_order_type=' || i_id_order_type;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.set_action_order / ' || l_params;
        g_retval := pk_comm_orders.set_action_order(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_episode        => i_id_episode,
                                                    i_id_comm_order_req => i_id_comm_order_req,
                                                    i_dt_order          => i_dt_order,
                                                    i_id_prof_order     => i_id_prof_order,
                                                    i_id_order_type     => i_id_order_type,
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
    END set_action_order;

    /**
    * Updates a communication order request clinical indication
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_comm_order_req          Array of communication orders request identifiers
    * @param   i_clinical_indication        Clinical indication information
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   03-03-2014
    */
    FUNCTION update_comm_order_clin_ind
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_comm_order_req   IN table_number,
        i_clinical_indication IN pk_translation.t_lob_char,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'update_comm_order_clin_ind';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req=' ||
                    pk_utils.to_string(i_id_comm_order_req);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.update_comm_order_clin_ind / ' || l_params;
        g_retval := pk_comm_orders.update_comm_order_clin_ind(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_id_comm_order_req   => i_id_comm_order_req,
                                                              i_clinical_indication => i_clinical_indication,
                                                              o_error               => o_error);
    
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
    END update_comm_order_clin_ind;

    /**
    * Checks if a given communication order needs co-sign to be ordered
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identification and its context (institution and software)
    * @param   i_episode                  Episode id
    * @param   o_flg_prof_needs_cosign    Professional needs co-sign to order? (Y - Yes; N - No)    
    * @param   o_error                    Error information
    *
    * @return  boolean                    True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-MAR-2015
    */
    FUNCTION check_prof_needs_cosign2order
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        o_flg_prof_needs_cosign OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_prof_needs_cosign2order';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call  pk_co_sign_api.check_prof_needs_cosign / ' || l_params;
        g_retval := pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_episode,
                                                           i_task_type              => pk_alert_constant.g_task_comm_orders,
                                                           i_cosign_def_action_type => NULL,
                                                           i_action                 => pk_comm_orders.g_cs_action_add,
                                                           o_flg_prof_need_cosign   => o_flg_prof_needs_cosign,
                                                           o_error                  => o_error);
    
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
    END check_prof_needs_cosign2order;

    /**
    * Checks if a given communication order needs co-sign to be canceled
    *
    * @param   i_lang                     Professional preferred language
    * @param   i_prof                     Professional identification and its context (institution and software)
    * @param   i_episode                  Episode id
    * @param   o_flg_prof_needs_cosign    Professional needs co-sign to cancel? (Y - Yes; N - No)
    * @param   o_error                    Error information
    *
    * @return  boolean                    True on sucess, otherwise false
    *
    * @author  tiago.silva
    * @since   27-MAR-2015
    */
    FUNCTION check_prof_needs_cosign2cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        o_flg_prof_needs_cosign OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_prof_needs_cosign2cancel';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call  pk_co_sign_api.check_prof_needs_cosign / ' || l_params;
        g_retval := pk_co_sign_api.check_prof_needs_cosign(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_episode,
                                                           i_task_type              => pk_alert_constant.g_task_comm_orders,
                                                           i_cosign_def_action_type => NULL,
                                                           i_action                 => pk_comm_orders.g_cs_action_cancel_discontinue,
                                                           o_flg_prof_need_cosign   => o_flg_prof_needs_cosign,
                                                           o_error                  => o_error);
    
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
    END check_prof_needs_cosign2cancel;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_comm_orders_order_sets;
/
