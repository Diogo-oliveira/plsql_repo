/*-- Last Change Revision: $Rev: 2050782 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-11-23 11:11:41 +0000 (qua, 23 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_cpoe IS

    -- Computerized Prescription Order Entry (CPOE) database package

    /********************************************************************************************
    * get group task id for a given task type
    *
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      number                    task group type id
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_group_id
    (
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * get group task name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task group type name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_group_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_show_out_msg IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get task type name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task type name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_task_type_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get group task rank for a given task type
    *
    * @param       i_prof           professional id structure
    * @param       i_id_task_type   Task type ID
    *
    * @return      task group type rank
    *
    * @author      Tiago Silva
    * @since       2009/10/28
    ********************************************************************************************/
    FUNCTION get_task_group_rank
    (
        i_prof         IN profissional,
        i_id_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * get task rank for a given task type
    *
    * @param       i_prof           professional id structure
    * @param       i_id_task_type   Task type ID
    *
    * @return      task type rank
    *
    * @author      Tiago Silva
    * @since       2014/01/31
    ********************************************************************************************/
    FUNCTION get_task_type_rank
    (
        i_prof         IN profissional,
        i_id_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * get task type icon name for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               task type id
    *
    * @return      varchar2                  task type icon name
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_task_type_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get all task types that can be requested in CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_task_types              task types id of the episode
    * @param       o_task_type_list_frequent cursor with all task types (for most frequent search)
    * @param       o_task_type_list_search   cursor with all task types (for advanced search)
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/19
    ********************************************************************************************/
    FUNCTION get_task_type_list
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_task_types              IN table_number,
        i_filter                  IN VARCHAR2,
        o_task_type_list_frequent OUT pk_types.cursor_type,
        o_task_type_list_search   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if a task action can be performed for a given professional and environment
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_task_type   cpoe task type id
    * @param   i_action      action id  
    * @param   i_episode     episode id
    *
    * @return  varchar2:    'Y': task action available, 'I': task action not available
    *
    * @author  Carlos Loureiro
    * @since   2009/10/19
    ********************************************************************************************/
    FUNCTION check_task_action_avail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE,
        i_action    IN cpoe_task_permission.id_action%TYPE,
        i_episode   IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check if a prescription action can be performed for a given professional
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_action      action id  
    *
    * @return  varchar2:     'A': prescription action available, 'I': prescription action not available
    *
    * @author  Carlos Loureiro
    * @since   2010/08/31
    ********************************************************************************************/
    FUNCTION check_presc_action_avail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.id_action%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get cpoe task type (reverse) for other modules API usage
    *
    * @param       i_task_type            task type id
    *
    * @return      reversed cpoe task type id
    *
    * @author      Carlos Loureiro
    * @since       2010/07/10
    ********************************************************************************************/
    FUNCTION get_reverse_task_type_map(i_task_type IN cpoe_task_type.id_task_type%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * get all task types to be presented in main CPOE grid
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_filter                  task status filter for CPOE
    * @param       o_cpoe_grid               grid containing all task types
    * @param       o_cpoe_tabs               tabs containing descriptions and task counters
    * @param       o_cpoe_info               cursor containing information about current CPOE
    * @param       o_error                   error message
    *
    * @value       i_filter                  {*} 'C' Current
    *                                        {*} 'A' Active   
    *                                        {*} 'I' Inactive 
    *                                        {*} 'D' Draft
    *                                        {*} '*' All   
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/10/24
    ********************************************************************************************/
    FUNCTION get_cpoe_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_filter       IN VARCHAR2,
        o_cpoe_grid    OUT pk_types.cursor_type,
        o_cpoe_tabs    OUT pk_types.cursor_type,
        o_cpoe_info    OUT pk_types.cursor_type,
        o_task_types   OUT table_number,
        o_can_req_next OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cpoe_grid
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_filter  IN VARCHAR2
    ) RETURN t_tbl_cpoe_task_list;

    PROCEDURE init_params_cpoe_grid
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    FUNCTION get_cpoe_info_grid
        (
            i_lang      IN language.id_language%TYPE,
            i_prof      IN profissional,
            i_patient   IN patient.id_patient%TYPE,
            i_episode   IN episode.id_episode%TYPE,
            i_filter    IN VARCHAR2,
            o_cpoe_tabs OUT pk_types.cursor_type,
            o_cpoe_info OUT pk_types.cursor_type,
            o_error     OUT t_error_out
        ) RETURN BOOLEAN;    
    */
    FUNCTION get_cpoe_info_grid
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_filter    IN VARCHAR2,
        o_cpoe_tabs OUT pk_types.cursor_type,
        o_cpoe_info OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task status refresh flag to indicate if task should be copied to draft prescription 
    *
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   varchar2                  refresh flag
    *
    * @value    get_task_status_refresh   {*} 'Y' task should be refreshed to draft area
    *                                     {*} 'N' do not refresh task to draft area    
    *
    * @author                             Carlos Loureiro
    * @since                              07-Sep-2010
    ********************************************************************************************/
    FUNCTION get_task_status_refresh
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get task status new prescription flag to indicate if task should be considered in new prescription
    *
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   varchar2                  new process flag
    *
    * @value    get_task_status_refresh   {*} 'Y' task should be considered in new prescription
    *                                     {*} 'N' do not consider task in new prescription
    *
    * @author                             Carlos Loureiro
    * @since                              13-Sep-2010
    ********************************************************************************************/
    FUNCTION get_task_status_new_presc
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * verify CPOE working mode for given institution or software
    *
    * @param       i_lang            preferred language id for this professional    
    * @param       i_prof            professional id structure
    * @param       o_flg_mode        CPOE working mode 
    * @param       o_error           error message
    *
    * @value       o_flg_mode        {*} 'S' working in simple mode 
    *                                {*} 'A' working in advanced mode
    *
    * @return      boolean           true or false on success or error
    *
    * @author                        Carlos Loureiro
    * @since                         2009/11/06
    ********************************************************************************************/
    FUNCTION get_cpoe_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_mode OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get CPOE actions
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id     
    * @param       i_filter                  task status filter for CPOE
    * @param       i_task_type               array with the selected task types
    * @param       i_task_request            array with the selected task requisition IDs    
    * @param       i_task_conflict           array with the conflicts indicator of the selected tasks (used for drafts only)
    * @param       i_task_draft              array with the drafts indicator of the selected tasks
    * @param       o_actions                 list of CPOE actions
    * @param       o_error                   error message
    *
    * @value       i_filter                  {*} 'C' Current
    *                                        {*} 'A' Active   
    *                                        {*} 'I' Inactive 
    *                                        {*} 'D' Draft
    *                                        {*} '*' All
    *                                        {*} 'H' History
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter        IN VARCHAR2,
        i_task_type     IN table_number,
        i_task_request  IN table_number,
        i_task_conflict IN table_varchar,
        i_task_draft    IN table_varchar,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * perform a CPOE action 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_action                  action id
    * @param       i_task_type               array of cpoe task type IDs
    * @param       i_task_request            array of task requisition IDs (also used for drafts)
    * @param       i_flg_conflict_answer     array with the answers of the conflicts pop-ups (only used in some actions)
    * @param       i_cdr_call                clinical decision rules call id    
    * @param       o_action                  action id (required by the flash layer)
    * @param       o_task_type               array of cpoe task type IDs (required by the flash layer)
    * @param       o_task_request            array of task requisition IDs (also used for drafts) (required by the flash layer)
    * @param       o_new_task_request        array with the new generated requisition IDs (only used in some actions)
    * @param       o_flg_conflict            array of action conflicts indicators (only used in some actions)
    * @param       o_msg_template            array of message/pop-up templates (only used in some actions)
    * @param       o_msg_title               array of message titles (only used in some actions)
    * @param       o_msg_body                array of message bodies (only used in some actions)
    * @param       o_flg_validated           array of validated flags (which indicates if an auxiliary  screen should be loaded or not)
    * @param       o_error                   error message
    *
    * @value       i_flg_conflict_answer     {*} 'Y' draft must be activated even if it has conflicts
    *                                        {*} 'N' draft shouldn't be activated
    *
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts
    *                                        {*} 'N' no conflicts found
    *
    * @value       o_msg_template            {*} 'WARNING_READ' Warning Read
    *                                        {*} 'WARNING_CONFIRMATION' Warning Confirmation
    *                                        {*} 'WARNING_CANCEL' Warning Cancel
    *                                        {*} 'WARNING_HELP_SAVE' Warning Help Save
    *                                        {*} 'WARNING_SECURITY' Warning Security
    *                                        {*} 'CONFIRMATION' Confirmation
    *                                        {*} 'DETAIL' Detail
    *                                        {*} 'HELP' Help
    *                                        {*} 'WIZARD' Wizard
    *                                        {*} 'ADVANCED_INPUT' Advanced Input
    *
    * @value       o_flg_validated           {*} 'Y' validated! no user inputs are needed
    *                                        {*} 'N' not validated! user needs to validare this action
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Tiago Silva
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION set_action
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_action              IN action.id_action%TYPE,
        i_task_type           IN table_number,
        i_task_request        IN table_number,
        i_flg_conflict_answer IN table_varchar,
        i_cdr_call            IN cdr_call.id_cdr_call%TYPE,
        i_flg_task_to_copy    IN table_varchar,
        o_action              OUT action.id_action%TYPE,
        o_task_type           OUT table_number,
        o_task_request        OUT table_number,
        o_new_task_request    OUT table_number,
        o_flg_conflict        OUT table_varchar,
        o_msg_template        OUT table_varchar,
        o_msg_title           OUT table_varchar,
        o_msg_body            OUT table_varchar,
        o_flg_validated       OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_task_bounds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_task_type          IN cpoe_task_type.id_task_type%TYPE,
        i_ts_task_start      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_task_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_start      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_end        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_next_start IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_ts_cpoe_next_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id (also used for draft activation)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 2009/11/23
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN cpoe_task_type.id_task_type%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * synchronize requested task with cpoe processes in task creation or draft activation
    * this overload is used for tasks that creates a new request for each statua transition
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_old_task_request        old task request id (also used for draft activation)
    * @param       i_new_task_request        new task request id (also used for draft activation)   
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 2009/12/09
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_type            IN cpoe_task_type.id_task_type%TYPE,
        i_old_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_new_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION request_task_to_next_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        o_new_task_request OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_into_rel_tasks
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_cpoe_process IN NUMBER,
        i_tasks_orig   IN table_number,
        i_tasks_dest   IN table_number,
        i_tasks_type   IN table_number,
        i_flg_type     IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_from_rel_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tasks      IN table_number,
        i_tasks_type IN table_number,
        i_flg_draft  IN VARCHAR2 DEFAULT 'N',
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * checks within cpoe if the given tasks can be created or not (in tasks requests)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_dt_start                tasks start timestamps
    * @param       i_dt_end                  tasks end timestamps
    * @param       i_task_id                 task ids (can be used with drafts also)
    * @param       o_task_list               list of tasks, according to cpoe confirmation grid
    * @param       o_flg_warning_type        warning type flag
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body, according to warning type flag
    * @param       o_proc_start              cpoe process start timestamp (for new cpoe process)
    * @param       o_proc_end                cpoe process end timestamp (for new cpoe process)
    * @param       o_proc_refresh            cpoe refresh to draft prescription timestamp (for new cpoe process)
    * @param       o_error                   error message
    *        
    * @value       o_flg_warning_type        {*} 'O' timestamps out of bounds
    *                                        {*} 'C' confirm cpoe creation
    *                                        {*} NULL proceed task creation, without warnings
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 14-Sep-2010
    ********************************************************************************************/
    FUNCTION check_tasks_creation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN table_number,
        i_dt_start          IN table_varchar,
        i_dt_end            IN table_varchar,
        i_task_id           IN table_varchar,
        i_tab_type          IN VARCHAR2 DEFAULT NULL,
        o_task_list         OUT pk_types.cursor_type,
        o_flg_warning_type  OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_proc_start        OUT VARCHAR2,
        o_proc_end          OUT VARCHAR2,
        o_proc_refresh      OUT VARCHAR2,
        o_proc_next_start   OUT VARCHAR2,
        o_proc_next_end     OUT VARCHAR2,
        o_proc_next_refresh OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cpoe_message
    (
        i_lang         IN language.id_language%TYPE,
        i_code_message IN sys_message.code_message%TYPE,
        i_param1       IN VARCHAR2,
        i_param2       IN VARCHAR2,
        i_param3       IN VARCHAR2,
        i_param4       IN VARCHAR2,
        i_param5       IN VARCHAR2,
        i_param6       IN VARCHAR2,
        i_param7       IN VARCHAR2,
        i_param8       IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * checks within cpoe if the given tasks can be created or not (in draft activations)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_dt_start                tasks start timestamps
    * @param       i_dt_end                  tasks end timestamps
    * @param       i_draft_request           draft task ids
    * @param       i_flg_new_presc           flag that indicates if a new prescription is needed
    * @param       o_task_list               list of tasks, according to cpoe confirmation grid
    * @param       o_flg_warning_type        warning type flag
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body, according to warning type flag
    * @param       o_proc_start              cpoe process start timestamp (for new cpoe process)
    * @param       o_proc_end                cpoe process end timestamp (for new cpoe process)
    * @param       o_proc_refresh            cpoe refresh to draft prescription timestamp (for new cpoe process)
    * @param       o_error                   error message
    *
    * @value       i_flg_new_presc           {*} 'Y' drafts will be activated in a new prescription
    *                                        {*} 'N' drafts will be activated in current prescription
    *        
    * @value       o_flg_warning_type        {*} 'O' timestamps out of bounds
    *                                        {*} 'C' confirm cpoe creation
    *                                        {*} 'P' force the creation of a new prescription
    *                                        {*} 'B' block the creation of a new prescription
    *                                        {*} NULL proceed task creation, without warnings
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 10-Sep-2010
    ********************************************************************************************/

    FUNCTION check_drafts_activation
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_task_type         IN table_number,
        i_dt_start          IN table_varchar,
        i_dt_end            IN table_varchar,
        i_draft_request     IN table_number,
        o_task_list         OUT pk_types.cursor_type,
        o_flg_warning_type  OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_proc_start        OUT VARCHAR2,
        o_proc_end          OUT VARCHAR2,
        o_proc_refresh      OUT VARCHAR2,
        o_proc_next_start   OUT VARCHAR2,
        o_proc_next_end     OUT VARCHAR2,
        o_proc_next_refresh OUT VARCHAR2,
        o_cpoe_process      OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create active cpoe 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_proc_start              new cpoe process start timestamp
    * @param       i_proc_end                new cpoe process end timestamp
    * @param       i_proc_refresh            new cpoe refresh to draft prescription timestamp
    * @param       o_cpoe_process            created cpoe process id
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/21   
    ********************************************************************************************/
    FUNCTION create_cpoe
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_proc_start        IN VARCHAR2,
        i_proc_end          IN VARCHAR2,
        i_proc_refresh      IN VARCHAR2,
        i_proc_next_start   IN VARCHAR2,
        i_proc_next_end     IN VARCHAR2,
        i_proc_next_refresh IN VARCHAR2,
        i_proc_type         IN VARCHAR2,
        o_cpoe_process      OUT cpoe_process.id_cpoe_process%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * checks the creation of a new active cpoe (plus button action)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       o_dt_proc_start           start timestamp of new cpoe prescription
    * @param       o_dt_proc_end             end timestamp of new cpoe prescription
    * @param       o_msg_title               message title for confirmation dialog box
    * @param       o_msg_body                message body for confirmation dialog box
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/21   
    ********************************************************************************************/
    FUNCTION check_cpoe_creation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_dt_proc_start OUT VARCHAR2,
        o_dt_proc_end   OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_body      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * refresh the draft prescription based in current active/expired prescription
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_cpoe_process            current cpoe process id
    * @param       i_auto_mode               indicates if this function is called by an automatic job
    * @param       o_draft_task_type         array of created draft task types
    * @param       o_draft_task_request      array of created draft task requests  
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @value       i_auto_mode               {*} 'Y' this function is being called by the system
    *                                        {*} 'N' this function is being called by the user
    *
    * @author                                Carlos Loureiro
    * @since                                 01-Set-2010   
    ********************************************************************************************/
    /*FUNCTION refresh_draft_prescription
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_cpoe_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_auto_mode          IN VARCHAR2,
        o_draft_task_type    OUT table_number,
        o_draft_task_request OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;*/

    /********************************************************************************************
    * refresh the draft prescription based in current active/expired prescription
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_cpoe_process            current cpoe process id
    * @param       o_draft_task_type         array of created draft task types
    * @param       o_draft_task_request      array of created draft task requests  
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 01-Set-2010   
    ********************************************************************************************/
    FUNCTION refresh_draft_prescription
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_cpoe_process       IN cpoe_process.id_cpoe_process%TYPE,
        o_draft_task_type    OUT table_number,
        o_draft_task_request OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * this procedure performs cpoe specific tasks (to be called by an oracle job)
    *
    * tasks performed here:
    * -> refresh all refreshable tasks into draft prescriptions, according to each institution config
    *
    * @author                                Carlos Loureiro
    * @since                                 17-Sep-2010
    ********************************************************************************************/
    PROCEDURE cpoe_job_draft_refresh;

    /********************************************************************************************
    * this procedure performs cpoe specific tasks (to be called by an oracle job)
    *
    * tasks performed here:
    * -> expire all cpoe processes (and tasks), according to each institution config 
    *
    * @author                                Tiago Silva
    * @since                                 25-Nov-2009
    ********************************************************************************************/
    PROCEDURE cpoe_job_expire;

    /********************************************************************************************
    * get cpoe current status and warning messages (to be called by reports)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_flg_cpoe_status         cpoe status flag
    * @param       o_cpoe_warning_message    cpoe warning message
    * @param       o_error                   error message    
    *
    * @return      boolean                   true on success, otherwise false   
    *
    * @author                                Tiago Silva
    * @since                                 2011/08/01
    ********************************************************************************************/
    FUNCTION get_cpoe_warning_messages
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        o_flg_cpoe_status      OUT VARCHAR2,
        o_cpoe_warning_message OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_presc_limits
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_filter         IN VARCHAR2,
        i_from_ux        IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_task_type      IN task_type.id_task_type%TYPE,
        o_ts_presc_start OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_ts_presc_end   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_ts_next_presc  OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_proc_exists    OUT BOOLEAN
    );

    /********************************************************************************************
    * check the current cpoe status (to be called on patient's ehr access)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_flg_warning             warning flag to show (or not) message
    * @param       o_msg_template            message/pop-up template
    * @param       o_msg_title               message title
    * @param       o_msg_body                message body
    * @param       o_error                   error message
    *
    * @value       o_flg_warning             {*} 'Y' show expired cpoe message 
    *                                        {*} 'N' proceed without showing any message
    *
    * @value       o_msg_template            {*} 'WARNING_READ' warning read
    *                                        {*} 'WARNING_SECURITY' warning security
    *
    * @return      boolean                   true on success, otherwise false   
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/11/28
    ********************************************************************************************/
    FUNCTION check_cpoe_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_flg_warning  OUT VARCHAR2,
        o_msg_template OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_body     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task report filter based in task type status  
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_prof                    professional id structure
    * @param    i_task_type               task type
    * @param    i_flg_status              task status
    *
    * @return   boolean                   indicates if task is visible in reports 
    *
    * @author                             Carlos Loureiro
    * @since                              2009/12/10
    ********************************************************************************************/
    FUNCTION get_task_report_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN VARCHAR2,
        i_flg_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get last cpoe information
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       o_cpoe_process            cpoe process id
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    * @param       o_flg_status              cpoe status flag
    * @param       o_id_professional         creator id (professional id)
    * @param       o_error                   error message
    *        
    * @value       o_flg_status              {*} 'A' cpoe is currently active
    *                                        {*} 'E' last cpoe is expired 
    *                                        {*} 'N' no cpoe created so far
    *
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/17
    ********************************************************************************************/
    FUNCTION get_last_cpoe_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        o_cpoe_process    OUT cpoe_process.id_cpoe_process%TYPE,
        o_dt_start        OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_flg_status      OUT cpoe_process.flg_status%TYPE,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get next cpoe information (get data input for new cpoe prescriprion action)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       o_dt_start                cpoe start timestamp
    * @param       o_dt_end                  cpoe end timestamp
    * @param       o_dt_refresh              cpoe "refresh to draft prescription" timestamp
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/18
    *
    * The CPOE Period will be dependent of the episode clinical service associated with it.
    * The id_episode will be needed in order to get the id_dep_clin_serv from the EPIS_INFO
    * @author                                Joao Reis
    * @since                                 2011/09/21
    ********************************************************************************************/
    FUNCTION get_next_cpoe_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dt_start      IN cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_start      OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end        OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_dt_refresh    OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_dt_next_presc OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get complete messages by replacing wildcards by context values  
    *
    * @param    i_lang                    preferred language id for this professional
    * @param    i_code_message            code message from sys_message
    * @param    i_param1                  replacing string @1
    * @param    i_param2                  replacing string @2
    * @param    i_param3                  replacing string @3
    * @param    i_param4                  replacing string @4
    * @param    i_param5                  replacing string @5
    *
    * @return   varchar2                  message with replaced wildcards 
    *
    * @author                             Carlos Loureiro
    * @since                              2009/11/21
    ********************************************************************************************/
    FUNCTION get_cpoe_message
    (
        i_lang         IN language.id_language%TYPE,
        i_code_message IN sys_message.code_message%TYPE,
        i_param1       IN VARCHAR2,
        i_param2       IN VARCHAR2 DEFAULT NULL,
        i_param3       IN VARCHAR2 DEFAULT NULL,
        i_param4       IN VARCHAR2 DEFAULT NULL,
        i_param5       IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check if task type requires an active cpoe (task creation / activation requirement)  
    *
    * @param    i_lang                       preferred language id for this professional
    * @param    i_prof                       professional id structure
    * @param    i_task_type                  cpoe task type id
    *
    * @return   varchar2                     flag that indicates if task type requires or not an 
    *                                        active cpoe
    *
    * @value    check_task_cpoe_requirement  {*} 'Y' active cpoe is needed to create this type
    *                                        {*} 'N' no actived cpoe needed to create this type
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/11/21
    ********************************************************************************************/
    FUNCTION check_task_cpoe_requirement
    (
        i_prof      profissional,
        i_task_type cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check if task type expires for the given institution/software environment  
    *
    * @param    i_prof                       professional id structure
    * @param    i_task_type                  cpoe task type id
    *
    * @return   varchar2                     flag that indicates if task type requires or not an 
    *                                        active cpoe
    *
    * @value    check_task_cpoe_expire       {*} 'Y' task expires with prescription
    *                                        {*} 'N' task doesn't expire with prescription
    *   
    * @author                                Carlos Loureiro
    * @since                                 2009/12/05
    ********************************************************************************************/
    FUNCTION check_task_cpoe_expire
    (
        i_prof      profissional,
        i_task_type cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get all patient's prescriptions history
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       o_cpoe_hist               cursor containing information about all prescriptions 
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/02
    ********************************************************************************************/
    FUNCTION get_cpoe_history
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_cpoe_hist OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get a patient's prescription tasks history (cpoe process detail)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/02
    ********************************************************************************************/
    FUNCTION get_cpoe_task_history
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_process   IN cpoe_process.id_cpoe_process%TYPE,
        o_cpoe_task OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get a patient's prescription tasks report
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_info               cursor containing information about prescription information
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @value       i_process                 {*} <ID>   cursors will have given process information
    *                                        {*} <NULL> cursors will have last/current process information 
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_cpoe_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_task_ids      IN table_number DEFAULT NULL,
        i_task_type_ids IN table_number DEFAULT NULL,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_cpoe_info     OUT pk_types.cursor_type,
        o_cpoe_task     OUT pk_types.cursor_type,
        o_execution     OUT pk_types.cursor_type,
        o_med_admin     OUT pk_types.cursor_type,
        o_proc_plan     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * clear specific cpoe processes or clear all cpoe processes related with a list of patients
    *
    * @param       i_lang              preferred language id for this professional
    * @param       i_prof              professional id structure
    * @param       i_patients          patients array
    * @param       i_cpoe_processes    cpoe processes array         
    * @param       o_error             error message
    *        
    * @return      boolean             true on success, otherwise false    
    *   
    * @author                          Tiago Silva
    * @since                           2010/11/02
    ********************************************************************************************/
    FUNCTION clear_cpoe_processes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patients       IN table_number DEFAULT NULL,
        i_cpoe_processes IN table_number DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get the closed task filter timestamp (with local tiome zone) used by CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       o_closed_task_filter_tstz closed task filter timestamp (with local tiome zone)
    *                                        note: if null, no cpoe was created or cpoe is not  
    *                                              working in advanced mode
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    *
    * @author                                Carlos Loureiro
    * @since                                 25-Jan-2011
    ********************************************************************************************/
    FUNCTION get_closed_task_filter_tstz
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        o_closed_task_filter_tstz OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get date char string properly formatted from a timestamp, for a given task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               episode id
    * @param       i_timestamp               closed task filter timestamp (with local tiome zone)
    *
    * @return      varchar2                  formatted date char timestamp, related to given task type    
    *
    * @author                                Carlos Loureiro
    * @since                                 11-OCT-2011
    ********************************************************************************************/
    FUNCTION get_date_char_by_task_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get cpoe end date timestamp for a given task type/request
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id 
    * @param       o_end_date                cpoe end date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 10-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cpoe_end_date_by_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_end_date     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get cds task type for given cpoe task type
    *
    * @param       i_task_type               cpoe task type id
    *
    * @return      number                    cds task type id  
    * 
    * @author                                Carlos Loureiro
    * @since                                 21-NOV-2011
    ********************************************************************************************/
    FUNCTION get_cds_task_type(i_task_type IN cpoe_task_type.id_task_type%TYPE) RETURN cpoe_task_type.id_task_type_cds%TYPE;

    /********************************************************************************************
    * set intake and output (hidric) references in cpoe_task_type table (to be executed only by DEFAULT)
    *
    * @author                                Carlos Loureiro
    * @since                                 12-JUN-2012
    ********************************************************************************************/
    PROCEDURE set_cpoe_hidric_references;

    /********************************************************************************************
    * get cpoe start date timestamp for a given task type/episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_task_type               cpoe task type id
    * @param       i_episode                 episode id 
    * @param       o_start_date              cpoe start date timestamp
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                CRISTINA.OLIVEIRA
    * @since                                 20-05-2016
    ********************************************************************************************/
    FUNCTION get_cpoe_start_date_by_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_episode    IN cpoe_process_task.id_episode%TYPE,
        o_start_date OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if the next prescription should be available ot not
    *
    * @param   i_lang        preferred language id for this professional
    * @param   i_prof        professional id structure
    * @param   i_episode     episode id  
    *
    * @return  varchar2      availability of next prescription
    *
    * @value   return        {*} 'Y' next prescription actions should be available
    *                        {*} 'N' next prescription actions shouldn't be available
    *    
    * @author                Carlos Loureiro
    * @since                 26-JUL-2012
    ********************************************************************************************/
    FUNCTION check_next_presc_availability
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*FUNCTION get_next_cpoe_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_start   IN cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_start   OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_dt_refresh OUT cpoe_process.dt_cpoe_proc_auto_refresh%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;*/

    FUNCTION delete_cpoe_process
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION task_out_of_cpoe_process
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION activate_drafts_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_types IN table_number,
        o_msg        OUT sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION exclude_task_status
    (
        i_task_type  IN cpoe_task_type.id_task_type%TYPE,
        i_flg_status IN VARCHAR2
        
    ) RETURN BOOLEAN;

    FUNCTION show_popup_epi_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_show_popup OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_create_cpoe_process
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cpoe_process IN cpoe_process.id_cpoe_process%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_tbl_task_types  IN table_number,
        i_tbl_task_ids    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job;

    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_tbl_print_list_jobs    IN table_number
    ) RETURN table_number;

    /********************************************************************************************
    ********************************************************************************************/
    PROCEDURE get_next_presc_process
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_cpoe_process OUT cpoe_process.id_cpoe_process%TYPE,
        o_dt_start     OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end       OUT cpoe_process.dt_cpoe_proc_end%TYPE
    );

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_next_cpoe_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_start OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end   OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_history
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_flg_status_final
    (
        i_id_task_type cpoe_task_type.id_task_type%TYPE,
        i_flg_status   cpoe_task_type_status_filter.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_process_end_date_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION group_close_open
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN cpoe_task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_tasks_relation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_tasks_relation.id_task_type%TYPE,
        i_task_request IN cpoe_tasks_relation.id_task_orig%TYPE,
        i_flg_filter   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_tasks_relation_tooltip
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN cpoe_tasks_relation.id_task_type%TYPE,
        i_task_request IN cpoe_tasks_relation.id_task_orig%TYPE,
        i_flg_filter   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_process_status_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION sync_active_to_next
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_type     IN cpoe_task_type.id_task_type%TYPE,
        i_request       IN cpoe_process_task.id_task_request%TYPE,
        i_flg_copy_next IN VARCHAR2 DEFAULT 'N',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_into_rel_tasks
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_next_presc_can_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_special_create_popup
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN NUMBER,
        i_task_type IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_mode      OUT VARCHAR2,
        o_title     OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_btn1      OUT VARCHAR2,
        o_btn2      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_special_create_popup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN NUMBER,
        o_flg_show OUT VARCHAR2,
        o_mode     OUT VARCHAR2,
        o_title    OUT VARCHAR2,
        o_msg      OUT VARCHAR2,
        o_btn1     OUT VARCHAR2,
        o_btn2     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_special_create_popup
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_option  IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cpoe_planning_period
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_cpoe_expire_time
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    /*
    FUNCTION request_task_to_next_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        o_new_task_request OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;*/

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- all task type IDs
    g_task_type_diet               CONSTANT cpoe_task_type.id_task_type%TYPE := 1; -- diet (group)   
    g_task_type_local_drug         CONSTANT cpoe_task_type.id_task_type%TYPE := 10; -- local drug (group)
    g_task_type_local_drug_w_tp    CONSTANT cpoe_task_type.id_task_type%TYPE := 11; -- local drug with therapeutic protocol    
    g_task_type_local_drug_wo_tp   CONSTANT cpoe_task_type.id_task_type%TYPE := 12; -- local drug without therapeutic protocol
    g_task_type_ext_drug           CONSTANT cpoe_task_type.id_task_type%TYPE := 16; -- outside medication
    g_task_type_iv_solution        CONSTANT cpoe_task_type.id_task_type%TYPE := 18; -- iv solutions
    g_task_type_hidric             CONSTANT cpoe_task_type.id_task_type%TYPE := 22; -- hidrics (group)
    g_task_type_hidric_in_out      CONSTANT cpoe_task_type.id_task_type%TYPE := 23; -- hidrics (intake and output)
    g_task_type_hidric_out         CONSTANT cpoe_task_type.id_task_type%TYPE := 24; -- hidrics (output)
    g_task_type_hidric_drain       CONSTANT cpoe_task_type.id_task_type%TYPE := 25; -- hidrics (drainage)
    g_task_type_positioning        CONSTANT cpoe_task_type.id_task_type%TYPE := 26; -- inpatient positioning    
    g_task_type_nursing            CONSTANT cpoe_task_type.id_task_type%TYPE := 27; -- nursing activities
    g_task_type_procedure          CONSTANT cpoe_task_type.id_task_type%TYPE := 31; -- procedure
    g_task_type_analysis           CONSTANT cpoe_task_type.id_task_type%TYPE := 33; -- analysis
    g_task_type_image_exam         CONSTANT cpoe_task_type.id_task_type%TYPE := 34; -- image exam
    g_task_type_other_exam         CONSTANT cpoe_task_type.id_task_type%TYPE := 35; -- other exam
    g_task_type_diet_inst          CONSTANT cpoe_task_type.id_task_type%TYPE := 36; -- institutionalized diet 
    g_task_type_diet_spec          CONSTANT cpoe_task_type.id_task_type%TYPE := 37; -- specific diet
    g_task_type_diet_predefined    CONSTANT cpoe_task_type.id_task_type%TYPE := 38; -- predefined diet
    g_task_type_monitorization     CONSTANT cpoe_task_type.id_task_type%TYPE := 40; -- monitorization
    g_task_type_hidric_in          CONSTANT cpoe_task_type.id_task_type%TYPE := 41; -- hidrics (intake)
    g_task_type_hidric_out_group   CONSTANT cpoe_task_type.id_task_type%TYPE := 42; -- hidrics (output group)
    g_task_type_hidric_out_all     CONSTANT cpoe_task_type.id_task_type%TYPE := 43; -- hidrics (output all)
    g_task_type_medication         CONSTANT cpoe_task_type.id_task_type%TYPE := 44; -- new medication    
    g_task_type_hidric_irrigations CONSTANT cpoe_task_type.id_task_type%TYPE := 45; -- hidrics (irrigations) 
    g_task_type_com_order          CONSTANT cpoe_task_type.id_task_type%TYPE := 46; -- communication order
    g_task_type_bp                 CONSTANT cpoe_task_type.id_task_type%TYPE := 49; -- blood products order
    g_task_type_medical_orders     CONSTANT cpoe_task_type.id_task_type%TYPE := 51; -- medical orders

    -- access types
    g_access_type_frequent CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_access_type_search   CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_access_type_both     CONSTANT VARCHAR2(1 CHAR) := 'B';

    -- cpoe process/complete prescription flag status
    g_flg_status_a       CONSTANT VARCHAR2(1 CHAR) := 'A'; -- active
    g_flg_status_i       CONSTANT VARCHAR2(1 CHAR) := 'I'; -- interrupted
    g_flg_status_n       CONSTANT VARCHAR2(1 CHAR) := 'N'; -- next
    g_flg_status_e       CONSTANT VARCHAR2(1 CHAR) := 'E'; -- expired
    g_flg_status_no_cpoe CONSTANT VARCHAR2(1 CHAR) := 'N'; -- no cpoe process created so far

    -- cpoe draft prescription refresh flag status
    g_flg_rfs_status_no_refresh  CONSTANT VARCHAR2(1 CHAR) := 'N'; -- do not refresh draft prescription
    g_flg_rfs_status_refresh     CONSTANT VARCHAR2(1 CHAR) := 'Y'; -- refresh draft prescription
    g_flg_rfs_status_refreshed   CONSTANT VARCHAR2(1 CHAR) := 'R'; -- refreshed draft prescription
    g_flg_rfs_status_interrupted CONSTANT VARCHAR2(1 CHAR) := 'I'; -- draft prescription not refreshed (interrupted)

    -- cpoe task action availability
    g_flg_active   CONSTANT VARCHAR2(1 CHAR) := 'A'; -- active
    g_flg_inactive CONSTANT VARCHAR2(1 CHAR) := 'I'; -- inactive

    -- cpoe action subjects
    g_cpoe_task_actions  CONSTANT action.subject%TYPE := 'CPOE_TASK_ACTIONS';
    g_cpoe_draft_actions CONSTANT action.subject%TYPE := 'CPOE_DRAFT_ACTIONS';
    g_cpoe_presc_actions CONSTANT action.subject%TYPE := 'CPOE_PRESCRIPTION_ACTIONS';

    -- cpoe actions IDs
    g_cpoe_task_request_action     CONSTANT cpoe_task_permission.id_action%TYPE := 213809;
    g_cpoe_task_view_action        CONSTANT cpoe_task_permission.id_action%TYPE := 213808;
    g_cpoe_task_copy2draft_action  CONSTANT cpoe_task_permission.id_action%TYPE := 213810;
    g_cpoe_task_del_draft_action   CONSTANT cpoe_task_permission.id_action%TYPE := 213811;
    g_cpoe_task_activ_draft_action CONSTANT cpoe_task_permission.id_action%TYPE := 213888;
    g_cpoe_task_edit_draft_action  CONSTANT cpoe_task_permission.id_action%TYPE := 213889;
    g_cpoe_task_a_draft_new_action CONSTANT cpoe_task_permission.id_action%TYPE := 221310;
    g_cpoe_task_a_draft_cur_action CONSTANT cpoe_task_permission.id_action%TYPE := 221311;
    g_cpoe_task_a_draft_newpresc   CONSTANT cpoe_task_permission.id_action%TYPE := 221312;
    g_cpoe_presc_refresh_action    CONSTANT action.id_action%TYPE := 214016;
    g_cpoe_presc_create_action     CONSTANT action.id_action%TYPE := 221315;
    g_cpoe_task_med_resume_action  CONSTANT action.id_action%TYPE := 700008;
    g_cpoe_task_copy_next_presc    CONSTANT action.id_action%TYPE := 235534309;

    -- cpoe filter tags
    g_filter_active    CONSTANT VARCHAR2(1 CHAR) := 'A'; -- active
    g_filter_inactive  CONSTANT VARCHAR2(1 CHAR) := 'I'; -- inactive
    g_filter_next      CONSTANT VARCHAR2(1 CHAR) := 'N'; -- next
    g_filter_all       CONSTANT VARCHAR2(1 CHAR) := '*'; -- all
    g_filter_current   CONSTANT VARCHAR2(1 CHAR) := 'C'; -- current
    g_filter_draft     CONSTANT VARCHAR2(1 CHAR) := 'D'; -- draft
    g_filter_cancelled CONSTANT VARCHAR2(1 CHAR) := 'X'; -- cancelled
    g_filter_history   CONSTANT VARCHAR2(1 CHAR) := 'H'; -- history
    g_filter_to_ack    CONSTANT VARCHAR2(1 CHAR) := 'K'; -- to acknowledge

    -- availability of task types in filter options
    g_task_filter_current CONSTANT VARCHAR2(1 CHAR) := 'C'; -- active filter    
    g_task_filter_active  CONSTANT VARCHAR2(1 CHAR) := 'A'; -- active filter
    g_task_filter_next    CONSTANT VARCHAR2(1 CHAR) := 'N'; -- next filter
    g_task_filter_draft   CONSTANT VARCHAR2(1 CHAR) := 'D'; -- active and draft filters
    g_task_filter_all     CONSTANT VARCHAR2(2 CHAR) := '*'; -- all task filters

    -- cpoe filter tab description message codes
    g_tab_desc_active      CONSTANT sys_message.code_message%TYPE := 'CPOE_T002'; -- active
    g_tab_desc_inactive    CONSTANT sys_message.code_message%TYPE := 'CPOE_T003'; -- inactive
    g_tab_desc_draft       CONSTANT sys_message.code_message%TYPE := 'CPOE_T004'; -- draft
    g_tab_desc_next        CONSTANT sys_message.code_message%TYPE := 'CPOE_T027'; -- next
    g_tab_desc_draft_presc CONSTANT sys_message.code_message%TYPE := 'CPOE_T023'; -- draft prescription   
    g_tab_desc_current     CONSTANT sys_message.code_message%TYPE := 'CPOE_T014'; -- current or active prescription
    g_tab_desc_to_ack      CONSTANT sys_message.code_message%TYPE := 'CPOE_T024'; -- to acknowledge
    g_tab_desc_all         CONSTANT sys_message.code_message%TYPE := 'CPOE_T005'; -- expired

    -- other cpoe message codes
    g_inactive_tasks_warning CONSTANT sys_message.code_message%TYPE := 'CPOE_M018'; -- inactive task period warning    

    -- task creation flag warnings
    g_flg_warning_none          CONSTANT VARCHAR2(1 CHAR) := NULL; -- no warnings
    g_flg_warning_no_cpoe       CONSTANT VARCHAR2(1 CHAR) := 'C'; -- no active cpoe (confirm creation of new one)
    g_flg_warning_out_of_bounds CONSTANT VARCHAR2(1 CHAR) := 'O'; -- start/end task timestamps are not in cpoe's validity period
    g_flg_warning_new_cpoe      CONSTANT VARCHAR2(1 CHAR) := 'P'; -- create new prescription
    g_flg_warning_cpoe_blocked  CONSTANT VARCHAR2(1 CHAR) := 'B'; -- block the creation of tasks in current/new prescription
    g_flg_warning_new_next_cpoe CONSTANT VARCHAR2(1 CHAR) := 'X'; -- create new next prescription    

    g_flg_profile_template_student CONSTANT VARCHAR2(1 CHAR) := 'T'; -- profile template Student   

    -- general variables
    g_all_institution      CONSTANT institution.id_institution%TYPE := 0;
    g_all_software         CONSTANT software.id_software%TYPE := 0;
    g_all_profile_template CONSTANT profile_template.id_profile_template%TYPE := 0;
    g_default_expire_time  CONSTANT sys_config.value%TYPE := '60';

    -- domains
    g_domain_cpoe_flg_status CONSTANT sys_domain.code_domain%TYPE := 'CPOE_PROCESS.FLG_STATUS';

    -- alerts
    g_sys_alert_expired_cpoe CONSTANT sys_alert.id_sys_alert%TYPE := 83;

    -- cpoe specific add button task types
    g_refresh_presc_id   CONSTANT NUMBER := 0;
    g_refresh_presc_rank CONSTANT NUMBER := -1;

    --generic task type 
    g_task_type_cancelled CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_task_type_read      CONSTANT VARCHAR2(1 CHAR) := 'L';

    -- configurations
    g_cfg_cpoe_mode               CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_MODE';
    g_cfg_cpoe_mode_simple        CONSTANT sys_config.value%TYPE := 'S';
    g_cfg_cpoe_mode_advanced      CONSTANT sys_config.value%TYPE := 'A';
    g_cfg_cpoe_wrn_exp_time       CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_EXPIRE_WARNING_TIME';
    g_cfg_cpoe_wrn_exp_prmpt      CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_EXPIRE_WARNING_PROMPT';
    g_cfg_cpoe_wrn_exp_prmpt_n    CONSTANT sys_config.value%TYPE := 'N'; -- no warningsg_cfg_cpoe_wrn_exp_time
    g_cfg_cpoe_wrn_exp_prmpt_a    CONSTANT sys_config.value%TYPE := 'A'; -- warn after expired
    g_cfg_cpoe_wrn_exp_prmpt_b    CONSTANT sys_config.value%TYPE := 'B'; -- warn before/after expire
    g_cfg_cpoe_closed_task_filter CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_CLOSED_TASK_FILTER_INTERVAL'; -- closed task filter interval in days
    g_cfg_cpoe_presc_action_cat   CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_PRESC_ACTION_CATEGORY'; -- categories allowed to execute prescription actions
    g_cfg_cpoe_del_auto_refresh   CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_DEL_DRAFT_IN_AUTO_REFRESH_PRESC'; -- draft tasks should be deleted when draft refresh action is issued by the system
    g_cfg_cpoe_del_manual_refresh CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_DEL_DRAFT_IN_MANUAL_REFRESH_PRESC'; -- draft tasks should be deleted when draft refresh action is issued by the user
    g_cfg_cpoe_del_presc_activ    CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_DEL_DRAFT_IN_PRESC_ACTIVATION'; -- draft tasks should be deleted when draft activation action is issued by the user
    g_cfg_cpoe_auto_refresh_presc CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_AUTO_REFRESH_PRESC'; -- draft prescriptions should be refreshed automatically by the system
    g_cfg_cpoe_copy_active_presc  CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_NEW_PRESC_COPY_ACTIVE'; -- new process should bring active tasks from previous process or prescription
    g_cfg_cpoe_confirm_creation   CONSTANT sys_config.id_sys_config%TYPE := 'CPOE_NEW_PRESC_CONFIRMATION'; -- creation of a new CPOE process need the user confirmation    

END pk_cpoe;
/
