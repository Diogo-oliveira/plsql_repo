/*-- Last Change Revision: $Rev: 2026721 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_ordertools_out IS

    -- purpose: order tools database api for outgoing data

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    -- declared exceptions
    e_user_exception EXCEPTION;

    /********************************************************************************************
    * function to return the contents of a professional structure in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a professional structure in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_prof_str(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
        IF i_prof IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        END IF;
    END get_prof_str;

    /********************************************************************************************
    * function to return the contents of a table number in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a table number in a string 
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabnum_str(i_table IN table_number) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_number(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabnum_str;

    /********************************************************************************************
    * function to return the contents of a table varchar in a string
    *
    * @param       i_prof                 professional structure
    *   
    * @return      varchar2               the contents of a table varchar in a string
    *
    * @author                             Carlos Loureiro
    * @since                              28-OCT-2011
    ********************************************************************************************/
    FUNCTION get_tabvar_str(i_table IN table_varchar) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN 'table_varchar(' || pk_utils.concat_table(i_tab => i_table, i_delim => ',') || ')';
        END IF;
    END get_tabvar_str;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_upd_task_state_suspend called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency || chr(10) || 'i_reason=' || i_reason ||
                                  chr(10) || 'i_reason_notes=' || i_reason_notes || chr(10) || 'i_transaction_id=' ||
                                  i_transaction_id,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.update_task_state_cancel function
        IF NOT pk_tde_db.update_task_state_cancel(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_task_dependency => i_task_dependency,
                                                  i_reason          => i_reason,
                                                  i_reason_notes    => i_reason_notes,
                                                  i_transaction_id  => i_transaction_id,
                                                  o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde_db.update_task_state_cancel function';
            RAISE e_user_exception;
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
                                              'TDE_UPD_TASK_STATE_CANCEL',
                                              o_error);
            RETURN FALSE;
    END tde_upd_task_state_cancel;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_upd_task_state_suspend called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency || chr(10) || 'i_reason=' || i_reason ||
                                  chr(10) || 'i_reason_notes=' || i_reason_notes,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.update_task_state_suspend function
        IF NOT pk_tde_db.update_task_state_suspend(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_task_dependency => i_task_dependency,
                                                   i_reason          => i_reason,
                                                   i_reason_notes    => i_reason_notes,
                                                   o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde_db.update_task_state_suspend function';
            RAISE e_user_exception;
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
                                              'TDE_UPD_TASK_STATE_SUSPEND',
                                              o_error);
            RETURN FALSE;
    END tde_upd_task_state_suspend;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_upd_task_state_execute called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.update_task_state_execute function
        IF NOT pk_tde_db.update_task_state_execute(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_task_dependency => i_task_dependency,
                                                   o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde_db.update_task_state_execute function';
            RAISE e_user_exception;
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
                                              'TDE_UPD_TASK_STATE_EXECUTE',
                                              o_error);
            RETURN FALSE;
    END tde_upd_task_state_execute;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_upd_task_state_finish called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.update_task_state_finish function
        IF NOT pk_tde_db.update_task_state_finish(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_task_dependency => i_task_dependency,
                                                  o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde_db.update_task_state_finish function';
            RAISE e_user_exception;
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
                                              'TDE_UPD_TASK_STATE_FINISH',
                                              o_error);
            RETURN FALSE;
    END tde_upd_task_state_finish;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_chk_task_state_resume called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.update_task_state_resume function
        IF NOT pk_tde_db.check_task_state_resume(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_task_dependency => i_task_dependency,
                                                 o_flg_resume      => o_flg_resume,
                                                 o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde_db.update_task_state_resume function';
            RAISE e_user_exception;
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
                                              'TDE_CHK_TASK_STATE_RESUME',
                                              o_error);
            RETURN FALSE;
    END tde_chk_task_state_resume;

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
    ) RETURN VARCHAR2 IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tde_get_task_depend_str called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_task_dependency=' || i_task_dependency,
                                  g_package_name);
        END IF;
    
        -- call pk_tde_db.get_task_depend_str function
        RETURN pk_tde_db.get_task_depend_str(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_task_dependency => i_task_dependency);
    END tde_get_task_depend_str;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.cpoe_med_sync_task called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) || 'i_episode=' ||
                                  i_episode || chr(10) || 'i_task_request=' || i_task_request,
                                  g_package_name);
        END IF;
    
        -- call pk_cpoe_db.sync_task function
        IF NOT pk_cpoe_db.sync_task(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_episode => i_episode,
                                    -- new medication task type
                                    i_task_type    => pk_alert_constant.g_task_type_medication,
                                    i_task_request => i_task_request,
                                    o_error        => o_error)
        THEN
            g_error := 'error while calling pk_cpoe_db.sync_task function';
            RAISE e_user_exception;
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
                                              'CPOE_SYNC_TASK',
                                              o_error);
            RETURN FALSE;
    END cpoe_med_sync_task;

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
    ) RETURN t_table_mapping_conc IS
        l_error t_error_out;
    BEGIN
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.tf_get_mapping_concepts called with:' || chr(10) ||
                                  'i_lang=' || i_lang || chr(10) || 'i_source_concept=' ||
                                  get_tabvar_str(i_source_concept) || chr(10) || 'i_source_map_set=' ||
                                  i_source_map_set || chr(10) || 'i_target_map_set=' || i_target_map_set || chr(10) ||
                                  'i_target_mcs_src=' || i_target_mcs_src,
                                  g_package_name);
        END IF;
    
        -- call pk_mapping_sets.tf_get_mapping_concepts function
        RETURN pk_mapping_sets.tf_get_mapping_concepts(i_lang           => i_lang,
                                                       i_source_concept => i_source_concept,
                                                       i_source_map_set => i_source_map_set,
                                                       i_target_map_set => i_target_map_set,
                                                       i_target_mcs_src => i_target_mcs_src);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_MAPPING_CONCEPTS',
                                              l_error);
            RETURN NULL;
    END tf_get_mapping_concepts;

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
    ) RETURN BOOLEAN IS
    
        l_order_set_tasks t_tbl_odst_task := t_tbl_odst_task();
    
        CURSOR c_order_set_tasks IS
        
            SELECT odst_tsk.id_order_set_task AS id_order_set_task, odst_tsk.id_task_type AS id_task_type
              FROM order_set_task odst_tsk
             WHERE odst_tsk.id_order_set = i_id_order_set;
    
    BEGIN
    
        -- input parameters debug message
        IF g_debug
        THEN
            pk_alertlog.log_debug('pk_api_pfh_ordertools_out.get_order_set_tasks called with:' || chr(10) || 'i_lang=' ||
                                  i_lang || chr(10) || 'i_prof=' || get_prof_str(i_prof) || chr(10) ||
                                  'i_id_order_set=' || i_id_order_set,
                                  g_package_name);
        END IF;
    
        g_error := 'GET CURSOR WITH ORDER SET TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_order_set_tasks
        LOOP
        
            l_order_set_tasks := l_order_set_tasks MULTISET UNION
                                 pk_order_sets.get_task_desc_array(i_lang,
                                                                   i_prof,
                                                                   rec.id_order_set_task,
                                                                   rec.id_task_type,
                                                                   pk_alert_constant.g_no,
                                                                   pk_alert_constant.g_no,
                                                                   pk_order_sets.g_task_desc_short_format,
                                                                   pk_alert_constant.g_no);
        
        END LOOP;
    
        OPEN o_order_set_tasks FOR
            SELECT ost.id_order_set_task AS id_order_set_task,
                   ost.id_task_type      AS id_task_type,
                   ost.id_task_link      AS id_task_link,
                   ost.task_desc         AS task_title
              FROM TABLE(l_order_set_tasks) ost
             ORDER BY ost.id_task_type, ost.task_desc;
    
        RETURN TRUE;
    EXCEPTION
        -- Unexpected error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_SET_TASKS',
                                              o_error);
            pk_types.open_my_cursor(o_order_set_tasks);
            RETURN FALSE;
    END get_order_set_tasks;

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
    g_debug := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);
END pk_api_pfh_ordertools_out;
/
