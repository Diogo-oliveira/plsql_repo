/*-- Last Change Revision: $Rev: 1913028 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-08-22 09:32:51 +0100 (qui, 22 ago 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_orders_cpoe_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

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
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders_cpoe.create_draft / ' || l_params;
        g_retval := pk_comm_orders_cpoe.create_draft(i_lang                    => i_lang,
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
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_task_parameters';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_comm_order_req.count=' ||
                    i_id_comm_order_req.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_comm_orders.set_task_parameters / ' || l_params;
        g_retval := pk_comm_orders_cpoe.set_task_parameters(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_comm_order_req     => i_id_comm_order_req,
                                                            i_flg_free_text         => i_flg_free_text,
                                                            i_desc_comm_order       => i_desc_comm_order,
                                                            i_notes                 => i_notes,
                                                            i_clinical_indication   => i_clinical_indication,
                                                            i_flg_clinical_purpose  => i_flg_clinical_purpose,
                                                            i_clinical_purpose_desc => i_clinical_purpose_desc,
                                                            i_flg_priority          => i_flg_priority,
                                                            i_flg_prn               => i_flg_prn,
                                                            i_prn_condition         => i_prn_condition,
                                                            i_dt_begin_str          => i_dt_begin_str,
                                                            i_dt_order_str          => i_dt_order_str,
                                                            i_id_prof_order         => i_id_prof_order,
                                                            i_id_order_type         => i_id_order_type,
                                                            o_error                 => o_error);
    
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
    END set_task_parameters;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_comm_orders_cpoe_ux;
/
