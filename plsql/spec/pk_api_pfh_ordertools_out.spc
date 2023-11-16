/*-- Last Change Revision: $Rev: 2028489 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:06 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_ordertools_out IS

    -- purpose: order tools database api for outgoing data

    /********************************************************************************************
    * update task dependency state for cancel action and process the affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_reason               when canceling/suspending, the id_cancel_reason can go
    *                                     to dependent tasks also
    * @param       i_reason_notes         when canceling/suspending, the cancel/suspend notes 
    *                                     field can go to dependent tasks also   
    * @param       i_transaction_id       transaction id for scheduler 3.0 transaction control
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION tde_upd_task_state_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes    IN VARCHAR2,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update task dependency state for suspend action
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_reason               when canceling/suspending, the id_cancel_reason can go
    *                                     to dependent tasks also
    * @param       i_reason_notes         when canceling/suspending, the cancel/suspend notes 
    *                                     field can go to dependent tasks also   
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION tde_upd_task_state_suspend
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes    IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update task dependency state for forced execution (for "start depending" tasks)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION tde_upd_task_state_execute
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update task dependency state for finish action and start other dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION tde_upd_task_state_finish
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if task shoud be resumed normally or should return to "waiting for dependencies" state
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency about to be resumed 
    * @param       o_flg_resume           flag that indicates if task shoud be resumed normally or not
    * @param       o_error                error structure for exception handling
    *
    * @value       o_flg_resume           {*} 'S' task should be resumed and started by target module    
    *                                     {*} 'W' task should be resumed to its waiting state  
    *                                     {*} 'N' task should be resumed to its last state
    *    
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              06-JUL-2010
    ********************************************************************************************/
    FUNCTION tde_chk_task_state_resume
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_flg_resume      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task dependencies to use in task detail screens (in string format)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency id
    *
    * @return      varchar2               dependencies string to use in task detail screens
    *
    * @author                             Carlos Loureiro
    * @since                              28-MAY-2010
    ********************************************************************************************/
    FUNCTION tde_get_task_depend_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * synchronize requested medication task with cpoe processes in task creation or draft activation
    * NOTE: CAN ONLY BE CALLED BY MEDICATION TASK TYPE
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id (also used for draft activation)
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false  
    * 
    * @author                                Carlos Loureiro
    * @since                                 20-10-2011
    ********************************************************************************************/
    FUNCTION cpoe_med_sync_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all mappings of a concept given a source and a target mapping set
    *
    * @param i_lang               preferred language id
    * @param i_source_concept     list of strings string with the pre or post-coordinated expression of the source concept
    * @param i_source_map_set     source mapping set id
    * @param i_target_map_set     target mapping set id
    * @param i_target_mcs_src     target standard id on medical classification system data model (used to get concept descriptions)
    * @param o_target_concepts    cursor with all target concepts
    * @param o_error              error structure and message
    *
    * @return                     true or false on success or error
    *
    * @author                     Sofia Mendes
    * @since                      2011/03/11
    ********************************************************************************************/
    FUNCTION tf_get_mapping_concepts
    (
        i_lang           IN language.id_language%TYPE,
        i_source_concept IN table_varchar,
        i_source_map_set IN xmap_set.id_map_set%TYPE,
        i_target_map_set IN xmap_set.id_map_set%TYPE,
        i_target_mcs_src IN mcs_source.id_mcs_source%TYPE DEFAULT NULL
    ) RETURN t_table_mapping_conc;

    /********************************************************************************************
    * Get all order sets tasks (used by ADW)
    *
    * @param i_lang              Preferred language ID
    * @param i_prof              Object (ID of professional, ID of institution, ID of software)
    * @param i_id_order_set      Order set ID
    * @param o_order_set_tasks   Cursor with all order set tasks
    * @param o_error             Error message
    *
    * @return                    BOOLEAN: False in case of error and true otherwise
    *
    * @author                    Tiago Silva
    * @version                   1.0
    * @since                     2013/11/14
    ********************************************************************************************/
    FUNCTION get_order_set_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_order_set    IN order_set_task.id_order_set%TYPE,
        o_order_set_tasks OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_pfh_ordertools_out;
/
