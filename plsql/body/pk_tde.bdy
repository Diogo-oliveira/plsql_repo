CREATE OR REPLACE PACKAGE BODY pk_tde IS

    -- Purpose : Task Dependency Engine database package

    /********************************************************************************************
    * create combination dependency relationship between 2 different and schedulable tasks (already created)
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
        l_task_dependency_from tde_task_dependency.id_task_dependency%TYPE;
        l_task_dependency_to   tde_task_dependency.id_task_dependency%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
        -- create or re-use "from" task dependecy
        g_error := 'create or re-use "from" task dependecy for task type/request [' || i_task_type_from || ',' ||
                   i_task_request_from || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT create_dependency(i_lang            => i_lang,
                                 i_task_type       => i_task_type_from,
                                 i_task_request    => i_task_request_from,
                                 i_task_state      => g_tde_task_state_future_sched,
                                 i_task_schedule   => pk_alert_constant.g_yes,
                                 o_task_dependency => o_task_dependency_from,
                                 o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- create or re-use "to" task dependecy
        g_error := 'create or re-use "to" task dependecy for task type/request [' || i_task_type_to || ',' ||
                   i_task_request_to || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT create_dependency(i_lang            => i_lang,
                                 i_task_type       => i_task_type_to,
                                 i_task_request    => i_task_request_to,
                                 i_task_state      => g_tde_task_state_future_sched,
                                 i_task_schedule   => pk_alert_constant.g_yes,
                                 o_task_dependency => o_task_dependency_to,
                                 o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- create dependencies relationship
        g_error := 'create dependencies relationship type [' || i_relationship_type || '] from dependency [' ||
                   o_task_dependency_from || '] to dependency [' || o_task_dependency_to || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT create_dependency_relationship(i_lang                 => i_lang,
                                              i_relationship_type    => i_relationship_type,
                                              i_task_dependency_from => o_task_dependency_from,
                                              i_task_dependency_to   => o_task_dependency_to,
                                              i_lag_min              => i_lag_min,
                                              i_lag_max              => i_lag_max,
                                              i_unit_measure_lag     => i_unit_measure_lag,
                                              o_error                => o_error)
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
        l_task_state tde_task_dependency.flg_task_state%TYPE;
    
        -- exception (in package scope) for ORA-01422: exact fetch returns more than requested number of rows
        e_too_many_rows EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_too_many_rows, -01422);
    
        l_exception EXCEPTION;
    
    BEGIN
        -- verify if all dependency relationships can be deleted
        g_error := 'verify if dependencies combination can be deleted or not';
        pk_alertlog.log_debug(g_error, g_package_name);
        BEGIN
            SELECT DISTINCT td.flg_task_state
              INTO l_task_state
              FROM tde_task_dependency td
             WHERE td.id_task_dependency IN (SELECT /*+OPT_ESTIMATE(table d rows=2)*/
                                              column_value
                                               FROM TABLE(i_task_dependency) d);
        EXCEPTION
            WHEN e_too_many_rows THEN
                g_error := 'one or more dependencies cannot be ungrouped';
                RAISE l_exception;
        END;
    
        -- verify if dependencies combination can be ungrouped or not                                           
        IF l_task_state != g_tde_task_state_future_sched
        THEN
            g_error := 'specified dependencies cannot be ungrouped';
            RAISE l_exception;
        END IF;
    
        -- delete task relationships
        g_error := 'delete existing tasks dependency relationships';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM tde_task_rel_dependency
         WHERE (id_relationship_type, id_task_dependency_from, id_task_dependency_to) IN
               (SELECT /*+OPT_ESTIMATE(table d rows=2)*/
                 trd.id_relationship_type, trd.id_task_dependency_from, trd.id_task_dependency_to
                  FROM TABLE(i_task_dependency) d
                  JOIN tde_task_rel_dependency trd
                    ON trd.id_task_dependency_from = d.column_value
                 WHERE trd.id_relationship_type = i_relationship_type
                INTERSECT
                SELECT /*+OPT_ESTIMATE(table d rows=2)*/
                 trd.id_relationship_type, trd.id_task_dependency_from, trd.id_task_dependency_to
                  FROM TABLE(i_task_dependency) d
                  JOIN tde_task_rel_dependency trd
                    ON trd.id_task_dependency_to = d.column_value
                 WHERE trd.id_relationship_type = i_relationship_type);
    
        -- TODO: maintain relationships history tracking?
    
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
        l_flg_dependency_support task_type.flg_dependency_support%TYPE;
    
    BEGIN
        -- check if given task type supports any kind of dependency relationship
        SELECT tt.flg_dependency_support
          INTO l_flg_dependency_support
          FROM task_type tt
         WHERE tt.id_task_type = i_task_type;
        IF l_flg_dependency_support = pk_alert_constant.g_tt_tde_rel_none
        THEN
            g_error := 'cannot create task dependency: task type [' || i_task_type ||
                       '] doesn''t support dependendcy relationships';
            RAISE l_exception;
        END IF;
    
        -- check if given i_task_state start task mode is allowed for dependency creation
        IF i_task_state NOT IN
           (g_tde_task_state_requested, g_tde_task_state_start_depend, g_tde_task_state_future_sched)
        THEN
            g_error := 'starting task mode/state [' || i_task_state || '] is not allowed in dependency creation';
            RAISE l_exception;
        END IF;
    
        -- check if task type/request already have an associated dependency
        -- if the task type/request already exists, no new dependency will be created and no data will be affected
        BEGIN
            SELECT td.id_task_dependency
              INTO o_task_dependency
              FROM tde_task_dependency td
             WHERE td.id_task_type = i_task_type
               AND td.id_task_request = nvl(i_task_request, -1);
        
            g_error := 'existing task dependency [' || o_task_dependency || '] will be considered';
            pk_alertlog.log_debug(g_error, g_package_name);
        
        EXCEPTION
            WHEN no_data_found THEN
                -- new dependency is needed
                g_error := 'new id_task_dependency will be created';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                INSERT INTO tde_task_dependency
                    (id_task_dependency, id_task_type, id_task_request, flg_task_state, flg_schedule)
                VALUES
                    (seq_tde_task_dependency.nextval, i_task_type, i_task_request, i_task_state, i_task_schedule)
                RETURNING id_task_dependency INTO o_task_dependency;
            
                -- insert firt history record for this new dependency
                INSERT INTO tde_task_dependency_hist
                    (id_task_dependency_hist, id_task_dependency, flg_task_state, change_timestamp)
                VALUES
                    (seq_tde_task_dependency_hist.nextval, o_task_dependency, i_task_state, current_timestamp);
            
        END;
    
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
        l_count NUMBER;
        l_exception EXCEPTION;
    
    BEGIN
        -- check if given task type/request already exists in the database with other depedency association
        SELECT COUNT(1)
          INTO l_count
          FROM tde_task_dependency td
         WHERE td.id_task_type = i_task_type
           AND td.id_task_request = i_task_request
           AND td.id_task_dependency != i_task_dependency;
    
        -- no other dependency is using the task type/request about to be updated here
        IF l_count = 0
        THEN
            -- update dependency information (task
            g_error := 'update task dependency [' || i_task_dependency || '] to type [' || i_task_type ||
                       '] and request [' || i_task_request || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            UPDATE tde_task_dependency td
               SET td.id_task_request = i_task_request, td.id_task_type = i_task_type
             WHERE td.id_task_dependency = i_task_dependency;
        
            -- note: no history record is needed because none of the update fields are being tracked 
        
        ELSE
            g_error := 'task type/request [' || i_task_type || ',' || i_task_request ||
                       '] already exists in the database with other depedency association';
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
            pk_utils.undo_changes;
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
        l_temp table_number;
        l_exception EXCEPTION;
    
    BEGIN
        -- check lag min <= lag max condition
        IF i_lag_min > i_lag_max
        THEN
            g_error := 'error found while evaluating the condition "maximum lag time should always be greater or equal than minimum lag time"';
            RAISE l_exception;
        END IF;
    
        -- insert new tasks relationship
        g_error := 'insert new relationship between from/to dependencies';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        INSERT INTO tde_task_rel_dependency
            (id_relationship_type,
             id_task_dependency_from,
             id_task_dependency_to,
             lag_min,
             lag_max,
             id_unit_measure_lag,
             flg_resolved)
        VALUES
            (i_relationship_type,
             i_task_dependency_from,
             i_task_dependency_to,
             i_lag_min,
             i_lag_max,
             i_unit_measure_lag,
             decode(get_task_dependency_schedule(i_task_dependency_from),
                    pk_alert_constant.g_yes,
                    g_tde_dependency_resolved,
                    decode(get_task_dependency_schedule(i_task_dependency_to),
                           pk_alert_constant.g_yes,
                           g_tde_dependency_resolved,
                           g_tde_dependency_unresolved)));
        -- dependency relationships are always created as unresolved, except is one of the dependencies is for schedule
    
        -- check closed loop dependencies cycle validation
        g_error := 'check closed loop dependencies cycle with inserted record';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT 1
          BULK COLLECT
          INTO l_temp -- dummy var to get all rows from below query to catch "ORA-01436: connect by loop" exception
          FROM tde_task_rel_dependency drl
         START WITH drl.id_task_dependency_from = i_task_dependency_from
                AND drl.id_relationship_type = i_relationship_type
        CONNECT BY PRIOR drl.id_task_dependency_to = drl.id_task_dependency_from
               AND drl.id_relationship_type = i_relationship_type;
    
        -- TODO: maintain relationships history tracking?
    
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
        -- check lag min <= lag max condition
        IF i_lag_min > i_lag_max
        THEN
            g_error := 'error found while evaluating the condition "maximum lag time should always be greater or equal than minimum lag time"';
            RAISE l_exception;
        END IF;
    
        -- update task dependencies relationship lag times/units
        g_error := 'update existing tasks dependency relationships';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE tde_task_rel_dependency trd
           SET trd.lag_min = i_lag_min, trd.lag_max = i_lag_max, trd.id_unit_measure_lag = i_unit_measure_lag
         WHERE trd.id_relationship_type = i_relationship_type
           AND trd.id_task_dependency_from = i_task_dependency_from
           AND trd.id_task_dependency_to = i_task_dependency_to;
    
        -- if no row was affected, then given from/to dependency with required relationship type does not exist
        IF SQL%ROWCOUNT = 0
        THEN
            g_error := 'task dependency from/to [' || i_task_dependency_from || ',' || i_task_dependency_to ||
                       '] with relationship type [' || i_relationship_type || '] does not exist';
            RAISE l_exception;
        
        END IF;
    
        -- TODO: maintain relationships history tracking?
    
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
    BEGIN
    
        -- TODO: implement delete_dependency_relationship code
    
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
    * get available validation rule names
    *
    * @param       i_lang                  preferred language id    
    * @param       i_flg_dependency_option task dependency id
    * @param       o_rules                 array with enabled rule names
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false    
    *
    * @author                              Carlos Loureiro
    * @since                               23-JUN-2010
    ********************************************************************************************/
    FUNCTION get_validation_rules
    (
        i_lang                  IN language.id_language%TYPE,
        i_flg_dependency_option IN VARCHAR2,
        o_rules                 OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get rules (dependency option [' || i_flg_dependency_option || '])';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT rule_name
          BULK COLLECT
          INTO o_rules
          FROM tde_rule r
         WHERE r.flg_available = pk_alert_constant.g_yes
           AND r.flg_validate_option = i_flg_dependency_option;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VALIDATION_RULES',
                                              o_error);
            RETURN FALSE;
        
    END get_validation_rules;

    /********************************************************************************************
    * set task type information for dependency handling
    *
    * @param       i_task_type             task type id
    * @param       o_flg_depend_support    dependency support flag for given task type
    * @param       o_flg_epis_task         episode/task flag for given task type
    *
    * @author                              Carlos Loureiro
    * @since                               23-JUN-2010
    ********************************************************************************************/
    PROCEDURE set_task_type_info
    (
        i_task_type          IN task_type.id_task_type%TYPE,
        o_flg_depend_support OUT task_type.flg_dependency_support%TYPE,
        o_flg_epis_task      OUT task_type.flg_episode_task%TYPE
    ) IS
    BEGIN
    
        SELECT flg_dependency_support, flg_episode_task
          INTO o_flg_depend_support, o_flg_epis_task
          FROM task_type
         WHERE id_task_type = i_task_type;
    
    END set_task_type_info;

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
    FUNCTION get_task_dependency_schedule(i_task_dependency IN task_type.id_task_type%TYPE) RETURN VARCHAR2 IS
        l_flg_schedule tde_task_dependency.flg_schedule%TYPE;
    BEGIN
        SELECT flg_schedule
          INTO l_flg_schedule
          FROM tde_task_dependency
         WHERE id_task_dependency = i_task_dependency;
        RETURN l_flg_schedule;
    END get_task_dependency_schedule;

    /********************************************************************************************
    * set conflict messages based in rule name
    *
    * @param       i_lang                  preferred language id
    * @param       i_rule                  rule name
    * @param       o_msg_title             conflict message title
    * @param       o_msg_body              conflict message body
    *
    * @author                              Carlos Loureiro
    * @since                               24-JUN-2010
    ********************************************************************************************/
    PROCEDURE set_conflict_messages
    (
        i_lang      IN language.id_language%TYPE,
        i_rule      IN tde_rule.rule_name%TYPE,
        o_msg_title OUT VARCHAR2,
        o_msg_body  OUT VARCHAR2
    ) IS
    BEGIN
        SELECT pk_message.get_message(i_lang, r.conflict_code_message_title),
               pk_message.get_message(i_lang, r.conflict_code_message_body)
          INTO o_msg_title, o_msg_body
          FROM tde_rule r
         WHERE r.rule_name = i_rule;
    END set_conflict_messages;

    /********************************************************************************************
    * set task type information for dependency handling
    *
    * @param       i_lang                       preferred language id    
    * @param       i_relationship_type          array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from       array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to         array of task dependencies for the tasks where the dependency goes to    
    * @param       i_task_type_from             array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to               array of task types for the tasks where the dependency goes to
    * @param       i_task_schedule_from         array of tasks where the dependency comes from, to schedule or not
    * @param       i_task_schedule_to           array of tasks where the dependency goes to, to schedule or not
    * @param       i_lag_min                    array of minimum lags per relationship
    * @param       i_lag_max                    array of maximum lags per relationship
    * @param       i_unit_measure_lag           array of lag's unit measure id per relationship
    * @param       i_chk_rel_type               dependency relationship type to check for conflicts
    * @param       i_chk_task_depend_from       task dependency to check for (for the tasks where the dependency comes from)
    * @param       i_chk_task_depend_to         task dependency to check for (for the tasks where the dependency goes to)
    * @param       i_chk_tsk_type_from          task type to check for (for the tasks where the dependency comes from)
    * @param       i_chk_tsk_type_to            task type to check for (for the tasks where the dependency goes to)
    * @param       i_chk_task_schedule_from     task to check for schedule flag, where the dependency comes from
    * @param       i_chk_task_schedule_to       task to check for schedule flag, where the dependency goes to
    * @param       i_chk_lag_min                minimum lags to check for
    * @param       i_chk_lag_max                maximum lags to check for
    * @param       i_chk_unit_measure_lag       lag's unit measure id to check for
    * @param       o_dtbl                       table of dependencies network    
    * @param       o_error                      error structure for exception handling
    *
    * @return      boolean                      true on success, otherwise false    
    *
    * @author                                   Carlos Loureiro
    * @since                                    24-JUN-2010
    ********************************************************************************************/
    FUNCTION set_dependencies_network
    (
        i_lang                   IN language.id_language%TYPE,
        i_relationship_type      IN table_number,
        i_task_dependency_from   IN table_number,
        i_task_dependency_to     IN table_number,
        i_task_type_from         IN table_number,
        i_task_type_to           IN table_number,
        i_task_schedule_from     IN table_varchar,
        i_task_schedule_to       IN table_varchar,
        i_lag_min                IN table_number DEFAULT NULL,
        i_lag_max                IN table_number DEFAULT NULL,
        i_unit_measure_lag       IN table_number DEFAULT NULL,
        i_chk_rel_type           IN tde_relationship_type.id_relationship_type%TYPE DEFAULT NULL,
        i_chk_task_depend_from   IN NUMBER DEFAULT NULL,
        i_chk_task_depend_to     IN NUMBER DEFAULT NULL,
        i_chk_task_type_from     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_chk_task_type_to       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_chk_task_schedule_from IN VARCHAR2 DEFAULT NULL,
        i_chk_task_schedule_to   IN VARCHAR2 DEFAULT NULL,
        i_chk_lag_min            IN tde_task_rel_dependency.lag_min%TYPE DEFAULT NULL,
        i_chk_lag_max            IN tde_task_rel_dependency.lag_max%TYPE DEFAULT NULL,
        i_chk_unit_measure_lag   IN tde_task_rel_dependency.id_unit_measure_lag%TYPE DEFAULT NULL,
        o_dtbl                   OUT t_tbl_tde_depend_rel_list,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drec t_rec_tde_depend_rel_list := t_rec_tde_depend_rel_list(NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL);
    BEGIN
        -- init o_dtbl table collection
        o_dtbl := t_tbl_tde_depend_rel_list();
    
        -- process dependencies into l_dtbl    
        g_error := 'process dependencies into table of records';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR i IN 1 .. i_task_dependency_from.count
        LOOP
            l_drec.id_relationship_type    := i_relationship_type(i);
            l_drec.id_task_dependency_from := i_task_dependency_from(i);
            l_drec.id_task_dependency_to   := i_task_dependency_to(i);
            l_drec.id_task_type_from       := i_task_type_from(i);
            set_task_type_info(i_task_type          => l_drec.id_task_type_from,
                               o_flg_depend_support => l_drec.flg_depend_support_from,
                               o_flg_epis_task      => l_drec.flg_episode_task_from);
            l_drec.id_task_type_to := i_task_type_to(i);
            set_task_type_info(i_task_type          => l_drec.id_task_type_to,
                               o_flg_depend_support => l_drec.flg_depend_support_to,
                               o_flg_epis_task      => l_drec.flg_episode_task_to);
            l_drec.flg_schedule_from := i_task_schedule_from(i);
            l_drec.flg_schedule_to   := i_task_schedule_to(i);
            IF i_unit_measure_lag IS NOT NULL
            THEN
                l_drec.lag_min             := i_lag_min(i);
                l_drec.lag_max             := i_lag_max(i);
                l_drec.id_unit_measure_lag := i_unit_measure_lag(i);
            END IF;
            o_dtbl.extend;
            o_dtbl(i) := l_drec;
        
        END LOOP;
    
        -- add "check for conflicts" record to collection
        IF i_chk_rel_type IS NOT NULL
        THEN
            l_drec.id_relationship_type    := i_chk_rel_type;
            l_drec.id_task_dependency_from := i_chk_task_depend_from;
            l_drec.id_task_dependency_to   := i_chk_task_depend_to;
            l_drec.id_task_type_from       := i_chk_task_type_from;
            set_task_type_info(i_task_type          => l_drec.id_task_type_from,
                               o_flg_depend_support => l_drec.flg_depend_support_from,
                               o_flg_epis_task      => l_drec.flg_episode_task_from);
            l_drec.id_task_type_to := i_chk_task_type_to;
            set_task_type_info(i_task_type          => l_drec.id_task_type_to,
                               o_flg_depend_support => l_drec.flg_depend_support_to,
                               o_flg_epis_task      => l_drec.flg_episode_task_to);
            l_drec.flg_schedule_from := i_chk_task_schedule_from;
            l_drec.flg_schedule_to   := i_chk_task_schedule_to;
            IF i_chk_unit_measure_lag IS NOT NULL
            THEN
                l_drec.lag_min             := i_chk_lag_min;
                l_drec.lag_max             := i_chk_lag_max;
                l_drec.id_unit_measure_lag := i_chk_unit_measure_lag;
            END IF;
            o_dtbl.extend;
            o_dtbl(o_dtbl.count) := l_drec;
        
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
                                              'SET_DEPENDENCIES_NETWORK',
                                              o_error);
            RETURN FALSE;
        
    END set_dependencies_network;

    /********************************************************************************************
    * check if a table_varchar collections containts the indicated value
    *
    * @param       i_col                   preferred language id    
    * @param       i_value                 value to check for 
    *
    * @return      boolean                 true if value was found, otherwise false    
    *
    * @author                              Carlos Loureiro
    * @since                               23-JUN-2010
    ********************************************************************************************/
    FUNCTION collection_contains
    (
        i_col   IN table_varchar,
        i_value IN VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_col.count > 0
        THEN
            FOR i IN i_col.first .. i_col.last
            LOOP
                IF i_col(i) = i_value
                THEN
                    RETURN TRUE;
                END IF;
            END LOOP;
        END IF;
        RETURN FALSE;
    END collection_contains;

    /********************************************************************************************
    * check if a table_varchar collections containts the indicated value
    *
    * @param       i_col                   preferred language id    
    * @param       i_value                 value to check for 
    *
    * @return      boolean                 true if value was found, otherwise false    
    *
    * @author                              Carlos Loureiro
    * @since                               23-JUN-2010
    ********************************************************************************************/
    FUNCTION get_episode_from_task
    (
        i_task_dependency IN NUMBER,
        i_dtbl            IN t_tbl_tde_depend_rel_list
    ) RETURN NUMBER IS
        l_dependency NUMBER;
    
    BEGIN
        -- get "contained in" episode from task, using task's start2start relationship
        -- if id_task_dependency_from's task type represents the current episode, then return default value (zero)
        SELECT decode(d.id_task_type_from,
                      pk_alert_constant.g_task_current_epis,
                      g_current_epis_dependency,
                      d.id_task_dependency_from)
          INTO l_dependency
          FROM TABLE(CAST(i_dtbl AS t_tbl_tde_depend_rel_list)) d
         WHERE d.id_task_dependency_to = i_task_dependency
           AND d.id_relationship_type = pk_alert_constant.g_tde_rel_start2start;
    
        RETURN l_dependency;
    
    EXCEPTION
        -- when no "contained in" relation was found, the task is in current episode
        WHEN no_data_found THEN
            RETURN g_current_epis_dependency;
        
    END get_episode_from_task;

    /********************************************************************************************
    * validate dependency rules
    *
    * @param       i_lang                  preferred language id    
    * @param       i_dtbl                  table with dependencies network
    * @param       i_flg_dependency_option flag that indicates if the rule is applied for each option
    * @param       o_flg_conflict          conflict flag
    * @param       o_msg_title             pop up message title for warnings
    * @param       o_msg_body              pop up message body for warnings
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false    
    *
    * @value       i_flg_dependency_option {*} 'Y' validation will be made for each dependency option
    *                                      {*} 'N' validation will be made for all dependencies network
    *
    * @value       o_flg_conflict          {*} 'Y' conflict detected
    *                                      {*} 'N' No conflicts detected
    *
    * @author                              Carlos Loureiro
    * @since                               14-JUN-2010
    ********************************************************************************************/
    FUNCTION validate_rules
    (
        i_lang                  IN language.id_language%TYPE,
        i_dtbl                  IN t_tbl_tde_depend_rel_list,
        i_flg_dependency_option IN VARCHAR2,
        o_flg_conflict          OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg_body              OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp                    table_number;
        l_rules                   table_varchar;
        b_validation_ok           BOOLEAN := TRUE;
        l_id_task_dependency_from tde_task_dependency.id_task_dependency%TYPE;
        l_id_task_dependency_to   tde_task_dependency.id_task_dependency%TYPE;
    
        -- validation rules booleans;
        b_from_to            BOOLEAN;
        b_dependency_support BOOLEAN;
        b_sched_unsched_link BOOLEAN;
        b_f2s_dependency     BOOLEAN;
        b_f2s_epis           BOOLEAN;
        b_epis_to_sched      BOOLEAN;
        b_s2s_dependency     BOOLEAN;
        b_mutually_exclusive BOOLEAN;
        b_f2s_future_epis_ex BOOLEAN;
        b_closed_loop        BOOLEAN;
    
        -- exception (in package scope) for ORA-01436: connect by loop in user data
        e_connect_by_loop EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_connect_by_loop, -01436);
    
        -- other exceptions
        l_exception EXCEPTION;
    
    BEGIN
        -- get available rules  
        IF NOT get_validation_rules(i_lang                  => i_lang,
                                    i_flg_dependency_option => i_flg_dependency_option,
                                    o_rules                 => l_rules,
                                    o_error                 => o_error)
        THEN
            g_error := 'errors found while calling get_validation_rules function';
            RAISE l_exception;
        ELSE
            b_from_to            := collection_contains(l_rules, g_tde_rule_from_to);
            b_dependency_support := collection_contains(l_rules, g_tde_rule_dependency_support);
            b_sched_unsched_link := collection_contains(l_rules, g_tde_rule_sched_unsched_link);
            b_f2s_dependency     := collection_contains(l_rules, g_tde_rule_f2s_dependency);
            b_f2s_epis           := collection_contains(l_rules, g_tde_rule_f2s_epis);
            b_epis_to_sched      := collection_contains(l_rules, g_tde_rule_epis_to_sched);
            b_s2s_dependency     := collection_contains(l_rules, g_tde_rule_s2s_dependency);
            b_mutually_exclusive := collection_contains(l_rules, g_tde_rule_mutually_exclusive);
            b_f2s_future_epis_ex := collection_contains(l_rules, g_tde_rule_f2s_future_epis_ex);
            b_closed_loop        := collection_contains(l_rules, g_tde_rule_closed_loop);
        END IF;
    
        -- process all dependency network records
        <<validate_rules_main_loop>>
        FOR i IN i_dtbl.first .. i_dtbl.last
        LOOP
            -- #################################          
            -- ## run FROM_TO_VALIDATION rule ##
            -- #################################          
            IF b_from_to
            THEN
                -- from/to dependency cannot be the same deppendency
                IF i_dtbl(i).id_task_dependency_from = i_dtbl(i).id_task_dependency_to
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_from_to,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(o_msg_body, '@1', '@[' || i_dtbl(i).id_task_dependency_from || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop
                END IF;
            END IF;
        
            -- ############################################
            -- ## run DEPENDENCY_SUPPORT_VALIDATION rule ##
            -- ############################################            
            IF b_dependency_support
            THEN
                -- both "from"/"to" dependencies must support any type of dependency
                IF i_dtbl(i).flg_depend_support_from = pk_alert_constant.g_tt_tde_rel_none
                    OR i_dtbl(i).flg_depend_support_to = pk_alert_constant.g_tt_tde_rel_none
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_dependency_support,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(o_msg_body,
                                              '@1',
                                              '@[' || CASE i_dtbl(i).flg_depend_support_from
                                                  WHEN pk_alert_constant.g_tt_tde_rel_none THEN
                                                   i_dtbl(i).id_task_dependency_from
                                                  ELSE
                                                   i_dtbl(i).id_task_dependency_to
                                              END || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                    
                END IF;
            END IF;
        
            -- ##############################################################
            -- ## run SCHEDULED_AND_UNSCHEDULED_TASKS_LINK_VALIDATION rule ##
            -- ##############################################################
            IF b_sched_unsched_link
            THEN
                -- no tasks to schedule can have finish-2-start relations to tasks that cannot be scheduled and vice-versa
                IF (i_dtbl(i).id_relationship_type = pk_alert_constant.g_tde_rel_finish2start)
                   AND (i_dtbl(i).flg_schedule_from != i_dtbl(i).flg_schedule_to)
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_sched_unsched_link,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(REPLACE(o_msg_body,
                                                      '@1',
                                                      '@[' || i_dtbl(i).id_task_dependency_from || ']'),
                                              '@2',
                                              '@[' || i_dtbl(i).id_task_dependency_to || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                                                 
                END IF;
            END IF;
        
            -- #################################################
            -- ## run FINISH2START_DEPENDENCY_VALIDATION rule ##
            -- #################################################
            IF b_f2s_dependency
            THEN
                -- if relation is finish-to-start, both "from"/"to" dependencies must support finish-2-start relations
                IF (i_dtbl(i).id_relationship_type = pk_alert_constant.g_tde_rel_finish2start)
                   AND ((i_dtbl(i).flg_depend_support_from NOT IN
                    (pk_alert_constant.g_tt_tde_rel_all, pk_alert_constant.g_tt_tde_rel_finish2start)) OR
                   (i_dtbl(i).flg_depend_support_to NOT IN
                    (pk_alert_constant.g_tt_tde_rel_all, pk_alert_constant.g_tt_tde_rel_finish2start)))
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_f2s_dependency,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(REPLACE(o_msg_body,
                                                      '@1',
                                                      '@[' || i_dtbl(i).id_task_dependency_from || ']'),
                                              '@2',
                                              '@[' || i_dtbl(i).id_task_dependency_to || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                                                 
                END IF;
            END IF;
        
            -- #########################################################
            -- ## run FINISH2START_DEPENDENCY_EPISODE_VALIDATION rule ##
            -- #########################################################
            IF b_f2s_epis
            THEN
                -- if relation is finish-to-start, both "from"/"to" non-schedulable dependencies 
                -- must be included in the same episode
                IF (i_dtbl(i).id_relationship_type = pk_alert_constant.g_tde_rel_finish2start)
                   AND (i_dtbl(i).flg_schedule_from = pk_alert_constant.g_no)
                   AND (i_dtbl(i).flg_schedule_to = pk_alert_constant.g_no)
                   AND (get_episode_from_task(i_dtbl(i).id_task_dependency_from, i_dtbl) !=
                   get_episode_from_task(i_dtbl(i).id_task_dependency_to, i_dtbl))
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_f2s_epis,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(REPLACE(o_msg_body,
                                                      '@1',
                                                      '@[' || i_dtbl(i).id_task_dependency_from || ']'),
                                              '@2',
                                              '@[' || i_dtbl(i).id_task_dependency_to || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                                                 
                END IF;
            END IF;
        
            -- #############################################
            -- ## run EPISODE_TO_SCHEDULE_VALIDATION rule ##
            -- #############################################
            IF b_epis_to_sched
            THEN
                -- an episode must be "schedulable"
                IF ((i_dtbl(i).flg_episode_task_from = pk_alert_constant.g_tt_tde_support_epis) AND
                   (i_dtbl(i).flg_schedule_from = pk_alert_constant.g_no))
                   OR ((i_dtbl(i).flg_episode_task_to = pk_alert_constant.g_tt_tde_support_epis) AND
                   (i_dtbl(i).flg_schedule_to = pk_alert_constant.g_no))
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_epis_to_sched,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        IF (i_dtbl(i).flg_episode_task_from = pk_alert_constant.g_tt_tde_support_epis)
                           AND (i_dtbl(i).flg_schedule_from = pk_alert_constant.g_no)
                        THEN
                            o_msg_body := REPLACE(o_msg_body, '@1', '@[' || i_dtbl(i).id_task_dependency_from || ']');
                        ELSE
                            o_msg_body := REPLACE(o_msg_body, '@1', '@[' || i_dtbl(i).id_task_dependency_to || ']');
                        END IF;
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                    
                END IF;
            END IF;
        
            -- ################################################
            -- ## run START2START_DEPENDENCY_VALIDATION rule ##
            -- ################################################
            IF b_s2s_dependency
            THEN
                -- when contained in episodes, "from" dependency must be an episode and "to" dependency cannot be a schedulable task
                IF (i_dtbl(i).id_relationship_type = pk_alert_constant.g_tde_rel_start2start)
                   AND ((i_dtbl(i).flg_episode_task_from != pk_alert_constant.g_tt_tde_support_epis) OR
                   (i_dtbl(i).flg_episode_task_to = pk_alert_constant.g_tt_tde_support_epis) OR
                   ((i_dtbl(i).id_task_type_from != g_task_future_epis) AND
                   (i_dtbl(i).flg_schedule_to = pk_alert_constant.g_yes)) OR
                   (i_dtbl(i).flg_depend_support_to NOT IN
                    (pk_alert_constant.g_tt_tde_rel_all, pk_alert_constant.g_tt_tde_rel_start2start)))
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_s2s_dependency,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                        o_msg_body := REPLACE(REPLACE(o_msg_body, '@1', '@[' || i_dtbl(i).id_task_dependency_to || ']'),
                                              '@2',
                                              '@[' || i_dtbl(i).id_task_dependency_from || ']');
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                                                 
                END IF;
            END IF;
        
            -- ###############################################################
            -- ## run FINISH2START_FUTURE_EPISODE_EXCLUSIVE_VALIDATION rule ##
            -- ###############################################################
            IF b_f2s_future_epis_ex
            THEN
                -- no f2s relations can exists from/to -2 task types (future episodes)
                IF ((i_dtbl(i).id_relationship_type = pk_alert_constant.g_tde_rel_finish2start) AND
                   ((i_dtbl(i).id_task_type_from = g_task_future_epis) OR
                   (i_dtbl(i).id_task_type_to = g_task_future_epis)))
                THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_f2s_future_epis_ex,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                    END IF;
                    b_validation_ok := FALSE;
                    EXIT validate_rules_main_loop; -- break for loop                                                 
                END IF;
            END IF;
        
        END LOOP;
        -- <<validate_rules_main_loop>> ended
    
        -- ############################################
        -- ## run MUTUALLY_EXCLUSIVE_VALIDATION rule ##
        -- ############################################            
        IF b_validation_ok
           AND b_mutually_exclusive
        THEN
            -- try to find "from/to" duplicates contained in the dependencies collections
            BEGIN
                SELECT id_task_dependency_from, id_task_dependency_to
                  INTO l_id_task_dependency_from, l_id_task_dependency_to
                  FROM (SELECT id_task_dependency_from, id_task_dependency_to
                          FROM TABLE(CAST(i_dtbl AS t_tbl_tde_depend_rel_list)) drl
                         GROUP BY id_task_dependency_from, id_task_dependency_to
                        HAVING COUNT(1) > 1)
                 WHERE rownum = 1;
            
                -- if "from/to" dependency variables are filled, create conflict message if not working in dependency options
                IF i_flg_dependency_option = pk_alert_constant.g_no
                THEN
                    set_conflict_messages(i_lang      => i_lang,
                                          i_rule      => g_tde_rule_mutually_exclusive,
                                          o_msg_title => o_msg_title,
                                          o_msg_body  => o_msg_body);
                    o_msg_body := REPLACE(REPLACE(o_msg_body, '@1', '@[' || l_id_task_dependency_from || ']'),
                                          '@2',
                                          '@[' || l_id_task_dependency_to || ']');
                END IF;
                b_validation_ok := FALSE;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- no "from/to" duplicate keys found
            END;
        END IF;
    
        -- #######################################
        -- ### run CLOSED_LOOP_VALIDATION rule ###
        -- #######################################
        IF b_validation_ok
           AND b_closed_loop
        THEN
            -- check for closed-loop dependencies for all start-2-finish relations
            g_error := 'check for closed-loop dependencies';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- block code to test if "ORA-01436: CONNECT BY loop in user data" exception occurs (closed loop validation)
            BEGIN
                SELECT 1
                  BULK COLLECT
                  INTO l_temp -- dummy var to get all rows from below query to catch "connect by loop" exception
                  FROM TABLE(CAST(i_dtbl AS t_tbl_tde_depend_rel_list)) drl
                CONNECT BY PRIOR drl.id_task_dependency_to = drl.id_task_dependency_from
                       AND drl.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start;
            
            EXCEPTION
                -- closed-loop cycle detected: incompatibilities were found
                WHEN e_connect_by_loop THEN
                    -- create conflict message if not working in dependency options
                    IF i_flg_dependency_option = pk_alert_constant.g_no
                    THEN
                        set_conflict_messages(i_lang      => i_lang,
                                              i_rule      => g_tde_rule_closed_loop,
                                              o_msg_title => o_msg_title,
                                              o_msg_body  => o_msg_body);
                    END IF;
                    b_validation_ok := FALSE;
            END;
        END IF;
    
        -- conflict messages are empty if function is executed without changes in o_flg_conflict variable
        o_flg_conflict := CASE b_validation_ok
                              WHEN TRUE THEN
                               g_tde_val_no_conflicts
                              ELSE
                               g_tde_val_with_conflicts
                          END;
    
        -- debug conflict messages (remove this before versioning)
        -- dbms_output.put_line(o_msg_title);
        -- dbms_output.put_line(o_msg_body);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'VALIDATE_RULES',
                                              o_error);
            RETURN FALSE;
        
    END validate_rules;

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
        l_dtbl t_tbl_tde_depend_rel_list;
        l_exception EXCEPTION;
        PRAGMA AUTONOMOUS_TRANSACTION;
    
    BEGIN
        -- check lag min <= lag max condition
        FOR i IN 1 .. i_lag_min.count()
        LOOP
            IF i_lag_min(i) > i_lag_max(i)
            THEN
                g_error := 'error found while evaluating the condition "maximum lag time should always be greater or equal than minimum lag time"';
                RAISE l_exception;
            END IF;
        END LOOP;
    
        -- process dependencies into l_dtbl table collection    
        IF NOT set_dependencies_network(i_lang                 => i_lang,
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
                                        o_dtbl                 => l_dtbl,
                                        o_error                => o_error)
        THEN
            g_error := 'error found while calling set_dependencies_network';
            RAISE l_exception;
        END IF;
    
        -- validate all dependency network records
        IF NOT validate_rules(i_lang                  => i_lang,
                              i_dtbl                  => l_dtbl,
                              i_flg_dependency_option => pk_alert_constant.g_no,
                              o_flg_conflict          => o_flg_conflict,
                              o_msg_title             => o_msg_title,
                              o_msg_body              => o_msg_body,
                              o_error                 => o_error)
        THEN
            g_error := 'error found while calling validate_rules';
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
        l_error        t_error_out;
        l_dtbl         t_tbl_tde_depend_rel_list;
        l_flg_conflict VARCHAR2(1);
        l_msg_title    VARCHAR2(1000 CHAR);
        l_msg_body     VARCHAR2(1000 CHAR);
    
        l_exception EXCEPTION;
    
    BEGIN
        -- process dependencies into l_dtbl table collection    
        IF NOT set_dependencies_network(i_lang                   => i_lang,
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
                                        i_chk_task_schedule_to   => i_chk_task_schedule_to,
                                        o_dtbl                   => l_dtbl,
                                        o_error                  => l_error)
        THEN
            g_error := 'error found while calling set_dependencies_network: ' || l_error.err_desc;
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        END IF;
    
        -- validate all dependency network records
        IF NOT validate_rules(i_lang                  => i_lang,
                              i_dtbl                  => l_dtbl,
                              i_flg_dependency_option => pk_alert_constant.g_yes,
                              o_flg_conflict          => l_flg_conflict,
                              o_msg_title             => l_msg_title,
                              o_msg_body              => l_msg_body,
                              o_error                 => l_error)
        THEN
            g_error := 'error found while calling validate_rules: ' || l_error.err_desc;
            pk_alertlog.log_error(g_error, g_package_name);
            RAISE l_exception;
        END IF;
    
        RETURN CASE l_flg_conflict WHEN g_tde_val_no_conflicts THEN pk_alert_constant.g_yes ELSE pk_alert_constant.g_no END;
    
        -- when an exception occurs, then provided option cannot be used
        --EXCEPTION
        --    WHEN OTHERS THEN
        --        RETURN pk_alert_constant.g_no;
    
    END validate_dependency_option;

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
    BEGIN
        g_error := 'get predecessor task dependencies for [' || i_task_dependency || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_dependencies FOR
            SELECT trd.id_task_dependency_from,
                   trd.flg_resolved,
                   get_task_description(i_lang, i_prof, td.id_task_type, td.id_task_request) task_desc
              FROM tde_task_rel_dependency trd
              JOIN tde_task_dependency td
                ON td.id_task_dependency = trd.id_task_dependency_from
             WHERE trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
               AND trd.id_task_dependency_to = i_task_dependency
             ORDER BY task_desc;
    
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
            pk_types.open_my_cursor(o_dependencies);
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
        l_dependencies    pk_types.cursor_type;
        l_task_dependency table_number;
        l_flg_resolved    table_varchar;
        l_task_desc       table_varchar;
        l_error           t_error_out;
    
        l_exception EXCEPTION;
    BEGIN
        -- get all predecessor task dependencies for i_task_dependency
        IF NOT get_task_dependencies(i_lang, i_prof, i_task_dependency, l_dependencies, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- fetch all dependencies into l_task_desc (the other collections will be discarded)
        FETCH l_dependencies BULK COLLECT
            INTO l_task_dependency, l_flg_resolved, l_task_desc;
        CLOSE l_dependencies;
    
        -- concatenate all dependencies to fit in one single lined string
        RETURN pk_utils.concat_table(l_task_desc, g_task_desc_separator);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Could not get dependencies task descriptions: ' || l_error.err_desc;
        
    END get_task_depend_str;

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
    ) RETURN VARCHAR2 IS
        l_task_desc   VARCHAR2(1000 CHAR);
        l_status_desc VARCHAR2(1000 CHAR);
        l_error       t_error_out;
        l_exception EXCEPTION;
    
        -- function used to get episode description
        PROCEDURE get_episode_desc
        (
            i_episode     IN episode.id_episode%TYPE,
            o_epis_desc   OUT VARCHAR2,
            o_status_desc OUT sys_domain.desc_val%TYPE
        ) IS
        
            l_epis_desc   VARCHAR2(1000 CHAR);
            l_status_desc sys_domain.desc_val%TYPE;
        
            l_future_event pk_types.cursor_type;
            l_patient      patient.id_patient%TYPE;
        
            l_id_consult_req              NUMBER(24);
            l_id_episode                  NUMBER(24);
            l_id_schedule                 NUMBER(24);
            l_event_type                  VARCHAR2(4000 CHAR);
            l_event_type_name_title       pk_translation.t_desc_translation;
            l_event_type_clinical_service pk_translation.t_desc_translation;
            l_sch_type_desc               pk_translation.t_desc_translation;
            l_desc_prof                   VARCHAR2(4000 CHAR);
            l_request_status_desc         VARCHAR2(4000 CHAR);
            l_event_date                  VARCHAR2(4000 CHAR);
            l_event_date_ux               VARCHAR2(4000 CHAR);
            l_event_date_str              VARCHAR2(30 CHAR);
            l_flg_status                  sys_domain.val%TYPE;
        
        BEGIN
        
            -- get episode status flag
            IF NOT pk_episode.get_flg_status(i_lang, i_prof, i_episode, l_flg_status, l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- get_episode status desc
            l_status_desc := pk_sysdomain.get_domain('EPISODE.FLG_STATUS', l_flg_status, i_lang);
        
            -- get patient ID of the episode
            l_patient := pk_episode.get_epis_patient(i_lang, i_prof, i_episode);
        
            -- call future events function to get episode data
            IF NOT pk_events.get_epis_short_detail(i_lang, i_prof, l_patient, i_episode, l_future_event, l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- fetch data (episode details)
            FETCH l_future_event
                INTO l_id_consult_req,
                     l_id_episode,
                     l_id_schedule,
                     l_event_type,
                     l_event_type_name_title,
                     l_event_type_clinical_service,
                     l_sch_type_desc,
                     l_desc_prof,
                     l_request_status_desc,
                     l_event_date,
                     l_event_date_ux;
        
            CLOSE l_future_event;
        
            -- build appointment episode description
            l_epis_desc := l_event_type_name_title || (CASE
                               WHEN l_event_type_clinical_service IS NOT NULL THEN
                                ' - ' || l_event_type_clinical_service
                               ELSE
                                NULL
                           END);
        
            o_epis_desc   := l_epis_desc;
            o_status_desc := l_status_desc;
        
        END get_episode_desc;
    
    BEGIN
        -- get task description / status description
        g_error := 'get task description for task type/request [' || i_task_type || ',' || i_task_request || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
        
            WHEN g_task_lab_test THEN
                IF NOT pk_lab_tests_external_api_db.get_lab_test_task_description(i_lang             => i_lang,
                                                                                  i_prof             => i_prof,
                                                                                  i_task_request     => i_task_request,
                                                                                  o_task_desc        => l_task_desc,
                                                                                  o_task_status_desc => l_status_desc,
                                                                                  o_error            => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_image_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_task_description(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_task_request     => i_task_request,
                                                                          o_task_desc        => l_task_desc,
                                                                          o_task_status_desc => l_status_desc,
                                                                          o_error            => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_other_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_task_description(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_task_request     => i_task_request,
                                                                          o_task_desc        => l_task_desc,
                                                                          o_task_status_desc => l_status_desc,
                                                                          o_error            => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_appoint_social THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_appoint_nurse THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_appoint_medical THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_appoint_nutrition THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_appoint_psychology THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_appoint_rehabilit THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_inpatient THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_inp_surg THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_inpatient_ptbr THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            WHEN g_task_inp_surg_ptbr THEN
            
                get_episode_desc(i_task_request, l_task_desc, l_status_desc);
            
            ELSE
                l_task_desc := 'Task description for task type [' || i_task_type || '] not supported yet';
            
        END CASE;
    
        RETURN l_task_desc || ' (' || lower(l_status_desc) || ')';
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Could not get task description: ' || l_error.err_desc;
        
    END get_task_description;

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
    ) RETURN VARCHAR2 IS
        l_flg_time      VARCHAR2(1 CHAR);
        l_flg_time_desc VARCHAR2(1000 CHAR);
        l_error         t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        -- get task description / status description
        g_error := 'get task execute time description for task type/request [' || i_task_type || ',' || i_task_request || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
        
            WHEN g_task_lab_test THEN
                IF NOT pk_lab_tests_external_api_db.get_lab_test_task_execute_time(i_lang          => i_lang,
                                                                                   i_prof          => i_prof,
                                                                                   i_task_request  => i_task_request,
                                                                                   o_flg_time      => l_flg_time,
                                                                                   o_flg_time_desc => l_flg_time_desc,
                                                                                   o_error         => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_image_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_task_execute_time(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_task_request  => i_task_request,
                                                                           o_flg_time      => l_flg_time,
                                                                           o_flg_time_desc => l_flg_time_desc,
                                                                           o_error         => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_other_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_task_execute_time(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_task_request  => i_task_request,
                                                                           o_flg_time      => l_flg_time,
                                                                           o_flg_time_desc => l_flg_time_desc,
                                                                           o_error         => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- TODO: implement remain task types here
        
            ELSE
                l_flg_time_desc := 'Task execute time description for task type [' || i_task_type ||
                                   '] not supported yet';
            
        END CASE;
    
        RETURN l_flg_time_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Could not get task description: ' || l_error.err_desc;
        
    END get_execute_time_desc;

    /********************************************************************************************
    * get task cancel permission based in task type and request id
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    *
    * @return      varchar2               cancel permission    
    *
    * @value       function return        {*} 'Y' given task type/request id can be canceled by i_prof
    *                                     {*} 'N' given task type/request id cannot be canceled by i_prof
    *
    * @author                             Carlos Loureiro
    * @since                              27-MAY-2010
    ********************************************************************************************/
    FUNCTION get_cancel_permission
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_request IN tde_task_dependency.id_task_dependency%TYPE
    ) RETURN VARCHAR2 IS
        l_allow_cancel VARCHAR2(1 CHAR);
        l_error        t_error_out;
        l_exception EXCEPTION;
    BEGIN
        -- get cancel permission
        g_error := 'get cancel permission for task type/request [' || i_task_type || ',' || i_task_request || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
            WHEN g_task_lab_test THEN
                IF NOT pk_lab_tests_external_api_db.get_lab_test_cancel_permission(i_lang         => i_lang,
                                                                                   i_prof         => i_prof,
                                                                                   i_task_request => i_task_request,
                                                                                   o_flg_cancel   => l_allow_cancel,
                                                                                   o_error        => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_image_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_cancel_permission(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_task_request => i_task_request,
                                                                           o_flg_cancel   => l_allow_cancel,
                                                                           o_error        => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_other_exam THEN
                IF NOT pk_exams_external_api_db.get_exam_cancel_permission(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_task_request => i_task_request,
                                                                           o_flg_cancel   => l_allow_cancel,
                                                                           o_error        => l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
        -- TODO: implement remain task types    
        
            ELSE
                -- allow cancel in remain cases
                l_allow_cancel := pk_alert_constant.g_yes;
            
        END CASE;
    
        RETURN l_allow_cancel;
    
    END get_cancel_permission;

    /********************************************************************************************
    * check if dependency can be started by dependencies engine
    *
    * @param       i_lang                 preferred language id    
    * @param       i_task_dependency      task dependency id
    * @param       o_flg_start            task type for requested dependency
    * @param       o_start_tstz           start timestamp to consider in task start
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @value       o_flg_start            {*} 'Y' task can be started (all dependencies are resolved) 
    *                                     {*} 'N' task cannot be started (unresolved dependencies found)  
    *
    * @author                             Carlos Loureiro
    * @since                              18-JUN-2010
    ********************************************************************************************/
    FUNCTION check_task_start
    (
        i_lang            IN language.id_language%TYPE,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        o_flg_start       OUT VARCHAR2,
        o_start_tstz      OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'check if dependency [' || i_task_dependency || '] can be started by dependencies engine and when';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- if no lag was provided in dependencies creation, the task will start right away (current_timestamp)
        SELECT MAX(nvl2(trd.lag_min, -- TODO: consider lag max value in a later step of this development
                        pk_tde.add_offset_to_tstz(trd.resolved_timestamp, trd.lag_min, trd.id_unit_measure_lag),
                        current_timestamp))
          INTO o_start_tstz
          FROM tde_task_rel_dependency trd
         WHERE trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
           AND trd.id_task_dependency_to = i_task_dependency
           AND NOT EXISTS (SELECT 1
                  FROM tde_task_rel_dependency
                 WHERE id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
                   AND id_task_dependency_to = i_task_dependency
                   AND flg_resolved = g_tde_dependency_unresolved);
    
        -- the o_start_tstz is filled with a timestamp only if all predecessor dependencies are resolved
        IF o_start_tstz IS NULL
        THEN
            -- task cannot be started (unresolved dependencies found)
            g_error := 'dependency [' || i_task_dependency || '] cannot be started';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            o_flg_start := pk_alert_constant.g_no;
        
        ELSE
            -- task can be started (all dependencies are resolved)
            g_error := 'dependency [' || i_task_dependency || '] can start';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            o_flg_start := pk_alert_constant.g_yes;
        
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
                                              'CHECK_TASK_START',
                                              o_error);
            RETURN FALSE;
        
    END check_task_start;

    /********************************************************************************************
    * get all resolved/unresolved predecessor/sucessor dependencies for a given task dependency (finish2start relations)
    *
    * @param       i_lang                 preferred language id    
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_flg_resolved         flag that indicates if desired dependencies are resolved
    * @param       i_level                number of levels in dependencies hierarchy to search for
    * @param       i_direction            get predecessor or sucessor dependencies
    * @param       o_dependencies         list of predecessor/sucessor dependencies
    * @param       o_dependencies_anchor  list of sucessor/predecessor dependencies (for relationship anchor with o_dependencies)
    * @param       o_task_types           list of predecessor/sucessor task types
    * @param       o_task_requests        list of predecessor/sucessor task requests (direct match with dependencies)
    * @param       o_task_states          list of current predecessor/sucessor task states
    * @param       o_error                error structure for exception handling
    *
    * @value       i_flg_resolved         {*} 'Y' return only resolved dependencies     
    *                                     {*} 'N' return only unresolved dependencies
    *
    * @value       i_direction            {*} 'P' return only predecessor dependencies     
    *                                     {*} 'S' return only sucessor dependencies
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              22-MAY-2010
    ********************************************************************************************/
    FUNCTION get_dependencies
    (
        i_lang                IN language.id_language%TYPE,
        i_task_dependency     IN tde_task_dependency.id_task_dependency%TYPE,
        i_flg_resolved        IN tde_task_rel_dependency.flg_resolved%TYPE,
        i_level               IN NUMBER DEFAULT NULL,
        i_direction           IN VARCHAR2,
        o_dependencies        OUT table_number,
        o_dependencies_anchor OUT table_number,
        o_task_types          OUT table_number,
        o_task_requests       OUT table_number,
        o_task_states         OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_direction = g_tde_sucessor_dependencies
        THEN
            g_error := 'get all resolved [' || i_flg_resolved || '] sucessor dependencies of [' || i_task_dependency || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            SELECT trd.id_task_dependency_to,
                   trd.id_task_dependency_from,
                   td.id_task_type,
                   td.id_task_request,
                   td.flg_task_state
              BULK COLLECT
              INTO o_dependencies, o_dependencies_anchor, o_task_types, o_task_requests, o_task_states
              FROM tde_task_rel_dependency trd
              JOIN tde_task_dependency td
                ON td.id_task_dependency = trd.id_task_dependency_to
              JOIN task_type tt
                ON tt.id_task_type = td.id_task_type
             WHERE (i_level IS NULL OR LEVEL = i_level)
             START WITH trd.id_task_dependency_from = i_task_dependency
                    AND trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
                    AND trd.flg_resolved = i_flg_resolved
                    AND td.flg_schedule = pk_alert_constant.g_no
            CONNECT BY PRIOR trd.id_task_dependency_to = trd.id_task_dependency_from
                   AND trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
                   AND trd.flg_resolved = i_flg_resolved
                   AND td.flg_schedule = pk_alert_constant.g_no
             ORDER BY decode(id_unit_measure_lag, 10374, 1, 1041, 2, 1039, 3, 10375, 4), lag_min;
        
        ELSE
            g_error := 'get all resolved [' || i_flg_resolved || '] predecessor dependencies of [' || i_task_dependency || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            SELECT trd.id_task_dependency_from,
                   trd.id_task_dependency_to,
                   td.id_task_type,
                   td.id_task_request,
                   td.flg_task_state
              BULK COLLECT
              INTO o_dependencies, o_dependencies_anchor, o_task_types, o_task_requests, o_task_states
              FROM tde_task_rel_dependency trd
              JOIN tde_task_dependency td
                ON td.id_task_dependency = trd.id_task_dependency_from
              JOIN task_type tt
                ON tt.id_task_type = td.id_task_type
             WHERE (i_level IS NULL OR LEVEL = i_level)
             START WITH trd.id_task_dependency_to = i_task_dependency
                    AND trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
                    AND trd.flg_resolved = i_flg_resolved
                    AND td.flg_schedule = pk_alert_constant.g_no
            CONNECT BY trd.id_task_dependency_to = PRIOR trd.id_task_dependency_from
                   AND trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
                   AND trd.flg_resolved = i_flg_resolved
                   AND td.flg_schedule = pk_alert_constant.g_no
             ORDER BY decode(id_unit_measure_lag, 10374, 1, 1041, 2, 1039, 3, 10375, 4), lag_min;
        
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
                                              'GET_DEPENDENCIES',
                                              o_error);
            RETURN FALSE;
        
    END get_dependencies;

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
    ) RETURN BOOLEAN IS
        l_task_type            task_type.id_task_type%TYPE;
        l_dependencies         table_number;
        l_dependencies_anchor  table_number;
        l_depend_task_types    table_number;
        l_depend_task_requests table_number;
        l_depend_task_states   table_varchar;
        l_tbl                  t_tbl_tde_dependency_list := t_tbl_tde_dependency_list();
        l_rec                  t_rec_tde_dependency_list := t_rec_tde_dependency_list(NULL, NULL, NULL, NULL, NULL);
        k                      NUMBER := 0;
        l_show_allowed_actions VARCHAR2(1) := pk_alert_constant.g_yes;
        l_cancel_items_count   PLS_INTEGER;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'check all dependent tasks for action [' || i_task_states || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- check if task state change may affect other predecessor/sucessor dependencies
        FOR i IN 1 .. i_task_dependencies.count
        LOOP
            g_error := 'task dependency [' || i_task_dependencies(i) || '] will change its state to [' || i_task_states || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get unresolved sucessor task dependencies for i_task_dependencies(i) if canceling or suspending
            -- ... or ...
            -- get unresolved predecessor task dependencies for i_task_dependencies(i) if forcing execution
            IF NOT get_dependencies(i_lang                => i_lang,
                                    i_task_dependency     => i_task_dependencies(i),
                                    i_flg_resolved        => g_tde_dependency_unresolved,
                                    i_level               => NULL,
                                    i_direction           => CASE i_task_states
                                                                 WHEN g_tde_task_trans_force_exec THEN
                                                                  g_tde_predecessor_dependencies
                                                                 ELSE
                                                                  g_tde_sucessor_dependencies -- else i_task_states IN (g_tde_task_trans_cancel, g_tde_task_trans_suspend)
                                                             END,
                                    o_dependencies        => l_dependencies,
                                    o_dependencies_anchor => l_dependencies_anchor,
                                    o_task_types          => l_depend_task_types,
                                    o_task_requests       => l_depend_task_requests,
                                    o_task_states         => l_depend_task_states,
                                    o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- process dependencies for each i_task_dependencies(i)
            FOR j IN 1 .. l_dependencies.count
            LOOP
                l_rec.task_dependency_id_anchor := i_task_dependencies(i);
                l_rec.task_dependency_id        := l_dependencies(j);
                l_rec.task_type_id              := l_depend_task_types(j);
                l_rec.task_request_id           := l_depend_task_requests(j);
            
                -- get cancel permission (only if tasks are being canceled)
                IF (i_task_states = g_tde_task_trans_cancel)
                THEN
                    l_rec.flg_allow_action := get_cancel_permission(i_lang,
                                                                    i_prof,
                                                                    l_depend_task_types(j),
                                                                    l_depend_task_requests(j));
                    IF (l_rec.flg_allow_action = pk_alert_constant.g_no)
                    THEN
                        -- dependencies cursor should return only conflicted records
                        l_show_allowed_actions := pk_alert_constant.g_no;
                    
                    END IF;
                
                ELSE
                    -- allow other actions
                    l_rec.flg_allow_action := pk_alert_constant.g_yes;
                
                END IF;
            
                -- create new dependency record in l_tbl
                l_tbl.extend();
                k := k + 1;
                l_tbl(k) := l_rec;
            
            END LOOP;
        
        END LOOP;
    
        -- BEGIN: flg_conflict and messages processing block
        -- check if dependencies cursor is empty (no dependencies found)
        IF l_tbl.count = 0
        THEN
            o_flg_conflict := g_tde_flg_confl_none; -- 'N' no conflicts detected
            pk_types.open_my_cursor(o_dependencies); -- throw empty cursor
            -- no messages needed for this "no-conflict" case
        ELSE
            -- l_tbl.count != 0 (dependencies cursor is not empty)
            IF l_show_allowed_actions = pk_alert_constant.g_yes
            THEN
                IF i_task_states = g_tde_task_trans_cancel
                THEN
                    -- check if dependencies that will be cancelled are the same that will be displayed in the o_dependencies cursor
                    SELECT COUNT(1)
                      INTO l_cancel_items_count
                      FROM TABLE(CAST(l_tbl AS t_tbl_tde_dependency_list)) dp
                     WHERE dp.flg_allow_action = l_show_allowed_actions
                       AND dp.task_dependency_id NOT IN
                           (SELECT column_value
                              FROM TABLE(i_task_dependencies)); -- exclude tasks that are being addressed in action
                    -- if there are items to display in cancel action, then
                    IF l_cancel_items_count != 0
                    THEN
                        o_flg_conflict := g_tde_flg_confl_cancel_allow; -- 'Y' confirm the cancel action
                        o_msg_title    := pk_message.get_message(i_lang, 'TDE_T001');
                        o_msg_body     := pk_message.get_message(i_lang, 'TDE_M001');
                    ELSE
                        -- if all tasks that are being cancelled are the ones affected, there's no need to confirm the action
                        o_flg_conflict := g_tde_flg_confl_none; -- 'N' no conflicts detected
                        pk_types.open_my_cursor(o_dependencies); -- throw empty cursor
                        -- no messages needed for this "no-conflict" case                                   
                    END IF;
                ELSIF i_task_states = g_tde_task_trans_suspend
                THEN
                    o_flg_conflict := g_tde_flg_confl_suspend; -- 'S' confirm the suspend action
                    o_msg_title    := pk_message.get_message(i_lang, 'TDE_T002');
                    o_msg_body     := pk_message.get_message(i_lang, 'TDE_M003');
                ELSE
                    -- it can only be: i_task_states = g_tde_flg_confl_force_exec
                    o_flg_conflict := g_tde_flg_confl_force_exec; -- 'F' confirm the forced execution action
                    o_msg_title    := pk_message.get_message(i_lang, 'TDE_T003');
                    o_msg_body     := pk_message.get_message(i_lang, 'TDE_M004');
                END IF;
            ELSE
                -- l_show_allowed_actions = pk_alert_constant.g_no: this case only happens if canceling tasks 
                -- which, at least, one dependency cannot be canceled with i_prof's profile
                o_flg_conflict := g_tde_flg_confl_cancel_deny; -- 'C' cancel action denied 
                o_msg_title    := pk_message.get_message(i_lang, 'TDE_T001');
                o_msg_body     := pk_message.get_message(i_lang, 'TDE_M002');
            END IF;
            -- messages are already processed - now show associated dependencies                
            OPEN o_dependencies FOR
                SELECT task_dependency_id,
                       task_type_id,
                       pk_task_type.get_task_type_icon(i_lang, task_type_id) AS task_type_icon,
                       task_request_id,
                       get_task_description(i_lang, i_prof, task_type_id, task_request_id) AS task_request_desc,
                       get_execute_time_desc(i_lang, i_prof, task_type_id, task_request_id) AS exec_episode_desc
                  FROM (SELECT DISTINCT task_dependency_id, task_type_id, task_request_id
                          FROM TABLE(CAST(l_tbl AS t_tbl_tde_dependency_list)) dp
                         WHERE dp.flg_allow_action = l_show_allowed_actions
                           AND dp.task_dependency_id NOT IN
                               (SELECT column_value
                                  FROM TABLE(i_task_dependencies))) -- exclude tasks that are being addressed in action
                 ORDER BY task_type_id, task_request_desc;
        END IF;
        -- END: flg_conflict and messages processing block
    
        -- log call for debug (TODO: comment this before versioning)
        -- dbms_output.put_line('Log call id: ' || pk_alertlog.get_call_id());
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_TASK_STATE_CORE',
                                              o_error);
            pk_types.open_my_cursor(o_dependencies);
            RETURN FALSE;
        
    END check_task_state_core;

    /********************************************************************************************
    * cancel the task
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         task request
    * @param       i_reason               the id_cancel_reason
    * @param       i_reason_notes         the cancel notes 
    * @param       i_transaction_id       transaction id for scheduler transaction control    
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              09-JUN-2010
    ********************************************************************************************/
    FUNCTION task_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_type      IN tde_task_dependency.id_task_type%TYPE,
        i_task_request   IN tde_task_dependency.id_task_request%TYPE,
        i_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes   IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        -- cancel the task, according to its task type
        g_error := 'cancel task type [' || i_task_type || '] with request [' || i_task_request || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
        
            WHEN g_task_lab_test THEN
                IF NOT pk_lab_tests_external_api_db.cancel_lab_test_task(i_lang         => i_lang,
                                                                         i_prof         => i_prof,
                                                                         i_task_request => i_task_request,
                                                                         i_reason       => i_reason,
                                                                         i_reason_notes => i_reason_notes,
                                                                         i_prof_order   => NULL,
                                                                         i_dt_order     => NULL,
                                                                         i_order_type   => NULL,
                                                                         o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_lab_tests_external_api_db.cancel_lab_test_task function';
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_image_exam THEN
                IF NOT pk_exams_external_api_db.cancel_exam_task(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_task_request   => i_task_request,
                                                                 i_reason         => i_reason,
                                                                 i_reason_notes   => i_reason_notes,
                                                                 i_prof_order     => NULL,
                                                                 i_dt_order       => NULL,
                                                                 i_order_type     => NULL,
                                                                 i_transaction_id => i_transaction_id,
                                                                 o_error          => o_error)
                THEN
                    g_error := 'error found while calling pk_exams_external_api_db.cancel_exam_task function';
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_other_exam THEN
                IF NOT pk_exams_external_api_db.cancel_exam_task(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_task_request   => i_task_request,
                                                                 i_reason         => i_reason,
                                                                 i_reason_notes   => i_reason_notes,
                                                                 i_prof_order     => NULL,
                                                                 i_dt_order       => NULL,
                                                                 i_order_type     => NULL,
                                                                 i_transaction_id => i_transaction_id,
                                                                 o_error          => o_error)
                THEN
                    g_error := 'error found while calling pk_exams_external_api_db.cancel_exam_task function';
                    RAISE l_exception;
                END IF;
            
        -- TODO: implement code for remain task types
        
            ELSE
                NULL; -- do nothing for other task types (not supported yet)
        
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TASK_CANCEL',
                                              o_error);
            RETURN FALSE;
        
    END task_cancel;

    /********************************************************************************************
    * start the task
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    * @param       i_lag                  lag time to set the start timestamp to be considered in task
    * @param       i_lag_unit_measure     unit measure id to define the previous argument
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              09-JUN-2010
    ********************************************************************************************/
    FUNCTION task_start
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN tde_task_dependency.id_task_type%TYPE,
        i_task_request IN tde_task_dependency.id_task_request%TYPE,
        i_start_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        -- start the task, according to its task type
        g_error := 'start task type [' || i_task_type || '] with request [' || i_task_request ||
                   '] with start timestamp [' || i_start_tstz || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
        
            WHEN g_task_lab_test THEN
                IF NOT pk_lab_tests_external_api_db.start_lab_test_task_req(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_task_request => i_task_request,
                                                                            i_start_tstz   => i_start_tstz,
                                                                            o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_lab_tests_external_api_db.start_lab_test_task_req function';
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_image_exam THEN
                IF NOT pk_exams_external_api_db.start_exam_task_req(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_task_request => table_number(i_task_request),
                                                                    i_start_tstz   => i_start_tstz,
                                                                    o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_exams_external_api_db.start_exam_task_req function';
                    RAISE l_exception;
                END IF;
            
            WHEN g_task_other_exam THEN
                IF NOT pk_exams_external_api_db.start_exam_task_req(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_task_request => table_number(i_task_request),
                                                                    i_start_tstz   => i_start_tstz,
                                                                    o_error        => o_error)
                THEN
                    g_error := 'error found while calling pk_exams_external_api_db.start_exam_task_req function';
                    RAISE l_exception;
                END IF;
            
        -- TODO: implement code for remain task types
        
            ELSE
                NULL; -- do nothing for other task types (not supported yet)
        
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TASK_START',
                                              o_error);
            RETURN FALSE;
        
    END task_start;

    /********************************************************************************************
    * resolve predecessor dependencies 
    *
    * @param       i_lang                     preferred language id
    * @param       i_relationship_type        relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency          task dependency id
    * @param       o_error                    error structure for exception handling
    *
    * @return      boolean                    true on success, otherwise false    
    *
    * @author                                 Carlos Loureiro
    * @since                                  19-JUN-2010
    ********************************************************************************************/
    FUNCTION resolve_depend_predecessors
    (
        i_lang              IN language.id_language%TYPE,
        i_relationship_type IN tde_task_rel_dependency.id_relationship_type%TYPE,
        i_task_dependency   IN tde_task_dependency.id_task_dependency%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- process predecessor dependencies by resolving their relationships
        g_error := 'dependency relationships of type [' || i_relationship_type ||
                   '] for all predecessor dependencies of [' || i_task_dependency || '] are now resolved also';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE tde_task_rel_dependency trd
           SET trd.flg_resolved = g_tde_dependency_resolved, trd.resolved_timestamp = current_timestamp
         WHERE trd.id_relationship_type = i_relationship_type
           AND trd.id_task_dependency_to = i_task_dependency
           AND trd.flg_resolved = g_tde_dependency_unresolved;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESOLVE_DEPEND_PREDECESSORS',
                                              o_error);
            RETURN FALSE;
        
    END resolve_depend_predecessors;

    /********************************************************************************************
    * update task state
    *
    * @param       i_lang                 preferred language id    
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_task_type            task type id
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              09-JUN-2010
    ********************************************************************************************/
    FUNCTION update_task_state
    (
        i_lang            IN language.id_language%TYPE,
        i_task_dependency IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_anchor     IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_state      IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
    BEGIN
        -- update task state
        g_error := 'update task dependency [' || i_task_dependency || '] to state [' || i_task_state || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE tde_task_dependency td
           SET td.flg_task_state = i_task_state
         WHERE td.id_task_dependency = i_task_dependency
           AND td.flg_task_state != i_task_state;
        -- note: this update is only allowed if the transition occurs to a different state   
    
        -- if dependency state was updated, insert new history record
        IF SQL%ROWCOUNT != 0
        THEN
            -- insert history record
            INSERT INTO tde_task_dependency_hist
                (id_task_dependency_hist,
                 id_task_dependency,
                 flg_task_state,
                 change_timestamp,
                 changed_by_id_task_depend)
            VALUES
                (seq_tde_task_dependency_hist.nextval,
                 i_task_dependency,
                 i_task_state,
                 current_timestamp,
                 i_task_anchor);
        
        ELSE
            g_error := 'task dependency [' || i_task_dependency || '] was not updated (already in state [' ||
                       i_task_state || '])';
            pk_alertlog.log_debug(g_error, g_package_name);
        
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
                                              'UPDATE_TASK_STATE',
                                              o_error);
            RETURN FALSE;
        
    END update_task_state;

    /********************************************************************************************
    * update task dependency state
    *
    * @param       i_lang                 preferred language id    
    * @param       i_prof                 professional structure
    * @param       i_task_dependency      task dependency for the task about to change its state
    * @param       i_task_depend_anchor   task anchor dependencies (the task that originated this change)    
    * @param       i_task_type            task type id
    * @param       i_task_request         task request id
    * @param       i_task_state           target task state or desired task state
    * @param       i_reason               the id_cancel_reason
    * @param       i_reason_notes         the cancel notes 
    * @param       i_transaction_id       transaction id for scheduler transaction control    
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false    
    *
    * @author                             Carlos Loureiro
    * @since                              11-JUN-2010
    ********************************************************************************************/
    FUNCTION update_task_dependency_state
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_task_dependency    IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_depend_anchor IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_type          IN tde_task_dependency.id_task_type%TYPE,
        i_task_request       IN tde_task_dependency.id_task_request%TYPE,
        i_task_state         IN VARCHAR2,
        i_reason             IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes       IN VARCHAR2,
        i_transaction_id     IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_can_update_task_state BOOLEAN := FALSE;
        l_flg_start             VARCHAR2(1);
        l_start_tstz            TIMESTAMP WITH LOCAL TIME ZONE;
        l_exception EXCEPTION;
    
    BEGIN
        -- now that task state was updated and dependencies resolved, perform the action to the task
        -- if canceling or finishig the main task, the target dependency must be canceled or started also
        CASE i_task_state
        
            WHEN g_tde_task_trans_cancel THEN
                -- cancel action can allways be applied 
                l_can_update_task_state := TRUE;
            
                -- cancel the task only if is not the task that originated this action
                IF i_task_depend_anchor IS NOT NULL
                THEN
                    -- cancel the task
                    IF NOT task_cancel(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_task_type      => i_task_type,
                                       i_task_request   => i_task_request,
                                       i_reason         => i_reason,
                                       i_reason_notes   => i_reason_notes,
                                       i_transaction_id => i_transaction_id,
                                       o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            WHEN g_tde_task_trans_finish THEN
                -- check if all predecessor dependencies are resolved and process the start timestamp
                IF NOT check_task_start(i_lang, i_task_dependency, l_flg_start, l_start_tstz, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -- check if all predecessor dependencies are resolved in order to start task
                IF l_flg_start = pk_alert_constant.get_yes
                THEN
                    -- start the task
                    IF NOT task_start(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_task_type    => i_task_type,
                                      i_task_request => i_task_request,
                                      i_start_tstz   => l_start_tstz,
                                      o_error        => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    -- the task state can be updated 
                    l_can_update_task_state := TRUE;
                
                END IF;
            
            ELSE
                NULL; -- nothing to do 
        
        END CASE;
    
        -- if task state can be updated
        IF l_can_update_task_state
        THEN
            -- if task is being canceled... sucessor dependency will be canceled also
            -- if task is being finished... sucessor dependency will be started and will continue its workflow
            IF NOT update_task_state(i_lang            => i_lang,
                                     i_task_dependency => i_task_dependency,
                                     i_task_anchor     => i_task_depend_anchor,
                                     i_task_state      => CASE i_task_state
                                                              WHEN g_tde_task_trans_cancel THEN
                                                               g_tde_task_state_canceled
                                                              WHEN g_tde_task_trans_finish THEN
                                                               g_tde_task_state_started_tde
                                                              ELSE
                                                               i_task_state
                                                          END,
                                     o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
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
                                              'UPDATE_TASK_DEPENDENCY_STATE',
                                              o_error);
            RETURN FALSE;
        
    END update_task_dependency_state;

    /********************************************************************************************
    * resolve dependency
    *
    * @param       i_lang                     preferred language id
    * @param       i_relationship_type        relationship type (start-2-start or finish-2-start)
    * @param       i_task_dependency          task dependency id
    * @param       i_task_dependency_anchor   task dependency id to anchor or distinguish dependency relations
    * @param       i_task_state               target task state or desired task state    
    * @param       o_error                    error structure for exception handling
    *
    * @return      boolean                    true on success, otherwise false    
    *
    * @author                                 Carlos Loureiro
    * @since                                  09-JUN-2010
    ********************************************************************************************/
    FUNCTION resolve_dependency
    (
        i_lang                   IN language.id_language%TYPE,
        i_relationship_type      IN tde_task_rel_dependency.id_relationship_type%TYPE,
        i_task_dependency        IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_dependency_anchor IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_state             IN VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- process predecessor dependencies if necessary
        CASE i_task_state
        
            WHEN g_tde_task_trans_cancel THEN
                -- resolve dependency relationship
                g_error := 'dependency relationships of type [' || i_relationship_type ||
                           '] for all dependencies around [' || i_task_dependency || '] are now resolved (action was [' ||
                           i_task_state || '])';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- resolve all dependencies around (predecessor+sucessor) 
                UPDATE tde_task_rel_dependency trd
                   SET trd.flg_resolved = g_tde_dependency_resolved, trd.resolved_timestamp = current_timestamp
                 WHERE trd.id_relationship_type = i_relationship_type
                   AND (trd.id_task_dependency_from = i_task_dependency OR
                       trd.id_task_dependency_to = i_task_dependency)
                   AND trd.flg_resolved = g_tde_dependency_unresolved;
            
            WHEN g_tde_task_trans_finish THEN
                -- resolve dependency relationship
                g_error := 'dependency relationship of type [' || i_relationship_type || '] for dependencies [' ||
                           i_task_dependency_anchor || '->' || i_task_dependency || '] is now resolved (action was [' ||
                           i_task_state || '])';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- resolve predecessor dependency
                UPDATE tde_task_rel_dependency trd
                   SET trd.flg_resolved = g_tde_dependency_resolved, trd.resolved_timestamp = current_timestamp
                 WHERE trd.id_relationship_type = i_relationship_type
                   AND trd.id_task_dependency_to = i_task_dependency
                   AND trd.id_task_dependency_from = i_task_dependency_anchor
                   AND trd.flg_resolved = g_tde_dependency_unresolved;
            
            ELSE
                NULL; -- nothing to do
        
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'RESOLVE_DEPENDENCY',
                                              o_error);
            RETURN FALSE;
        
    END resolve_dependency;

    /********************************************************************************************
    * process dependencies for required target task states
    *
    * @param       i_lang                       preferred language id
    * @param       i_prof                       professional structure
    * @param       i_task_dependencies          array of dependencies id for the task where the dependecy comes from
    * @param       i_task_dependencies_anchor   array of anchored dependencies (for relationship anchor with i_task_dependencies)
    * @param       i_trans_to_state             target tasks states or desired tasks states
    * @param       i_task_types                 array of task type id
    * @param       i_task_requests              array of task request
    * @param       i_reason                     the id_cancel_reason, when canceling
    * @param       i_reason_notes               the cancel notes, when canceling 
    * @param       i_transaction_id             transaction id for scheduler    
    * @param       o_error                      error structure for exception handling
    *
    * @return      boolean                      true on success, otherwise false    
    *
    * @author                                   Carlos Loureiro
    * @since                                    10-JUN-2010
    ********************************************************************************************/
    FUNCTION process_dependencies
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_task_dependencies        IN table_number,
        i_task_dependencies_anchor IN table_number,
        i_trans_to_state           IN VARCHAR2,
        i_task_types               IN table_number,
        i_task_requests            IN table_number,
        i_reason                   IN cancel_reason.id_cancel_reason%TYPE,
        i_reason_notes             IN VARCHAR2,
        i_transaction_id           IN VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    
        l_exception EXCEPTION;
    
    BEGIN
        -- process all dependencies
        FOR i IN 1 .. i_task_dependencies.count
        LOOP
            -- resolve dependency relationships for i_task_dependencies based in i_task_state action
            IF NOT resolve_dependency(i_lang                   => i_lang,
                                      i_relationship_type      => pk_alert_constant.g_tde_rel_finish2start,
                                      i_task_dependency        => i_task_dependencies(i),
                                      i_task_dependency_anchor => i_task_dependencies_anchor(i),
                                      i_task_state             => i_trans_to_state,
                                      o_error                  => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- update task state  
            IF NOT update_task_dependency_state(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_task_dependency    => i_task_dependencies(i),
                                                i_task_depend_anchor => i_task_dependencies_anchor(i),
                                                i_task_type          => i_task_types(i),
                                                i_task_request       => i_task_requests(i),
                                                i_task_state         => i_trans_to_state,
                                                i_reason             => i_reason,
                                                i_reason_notes       => i_reason_notes,
                                                i_transaction_id     => i_transaction_id,
                                                o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROCESS_DEPENDENCIES',
                                              o_error);
            RETURN FALSE;
        
    END process_dependencies;

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
    ) RETURN BOOLEAN IS
        l_dependencies         table_number;
        l_dependencies_anchor  table_number;
        l_depend_task_types    table_number;
        l_depend_task_requests table_number;
        l_depend_task_states   table_varchar;
        l_exception EXCEPTION;
    
    BEGIN
        -- get unresolved sucessor task dependencies for i_task_dependency if canceling or finishing
        IF i_task_state IN (g_tde_task_trans_cancel, g_tde_task_trans_finish)
        THEN
            IF NOT get_dependencies(i_lang                => i_lang,
                                    i_task_dependency     => i_task_dependency,
                                    i_flg_resolved        => g_tde_dependency_unresolved,
                                    i_level               => CASE i_task_state
                                                                 WHEN g_tde_task_trans_finish THEN
                                                                  1 -- only one level is required
                                                                 ELSE
                                                                  NULL -- all levels are required for cancel action
                                                             END,
                                    i_direction           => g_tde_sucessor_dependencies, -- for cancel and finish actions, allways get sucessors
                                    o_dependencies        => l_dependencies,
                                    o_dependencies_anchor => l_dependencies_anchor,
                                    o_task_types          => l_depend_task_types,
                                    o_task_requests       => l_depend_task_requests,
                                    o_task_states         => l_depend_task_states,
                                    o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- dependencies are processed here, includind starting or canceling dependent tasks
            IF NOT process_dependencies(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_task_dependencies        => l_dependencies,
                                        i_task_dependencies_anchor => l_dependencies_anchor,
                                        i_trans_to_state           => i_task_state,
                                        i_task_types               => l_depend_task_types,
                                        i_task_requests            => l_depend_task_requests,
                                        i_reason                   => i_reason,
                                        i_reason_notes             => i_reason_notes,
                                        i_transaction_id           => i_transaction_id,
                                        o_error                    => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        -- after processing the dependencies we will end the workflow of main task
        IF NOT update_task_state(i_lang            => i_lang,
                                 i_task_dependency => i_task_dependency,
                                 i_task_anchor     => NULL, -- this change was request by the user
                                 i_task_state      => i_task_state,
                                 o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- resolve all predecessors of main task, if canceling, finishing, or force execution action
        -- equivalent to i_task_state not in (g_tde_task_trans_cancel, g_tde_task_trans_finish, g_tde_task_trans_force_exec)
        IF i_task_state != g_tde_task_trans_suspend
        THEN
            IF NOT
                resolve_depend_predecessors(i_lang, pk_alert_constant.g_tde_rel_finish2start, i_task_dependency, o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        -- log call for debug (TODO: comment this before versioning)
        -- dbms_output.put_line('Log call id: ' || pk_alertlog.get_call_id());
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_TASK_STATE_CORE',
                                              o_error);
            RETURN FALSE;
        
    END update_task_state_core;

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
        g_error          := 'call pk_schedule_api_upstream.begin_new_transaction';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF NOT update_task_state_core(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_task_dependency => i_task_dependency,
                                      i_task_state      => g_tde_task_trans_cancel,
                                      i_reason          => i_reason,
                                      i_reason_notes    => i_reason_notes,
                                      i_transaction_id  => l_transaction_id,
                                      o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- if no transaction id was given to this function, then commit scheduler transaction created here
        IF i_transaction_id IS NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit';
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
        IF NOT update_task_state_core(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_task_dependency => i_task_dependency,
                                      i_task_state      => g_tde_task_trans_suspend,
                                      i_reason          => i_reason,
                                      i_reason_notes    => i_reason_notes,
                                      i_transaction_id  => NULL,
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
        IF NOT update_task_state_core(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_task_dependency => i_task_dependency,
                                      i_task_state      => g_tde_task_trans_force_exec,
                                      i_reason          => NULL,
                                      i_reason_notes    => NULL,
                                      i_transaction_id  => NULL,
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
        IF NOT update_task_state_core(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_task_dependency => i_task_dependency,
                                      i_task_state      => g_tde_task_trans_finish,
                                      i_reason          => NULL,
                                      i_reason_notes    => NULL,
                                      i_transaction_id  => NULL,
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
    BEGIN
        OPEN o_relationships FOR
            SELECT tde_rel_type.id_relationship_type,
                   pk_translation.get_translation(i_lang, tde_rel_type.code_tde_relationship_type) AS relationship_type_desc,
                   tde_rel_type.internal_name
              FROM tde_relationship_type tde_rel_type
             WHERE tde_rel_type.flg_available = pk_alert_constant.get_yes
               AND tde_rel_type.id_relationship_type IN
                   (SELECT decode(tt.flg_dependency_support,
                                  pk_alert_constant.g_tt_tde_rel_all,
                                  tde_rel_type.id_relationship_type,
                                  pk_alert_constant.g_tt_tde_rel_start2start,
                                  pk_alert_constant.g_tde_rel_start2start,
                                  pk_alert_constant.g_tt_tde_rel_finish2start,
                                  pk_alert_constant.g_tde_rel_finish2start,
                                  NULL)
                      FROM task_type tt
                     WHERE tt.id_task_type = i_task_type);
    
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
            pk_types.open_my_cursor(o_relationships);
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
        l_desc pk_translation.t_desc_translation;
    
    BEGIN
        SELECT pk_translation.get_translation(i_lang, rt.code_tde_relationship_type)
          INTO l_desc
          FROM tde_relationship_type rt
         WHERE rt.id_relationship_type = i_tde_rel_type;
    
        RETURN l_desc;
    
    END get_relationship_type_desc;

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
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN CASE i_unit
        -- when i_lag is in minutes
        WHEN g_tde_lag_unit_minute THEN i_timestamp + numtodsinterval(i_lag, 'MINUTE')
        -- when i_lag is in hours
        WHEN g_tde_lag_unit_hour THEN i_timestamp + numtodsinterval(i_lag, 'HOUR')
        -- when i_lag is in days
        WHEN g_tde_lag_unit_day THEN i_timestamp + numtodsinterval(i_lag, 'DAY')
        -- when i_lag is in weeks
        WHEN g_tde_lag_unit_week THEN i_timestamp + numtodsinterval(i_lag * 7, 'DAY')
        -- when i_lag is in months
        WHEN g_tde_lag_unit_month THEN i_timestamp + numtoyminterval(i_lag, 'MONTH')
        -- when i_lag is in years
        WHEN g_tde_lag_unit_year THEN i_timestamp + numtoyminterval(i_lag, 'YEAR')
        -- else
        ELSE NULL END;
    END add_offset_to_tstz;

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
        l_flg_depend_support_from task_type.flg_dependency_support%TYPE;
        l_flg_epis_task_from      task_type.flg_episode_task%TYPE;
        l_flg_depend_support_to   task_type.flg_dependency_support%TYPE;
        l_flg_epis_task_to        task_type.flg_episode_task%TYPE;
    
    BEGIN
        -- get task type information
        set_task_type_info(i_task_type          => i_task_type_from,
                           o_flg_depend_support => l_flg_depend_support_from,
                           o_flg_epis_task      => l_flg_epis_task_from);
        set_task_type_info(i_task_type          => i_task_type_to,
                           o_flg_depend_support => l_flg_depend_support_to,
                           o_flg_epis_task      => l_flg_epis_task_to);
    
        -- lag interval can only exists between 2 episodes (single lag will be applied only between 2 tasks)
        IF l_flg_epis_task_from != pk_alert_constant.g_tt_tde_support_task
           AND l_flg_epis_task_to != pk_alert_constant.g_tt_tde_support_task
           AND i_flg_schedule_from = pk_alert_constant.g_yes
           AND i_flg_schedule_to = pk_alert_constant.g_yes
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            RETURN pk_alert_constant.g_yes;
        END IF;
    
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
        l_flg_depend_support_from task_type.flg_dependency_support%TYPE;
        l_flg_epis_task_from      task_type.flg_episode_task%TYPE;
        l_flg_depend_support_to   task_type.flg_dependency_support%TYPE;
        l_flg_epis_task_to        task_type.flg_episode_task%TYPE;
    
    BEGIN
        -- get task type information
        set_task_type_info(i_task_type          => i_task_type_from,
                           o_flg_depend_support => l_flg_depend_support_from,
                           o_flg_epis_task      => l_flg_epis_task_from);
        set_task_type_info(i_task_type          => i_task_type_to,
                           o_flg_depend_support => l_flg_depend_support_to,
                           o_flg_epis_task      => l_flg_epis_task_to);
    
        -- lag support is available for all task types that supports any kind of dependency, except current/future episodes
        IF l_flg_depend_support_from != pk_alert_constant.g_tt_tde_rel_none
           AND l_flg_depend_support_to != pk_alert_constant.g_tt_tde_rel_none
           AND
           ((i_task_type_from NOT IN (g_task_future_epis, g_task_current_epis) AND
           i_relationship_type = pk_alert_constant.g_tde_rel_start2start) OR
           (i_task_type_from != g_task_future_epis AND i_relationship_type = pk_alert_constant.g_tde_rel_finish2start))
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END lag_support_enable;

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
    ) RETURN NUMBER IS
    BEGIN
        -- verify if the dependencies array is not empty
        FOR i IN 1 .. i_tasks_rank.count
        LOOP
            -- search for dependency and returns its rank order
            IF i_tasks_rank(i) = i_dependency
            THEN
                RETURN i;
            END IF;
        END LOOP;
        RETURN NULL;
    END get_task_rank;

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
        l_task_depend_desc VARCHAR2(1000 CHAR);
        l_dtbl             t_tbl_tde_depend_rel_list;
        l_error            t_error_out;
        l_exception EXCEPTION;
    
        -- function used to build dependency lags description
        FUNCTION get_lag_description
        (
            in_lag_min          order_set_task_dependency.lag_min%TYPE,
            in_lag_max          order_set_task_dependency.lag_max%TYPE,
            in_lag_unit_measure order_set_task_dependency.id_unit_measure_lag%TYPE
        ) RETURN VARCHAR2 IS
            l_lag_desc VARCHAR2(200 CHAR);
            -- get lag unit measure abbreviation
            l_unit_measure_abbreviation CONSTANT VARCHAR2(10 CHAR) := pk_unit_measure.get_uom_abbreviation(i_lang,
                                                                                                           i_prof,
                                                                                                           in_lag_unit_measure);
            -- define empty lag symbol
            l_empty_lag_symbol CONSTANT VARCHAR2(3 CHAR) := '...';
        
        BEGIN
            -- verify if at least exists one of the lags
            IF (in_lag_min IS NOT NULL OR in_lag_max IS NOT NULL)
            THEN
                l_lag_desc := ' ['; -- start character
                -- if lag values are equal, then they appear as a single lag
                IF (in_lag_min = in_lag_max)
                THEN
                    l_lag_desc := l_lag_desc || nvl(in_lag_min, in_lag_max) || ' ' || l_unit_measure_abbreviation;
                ELSE
                    -- build lags description when min/max lag values are different                
                    l_lag_desc := l_lag_desc || (CASE
                                      WHEN in_lag_min IS NULL THEN
                                       l_empty_lag_symbol
                                      ELSE
                                       in_lag_min || ' ' || l_unit_measure_abbreviation
                                  END) || '-' || (CASE
                                      WHEN in_lag_max IS NULL THEN
                                       l_empty_lag_symbol
                                      ELSE
                                       in_lag_max || ' ' || l_unit_measure_abbreviation
                                  END);
                END IF;
                l_lag_desc := l_lag_desc || ']'; -- concatenate end character
            END IF;
        
            -- returns lags description
            RETURN l_lag_desc;
        END get_lag_description;
    
    BEGIN
        -- process dependencies into l_dtbl table collection    
        IF NOT set_dependencies_network(i_lang                 => i_lang,
                                        i_relationship_type    => i_relationship_type,
                                        i_task_dependency_from => i_task_dependency_from,
                                        i_task_dependency_to   => i_task_dependency_to,
                                        i_task_type_from       => i_task_type_from,
                                        i_task_type_to         => i_task_type_to,
                                        i_task_schedule_from   => i_task_schedule_from,
                                        i_task_schedule_to     => i_task_schedule_to,
                                        i_lag_min              => i_lag_min,
                                        i_lag_max              => i_lag_max,
                                        i_unit_measure_lag     => i_lag_unit_measure,
                                        o_dtbl                 => l_dtbl,
                                        o_error                => l_error)
        THEN
            g_error := 'error found while calling set_dependencies_network';
            RAISE l_exception;
        END IF;
    
        -- set default dependencies description
        -- verifies if the task represents or is considered as an episode
        IF (i_target_schedule = pk_alert_constant.g_yes)
        THEN
            -- "included in a future episode"
            l_task_depend_desc := pk_sysdomain.get_domain(g_dependency_episode_domain, g_depend_future_epis, i_lang);
        
        ELSE
            -- "included in the current episode"
            l_task_depend_desc := pk_sysdomain.get_domain(g_dependency_episode_domain, g_depend_current_epis, i_lang);
        END IF;
    
        -- loop for each relationship
        FOR rec IN (SELECT id_relationship_type,
                           rownum,
                           decode(rank, 1, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_first_dependency_type,
                           decode(total_count, rownum, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_last_dependency,
                           id_task_dependency_from,
                           id_task_type_from,
                           lag_min,
                           lag_max,
                           id_unit_measure_lag
                      FROM (SELECT deps.id_relationship_type,
                                   row_number() over(PARTITION BY deps.id_relationship_type ORDER BY get_task_rank(i_tasks_rank, deps.id_task_dependency_from) NULLS FIRST) AS rank,
                                   COUNT(1) over(ORDER BY 1 RANGE BETWEEN unbounded preceding AND unbounded following) AS total_count,
                                   deps.id_task_dependency_from,
                                   deps.id_task_type_from,
                                   deps.lag_min AS lag_min,
                                   deps.lag_max AS lag_max,
                                   deps.id_unit_measure_lag
                              FROM TABLE(CAST(l_dtbl AS t_tbl_tde_depend_rel_list)) deps
                             WHERE deps.id_task_dependency_to = i_target_dependency
                             ORDER BY deps.id_relationship_type, rank))
        LOOP
            -- #######################################
            -- ## DESCRIBE START2START DEPENDENCIES ##
            -- #######################################
        
            -- first task dependency
            IF (rec.flg_first_dependency_type = pk_alert_constant.g_yes AND rec.rownum = 1)
            THEN
                -- verifies if the task represents or is considered as an episode
                IF (i_target_schedule = pk_alert_constant.g_yes)
                THEN
                    -- "included in a future episode"
                    l_task_depend_desc := pk_sysdomain.get_domain(g_dependency_episode_domain,
                                                                  g_depend_future_epis,
                                                                  i_lang);
                ELSE
                    -- if no start2start relationship exists or 
                    -- exists a start2start relationship with the current episode
                    IF (rec.id_relationship_type != pk_alert_constant.g_tde_rel_start2start OR
                       (rec.id_relationship_type = pk_alert_constant.g_tde_rel_start2start AND
                       rec.id_task_type_from = g_task_current_epis))
                    THEN
                        -- "included in the current episode"
                        l_task_depend_desc := pk_sysdomain.get_domain(g_dependency_episode_domain,
                                                                      g_depend_current_epis,
                                                                      i_lang);
                    
                        -- exists a start2start relationship with a task existing in the network
                    ELSIF (rec.id_relationship_type = pk_alert_constant.g_tde_rel_start2start)
                    THEN
                        -- "included in an episode task existing in the network"
                        l_task_depend_desc := get_relationship_type_desc(i_lang,
                                                                         pk_alert_constant.g_tde_rel_start2start) || ': ' || '@[' ||
                                              rec.id_task_dependency_from || ']' ||
                                              get_lag_description(rec.lag_min, rec.lag_max, rec.id_unit_measure_lag);
                    END IF;
                END IF;
            END IF;
        
            -- ########################################
            -- ## DESCRIBE FINISH2START DEPENDENCIES ##
            -- ########################################
        
            -- concatenate "after" description
            IF (rec.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start)
            THEN
                -- first finish2start relationship
                IF (rec.flg_first_dependency_type = pk_alert_constant.g_yes)
                THEN
                    -- "after other task that exists in the network"
                    l_task_depend_desc := l_task_depend_desc || chr(10) ||
                                          get_relationship_type_desc(i_lang, pk_alert_constant.g_tde_rel_finish2start) || ': ';
                END IF;
            
                -- concatenate dependency reference
                l_task_depend_desc := l_task_depend_desc || '@[' || rec.id_task_dependency_from || ']' ||
                                      get_lag_description(rec.lag_min, rec.lag_max, rec.id_unit_measure_lag);
            
                -- concatenate dependencies separator
                IF (rec.flg_last_dependency = pk_alert_constant.g_no)
                THEN
                    l_task_depend_desc := l_task_depend_desc || ', ';
                END IF;
            END IF;
        
        END LOOP;
    
        -- returns dependencies description
        RETURN l_task_depend_desc;
    
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
        l_unresolved_count NUMBER;
        l_exception EXCEPTION;
    
    BEGIN
        -- check if task dependency is null (is so, proceed task resume as usual)    
        IF i_task_dependency IS NULL
        THEN
            o_flg_resume := g_tde_resume_normal;
        ELSE
            -- check if there are unresolved predecessor dependencies of i_task_dependency
            g_error := 'check if dependency [' || i_task_dependency || '] has unresolved dependencies';
            pk_alertlog.log_debug(g_error);
        
            SELECT COUNT(1)
              INTO l_unresolved_count
              FROM tde_task_rel_dependency trd
             WHERE trd.id_relationship_type = pk_alert_constant.g_tde_rel_finish2start
               AND trd.id_task_dependency_to = i_task_dependency
               AND trd.flg_resolved = g_tde_dependency_unresolved;
        
            IF l_unresolved_count > 0
            THEN
                o_flg_resume := g_tde_resume_wait;
            ELSE
                o_flg_resume := g_tde_resume_start;
            END IF;
        
            g_error := 'dependency [' || i_task_dependency || '] has [' || l_unresolved_count ||
                       '] unresolved dependencies - flg_resume sent was [' || o_flg_resume || ']';
            pk_alertlog.log_debug(g_error);
        
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
    * create simple dependencies network procedure
    *
    * @param       i_relationship_type          array of relationships (start-2-start or finish-2-start)
    * @param       i_task_dependency_from       array of task dependencies for the tasks where the dependency comes from
    * @param       i_task_dependency_to         array of task dependencies for the tasks where the dependency goes to    
    * @param       i_task_type_from             array of task types for the tasks where the dependency comes from
    * @param       i_task_type_to               array of task types for the tasks where the dependency goes to
    * @param       o_dtbl                       table of dependencies network    
    *
    * @author                                   Carlos Loureiro
    * @since                                    09-JUL-2010
    ********************************************************************************************/
    PROCEDURE create_dependencies_network
    (
        i_relationship_type    IN table_number DEFAULT NULL,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number DEFAULT NULL,
        i_task_type_to         IN table_number DEFAULT NULL,
        o_dtbl                 OUT t_tbl_tde_network
    ) IS
        l_rel_rec t_rec_tde_network := t_rec_tde_network(NULL, NULL, NULL, NULL, NULL);
    
    BEGIN
        -- init 
        o_dtbl := t_tbl_tde_network();
        -- process dependencies into o_dtbl
        FOR i IN 1 .. i_task_dependency_from.count
        LOOP
            l_rel_rec.id_task_dependency_from := i_task_dependency_from(i);
            l_rel_rec.id_task_dependency_to   := i_task_dependency_to(i);
        
            IF i_relationship_type IS NOT NULL
            THEN
                l_rel_rec.id_relationship_type := i_relationship_type(i);
            END IF;
        
            IF i_task_type_from IS NOT NULL
               AND i_task_type_to IS NOT NULL
            THEN
                l_rel_rec.id_task_type_from := i_task_type_from(i);
                l_rel_rec.id_task_type_to   := i_task_type_to(i);
            END IF;
        
            o_dtbl.extend;
            o_dtbl(i) := l_rel_rec;
        END LOOP;
    END create_dependencies_network;

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
        l_rel_tbl t_tbl_tde_network;
        l_combo   table_number := table_number();
        l_exception EXCEPTION;
    
        -- find dependency in array
        FUNCTION find_dependency
        (
            i_dependency  IN NUMBER,
            i_combination IN table_number
        ) RETURN BOOLEAN IS
        BEGIN
            -- for each element of a combination
            FOR i IN 1 .. i_combination.count
            LOOP
                IF i_combination(i) = i_dependency
                THEN
                    -- i_dependency was found and is one element of i_combination
                    RETURN TRUE;
                END IF;
            END LOOP;
            -- i_dependency was not found in i_combination
            RETURN FALSE;
        END find_dependency;
    
        -- find combo where the dependency exists
        FUNCTION find_dependency_combo
        (
            i_dependency   IN NUMBER,
            i_combinations IN table_table_number
        ) RETURN NUMBER IS
            l_cb table_number;
        BEGIN
            -- for each combination
            FOR i IN 1 .. i_combinations.count
            LOOP
                -- for each element of a combination
                l_cb := i_combinations(i);
                IF find_dependency(i_dependency, l_cb)
                THEN
                    -- i_dependency was found and is in the "i"st array
                    RETURN i;
                END IF;
            END LOOP;
            -- i_dependency was not found in any arrays of i_combinations
            RETURN 0;
        END find_dependency_combo;
    
        -- get dependency related nodes for navigation in the relations network
        FUNCTION get_related_nodes
        (
            i_dep       IN NUMBER,
            i_relations IN t_tbl_tde_network
        ) RETURN table_number IS
            l_return_tn table_number;
        BEGIN
            -- get all i_dep related nodes, with i_rel_type relationship type 
            SELECT dependency
              BULK COLLECT
              INTO l_return_tn
              FROM (SELECT drl.id_task_dependency_to AS dependency
                      FROM TABLE(CAST(i_relations AS t_tbl_tde_network)) drl
                     WHERE drl.id_task_dependency_from = i_dep
                    UNION
                    SELECT drl.id_task_dependency_from AS dependency
                      FROM TABLE(CAST(i_relations AS t_tbl_tde_network)) drl
                     WHERE drl.id_task_dependency_to = i_dep);
            RETURN l_return_tn;
        END get_related_nodes;
    
        -- update combination array with the new element and navigate to related ones (recursive function)
        PROCEDURE update_combo
        (
            i_dependency IN NUMBER,
            i_relations  IN t_tbl_tde_network,
            io_combo     IN OUT NOCOPY table_number
        ) IS
            l_temp_tn table_number;
        BEGIN
            -- add starting dependency
            io_combo.extend;
            io_combo(io_combo.count) := i_dependency;
            -- get related nodes for network navigation
            l_temp_tn := get_related_nodes(i_dependency, i_relations);
            -- process related nodes        
            FOR i IN 1 .. l_temp_tn.count
            LOOP
                -- find dependency in current combo to avoid adding it again
                IF NOT find_dependency(l_temp_tn(i), io_combo)
                THEN
                    -- add a new element to the combo
                    update_combo(l_temp_tn(i), i_relations, io_combo);
                END IF;
            END LOOP;
        END update_combo;
    
    BEGIN
        -- init bi-dimensional array
        o_combinations := table_table_number();
    
        -- process dependencies into l_rel_tbl  
        create_dependencies_network(i_task_dependency_from => i_task_dependency_from,
                                    i_task_dependency_to   => i_task_dependency_to,
                                    o_dtbl                 => l_rel_tbl);
    
        -- process dependencies present in the network
        FOR i IN 1 .. i_dependency.count
        LOOP
            -- find dependency in combination
            IF find_dependency_combo(i_dependency(i), o_combinations) = 0
            THEN
                -- dependency wasn't found in any combo, so create a new one
                l_combo := table_number();
                update_combo(i_dependency(i), l_rel_tbl, l_combo);
                o_combinations.extend;
                o_combinations(o_combinations.count) := l_combo;
            END IF;
        END LOOP;
    
        -- if no combinations were created in previous dependencies process
        IF o_combinations.count = 0
        THEN
            g_error := 'no combinations were found';
            RAISE l_exception;
        ELSIF o_combinations.count = 1
        THEN
            o_flg_single_network := pk_alert_constant.g_yes; -- single network found
        ELSE
            o_flg_single_network := pk_alert_constant.g_no; -- multiple networks found
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
        l_rel_tbl t_tbl_tde_network := t_tbl_tde_network();
        l_tn      table_number;
    
    BEGIN
        -- process dependencies into l_rel_tbl  
        create_dependencies_network(i_relationship_type    => i_relationship_type,
                                    i_task_dependency_from => i_task_dependency_from,
                                    i_task_dependency_to   => i_task_dependency_to,
                                    i_task_type_from       => i_task_type_from,
                                    i_task_type_to         => i_task_type_to,
                                    o_dtbl                 => l_rel_tbl);
    
        -- collect sucessor dependencies into l_tn table_number
        SELECT DISTINCT drl.id_task_dependency_to
          BULK COLLECT
          INTO l_tn
          FROM TABLE(CAST(l_rel_tbl AS t_tbl_tde_network)) drl
         START WITH drl.id_task_dependency_from = i_dependency
                AND drl.id_task_type_from NOT IN (g_task_current_epis, g_task_future_epis)
        CONNECT BY PRIOR drl.id_task_dependency_to = drl.id_task_dependency_from
               AND drl.id_task_type_from NOT IN (g_task_current_epis, g_task_future_epis);
    
        RETURN l_tn;
    
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
        l_rel_tbl t_tbl_tde_network := t_tbl_tde_network();
        l_tn      table_number;
    
    BEGIN
        -- process dependencies into l_rel_tbl  
        create_dependencies_network(i_relationship_type    => i_relationship_type,
                                    i_task_dependency_from => i_task_dependency_from,
                                    i_task_dependency_to   => i_task_dependency_to,
                                    i_task_type_from       => i_task_type_from,
                                    i_task_type_to         => i_task_type_to,
                                    o_dtbl                 => l_rel_tbl);
    
        -- collect predecessor dependencies into l_tn table_number
        SELECT DISTINCT drl.id_task_dependency_from
          BULK COLLECT
          INTO l_tn
          FROM TABLE(CAST(l_rel_tbl AS t_tbl_tde_network)) drl
         START WITH drl.id_task_dependency_to = i_dependency
        CONNECT BY drl.id_task_dependency_to = PRIOR drl.id_task_dependency_from;
    
        RETURN l_tn;
    
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
        l_task_dependency tde_task_dependency.id_task_dependency%TYPE;
    BEGIN
        SELECT id_task_dependency
          INTO l_task_dependency
          FROM tde_task_dependency td
         WHERE td.id_task_type = i_task_type
           AND td.id_task_request = i_task_request;
        RETURN l_task_dependency;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_task_dependency;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_tde;
/
