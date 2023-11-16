/*-- Last Change Revision: $Rev: 2029009 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:16 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_tde_ux IS

    -- Purpose : Task Dependency Engine database package for UX interface

    /********************************************************************************************
    * check if task can be canceled while checking the possible affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependencies    task dependencies array for the tasks about to change their 
    *                                     states
    * @param       o_flg_conflict         conflict flag to indicate if action affects other dependencies
    * @param       o_dependencies         cursor with all affected tasks
    * @param       o_msg_title            pop up message title for warnings
    * @param       o_msg_body             pop up message body for warnings
    * @param       o_error                error structure for exception handling
    *
    * @value       o_flg_conflict         {*} 'Y' Conflicts detected in task cancelation and caller    
    *                                         module needs to confirm the action
    *                                     {*} 'C' Conflicts detected in task cancelation, but caller  
    *                                         module cannot continue tasks update
    *                                     {*} 'N' No conflicts detected: caller function can proceed 
    *                                         with tasks update
    *    
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION check_task_state_cancel
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_dependencies IN table_number,
        o_flg_conflict      OUT VARCHAR2,
        o_dependencies      OUT pk_types.cursor_type,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if task can be suspended while checking the possible affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependencies    task dependencies array for the tasks about to change their 
    *                                     states
    * @param       o_flg_conflict         conflict flag to indicate if action affects other dependencies
    * @param       o_dependencies         cursor with all affected tasks
    * @param       o_msg_title            pop up message title for warnings
    * @param       o_msg_body             pop up message body for warnings
    * @param       o_error                error structure for exception handling
    *
    * @value       o_flg_conflict         {*} 'S' Conflicts detected in suspend action, and caller    
    *                                         module needs to confirm the action
    *                                     {*} 'N' No conflicts detected: caller function can proceed 
    *                                         with tasks update
    *    
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION check_task_state_suspend
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_dependencies IN table_number,
        o_flg_conflict      OUT VARCHAR2,
        o_dependencies      OUT pk_types.cursor_type,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if task can be executed (force) while checking the possible affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependencies    task dependencies array for the tasks about to change their 
    *                                     states
    * @param       o_flg_conflict         conflict flag to indicate if action affects other dependencies
    * @param       o_dependencies         cursor with all affected tasks
    * @param       o_msg_title            pop up message title for warnings
    * @param       o_msg_body             pop up message body for warnings
    * @param       o_error                error structure for exception handling
    *
    * @value       o_flg_conflict         {*} 'F' Task execution was forced by user. Caller module    
    *                                         needs to confirm the action
    *                                     {*} 'N' No conflicts detected: caller function can proceed 
    *                                         with tasks update
    *    
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              26-MAY-2010
    ********************************************************************************************/
    FUNCTION check_task_state_execute
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_dependencies IN table_number,
        o_flg_conflict      OUT VARCHAR2,
        o_dependencies      OUT pk_types.cursor_type,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- general error descriptions
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_tde_ux;
/
