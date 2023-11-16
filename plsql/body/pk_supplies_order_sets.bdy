/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_order_sets IS

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
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   i_supply                     Array of supply identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies locations
    * @param   i_dt_request                 Array of dates of request
    * @param   i_dt_return                  Array of estimated dates of return
    * @param   i_id_req_reason              Array of reasons for each supply
    * @param   i_id_context                 Array of surgical procedures, in case of a surgical supply
    * @param   i_id_context                 Array of surgical procedures, in case of a surgical supply
    * @param   i_flg_cons_type              Array of flags indicating consumption type
    * @param   i_notes                      Request notes
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION set_task_parameters
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_loc      IN table_number,
        i_dt_request      IN table_varchar,
        i_dt_return       IN table_varchar,
        i_id_req_reason   IN table_number,
        i_id_context      IN table_number,
        i_flg_cons_type   IN table_varchar,
        i_notes           IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_task_parameters';
        l_params             VARCHAR2(1000 CHAR);
        l_id_supply_request  supply_request.id_supply_request%TYPE;
        l_id_supply_area_tab table_number;
        l_flg_status         table_varchar;
        l_array_empty_vc     table_varchar;
    BEGIN
        l_params         := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply_workflow.count=' ||
                            i_supply_workflow.count;
        g_error          := 'Init ' || l_func_name || ' / ' || l_params;
        l_array_empty_vc := table_varchar();
        l_flg_status     := table_varchar();
    
        -- init
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- val
        IF i_supply_workflow.count = 0
           OR i_supply_workflow.count != i_supply.count
           OR i_supply_workflow.count != i_supply_set.count
           OR i_supply_workflow.count != i_supply_qty.count
           OR i_supply_workflow.count != i_supply_loc.count
           OR i_supply_workflow.count != i_dt_request.count
           OR i_supply_workflow.count != i_dt_return.count
           OR i_supply_workflow.count != i_id_req_reason.count
           OR i_supply_workflow.count != i_notes.count
           OR i_supply_workflow.count != i_id_context.count -- used only for surgical procedures
           OR i_supply_workflow.count != i_flg_cons_type.count -- used only for surgical procedures         
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        g_error := 'extend / ' || l_params;
        l_array_empty_vc.extend(i_supply_workflow.count);
        l_flg_status.extend(i_supply_workflow.count);
    
        g_error := 'FOR i IN 1 .. ' || i_supply_workflow.count || ' / ' || l_params;
        FOR i IN 1 .. i_supply_workflow.count
        LOOP
            l_flg_status(i) := pk_supplies_constant.g_sww_predefined;
        END LOOP;
    
        -- note: when all supplies are merged, remove this code and call just one function
        g_error := 'SELECT sw.id_supply_area / ' || l_params;
        SELECT DISTINCT sw.id_supply_area
          BULK COLLECT
          INTO l_id_supply_area_tab
          FROM supply_workflow sw
          JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
            ON (t.column_value = sw.id_supply_workflow);
    
        IF l_id_supply_area_tab.count > 1
        THEN
            g_error := 'All supplies must be of the same area / i_supply_workflow=' ||
                       pk_utils.to_string(i_supply_workflow);
            RAISE g_exception;
        END IF;
    
        IF l_id_supply_area_tab(1) = pk_supplies_constant.g_area_surgical_supplies
        THEN
            -- surgical supplies
            g_error  := 'Call pk_supplies_api_db.edit_supply / ' || l_params;
            g_retval := pk_supplies_external_api_db.set_edit_supply(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_id_episode      => NULL,
                                                                    i_supply_workflow => i_supply_workflow,
                                                                    i_supply          => i_supply,
                                                                    i_supply_qty      => i_supply_qty,
                                                                    i_supply_loc      => i_supply_loc,
                                                                    i_dt_return       => i_dt_return,
                                                                    i_id_req_reason   => i_id_req_reason,
                                                                    i_id_context      => i_id_context,
                                                                    i_notes           => i_notes,
                                                                    i_flg_cons_type   => i_flg_cons_type,
                                                                    i_cod_table       => l_array_empty_vc,
                                                                    o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
            -- supplies
            g_error  := 'Call pk_supplies_api_db.edit_supply / ' || l_params;
            g_retval := pk_supplies_api_db.update_supply_order(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_episode      => NULL,
                                                               i_supply_workflow => i_supply_workflow,
                                                               i_supply          => i_supply,
                                                               i_supply_set      => i_supply_set,
                                                               i_supply_qty      => i_supply_qty,
                                                               i_supply_loc      => i_supply_loc,
                                                               i_dt_request      => i_dt_request,
                                                               i_dt_return       => i_dt_return,
                                                               i_id_req_reason   => i_id_req_reason,
                                                               i_flg_reason_req  => NULL, -- not used
                                                               i_id_context      => NULL, -- there is no context when creating supplies via order sets
                                                               i_flg_context     => NULL,
                                                               i_notes           => i_notes,
                                                               o_error           => o_error);
        
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
    END set_task_parameters;

    /**
    * Gets supply_workflow title (title and notes)
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Supply_workflow identifier
    * @param   i_flg_with_notes       Flag that indicates if notes should appear under the title or not
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION get_task_title
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_request   IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_with_notes IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_task_title';
        l_params             VARCHAR2(1000 CHAR);
        l_title              VARCHAR2(1000 CHAR);
        l_notes              VARCHAR2(1000 CHAR);
        l_format_bold_string VARCHAR2(10 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || i_task_request ||
                    ' i_flg_with_notes=' || i_flg_with_notes;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- get supply_workflow title
        g_error := 'get_supply_desc / ' || l_params;
        SELECT pk_translation.get_translation(i_lang, sa.code_supply_area) || ' - ' ||
               pk_supplies_external_api_db.get_supply_desc(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_id_supply => sw.id_supply),
               decode(i_flg_with_notes,
                      pk_alert_constant.g_yes,
                      (pk_supplies_api_db.get_attributes(i_lang, i_prof, sw.id_supply_area, sw.id_supply)),
                      NULL)
          INTO l_title, l_notes
          FROM supply_workflow sw
          JOIN supply_area sa
            ON sa.id_supply_area = sw.id_supply_area
         WHERE sw.id_supply_workflow = i_task_request;
    
        -- check if bold format has to be returned
        g_error := 'l_notes / ' || l_params;
        IF i_flg_with_notes = pk_alert_constant.g_yes
        THEN
            l_format_bold_string := '<b>@</b>';
        ELSE
            l_format_bold_string := '@';
        END IF;
    
        -- format description in bold if necessary
        g_error := 'l_format_bold_string=' || l_format_bold_string || ' / ' || l_params;
        l_title := REPLACE(l_format_bold_string, '@', l_title);
    
        IF l_notes IS NOT NULL
        THEN
            -- add attributes to the string
            l_title := l_title || chr(10) || htf.escape_sc(l_notes);
        END IF;
    
        -- return supply_workflow title
        RETURN l_title;
    
    END get_task_title;

    /**
    * Gets supply_workflow instructions
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         Supply_workflow request id
    * @param   o_task_instr           Task instructions
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   22-07-2014
    */
    FUNCTION get_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN supply_workflow.id_supply_workflow%TYPE,
        o_task_instr   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_task_instructions';
        l_params         VARCHAR2(1000 CHAR);
        l_id_supply_area supply_workflow.id_supply_area%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || i_task_request;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_supplies_api_db.get_id_supply_area / ' || l_params;
        g_retval := pk_supplies_api_db.get_id_supply_area(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_supply          => NULL,
                                                          i_flg_type           => NULL,
                                                          i_id_supply_workflow => i_task_request,
                                                          o_id_supply_area     => l_id_supply_area,
                                                          o_error              => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'l_id_supply_area=' || l_id_supply_area || ' / ' || l_params;
        IF l_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
        THEN
            -- surgical supplies
            g_error  := 'Call pk_supplies_external_api_db.get_task_instructions / ' || l_params;
            g_retval := pk_supplies_external_api_db.get_task_instructions(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_task_request => i_task_request,
                                                                          o_task_instr   => o_task_instr,
                                                                          o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
            -- supplies
            g_error  := 'Call pk_supplies_api_db.get_task_instructions / ' || l_params;
            g_retval := pk_supplies_external_api_db.get_task_instructions(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_task_request => i_task_request,
                                                                          o_task_instr   => o_task_instr,
                                                                          o_error        => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
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
            RETURN FALSE;
    END get_task_instructions;

    /**
    * Creates a predefined supply_workflow request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_area             Supply area identifier
    * @param   i_supply                     Array of supplies identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies location
    * @param   i_id_req_reason              Array of reasons for each supply
    * @param   i_notes                      Array of request notes
    * @param   i_supply_soft_inst           Array of supplies configuration identifiers
    * @param   i_flg_cons_type              Array of flag of consumption type
    * @param   o_id_supply_workflow         Array of new supply_workflow identifiers
    * @param   o_error                      Error information       
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION create_predefined_task
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_area     IN supply_area.id_supply_area%TYPE,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_id_req_reason      IN table_number,
        i_notes              IN table_varchar,
        i_supply_soft_inst   IN table_number,
        i_flg_cons_type      IN table_varchar,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_predefined_task';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_area=' || i_id_supply_area ||
                    ' i_supply.count=' || i_supply.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- creates supply_workflows in a predefined state
        g_error  := 'Call pk_supplies_api_db.create_supply_wf_predf / ' || l_params;
        g_retval := pk_supplies_external_api_db.create_supply_wf_predf(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_supply_area     => i_id_supply_area,
                                                                       i_supply             => i_supply,
                                                                       i_supply_set         => i_supply_set,
                                                                       i_supply_qty         => i_supply_qty,
                                                                       i_supply_loc         => i_supply_loc,
                                                                       i_id_req_reason      => i_id_req_reason,
                                                                       i_notes              => i_notes,
                                                                       i_supply_soft_inst   => i_supply_soft_inst,
                                                                       i_flg_cons_type      => i_flg_cons_type,
                                                                       o_id_supply_workflow => o_id_supply_workflow,
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
    * @param   i_task_request   Array of task request identifiers
    * @param   o_error          Error information
    *
    * @return  boolean          True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   18-06-2014
    */
    FUNCTION cancel_predefined_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'cancel_predefined_task';
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
        -- deletes supply_workflows
        g_error  := 'Call pk_supplies_api_db.delete_supply_workflow / ' || l_params;
        g_retval := pk_supplies_external_api_db.delete_supply_workflow(i_lang            => i_lang,
                                                                       i_prof            => i_prof,
                                                                       i_supply_workflow => i_task_request,
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
    END cancel_predefined_task;

    /**
    * Cancels a supply_workflow, updating state to canceled
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   i_id_cancel_reason           Cancel reason identifier
    * @param   i_notes_cancel               Cancelling notes
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION set_action_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_supply_workflow  IN table_number,
        i_id_episode       IN supply_workflow.id_episode%TYPE,
        i_cancel_notes     IN supply_workflow.notes_cancel%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_action_cancel';
        l_params             VARCHAR2(1000 CHAR);
        l_id_supply_area_tab table_number;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply_workflow=' ||
                    pk_utils.to_string(i_supply_workflow) || ' i_id_episode=' || i_id_episode || ' i_id_cancel_reason=' ||
                    i_id_cancel_reason;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- val
        IF i_supply_workflow.count = 0
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- getting supply_area
        g_error := 'SELECT sw.id_supply_area / ' || l_params;
        SELECT DISTINCT sw.id_supply_area
          BULK COLLECT
          INTO l_id_supply_area_tab
          FROM supply_workflow sw
          JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
            ON (t.column_value = sw.id_supply_workflow);
    
        IF l_id_supply_area_tab.count > 1
        THEN
            g_error := 'All supplies must be of the same area / i_supply_workflow=' ||
                       pk_utils.to_string(i_supply_workflow);
            RAISE g_exception;
        END IF;
    
        -- cancel supply_workflows
        IF l_id_supply_area_tab(1) = pk_supplies_constant.g_area_surgical_supplies
        THEN
            g_error  := 'Call pk_supplies_external_api_db.set_cancel_supply / ' || l_params;
            g_retval := pk_supplies_external_api_db.cancel_supply(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_supplies         => i_supply_workflow,
                                                                  i_id_episode       => i_id_episode,
                                                                  i_cancel_notes     => i_cancel_notes,
                                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                                  o_error            => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
        
            g_error  := 'Call pk_supplies_api_db.set_cancel_supply / ' || l_params;
            g_retval := pk_supplies_api_db.cancel_supply_order(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_supplies         => i_supply_workflow,
                                                               i_id_prof_cancel   => NULL,
                                                               i_cancel_notes     => i_cancel_notes,
                                                               i_id_cancel_reason => i_id_cancel_reason,
                                                               i_dt_cancel        => NULL,
                                                               o_error            => o_error);
        
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
    END set_action_cancel;

    /**
    * Checks if a supply_workflow can be executed or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode identifier
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   o_flg_conflict               Conflict status 
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION check_supply_wf_conflict
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        o_flg_conflict       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_supply_wf_conflict';
        l_params VARCHAR2(1000 CHAR);
        l_count  PLS_INTEGER;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_episode=' || i_episode || ' i_id_supply_workflow=' ||
                    i_id_supply_workflow;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT row_number() over(PARTITION BY ssi.id_supply ORDER BY ssi.id_institution DESC, ssi.id_software DESC, ssi.id_professional DESC) AS rn
                  FROM supply_workflow sw
                  JOIN supply_soft_inst ssi
                    ON (ssi.id_supply = sw.id_supply)
                 INNER JOIN supply_sup_area ssa
                    ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
                   AND ssa.flg_available = pk_alert_constant.g_yes
                   AND ssa.id_supply_area = sw.id_supply_area
                 WHERE ssi.id_institution IN (0, i_prof.institution)
                   AND ssi.id_software IN (0, i_prof.software)
                   AND sw.id_supply_workflow = i_id_supply_workflow
                   AND ((sw.id_supply_area = pk_supplies_constant.g_area_supplies) OR
                       (sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies AND
                       ssi.id_software = pk_alert_constant.g_soft_oris) -- order sets: surgical supplies can only be ordered from ORIS
                       )) t
         WHERE t.rn = 1;
    
        g_error := 'l_count=' || l_count || ' / ' || l_params;
        IF l_count > 0
        THEN
            o_flg_conflict := pk_alert_constant.g_no;
        ELSE
            o_flg_conflict := pk_alert_constant.g_yes;
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
            RETURN FALSE;
    END check_supply_wf_conflict;

    /**
    * Checks if a supply_workflow can be canceled or not
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   o_flg_cancel                 Flag that indicates if cancel option is available or not for this supply_workflow
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION check_supply_wf_cancel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        o_flg_cancel         OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_supply_wf_cancel';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params     := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_workflow=' || i_id_supply_workflow;
        o_flg_cancel := pk_alert_constant.g_no;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        SELECT pk_supplies_api_db.check_supply_wf_cancel(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_supply_area => sw.id_supply_area,
                                                         i_flg_status     => sw.flg_status,
                                                         i_quantity       => sw.quantity,
                                                         i_total_quantity => sw.total_quantity)
          INTO o_flg_cancel
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
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
    END check_supply_wf_cancel;

    /**
    * Gets supply_workflow timestamp interval (start/end dates)
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_task_request         array of supply_workflow request identifiers
    * @param   o_date_limits          cursor with suplpy_workflow start/end dates
    * @param   o_error                error structure for exception handling
    *
    * @return  boolean                True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION get_date_limits
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_date_limits  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_date_limits';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || pk_utils.to_string(i_task_request);
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error := 'get supply_workflow date limits / ' || l_params;
        OPEN o_date_limits FOR
            SELECT sw.id_supply_workflow,
                   nvl(sw.dt_request, sw.dt_supply_workflow) AS dt_begin,
                   sw.dt_returned AS dt_end
              FROM supply_workflow sw
              JOIN (SELECT /*+opt_estimate (table t rows=1)*/
                     column_value
                      FROM TABLE(i_task_request)) t
                ON (sw.id_supply_workflow = t.column_value);
    
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
    * Creates a new supply_workflow based on an existing one (copy)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   i_id_episode                 New episode identifier. If null, copy value from the original
    * @param   i_dt_request                 New date of request. If null, copy value from the original
    * @param   o_id_supply_workflow         New supply_workflow identifier created
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION copy_supply_wf
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        i_id_episode         IN supply_workflow.id_episode%TYPE DEFAULT NULL,
        i_dt_request         IN supply_workflow.dt_request%TYPE DEFAULT NULL,
        o_id_supply_workflow OUT supply_workflow.id_supply_workflow%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'copy_supply_wf';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_workflow=' || i_id_supply_workflow ||
                    ' i_id_episode=' || i_id_episode || ' i_dt_request=' || i_dt_request;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        g_error  := 'Call pk_supplies_api_db.copy_supply_wf / ' || l_params;
        g_retval := pk_supplies_external_api_db.copy_supply_wf(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_id_supply_workflow => i_id_supply_workflow,
                                                               i_id_episode         => i_id_episode,
                                                               i_dt_request         => i_dt_request,
                                                               o_id_supply_workflow => o_id_supply_workflow,
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
    END copy_supply_wf;

    /**
    * Gets supply_workflow status string
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    * @param   o_task_status                Supply_workflow status string
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   25-06-2014
    */
    FUNCTION get_supply_wf_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE,
        o_task_status        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_supply_wf_status';
        l_params      VARCHAR2(1000 CHAR);
        l_id_category category.id_category%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_workflow=' || i_id_supply_workflow;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        -- getting status string
        g_error := 'Call pk_supplies_api_db.get_supply_wf_status_string / ' || l_params;
        SELECT pk_supplies_api_db.get_supply_wf_status_string(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_flg_status         => sw.flg_status,
                                                              i_id_sys_shortcut    => NULL,
                                                              i_id_workflow        => NULL,
                                                              i_id_supply_area     => sw.id_supply_area,
                                                              i_id_category        => l_id_category,
                                                              i_dt_returned        => sw.dt_returned,
                                                              i_dt_request         => sw.dt_request,
                                                              i_dt_supply_workflow => sw.dt_supply_workflow,
                                                              i_id_episode         => sw.id_episode) AS status_string
          INTO o_task_status
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
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
    END get_supply_wf_status;

    /**
    * Gets supply_workflow icon
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_supply_workflow         Supply_workflow identifier
    *
    * @return  varchar2                     Supply_workflow icon
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   26-06-2014
    */
    FUNCTION get_supply_wf_icon
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_supply_workflow IN supply_workflow.id_supply_workflow%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_supply_wf_icon';
        l_params         VARCHAR2(1000 CHAR);
        l_error          t_error_out;
        l_id_category    category.id_category%TYPE;
        l_status_info    t_rec_wf_status_info;
        l_id_supply_area supply_workflow.id_supply_area%TYPE;
        l_id_status      wf_status.id_status%TYPE;
        l_id_workflow    wf_workflow.id_workflow%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_supply_workflow=' || i_id_supply_workflow;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- func
        l_id_category := pk_prof_utils.get_id_category(i_lang, i_prof);
    
        -- getting data from supply_workflow
        g_error := 'SELECT FROM supply_workflow sw / ' || l_params;
        SELECT sw.id_supply_area, pk_sup_status.convert_status_n(i_lang, i_prof, sw.flg_status) AS id_status
          INTO l_id_supply_area, l_id_status
          FROM supply_workflow sw
         WHERE sw.id_supply_workflow = i_id_supply_workflow;
    
        -- getting id_workflow
        g_error       := 'Call pk_supplies_api_db.get_id_workflow / ' || l_params;
        l_id_workflow := pk_supplies_api_db.get_id_workflow(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_id_supply_area => l_id_supply_area);
    
        -- getting icon information
        g_error  := 'Call pk_sup_status.get_status_config / ' || l_params;
        g_retval := pk_sup_status.get_status_config(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_id_workflow        => l_id_workflow,
                                                    i_id_status          => l_id_status,
                                                    i_id_category        => l_id_category,
                                                    o_status_config_info => l_status_info,
                                                    o_error              => l_error);
    
        RETURN l_status_info.icon;
    
    END get_supply_wf_icon;

    /**
    * Order a supply_workflow, updating state to ongoing
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 New episode identifier. If null mantains the value
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   o_supply_workflow            Array of supply_workflow identifiers created/updated
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   26-06-2014
    */
    FUNCTION set_action_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN supply_workflow.id_episode%TYPE,
        i_supply_workflow IN table_number,
        o_supply_workflow OUT table_table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'set_action_order';
        l_params             VARCHAR2(1000 CHAR);
        l_id_supply_area_tab table_number;
        l_id_supply_request  table_number;
    BEGIN
        l_params          := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_episode=' || i_id_episode ||
                             ' i_supply_workflow=' || pk_utils.to_string(i_supply_workflow);
        o_supply_workflow := table_table_number();
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        -- val
        IF i_supply_workflow.count = 0
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        -- getting supply_area
        g_error := 'SELECT sw.id_supply_area / ' || l_params;
        SELECT DISTINCT sw.id_supply_area
          BULK COLLECT
          INTO l_id_supply_area_tab
          FROM supply_workflow sw
          JOIN TABLE(CAST(i_supply_workflow AS table_number)) t
            ON (t.column_value = sw.id_supply_workflow);
    
        IF l_id_supply_area_tab.count > 1
        THEN
            g_error := 'All supplies must be of the same area / i_supply_workflow=' ||
                       pk_utils.to_string(i_supply_workflow);
            RAISE g_exception;
        END IF;
    
        -- order predefined supply_workflows
        IF l_id_supply_area_tab(1) = pk_supplies_constant.g_area_surgical_supplies
        THEN
            g_error  := 'Call pk_supplies_external_api_db.set_supply_wf_order_predf / ' || l_params;
            g_retval := pk_supplies_external_api_db.set_supply_wf_order_predf(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_supply_workflow    => i_supply_workflow,
                                                                              i_id_episode         => i_id_episode,
                                                                              o_id_supply_request  => l_id_supply_request,
                                                                              o_id_supply_workflow => o_supply_workflow,
                                                                              o_error              => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        ELSE
            g_error  := 'Call pk_supplies_api_db.set_supply_wf_order_predf / ' || l_params;
            g_retval := pk_supplies_external_api_db.set_supply_wf_order_predf(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_supply_workflow    => i_supply_workflow,
                                                                              i_id_episode         => i_id_episode,
                                                                              o_id_supply_request  => l_id_supply_request,
                                                                              o_id_supply_workflow => o_supply_workflow,
                                                                              o_error              => o_error);
        
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
    END set_action_order;

    /**
    * Checks if all mandatory fields are filled in this supply_workflow
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_task_request               Supply_workflow identifier
    * @param   i_flg_context                Flag that indicates the application context where this function is being called
    * @param   o_check                      Indicate if this supply_workflow has all mandatory fields filled
    * @param   o_error                      Error information
    *
    * @value   i_flg_context                {*} 'S' settings context
    *                                       {*} 'P' patient context
    *
    * @value   o_check                      {*} 'Y'- has all mandatory fields filled 
    *                                       {*} 'N'- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   17-07-2014
    */
    FUNCTION check_mandatory_field
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN supply_workflow.id_supply_workflow%TYPE,
        i_flg_context  IN VARCHAR2,
        o_check        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'check_mandatory_field';
        l_params             VARCHAR2(1000 CHAR);
        l_id_supply_area     supply_workflow.id_supply_area%TYPE;
        l_id_supply_location supply_workflow.id_supply_location%TYPE;
        l_id_req_reason      supply_workflow.id_req_reason%TYPE;
        l_quantity           supply_workflow.quantity%TYPE;
        l_flg_cons_type      supply_workflow.flg_cons_type%TYPE;
        l_dt_returned        supply_workflow.dt_returned%TYPE;
        l_dt_request         supply_workflow.dt_request%TYPE;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_task_request=' || i_task_request ||
                    ' i_flg_context=' || i_flg_context;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
        o_check := pk_alert_constant.g_no;
    
        -- getting supply_area
        BEGIN
            g_error := 'SELECT sw.id_supply_area / ' || l_params;
            SELECT sw.id_supply_area,
                   sw.id_supply_location,
                   sw.id_req_reason,
                   sw.quantity,
                   sw.flg_cons_type,
                   sw.dt_returned,
                   sw.dt_request
              INTO l_id_supply_area,
                   l_id_supply_location,
                   l_id_req_reason,
                   l_quantity,
                   l_flg_cons_type,
                   l_dt_returned,
                   l_dt_request
              FROM supply_workflow sw
             WHERE sw.id_supply_workflow = i_task_request;
        EXCEPTION
            WHEN no_data_found THEN
                o_check := pk_alert_constant.g_no;
        END;
    
        l_params := l_params || ' l_id_supply_area=' || l_id_supply_area;
    
        CASE i_flg_context
        
            WHEN g_context_settings THEN
                -- personal settings
                g_error := 'IF l_id_supply_area / ' || l_params;
                IF l_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                THEN
                
                    -- Surgical Supplies
                    IF l_id_supply_location IS NOT NULL
                       AND l_quantity IS NOT NULL
                       AND l_flg_cons_type IS NOT NULL
                    THEN
                        o_check := pk_alert_constant.g_yes;
                    END IF;
                
                ELSE
                
                    -- Supplies
                    IF l_id_supply_location IS NOT NULL
                       AND l_id_req_reason IS NOT NULL
                       AND l_quantity IS NOT NULL
                    THEN
                        o_check := pk_alert_constant.g_yes;
                    END IF;
                
                END IF;
            
            WHEN g_context_patient THEN
            
                -- patient area context              
                g_error := 'IF l_id_supply_area / ' || l_params;
                IF l_id_supply_area = pk_supplies_constant.g_area_surgical_supplies
                THEN
                
                    -- Surgical Supplies
                    IF l_id_supply_location IS NOT NULL
                       AND l_quantity IS NOT NULL
                       AND l_flg_cons_type IS NOT NULL
                       AND
                       ((l_dt_returned IS NULL AND l_flg_cons_type != pk_supplies_constant.g_consumption_type_loan) OR
                       (l_dt_returned IS NOT NULL AND l_flg_cons_type = pk_supplies_constant.g_consumption_type_loan))
                    THEN
                        o_check := pk_alert_constant.g_yes;
                    END IF;
                
                ELSE
                
                    -- Supplies
                    IF l_id_supply_location IS NOT NULL
                       AND l_id_req_reason IS NOT NULL
                       AND l_quantity IS NOT NULL
                       AND l_dt_request IS NOT NULL
                    THEN
                        o_check := pk_alert_constant.g_yes;
                    END IF;
                END IF;
            ELSE
                g_error := 'Context not found / ' || l_params;
                RAISE g_exception;
        END CASE;
    
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
    END check_mandatory_field;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);

END pk_supplies_order_sets;
/
