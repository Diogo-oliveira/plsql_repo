/*-- Last Change Revision: $Rev: 2050781 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2022-11-23 11:11:28 +0000 (qua, 23 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cpoe_ux IS

    -- Purpose : Computerized Prescription Order Entry (CPOE) UX API database package

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    g_tstz_presc_limit_threshold CONSTANT NUMBER := 1 / 86400; -- to remove 1 second in prescription end limit

    /********************************************************************************************
    * get table_timestamp_tstz array from table_varchar arrays with dates
    *
    * @param    i_lang                     preferred language id for this professional
    * @param    i_prof                     professional id structure
    * @param    i_tbl                      varchar table
    *
    * @return   table_timestamp_tstz       timestamp table collection
    *
    * @author   Carlos Loureiro
    * @since    18-NOV-2011
    ********************************************************************************************/
    FUNCTION get_table_timestamp_tstz
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_tbl  IN table_varchar
    ) RETURN table_timestamp_tstz IS
        l_ret table_timestamp_tstz := table_timestamp_tstz();
    BEGIN
        FOR i IN 1 .. i_tbl.count
        LOOP
            l_ret.extend;
            l_ret(l_ret.count) := pk_date_utils.get_string_tstz(i_lang, i_prof, i_tbl(i), NULL);
        END LOOP;
        RETURN l_ret;
    END get_table_timestamp_tstz;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_task_type_list function
        IF NOT pk_cpoe.get_task_type_list(i_lang                    => i_lang,
                                          i_prof                    => i_prof,
                                          i_patient                 => i_patient,
                                          i_episode                 => i_episode,
                                          i_task_types              => i_task_types,
                                          i_filter                  => i_filter,
                                          o_task_type_list_frequent => o_task_type_list_frequent,
                                          o_task_type_list_search   => o_task_type_list_search,
                                          o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_task_type_list function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_task_type_list_frequent);
            pk_types.open_my_cursor(o_task_type_list_search);
            RETURN FALSE;
    END get_task_type_list;

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
    FUNCTION request_task_to_next_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN table_number,
        i_task_request     IN table_number,
        o_new_task_request OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        -- call pk_cpoe.get_cpoe_grid function
        IF NOT pk_cpoe.request_task_to_next_presc(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_episode          => i_episode,
                                                  i_task_type        => i_task_type,
                                                  i_task_request     => i_task_request,
                                                  o_new_task_request => o_new_task_request,
                                                  o_error            => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.request_task_to_next_presc function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    END request_task_to_next_presc;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_grid function
        IF NOT pk_cpoe.get_cpoe_grid(i_lang         => i_lang,
                                     i_prof         => i_prof,
                                     i_patient      => i_patient,
                                     i_episode      => i_episode,
                                     i_filter       => i_filter,
                                     o_cpoe_grid    => o_cpoe_grid,
                                     o_cpoe_tabs    => o_cpoe_tabs,
                                     o_cpoe_info    => o_cpoe_info,
                                     o_task_types   => o_task_types,
                                     o_can_req_next => o_can_req_next,
                                     o_error        => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_grid function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_grid);
            pk_types.open_my_cursor(o_cpoe_tabs);
            pk_types.open_my_cursor(o_cpoe_info);
            RETURN FALSE;
    END get_cpoe_grid;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_grid function
        IF NOT pk_cpoe.get_cpoe_info_grid(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_patient   => i_patient,
                                          i_episode   => i_episode,
                                          i_filter    => i_filter,
                                          o_cpoe_tabs => o_cpoe_tabs,
                                          o_cpoe_info => o_cpoe_info,
                                          o_error     => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_info_grid function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_INFO_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_tabs);
            pk_types.open_my_cursor(o_cpoe_info);
            RETURN FALSE;
    END get_cpoe_info_grid;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_mode function
        IF NOT pk_cpoe.get_cpoe_mode(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     o_flg_mode => o_flg_mode,
                                     i_episode  => i_episode,
                                     o_error    => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_mode function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_MODE',
                                              o_error);
            RETURN FALSE;
    END get_cpoe_mode;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_actions function
        IF NOT pk_cpoe.get_actions(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_episode       => i_episode,
                                   i_filter        => i_filter,
                                   i_task_type     => i_task_type,
                                   i_task_request  => i_task_request,
                                   i_task_conflict => i_task_conflict,
                                   i_task_draft    => i_task_draft,
                                   o_actions       => o_actions,
                                   o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_actions function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

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
    * @value       i_flg_conflict_answer     {*} 'Y'  draft must be activated even if it has conflicts
    *                                        {*} 'N'  draft shouldn't be activated
    *                                        {*} NULL there are no conflicts
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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_noreqnext EXCEPTION;
    
        l_ret BOOLEAN;
    
        l_flg_cpoe_mode VARCHAR2(1 CHAR);
        l_count         NUMBER(24);
    
        l_final_day_date cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_cpoe_process  cpoe_process.id_cpoe_process%TYPE;
        l_ts_cpoe_start cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end   cpoe_process.dt_cpoe_proc_end%TYPE;
    
        l_current_timestamp TIMESTAMP WITH TIME ZONE;
    
        l_id_professional professional.id_professional%TYPE;
        l_flg_cpoe_status cpoe_process.flg_status%TYPE;
        l_planning_period cpoe_period.planning_period%TYPE;
        l_expire_time     cpoe_period.expire_time%TYPE;
    
        l_hour   NUMBER;
        l_minute NUMBER;
    
        l_can_presc VARCHAR2(1 CHAR);
    
    BEGIN
        -- call pk_cpoe.set_action function
        --raise_application_error(-20001,'teste');
        pk_alert_exceptions.reset_error_state();
        IF NOT pk_cpoe.set_action(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_episode             => i_episode,
                                  i_action              => i_action,
                                  i_task_type           => i_task_type,
                                  i_task_request        => i_task_request,
                                  i_flg_conflict_answer => i_flg_conflict_answer,
                                  i_cdr_call            => i_cdr_call,
                                  i_flg_task_to_copy    => i_flg_task_to_copy,
                                  o_action              => o_action,
                                  o_task_type           => o_task_type,
                                  o_task_request        => o_task_request,
                                  o_new_task_request    => o_new_task_request,
                                  o_flg_conflict        => o_flg_conflict,
                                  o_msg_template        => o_msg_template,
                                  o_msg_title           => o_msg_title,
                                  o_msg_body            => o_msg_body,
                                  o_flg_validated       => o_flg_validated,
                                  o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.set_action function';
            IF o_error.err_action = 'NOREQNEXT'
            THEN
                RAISE l_noreqnext;
            ELSE
                RAISE l_exception;
            END IF;
        
        END IF;
        -- commit perfomed CPOE action
        COMMIT;
        RETURN TRUE;
    EXCEPTION
    
        WHEN l_noreqnext THEN
        
            l_current_timestamp := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, SYSDATE);
            l_planning_period   := pk_cpoe.get_cpoe_planning_period(i_lang, i_prof, i_episode);
            l_expire_time       := pk_cpoe.get_cpoe_expire_time(i_lang, i_prof, i_episode);
        
            l_final_day_date := pk_date_utils.get_string_tstz(i_lang,
                                                              i_prof,
                                                              to_char(l_current_timestamp, 'YYYYMMDD') ||
                                                              substr(l_expire_time, 1, 2) || substr(l_expire_time, 4, 2) || '00',
                                                              NULL);
        
            l_hour              := extract(hour FROM(l_final_day_date - l_current_timestamp));
            l_minute            := extract(minute FROM(l_final_day_date - l_current_timestamp));
            o_error.err_action  := o_error.ora_sqlerrm;
            o_error.ora_sqlerrm := NULL;
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_action',
                                              o_error);
            RETURN FALSE;
    END set_action;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_ts_cpoe_start     cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end       cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_refresh   cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_proc_next_start   cpoe_process.dt_cpoe_proc_start%TYPE;
        l_proc_next_end     cpoe_process.dt_cpoe_proc_end%TYPE;
        l_proc_next_refresh cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
    BEGIN
        -- call pk_cpoe.check_tasks_creation function
        IF NOT pk_cpoe.check_tasks_creation(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_episode           => i_episode,
                                            i_task_type         => i_task_type,
                                            i_dt_start          => i_dt_start,
                                            i_dt_end            => i_dt_end,
                                            i_task_id           => i_task_id,
                                            i_tab_type          => i_tab_type,
                                            o_task_list         => o_task_list,
                                            o_flg_warning_type  => o_flg_warning_type,
                                            o_msg_title         => o_msg_title,
                                            o_msg_body          => o_msg_body,
                                            o_proc_start        => o_proc_start,
                                            o_proc_end          => o_proc_end,
                                            o_proc_refresh      => o_proc_refresh,
                                            o_proc_next_start   => o_proc_next_start,
                                            o_proc_next_end     => o_proc_next_end,
                                            o_proc_next_refresh => o_proc_next_refresh,
                                            o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_tasks_creation function';
            RAISE l_exception;
        END IF;
        -- the valid cpoe period (actual or new)
        /*o_proc_start   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_start, i_prof);
        o_proc_end     := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_end, i_prof);
        o_proc_refresh := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_refresh, i_prof);
        o_proc_next_start   := pk_date_utils.date_send_tsz(i_lang, l_proc_next_start, i_prof);
        o_proc_next_end     := pk_date_utils.date_send_tsz(i_lang, l_proc_next_end, i_prof);
        o_proc_next_refresh := pk_date_utils.date_send_tsz(i_lang, l_proc_next_refresh, i_prof);*/
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_TASKS_CREATION',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END check_tasks_creation;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_cpoe_process cpoe_process.id_cpoe_process%TYPE;
    BEGIN
        -- call pk_cpoe.check_drafts_activation function
        --raise_application_error(-20001,'Teste');
        IF NOT pk_cpoe.check_drafts_activation(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_episode           => i_episode,
                                               i_task_type         => i_task_type,
                                               i_dt_start          => i_dt_start,
                                               i_dt_end            => i_dt_end,
                                               i_draft_request     => i_draft_request,
                                               o_task_list         => o_task_list,
                                               o_flg_warning_type  => o_flg_warning_type,
                                               o_msg_title         => o_msg_title,
                                               o_msg_body          => o_msg_body,
                                               o_proc_start        => o_proc_start,
                                               o_proc_end          => o_proc_end,
                                               o_proc_refresh      => o_proc_refresh,
                                               o_proc_next_start   => o_proc_next_start,
                                               o_proc_next_end     => o_proc_next_end,
                                               o_proc_next_refresh => o_proc_next_refresh,
                                               o_cpoe_process      => l_cpoe_process,
                                               o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_drafts_activation function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DRAFTS_ACTIVATION',
                                              o_error);
            pk_types.open_my_cursor(o_task_list);
            RETURN FALSE;
    END check_drafts_activation;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.check_cpoe_creation function
        IF NOT pk_cpoe.check_cpoe_creation(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => i_episode,
                                           o_dt_proc_start => o_dt_proc_start,
                                           o_dt_proc_end   => o_dt_proc_end,
                                           o_msg_title     => o_msg_title,
                                           o_msg_body      => o_msg_body,
                                           o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_cpoe_creation function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CPOE_CREATION',
                                              o_error);
            RETURN FALSE;
    END check_cpoe_creation;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        -- call pk_cpoe.refresh_draft_prescription function
        IF NOT pk_cpoe.refresh_draft_prescription(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_episode      => i_episode,
                                                  i_cpoe_process => i_cpoe_process,
                                                  /*i_auto_mode          => pk_alert_constant.g_no,*/
                                                  o_draft_task_type    => o_draft_task_type,
                                                  o_draft_task_request => o_draft_task_request,
                                                  o_error              => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.refresh_draft_prescription function';
            RAISE l_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REFRESH_DRAFT_PRESCRIPTION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END refresh_draft_prescription;

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
    * @since                                 10-Sep-2010
    *
    * Added new column to CPOE_PROCESS, id_dep_clin_serv
    * @author                                Joao Reis
    * @since                                 21-Sep-2011
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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.create_cpoe function
        IF NOT pk_cpoe.create_cpoe(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_episode           => i_episode,
                                   i_proc_start        => i_proc_start,
                                   i_proc_end          => i_proc_end,
                                   i_proc_next_start   => i_proc_next_start,
                                   i_proc_next_end     => i_proc_next_end,
                                   i_proc_next_refresh => i_proc_next_refresh,
                                   i_proc_type         => i_proc_type,
                                   i_proc_refresh      => i_proc_refresh,
                                   o_cpoe_process      => o_cpoe_process,
                                   o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.create_cpoe function';
            RAISE l_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_CPOE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_cpoe;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.check_cpoe_status function
        IF NOT pk_cpoe.check_cpoe_status(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_episode      => i_episode,
                                         o_flg_warning  => o_flg_warning,
                                         o_msg_template => o_msg_template,
                                         o_msg_title    => o_msg_title,
                                         o_msg_body     => o_msg_body,
                                         o_error        => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.check_cpoe_status function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CPOE_STATUS',
                                              o_error);
            RETURN FALSE;
    END check_cpoe_status;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_history function
        IF NOT pk_cpoe.get_cpoe_history(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_patient   => i_patient,
                                        i_episode   => i_episode,
                                        o_cpoe_hist => o_cpoe_hist,
                                        o_error     => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_history function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_hist);
            RETURN FALSE;
    END get_cpoe_history;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- call pk_cpoe.get_cpoe_task_history function
        IF NOT pk_cpoe.get_cpoe_task_history(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_patient   => i_patient,
                                             i_process   => i_process,
                                             o_cpoe_task => o_cpoe_task,
                                             o_error     => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_task_history function';
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CPOE_TASK_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_task);
            RETURN FALSE;
    END get_cpoe_task_history;

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
    ) RETURN BOOLEAN IS
        l_ts_cpoe_start      cpoe_process.dt_cpoe_proc_start%TYPE;
        l_ts_cpoe_end        cpoe_process.dt_cpoe_proc_end%TYPE;
        l_ts_cpoe_next_presc cpoe_process.dt_cpoe_proc_auto_refresh%TYPE;
        l_proc_exists        BOOLEAN;
    
    BEGIN
        -- get prescription limits, based in selected filter
        pk_cpoe.get_presc_limits(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_episode        => i_episode,
                                 i_filter         => i_filter,
                                 i_from_ux        => pk_alert_constant.g_yes,
                                 i_task_type      => i_task_type,
                                 o_ts_presc_start => l_ts_cpoe_start,
                                 o_ts_presc_end   => l_ts_cpoe_end,
                                 o_ts_next_presc  => l_ts_cpoe_next_presc,
                                 o_proc_exists    => l_proc_exists);
    
        -- convert timestamps to varchar      
        o_dt_presc_start := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_start, i_prof);
        o_dt_presc_end   := pk_date_utils.date_send_tsz(i_lang, l_ts_cpoe_end - g_tstz_presc_limit_threshold, i_prof);
    
        -- if cpoe mode is not in advanced mode, then the following variables will be null:
        --  * o_dt_presc_start
        --  * o_dt_presc_end
        -- in this case, the application shouldn't apply the timestamp limits
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PRESCRIPTION_LIMITS',
                                              o_error);
            RETURN FALSE;
    END get_prescription_limits;

    FUNCTION activate_drafts_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_types IN table_number,
        o_msg        OUT sys_message.desc_message%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.activate_drafts_popup(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_task_types => i_task_types,
                                             o_msg        => o_msg,
                                             o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS_POPUP',
                                              o_error);
            RETURN FALSE;
    END activate_drafts_popup;

    FUNCTION show_popup_epi_resp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_show_popup OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.show_popup_epi_resp(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_episode    => i_episode,
                                           o_show_popup => o_show_popup,
                                           o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SHOW_POPUP_EPI_RESP',
                                              o_error);
            RETURN FALSE;
    END show_popup_epi_resp;

    FUNCTION delete_create_cpoe_process
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cpoe_process IN cpoe_process.id_cpoe_process%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.delete_create_cpoe_process(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_cpoe_process => i_id_cpoe_process,
                                                  o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_CREATE_CPOE_PROCESS',
                                              o_error);
            RETURN FALSE;
    END delete_create_cpoe_process;

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
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.add_print_list_jobs(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_patient         => i_patient,
                                           i_episode         => i_episode,
                                           i_tbl_task_types  => i_tbl_task_types,
                                           i_tbl_task_ids    => i_tbl_task_ids,
                                           i_print_arguments => i_print_arguments,
                                           o_print_list_job  => o_print_list_job,
                                           o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_PRINT_LIST_JOBS',
                                              o_error);
            RETURN FALSE;
    END add_print_list_jobs;

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
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.get_special_create_popup(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_episode   => i_episode,
                                                i_task_type => i_task_type,
                                                o_flg_show  => o_flg_show,
                                                o_mode      => o_mode,
                                                o_title     => o_title,
                                                o_msg       => o_msg,
                                                o_btn1      => o_btn1,
                                                o_btn2      => o_btn2,
                                                o_error     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END get_special_create_popup;

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
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.get_next_special_create_popup(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_episode  => i_episode,
                                                     o_flg_show => o_flg_show,
                                                     o_mode     => o_mode,
                                                     o_title    => o_title,
                                                     o_msg      => o_msg,
                                                     o_btn1     => o_btn1,
                                                     o_btn2     => o_btn2,
                                                     o_error    => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END get_next_special_create_popup;

    FUNCTION set_special_create_popup
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_option  IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_cpoe.set_special_create_popup(i_lang    => i_lang,
                                                i_prof    => i_prof,
                                                i_episode => i_episode,
                                                i_option  => i_option,
                                                o_error   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SPECIAL_CREATE_POPUP',
                                              o_error);
            RETURN FALSE;
    END set_special_create_popup;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_cpoe_ux;
/
