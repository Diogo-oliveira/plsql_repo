/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_supplies_order_sets_ux IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    /**
    * Creates a predefined supply_workflow request
    * Used for supplies area (id_supply_area=1)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply                     Array of supplies identifiers
    * @param   i_supply_set                 Array of parent supplies set (if applicable)
    * @param   i_supply_qty                 Array of supplies quantities
    * @param   i_supply_loc                 Array of supplies location
    * @param   i_id_req_reason              Array of reasons for each supply
    * @param   i_notes                      Array of request notes
    * @param   i_supply_soft_inst           Array of supplies configuration identifiers
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
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_supply_loc         IN table_number,
        i_id_req_reason      IN table_number,
        i_notes              IN table_varchar,
        i_supply_soft_inst   IN table_number,
        o_id_supply_workflow OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_predefined_task';
        l_params        VARCHAR2(1000 CHAR);
        l_flg_cons_type table_varchar;
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply.count=' || i_supply.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        l_flg_cons_type := table_varchar();
        l_flg_cons_type.extend(i_supply.count);
    
        g_error  := 'Call pk_supplies_order_sets.create_predefined_task / ' || l_params;
        g_retval := pk_supplies_order_sets.create_predefined_task(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_id_supply_area     => pk_supplies_constant.g_area_supplies,
                                                                  i_supply             => i_supply,
                                                                  i_supply_set         => i_supply_set,
                                                                  i_supply_qty         => i_supply_qty,
                                                                  i_supply_loc         => i_supply_loc,
                                                                  i_id_req_reason      => i_id_req_reason,
                                                                  i_notes              => i_notes,
                                                                  i_supply_soft_inst   => i_supply_soft_inst,
                                                                  i_flg_cons_type      => l_flg_cons_type,
                                                                  o_id_supply_workflow => o_id_supply_workflow,
                                                                  o_error              => o_error);
    
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
    END create_predefined_task;

    /**
    * Creates a predefined supply_workflow request
    * Used for surgical supplies area (id_supply_area=3)
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
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
    FUNCTION create_predefined_task_sr
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
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
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'create_predefined_task_sr';
        l_params VARCHAR2(1000 CHAR);
    
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply.count=' || i_supply.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_supplies_order_sets.create_predefined_task / ' || l_params;
        g_retval := pk_supplies_order_sets.create_predefined_task(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_id_supply_area     => pk_supplies_constant.g_area_surgical_supplies,
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
    END create_predefined_task_sr;

    /**
    * Updates a task
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_supply_workflow            Array of supply_workflow identifiers
    * @param   i_flg_status                 Array of flags indicating supply_workflow states
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
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_supply_workflow.count=' || i_supply_workflow.count;
    
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        g_error  := 'Call pk_supplies_order_sets.set_task_parameters / ' || l_params;
        g_retval := pk_supplies_order_sets.set_task_parameters(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_supply_workflow => i_supply_workflow,
                                                               i_supply          => i_supply,
                                                               i_supply_set      => i_supply_set,
                                                               i_supply_qty      => i_supply_qty,
                                                               i_supply_loc      => i_supply_loc,
                                                               i_dt_request      => i_dt_request,
                                                               i_dt_return       => i_dt_return,
                                                               i_id_req_reason   => i_id_req_reason,
                                                               i_id_context      => i_id_context,
                                                               i_flg_cons_type   => i_flg_cons_type,
                                                               i_notes           => i_notes,
                                                               o_error           => o_error);
    
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
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_supplies_order_sets_ux;
/
