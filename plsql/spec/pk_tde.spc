/*-- Last Change Revision: $Rev: 2029007 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_tde IS

    -- Purpose : Task Dependency Engine database package

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    FUNCTION get_task_depend_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get task description based in task type and request id
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    *
    * @return      varchar2               task description    
    *
    * @author                             Carlos Loureiro
    * @since                              27-MAY-2010
    ********************************************************************************************/
    FUNCTION get_task_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_request IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get task execute time description
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         request that identifies patient's task process
    *
    * @return      varchar2               task execute time description
    *
    * @author                             Carlos Loureiro
    * @since                              22-JUN-2010
    ********************************************************************************************/
    FUNCTION get_execute_time_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_request IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check if task state can be updated while checking the possible affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependencies    task dependencies array for the tasks about to change their 
    *                                     states
    * @param       i_task_states          target tasks states or desired tasks states
    * @param       o_flg_conflict         conflict flag to indicate if task action affects other
    *                                     dependencies
    * @param       o_dependencies         cursor with all affected tasks
    * @param       o_msg_title            pop up message title for warnings
    * @param       o_msg_body             pop up message body for warnings
    * @param       o_error                error structure for exception handling
    *
    * @value       o_flg_conflict         {*} 'Y' Conflicts detected in task cancelation and caller    
    *                                         module needs to confirm the action
    *                                     {*} 'C' Conflicts detected in task cancelation, but caller  
    *                                         module cannot continue tasks update
    *                                     {*} 'S' Conflicts detected in suspend action, and caller    
    *                                         module needs to confirm the action
    *                                     {*} 'F' Task execution was forced by user. Caller module    
    *                                         needs to confirm the action
    *                                     {*} 'N' No conflicts detected: caller function can proceed 
    *                                         with tasks update
    *    
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              03-MAY-2010
    ********************************************************************************************/
    FUNCTION check_task_state_core
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_dependencies IN table_number,
        i_task_states       IN VARCHAR2,
        o_flg_conflict      OUT VARCHAR2,
        o_dependencies      OUT pk_types.cursor_type,
        o_msg_title         OUT VARCHAR2,
        o_msg_body          OUT VARCHAR2,
        o_error             OUT t_error_out
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
    FUNCTION check_task_state_resume
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_flg_resume      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update task state and processes the affected dependencies (if any)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_task_state           target task state or desired task state
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
    * @since                              29-APR-2010
    ********************************************************************************************/
    FUNCTION update_task_state_core
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_state      IN VARCHAR2,
        i_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes    IN VARCHAR2,
        i_transaction_id  IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    FUNCTION update_task_state_suspend
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
    FUNCTION update_task_state_execute
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
    FUNCTION update_task_state_finish
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * add an offset quantity to timestamp, according to specified unit
    *
    * @param       i_timestamp               timestamp to add the offset
    * @param       i_lag                     lag time (number to use as an offset)
    * @param       i_unit                    offset's unit (minute, hour, day, week, month)
    *
    * @return      timestamp with time zone  timestamp plus lag offset
    *
    * @author                                Carlos Loureiro
    * @since                                 18-JUN-2010
    ********************************************************************************************/
    FUNCTION add_offset_to_tstz
    (
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_lag       IN tde_task_rel_dependency.lag_min%TYPE,
        i_unit      IN tde_task_rel_dependency.id_unit_measure_lag%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get task dependency schedule mode
    *
    * @param       i_task_dependency              task dependency id
    *
    * @return      varchar2                       dependency is for schedule or not
    *
    * @value       get_task_dependency_schedule   {*} 'Y' task dependency schedule enabled
    *                                             {*} 'N' task dependency schedule disabled
    * 
    * @author                                     Carlos Loureiro
    * @since                                      30-JUN-2010
    ********************************************************************************************/
    FUNCTION get_task_dependency_schedule(i_task_dependency IN task_type.id_task_type%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * returns the task rank 
    *
    * @param    i_tasks_rank     array with all dapendencies sorted by their rank
    * @param    i_dependency     task dependency to check for its rank
    *
    * @return   number           task dependency rank
    *
    * @author                    Tiago Silva
    * @since                     30-JUN-2010
    ********************************************************************************************/
    FUNCTION get_task_rank
    (
        i_tasks_rank IN table_number,
        i_dependency IN NUMBER
    ) RETURN NUMBER;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN table_number;

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
    ) RETURN table_number;

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
    ) RETURN tde_task_dependency.id_task_dependency%TYPE;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- task type dependency types mappings for relationship types (defined in pk_alert_constant)
    -- g_tt_tde_rel_all          CONSTANT task_type.flg_dependency_support%TYPE := 'A';
    -- g_tt_tde_rel_none         CONSTANT task_type.flg_dependency_support%TYPE := 'N';
    -- g_tt_tde_rel_start2start  CONSTANT task_type.flg_dependency_support%TYPE := 'S';
    -- g_tt_tde_rel_finish2start CONSTANT task_type.flg_dependency_support%TYPE := 'F';

    -- task type support (defined in pk_alert_constant)
    -- g_tt_tde_support_task      CONSTANT task_type.flg_episode_task%TYPE := 'T';
    -- g_tt_tde_support_epis      CONSTANT task_type.flg_episode_task%TYPE := 'E';
    -- g_tt_tde_support_task_epis CONSTANT task_type.flg_episode_task%TYPE := 'B';

    -- relationship types (defined in pk_alert_constant)
    -- g_tde_rel_start2start  CONSTANT tde_relationship_type.id_relationship_type%TYPE := 1;
    -- g_tde_rel_finish2start CONSTANT tde_relationship_type.id_relationship_type%TYPE := 2;

    -- tde dependency resolution
    g_tde_dependency_resolved   CONSTANT tde_task_rel_dependency.flg_resolved%TYPE := 'Y';
    g_tde_dependency_unresolved CONSTANT tde_task_rel_dependency.flg_resolved%TYPE := 'N';

    -- tde dependency direction
    g_tde_sucessor_dependencies    CONSTANT VARCHAR2(1) := 'S';
    g_tde_predecessor_dependencies CONSTANT VARCHAR2(1) := 'P';

    -- tde task states
    g_tde_task_state_requested    CONSTANT tde_task_dependency.flg_task_state%TYPE := 'R';
    g_tde_task_state_start_depend CONSTANT tde_task_dependency.flg_task_state%TYPE := 'D';
    g_tde_task_state_started_tde  CONSTANT tde_task_dependency.flg_task_state%TYPE := 'T';
    g_tde_task_state_started_user CONSTANT tde_task_dependency.flg_task_state%TYPE := 'U';
    g_tde_task_state_finished     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'F';
    g_tde_task_state_canceled     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'C';
    g_tde_task_state_suspended    CONSTANT tde_task_dependency.flg_task_state%TYPE := 'S';
    g_tde_task_state_future_sched CONSTANT tde_task_dependency.flg_task_state%TYPE := 'H';

    -- tde transition states
    g_tde_task_trans_finish     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'F';
    g_tde_task_trans_cancel     CONSTANT tde_task_dependency.flg_task_state%TYPE := 'C';
    g_tde_task_trans_suspend    CONSTANT tde_task_dependency.flg_task_state%TYPE := 'S';
    g_tde_task_trans_force_exec CONSTANT tde_task_dependency.flg_task_state%TYPE := 'U';

    -- task types
    g_task_current_epis       CONSTANT task_type.id_task_type%TYPE := -1;
    g_task_future_epis        CONSTANT task_type.id_task_type%TYPE := -2;
    g_task_followup_appoint   CONSTANT task_type.id_task_type%TYPE := 2;
    g_task_specialty_appoint  CONSTANT task_type.id_task_type%TYPE := 3;
    g_task_consult            CONSTANT task_type.id_task_type%TYPE := 4;
    g_task_discharge_instruct CONSTANT task_type.id_task_type%TYPE := 5;
    g_task_image_exam         CONSTANT task_type.id_task_type%TYPE := 7;
    g_task_other_exam         CONSTANT task_type.id_task_type%TYPE := 8;
    g_task_monitoring         CONSTANT task_type.id_task_type%TYPE := 9;
    g_task_procedure          CONSTANT task_type.id_task_type%TYPE := 10;
    g_task_lab_test           CONSTANT task_type.id_task_type%TYPE := 11;
    g_task_local_drug         CONSTANT task_type.id_task_type%TYPE := 13;
    g_task_ext_drug           CONSTANT task_type.id_task_type%TYPE := 15;
    g_task_predef_diet        CONSTANT task_type.id_task_type%TYPE := 22;
    g_task_appoint_social     CONSTANT task_type.id_task_type%TYPE := 28;
    g_task_appoint_nurse      CONSTANT task_type.id_task_type%TYPE := 29;
    g_task_appoint_medical    CONSTANT task_type.id_task_type%TYPE := 30;
    g_task_appoint_nutrition  CONSTANT task_type.id_task_type%TYPE := 31;
    g_task_appoint_psychology CONSTANT task_type.id_task_type%TYPE := 32;
    g_task_appoint_rehabilit  CONSTANT task_type.id_task_type%TYPE := 33;
    g_task_inpatient          CONSTANT task_type.id_task_type%TYPE := 34;
    g_task_inp_surg           CONSTANT task_type.id_task_type%TYPE := 35;
    g_task_inpatient_ptbr     CONSTANT task_type.id_task_type%TYPE := 40;
    g_task_inp_surg_ptbr      CONSTANT task_type.id_task_type%TYPE := 41;

    -- default task dependencies
    g_current_epis_dependency CONSTANT tde_task_dependency.id_task_dependency%TYPE := 0;

    -- check task state update conflict flags
    g_tde_flg_confl_cancel_allow CONSTANT VARCHAR2(1) := 'Y'; -- confirm the cancel action
    g_tde_flg_confl_cancel_deny  CONSTANT VARCHAR2(1) := 'C'; -- cancel action denied  
    g_tde_flg_confl_suspend      CONSTANT VARCHAR2(1) := 'S'; -- confirm the suspend action
    g_tde_flg_confl_force_exec   CONSTANT VARCHAR2(1) := 'F'; -- confirm the forced execution action
    g_tde_flg_confl_none         CONSTANT VARCHAR2(1) := 'N'; -- no conflicts detected

    -- dependencies validation check flags
    g_tde_val_with_conflicts CONSTANT VARCHAR2(1) := 'Y'; -- conflicts detected
    g_tde_val_no_conflicts   CONSTANT VARCHAR2(1) := 'N'; -- no conflicts detected

    -- dependency validation rules
    g_tde_rule_from_to            CONSTANT tde_rule.rule_name%TYPE := 'FROM_TO_VALIDATION';
    g_tde_rule_dependency_support CONSTANT tde_rule.rule_name%TYPE := 'DEPENDENCY_SUPPORT_VALIDATION';
    g_tde_rule_sched_unsched_link CONSTANT tde_rule.rule_name%TYPE := 'SCHEDULED_AND_UNSCHEDULED_TASKS_LINK_VALIDATION';
    g_tde_rule_f2s_dependency     CONSTANT tde_rule.rule_name%TYPE := 'FINISH2START_DEPENDENCY_VALIDATION';
    g_tde_rule_f2s_epis           CONSTANT tde_rule.rule_name%TYPE := 'FINISH2START_DEPENDENCY_EPISODE_VALIDATION';
    g_tde_rule_epis_to_sched      CONSTANT tde_rule.rule_name%TYPE := 'EPISODE_TO_SCHEDULE_VALIDATION';
    g_tde_rule_s2s_dependency     CONSTANT tde_rule.rule_name%TYPE := 'START2START_DEPENDENCY_VALIDATION';
    g_tde_rule_f2s_future_epis_ex CONSTANT tde_rule.rule_name%TYPE := 'FINISH2START_FUTURE_EPISODE_EXCLUSIVE_VALIDATION';
    g_tde_rule_mutually_exclusive CONSTANT tde_rule.rule_name%TYPE := 'MUTUALLY_EXCLUSIVE_VALIDATION';
    g_tde_rule_closed_loop        CONSTANT tde_rule.rule_name%TYPE := 'CLOSED_LOOP_VALIDATION';

    -- lag units
    g_tde_lag_unit_year   CONSTANT unit_measure.id_unit_measure%TYPE := 10373;
    g_tde_lag_unit_month  CONSTANT unit_measure.id_unit_measure%TYPE := 1127;
    g_tde_lag_unit_week   CONSTANT unit_measure.id_unit_measure%TYPE := 10375;
    g_tde_lag_unit_day    CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
    g_tde_lag_unit_hour   CONSTANT unit_measure.id_unit_measure%TYPE := 1041;
    g_tde_lag_unit_minute CONSTANT unit_measure.id_unit_measure%TYPE := 10374;

    -- resume states for tasks that supports suspend action
    g_tde_resume_wait   CONSTANT VARCHAR2(1) := 'W';
    g_tde_resume_start  CONSTANT VARCHAR2(1) := 'S';
    g_tde_resume_normal CONSTANT VARCHAR2(1) := 'N';

    -- dependencies from episodes (code_domain = 'DEPENDENCY_EPISODE')
    g_depend_current_epis       CONSTANT sys_domain.val%TYPE := '-1';
    g_depend_future_epis        CONSTANT sys_domain.val%TYPE := '-2';
    g_dependency_episode_domain CONSTANT sys_domain.code_domain%TYPE := 'DEPENDENCY_EPISODE';

    -- other utility variables
    g_task_desc_separator CONSTANT VARCHAR2(2) := '; ';

    -- general error descriptions
    g_error VARCHAR2(4000);

    -- log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);

END pk_tde;
/
