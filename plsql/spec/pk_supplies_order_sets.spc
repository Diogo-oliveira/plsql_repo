/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/

CREATE OR REPLACE PACKAGE pk_supplies_order_sets IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;
    
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    -- application context
    g_context_settings CONSTANT VARCHAR2(1 CHAR) := 'S'; -- settings context
    g_context_patient  CONSTANT VARCHAR2(1 CHAR) := 'P'; -- patient context

END pk_supplies_order_sets;
/
