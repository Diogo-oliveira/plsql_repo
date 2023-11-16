/*-- Last Change Revision: $Rev: 2050782 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-11-23 11:11:41 +0000 (qua, 23 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_cpoe_ux IS

    -- Computerized Prescription Order Entry (CPOE) UX API database package

    /********************************************************************************************
    * get all task types that can be requested in CPOE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient
    * @param       i_episode                 internal id of the episode
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
        i_proc_next_start   IN VARCHAR2 DEFAULT NULL,
        i_proc_next_end     IN VARCHAR2 DEFAULT NULL,
        i_proc_next_refresh IN VARCHAR2 DEFAULT NULL,
        i_proc_type         IN VARCHAR2 DEFAULT NULL,
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

    FUNCTION get_prescription_limits
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_filter         IN VARCHAR2,
        i_task_type      IN cpoe_task_type.id_task_type%TYPE,
        o_dt_presc_start OUT VARCHAR2,
        o_dt_presc_end   OUT VARCHAR2,
        o_error          OUT t_error_out
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

    FUNCTION activate_drafts_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_types IN table_number,
        o_msg        OUT sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
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

    FUNCTION get_special_create_popup
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
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
        i_episode  IN episode.id_episode%TYPE,
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
        i_episode IN episode.id_episode%TYPE,
        i_option  IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_cpoe_ux;
/
