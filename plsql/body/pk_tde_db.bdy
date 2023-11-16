CREATE OR REPLACE PACKAGE BODY pk_tde_db IS

    -- Purpose : Task Dependency Engine database package for DB interface

    /********************************************************************************************
    * create combination dependency relationship between 2 different tasks
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    relationship type (start-2-start or finish-2-start)
    * @param       i_task_type_from       task type id (where the dependecy comes from)
    * @param       i_task_request_from    task request id (where the dependecy comes from)
    * @param       i_task_type_to         task type id (where the dependecy goes to)
    * @param       i_task_request_to      task request id (where the dependecy goes to)
    * @param       i_lag_min              minimum lag time between tasks
    * @param       i_lag_max              maximum lag time between tasks
    * @param       i_unit_measure_lag     lag time unit measure id
    * @param       o_task_dependency_from created dependency id for i_task_type_from and i_task_request_from pair
    * @param       o_task_dependency_to   created dependency id for i_task_type_to and i_task_request_to pair
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              01-JUL-2010
    ********************************************************************************************/
    FUNCTION create_dependency_network
    (
        i_lang                 IN language.id_language%TYPE,
        i_relationship_type    IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_type_from       IN task_type.id_task_type%TYPE,
        i_task_request_from    IN tde_task_dependency.id_task_request%TYPE,
        i_task_type_to         IN task_type.id_task_type%TYPE,
        i_task_request_to      IN tde_task_dependency.id_task_request%TYPE,
        i_lag_min              IN tde_task_rel_dependency.lag_min%TYPE,
        i_lag_max              IN tde_task_rel_dependency.lag_max%TYPE,
        i_unit_measure_lag     IN tde_task_rel_dependency.id_unit_measure_lag%TYPE,
        o_task_dependency_from OUT tde_task_dependency.id_task_dependency%TYPE,
        o_task_dependency_to   OUT tde_task_dependency.id_task_dependency%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.create_dependency_network(i_lang                 => i_lang,
                                                i_relationship_type    => i_relationship_type,
                                                i_task_type_from       => i_task_type_from,
                                                i_task_request_from    => i_task_request_from,
                                                i_task_type_to         => i_task_type_to,
                                                i_task_request_to      => i_task_request_to,
                                                i_lag_min              => i_lag_min,
                                                i_lag_max              => i_lag_max,
                                                i_unit_measure_lag     => i_unit_measure_lag,
                                                o_task_dependency_from => o_task_dependency_from,
                                                o_task_dependency_to   => o_task_dependency_to,
                                                o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.create_dependency_network function';
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
                                              'CREATE_DEPENDENCY_NETWORK',
                                              o_error);
            RETURN FALSE;
        
    END create_dependency_network;

    /********************************************************************************************
    * delete all existing relationships between given dependencies
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency      array with task dependencies
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              01-JUL-2010
    ********************************************************************************************/
    FUNCTION delete_dependency_network
    (
        i_lang              IN language.id_language%TYPE,
        i_relationship_type IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_dependency   IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.delete_dependency_network(i_lang              => i_lang,
                                                i_relationship_type => i_relationship_type,
                                                i_task_dependency   => i_task_dependency,
                                                o_error             => o_error)
        THEN
            g_error := 'error while calling pk_tde.delete_dependency_network function';
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
                                              'DELETE_DEPENDENCY_NETWORK',
                                              o_error);
            RETURN FALSE;
        
    END delete_dependency_network;

    /********************************************************************************************
    * create task dependency
    *
    * @param       i_lang                 preferred language id
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    * @param       i_task_state           starting task mode or state
    * @param       i_task_schedule        task schedule mode
    * @param       o_task_dependency      created task dependency
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       i_task_state           {*} 'R' start task as usual (requested)
    *                                     {*} 'D' start task is depending of other tasks
    *                                             conclusion (start depending)
    *
    * @value       i_task_schedule        {*} 'Y' task if for schedule
    *                                     {*} 'N' task is not for schedule
    *
    * @author                             Carlos Loureiro
    * @since                              11-JUN-2010
    ********************************************************************************************/
    FUNCTION create_dependency
    (
        i_lang            IN language.id_language%TYPE,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_task_request    IN tde_task_dependency.id_task_request%TYPE,
        i_task_state      IN tde_task_dependency.flg_task_state%TYPE,
        i_task_schedule   IN tde_task_dependency.flg_schedule%TYPE,
        o_task_dependency OUT tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.create_dependency(i_lang            => i_lang,
                                        i_task_type       => i_task_type,
                                        i_task_request    => i_task_request,
                                        i_task_state      => i_task_state,
                                        i_task_schedule   => i_task_schedule,
                                        o_task_dependency => o_task_dependency,
                                        o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.create_dependency function';
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
                                              'CREATE_DEPENDENCY',
                                              o_error);
            RETURN FALSE;
        
    END create_dependency;

    /********************************************************************************************
    * update task dependency
    *
    * @param       i_lang                 preferred language id
    * @param       i_task_dependency      task dependency to be updated
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              11-JUN-2010
    ********************************************************************************************/
    FUNCTION update_dependency
    (
        i_lang            IN language.id_language%TYPE,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_task_request    IN tde_task_dependency.id_task_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.update_dependency(i_lang            => i_lang,
                                        i_task_dependency => i_task_dependency,
                                        i_task_type       => i_task_type,
                                        i_task_request    => i_task_request,
                                        o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_dependency function';
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
                                              'UPDATE_DEPENDENCY',
                                              o_error);
            RETURN FALSE;
        
    END update_dependency;

    /********************************************************************************************
    * create task dependency relationship between 2 different tasks
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency_from task dependency for the task where the dependecy comes from
    * @param       i_task_dependency_to   task dependency for the task where the dependecy goes to
    * @param       i_lag_min              minimum lag time between tasks
    * @param       i_lag_max              maximum lag time between tasks
    * @param       i_unit_measure_lag     lag time unit measure id
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              28-APR-2010
    ********************************************************************************************/
    FUNCTION create_dependency_relationship
    (
        i_lang                 IN language.id_language%TYPE,
        i_relationship_type    IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_dependency_from IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_dependency_to   IN tde_task_dependency.id_task_dependency%TYPE,
        i_lag_min              IN tde_task_rel_dependency.lag_min%TYPE,
        i_lag_max              IN tde_task_rel_dependency.lag_max%TYPE,
        i_unit_measure_lag     IN tde_task_rel_dependency.id_unit_measure_lag%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.create_dependency_relationship(i_lang                 => i_lang,
                                                     i_relationship_type    => i_relationship_type,
                                                     i_task_dependency_from => i_task_dependency_from,
                                                     i_task_dependency_to   => i_task_dependency_to,
                                                     i_lag_min              => i_lag_min,
                                                     i_lag_max              => i_lag_max,
                                                     i_unit_measure_lag     => i_unit_measure_lag,
                                                     o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.create_dependency_relationship function';
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
                                              'CREATE_DEPENDENCY_RELATIONSHIP',
                                              o_error);
            RETURN FALSE;
        
    END create_dependency_relationship;

    /********************************************************************************************
    * update task dependency lags between 2 different tasks
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency_from task dependency for the task where the dependecy comes from
    * @param       i_task_dependency_to   task dependency for the task where the dependecy goes to
    * @param       i_lag_min              minimum lag time between tasks
    * @param       i_lag_max              maximum lag time between tasks
    * @param       i_unit_measure_lag     lag time unit measure id
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              28-APR-2010
    ********************************************************************************************/
    FUNCTION update_dependency_relationship
    (
        i_lang                 IN language.id_language%TYPE,
        i_relationship_type    IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_dependency_from IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_dependency_to   IN tde_task_dependency.id_task_dependency%TYPE,
        i_lag_min              IN tde_task_rel_dependency.lag_min%TYPE DEFAULT NULL,
        i_lag_max              IN tde_task_rel_dependency.lag_max%TYPE DEFAULT NULL,
        i_unit_measure_lag     IN tde_task_rel_dependency.id_unit_measure_lag%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.create_dependency_relationship(i_lang                 => i_lang,
                                                     i_relationship_type    => i_relationship_type,
                                                     i_task_dependency_from => i_task_dependency_from,
                                                     i_task_dependency_to   => i_task_dependency_to,
                                                     i_lag_min              => i_lag_min,
                                                     i_lag_max              => i_lag_max,
                                                     i_unit_measure_lag     => i_unit_measure_lag,
                                                     o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_dependency_relationship function';
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
                                              'UPDATE_DEPENDENCY_RELATIONSHIP',
                                              o_error);
            RETURN FALSE;
        
    END update_dependency_relationship;

    /********************************************************************************************
    * delete task dependency relationship between two dependencies
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency_from task dependency where the relationship comes from
    * @param       i_task_dependency_to   task dependency where the relationship goes to
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              03-JUL-2010
    ********************************************************************************************/
    FUNCTION delete_dependency_relationship
    (
        i_lang                 IN language.id_language%TYPE,
        i_relationship_type    IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_dependency_from IN tde_task_rel_dependency.id_task_dependency_from%TYPE,
        i_task_dependency_to   IN tde_task_rel_dependency.id_task_dependency_to%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.delete_dependency_relationship(i_lang                 => i_lang,
                                                     i_relationship_type    => i_relationship_type,
                                                     i_task_dependency_from => i_task_dependency_from,
                                                     i_task_dependency_to   => i_task_dependency_to,
                                                     o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.delete_dependency_relationship function';
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
                                              'DELETE_DEPENDENCY_RELATIONSHIP',
                                              o_error);
            RETURN FALSE;
        
    END delete_dependency_relationship;

    /********************************************************************************************
    * validate task dependencies (closed loop and lag time incompatibilities)
    *
    * @param       i_lang                 preferred language id
    * @param       i_relationship_type    array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to   array of task dependencies for the tasks where the dependency goes to
    * @param       i_task_type_from       array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to         array of task types for the tasks where the dependency goes to
    * @param       i_task_schedule_from   array of tasks where the dependency comes from, to schedule or not
    * @param       i_task_schedule_to     array of tasks where the dependency goes to, to schedule or not
    * @param       i_lag_min              array of minimum lag time between tasks
    * @param       i_lag_max              array of maximum lag time between tasks
    * @param       i_unit_measure_lag     array of lag time unit measure id
    * @param       o_flg_conflict         conflict flag to indicate incompatible dependencies network
    * @param       o_msg_title            pop up message title for warnings
    * @param       o_msg_body             pop up message body for warnings
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       o_flg_conflict         {*} 'C' closed loop cycle through dependencies was found
    *                                     {*} 'E' from/to dependencies cannot be the equal in the same relationship
    *                                     {*} 'N' No conflicts detected
    *
    * @author                             Carlos Loureiro
    * @since                              14-JUN-2010
    ********************************************************************************************/
    FUNCTION validate_dependencies
    (
        i_lang                 IN language.id_language%TYPE,
        i_relationship_type    IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number,
        i_task_schedule_from   IN table_varchar,
        i_task_schedule_to     IN table_varchar,
        i_lag_min              IN table_number,
        i_lag_max              IN table_number,
        i_unit_measure_lag     IN table_number,
        o_flg_conflict         OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_body             OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.validate_dependencies(i_lang                 => i_lang,
                                            i_relationship_type    => i_relationship_type,
                                            i_task_dependency_from => i_task_dependency_from,
                                            i_task_dependency_to   => i_task_dependency_to,
                                            i_task_type_from       => i_task_type_from,
                                            i_task_type_to         => i_task_type_to,
                                            i_task_schedule_from   => i_task_schedule_from,
                                            i_task_schedule_to     => i_task_schedule_to,
                                            i_lag_min              => i_lag_min,
                                            i_lag_max              => i_lag_max,
                                            i_unit_measure_lag     => i_unit_measure_lag,
                                            o_flg_conflict         => o_flg_conflict,
                                            o_msg_title            => o_msg_title,
                                            o_msg_body             => o_msg_body,
                                            o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.validate_dependencies function';
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
                                              'VALIDATE_DEPENDENCIES',
                                              o_error);
            RETURN FALSE;
        
    END validate_dependencies;

    /********************************************************************************************
    * validate task dependency option (to enable/disable options)
    *
    * @param       i_lang                       preferred language id
    * @param       i_relationship_type          array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from       array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to         array of task dependencies for the tasks where the dependency goes to
    * @param       i_task_type_from             array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to               array of task types for the tasks where the dependency goes to
    * @param       i_task_schedule_from         array of tasks where the dependency comes from, to schedule or not
    * @param       i_task_schedule_to           array of tasks where the dependency goes to, to schedule or not
    * @param       i_chk_rel_type               dependency relationship type to check for conflicts
    * @param       i_chk_task_depend_from       task dependency to check for (for the tasks where the dependency comes from)
    * @param       i_chk_task_depend_to         task dependency to check for (for the tasks where the dependency goes to)
    * @param       i_chk_task_type_from         task type to check for (for the tasks where the dependency comes from)
    * @param       i_chk_task_type_to           task type to check for (for the tasks where the dependency goes to)
    * @param       i_chk_task_schedule_from     task to check for schedule flag, where the dependency comes from
    * @param       i_chk_task_schedule_to       task to check for schedule flag, where the dependency goes to
    *
    * @return      validate_dependency_option   {*} 'Y' check dependency is valid
    *                                           {*} 'N' check dependency has failed and cannot be used
    *
    * @author                                   Carlos Loureiro
    * @since                                    14-JUN-2010
    ********************************************************************************************/
    FUNCTION validate_dependency_option
    (
        i_lang                   IN language.id_language%TYPE,
        i_relationship_type      IN table_number,
        i_task_dependency_from   IN table_number,
        i_task_dependency_to     IN table_number,
        i_task_type_from         IN table_number,
        i_task_type_to           IN table_number,
        i_task_schedule_from     IN table_varchar,
        i_task_schedule_to       IN table_varchar,
        i_chk_rel_type           IN tde_relationship_type.id_relationship_type%TYPE,
        i_chk_task_depend_from   IN NUMBER,
        i_chk_task_depend_to     IN NUMBER,
        i_chk_task_type_from     IN task_type.id_task_type%TYPE,
        i_chk_task_type_to       IN task_type.id_task_type%TYPE,
        i_chk_task_schedule_from IN VARCHAR2,
        i_chk_task_schedule_to   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.validate_dependency_option(i_lang                   => i_lang,
                                                 i_relationship_type      => i_relationship_type,
                                                 i_task_dependency_from   => i_task_dependency_from,
                                                 i_task_dependency_to     => i_task_dependency_to,
                                                 i_task_type_from         => i_task_type_from,
                                                 i_task_type_to           => i_task_type_to,
                                                 i_task_schedule_from     => i_task_schedule_from,
                                                 i_task_schedule_to       => i_task_schedule_to,
                                                 i_chk_rel_type           => i_chk_rel_type,
                                                 i_chk_task_depend_from   => i_chk_task_depend_from,
                                                 i_chk_task_depend_to     => i_chk_task_depend_to,
                                                 i_chk_task_type_from     => i_chk_task_type_from,
                                                 i_chk_task_type_to       => i_chk_task_type_to,
                                                 i_chk_task_schedule_from => i_chk_task_schedule_from,
                                                 i_chk_task_schedule_to   => i_chk_task_schedule_to);
    END validate_dependency_option;

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
    FUNCTION update_task_state_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes    IN VARCHAR2,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_transaction_id VARCHAR2(4000); -- scheduler transaction
    
    BEGIN
        -- get new transaction id (if no one was provided) and begins the transaction for scheduler
        g_error          := 'calling pk_schedule_api_upstream.begin_new_transaction';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF NOT pk_tde.update_task_state_core(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_task_dependency => i_task_dependency,
                                             i_task_state      => pk_tde.g_tde_task_trans_cancel,
                                             i_reason          => i_reason,
                                             i_reason_notes    => i_reason_notes,
                                             i_transaction_id  => l_transaction_id,
                                             o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_task_state_core function';
            RAISE l_exception;
        END IF;
    
        -- if no transaction id was given to this function, then commit scheduler transaction created here
        IF i_transaction_id IS NULL
        THEN
            g_error := 'calling pk_schedule_api_upstream.do_commit';
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'UPDATE_TASK_STATE_CANCEL',
                                              o_error);
        
            -- if no transaction id was given to this function, then commit scheduler transaction created here
            IF i_transaction_id IS NULL
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof); -- rollback scheduler transaction
            END IF;
        
            RETURN FALSE;
        
    END update_task_state_cancel;

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
    FUNCTION update_task_state_suspend
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes    IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.update_task_state_core(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_task_dependency => i_task_dependency,
                                             i_task_state      => pk_tde.g_tde_task_trans_suspend,
                                             i_reason          => i_reason,
                                             i_reason_notes    => i_reason_notes,
                                             i_transaction_id  => NULL,
                                             o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_task_state_core function';
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
                                              'UPDATE_TASK_STATE_SUSPEND',
                                              o_error);
            RETURN FALSE;
        
    END update_task_state_suspend;

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
    FUNCTION update_task_state_execute
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.update_task_state_core(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_task_dependency => i_task_dependency,
                                             i_task_state      => pk_tde.g_tde_task_trans_force_exec,
                                             i_reason          => NULL,
                                             i_reason_notes    => NULL,
                                             i_transaction_id  => NULL,
                                             o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_task_state_core function';
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
                                              'UPDATE_TASK_STATE_EXECUTE',
                                              o_error);
            RETURN FALSE;
        
    END update_task_state_execute;

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
    FUNCTION update_task_state_finish
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.update_task_state_core(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_task_dependency => i_task_dependency,
                                             i_task_state      => pk_tde.g_tde_task_trans_finish,
                                             i_reason          => NULL,
                                             i_reason_notes    => NULL,
                                             i_transaction_id  => NULL,
                                             o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.update_task_state_core function';
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
                                              'UPDATE_TASK_STATE_FINISH',
                                              o_error);
            RETURN FALSE;
        
    END update_task_state_finish;

    /********************************************************************************************
    * get available relationship types for a given task type
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       o_relationships        cursor with all relationship types
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              02-JUN-2010
    ********************************************************************************************/
    FUNCTION get_relationship_types
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_type     IN task_type.id_task_type%TYPE,
        o_relationships OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.get_relationship_types(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_task_type     => i_task_type,
                                             o_relationships => o_relationships,
                                             o_error         => o_error)
        THEN
            g_error := 'error while calling pk_tde.get_relationship_types function';
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
                                              'GET_RELATIONSHIP_TYPES',
                                              o_error);
            RETURN FALSE;
        
    END get_relationship_types;

    /********************************************************************************************
    * get relationship type translation
    *
    * @param       i_lang                 preferred language id
    * @param       i_tde_rel_type         id of tde relationship type
    *
    * @return      varchar2               description/translation of tde relationship type
    *
    * @author                             Carlos Loureiro
    * @since                              07-JUN-2010
    ********************************************************************************************/
    FUNCTION get_relationship_type_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_tde_rel_type IN tde_relationship_type.id_relationship_type%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.get_relationship_type_desc(i_lang => i_lang, i_tde_rel_type => i_tde_rel_type);
    END get_relationship_type_desc;

    /********************************************************************************************
    * evaluates if a single lag should be used or not between 2 dependencies
    *
    * @param       i_task_type_from         task type to check for (for the tasks where the dependency comes from)
    * @param       i_task_type_to           task type to check for (for the tasks where the dependency goes to)
    * @param       i_task_schedule_from     task to check for schedule flag, where the dependency comes from
    * @param       i_task_schedule_to       task to check for schedule flag, where the dependency goes to
    *
    * @return      varchar2                 flag that indicates if a single lag should be used or not
    *
    * @value       single_lag_enable        {*} 'Y' use single lag
    *                                       {*} 'N' normal lag interval can be used
    *
    * @author                               Carlos Loureiro
    * @since                                28-JUN-2010
    ********************************************************************************************/
    FUNCTION single_lag_enable
    (
        i_task_type_from    IN task_type.id_task_type%TYPE,
        i_task_type_to      IN task_type.id_task_type%TYPE,
        i_flg_schedule_from IN VARCHAR2,
        i_flg_schedule_to   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.single_lag_enable(i_task_type_from    => i_task_type_from,
                                        i_task_type_to      => i_task_type_to,
                                        i_flg_schedule_from => i_flg_schedule_from,
                                        i_flg_schedule_to   => i_flg_schedule_to);
    END single_lag_enable;

    /********************************************************************************************
    * evaluates if lag should be used or not between 2 dependencies
    *
    * @param       i_relationship_type      task dependency relationship type
    * @param       i_task_type_from         task type to check for (for the tasks where the dependency comes from)
    * @param       i_task_type_to           task type to check for (for the tasks where the dependency goes to)
    *
    * @return      varchar2                 flag that indicates if lag should be used or not
    *
    * @value       lag_support_enable       {*} 'Y' use lags
    *                                       {*} 'N' don't use lags
    *
    * @author                               Carlos Loureiro
    * @since                                28-JUN-2010
    ********************************************************************************************/
    FUNCTION lag_support_enable
    (
        i_relationship_type IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_type_from    IN task_type.id_task_type%TYPE,
        i_task_type_to      IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.lag_support_enable(i_relationship_type => i_relationship_type,
                                         i_task_type_from    => i_task_type_from,
                                         i_task_type_to      => i_task_type_to);
    END lag_support_enable;

    /********************************************************************************************
    * get task dependencies to use in task detail screens
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency id
    * @param       o_dependencies         cursor with task dependencies descriptions
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              03-MAY-2010
    ********************************************************************************************/
    FUNCTION get_task_dependencies
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_dependencies    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.get_task_dependencies(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_task_dependency => i_task_dependency,
                                            o_dependencies    => o_dependencies,
                                            o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.get_task_dependencies function';
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
                                              'GET_TASK_DEPENDENCIES',
                                              o_error);
            RETURN FALSE;
        
    END get_task_dependencies;

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
    FUNCTION get_task_depend_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.get_task_depend_str(i_lang => i_lang, i_prof => i_prof, i_task_dependency => i_task_dependency);
    END get_task_depend_str;

    /********************************************************************************************
    * returns a dependencies description for a given dependency and network
    *
    * @param    i_lang                 preferred language id
    * @param    i_prof                 professional structure
    * @param    i_target_dependency    target dependency
    * @param    i_target_schedule      indicates if the target dependency is to schedule or not
    * @param    i_tasks_rank           array that contains the rank of each task
    * @param    i_relationship_type    array of relationships (start-2-start or finish-2-start)
    * @param    i_task_dependency_from array of task dependencies for the tasks where the dependency comes from
    * @param    i_task_dependency_to   array of task dependencies for the tasks where the dependency goes to
    * @param    i_task_type_from       array of task types for the tasks where the dependency comes from
    * @param    i_task_type_to         array of task types for the tasks where the dependency goes to
    * @param    i_task_schedule_from   array of tasks where the dependency comes from, to schedule or not
    * @param    i_task_schedule_to     array of tasks where the dependency goes to, to schedule or not
    * @param    i_lag_min              array of minimum lag time between tasks
    * @param    i_lag_max              array of maximum lag time between tasks
    * @param    i_lag_unit_measure     array of lag time unit measure id
    *
    * @return   varchar2               dependencies description string
    *
    * @author                          Tiago Silva
    * @since                           28-JUN-2010
    ********************************************************************************************/
    FUNCTION get_depend_description
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_target_dependency    IN NUMBER,
        i_target_schedule      IN VARCHAR2,
        i_tasks_rank           IN table_number,
        i_relationship_type    IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number,
        i_task_schedule_from   IN table_varchar,
        i_task_schedule_to     IN table_varchar,
        i_lag_min              IN table_number,
        i_lag_max              IN table_number,
        i_lag_unit_measure     IN table_number
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_tde.get_depend_description(i_lang                 => i_lang,
                                             i_prof                 => i_prof,
                                             i_target_dependency    => i_target_dependency,
                                             i_target_schedule      => i_target_schedule,
                                             i_tasks_rank           => i_tasks_rank,
                                             i_relationship_type    => i_relationship_type,
                                             i_task_dependency_from => i_task_dependency_from,
                                             i_task_dependency_to   => i_task_dependency_to,
                                             i_task_type_from       => i_task_type_from,
                                             i_task_type_to         => i_task_type_to,
                                             i_task_schedule_from   => i_task_schedule_from,
                                             i_task_schedule_to     => i_task_schedule_to,
                                             i_lag_min              => i_lag_min,
                                             i_lag_max              => i_lag_max,
                                             i_lag_unit_measure     => i_lag_unit_measure);
    END get_depend_description;

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
    FUNCTION check_task_state_resume
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_flg_resume      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.check_task_state_resume(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_task_dependency => i_task_dependency,
                                              o_flg_resume      => o_flg_resume,
                                              o_error           => o_error)
        THEN
            g_error := 'error while calling pk_tde.check_task_state_resume function';
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
                                              'CHECK_TASK_STATE_RESUME',
                                              o_error);
            RETURN FALSE;
        
    END check_task_state_resume;

    /********************************************************************************************
    * check if task shoud be resumed normally or should return to "waiting for dependencies" state
    *
    * @param       i_lang                 preferred language id
    * @param       i_dependency           array with all dependencies to validate in the network
    * @param       i_task_dependency_from array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to   array of task dependencies for the tasks where the dependency goes to
    * @param       o_flg_single_network   flag that indicates if given dependencies belongs to the same network
    * @param       o_combinations         bi-dimensional array with all available dependency combinations
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       o_flg_single_network   {*} 'Y' all elements provided by this function belongs to
    *                                         the same network
    *                                     {*} 'N' all elements provided by this function are contained in
    *                                         different networks (at least they belong to 2 different networks)
    *
    * @author                             Carlos Loureiro
    * @since                              07-JUL-2010
    ********************************************************************************************/
    FUNCTION get_network_combinations
    (
        i_lang                 IN language.id_language%TYPE,
        i_dependency           IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        o_flg_single_network   OUT VARCHAR2,
        o_combinations         OUT table_table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        IF NOT pk_tde.get_network_combinations(i_lang                 => i_lang,
                                               i_dependency           => i_dependency,
                                               i_task_dependency_from => i_task_dependency_from,
                                               i_task_dependency_to   => i_task_dependency_to,
                                               o_flg_single_network   => o_flg_single_network,
                                               o_combinations         => o_combinations,
                                               o_error                => o_error)
        THEN
            g_error := 'error while calling pk_tde.get_network_combinations function';
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
                                              'GET_NETWORK_COMBINATIONS',
                                              o_error);
            RETURN FALSE;
        
    END get_network_combinations;

    /********************************************************************************************
    * check if task shoud be resumed normally or should return to "waiting for dependencies" state
    *
    * @param       i_dependency           array with all dependencies to validate in the network
    * @param       i_relationship_type    array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to   array of task dependencies for the tasks where the dependency goes to
    * @param       i_task_type_from       array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to         array of task types for the tasks where the dependency goes to
    *
    * @return      table_number           array with sucessor dependencies
    *
    * @author                             Carlos Loureiro
    * @since                              09-JUL-2010
    ********************************************************************************************/
    FUNCTION get_sucessor_dependencies
    (
        i_dependency           IN NUMBER,
        i_relationship_type    IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number
    ) RETURN table_number IS
    BEGIN
        RETURN pk_tde.get_sucessor_dependencies(i_dependency           => i_dependency,
                                                i_relationship_type    => i_relationship_type,
                                                i_task_dependency_from => i_task_dependency_from,
                                                i_task_dependency_to   => i_task_dependency_to,
                                                i_task_type_from       => i_task_type_from,
                                                i_task_type_to         => i_task_type_to);
    END get_sucessor_dependencies;

    /********************************************************************************************
    * check if task shoud be resumed normally or should return to "waiting for dependencies" state
    *
    * @param       i_dependency           array with all dependencies to validate in the network
    * @param       i_relationship_type    array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to   array of task dependencies for the tasks where the dependency goes to
    * @param       i_task_type_from       array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to         array of task types for the tasks where the dependency goes to
    *
    * @return      table_number           array with predecessor dependencies
    *
    * @author                             Carlos Loureiro
    * @since                              09-JUL-2010
    ********************************************************************************************/
    FUNCTION get_predecessor_dependencies
    (
        i_dependency           IN NUMBER,
        i_relationship_type    IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number
    ) RETURN table_number IS
    BEGIN
        RETURN pk_tde.get_predecessor_dependencies(i_dependency           => i_dependency,
                                                   i_relationship_type    => i_relationship_type,
                                                   i_task_dependency_from => i_task_dependency_from,
                                                   i_task_dependency_to   => i_task_dependency_to,
                                                   i_task_type_from       => i_task_type_from,
                                                   i_task_type_to         => i_task_type_to);
    END get_predecessor_dependencies;

    /********************************************************************************************
    * get task dependency based in task type and request id
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    *
    * @return      number                 task dependency id
    *
    * @author                             Carlos Loureiro
    * @since                              19-AUG-2010
    ********************************************************************************************/
    FUNCTION get_task_dependency
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_request IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN tde_task_dependency.id_task_dependency%TYPE IS
    BEGIN
        RETURN pk_tde.get_task_dependency(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_task_type    => i_task_type,
                                          i_task_request => i_task_request);
    END get_task_dependency;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_tde_db;
/
