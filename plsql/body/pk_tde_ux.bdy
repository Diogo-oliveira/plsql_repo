/*-- Last Change Revision: $Rev: 2027789 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_tde_ux IS

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.check_task_state_core(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_task_dependencies => i_task_dependencies,
                                            i_task_states       => pk_tde.g_tde_task_trans_cancel,
                                            o_flg_conflict      => o_flg_conflict,
                                            o_dependencies      => o_dependencies,
                                            o_msg_title         => o_msg_title,
                                            o_msg_body          => o_msg_body,
                                            o_error             => o_error)
        THEN
            g_error := 'error while calling pk_tde.check_task_state_core function';
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
                                              'CHECK_TASK_STATE_CANCEL',
                                              o_error);
            pk_types.open_my_cursor(o_dependencies);
            RETURN FALSE;
        
    END check_task_state_cancel;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.check_task_state_core(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_task_dependencies => i_task_dependencies,
                                            i_task_states       => pk_tde.g_tde_task_trans_suspend,
                                            o_flg_conflict      => o_flg_conflict,
                                            o_dependencies      => o_dependencies,
                                            o_msg_title         => o_msg_title,
                                            o_msg_body          => o_msg_body,
                                            o_error             => o_error)
        THEN
            g_error := 'error while calling pk_tde.check_task_state_core function';
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
                                              'CHECK_TASK_STATE_SUSPEND',
                                              o_error);
            pk_types.open_my_cursor(o_dependencies);
            RETURN FALSE;
        
    END check_task_state_suspend;

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
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.check_task_state_core(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_task_dependencies => i_task_dependencies,
                                            i_task_states       => pk_tde.g_tde_task_trans_force_exec,
                                            o_flg_conflict      => o_flg_conflict,
                                            o_dependencies      => o_dependencies,
                                            o_msg_title         => o_msg_title,
                                            o_msg_body          => o_msg_body,
                                            o_error             => o_error)
        THEN
            g_error := 'error while calling pk_tde.check_task_state_core function';
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
                                              'CHECK_TASK_STATE_EXECUTE',
                                              o_error);
            pk_types.open_my_cursor(o_dependencies);
            RETURN FALSE;
        
    END check_task_state_execute;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_tde_ux;
/
