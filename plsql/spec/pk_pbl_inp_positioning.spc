/*-- Last Change Revision: $Rev: 2028856 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_pbl_inp_positioning IS

    -- Author  : GUSTAVO.SERRANO
    -- Created : 13-11-2009 12:23:20
    -- Purpose : API functions for external modules

    /********************************************************************************************
    * get all tasks information to show in CPOE grid
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    * @param       i_episode                 episode id
    * @param       i_task_request            array of task requests (if null, return all tasks as usual)
    * @param       i_filter_tstz             Date to filter only the records with "end dates" > i_filter_tstz
    * @param       i_filter_status           Array with task status to consider along with i_filter_tstz
    * @param       i_flg_report              Required in all get_task_list APIs
    * @param       o_grid                    cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    ********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_grid          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of requests that identifies the tasks
    * @param       o_task_status          cursor with all requested task status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false   
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.1.x
    * @since                          02-Sep-2010 
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Return positioning description including all positioning sequence
    *
    * @param      i_lang           language ID
    * @param      i_prof           professional information
    * @param      i_episode        episode ID
    *    
    * @author     Luís Maia
    * @version    2.6.0.3
    * @since      2010/Jun/08
    *
    * @dependencies    This function was developed to Content team
    ***********************************************************************************************************/
    FUNCTION get_all_posit_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * create draft task 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * 
    * @param       param1                    param1
    * @param       param2                    param2
    * @param       param3                    param3
    * ...          ...                       ...
    * @param       paramN                    paramN
    * 
    * @param       o_draft                   list of created drafts
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_posit         IN table_number,
        i_rot_interv    IN rotation_interval.interval%TYPE,
        i_id_rot_interv IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage   IN epis_positioning.flg_massage%TYPE,
        i_notes         IN epis_positioning.notes%TYPE,
        i_pos_type      IN positioning_type.id_positioning_type%TYPE,
        o_draft         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel draft task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   list of draft ids
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * cancel all draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false    
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.1.x
    * @since                          02-Sep-2010 
    ********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators
    * @param       o_msg_template            array of message/pop-up templates
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_body                array of message bodies
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_msg_template            {*} ' WARNING_READ' Warning Read
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
    * @return                                True on success, false otherwise
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN table_number,
        o_flg_conflict OUT NOCOPY table_varchar,
        o_msg_template OUT NOCOPY table_varchar,
        o_msg_title    OUT NOCOPY table_varchar,
        o_msg_body     OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task parameters needed to fill task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that returns the required values, 
    *       according to current task workflow edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       ...                       specific to each target area
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_pos IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set task parameters changed in task edit screens (critical for draft editing)
    *
    * NOTE: this function can be replaced by several functions that update the required values, 
    *       according to current task workflow edit screens
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       ...                       specific to each target area
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION set_task_parameters
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_posit            IN table_number,
        i_rot_interv       IN rotation_interval.interval%TYPE,
        i_id_rot_interv    IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage      IN epis_positioning.flg_massage%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_pos_type         IN positioning_type.id_positioning_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_draft                   array of selected drafts 
    * @param       i_flg_commit              transaction control
    * @param       o_created_tasks        array of created taksk requests    
    * @param       o_error                   error message
    *
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction
    *                                        {*} 'N' transaction control is done outside
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get available actions for a requested task
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_request            task request id (also used for drafts)
    * @param       o_actions_list            list of available actions for the task request
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_actions_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * copy task to draft (from an existing active/inactive task)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id (current episode)
    * @param       i_task_request            task request id (used for active/inactive tasks)
    * @param       o_draft                   draft id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN cpoe_process_task.id_task_request%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT cpoe_process_task.id_task_request%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    -- pk_cpoe functions

    /********************************************************************************************
    * synchronize requested task with cpoe processes 
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_type               cpoe task type id
    * @param       i_task_request            task request id (also used for drafts)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false    
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_type    IN cpoe_task_type.id_task_type%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * set new episode when executing match functionality                      *
    *                                                                         *
    * @param       i_lang             preferred language id for this          *
    *                                 professional                            *
    * @param       i_prof             professional id structure               *
    * @param       i_current_episode  episode id                              *
    * @param       i_new_episode      array of selected drafts                *
    * @param       o_error            error message                           *
    *                                                                         *
    * @return      boolean            true on success, otherwise false        *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION set_new_match_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_ONGOING_TASKS_POSIT                Get all tasks available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_posit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /********************************************************************************************
    * SUSPEND_TASK_POSIT                     Function that should suspend (cancel or interrupt) ongoing task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       i_flg_reason              Reason for the WF suspension: 'D' (Death)
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION suspend_task_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_task    IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_reason IN VARCHAR2,
        o_msg_error  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * REACTIVATE_TASK_POSIT                  Function that should reactivate cancelled or interrupted task
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia
    * @version                               2.6.0.3
    * @since                                 2010/May/23
    ********************************************************************************************/
    FUNCTION reactivate_task_posit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN epis_positioning.id_epis_positioning%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status
    *                        
    * @author                        António Neto
    * @version                       v2.5.1.3
    * @since                         03-Feb-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    );

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    * 
    * @author                                António Neto
    * @version                               2.5.1.8
    * @since                                 13-Sep-2011
    */
    FUNCTION expire_task
    
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the positionings list for reports with timeframe and scope
    *
    * @param   I_LANG                      Language associated to the professional executing the request
    * @param   I_PROF                      Professional Identification
    * @param   I_SCOPE                     Scope ID
    * @param   I_FLG_SCOPE                 Scope type
    * @param   I_START_DATE                Start date for temporal filtering
    * @param   I_END_DATE                  End date for temporal filtering
    * @param   I_CANCELLED                 Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param   I_CRIT_TYPE                 Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param   I_FLG_REPORT                Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param   O_POS                       Positioning list
    * @param   O_POS_EXEC                  Executions for Positioning list
    * @param   O_ERROR                     Error message
    *
    * @value   I_SCOPE                     {*} 'E' Episode ID {*} 'V' Visit ID {*} 'P' Patient ID
    * @value   I_FLG_SCOPE                 {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value   I_CANCELLED                 {*} 'Y' Yes {*} 'N' No
    * @value   I_CRIT_TYPE                 {*} 'A' All {*} 'E' Executions {*} 'R' requests
    * @value   I_FLG_REPORT                {*} 'Y' Yes {*} 'N' No
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.8.1
    * @since                               29-Sep-2011
    **********************************************************************************************/
    FUNCTION get_positioning_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_flg_scope  IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_cancelled  IN VARCHAR2,
        i_crit_type  IN VARCHAR2,
        i_flg_report IN VARCHAR2,
        o_pos        OUT NOCOPY pk_types.cursor_type,
        o_pos_exec   OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    --
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    --    
    g_error        VARCHAR2(2000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    --    
    g_epis_posit_r CONSTANT epis_positioning.flg_status%TYPE := 'R';
    g_epis_posit_e CONSTANT epis_positioning.flg_status%TYPE := 'E';
    g_epis_posit_d CONSTANT epis_positioning.flg_status%TYPE := 'D';
    g_epis_posit_c CONSTANT epis_positioning.flg_status%TYPE := 'C';
    g_epis_posit_i CONSTANT epis_positioning.flg_status%TYPE := 'I';
    g_epis_posit_f CONSTANT epis_positioning.flg_status%TYPE := 'F';
    g_epis_posit_l CONSTANT epis_positioning.flg_status%TYPE := 'L';
    g_epis_posit_o CONSTANT epis_positioning.flg_status%TYPE := 'O';

END pk_pbl_inp_positioning;
/
